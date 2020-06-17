#!/bin/sh

. ./util.sh

POST_PARTITION_LOG='log.post_partition'
GENERIC_ERR="Check $POST_PARTITION_LOG for more information."

################################################################################

install_essentials() {
    pacstrap /mnt base linux linux-firmware
}

generate_fstab() {
    genfstab -U /mnt >>/mnt/etc/fstab
}


prepare_change_root() {
    mkdir -p /mnt/os-setup
    cp -R . /mnt/os-setup
}

clean() {
    rm -rf /mnt/os-setup
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
    print_msg "--------------------------------\n" && \
    print_msg "         /mnt/etc/fstab         \n" && \
    print_msg "--------------------------------\n" && \
    cat /mnt/etc/fstab >$(tty) && \
    print_msg "--------------------------------\n"
ret=$?
[ $ret != 0 ] && print_msg "ERR: Generating fstab exit code: $ret. $GENERIC_ERR\n" && exit 5

perform_task prepare_change_root 'Preparing to chroot into the new system '
ret=$?
[ $ret != 0 ] && print_msg "ERR: Prepare chroot exit code: $ret. $GENERIC_ERR\n" && exit 6

print_msg '############ chroot ############\n'
arch-chroot /mnt /os-setup/post_chroot.sh
ret=$?
[ $ret != 0 ] && print_msg "ERR: Failed to chroot. $GENERIC_ERR\n" && exit 7

perform_task clean
