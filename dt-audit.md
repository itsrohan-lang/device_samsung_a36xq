# a36xq device tree audit

What was wrong with the tree as it stood, what it was changed to, and what
evidence each change is based on.

Reference trees used for conventions:

* `LineageOS/android_device_samsung_a73xq` (lineage-23.2) and
  `android_device_samsung_sm7325-common` — Samsung QSSI / prebuilt-blob layout.
* `kunzite-stuff/device_xiaomi_kunzite` — same `parrot`/SM6475 SoC, GKI 6.6,
  `qti_dynamic_partitions`, module handling.

Ground truth for every device-specific value:
`fota.zip` → `META/misc_info.txt`, `META/dynamic_partitions_info.txt`,
`META/ab_partitions.txt`, plus the `boot.img` / `vendor_boot.img` headers.

---

## Fixed

| # | Problem | Was | Now | Evidence |
|---|---|---|---|---|
| 1 | Invalid VINTF manifest | `<manifest version="None" type="None" target-level="None">` — would fail `assemble_vintf` / boot-time VINTF check | Real device manifest in `configs/vintf/manifest.xml` declaring `vendor.samsung.hardware.bluetooth` + `<sepolicy>` version | stock `vendor/etc/vintf/manifest_parrot.xml` |
| 2 | No device compatibility matrix | absent (and not in the blob list either) | `configs/vintf/compatibility_matrix.xml` + `DEVICE_MATRIX_FILE` | stock `vendor/etc/vintf/compatibility_matrix.xml` |
| 3 | Wrong dynamic-partition group | `samsung_dynamic_partitions` / `BOARD_SAMSUNG_DYNAMIC_PARTITIONS_*` | `qti_dynamic_partitions` / `BOARD_QTI_DYNAMIC_PARTITIONS_*` | `dynamic_partitions_info.txt: super_partition_groups=qti_dynamic_partitions` |
| 4 | `super` group size | `14675869696` (unchanged, correct) | kept, now documented | same file |
| 5 | `boot.img` size | `100597760` | `100663296` | `misc_info.txt: boot_size=100663296` |
| 6 | `vendor_boot.img` size | `134217728` | `100663296` | `misc_info.txt: vendor_boot_size=0x06000000` |
| 7 | `BOARD_FLASH_BLOCK_SIZE` | `262144` | `131072` | `misc_info.txt: blocksize=131072` |
| 8 | DTB placed in `boot.img` | `BOARD_MKBOOTIMG_ARGS += --dtb …` with header v4 — `mkbootimg` rejects a dtb in a v4 boot image | `BOARD_INCLUDE_DTB_IN_BOOTIMG` + `BOARD_PREBUILT_DTBIMAGE_DIR`, which puts the dtb in **vendor_boot** only | `build/make/core/Makefile` lines 1305‑1309 and 1684‑1690 |
| 9 | Contradictory DTB flags | `BOARD_INCLUDE_DTB_IN_BOOTIMG := true` then blanked, `BOARD_KERNEL_SEPARATED_DTBO := true` then blanked | set once, consistently | — |
| 10 | Recovery completely misconfigured | `BOARD_USES_RECOVERY_AS_BOOT := true`, `recovery` in `AB_OTA_PARTITIONS`, no `BOARD_RECOVERYIMAGE_PARTITION_SIZE` | recovery ramdisk moved into `vendor_boot` (`BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT` + `BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT`), `recovery` dropped from A/B | `misc_info.txt: no_recovery=true`; stock fstab has no usable recovery partition |
| 11 | Kernel modules not wired at all | nothing → `vendor_dlkm` would be empty (no display, Wi‑Fi, camera, touch) | `BOARD_VENDOR_KERNEL_MODULES*` from `prebuilts/modules/vendor_dlkm`, `BOARD_USES_VENDOR_DLKMIMAGE`, `BOARD_SYSTEM_DLKM_SRC` for `system_dlkm` | `misc_info.txt: vendor_dlkm_fs_type=erofs`; blob list has zero `vendor_dlkm/` entries |
| 12 | All partitions built as ext4 | no `BOARD_*IMAGE_FILE_SYSTEM_TYPE` at all | every read-only partition set to `erofs`, `/data` to `f2fs` | all unpacked images probe as `erofs@1024` |
| 13 | Missing platform flags | no `BOARD_USES_QCOM_HARDWARE`, no `BOARD_VENDOR`, no metadata partition, no `TARGET_FS_CONFIG_GEN`, no `TARGET_USES_MKE2FS` | all added | sm7325-common / a73xq conventions, stock fstab uses `/metadata` |
| 14 | BoardConfig referenced non-existent files | `system_dlkm.prop`, `odm_dlkm.prop`, `vendor_dlkm.prop` (never existed) | references removed | `ls *.prop` |
| 15 | Cuttlefish HAL in a phone tree | `android.hardware.health-service.cuttlefish{,_recovery}` | removed — the stock vendor ships `vendor.samsung.hardware.health-service` | `vendor/bin/hw/` |
| 16 | Duplicate boot-control HAL | `android.hardware.boot-service.default{,.recovery}` | removed — stock ships `android.hardware.boot-service.qti` | `vendor/bin/hw/`, `proprietary-files.txt` |
| 17 | Non-existent package | `sehradiomanager` | removed | not defined in any tree, vendor `Android.bp` has no such module |
| 18 | Duplicate package | `secril_config_svc` listed *and* shipped as a prebuilt vendor module | removed from `device.mk` | `vendor_samsung_a36xq/Android.bp` |
| 19 | Audio HAL collision | `audio.r_submix.default`, `audio.usb.default`, `audio.bluetooth.default` built while the same `.so` paths are blobs | removed | `proprietary-files.txt: vendor/lib64/hw/audio.*.default.so` |
| 20 | 47 permission XMLs never extracted | `vendor/etc/permissions/*` missing from the blob list → camera/wifi/NFC/sensor/touch/telephony features absent on a built vendor image | restored into `vendor_samsung_a36xq` + `proprietary-files.txt` + `a36xq-vendor.mk` | stock `vendor/etc/permissions/` (48 files, `handheld_core_hardware.xml` skipped: framework provides it) |
| 21 | `fstab.emmc` installed twice | tree `prebuilt_etc` → `/vendor/etc/fstab.emmc` **and** the same path is a blob | blob excluded with `-vendor/etc/fstab.emmc` | `proprietary-files.txt:1796` |
| 22 | sysfs labelled via `file_contexts` | `/sys/class/sec/...` in `file_contexts` — never applies, sysfs has no xattrs | moved to `sepolicy/vendor/genfs_contexts` with `genfscon sysfs …` | SELinux semantics |
| 23 | 104 OneUI/Knox/GMS/build props shipped | `ro.slmk.*`, `security.*`, `ro.vendor.beluga.*`, `ro.config.ringtone*`, `ro.virtual_ab.*`, `ro.build.uuid`, `setupwizard.*`, `ro.com.google.*` … | pruned from `vendor.prop` (77) and `product.prop` (27) | build system owns these; OneUI-only |
| 24 | Build-generated props hard-coded | `ro.system_ext.build.uuid`, `ro.*build.version.sdk_full` | removed from `system_ext.prop` | generated by `build/make` |
| 25 | QSSI identity missing | product did not set the `qssi_64` system split | `PRODUCT_SYSTEM_NAME := a36xqnsxx`, `PRODUCT_SYSTEM_DEVICE := qssi_64` | stock `build.prop: ro.product.system.device=qssi_64` |
| 26 | Trailing backslash at end of `PRODUCT_PACKAGES` lists | `…vendor_modprobe.sh \` followed by a blank line | fixed | make continuation semantics |
| 27 | `TARGET_SCREEN_HEIGHT/WIDTH` in BoardConfig | set where nothing reads them | moved to `lineage_a36xq.mk` | a73xq convention |

---

## Added

* `board-info.txt` — `require board=parrot` (from the OTA `android-info.txt`).
* `configs/config.fs` — Samsung/QCOM file ownership, `efs` root folder, caps for
  `cnss-daemon`, `loc_launcher`, `pm-service`, `pd-mapper`, `adsprpcd`.
* `configs/vintf/manifest.xml`, `configs/vintf/compatibility_matrix.xml`.
* `prebuilts/dtbs/a36xq.dtb` — the stock FDT chain, byte-identical
  (`prebuilts/dtb.img` renamed; AOSP concatenates `*.dtb`, so one file keeps it
  exact).
* `prebuilts/modules/system_dlkm/lib/modules/` — restructured so
  `BOARD_SYSTEM_DLKM_SRC` reproduces the device layout.
* `sepolicy/vendor/genfs_contexts`.
* `tools/validate_dt.py` — static checker, no AOSP checkout required.

---

## Verified by `tools/validate_dt.py`

```
0 error(s), 0 warning(s)
blobs: 2311 entries, 1 exclusion, 2311 present in vendor tree
no install collisions between device tree and 2311 blobs
PRODUCT_PACKAGES: 55 unique, 8 not defined in-tree (NfcNci, Tag,
  com.android.nfc_extras, fastbootd, otapreopt_script, update_engine,
  update_engine_sideload, update_verifier - all AOSP/Lineage)
sepolicy: 22 .te files, 17 domains, 39 context types,
  0 unresolved, 0 duplicate domain(s)
```

---

## Round 2: HAL bring-up (sepolicy + audio)

The stock vendor init scripts carry **no `seclabel`** for the HAL services, so
every HAL's domain is derived from the SELinux label of its binary through
`init_daemon_domain()`. Checking all 59 prebuilt HAL binaries against AOSP and
QTI policy showed 19 were already labelled and **40 had no domain at all** -
those services could not start. That is the "no radio, no camera, bootloop at
init" failure mode.

* **19 binaries are mapped onto existing AOSP/QTI domains** whose interface they
  implement: health, power, lights, thermal, vibrator, camera, fingerprint,
  face, wifi, bluetooth, audio, dumpstate, weaver, mediacodec, display colour,
  capability config store, trusted UI and perf. They inherit a real, tight
  policy instead of a new empty one.
* **17 new domains** were defined for Samsung/QTI-only services: the five TLC
  trusted apps, DRK, SKPM, WSM, Widevine key provisioning, auth framework,
  HyPer, KHDM, mPOS, SNAP, sysinput, colour converter, display quality, MemHal,
  service tracker, `macloader` and `mfgloader`.
* Those 17 are **`permissive` during bring-up**: denials are logged instead of
  blocking boot. They must be tightened on a real device.
* `sepolicy/vendor/file_contexts` labels all 40 binaries.
* **Audio**: the tree now ships `configs/audio/audio_policy_configuration.xml`,
  a copy of the stock `audio_policy_configuration_base.xml`, because audioserver
  looks for the plain filename. The missing primary module is by design - the
  AIDL audio HAL hosts it (`vendor/etc/audio/audio_module_config_primary.xml`,
  stated in a comment in that very file). The stock `sku_*` variants are
  unusable on this device: they `xi:include` a
  `stub_audio_policy_configuration.xml` that does not exist anywhere in the
  firmware.

`tools/validate_dt.py` gained a sepolicy cross-check. Point `DSH_SEPOLICY_REFS`
at a directory containing `ref_sepolicy` (LineageOS, `lineage-23.0`) and
`ref_qcom_sepolicy` (`lineage-23.0-caf-sm8450`) to enable it:

```
sepolicy: 22 .te files, 17 domains, 39 context types,
          0 unresolved, 0 duplicate domain(s)
```

Without those checkouts the validator still checks internal consistency and
reports that the upstream cross-check was skipped.

---

## Still to do on-device

These are real gaps, not oversights - they need a device in hand.

1. **Tighten the bring-up policy.** The 17 new domains are `permissive`. Once the
   device boots, collect `adb shell dmesg | grep avc`, turn each denial into an
   `allow` rule and drop the `permissive` line. Also verify the 19 reused
   domains do not need Samsung-specific additions (battery/EFS/touch sysfs
   nodes are the common ones - `sepolicy/vendor/hal_*_default.te`).
2. **Paths the reused domains may still need.** `hal_power_default` on this
   device will want the Samsung touchscreen sysfs nodes
   (`sysfs_sec_touch`, already declared in `file.te`/`genfs_contexts`) and the
   Samsung battery nodes for `hal_health_default`. Expect to add a handful of
   `allow` lines there.

3. **Samsung framework HALs vs Lineage ones.** Power, lights, health, vibrator,
   fingerprint are all prebuilt Samsung services with their own `.rc` and
   `seclabel`. They must be trusted by the Lineage sepolicy; do not also build
   the AOSP equivalents.
4. **`super` flashing.** The stock `super.img` is wrapped in a Samsung
   `SignerVer02` header. A self-built `super` has no such wrapper; flashing it
   needs an unlocked bootloader plus `fastbootd`/Odin, and AVB is signed with
   the AOSP test key (`external/avb/test/data/testkey_rsa4096.pem`).
5. **`extract-files.py` round-trip.** Re-run it against the same dump and check
   that the 47 permission entries at the end of `proprietary-files.txt` survive;
   if not, keep them hand-maintained.
6. **`TARGET_CPU_VARIANT_RUNTIME := kryo300`.** Taken from kunzite (same SoC
   family) and from the other a36xq TWRP tree. If the toolchain rejects the
   `-mcpu` value, drop back to `generic`.
7. **`a36xq_defconfig` and the root `modules.load`** are leftovers from the
   kernel porting effort and are not referenced by the build; they are kept only
   as reference material.
8. **`pvmfw.img`** exists on the device (pKVM) but is not produced by the AOSP
   build; it is not listed in `AB_OTA_PARTITIONS` and is left untouched.
