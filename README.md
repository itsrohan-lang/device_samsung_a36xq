# Device Tree for Samsung Galaxy A36 5G (SM-A366E / a36xq)

The Samsung Galaxy A36 5G (codename `a36xq`, model `SM-A366E`) is a mid-range smartphone from Samsung based on the Qualcomm Snapdragon platform (`parrot` / SM6450).

## Device Specifications

| Feature | Details |
| :--- | :--- |
| **Chipset** | Qualcomm Snapdragon (`parrot`) |
| **Architecture** | ARM64 (arm64-v8a) |
| **Target Codename** | `a36xq` |
| **Model** | SM-A366E |
| **Partition Scheme** | Dynamic Partitions (Virtual A/B) |
| **Boot Header** | Version 4 (GKI) |
| **Filesystems** | EROFS (system, vendor, product, odm) |

---

## How to use this Device Tree for Custom ROM Building

### 1. Place the Device Tree in your ROM Source
Clone or copy this directory into your Android build tree:
```bash
mkdir -p device/samsung/a36xq
cp -r /path/to/device_samsung_a36xq/* device/samsung/a36xq/
```

### 2. Extract Proprietary Blobs
Extract vendor blobs into `vendor/samsung/a36xq` from your system dump or connected device:
```bash
cd device/samsung/a36xq
# To extract from your dump folder:
./extract-files.py /path/to/dump
# Or to extract directly from a connected device with ADB:
./extract-files.py
```

### 3. Initialize the Build Environment
```bash
source build/envsetup.sh
lunch lineage_a36xq-userdebug
```

### 4. Build the ROM
```bash
mka bacon
```
