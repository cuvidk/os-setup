#!/bin/sh

. ./util.sh

POST_PARTITION_LOG='log.post_partition'
GENERIG_ERR="Check $POST_PARTITION_LOG for more information."

################################################################################

install_essentials() {
    pacstrap /mnt base linux linux-firmware
}

generate_fstab() {
    genfstab -U /mnt >>/mnt/etc/fstab
}

change_root() {
    mkdir -P /mnt/os-setup && \
        cp -R . /mnt/os-setup && \
        arch-chroot /mnt /os-setup/post_chroot.sh
}

################################################################################

if [ -t 1 ]; then
    "$0" >$POST_PARTITION_LOG 2>&1
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

perform_task install_essentials 'Installing essential arch linux packages '
ret=$?
[ $ret != 0 ] && print_msg "ERR: Installing essential packages exit code; $ret. $GENERIC_ERR\n" && exit 4

perform_task generate_fstab 'Generating fstab ' && \
    echo "#### /mnt/etc/fstab ####" >$(tty) && \
    cat /mnt/etc/fstab >$(tty) && \
    echo "########################" >$(tty)
ret=$?
[ $ret != 0 ] && print_msg "ERR: Generating fstab exit code: $ret. $GENERIC_ERR\n" && exit 5

perform change_root 'Chroot-ing into the new system '
ret=$?
[ $ret != 0 ] && print_msg "ERR: Chroot exit code: $ret. $GENERIC_ERR\n" && exit 6
