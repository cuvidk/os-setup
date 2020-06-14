#!/bin/sh

print_msg() {
    echo -n -e "$1">>$(tty)
}

check_root() {
    test $(id -u) -eq 0
}

check_conn() {
    ping -c 4 archlinux.org
}

perform_task() {
    task=$1
    message=$2
    print_msg "$message"
    $task
    ret=$?
    [ $ret -eq 0 ] && print_msg 'OK\n' || print_msg 'FAILED\n'
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
