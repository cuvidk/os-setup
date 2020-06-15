#!/bin/sh

. ./util.sh

GLOBAL_CONFIG_DIR='/etc/conf.d'
PROFILE_SCRIPTS_DIR='/etc/profile.d'
POSTINSTALL_LOG='log.postinstall'
CONFIG_FILES_URL='https://github.com/cuvidk/config-files'

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

install_package() {
    package_name=$1
    pacman -S --noconfirm "$package_name"
}

configure_vim() {
    echo '#!/bin/sh'                                          >"$PROFILE_SCRIPTS_DIR/vim.sh" && \
    echo "alias vim=\"vim -u $GLOBAL_CONFIG_DIR/vim/vimrc\"" >>"$PROFILE_SCRIPTS_DIR/vim.sh" && \
    echo "export EDITOR=vim"                                 >>"$PROFILE_SCRIPTS_DIR/vim.sh" && \
    chmod +x "$PROFILE_SCRIPTS_DIR/vim.sh" && \
    mkdir -p "$GLOBAL_CONFIG_DIR/vim" && \
    cp ./config-files/vim/.vimrc "$GLOBAL_CONFIG_DIR/vim/vimrc"
}

configure_urxvt() {
    mkdir -p "$GLOBAL_CONFIG_DIR/urxvt" && \
    cp ./config-files/urxvt/URxvt "$GLOBAL_CONFIG_DIR/urxvt/URxvt" && \

    cat <<-EOF >"$PROFILE_SCRIPTS_DIR/urxvt.sh"
#!/bin/sh
export APPLRESDIR="$GLOBAL_CONFIG_DIR/urxvt"
EOF
    chmod +x "$PROFILE_SCRIPTS_DIR/urxvt.sh" && \

    cat <<-EOF >/etc/X11/xinit/xinitrc.d/urxvt.sh
#!/bin/sh
urxvtd -q -f -o
export TERMINAL="urxvtc"
EOF
    chmod +x /etc/X11/xinit/xinitrc.d/urxvt.sh
}

################################################################################

PACKAGES="vim \
          man-db \
          man-pages \
          texinfo \
          wpa_supplicant \
	  ttf-roboto \
          i3-gaps \
          i3lock \
          i3status
          rxvt-unicode \
          zsh \
          "

setup_hostname
setup_password

for package in `echo $PACKAGES`;do
    perform_task_arg install_package $package "Installing $package "
    ret=$?
    check_ok $ret "ERR: $package install exit code: $ret. Check $POSTINSTALL_LOG for more information\n"
done

perform_task configure_vim 'Configuring vim '
ret=$?
check_ok $ret "ERR: Configuring vim exit code: $ret. Check $POSTINSTALL_LOG for more information\n"

perform_task configure_urxvt 'Configuring urxvt '
ret=$?
check_ok $ret "ERR: Configuring urxvt exit code: $ret. Check $POSTINSTALL_LOG for more information\n"

print_msg 'Done\n'
