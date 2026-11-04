#!/vendor/bin/sh
# Copyright (c) 2020 The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

#
# Function to start sensors for SSC enabled platforms
#
echo "SensorDebug"
param1=$1
param2=$2

echo "param1: $param1"
echo "param2: $param2"

if [ "$param1" == "copy_registry" ]; then
    if [ ! -d /data/vendor/log/sensordebug ] ; then
        mkdir /data/vendor/log/sensordebug
        touch /data/vendor/log/sensordebug/.nomedia
        chown system.system /data/vendor/log/sensordebug
    fi

    if [ ! -d /data/vendor/log/sensordebug/persist ] ; then
        mkdir /data/vendor/log/sensordebug/persist
        chown system.system /data/vendor/log/sensordebug/persist
    else
        rm -rf /data/vendor/log/sensordebug/persist/*
    fi

    cp -rf /mnt/vendor/persist/sensors/ /data/vendor/log/sensordebug/persist
    chown -R system.system /data/vendor/log/sensordebug/persist

    if [ -f /data/vendor/log/sensordebug/qrtr_5 ] ; then
        rm -rf /data/vendor/log/sensordebug/qrtr_5
    fi

    cat /dev/ipc_logging/qrtr_5 >> /data/vendor/log/sensordebug/qrtr_5
    chown -R system.system /data/vendor/log/sensordebug/qrtr_5
elif [ "$param1" == "ssr_dump" ]; then
    if [ "$param2" == "start" ]; then
        echo "start"
        SSR_DUMP_CMD=""
        ENABLE_RAMDUMPS_CMD='getprop persist.vendor.ssr.enable_ramdumps'
        enable_ramdumps=$(eval $ENABLE_RAMDUMPS_CMD)
        echo "enable_ramdumps:$enable_ramdumps"
        if [ "$enable_ramdumps" == "0" ]; then
            SSR_DUMP_CMD+="setprop persist.vendor.ssr.enable_ramdumps 1 &"
        fi

        RESTART_LEVEL_CMD='getprop persist.vendor.ssr.restart_level'
        restart_level=$(eval $RESTART_LEVEL_CMD)
        echo "restart_level:$restart_level"
        if [ "$restart_level" == "ALL_ENABLE" ]; then
            set_val="$restart_level"
        elif [ "$restart_level" == "ALL_DISABLE" ]; then
            set_val="adsp"
        elif [ -n "$restart_level" ];then
            if [[ "$restart_level" == *adsp* ]]; then
                set_val="$restart_level"
            else
                set_val="$restart_level adsp"
            fi
        else
            set_val="adsp"
        fi
        SSR_DUMP_CMD+="setprop persist.vendor.ssr.restart_level '$set_val'"
        echo "SSR_DUMP_CMD:$SSR_DUMP_CMD"
        eval $SSR_DUMP_CMD
    elif [ "$param2" == "stop" ]; then
        echo "stop"
        SSR_DUMP_CMD="setprop persist.vendor.ssr.enable_ramdumps 0 &"
        SSR_DUMP_CMD+="setprop persist.vendor.ssr.restart_level ALL_DISABLE"
        eval $SSR_DUMP_CMD
    elif [ "$param2" == "complete" ]; then
        chown root:system /data/vendor/ramdump/remoteproc-adsp.elf
        INTENT_CMD="am broadcast -a com.sec.android.ISSUE_TRACKER_ACTION "
        INTENT_CMD+="--ei ERRCODE -126 "
        INTENT_CMD+="--es ERRNAME \"Sensor Silent dump\" "
        INTENT_CMD+="--es ERRPKG \"Sensor ADSP\" "
        INTENT_CMD+="--es ERRMSG \"Sensor SSR Dump after SSR\" "
        INTENT_CMD+="--es EXTLOG \"/data/vendor/ramdump/remoteproc-adsp.elf\""
        echo "$INTENT_CMD" && eval "$INTENT_CMD"
    fi
else
    echo "No Support Command:$param1"
fi
