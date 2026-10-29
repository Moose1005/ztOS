#!/bin/bash
#
# ztOS herolight Kernel Build Script
# Samsung Galaxy S7 (SM-G930W8) - Exynos 8890
#
# Usage:
#   ./build-herolight.sh [target]
#
# Targets:
#   boot        - Build boot.img (kernel + dtb + initramfs)
#   dtb         - Build device tree blob only
#   modules     - Build loadable kernel modules
#   clean       - Clean build artifacts
#   menuconfig  - Interactive kernel configuration
#
# Prerequisites:
#   - aarch64-linux-gnu-gcc toolchain
#   - mkimage (u-boot-tools)
#   - dtb compiler (dtc)
#   - bootimg tool or mkbootimg

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="${SCRIPT_DIR}/linux"
BUILD_DIR="${SCRIPT_DIR}/build"
OUT_DIR="${SCRIPT_DIR}/out"
DTS_DIR="${SCRIPT_DIR}/arch/arm64/boot/dts/samsung"

# Toolchain
CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"
ARCH="arm64"

# Device config
DEVICE="herolight"
SOC="exynos8890"
BOARD="samsung,${DEVICE}"

# Build configuration
JOBS=$(nproc)
KERNEL_VERSION="7.1.0"
LOCALVERSION="-ztos-herolight"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    echo "Usage: $0 [target]"
    echo ""
    echo "Targets:"
    echo "  boot        Build boot.img (default)"
    echo "  dtb         Build device tree blob"
    echo "  modules     Build loadable modules"
    echo "  clean       Clean build artifacts"
    echo "  menuconfig  Interactive configuration"
    echo "  check       Check prerequisites"
    echo ""
    echo "Environment:"
    echo "  CROSS_COMPILE    Path to toolchain prefix (default: aarch64-linux-gnu-)"
    echo "  KERNEL_DIR       Path to kernel source (default: ./linux)"
    echo ""
    exit 1
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=0
    
    # Check toolchain
    if ! command -v "${CROSS_COMPILE}gcc" &> /dev/null; then
        log_error "Toolchain not found: ${CROSS_COMPILE}gcc"
        log_info "Install with: sudo apt install gcc-aarch64-linux-gnu"
        missing=1
    fi
    
    # Check dtc
    if ! command -v dtc &> /dev/null; then
        log_error "Device tree compiler not found"
        log_info "Install with: sudo apt install device-tree-compiler"
        missing=1
    fi
    
    # Check kernel source
    if [ ! -d "${KERNEL_DIR}" ]; then
        log_warn "Kernel source not found at ${KERNEL_DIR}"
        log_info "Clone with: git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git ${KERNEL_DIR}"
        log_info "Or symlink your existing kernel tree"
        missing=1
    fi
    
    # Check mkimage
    if ! command -v mkimage &> /dev/null; then
        log_warn "mkimage not found (needed for uImage)"
        log_info "Install with: sudo apt install u-boot-tools"
    fi
    
    if [ $missing -eq 1 ]; then
        exit 1
    fi
    
    log_info "All prerequisites satisfied"
}

setup_directories() {
    mkdir -p "${BUILD_DIR}"
    mkdir -p "${OUT_DIR}"
}

copy_dts_files() {
    log_info "Copying device tree files to kernel source..."
    
    local kernel_dts_dir="${KERNEL_DIR}/arch/arm64/boot/dts/samsung"
    mkdir -p "${kernel_dts_dir}"
    
    cp "${DTS_DIR}/exynos8890.dtsi" "${kernel_dts_dir}/"
    cp "${DTS_DIR}/exynos8890-herolight.dts" "${kernel_dts_dir}/"
    
    log_info "Device tree files copied"
}

build_dtb() {
    log_info "Building device tree blob for ${DEVICE}..."
    
    copy_dts_files
    
    cd "${KERNEL_DIR}"
    
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} \
        exynos8890-herolight.dtb \
        -j${JOBS}
    
    cp "arch/arm64/boot/dts/samsung/exynos8890-herolight.dtb" \
       "${OUT_DIR}/dtb"
    
    log_info "DTB built: ${OUT_DIR}/dtb"
}

build_kernel() {
    log_info "Building kernel for ${DEVICE}..."
    
    cd "${KERNEL_DIR}"
    
    # Use our defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} \
        O="${BUILD_DIR}" \
        exynos8890_herolight_defconfig
    
    # Build kernel image
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} \
        O="${BUILD_DIR}" \
        -j${JOBS} \
        Image.gz
    
    cp "${BUILD_DIR}/arch/arm64/boot/Image.gz" "${OUT_DIR}/kernel.gz"
    
    log_info "Kernel built: ${OUT_DIR}/kernel.gz"
}

build_modules() {
    log_info "Building kernel modules..."
    
    cd "${KERNEL_DIR}"
    
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} \
        O="${BUILD_DIR}" \
        -j${JOBS} \
        modules
    
    # Install modules to a staging directory
    local modules_dir="${OUT_DIR}/modules"
    mkdir -p "${modules_dir}"
    
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} \
        O="${BUILD_DIR}" \
        INSTALL_MOD_PATH="${modules_dir}" \
        modules_install
    
    log_info "Modules built and installed to ${modules_dir}"
}

build_bootimg() {
    log_info "Building boot.img for ${DEVICE}..."
    
    build_kernel
    build_dtb
    
    local kernel="${OUT_DIR}/kernel.gz"
    local dtb="${OUT_DIR}/dtb"
    local bootimg="${OUT_DIR}/boot.img"
    
    # Check if we have initramfs
    local initramfs=""
    if [ -f "${SCRIPT_DIR}/initramfs.cpio.gz" ]; then
        initramfs="--ramdisk ${SCRIPT_DIR}/initramfs.cpio.gz"
        log_info "Using initramfs: ${SCRIPT_DIR}/initramfs.cpio.gz"
    else
        log_warn "No initramfs found. Boot image will have no ramdisk."
        log_info "Create one with: ./scripts/build-initramfs.sh"
    fi
    
    # Concatenate kernel + dtb for appended dtb format
    cat "${kernel}" "${dtb}" > "${OUT_DIR}/kernel-dtb"
    
    # Build boot image using mkbootimg or similar
    if command -v mkbootimg &> /dev/null; then
        mkbootimg \
            --kernel "${OUT_DIR}/kernel-dtb" \
            ${initramfs} \
            --base 0x80000000 \
            --pagesize 2048 \
            --cmdline "console=ttySAC0,115200n8 root=/dev/sda25 rw rootwait init=/sbin/init" \
            -o "${bootimg}"
    elif command -v abootimg &> /dev/null; then
        abootimg --create "${bootimg}" \
            -k "${OUT_DIR}/kernel-dtb" \
            ${initramfs:+-r ${SCRIPT_DIR}/initramfs.cpio.gz} \
            -c "pagesize = 2048" \
            -c "kerneladdr = 0x80008000" \
            -c "ramdiskaddr = 0x82000000" \
            -c "cmdline = console=ttySAC0,115200n8 root=/dev/sda25 rw rootwait"
    else
        log_warn "No boot image tool found. Raw kernel+dtb available at ${OUT_DIR}/kernel-dtb"
        log_info "Install mkbootimg (android-tools-mkbootimg) or abootimg"
        return 1
    fi
    
    log_info "Boot image built: ${bootimg}"
    
    # Print info
    ls -lh "${bootimg}"
}

clean_build() {
    log_info "Cleaning build artifacts..."
    
    if [ -d "${BUILD_DIR}" ]; then
        rm -rf "${BUILD_DIR}"
    fi
    
    if [ -d "${OUT_DIR}" ]; then
        rm -rf "${OUT_DIR}"
    fi
    
    log_info "Clean complete"
}

menu_config() {
    log_info "Opening menuconfig..."
    
    cd "${KERNEL_DIR}"
    
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} \
        O="${BUILD_DIR}" \
        exynos8890_herolight_defconfig
    
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} \
        O="${BUILD_DIR}" \
        menuconfig
    
    # Save custom config
    cp "${BUILD_DIR}/.config" "${SCRIPT_DIR}/exynos8890_herolight_defconfig"
    log_info "Configuration saved to ${SCRIPT_DIR}/exynos8890_herolight_defconfig"
}

# Main
case "${1:-boot}" in
    check)
        check_prerequisites
        ;;
    boot|bootimg)
        check_prerequisites
        setup_directories
        build_bootimg
        ;;
    dtb)
        check_prerequisites
        setup_directories
        build_dtb
        ;;
    kernel)
        check_prerequisites
        setup_directories
        build_kernel
        ;;
    modules)
        check_prerequisites
        setup_directories
        build_modules
        ;;
    menuconfig)
        check_prerequisites
        setup_directories
        menu_config
        ;;
    clean)
        clean_build
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        log_error "Unknown target: $1"
        usage
        ;;
esac

log_info "Done!"
