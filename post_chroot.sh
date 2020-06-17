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

enable_ucode_updates() {
    if [ -n "$(lscpu | grep Vendor | grep -i intel)" ]; then
        pacman -S intel-ucode
    elif [ -n "$(lscpu | grep Vendor | grep -i amd)" ]; then
        pacman -S amd-ucode
    fi
}

install_grub_bootloader() {
    print_msg 'Installing grub boot-loader\n'
    print_msg '---------------------------\n'
    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB && \
        grub-mkconfig -o /boot/grub/grub.cfg >$(tty) 2>&1 && \
        print_msg '----------SUCCESS----------\n' || \
        print_msg '-----------FAILED----------\n'
}

################################################################################

if [ -t 1 ]; then
    print_msg "ERR: Don't run this manually. Run post_partition.sh instead or read README.md for more information on how to use this installer.\n"
    exit 1
fi

setup_hostname
setup_password

for package in `echo $PACKAGES`; do
    perform_task_arg install_package $package "Installing package $package "
done

intel_integrated_graphics && perform_task_arg install_package xf86-video-intel "Installing intel driver for integrated graphics "
nvidia_dedicated_graphics && perform_task_arg install_package nvidia "Installing nvidia driver for dedicated graphics "
nvidia_dedicated_graphics && intel_integrated_graphics && perform_task_arg install_package nvidia-prime "Instaling nvidia prime (for optimus technology) "

perform_task enable_ucode_updates 'Enabling ucode updates '
install_grub_bootloader

perform_task configure_vim 'Configuring vim '
perform_task configure_urxvt 'Configuring urxvt '

[ g_err_flag -eq 1 ] && print_msg "ERR: Errors were reported during installation. Check $POST_CHROOT_LOG for full install log.\n"

print_msg 'Done\n'
