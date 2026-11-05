#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/custom_a36xq.mk \
    $(LOCAL_DIR)/lineage_a36xq.mk

COMMON_LUNCH_CHOICES := \
    custom_a36xq-user \
    custom_a36xq-userdebug \
    custom_a36xq-eng \
    lineage_a36xq-user \
    lineage_a36xq-userdebug \
    lineage_a36xq-eng
