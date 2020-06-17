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
    print_msg "$message"
    $task
    ret=$?
    if [ $ret -eq 0 ]; then
        print_msg 'OK\n'
    else
        print_msg 'FAILED\n'
        g_err_flag=1
    fi
    return $ret
}

perform_task_arg() {
    task=$1
    arg=$2
    message=$3
    print_msg "$message"
    $task $arg
    ret=$?
    if [ $ret -eq 0 ]; then
        print_msg 'OK\n'
    else
        print_msg 'FAILED\n'
        g_err_flag=1
    fi
    return $ret
}

check_ok() {
    ret=$1
    message=$2
    if [ $ret != 0 ]; then
        print_msg "$message"
    fi
    return $ret
}
