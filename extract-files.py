#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils:../../../vendor/pixel/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# PYTHONPATH carries both locations on purpose:
#   tools/extract-utils         LineageOS
#   vendor/pixel/extract-utils  PixelOS
# Only the path that exists is imported, so this script works on both.
#

from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    'device/samsung/a36xq',
]

module = ExtractUtilsModule(
    'a36xq',
    'samsung',
    namespace_imports=namespace_imports,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
