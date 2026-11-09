#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Samsung Galaxy A36 5G (SM-A366E / a36xq)
#
# Model: the whole vendor side (HALs, firmware, configs) comes from the stock
# firmware through vendor/samsung/a36xq. The device tree therefore must NOT
# build the Qualcomm HALs from source - it only builds system/product/system_ext
# plus the ramdisk and the handful of vendor files listed below.
#

# Enable updating of APEXes
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

# A/B (ramdisk lives in vendor_boot)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=erofs \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

# API level
PRODUCT_SHIPPING_API_LEVEL := 35

# fastbootd
PRODUCT_PACKAGES += \
    fastbootd

# Kernel
PRODUCT_ENABLE_UFFD_GC := true

# Overlays (legacy device overlays)
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay
PRODUCT_ENFORCE_RRO_TARGETS := *

# Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_BUILD_SUPER_PARTITION := true

# Product characteristics
PRODUCT_CHARACTERISTICS := phone

# Init scripts and configuration
PRODUCT_PACKAGES += \
    coresight_reset_source_sink.sh \
    hdm_status.sh \
    init.class_main.sh \
    init.crda.sh \
    init.kernel.post_boot-parrot.sh \
    init.kernel.post_boot-ravelin.sh \
    init.kernel.post_boot.sh \
    init.mdm.sh \
    init.qcom.class_core.sh \
    init.qcom.coex.sh \
    init.qcom.early_boot.sh \
    init.qcom.efs.sync.sh \
    init.qcom.post_boot.sh \
    init.qcom.sdio.sh \
    init.qcom.sensors.sh \
    init.qcom.sh \
    init.qcom.usb.sh \
    init.qti.kernel.debug-parrot.sh \
    init.qti.kernel.debug-ravelin.sh \
    init.qti.kernel.debug.sh \
    init.qti.kernel.early_debug-parrot.sh \
    init.qti.kernel.early_debug.sh \
    init.qti.kernel.sh \
    init.qti.media.sh \
    init.qti.qcv.sh \
    init.qti.write.sh \
    init.vendor.sensordebug.sh \
    qca6234-service.sh \
    start_subsys.sh \
    system_dlkm_modprobe.sh \
    vendor_modprobe.sh

PRODUCT_PACKAGES += \
    fstab.emmc \
    fstab.emmc.ramdisk \
    fstab.qcom.ramdisk \
    init.a36xq.rc \
    init.qcom.factory.rc \
    init.qcom.rc \
    init.qcom.usb.rc \
    init.qti.kernel.rc \
    init.qti.kernel.target.rc \
    init.qti.ss-ramdump.sh \
    init.qti.ufs.rc \
    init.samsung.bsp.rc \
    init.samsung.display.rc \
    init.samsung.power.rc \
    init.samsung.rc \
    init.target.rc

# Audio
#
# The stock vendor only ships audio_policy_configuration_base.xml; audioserver
# looks for audio_policy_configuration.xml. The base file is a complete policy -
# the primary module is deliberately absent because it is hosted by the AIDL
# audio HAL itself (vendor/etc/audio/audio_module_config_primary.xml), which is
# also why the sku_* variants (broken include of a stub that does not exist on
# the device) are not used here.
PRODUCT_PACKAGES += \
    libaudioplatformconverter.qti \
    libdownmixaidl

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    vendor/samsung/a36xq \
    vendor/samsung/camera \
    hardware/qcom-caf/sm8450-6.6 \
    hardware/qcom-caf/wlan \
    hardware/qcom-caf/wlan/qcwcn \
    hardware/qcom-caf/common/libqti-perfd-client \
    vendor/qcom/opensource/dataservices

# Permissions
#
# Most device feature permissions ship inside the stock vendor image
# (vendor/etc/permissions). Only the ones the stock tree does not carry are
# added here - never copy a file to a path a blob already occupies, the build
# fails on the duplicate.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.audio.pro.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.pro.xml \
    frameworks/native/data/etc/android.hardware.camera.concurrent.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.concurrent.xml \
    frameworks/native/data/etc/android.hardware.camera.raw.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.raw.xml \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.telephony.ims.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.ims.xml \
    frameworks/native/data/etc/android.hardware.telephony.ims.singlereg.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.ims.singlereg.xml

# Wi-Fi
#
# These are built from source (external/wpa_supplicant_8,
# hardware/interfaces/wifi/aidl/default) so they match the AIDL versions this
# ROM ships. The stock Samsung binaries declare older AIDL revisions and cannot
# be mixed into the same build graph.
PRODUCT_PACKAGES += \
    android.hardware.wifi-service \
    hostapd \
    hostapd_cli \
    wpa_cli \
    wpa_supplicant

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm-service.clearkey

# Sensors
#
# libsensorndkbridge is provided by frameworks/hardware/interfaces; building it
# from source keeps the sensors AIDL version consistent with the rest of the ROM.
PRODUCT_PACKAGES += \
    android.hardware.sensors-service.multihal \
    libsensorndkbridge
    

# NFC
PRODUCT_PACKAGES += \
    NfcNci \
    Tag \
    com.android.nfc_extras

# Samsung Camera (vendor/samsung/camera)
$(call inherit-product-if-exists, vendor/samsung/camera/camera.mk)

# Inherit the proprietary files
$(call inherit-product, vendor/samsung/a36xq/a36xq-vendor.mk)
