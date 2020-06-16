#!/bin/sh

. ./util.sh

PRE_PARTITION_LOG='./log.pre_partition'
GENERIC_ERR="Check $PRE_PARTITION_LOG for more details."

################################################################################

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

################################################################################

if [ -t 1 ]; then
    "$0" >"$PRE_PARTITION_LOG" 2>&1
    exit 0
fi

perform_task check_uefi_boot 'Checking if system is booted in UEFI mode '
ret=$?
[ $ret != 0 ] && print_msg 'The installer scripts are limited to UEFI systems.\n' && exit 1

perform_task check_root 'Checking for root '
ret=$?
[ $ret != 0 ] && print_msg 'This script needs to be run as root.\n' && exit 2

perform_task check_conn 'Checking for internet connection '
ret=$?
[ $ret != 0 ] && print_msg 'Unable to reach the internet. Check your connection.\n' && exit 3

perform_task update_package_database 'Updating package database ' || \
    print_msg "ERR: Updating package database exit code: $ret. $GENERIC_ERR\n"

perform_task update_system_clock 'Updating system clock ' || \
    print_msg "ERR: Updating system clock exit code: $ret. $GENERIC_ERR\n"

perform_task setup_download_mirrors 'Sorting download mirrors (this will take a while) ' || \
    print_msg "ERR: Sorting download mirrors exit code: $ret. $GENERIC_ERR\n"

print_msg "Done\n"
