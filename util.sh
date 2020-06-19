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
    task=$1
    message=$2
    [ -n "$message" ] && print_msg "$message"
    $task
    ret=$?
    if [ $ret -eq 0 ]; then
        [ -n "$message" ] && print_msg 'OK\n'
    else
        [ -n "$message" ] && print_msg 'FAILED\n'
        g_err_flag=1
    fi
    unset message
    return $ret
}

perform_task_arg() {
    task=$1
    arg=$2
    message=$3
    [ -n "$message" ] && print_msg "$message"
    $task $arg
    ret=$?
    if [ $ret -eq 0 ]; then
        [ -n "$message" ] && print_msg 'OK\n'
    else
        [ -n "$message" ] && print_msg 'FAILED\n'
        g_err_flag=1
    fi
    unset message
    return $ret
}

errors_encountered() {
    [ $g_err_flag -eq 1 ]
}
