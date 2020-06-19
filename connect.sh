#!/bin/sh

rfkill unblock wifi
ip link set wlp9s0 up
wpa_supplicant -B -i wlp9s0 up -c ./cred.txt
systemctl start dhcpcd
