#!/bin/sh

. ./util.sh

POSTINSTALL_LOG='log.postinstall'

if [ -t 1 ]; then
    "$0" >$POSTINSTALL_LOG 2>&1
    exit 0
fi

perform_task check_root 'Checking for root '
ret=$?
check_ok $ret 'This script needs to be run as root.\n' || exit 1

perform_task check_conn 'Checking for internet connection '
ret=$?
check_ok $ret 'Unable to reach the internet. Check your connection.\n' || exit 2

################################################################################

setup_hostname() {
    print_msg 'Pick a hostname: '
    read hname
    echo "$hname" > /etc/hostname
}

setup_password() {
    print_msg 'Setting up root password\n'
    passwd >$(tty) 2>&1
}

################################################################################

setup_hostname
setup_password
