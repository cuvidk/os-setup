#!/bin/sh

################################################################################

usage() {
    print_msg "Usage: ${0} --config <filename>\n"
}

check_root() {
    test $(id -u) -eq 0
}

check_conn() {
    ping -c 4 archlinux.org
}

check_uefi_boot() {
    [ -d /sys/firmware/efi/efivars -a `ls /sys/firmware/efi/efivars | wc -l` -gt 0 ]
}


check_config_file() {
    [ -f "${CONFIG_FILE}" ] &&
        [ -n "$(grep -E "${HOSTNAME_REGEX}" "${CONFIG_FILE}")" ] &&
        [ -n "$(grep -E "${ROOT_PASS_REGEX}" "${CONFIG_FILE}")" ] &&
        [ "$(grep -c -E "${USER_REGEX}" "${CONFIG_FILE}")" == "$(grep -c -E '^user' ${CONFIG_FILE})" ]
}

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
    cp -R "${WORKING_DIR}" /mnt/os-setup
}

clean() {
    rm -rf /mnt/os-setup
}

################################################################################

WORKING_DIR="$(realpath "$(dirname "${0}")")"

. "${WORKING_DIR}/shell-utils/util.sh"

setup_output

CONFIG_FILE='./install.config'

HOSTNAME_REGEX='^hostname[ \t]*=[ \t]*[[:alnum:]]+$'
ROOT_PASS_REGEX='^root_pass[ \t]*=[ \t]*.+$'
USER_REGEX='^user[ \t]*=[ \t]*[[:alnum:]]+:.+:[0|1]$'

[ -z "$(echo ${@} | grep '\-\-config ')" ] && usage && exit 1

while [ $# -gt 0 ];
do
    option=${1}
    case ${option} in
        "--config")
            cp "${2}" "${CONFIG_FILE}"
            shift
            shift
            ;;
        *)
            echo "Unknown option ${option}; ignoring"
            shift
            ;;
    esac
done

perform_task check_config_file "Checking for valid config file"
ret=$?
[ ${ret} != 0 ] && print_msg "ERR: Invalid config file.\n" && exit 2

perform_task check_uefi_boot 'Checking if system is booted in UEFI mode '
ret=$?
[ ${ret} != 0 ] && print_msg 'The installer scripts are limited to UEFI systems.\n' && exit 3

perform_task check_root 'Checking for root '
ret=$?
[ ${ret} != 0 ] && print_msg 'This script needs to be run as root.\n' && exit 4

perform_task check_conn 'Checking for internet connection '
ret=$?
[ ${ret} != 0 ] && print_msg 'Unable to reach the internet. Check your connection.\n' && exit 5

perform_task update_package_database 'Updating package database '
perform_task update_system_clock 'Updating system clock '
perform_task setup_download_mirrors 'Sorting download mirrors (this will take a while) '

perform_task install_essentials 'Installing essential arch linux packages '
ret=$?
[ ${ret} != 0 ] && print_msg "ERR: Installing essential packages exit code; ${ret}. \n" && exit 6

perform_task generate_fstab 'Generating fstab ' &&
    print_msg '################################################\n' &&
    print_msg '################# /mnt/etc/fstab ###############\n' &&
    print_msg '################################################\n' &&
    cat /mnt/etc/fstab >$(tty) &&
    print_msg '################################################\n'
ret=$?
[ ${ret} != 0 ] && print_msg "ERR: Generating fstab exit code: ${ret}.\n" && exit 7

perform_task prepare_change_root 'Preparing to chroot into the new system '
ret=$?
[ ${ret} != 0 ] && print_msg "ERR: Prepare chroot exit code: ${ret}.\n" && exit 8

print_msg '################################################\n'
print_msg '#################### chroot ####################\n'
print_msg '################################################\n'

arch-chroot /mnt /os-setup/post_chroot.sh
ret=$?
[ ${ret} != 0 ] && print_msg "ERR: Failed to chroot.\n" && exit 9

print_msg '################################################\n'

perform_task clean 'Removing os setup files from the new system '

check_for_errors
