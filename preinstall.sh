#!/bin/sh

. ./util.sh

PREINSTALL_LOG='./log.preinstall'

if [ -t 1 ]; then
    "$0" >"$PREINSTALL_LOG" 2>&1
    exit 0
fi

perform_task check_root 'Checking for root '
ret=$?
check_ok $ret 'This script needs to be run as root.\n' || exit 1

perform_task check_conn 'Checking for internet connection '
ret=$?
check_ok $ret 'Unable to reach the internet. Check your connection.\n' || exit 2

update_package_database() {
    pacman -Sy
}

update_system_clock() {
    timedatectl set-ntp true
}

setup_download_mirrors() {
    pacman -S --noconfirm pacman-contrib
    grep -E "Server = .+" /etc/pacman.d/mirrorlist >/etc/pacman.d/mirrorlist.filtered
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    rankmirrors /etc/pacman.d/mirrorlist.filtered >/etc/pacman.d/mirrorlist
}

perform_task update_package_database 'Updating package database '
ret=$?
check_ok $ret "ERR: Updating package database exit code: $ret. Check $PREINSTALL_LOG for more details.\n"

perform_task update_system_clock 'Updating system clock '
ret=$?
check_ok $ret "ERR: Updating system clock exit code: $ret. Check $PREINSTALL_LOG for more details.\n"

perform_task setup_download_mirrors 'Sorting download mirrors (this will take a while...) '
ret=$?
check_ok $ret "ERR: Sorting download mirrors exit code: $ret. Check $PREINSTALL_LOG for more details.\n"

print_msg "Done"
