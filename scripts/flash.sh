#!/bin/bash
#
# ztOS herolight Flash Script
# Helper script for flashing ztOS images to Samsung Galaxy S7
#
# Usage:
#   ./flash.sh [command] [options]
#
# Commands:
#   boot      Flash boot image to BOOT partition
#   recovery  Flash recovery image to RECOVERY partition
#   rootfs    Flash root filesystem to USERDATA partition
#   all       Flash all images (boot + recovery + rootfs)
#   twrp      Flash TWRP recovery
#   stock     Restore stock images
#
# Options:
#   -f, --file FILE    Specify image file path
#   -d, --device ID    Specify device serial (for multiple phones)
#   -y, --yes          Skip confirmation prompts
#   -h, --help         Show this help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

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

# Default paths
BOOT_IMG="${PROJECT_DIR}/out/boot.img"
RECOVERY_IMG="${PROJECT_DIR}/out/recovery.img"
ROOTFS_IMG="${PROJECT_DIR}/out/rootfs.img"
TWRP_IMG="${PROJECT_DIR}/firmware/twrp-herolight.img"
STOCK_DIR="${PROJECT_DIR}/firmware/stock"

# Options
DEVICE_SERIAL=""
SKIP_CONFIRM=false

usage() {
    cat << EOF
ztOS herolight Flash Script

Usage: $0 [command] [options]

Commands:
  boot          Flash boot image (requires -f or default path)
  recovery      Flash recovery image (requires -f or default path)
  rootfs        Flash root filesystem (requires -f or default path)
  all           Flash boot + recovery + rootfs
  twrp          Flash TWRP recovery image
  stock-boot    Restore stock boot image
  stock-full    Full stock restore (boot + recovery + format userdata)
  verify        Verify current installation

Options:
  -f, --file FILE     Specify image file path
  -d, --device ID     Specify adb device serial
  -y, --yes           Skip confirmation prompts
  -h, --help          Show this help

Examples:
  $0 boot -f ./my-boot.img
  $0 all -y
  $0 twrp
  $0 stock-boot

EOF
    exit 0
}

# Parse arguments
COMMAND=""
FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        boot|recovery|rootfs|all|twrp|stock-boot|stock-full|verify)
            COMMAND="$1"
            shift
            ;;
        -f|--file)
            FILE="$2"
            shift 2
            ;;
        -d|--device)
            DEVICE_SERIAL="$2"
            shift 2
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

[[ -z "$COMMAND" ]] && usage

# ADB helper
adb_cmd() {
    if [[ -n "$DEVICE_SERIAL" ]]; then
        adb -s "$DEVICE_SERIAL" "$@"
    else
        adb "$@"
    fi
}

# Check device connection
check_device() {
    log_step "Checking device connection..."
    if ! adb_cmd devices | grep -q "device$"; then
        log_error "No device found. Please connect your phone in download mode or with ADB enabled."
        exit 1
    fi
    log_info "Device connected"
}

# Confirm dangerous operations
confirm() {
    if [[ "$SKIP_CONFIRM" == true ]]; then
        return 0
    fi
    echo -e "${YELLOW}WARNING:${NC} $1"
    read -p "Are you sure? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Flash via heimdall (download mode)
flash_heimdall() {
    local partition="$1"
    local image="$2"
    
    if ! command -v heimdall &> /dev/null; then
        log_error "heimdall not found. Install with: sudo apt install heimdall-flash"
        exit 1
    fi
    
    log_step "Flashing ${partition} with heimdall..."
    heimdall flash --"${partition}" "${image}"
    log_info "${partition} flashed successfully"
}

# Flash via ODIN protocol (using our web tool or python)
flash_odin() {
    local partition="$1"
    local image="$2"
    
    log_info "Please use the web installer for ODIN flashing:"
    log_info "  https://g7qispjjjjky4.kimi.page"
    log_info "Or manually with heimdall: heimdall flash --${partition} ${image}"
}

# Flash via adb shell dd (TWRP mode)
flash_adb() {
    local partition="$1"
    local image="$2"
    
    log_step "Pushing ${image} to device..."
    local remote_path="/tmp/flash_$(basename "$image")"
    adb_cmd push "${image}" "${remote_path}"
    
    log_step "Writing to ${partition} partition..."
    adb_cmd shell "dd if=${remote_path} of=/dev/block/bootdevice/by-name/${partition} bs=4M status=progress"
    adb_cmd shell "rm -f ${remote_path}"
    
    log_info "${partition} flashed successfully"
}

# Detect device mode and flash accordingly
detect_and_flash() {
    local partition="$1"
    local image="$2"
    
    # Check if in download mode (heimdall detect)
    if heimdall detect &> /dev/null; then
        flash_heimdall "$partition" "$image"
        return
    fi
    
    # Check if in recovery/TWRP (adb available)
    if adb_cmd shell echo test &> /dev/null; then
        flash_adb "$partition" "$image"
        return
    fi
    
    log_error "Device not detected in download mode or ADB mode."
    log_info "Please put device in download mode: Volume Down + Home + Power"
    exit 1
}

# Commands
case "$COMMAND" in
    boot)
        IMAGE="${FILE:-$BOOT_IMG}"
        [[ ! -f "$IMAGE" ]] && { log_error "Boot image not found: $IMAGE"; exit 1; }
        confirm "This will flash ${IMAGE} to the BOOT partition."
        detect_and_flash "BOOT" "$IMAGE"
        ;;
    
    recovery)
        IMAGE="${FILE:-$RECOVERY_IMG}"
        [[ ! -f "$IMAGE" ]] && { log_error "Recovery image not found: $IMAGE"; exit 1; }
        confirm "This will flash ${IMAGE} to the RECOVERY partition."
        detect_and_flash "RECOVERY" "$IMAGE"
        ;;
    
    rootfs)
        IMAGE="${FILE:-$ROOTFS_IMG}"
        [[ ! -f "$IMAGE" ]] && { log_error "Rootfs image not found: $IMAGE"; exit 1; }
        confirm "This will ERASE USERDATA and flash ${IMAGE}. All personal data will be lost!"
        detect_and_flash "USERDATA" "$IMAGE"
        ;;
    
    all)
        log_step "Full flash: boot + recovery + rootfs"
        
        [[ ! -f "$BOOT_IMG" ]] && { log_error "Boot image not found: $BOOT_IMG"; exit 1; }
        [[ ! -f "$RECOVERY_IMG" ]] && { log_error "Recovery image not found: $RECOVERY_IMG"; exit 1; }
        [[ ! -f "$ROOTFS_IMG" ]] && { log_error "Rootfs image not found: $ROOTFS_IMG"; exit 1; }
        
        confirm "This will flash boot, recovery, and ERASE USERDATA. All personal data will be lost!"
        
        detect_and_flash "BOOT" "$BOOT_IMG"
        detect_and_flash "RECOVERY" "$RECOVERY_IMG"
        detect_and_flash "USERDATA" "$ROOTFS_IMG"
        
        log_info "All images flashed. Rebooting..."
        adb_cmd reboot || true
        ;;
    
    twrp)
        [[ ! -f "$TWRP_IMG" ]] && { log_error "TWRP image not found: $TWRP_IMG"; exit 1; }
        confirm "This will flash TWRP to the RECOVERY partition."
        detect_and_flash "RECOVERY" "$TWRP_IMG"
        ;;
    
    stock-boot)
        STOCK_BOOT="${STOCK_DIR}/BOOT.img"
        [[ ! -f "$STOCK_BOOT" ]] && { log_error "Stock boot not found: $STOCK_BOOT"; exit 1; }
        confirm "This will restore stock BOOT. Your ztOS kernel will be replaced."
        detect_and_flash "BOOT" "$STOCK_BOOT"
        ;;
    
    stock-full)
        confirm "This will COMPLETELY RESTORE stock Android and erase ztOS. This cannot be undone!"
        
        for img in BOOT RECOVERY USERDATA; do
            STOCK_IMG="${STOCK_DIR}/${img}.img"
            if [[ -f "$STOCK_IMG" ]]; then
                detect_and_flash "$img" "$STOCK_IMG"
            else
                log_warn "Stock ${img} not found, skipping"
            fi
        done
        
        log_info "Full restore complete. Rebooting to stock..."
        adb_cmd reboot || true
        ;;
    
    verify)
        log_step "Verifying current installation..."
        
        if adb_cmd shell test -f /sbin/init &> /dev/null; then
            log_info "ztOS init found - system appears bootable"
        fi
        
        if adb_cmd shell test -d /ztos &> /dev/null; then
            log_info "ztOS root directory found"
        fi
        
        # Check kernel version
        KERNEL=$(adb_cmd shell uname -r 2>/dev/null || echo "unknown")
        log_info "Kernel version: $KERNEL"
        
        # Check partitions
        log_step "Partition status:"
        for part in BOOT RECOVERY SYSTEM VENDOR USERDATA EFS; do
            if adb_cmd shell test -e "/dev/block/bootdevice/by-name/${part}" &> /dev/null; then
                SIZE=$(adb_cmd shell blockdev --getsize64 "/dev/block/bootdevice/by-name/${part}" 2>/dev/null || echo "?")
                log_info "  ${part}: ${SIZE} bytes"
            else
                log_warn "  ${part}: not found"
            fi
        done
        ;;
    
    *)
        log_error "Unknown command: $COMMAND"
        usage
        ;;
esac

log_info "Done!"
