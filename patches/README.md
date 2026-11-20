# ROM patches

Small changes that have to be made outside this device tree, kept here so a
`repo sync` does not silently take them away.

* Each `.patch` is a normal `git diff` with a header line

      # target-repo: <path relative to the repo root>

* `vendorsetup.sh` in the parent directory applies everything in here on every
  `source build/envsetup.sh`, skipping patches that are already applied.
* Disable with `A36XQ_SKIP_PATCHES=1`.

## Current patches

| File | Target | Why |
|---|---|---|
| `0001-wifi-hal-export-vendor-headers.patch` | `frameworks/opt/net/wifi` | We ship Samsung's `libwifi-hal.so` as a prebuilt, so the platform's non-vendor `libwifi-hal` cannot give `android.hardware.wifi-service-lib` the headers it needs. Adds a vendor-available `libwifi-hal-headers` module. |

## Adding one

```sh
cd ~/pos/frameworks/opt/net/wifi
git diff -- libwifi_hal/Android.bp \
  > ~/pos/device/samsung/a36xq/patches/0002-something.patch
# then prepend the "# target-repo:" line
```
