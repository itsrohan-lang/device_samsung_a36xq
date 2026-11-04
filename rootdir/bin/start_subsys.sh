#! /vendor/bin/sh
#=============================================================================
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# All rights reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#=============================================================================

soccp_path_file=$(dirname  "$(grep -rl "soccp" /sys/class/remoteproc/remoteproc*/name)")
adsp_path_file=$(dirname  "$(grep -rl "adsp" /sys/class/remoteproc/remoteproc*/name)")
cdsp_path_file=$(dirname  "$(grep -rl "cdsp" /sys/class/remoteproc/remoteproc*/name)")

soccp_state=$(cat "$soccp_path_file/state")
adsp_state=$(cat "$adsp_path_file/state")
cdsp_state=$(cat "$cdsp_path_file/state")
boot_mode_sh=$(getprop ro.boot.mode)

echo "Subsystem starting in mode: $boot_mode_sh"

if [[ "$soccp_state" != "running" ]] && [[ "$soccp_state" != "attached" ]]; then
    echo "start" > "$soccp_path_file/state"
fi

if [[ "$boot_mode_sh" != "charger" ]]; then
    if [[ "$adsp_state" != "running" ]]; then
        echo "start" > "$adsp_path_file/state"
    fi

    if [[ "$cdsp_state" != "running" ]]; then
        echo "start" > "$cdsp_path_file/state"
    fi
fi

