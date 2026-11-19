#!/usr/bin/env bash
set -euo pipefail
if [[ $(dpkg-query -W -f='${db:Status-Status}' synaptics-00da-local 2>/dev/null || :) == installed ]]; then
    systemctl stop fprintd.service tudor-host-launcher.service
    apt-get remove synaptics-00da-local
    systemctl daemon-reload
    udevadm control --reload-rules
fi
