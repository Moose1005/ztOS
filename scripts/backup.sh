#!/bin/bash
#
# ztOS herolight Backup Script
# Critical: Run this BEFORE any flash operation!
#
# Usage:
#   ./backup.sh [output_directory]
#
# This script backs up all critical partitions from your Samsung Galaxy S7.
# KEEP THESE BACKUPS SAFE - especially EFS.img!

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default output directory
OUTPUT_DIR="${1:-${PROJECT_DIR}/firmware/stock}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

mkdir -p "$OUTPUT_DIR"

log_step "ztOS herolight Backup Script"
log_info "Output directory: $OUTPUT_DIR"
log_warn "Make sure your phone is in TWRP recovery mode with ADB enabled!"
read -p "Press Enter to continue..."

# Check ADB connection
if ! adb devices | grep -q "recovery"; then
    log_warn "No device in recovery mode detected."
    log_info "Trying anyway..."
fi

# Partitions to backup (CRITICAL ones first)
PARTITIONS=(
    "EFS:efs.bin:CRITICAL - IMEI/WiFi/BT MACs"
    "CPEFS:cpefs.bin:Cellular parameters"
    "BOOT:boot.img:Kernel image"
    "RECOVERY:recovery.img:Recovery image"
    "SYSTEM:system.img:Android system (4GB - large!)"
    "VENDOR:vendor.img:Android vendor"
    "RADIO:radio.img:Modem firmware"
    "PARAM:param.bin:Device parameters"
    "MISC:misc.bin:Misc data"
)

TOTAL=${#PARTITIONS[@]}
CURRENT=0

for entry in "${PARTITIONS[@]}"; do
    IFS=':' read -r part file desc <<< "$entry"
    CURRENT=$((CURRENT + 1))
    
    log_step "[$CURRENT/$TOTAL] Backing up $part ($desc)..."
    
    OUTPUT_FILE="${OUTPUT_DIR}/${file}"
    
    # Get partition size
    SIZE=$(adb shell blockdev --getsize64 "/dev/block/bootdevice/by-name/${part}" 2>/dev/null || echo "0")
    
    if [[ "$SIZE" == "0" ]]; then
        log_warn "Partition $part not found or empty, skipping"
        continue
    fi
    
    SIZE_MB=$((SIZE / 1024 / 1024))
    log_info "Partition size: ${SIZE_MB}MB"
    
    if [[ "$SIZE_MB" -gt 2048 ]]; then
        log_warn "Large partition (${SIZE_MB}MB). This will take a while..."
    fi
    
    # Backup via dd
    adb shell "dd if=/dev/block/bootdevice/by-name/${part} bs=4M" | pv -s "$SIZE" > "$OUTPUT_FILE"
    
    # Verify backup
    BACKUP_SIZE=$(stat -c%s "$OUTPUT_FILE")
    if [[ "$BACKUP_SIZE" == "$SIZE" ]]; then
        log_info "Backup verified: ${BACKUP_SIZE} bytes"
    else
        log_warn "Size mismatch! Expected ${SIZE}, got ${BACKUP_SIZE}"
    fi
    
    # Generate checksum
    sha256sum "$OUTPUT_FILE" > "${OUTPUT_FILE}.sha256"
    log_info "SHA-256 saved to ${OUTPUT_FILE}.sha256"
done

# Special: dump PIT (Partition Information Table)
log_step "Dumping PIT (Partition Information Table)..."
if command -v heimdall &> /dev/null; then
    heimdall download-pit --output "${OUTPUT_DIR}/herolight.pit"
    log_info "PIT dumped successfully"
else
    log_warn "heimdall not found, skipping PIT dump"
fi

# Generate backup manifest
log_step "Generating backup manifest..."
cat > "${OUTPUT_DIR}/MANIFEST.txt" << EOF
ztOS herolight Backup Manifest
==============================
Device: Samsung Galaxy S7 (SM-G930W8)
Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Backup location: ${OUTPUT_DIR}

CRITICAL WARNINGS:
- EFS partition contains IMEI, Wi-Fi MAC, and Bluetooth MAC
- If EFS is lost without backup, cellular is PERMANENTLY broken
- Keep backups on multiple devices/cloud storage

Files:
EOF

for entry in "${PARTITIONS[@]}"; do
    IFS=':' read -r part file desc <<< "$entry"
    if [[ -f "${OUTPUT_DIR}/${file}" ]]; then
        SIZE=$(stat -c%s "${OUTPUT_DIR}/${file}")
        HASH=$(sha256sum "${OUTPUT_DIR}/${file}" | cut -d' ' -f1)
        echo "  ${file}: ${SIZE} bytes, SHA256=${HASH}" >> "${OUTPUT_DIR}/MANIFEST.txt"
    fi
done

log_step "Backup complete!"
log_info "Files saved to: ${OUTPUT_DIR}"
log_warn "CRITICAL: Store EFS backups securely!"

# Summary
ls -lh "$OUTPUT_DIR"
