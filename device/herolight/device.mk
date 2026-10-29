#
# Device-specific makefile for Samsung Galaxy S7 (herolight)
# SM-G930W8 - Canadian variant, Exynos 8890
#

# Inherit from exynos8890-common
$(call inherit-product, device/samsung/exynos8890-common/exynos8890-common.mk)

# Device identifier
PRODUCT_DEVICE := herolight
PRODUCT_NAME := ztos_herolight
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-G930W8
PRODUCT_MANUFACTURER := samsung
PRODUCT_GMS_CLIENTID_BASE := android-samsung

# Boot animation
TARGET_SCREEN_WIDTH := 1440
TARGET_SCREEN_HEIGHT := 2560
TARGET_BOOT_ANIMATION_RES := 1440

# Device overlays
DEVICE_PACKAGE_OVERLAYS += device/samsung/herolight/overlay

# Audio configuration
PRODUCT_COPY_FILES += \
    device/samsung/herolight/audio/audio_policy.conf:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy.conf \
    device/samsung/herolight/audio/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml \
    device/samsung/herolight/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml

# Bluetooth
PRODUCT_COPY_FILES += \
    device/samsung/herolight/bluetooth/bt_vendor.conf:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth/bt_vendor.conf

# GPS
PRODUCT_COPY_FILES += \
    device/samsung/herolight/gps/gps.conf:$(TARGET_COPY_OUT_VENDOR)/etc/gps.conf \
    device/samsung/herolight/gps/gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/gps.xml

# IDC (Input Device Configuration)
PRODUCT_COPY_FILES += \
    device/samsung/herolight/idc/sec_touchscreen.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/sec_touchscreen.idc

# Keylayouts
PRODUCT_COPY_FILES += \
    device/samsung/herolight/keylayout/gpio-keys.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/gpio-keys.kl \
    device/samsung/herolight/keylayout/sec_touchkey.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/sec_touchkey.kl

# Init files
PRODUCT_PACKAGES += \
    fstab.herolight \
    init.herolight.rc \
    init.herolight.usb.rc \
    init.recovery.herolight.rc \
    ueventd.herolight.rc

# Lights
PRODUCT_PACKAGES += \
    lights.herolight

# Power
PRODUCT_PACKAGES += \
    power.herolight

# Camera
PRODUCT_PACKAGES += \
    camera.exynos8890 \
    Snap

# Sensors
PRODUCT_PACKAGES += \
    sensors.herolight

# Thermal
PRODUCT_PACKAGES += \
    thermal.exynos8890

# Wi-Fi
PRODUCT_PACKAGES += \
    wpa_supplicant.conf \
    hostapd_default.conf \
    dhcpcd.conf

# NFC
PRODUCT_PACKAGES += \
    NfcNci \
    Tag \
    com.android.nfc_extras

# Fingerprint
PRODUCT_PACKAGES += \
    fingerprintd \
    fingerprint.herolight

# ztOS specific packages
PRODUCT_PACKAGES += \
    ztMETRO \
    zrnperfd \
    zrnlauncher \
    zrnupdate

# Properties
PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.first_api_level=23 \
    ro.opengles.version=196610 \
    debug.hwui.use_buffer_age=false \
    ro.sf.lcd_density=640 \
    ro.hardware.keystore=mdfpp \
    ro.hardware.gatekeeper=mdfpp

# Dalvik heap configuration
$(call inherit-product, frameworks/native/build/phone-xxxhdpi-4096-dalvik-heap.mk)

# HWUI memory configuration
$(call inherit-product, frameworks/native/build/phone-xxxhdpi-4096-hwui-memory.mk)

# Security patch level
PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.build.security_patch=2026-10-01
