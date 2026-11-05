#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# PixelOS product definition.
#
# PixelOS names its products custom_<device> and breakfast/lunch call
# "lunch custom_$target": vendor/custom/build/envsetup.sh line 59. The common
# product config lives in vendor/custom/config, which chains into both
# vendor/lineage/config and vendor/custom/config.
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# The stock firmware builds its system image as the Samsung "qssi_64" target
# while every other partition is built for a36xq. Keep that split so the
# system partition identifies itself the same way the vendor blobs expect.
PRODUCT_SYSTEM_NAME := a36xqnsxx
PRODUCT_SYSTEM_DEVICE := qssi_64

# Inherit from a36xq device
$(call inherit-product, device/samsung/a36xq/device.mk)

# Inherit some common PixelOS stuff.
$(call inherit-product, vendor/custom/config/common_full_phone.mk)

# Boot animation
TARGET_BOOT_ANIMATION_RES := 1080
TARGET_SCREEN_HEIGHT := 2340
TARGET_SCREEN_WIDTH := 1080

# Device identifier. This must come after all inclusions.
PRODUCT_NAME := custom_a36xq
PRODUCT_DEVICE := a36xq
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-A366E
PRODUCT_MANUFACTURER := samsung

PRODUCT_GMS_CLIENTID_BASE := android-samsung-ss

# Vendor fingerprint (stock A366EXXUCDZIF)
PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="a36xqnsxx-user 17 CP2A.260605.016 A366EXXUCDZIF release-keys" \
    BuildFingerprint=samsung/a36xqnsxx/qssi_64:17/CP2A.260605.016/A366EXXUCDZIF:user/release-keys
