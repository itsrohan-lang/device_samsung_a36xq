# Device Tree for the Samsung Galaxy A36 5G (SM-A366E / a36xq)

LineageOS-style device configuration for the Samsung Galaxy A36 5G.

| Feature | Value |
| :--- | :--- |
| Codename | `a36xq` |
| Model | SM-A366E (INS) |
| SoC | Qualcomm Snapdragon 6 Gen 3 (`SM6475-AB`), platform `parrot` |
| Architecture | arm64 + arm (armv8-2a, dotprod) |
| Kernel | Prebuilt GKI `6.6.118-android15-8-…-4k` |
| Boot header | v4 (`boot`, `init_boot`, `vendor_boot`, `dtbo`) |
| Partition scheme | Virtual A/B, dynamic partitions, group `qti_dynamic_partitions` |
| Filesystems | EROFS for every read-only partition, F2FS for `/data` |
| Stock firmware | `A366EXXUCDZIF` / Android 17 (OneUI 9), SPL 2026-09-05 |
| Density | 450 dpi |

## Layout

```
BoardConfig.mk            board/kernel/partition/AVB configuration
device.mk                 product packages, ramdisk files, permissions
lineage_a36xq.mk          product definition
board-info.txt            OTA board assert (parrot)
proprietary-files.txt     blob manifest (drives extract-files.py)
configs/config.fs         filesystem ownership/capabilities
configs/vintf/            device manifest + compatibility matrix
overlay/                  legacy device overlays
prebuilts/                prebuilt kernel, DTB chain, dtbo, dlkm modules
rootdir/                  init scripts, init rc files, fstab
sepolicy/vendor/          device sepolicy
tools/validate_dt.py      static consistency checker (run this first)
```

## Blob model

This is a **QSSI / prebuilt-vendor** tree, not a source-built one:

* `system`, `system_ext`, `product`, `system_dlkm` are built from LineageOS sources.
* `vendor`, `odm`, `vendor_dlkm` come from the stock firmware through
  `vendor/samsung/a36xq` (`proprietary-files.txt` → `extract-files.py`).
* Therefore **no Qualcomm HAL may be built from source here**. Anything the
  stock vendor image already ships a binary for must not be added to
  `PRODUCT_PACKAGES`, or the build fails with a duplicate-install error.

`tools/validate_dt.py` enforces that last rule.

## Building

```bash
# 1. put the tree in place
#    device/samsung/a36xq          <- this repository
#    vendor/samsung/a36xq          <- blob tree (extract-files.py)
#    vendor/samsung/camera         <- SamsungCamera

# 2. sanity check the tree (no AOSP checkout needed)
python3 device/samsung/a36xq/tools/validate_dt.py

# 3. build
source build/envsetup.sh
lunch lineage_a36xq-userdebug
mka bacon
```

## Extracting blobs

```bash
cd device/samsung/a36xq
./extract-files.py /path/to/dump
```

The dump needs `system`, `vendor`, `product`, `odm`, `system_ext`,
`system_dlkm` and `vendor_dlkm` extracted. Note that
`vendor/etc/permissions/` is **not** picked up by `extract-files.py`; those 47
XMLs were restored by hand and are listed at the end of `proprietary-files.txt`.

## Recovering the values in BoardConfig.mk

Every hard-coded number can be re-derived from the stock firmware:

```bash
# partition sizes, fs types, AB partition list, super group name
unzip -p meta-data/fota.zip META/misc_info.txt
unzip -p meta-data/fota.zip META/dynamic_partitions_info.txt
unzip -p meta-data/fota.zip META/ab_partitions.txt

# kernel cmdline, bootconfig, offsets, board name
unpack_bootimg --boot_img vendor_boot.img --out vendor_boot_out
```

## Known limitations

See `dt-audit.md` for the full list. The two big ones are:

1. **17 Samsung/QTI HAL domains are `permissive`.** The stock vendor init
   scripts carry no `seclabel`, so every HAL's domain comes from the exec label
   of its binary. 19 binaries reuse existing AOSP/QTI domains; 17 Samsung-only
   services got new domains that are permissive on purpose so they log instead
   of blocking boot. Tighten them with `adb shell dmesg | grep avc`.
2. **The stock `super` image is Samsung-signed.** Flashing a self-built `super`
   needs an unlocked bootloader and `fastbootd`/Odin — and the AVB footer is
   signed with the AOSP test key, not Samsung's.

## Copyright

SPDX-FileCopyrightText: The LineageOS Project

SPDX-License-Identifier: Apache-2.0
