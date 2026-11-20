#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Samsung Galaxy A36 5G (SM-A366E / a36xq)
# Platform: Qualcomm "parrot" (SM6475) - GKI 6.6, virtual A/B, QSSI blob layout
#
# All partition sizes, filesystem types, the dynamic-partition group name and
# the boot parameters below were read back from the device firmware:
#   * fota.zip -> META/misc_info.txt, META/dynamic_partitions_info.txt,
#                 META/ab_partitions.txt
#   * vendor_boot.img header (cmdline, bootconfig, offsets, board name)
#   * the unpacked erofs images (filesystem type)
#

DEVICE_PATH := device/samsung/a36xq

# Prebuilt-blob build workarounds
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# A/B (matches META/ab_partitions.txt; this device has no recovery partition)
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    init_boot \
    odm \
    product \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vendor \
    vendor_boot \
    vendor_dlkm

# APEX
DEXPREOPT_GENERATE_APEX_IMAGE := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo300

# 64-bit only. The stock firmware says so unambiguously:
#   dump/vendor/build.prop: ro.zygote=zygote64
#                           ro.vendor.product.cpu.abilist32=      (empty)
#                           ro.vendor.product.cpu.abilist64=arm64-v8a
# and it ships no 32-bit ARM userspace at all - the only file under vendor/lib/
# is rfsa/adsp/libdsp_streamer_binning.so, which is a Hexagon DSP object
# (ELF32, e_machine 164 = EM_HEXAGON), not 32-bit ARM code.
#
# A TARGET_2ND_ARCH here made the build emit arm variants of every
# "compile_multilib: both" module, which nothing on this device can load and
# which trip ILP32-only bugs in the QCOM HALs (LP64 code assumes %lu is 64-bit):
#
#   gr_snap_helper.cpp:1818:15: error: format specifies type 'unsigned long'
#   but the argument has type 'uint64_t' (aka 'unsigned long long')
#
# Leaving TARGET_2ND_ARCH unset removes those variants entirely.
TARGET_SUPPORTS_32_BIT_APPS := false
TARGET_SUPPORTS_64_BIT_APPS := true

# Platform
BOARD_VENDOR := samsung
TARGET_BOARD_PLATFORM := parrot
TARGET_BOOTLOADER_BOARD_NAME := parrot
TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true
TARGET_USES_UEFI := true

# Display
TARGET_SCREEN_DENSITY := 450
TARGET_USES_VULKAN := true

# Gralloc handle layout
#
# private_handle_t only carries reserved_size / custom_content_md_reserved_size
# when the matching qtidisplay Soong config variable is true, and the qcom-caf
# display sources use both fields unconditionally:
#
#   gr_utils.cpp:2213:43: error: no member named 'reserved_size' in
#   'qtigralloc::private_handle_t'
#
# Setting SOONG_CONFIG_qtidisplay_<key> is not enough on its own: build/make
# only serialises the keys that are also listed in SOONG_CONFIG_qtidisplay
# (see the VendorVars loop in build/make/core/soong_config.mk), everything else
# is dropped before Soong ever sees it. Since this tree does not inherit
# hardware/qcom-caf/common/BoardConfigQcom.mk - the file that normally declares
# the namespace and derives these values from TARGET_BOARD_PLATFORM - declare
# them here. SOONG_CONFIG_NAMESPACES and SOONG_CONFIG_<ns> are sorted, so a
# duplicate entry from a future caf_common include is harmless.
#
# TARGET_BOARD_PLATFORM is "parrot", which caf_common treats as UM 5.10: the two
# reserved fields are on and ubwcp_format is off.
#
# ubwcp_format stays off on purpose: none of the gralloc blobs we still ship
# (mapper.qti.so, libmapperutils.so, libgralloccore.so) reference ubwcp or link
# libubwcp, so the stock handle has no such field - adding it would change the
# ABI those blobs were built against.
TARGET_GRALLOC_HANDLE_HAS_RESERVED_SIZE := true
TARGET_GRALLOC_HANDLE_HAS_CUSTOM_CONTENT_MD_RESERVED_SIZE := true
TARGET_GRALLOC_HANDLE_HAS_UBWCP_FORMAT := false

SOONG_CONFIG_NAMESPACES += qtidisplay
SOONG_CONFIG_qtidisplay += \
    gralloc_handle_has_reserved_size \
    gralloc_handle_has_custom_content_md_reserved_size \
    gralloc_handle_has_ubwcp_format

SOONG_CONFIG_qtidisplay_gralloc_handle_has_reserved_size := true
SOONG_CONFIG_qtidisplay_gralloc_handle_has_custom_content_md_reserved_size := true
SOONG_CONFIG_qtidisplay_gralloc_handle_has_ubwcp_format := false
# The remaining qtidisplay keys that hardware/qcom-caf/common/BoardConfigQcom.mk
# declares with their defaults. This tree does not inherit that file, and
# build/make drops every key that is not listed in SOONG_CONFIG_qtidisplay.
# Without "default", qtidisplay_defaults does not add display_headers, so
# libqdutils/libqservice users cannot find QServiceUtils.h and QtiGralloc.h.
SOONG_CONFIG_qtidisplay += \
    composer_version \
    drmpp \
    headless \
    llvmsa \
    gralloc4 \
    displayconfig_enabled \
    udfps \
    default \
    master_side_cp \
    shift_horizontal \
    shift_vertical \
    smmu_proxy \
    var1 \
    var2 \
    var3 \
    hwasan \
    hw_fence_disabled \
    hy11 \
    hy22 \
    hy33

SOONG_CONFIG_qtidisplay_composer_version ?= v3_3
SOONG_CONFIG_qtidisplay_drmpp ?= false
SOONG_CONFIG_qtidisplay_headless ?= false
SOONG_CONFIG_qtidisplay_llvmsa ?= false
SOONG_CONFIG_qtidisplay_gralloc4 ?= false
SOONG_CONFIG_qtidisplay_displayconfig_enabled ?= false
SOONG_CONFIG_qtidisplay_udfps ?= false
SOONG_CONFIG_qtidisplay_default ?= true
SOONG_CONFIG_qtidisplay_master_side_cp ?= false
SOONG_CONFIG_qtidisplay_shift_horizontal ?= 0
SOONG_CONFIG_qtidisplay_shift_vertical ?= 0
SOONG_CONFIG_qtidisplay_smmu_proxy ?= false
SOONG_CONFIG_qtidisplay_var1 ?= false
SOONG_CONFIG_qtidisplay_var2 ?= false
SOONG_CONFIG_qtidisplay_var3 ?= false
SOONG_CONFIG_qtidisplay_hwasan ?= false
SOONG_CONFIG_qtidisplay_hw_fence_disabled ?= false
SOONG_CONFIG_qtidisplay_hy11 ?= false
SOONG_CONFIG_qtidisplay_hy22 ?= false
SOONG_CONFIG_qtidisplay_hy33 ?= false


DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += $(DEVICE_PATH)/framework_compatibility_matrix.xml

# Kernel (prebuilt GKI image, 6.6.118-android15-8-*-4k)
#
# build/make no longer knows TARGET_PREBUILT_KERNEL: a prebuilt kernel has to be
# installed to $(PRODUCT_OUT)/kernel itself, which is what the boot image rules
# consume. TARGET_NO_KERNEL_OVERRIDE stops the build from looking for a kernel
# target to build.
BOARD_USES_GENERIC_KERNEL_IMAGE := true
TARGET_NO_KERNEL_OVERRIDE := true
PRODUCT_COPY_FILES += $(DEVICE_PATH)/prebuilts/kernel:kernel

# Kernel UAPI headers
#
# Nothing builds a kernel from this tree - the boot image ships the prebuilt
# image above. TARGET_KERNEL_SOURCE is only read by Lineage's
# generated_kernel_includes generator, which runs `make headers_install` there
# and exports the result as usr/include{,/audio} to every module that declares
# header_libs: ["audio_kernel_headers", "qti_kernel_headers", ...] (for example
# hardware/qcom-caf/*/audio/graphservices/ar_osal). It has to point at a real
# kernel tree with a Makefile and include/uapi; the default
# $(TARGET_AUTO_KDIR) is our wrapper repo root, which has neither, so the
# generator would export nothing.
TARGET_KERNEL_SOURCE := kernel/samsung/a36xq/kernel_platform/msm-kernel

# The kernel repo carries kernel_samsung_a36xq/.find-ignore, so the generator's
# dep_files globs over that tree come back empty and none of its headers are
# real inputs of the generated_kernel_includes action. Bump this whenever the
# exported UAPI header set changes without the generator's command changing,
# otherwise ninja/siso treats the action as up to date and keeps the old
# usr/include tree in place.
TARGET_KERNEL_ADDITIONAL_FLAGS += A36XQ_KERNEL_UAPI_REV=3

BOARD_BOOT_HEADER_VERSION := 4
BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_RAMDISK_USE_LZ4 := true

# DTB
#
# Samsung ships the whole FDT chain as one blob (the exact bytes that sit in the
# stock vendor_boot dtb section). AOSP concatenates $(BOARD_PREBUILT_DTBIMAGE_DIR)/*.dtb
# into dtb.img, so keeping it as a single file makes the rebuilt vendor_boot
# byte-identical to the stock one. Do NOT split it into per-`dtb` files.
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilts/dtbs
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilts/dtbo.img
TARGET_NEEDS_DTBOIMAGE := true

# Kernel cmdline / bootconfig (verbatim from the stock vendor_boot header)
BOARD_KERNEL_CMDLINE := video=vfb:640x400,bpp=32,memsize=3072000 msm_geni_serial.con_enabled=0 printk.devkmsg=on firmware_class.path=/vendor/firmware_mnt/image bootconfig loop.max_part=7
BOARD_BOOTCONFIG := \
    androidboot.hardware=qcom \
    androidboot.memcg=1 \
    androidboot.usbcontroller=a600000.dwc3 \
    androidboot.load_modules_parallel=false \
    androidboot.serialconsole=0 \
    androidboot.vendor.qspa=true \
    androidboot.hypervisor.protected_vm.supported=true

# Offsets and board id taken from the stock vendor_boot header
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --kernel_offset 0x00008000
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset 0x02000000
BOARD_MKBOOTIMG_ARGS += --dtb_offset 0x01f00000
BOARD_MKBOOTIMG_ARGS += --board SRPXK11A012
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)

# Kernel modules
#
# The vendor_dlkm partition is rebuilt from the modules extracted out of the
# stock vendor_dlkm image; they must match the prebuilt kernel exactly.
VENDOR_DLKM_MODULES_PATH := $(DEVICE_PATH)/prebuilts/modules/vendor_dlkm

BOARD_USES_VENDOR_DLKMIMAGE := true
BOARD_USES_SYSTEM_DLKMIMAGE := true

BOARD_VENDOR_KERNEL_MODULES := $(wildcard $(VENDOR_DLKM_MODULES_PATH)/*.ko)
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(patsubst %,$(VENDOR_DLKM_MODULES_PATH)/%,$(shell cat $(VENDOR_DLKM_MODULES_PATH)/modules.load))
BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(VENDOR_DLKM_MODULES_PATH)/modules.blocklist

# Copied verbatim (build/make `BOARD_SYSTEM_DLKM_SRC`), preserving lib/modules/
BOARD_SYSTEM_DLKM_SRC := $(DEVICE_PATH)/prebuilts/modules/system_dlkm

# Partitions (META/misc_info.txt)
BOARD_BOOTIMAGE_PARTITION_SIZE := 100597760
BOARD_DTBOIMG_PARTITION_SIZE := 25165824
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 134217728
BOARD_FLASH_BLOCK_SIZE := 131072 # (blocksize=131072 in misc_info.txt)

# Dynamic partitions
#
# NOTE: the stock metadata uses the QTI group name - not the usual Samsung
# "samsung_dynamic_partitions" one. Keep it identical or the built super will
# not match the on-device metadata generated by the stock firmware.
BOARD_SUPER_PARTITION_SIZE := 14680064000
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system \
    system_dlkm \
    odm \
    system_ext \
    vendor \
    product \
    vendor_dlkm
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 14675869696 # (super - 4 MiB)

# File systems (every read-only partition is erofs on this device)
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs

BOARD_USES_METADATA_PARTITION := true
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USES_MKE2FS := true

TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM := system
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

# Filesystem config
TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/configs/config.fs
BOARD_ROOT_EXTRA_FOLDERS += efs

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/product.prop
TARGET_SYSTEM_EXT_PROP += $(DEVICE_PATH)/system_ext.prop
TARGET_ODM_PROP += $(DEVICE_PATH)/odm.prop

# Recovery
#
# misc_info.txt says no_recovery=true - recovery lives in the vendor_boot
# ramdisk, there is no dedicated recovery partition to build or OTA.
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.emmc
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888

# WiFi
BOARD_WLAN_DEVICE := qcwcn
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_WPA_SUPPLICANT_DRIVER := $(BOARD_HOSTAPD_DRIVER)
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := $(BOARD_HOSTAPD_PRIVATE_LIB)
BOARD_WPA_SUPPLICANT_PRIVATE_LIB_EVENT := "ON"
WIFI_DRIVER_STATE_CTRL_PARAM := "/dev/wlan"
WIFI_DRIVER_STATE_OFF := "OFF"
WIFI_DRIVER_STATE_ON := "ON"
WIFI_FEATURE_HOSTAPD_11AX := true
WIFI_HIDL_FEATURE_AWARE := true
WIFI_HIDL_FEATURE_DUAL_INTERFACE := true
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true
WPA_SUPPLICANT_VERSION := VER_0_8_X

# RIL
ENABLE_VENDOR_RIL_SERVICE := true

# SEPolicy
include device/qcom/sepolicy_vndr/SEPolicy.mk
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

# VINTF
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/configs/vintf/manifest.xml
DEVICE_MATRIX_FILE := $(DEVICE_PATH)/configs/vintf/compatibility_matrix.xml

# Security patch level
VENDOR_SECURITY_PATCH := 2026-09-05

# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

BOARD_AVB_ALGORITHM := SHA256_RSA4096
BOARD_AVB_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem

BOARD_AVB_BOOT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_BOOT_ROLLBACK_INDEX := 1
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 3

BOARD_AVB_VENDOR_BOOT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VENDOR_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX := 1
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX_LOCATION := 1

BOARD_AVB_VBMETA_SYSTEM := system system_ext product
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := 1
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

# Inherit the proprietary files
include vendor/samsung/a36xq/BoardConfigVendor.mk
