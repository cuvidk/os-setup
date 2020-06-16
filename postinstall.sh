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

perform_task check_uefi_boot 'Checking if system is booted in UEFI mode '
ret=$?
[ $ret != 0 ] && print_msg 'The installer scripts are limited to UEFI systems.\n' && exit 1

perform_task check_root 'Checking for root '
ret=$?
[ $ret != 0 ] && print_msg 'This script needs to be run as root.\n' && exit 2

perform_task check_conn 'Checking for internet connection '
ret=$?
[ $ret != 0 ] && print_msg 'Unable to reach the internet. Check your connection.\n' && exit 3

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

intel_integrated_graphics() {
    lspci -v | grep VGA | grep -i intel
}

nvidia_dedicated_graphics() {
    lspci -v | grep 3D | grep -i nvidia
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
          xorg-server \
	  xorg-xinit \
          grub \
          efibootmgr \
          osprober \
          zsh \
          "

setup_hostname
setup_password

for package in `echo $PACKAGES`;do
    perform_task_arg install_package $package "Installing $package " || \
        print_msg "ERR: $package install exit code: $ret. Check $POSTINSTALL_LOG for more information\n"
done

intel_integrated_graphics && perform_task_arg install_package xf86-video-intel "Installing intel driver for integrated graphics "
nvidia_dedicated_graphics && perform_task_arg install_package nvidia "Installing nvidia driver for dedicated graphics "
nvidia_dedicated_graphics && intel_integrated_graphics && perform_task_arg install_package nvidia-prime "Instaling nvidia prime (for optimus technology) "

perform_task configure_vim 'Configuring vim ' || \
    print_msg "ERR: Configuring vim exit code: $ret. Check $POSTINSTALL_LOG for more information\n"

perform_task configure_urxvt 'Configuring urxvt ' || \
    print_msg "ERR: Configuring urxvt exit code: $ret. Check $POSTINSTALL_LOG for more information\n"

print_msg 'Done\n'
