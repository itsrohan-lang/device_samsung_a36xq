#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from a36xq device
$(call inherit-product, device/samsung/a36xq/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_DEVICE := a36xq
PRODUCT_NAME := lineage_a36xq
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-A366E
PRODUCT_MANUFACTURER := samsung

PRODUCT_GMS_CLIENTID_BASE := android-samsung-ss

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="a36xqnsxx-user 17 CP2A.260605.016 A366EXXUCDZIF release-keys" \
    BuildFingerprint=samsung/a36xqnsxx/qssi_64:17/CP2A.260605.016/A366EXXUCDZIF:user/release-keys
