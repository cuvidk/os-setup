#!/bin/sh

. ./util.sh

REAPPLY_CONFIG_LOG="log.reapply_configuration"

################################################################################

configure_vim() {
    cp -R ./config-files/vim/etc /
}

configure_urxvt() {
    mkdir -p "/etc/conf.d/urxvt" && \
    cp -R ./config-files/urxvt/etc / && \
    chmod +x /etc/X11/xinit/xinitrc.d/urxvt.sh
}

configure_ly() {
    cp -R ./config-files/ly/etc /
}


################################################################################

if [ -t 1 ]; then
    "$0" >"$REAPPLY_CONFIG_LOG" 2>&1
    exit $?
fi

perform_task configure_vim 'Applying vim config '
perform_task configure_urxvt 'Applying urxvt config '
perform_task configure_ly 'Applying ly config '

errors_encountered && print_msg "ERR: Errors were reported during installation. Check $REAPPLY_CONFIG_LOG for more info.\n"

print_msg 'Done\n'
