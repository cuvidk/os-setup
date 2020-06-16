#!/bin/sh

. /os-setup/util.sh

GLOBAL_CONFIG_DIR='/etc/conf.d'
PROFILE_SCRIPTS_DIR='/etc/profile.d'
POST_CHROOT_LOG='log.post_partition'
GENERIC_ERR="Check $POST_CHROOT_LOG for more information."

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
          os-prober \
          zsh \
          "


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
        cp /os-setup/config-files/vim/.vimrc "$GLOBAL_CONFIG_DIR/vim/vimrc"
}

configure_urxvt() {
    mkdir -p "$GLOBAL_CONFIG_DIR/urxvt" && \
    cp /os-setup/config-files/urxvt/URxvt "$GLOBAL_CONFIG_DIR/urxvt/URxvt" && \

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

if [ -t 1 ]; then
    print_msg "ERR: Don't run this manually. Run post_partition.sh instead or read README.md for more information about how to use this installer.\n"
    exit 1
fi

setup_hostname
setup_password

for package in `echo $PACKAGES`;do
    perform_task_arg install_package $package "Installing $package " || \
        print_msg "ERR: $package install exit code: $ret. $GENERIC_ERR\n"
done

intel_integrated_graphics && perform_task_arg install_package xf86-video-intel "Installing intel driver for integrated graphics "
nvidia_dedicated_graphics && perform_task_arg install_package nvidia "Installing nvidia driver for dedicated graphics "
nvidia_dedicated_graphics && intel_integrated_graphics && perform_task_arg install_package nvidia-prime "Instaling nvidia prime (for optimus technology) "

perform_task configure_vim 'Configuring vim ' || \
    print_msg "ERR: Configuring vim exit code: $ret. $GENERIC_ERR\n"

perform_task configure_urxvt 'Configuring urxvt ' || \
    print_msg "ERR: Configuring urxvt exit code: $ret. $GENERIC_ERR\n"

print_msg 'Done\n'
