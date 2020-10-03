#!/bin/sh

g_err_flag=0

print_msg() {
    echo -n -e "$1">>$(tty)
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

perform_task() {
    local task=$1
    local message=$2
    [ -n "${message}" ] && print_msg "${message}"
    ${task}
    local ret=$?
    if [ ${ret} -eq 0 ]; then
        [ -n "${message}" ] && print_msg "\r[ OK ] ${message}\n"
    else
        [ -n "${message}" ] && print_msg "\r[ FAIL ] ${message}\n"
        g_err_flag=1
    fi
    return ${ret}
}

perform_task_arg() {
    local task=$1
    local arg=$2
    local message=$3
    [ -n "${message}" ] && print_msg "${message}"
    ${task} ${arg}
    local ret=$?
    if [ ${ret} -eq 0 ]; then
        [ -n "${message}" ] && print_msg "\r[ OK ] ${message}\n"
    else
        [ -n "${message}" ] && print_msg "\r[ FAIL ] ${message}\n"
        g_err_flag=1
    fi
    return ${ret}
}

errors_encountered() {
    [ ${g_err_flag} -eq 1 ]
}
