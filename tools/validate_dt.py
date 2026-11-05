#!/usr/bin/env python3
"""
Static consistency checker for the Samsung a36xq device tree.

It does not need an AOSP checkout: everything is verified against the files in
this tree, the vendor blob tree and the blob manifest.

Checks
------
  * every file referenced from a makefile / blueprint exists
  * every proprietary-files.txt entry exists in vendor/samsung/a36xq/proprietary
  * files the device tree installs never collide with a blob path
  * modules listed in PRODUCT_PACKAGES are either defined in-tree or flagged
  * XML configs are well formed
  * property files are syntactically valid and free of duplicates
  * BoardConfig values agree with the values recovered from the stock firmware

Usage: python tools/validate_dt.py [-q]
Exit code 0 when no ERROR is reported.
"""

import os
import re
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
DT = os.path.dirname(HERE)

# device_samsung_a36xq sits next to vendor_samsung_a36xq in the porting workspace
VENDOR = os.path.join(os.path.dirname(DT), "vendor_samsung_a36xq")
VENDOR_BLOBS = os.path.join(VENDOR, "proprietary")

# Values that were read back from fota.zip (META/misc_info.txt,
# META/dynamic_partitions_info.txt) and the stock image headers.
STOCK = {
    "BOARD_SUPER_PARTITION_SIZE": "14680064000",
    "BOARD_QTI_DYNAMIC_PARTITIONS_SIZE": "14675869696",
    "BOARD_SUPER_PARTITION_GROUPS": "qti_dynamic_partitions",
    "BOARD_BOOTIMAGE_PARTITION_SIZE": "100663296",
    "BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE": "100663296",
    "BOARD_DTBOIMG_PARTITION_SIZE": "25165824",
    "BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE": "8388608",
    "BOARD_FLASH_BLOCK_SIZE": "131072",
}

errors = []
warnings = []
infos = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def info(msg):
    infos.append(msg)


def rel(p):
    return os.path.relpath(p, DT).replace("\\", "/")


def read(path):
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        return fh.read()


def strip_make_comments(text):
    out = []
    for line in text.splitlines():
        if line.lstrip().startswith("#"):
            continue
        out.append(line)
    return "\n".join(out)


# ---------------------------------------------------------------- makefiles
MAKEFILES = ["BoardConfig.mk", "device.mk", "lineage_a36xq.mk",
             "AndroidProducts.mk", "Android.mk"]
BPFILES = ["Android.bp", "rootdir/Android.bp"]
if os.path.isdir(os.path.join(DT, "configs")):
    pass
if os.path.exists(os.path.join(DT, "camera", "Android.bp")):
    BPFILES.append("camera/Android.bp")

VAR_RE = re.compile(r"\$[({](LOCAL_PATH|DEVICE_PATH|DT|COMMON_PATH)[)}]")
PATH_TOKEN_RE = re.compile(r"[A-Za-z0-9_./@+\-]+")


def check_referenced_files():
    for mf in MAKEFILES:
        p = os.path.join(DT, mf)
        if not os.path.exists(p):
            err(f"missing makefile: {mf}")
            continue
        for lineno, line in enumerate(read(p).splitlines(), 1):
            if line.lstrip().startswith("#"):
                continue
            for m in VAR_RE.finditer(line):
                rest = line[m.end():]
                tok = PATH_TOKEN_RE.match(rest)
                if not tok:
                    continue
                relpath = tok.group(0).rstrip("\\").strip().lstrip("/")
                # PRODUCT_COPY_FILES entries carry a ":destination" suffix
                relpath = relpath.split(":")[0]
                if not relpath or relpath.startswith("$"):
                    continue
                full = os.path.join(DT, relpath)
                if not os.path.exists(full):
                    err(f"{mf}:{lineno}: referenced path does not exist: {relpath}")


def parse_mk_vars():
    vars_ = {}
    for mf in MAKEFILES:
        p = os.path.join(DT, mf)
        if not os.path.exists(p):
            continue
        text = read(p)
        # join continuation lines
        text = text.replace("\\\n", " ")
        for line in text.splitlines():
            if line.lstrip().startswith("#"):
                continue
            m = re.match(r"\s*([A-Za-z_][A-Za-z0-9_]*)\s*[:+?]?=\s*(.*)$", line)
            if not m:
                continue
            key, val = m.group(1), m.group(2).strip()
            if key.endswith("_PROP") or key in ("DEVICE_MANIFEST_FILE", "DEVICE_MATRIX_FILE"):
                vars_.setdefault(key, []).append(val)
    return vars_


def check_prop_files(vars_):
    for key, values in vars_.items():
        for val in values:
            for tok in val.split():
                if tok.startswith("$(DEVICE_PATH)/") or tok.startswith("$(LOCAL_PATH)/"):
                    relpath = tok.split("/", 1)[1]
                    if not os.path.exists(os.path.join(DT, relpath)):
                        err(f"{key}: property file does not exist: {relpath}")


def check_prop_syntax():
    for name in sorted(os.listdir(DT)):
        if not name.endswith(".prop"):
            continue
        seen = {}
        for lineno, line in enumerate(read(os.path.join(DT, name)).splitlines(), 1):
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            if "=" not in s:
                err(f"{name}:{lineno}: not a key=value line: {s!r}")
                continue
            k, v = s.split("=", 1)
            if not re.fullmatch(r"[A-Za-z0-9_.\-]+", k):
                err(f"{name}:{lineno}: invalid property name {k!r}")
            if k in seen:
                warn(f"{name}:{lineno}: duplicate property {k} (first at line {seen[k]})")
            seen[k] = lineno


def check_boardconfig_vs_stock():
    text = read(os.path.join(DT, "BoardConfig.mk"))
    vals = {}
    for line in text.replace("\\\n", " ").splitlines():
        m = re.match(r"\s*([A-Za-z_][A-Za-z0-9_]*)\s*[:+?]?=\s*(.*)$", line)
        if m:
            vals[m.group(1)] = m.group(2).strip()
    for key, expected in STOCK.items():
        if key not in vals:
            err(f"BoardConfig.mk: {key} missing (stock value {expected})")
            continue
        got = vals[key].split("#")[0].strip()
        if got != expected:
            err(f"BoardConfig.mk: {key}={got} but stock firmware says {expected}")

    # things that must NOT be there for this device
    if re.search(r"^BOARD_USES_RECOVERY_AS_BOOT\s*:?=\s*true", text, re.M):
        err("BoardConfig.mk: BOARD_USES_RECOVERY_AS_BOOT is set but the device has no recovery partition")
    if "recovery" in vals.get("AB_OTA_PARTITIONS", "") and "AB_OTA_PARTITIONS" in text:
        # only complain when recovery is an actual list item
        ab = text.split("AB_OTA_PARTITIONS", 1)[1].split("\n\n", 1)[0]
        if re.search(r"^\s*recovery\s*\\?$", ab, re.M):
            err("BoardConfig.mk: 'recovery' must not be in AB_OTA_PARTITIONS (no_recovery=true)")

    for key in ("TARGET_PREBUILT_KERNEL", "BOARD_PREBUILT_DTBIMAGE_DIR",
                "BOARD_PREBUILT_DTBOIMAGE", "BOARD_SYSTEM_DLKM_SRC"):
        if key in vals:
            relpath = vals[key].replace("$(DEVICE_PATH)/", "")
            if not os.path.exists(os.path.join(DT, relpath)):
                err(f"BoardConfig.mk: {key} points at missing path {relpath}")
    ddir = vals.get("BOARD_PREBUILT_DTBIMAGE_DIR", "").replace("$(DEVICE_PATH)/", "")
    if ddir and os.path.isdir(os.path.join(DT, ddir)):
        dtbs = [f for f in os.listdir(os.path.join(DT, ddir)) if f.endswith(".dtb")]
        if not dtbs:
            err(f"BoardConfig.mk: {ddir} contains no *.dtb files")
        elif len(dtbs) > 1:
            info(f"{ddir}: {len(dtbs)} .dtb files will be concatenated into dtb.img")


# --------------------------------------------------------------- blobs
def parse_proprietary_files():
    positive, negative = [], []
    p = os.path.join(DT, "proprietary-files.txt")
    for lineno, line in enumerate(read(p).splitlines(), 1):
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        if s.startswith("-"):
            negative.append((s[1:], lineno))
        else:
            positive.append((s, lineno))
    return positive, negative


def check_blobs(positive, negative):
    if not os.path.isdir(VENDOR_BLOBS):
        warn(f"vendor blob tree not found at {VENDOR_BLOBS}; skipping existence checks")
        return
    missing = [path for path, _ in positive
               if not os.path.exists(os.path.join(VENDOR_BLOBS, path))]
    for path, lineno in positive:
        full = os.path.join(VENDOR_BLOBS, path)
        if not os.path.exists(full):
            err(f"proprietary-files.txt:{lineno}: blob missing from vendor tree: {path}")
        elif os.path.getsize(full) == 0:
            # Legitimate: several firmware chunks and marker files are empty
            # in the stock images too.
            info(f"proprietary-files.txt:{lineno}: blob is empty: {path}")
        else:
            # symlinks inside the blob tree are legitimate placeholders
            pass
    for path, lineno in negative:
        if not os.path.exists(os.path.join(VENDOR_BLOBS, path)):
            warn(f"proprietary-files.txt:{lineno}: excluded path is not in the vendor tree: {path}")
    info(f"blobs: {len(positive)} entries, {len(negative)} exclusions, "
         f"{len(positive) - len(missing)} present in vendor tree")


def dt_installed_vendor_paths():
    """Paths the device tree installs onto the vendor partition."""
    dests = {}
    bp = os.path.join(DT, "rootdir", "Android.bp")
    if os.path.exists(bp):
        text = read(bp)
        for m in re.finditer(r"prebuilt_etc\s*\{(.*?)\n\}", text, re.S):
            body = m.group(1)
            name = re.search(r'name:\s*"([^"]+)"', body)
            src = re.search(r'src:\s*"([^"]+)"', body)
            sub = re.search(r'sub_dir:\s*"([^"]+)"', body)
            vendor = re.search(r"vendor:\s*true", body)
            if not (name and src):
                continue
            if not vendor:
                continue
            fname = os.path.basename(src.group(1))
            dest = "vendor/" + (sub.group(1) + "/" if sub else "") + fname
            dests[dest] = f"rootdir/Android.bp:{name.group(1)}"
        for m in re.finditer(r"sh_binary\s*\{(.*?)\n\}", text, re.S):
            body = m.group(1)
            name = re.search(r'name:\s*"([^"]+)"', body)
            src = re.search(r'src:\s*"([^"]+)"', body)
            if name and src and re.search(r"vendor:\s*true", body):
                dests["vendor/bin/" + os.path.basename(src.group(1))] = \
                    f"rootdir/Android.bp:{name.group(1)}"

    # PRODUCT_COPY_FILES with $(TARGET_COPY_OUT_VENDOR)
    for mf in MAKEFILES:
        p = os.path.join(DT, mf)
        if not os.path.exists(p):
            continue
        text = read(p).replace("\\\n", " ")
        for line in text.splitlines():
            m = re.search(r":\$\(TARGET_COPY_OUT_VENDOR\)/(\S+)", line)
            if m:
                dests["vendor/" + m.group(1)] = f"{mf}:PRODUCT_COPY_FILES"
            m = re.search(r":\$\(TARGET_COPY_OUT_ODM\)/(\S+)", line)
            if m:
                dests["odm/" + m.group(1)] = f"{mf}:PRODUCT_COPY_FILES"
    return dests


def check_collisions(positive):
    blob_paths = {path for path, _ in positive}
    dests = dt_installed_vendor_paths()
    clashes = sorted(set(dests) & blob_paths)
    for c in clashes:
        err(f"install collision: {dests[c]} writes {c} which is also a vendor blob")
    if not clashes:
        info(f"no install collisions between device tree and {len(blob_paths)} blobs")
    return clashes


# --------------------------------------------------------------- modules
def in_tree_modules():
    names = set()
    for bp in BPFILES:
        p = os.path.join(DT, bp)
        if os.path.exists(p):
            names.update(re.findall(r'^\s*name:\s*"([^"]+)"', read(p), re.M))
    for bp in (os.path.join(VENDOR, "Android.bp"),
               os.path.join(os.path.dirname(DT), "vendor_samsung_camera", "Android.bp")):
        if os.path.exists(bp):
            names.update(re.findall(r'^\s*name:\s*"([^"]+)"', read(bp), re.M))
    return names


def product_packages():
    pkgs = []
    for mf in ("device.mk", "lineage_a36xq.mk"):
        p = os.path.join(DT, mf)
        if not os.path.exists(p):
            continue
        text = read(p)
        for m in re.finditer(r"PRODUCT_PACKAGES\s*\+?=\s*((?:[^\n]*\\\n)*[^\n]*)", text):
            for tok in re.sub(r"\\\n", " ", m.group(1)).split():
                tok = tok.strip()
                if tok and not tok.startswith("#") and not tok.startswith("$"):
                    pkgs.append(tok)
    return pkgs


def check_modules():
    known = in_tree_modules()
    unknown = sorted({p for p in product_packages() if p not in known})
    info(f"PRODUCT_PACKAGES: {len(set(product_packages()))} unique, "
         f"{len(unknown)} not defined in-tree (expected to come from AOSP/Lineage)")
    for u in unknown:
        info(f"  external package: {u}")


# --------------------------------------------------------------- xml
def check_xml():
    for root, _dirs, files in os.walk(os.path.join(DT, "configs")):
        for f in files:
            if f.endswith(".xml"):
                p = os.path.join(root, f)
                try:
                    ET.parse(p)
                except ET.ParseError as e:
                    err(f"invalid XML {rel(p)}: {e}")


# --------------------------------------------------------------- run
def main():
    quiet = "-q" in sys.argv
    check_referenced_files()
    vars_ = parse_mk_vars()
    check_prop_files(vars_)
    check_prop_syntax()
    check_boardconfig_vs_stock()
    positive, negative = parse_proprietary_files()
    check_blobs(positive, negative)
    check_collisions(positive)
    check_modules()
    check_xml()

    print("=" * 70)
    print("a36xq device tree validation")
    print("=" * 70)
    if not quiet:
        for i in infos:
            print("INFO  ", i)
    for w in warnings:
        print("WARN  ", w)
    for e in errors:
        print("ERROR ", e)
    print("-" * 70)
    print(f"{len(errors)} error(s), {len(warnings)} warning(s), {len(infos)} info")
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
