#!/bin/sh

WORKING_DIR="$(realpath "$(dirname "${0}")")"
CONFIG_FILE="${WORKING_DIR}/install.config"

. "${WORKING_DIR}/config/shell-utils/util.sh"

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
    local hostname_regex='^hostname[ \t]*=[ \t]*[[:alnum:]]+$'
    local root_pass_regex='^root_pass[ \t]*=[ \t]*.+$'
    local user_regex='^user[ \t]*=[ \t]*[[:alnum:]]+:.+:[0|1]$'
    [ -f "${CONFIG_FILE}" ] &&
        [ -n "$(grep -E "${hostname_regex}" "${CONFIG_FILE}")" ] &&
        [ -n "$(grep -E "${root_pass_regex}" "${CONFIG_FILE}")" ] &&
        [ "$(grep -c -E "${user_regex}" "${CONFIG_FILE}")" == "$(grep -c -E '^user' ${CONFIG_FILE})" ]
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
    cp -R "${WORKING_DIR}" /mnt
}

exec_arch_chroot() {
    arch-chroot /mnt /os-setup/post_chroot.sh
}

clean() {
    rm -rf "/mnt/$(basename "${WORKING_DIR}")"
}

main() {
    setup_verbosity "${@}"

    [ -z "$(echo ${@} | grep '\-\-config ')" ] && usage && return 1

    while [ $# -gt 0 ];
    do
        local option=${1}
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
    [ $? != 0 ] && print_msg "ERR: Invalid config file.\n" && return 2

    perform_task check_uefi_boot 'Checking if system is booted in UEFI mode '
    [ $? != 0 ] && print_msg 'The installer scripts are limited to UEFI systems.\n' && return 3

    perform_task check_root 'Checking for root '
    [ $? != 0 ] && print_msg 'This script needs to be run as root.\n' && return 4

    perform_task check_conn 'Checking for internet connection '
    [ $? != 0 ] && print_msg 'Unable to reach the internet. Check your connection.\n' && return 5

    perform_task update_package_database 'Updating package database '
    perform_task update_system_clock 'Updating system clock '
    perform_task setup_download_mirrors 'Sorting download mirrors (this will take a while) '

    perform_task install_essentials 'Installing essential arch linux packages '
    local ret=$?
    [ ${ret} != 0 ] && print_msg "ERR: Installing essential packages exit code; ${ret}. \n" && return 6

    perform_task generate_fstab 'Generating fstab ' &&
        print_msg '################################################\n' &&
        print_msg '################# /mnt/etc/fstab ###############\n' &&
        print_msg '################################################\n' &&
        cat /mnt/etc/fstab >$(tty) &&
        print_msg '################################################\n'
    ret=$?
    [ ${ret} != 0 ] && print_msg "ERR: Generating fstab exit code: ${ret}.\n" && return 7

    perform_task prepare_change_root 'Preparing to chroot into the new system '
    ret=$?
    [ ${ret} != 0 ] && print_msg "ERR: Prepare chroot exit code: ${ret}.\n" && return 8

    print_msg '################################################\n'
    print_msg '#################### chroot ####################\n'
    print_msg '################################################\n'

    perform_task exec_arch_chroot
    [ ${ret} != 0 ] && print_msg "ERR: arch-chroot returned ${ret}.\n"

    print_msg '################################################\n'

    perform_task clean 'Removing os setup files from the new system '

    check_for_errors
    if [ $? -eq 1 ]; then
        print_msg "[ WARNING ]: Errors encountered. Check $(log_file_name) for details.\n"
        return 9
    else
        print_msg "[ SUCCESS ]"
        return 0
    fi
}

main "${@}"
