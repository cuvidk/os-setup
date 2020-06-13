#!/bin/sh

print_msg() {
    echo -n -e "$1"
}

check_root() {
    test $(id -u) -eq 0
}

check_conn() {
    ping -c 4 archlinux.org >/dev/null 2>&1
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

#############################################################

perform_task check_root 'Checking for root: '
is_root=$?

if [ $is_root != 0 ]; then
    print_msg 'This script needs to be run as root.\n'
    exit 1
fi

perform_task check_conn 'Checking for internet connection: '
conn=$?

if [ $conn != 0 ]; then
    print_msg 'Unable to reach the internet. Check you connection.\n'
    exit 2
fi

print_msg 'DONE\n'
