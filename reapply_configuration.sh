#!/bin/sh

. ./util.sh

STDOUT_LOG="stdout.log"
STDERR_LOG="stderr.log"

################################################################################

configure_i3() {
    mkdir -p "$g_home_dir/.config/i3" &&
        cp ./config-files/i3/config "$g_home_dir/.config/i3/"
}

configure_i3status() {
    mkdir -p "$g_home_dir/.config/i3status" &&
        cp ./config-files/i3status/config "$g_home_dir/.config/i3status/"
}

configure_vim() {
    cp -R ./config-files/vim/etc /
}

configure_urxvt() {
    mkdir -p "/etc/conf.d/urxvt" &&
    cp -R ./config-files/urxvt/etc / &&
    chmod +x /etc/X11/xinit/xinitrc.d/urxvt.sh
}

configure_ly() {
    cp -R ./config-files/ly/etc /
}

configure_x11_input() {
    # is it worth copying this only if a touchpad is present ?
    cp -R ./config-files/X11/etc /
}

notification_daemon() {
    cp -R ./config-files/notification-daemon/usr /
}

fix_config_permissions() {
    chown -R "$g_user":"$g_user" "$g_home_dir/.config"
}

################################################################################

if [ -t 1 ]; then
    "${0}" "$@" >"${STDOUT_LOG}" 2>"${STDERR_LOG}"
    exit $?
fi

if [ -z "${1}" ]; then
    print_msg "Usage: ${0} <user_to_apply_settings_to>\n"
    exit 2
fi

g_user="$1"
g_home_dir="/home/$g_user"

perform_task configure_i3 "Applying i3 config for user ${g_user}"
perform_task configure_i3status "Applying i3status config for user ${g_user}"
perform_task configure_vim "Applying vim config for user ${g_user}"
perform_task configure_urxvt "Applying urxvt config for user ${g_user}"
perform_task configure_ly "Applying ly config for user ${g_user}"
perform_task configure_x11_input "Applying x11 config for user ${g_user}"
perform_task notification_daemon "Applying notification-daemon config for user ${g_user}"
perform_task fix_config_permissions "Fixing permissions "

errors_encountered && exit 1
