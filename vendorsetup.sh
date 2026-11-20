#!/bin/sh
#
# Re-apply the ROM patches kept in device/samsung/a36xq/patches.
#
# This file is sourced by build/envsetup.sh on every "source build/envsetup.sh",
# which makes the patches survive "repo sync".  Each patch must start with a
# line of the form
#
#     # target-repo: <path relative to the repo root>
#
# and is applied with "git apply" inside that project.  Patches that are
# already applied are skipped, so sourcing this repeatedly is harmless.
#
# Set A36XQ_SKIP_PATCHES=1 to disable.

if [ -n "$A36XQ_SKIP_PATCHES" ]; then
    return 0 2>/dev/null || exit 0
fi

_a36xq_top="${TOP:-$(gettop 2>/dev/null)}"
if [ -z "$_a36xq_top" ]; then
    return 0 2>/dev/null || exit 0
fi

_a36xq_patchdir="$_a36xq_top/device/samsung/a36xq/patches"

for _a36xq_patch in "$_a36xq_patchdir"/*.patch; do
    [ -e "$_a36xq_patch" ] || continue

    _a36xq_target=$(sed -n 's/^# target-repo: //p' "$_a36xq_patch" | head -n 1)
    [ -n "$_a36xq_target" ] || continue

    _a36xq_repo="$_a36xq_top/$_a36xq_target"
    [ -d "$_a36xq_repo/.git" ] || continue

    if ( cd "$_a36xq_repo" && git apply --check "$_a36xq_patch" >/dev/null 2>&1 ); then
        if ( cd "$_a36xq_repo" && git apply "$_a36xq_patch" ); then
            echo "a36xq: applied $(basename "$_a36xq_patch")"
        fi
    fi
done

unset _a36xq_top _a36xq_patchdir _a36xq_patch _a36xq_target _a36xq_repo
