#!/bin/bash
#
# ztOS herolight Boot Image Packer
# Combines kernel, device tree blob, and initramfs into Android boot.img
#
# Usage:
#   ./mkbootimg.sh [options]
#
# Options:
#   -k, --kernel FILE       Kernel image (Image.gz) [default: arch/arm64/boot/Image.gz]
#   -d, --dtb FILE          Device tree blob [default: arch/arm64/boot/dts/samsung/exynos8890-herolight.dtb]
#   -r, --ramdir DIR        Initramfs source directory [default: initramfs/]
#   -o, --output FILE       Output boot.img path [default: out/boot.img]
#   -c, --cmdline STRING    Kernel cmdline [default: see below]
#   -h, --help              Show this help
#
# The script uses mkbootimg (from android-tools-mkbootimg) or abootimg as fallback.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$SCRIPT_DIR"

# Samsung Galaxy S7 (herolight) boot image parameters
# These MUST match BoardConfig.mk values
KERNEL_BASE="0x10000000"
KERNEL_PAGESIZE="2048"
KERNEL_TAGS_OFFSET="0x00000100"
RAMDISK_OFFSET="0x01000000"
DTB_OFFSET="0x00000000"  # Appended to kernel

# Default paths
KERNEL="${KERNEL_DIR}/arch/arm64/boot/Image.gz"
DTB="${KERNEL_DIR}/arch/arm64/boot/dts/samsung/exynos8890-herolight.dtb"
RAMDISK_DIR="${KERNEL_DIR}/initramfs"
OUTPUT="${KERNEL_DIR}/out/boot.img"

# Default cmdline - permissive SELinux for bring-up
CMDLINE="console=ttySAC0,115200n8 androidboot.hardware=herolight androidboot.selinux=permissive ztOS.root=/dev/block/bootdevice/by-name/USERDATA"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[BOOTIMG]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[BOOTIMG]${NC} $1"; }
log_error() { echo -e "${RED}[BOOTIMG]${NC} $1"; }
log_step()  { echo -e "${BLUE}[BOOTIMG]${NC} $1"; }

usage() {
    cat << EOF
ztOS herolight Boot Image Packer

Usage: $0 [options]

Options:
  -k, --kernel FILE       Kernel image (Image.gz)
                          [default: arch/arm64/boot/Image.gz]
  -d, --dtb FILE          Device tree blob
                          [default: arch/arm64/boot/dts/samsung/exynos8890-herolight.dtb]
  -r, --ramdir DIR        Initramfs source directory
                          [default: initramfs/]
  -o, --output FILE       Output boot.img path
                          [default: out/boot.img]
  -c, --cmdline STRING    Kernel cmdline
  -h, --help              Show this help

Examples:
  $0                                    # Use all defaults
  $0 -k /path/to/custom/Image.gz       # Custom kernel
  $0 -c "console=tty0 debug"           # Custom cmdline

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--kernel)
            KERNEL="$2"
            shift 2
            ;;
        -d|--dtb)
            DTB="$2"
            shift 2
            ;;
        -r|--ramdir)
            RAMDISK_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        -c|--cmdline)
            CMDLINE="$2"
            shift 2
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

mkdir -p "$(dirname "$OUTPUT")"

log_step "ztOS herolight Boot Image Packer"
log_info "Kernel base: $KERNEL_BASE"
log_info "Page size: $KERNEL_PAGESIZE"
log_info "RAMDISK offset: $RAMDISK_OFFSET"
log_info "Tags offset: $KERNEL_TAGS_OFFSET"

# Validate inputs
if [[ ! -f "$KERNEL" ]]; then
    log_error "Kernel not found: $KERNEL"
    log_info "Build the kernel first: ./build-herolight.sh boot"
    exit 1
fi

if [[ ! -f "$DTB" ]]; then
    log_error "DTB not found: $DTB"
    log_info "Build DTB first: ./build-herolight.sh dtb"
    exit 1
fi

if [[ ! -d "$RAMDISK_DIR" ]]; then
    log_error "Initramfs directory not found: $RAMDISK_DIR"
    exit 1
fi

log_info "Kernel: $KERNEL ($(stat -c%s "$KERNEL") bytes)"
log_info "DTB: $DTB ($(stat -c%s "$DTB") bytes)"
log_info "Initramfs: $RAMDISK_DIR"
log_info "Cmdline: $CMDLINE"

# Step 1: Append DTB to kernel (Samsung style - dtb appended after gzip)
log_step "Appending DTB to kernel..."
KERNEL_WITH_DTB="${KERNEL_DIR}/out/Image.gz-dtb"
cp "$KERNEL" "$KERNEL_WITH_DTB"
cat "$DTB" >> "$KERNEL_WITH_DTB"
log_info "Kernel+DTB: $(stat -c%s "$KERNEL_WITH_DTB") bytes"

# Step 2: Create initramfs cpio archive
log_step "Packing initramfs..."
RAMDISK_CPIO="${KERNEL_DIR}/out/ramdisk.cpio"
RAMDISK_GZ="${KERNEL_DIR}/out/ramdisk.cpio.gz"

# Find all files in initramfs and create cpio archive
# Use 'cpio -o -H newc' for modern initramfs format
cd "$RAMDISK_DIR"
find . -print0 | cpio --null -o --format=newc > "$RAMDISK_CPIO" 2>/dev/null || {
    log_warn "cpio failed, trying with file list..."
    find . | cpio -o -H newc > "$RAMDISK_CPIO"
}
cd - > /dev/null

log_info "Ramdisk cpio: $(stat -c%s "$RAMDISK_CPIO") bytes"

# Compress with gzip
pigz -f -c "$RAMDISK_CPIO" > "$RAMDISK_GZ" 2>/dev/null || \
gzip -f -c "$RAMDISK_CPIO" > "$RAMDISK_GZ"

log_info "Ramdisk gzip: $(stat -c%s "$RAMDISK_GZ") bytes"

# Step 3: Pack boot.img
log_step "Creating boot.img..."

# Prefer mkbootimg (from android-tools-mkbootimg)
if command -v mkbootimg &> /dev/null; then
    mkbootimg \
        --kernel "$KERNEL_WITH_DTB" \
        --ramdisk "$RAMDISK_GZ" \
        --base "$KERNEL_BASE" \
        --pagesize "$KERNEL_PAGESIZE" \
        --kernel_offset "$KERNEL_BASE" \
        --ramdisk_offset "$RAMDISK_OFFSET" \
        --tags_offset "$KERNEL_TAGS_OFFSET" \
        --cmdline "$CMDLINE" \
        --output "$OUTPUT"

    log_info "boot.img created with mkbootimg"

# Fallback to abootimg
elif command -v abootimg &> /dev/null; then
    # abootimg uses different parameter names
    abootimg \
        --create "$OUTPUT" \
        -k "$KERNEL_WITH_DTB" \
        -r "$RAMDISK_GZ" \
        -c "pagesize = $KERNEL_PAGESIZE" \
        -c "kerneladdr = $KERNEL_BASE" \
        -c "ramdiskaddr = $RAMDISK_OFFSET" \
        -c "tagsaddr = $KERNEL_TAGS_OFFSET" \
        -c "cmdline = $CMDLINE"

    log_info "boot.img created with abootimg"

else
    log_error "Neither mkbootimg nor abootimg found!"
    log_info "Install with: sudo apt install android-tools-mkbootimg"
    exit 1
fi

# Verify output
if [[ -f "$OUTPUT" ]]; then
    SIZE=$(stat -c%s "$OUTPUT")
    log_step "Success!"
    log_info "Output: $OUTPUT"
    log_info "Size: $SIZE bytes ($(echo "scale=2; $SIZE / 1024 / 1024" | bc) MB)"
    
    # Validate size against partition limit
    if [[ $SIZE -gt 33554432 ]]; then
        log_warn "boot.img ($SIZE bytes) exceeds BOOT partition size (33554432 bytes = 32MB)!"
        log_warn "Try stripping kernel modules or compressing more aggressively."
    else
        log_info "Size OK - fits in 32MB BOOT partition"
    fi
    
    # Generate checksums
    sha256sum "$OUTPUT" > "${OUTPUT}.sha256"
    md5sum "$OUTPUT" > "${OUTPUT}.md5"
    log_info "Checksums saved"
else
    log_error "boot.img was not created!"
    exit 1
fi

# Print heimdall flash command
log_step "Next steps:"
log_info "Flash with: heimdall flash --BOOT $OUTPUT"
log_info "Or use the web installer: https://g7qispjjjjky4.kimi.page"
