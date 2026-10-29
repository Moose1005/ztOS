#
# Board configuration for Samsung Galaxy S7 (herolight)
# SM-G930W8 - Canadian variant, Exynos 8890
#

TARGET_BOARD_PLATFORM := exynos8890
TARGET_SOC := exynos8890
TARGET_BOOTLOADER_BOARD_NAME := universal8890

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a53

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a53

# Bootloader
TARGET_NO_BOOTLOADER := false
TARGET_NO_RADIOIMAGE := true

# Kernel
BOARD_KERNEL_BASE := 0x10000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_KERNEL_CMDLINE := console=ttySAC0,115200n8 androidboot.hardware=herolight
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
BOARD_KERNEL_IMAGE_NAME := Image.gz
BOARD_KERNEL_SEPARATED_DT := true
BOARD_CUSTOM_BOOTIMG_MK := device/samsung/herolight/mkbootimg.mk

# Kernel source
TARGET_KERNEL_SOURCE := kernel/samsung/exynos8890
TARGET_KERNEL_CONFIG := exynos8890_herolight_defconfig
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_CROSS_COMPILE_PREFIX := aarch64-linux-android-

# Partitions
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432        # 32MB
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 33554432    # 32MB
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 4294967296    # 4GB
BOARD_VENDORIMAGE_PARTITION_SIZE := 1073741824    # 1GB
BOARD_USERDATAIMAGE_PARTITION_SIZE := 57982058496 # ~54GB
BOARD_CACHEIMAGE_PARTITION_SIZE := 209715200      # 200MB
BOARD_FLASH_BLOCK_SIZE := 131072

# Filesystem
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Recovery
TARGET_RECOVERY_FSTAB := device/samsung/herolight/rootdir/etc/fstab.herolight
BOARD_HAS_DOWNLOAD_MODE := true
BOARD_HAS_LARGE_FILESYSTEM := true

# TWRP
RECOVERY_VARIANT := twrp
TW_THEME := portrait_hdpi
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel/brightness"
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 162
TW_NO_REBOOT_BOOTLOADER := false
TW_HAS_DOWNLOAD_MODE := true
TW_INCLUDE_NTFS_3G := true
TW_EXCLUDE_SUPERSU := true
TW_EXTRA_LANGUAGES := true
TW_USE_NEW_MINADBD := true
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_FBE := true

# Display
TARGET_SCREEN density := 640
TARGET_SCREEN_WIDTH := 1440
TARGET_SCREEN_HEIGHT := 2560

# Audio
BOARD_USES_ALSA_AUDIO := true

# Bluetooth
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_BCM := true
BOARD_CUSTOM_BT_CONFIG := device/samsung/herolight/bluetooth/vnd_herolight.txt

# Wi-Fi
BOARD_WLAN_DEVICE := bcmdhd
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_bcmdhd
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_bcmdhd
WIFI_DRIVER_FW_PATH_PARAM := "/sys/module/dhd/parameters/firmware_path"
WIFI_DRIVER_FW_PATH_STA := "/vendor/etc/wifi/bcmdhd_sta.bin"
WIFI_DRIVER_FW_PATH_AP := "/vendor/etc/wifi/bcmdhd_apsta.bin"
WIFI_HIDL_FEATURE_DUAL_INTERFACE := true

# Camera
BOARD_USE_SAMSUNG_CAMERAFORMAT_NV21 := true
TARGET_USES_MEDIA_EXTENSIONS := true

# Sensors
TARGET_NO_SENSOR_PERMISSION_CHECK := true

# Power
TARGET_POWERHAL_VARIANT := samsung

# Lights
TARGET_PROVIDES_LIBLIGHT := true

# Charger
BOARD_CHARGING_MODE_BOOTING_LPM := /sys/class/power_supply/battery/batt_lp_charging
BOARD_CHARGER_ENABLE_SUSPEND := true
BOARD_CHARGER_SHOW_PERCENTAGE := true
CHARGING_ENABLED_PATH := /sys/class/power_supply/battery/batt_lp_charging

# Security
BOARD_USES_TRUSTZONE := true
BOARD_SECCOMP_POLICY := device/samsung/herolight/seccomp

# Properties
TARGET_SYSTEM_PROP := device/samsung/herolight/system.prop

# SELinux
BOARD_SEPOLICY_DIRS += device/samsung/herolight/sepolicy

# VNDK
BOARD_VNDK_VERSION := current

# Dynamic partitions (not used on S7, but good for forward compatibility)
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false

# Vendor interface manifest
DEVICE_MANIFEST_FILE := device/samsung/herolight/manifest.xml
DEVICE_MATRIX_FILE := device/samsung/herolight/compatibility_matrix.xml
