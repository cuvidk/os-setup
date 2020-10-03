#!/bin/sh

. ./util.sh

INSTALL_LOG='stdout.log'
GENERIC_ERR="Check ${INSTALL_LOG} for more information."

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
    "${0}" >"${INSTALL_LOG}" 2>&1
    exit 0
fi

perform_task check_uefi_boot 'Checking if system is booted in UEFI mode '
ret=$?
[ ${ret} != 0 ] && print_msg 'The installer scripts are limited to UEFI systems.\n' && exit 1

perform_task check_root 'Checking for root '
ret=$?
[ ${ret} != 0 ] && print_msg 'This script needs to be run as root.\n' && exit 2

perform_task check_conn 'Checking for internet connection '
ret=$?
[ ${ret} != 0 ] && print_msg 'Unable to reach the internet. Check your connection.\n' && exit 3

perform_task update_package_database 'Updating package database '
perform_task update_system_clock 'Updating system clock '
perform_task setup_download_mirrors 'Sorting download mirrors (this will take a while) '

perform_task install_essentials 'Installing essential arch linux packages '
ret=$?
[ ${ret} != 0 ] && print_msg "ERR: Installing essential packages exit code; ${ret}. ${GENERIC_ERR}\n" && exit 4

perform_task generate_fstab 'Generating fstab ' &&
    print_msg '################################################\n' &&
    print_msg '################# /mnt/etc/fstab ###############\n' &&
    print_msg '################################################\n' &&
    cat /mnt/etc/fstab >$(tty) &&
    print_msg '################################################\n'
ret=$?
[ ${ret} != 0 ] && print_msg "ERR: Generating fstab exit code: ${ret}. ${GENERIC_ERR}\n" && exit 5

perform_task prepare_change_root 'Preparing to chroot into the new system '
ret=$?
[ ${ret} != 0 ] && print_msg "ERR: Prepare chroot exit code: ${ret}. ${GENERIC_ERR}\n" && exit 6

print_msg '################################################\n'
print_msg '#################### chroot ####################\n'
print_msg '################################################\n'

arch-chroot /mnt /os-setup/post_chroot.sh
ret=$?
[ ${ret} != 0 ] && print_msg "ERR: Failed to chroot. ${GENERIC_ERR}\n" && exit 7

#cat "${INSTALL_LOG}" "/mnt/${INSTALL_LOG}" >"${INSTALL_LOG}.concat" &&
#    mv "${INSTALL_LOG}.concat" "${INSTALL_LOG}"

print_msg '################################################\n'

perform_task clean 'Removing os setup files from the new system '

errors_encountered &&
    print_msg "ERR: ${0} finished with errors. Check ${INSTALL_LOG} for details.\n" ||
    print_msg "${0} finished with success.\n"
