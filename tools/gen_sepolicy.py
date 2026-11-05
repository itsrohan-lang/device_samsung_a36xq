#!/usr/bin/env python3
"""
Generate (or verify) the SELinux labelling for the prebuilt a36xq HALs.

The stock vendor init scripts carry no `seclabel`, so every HAL's domain is
derived from the exec label of its binary. This script holds the binary ->
domain mapping, checks it against the dump, and can rewrite
`sepolicy/vendor/file_contexts` and the domain `.te` files.

Usage:
    python tools/gen_sepolicy.py /path/to/dump            # verify only
    python tools/gen_sepolicy.py /path/to/dump --write    # regenerate files
    DSH_SEPOLICY_REFS=/path/to/refs python tools/gen_sepolicy.py /path/to/dump

`/path/to/dump` is the directory holding unpacked `vendor/`, `odm/`, ...
"""

import os
import re
import sys
import glob

HERE = os.path.dirname(os.path.abspath(__file__))
DT = os.path.dirname(HERE)
POL = os.path.join(DT, "sepolicy", "vendor")

# HAL binaries that already have a domain in AOSP or QTI policy. Reusing the
# upstream domain gives the service that domain's real, audited rules.
REUSE = {
    "android.hardware.bluetooth@aidl-service-qti": "hal_bluetooth_default",
    "android.hardware.dumpstate-service": "hal_dumpstate_default",
    "android.hardware.lights-service.samsung": "hal_light_default",
    "android.hardware.power.samsung-service": "hal_power_default",
    "android.hardware.weaver-service-spu-qti": "hal_weaver_default",
    "audiohalservice.qti": "hal_audio_default",
    "secaudiohalaidl": "hal_audio_default",
    "samsung.software.media.c2@1.0-service": "mediacodec",
    "vendor.qti.hardware.capabilityconfigstore-service": "vendor_hal_capabilityconfigstore_qti_default",
    "vendor.qti.hardware.display.color-service": "vendor_hal_display_color_default",
    "vendor.qti.hardware.trustedui-aidl-service-qti": "vendor_hal_trustedui_qti",
    "vendor.qti.hardware.perf2-hal-service": "vendor_hal_perf_default",
    "vendor.samsung.hardware.health-service": "hal_health_default",
    "vendor.samsung.hardware.biometrics.fingerprint-service": "hal_fingerprint_default",
    "vendor.samsung.hardware.biometrics.face-service": "hal_face_default",
    "vendor.samsung.hardware.camera.provider-service_64": "hal_camera_default",
    "vendor.samsung.hardware.thermal-service": "hal_thermal_default",
    "vendor.samsung.hardware.vibrator-service": "hal_vibrator_default",
    "vendor.samsung.hardware.wifi-service": "hal_wifi_default",
}

# Samsung/QTI-only services: new domains, permissive during bring-up.
NEW = {
    "macloader": ("macloader", "Samsung Wi-Fi MAC/BT address loader"),
    "mfgloader": ("mfgloader", "Samsung manufacturing mode loader"),
    "vendor.qti.MemHal-service": ("hal_memhal_qti", "QTI MemHal"),
    "vendor.qti.hardware.servicetrackeraidl-service": ("hal_servicetracker_qti", "QTI service tracker"),
    "vendor.samsung.hardware.authfw-service": ("hal_samsung_authfw_default", "Samsung auth framework"),
    "vendor.samsung.hardware.displayquality-service": ("hal_samsung_displayquality_default", "Samsung display quality"),
    "vendor.samsung.hardware.hyper-service": ("hal_samsung_hyper_default", "Samsung HyPer (hypervisor) service"),
    "vendor.samsung.hardware.khdm-service": ("hal_samsung_khdm_default", "Samsung KHDM"),
    "vendor.samsung.hardware.mpos-service": ("hal_samsung_mpos_default", "Samsung mPOS"),
    "vendor.samsung.hardware.security.drk-service": ("hal_samsung_drk_default", "Samsung DRK"),
    "vendor.samsung.hardware.security.skpm-service": ("hal_samsung_skpm_default", "Samsung SKPM"),
    "vendor.samsung.hardware.security.widevine.keyprov-service": ("hal_samsung_widevine_keyprov_default", "Samsung Widevine key provisioning"),
    "vendor.samsung.hardware.security.wsm-service": ("hal_samsung_wsm_default", "Samsung WSM"),
    "vendor.samsung.hardware.snap-service": ("hal_samsung_snap_default", "Samsung SNAP"),
    "vendor.samsung.hardware.sysinput-service": ("hal_samsung_sysinput_default", "Samsung sysinput"),
    "vendor.samsung.hardware.media.converter@1.0-service": ("hal_samsung_converter_default", "Samsung colour converter"),
    "vendor.samsung.hardware.tlc.blockchain-service": ("hal_samsung_tlc_default", "Samsung TLC trusted app (blockchain)"),
    "vendor.samsung.hardware.tlc.iccc-service": ("hal_samsung_tlc_default", "Samsung TLC trusted app (ICCC)"),
    "vendor.samsung.hardware.tlc.kg-service": ("hal_samsung_tlc_default", "Samsung TLC trusted app (KG)"),
    "vendor.samsung.hardware.tlc.payment-service": ("hal_samsung_tlc_default", "Samsung TLC trusted app (payment)"),
    "vendor.samsung.hardware.tlc.ucm-service": ("hal_samsung_tlc_default", "Samsung TLC trusted app (UCM)"),
}

TEMPLATE = """#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# {desc} ({bin})
#
# Bring-up policy: the prebuilt binary has no seclabel in its stock init .rc, so
# the domain is reached through the executable label below. The domain is
# permissive on purpose - it logs denials instead of blocking boot. Once the
# device boots, run `adb shell dmesg | grep avc` and replace this with real
# allow rules.
#

type {dom}, domain;
type {dom}_exec, exec_type, vendor_file_type, file_type;

init_daemon_domain({dom})

binder_use({dom})

allow {dom} vendor_file:file rx_file_perms;

permissive {dom};
"""

TYPE_RE = re.compile(r"^\s*type\s+([A-Za-z0-9_]+)\s*,\s*([^;]*);", re.M)


def upstream_types():
    refs = os.environ.get("DSH_SEPOLICY_REFS")
    if not refs:
        return None
    out = set()
    for sub in ("ref_sepolicy", "ref_qcom_sepolicy"):
        root = os.path.join(refs, sub)
        if not os.path.isdir(root):
            return None
        for p in glob.glob(os.path.join(root, "**", "*.te"), recursive=True):
            text = re.sub(r"#[^\n]*", "", open(p, encoding="utf-8", errors="replace").read())
            out.update(m.group(1) for m in TYPE_RE.finditer(text))
    return out


NOT_A_DOMAIN = {"vendor_file", "vendor_executable", "system_file", "system_executable"}


def upstream_fc_rules():
    """file_contexts regexes from the reference policy (most specific wins)."""
    refs = os.environ.get("DSH_SEPOLICY_REFS")
    if not refs:
        return None
    rules = []
    for sub in ("ref_sepolicy", "ref_qcom_sepolicy"):
        root = os.path.join(refs, sub)
        if not os.path.isdir(root):
            return None
        for p in glob.glob(os.path.join(root, "**", "file_contexts*"), recursive=True):
            if not os.path.isfile(p) or "test" in os.path.basename(p):
                continue
            for line in open(p, encoding="utf-8", errors="replace"):
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                parts = line.split()
                if len(parts) < 2:
                    continue
                try:
                    rules.append((re.compile("^" + parts[0] + "$"), parts[-1]))
                except re.error:
                    pass
    return rules


def upstream_label(binary, rules):
    best = None
    for d in ("/vendor/bin/hw/", "/vendor/bin/"):
        path = d + binary
        for rx, ctx in rules:
            if rx.match(path):
                if best is None or len(rx.pattern) > len(best[0].pattern):
                    best = (rx, ctx)
    if best is None:
        return None
    dom = best[1].split(":")[2]
    return None if dom in NOT_A_DOMAIN else dom


def fc_lines():
    lines = [f"/vendor/bin/hw/{re.escape(b)}" + " " * max(1, 62 - len(b))
             + f"u:object_r:{d}_exec:s0" for b, d in sorted(REUSE.items())]
    lines.append("")
    lines += [f"/vendor/bin/hw/{re.escape(b)}" + " " * max(1, 62 - len(b))
              + f"u:object_r:{d}_exec:s0" for b, (d, _) in sorted(NEW.items())]
    return lines


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    write = "--write" in sys.argv
    if not args:
        print(__doc__)
        return 2
    dump = args[0]
    hw = os.path.join(dump, "vendor", "bin", "hw")
    if not os.path.isdir(hw):
        print(f"error: {hw} not found")
        return 2

    bins = sorted(os.listdir(hw))
    mapped = set(REUSE) | set(NEW)
    rest = [b for b in bins if b not in mapped]
    stale = [b for b in mapped if b not in bins]

    rules = upstream_fc_rules()
    if rules is None:
        unlabelled, covered = [], rest
    else:
        covered = [b for b in rest if upstream_label(b, rules)]
        unlabelled = [b for b in rest if not upstream_label(b, rules)]

    print(f"HAL binaries in dump: {len(bins)}")
    print(f"mapped by this tree: {len(mapped)}  (reused domains {len(REUSE)}, "
          f"new domains {len(set(d for d, _ in NEW.values()))})")
    print(f"labelled by upstream policy: {len(covered)}")
    if rules is None:
        print("  (cannot verify without DSH_SEPOLICY_REFS - assumed covered)")
    for b in covered:
        if rules is not None:
            print(f"    {b:58} -> {upstream_label(b, rules)}")

    if unlabelled:
        print("\nUNLABELLED - these have no exec label and cannot start:")
        for b in unlabelled:
            print("  ", b)
    if stale:
        print("\nmapped but no longer present in the dump:")
        for b in stale:
            print("  ", b)

    up = upstream_types()
    if up is not None:
        bad = [b for b, d in REUSE.items() if d + "_exec" not in up]
        dup = [d for d in {d for d, _ in NEW.values()} if d in up]
        if bad:
            print("\nreused domains missing upstream exec type:")
            for b in bad:
                print("  ", b, "->", REUSE[b] + "_exec")
        if dup:
            print("\ndomains that would be declared twice:")
            for d in dup:
                print("  ", d)
        if not bad and not dup:
            print("\nupstream cross-check: all reused exec types exist, no duplicates")

    if not write:
        print("\n(dry run - pass --write to update sepolicy/vendor)")
        return 0 if not (unlabelled or stale) else 1

    fc = os.path.join(POL, "file_contexts")
    text = open(fc, encoding="utf-8").read()
    marker = "# Reused AOSP/QTI domains"
    head = text.split(marker)[0].rstrip() + "\n\n" if marker in text else text.rstrip() + "\n\n"
    body = "# Reused AOSP/QTI domains\n" + "\n".join(fc_lines()[:len(REUSE)]) + "\n\n"
    body += "# Samsung/QTI specific domains (defined in this directory)\n"
    body += "\n".join(fc_lines()[len(REUSE) + 1:]) + "\n"
    open(fc, "w", encoding="utf-8", newline="\n").write(head + body)
    print("wrote", os.path.relpath(fc, DT))

    done = set()
    for b, (d, desc) in NEW.items():
        if d in done:
            continue
        done.add(d)
        p = os.path.join(POL, d + ".te")
        open(p, "w", encoding="utf-8", newline="\n").write(TEMPLATE.format(dom=d, desc=desc, bin=b))
        print("wrote", os.path.relpath(p, DT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
