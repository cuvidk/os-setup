#!/bin/sh

cd /os-setup
. ./util.sh

GLOBAL_CONFIG_DIR='/etc/conf.d'
PROFILE_SCRIPTS_DIR='/etc/profile.d'
POST_CHROOT_LOG='log.post_partition'
GENERIC_ERR="Check $POST_CHROOT_LOG for more information."

PACKAGES="vim \
          ranger \
          man-db \
          man-pages \
          texinfo \
          networkmanager \
          nm-applet \
          gnome-keyring \
          ttf-fira-code \
          ttf-ubuntu-font-family \
          rxvt-unicode \
          pulseaudio \
          alsa-utils \
          grub \
          efibootmgr \
          os-prober \
	  base-devel \
          git \
          zsh \
          xorg-server \
	  xorg-xinit \
          i3-gaps \
          i3lock \
          i3status
          "

AUR_PACKAGES="google-chrome \
              ly-git \
              ttf-iosevka
             "

################################################################################

setup_hostname() {
    print_msg 'Pick a hostname (machine-name): '
    read hname
    echo "$hname" > /etc/hostname
    echo '127.0.0.1 localhost' >/etc/hosts
    echo '::1 localhost' >>/etc/hosts
    echo "127.0.1.1 $hname.localdomain $hname" >>/etc/hosts
}

setup_root_password() {
    print_msg 'Setting up root password\n'
    passwd >$(tty) 2>&1
}

setup_new_user() {
    print_msg 'Create a non-root username: '
    read g_user && \
        useradd -m $g_user && \
        print_msg "Setting up password for user $g_user\n" && \
        passwd $g_user >$(tty) 2>&1  && \
        print_msg "Adding $g_user as a sudoer\n" && \
        echo "$g_user ALL=(ALL) NOPASSWD:ALL" >"/etc/sudoers.d/$g_user"
}

fix_sudo() {
    echo 'Defaults targetpw' >"/etc/sudoers.d/$g_user"
    echo "$g_user ALL=(ALL) ALL" >>"/etc/sudoers.d/$g_user"
}

setup_timezone() {
    ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime && \
        hwclock --systohc
}

setup_localization() {
    sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen && \
        locale-gen && \
        echo 'LANG=en_US.UTF-8' >/etc/locale.conf
}

install_package() {
    package_name=$1
    pacman -S --noconfirm "$package_name"
}

install_aur_package() {
    aur_package_name="$1"
    git clone "https://aur.archlinux.org/$aur_package_name.git" && \
        chown -R $g_user:$g_user "./$aur_package_name" && \
        cd "./$aur_package_name" && \
        su $g_user --command="makepkg -s --noconfirm" && \
        pacman -U --noconfirm *.pkg.tar.xz
    ret=$?
    cd /os-setup
    return $ret
}

intel_integrated_graphics() {
    lspci -v | grep VGA | grep -i intel
}

nvidia_dedicated_graphics() {
    lspci -v | grep 3D | grep -i nvidia
}

enable_ucode_updates() {
    if [ -n "$(lscpu | grep Vendor | grep -i intel)" ]; then
        install_package intel-ucode
    elif [ -n "$(lscpu | grep Vendor | grep -i amd)" ]; then
        install_package amd-ucode
    fi
}

install_grub_bootloader() {
    print_msg '--------------------------------\n'
    print_msg 'Installing grub boot-loader\n'
    print_msg '--------------------------------\n'
    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB && \
        grub-mkconfig -o /boot/grub/grub.cfg >$(tty) 2>&1 && \
        print_msg '-------------SUCCESS------------\n' || \
        print_msg '-------------FAILED-------------\n'
}

enable_ly_display_manager() {
    systemctl disable getty@tty2.service
    systemctl enable ly.service
}

enable_network_manager() {
    systemctl enable NetworkManager.service
}

configure_gnome_keyring() {
    last_auth_entry=$(grep --line-number -E "^auth" /etc/pam.d/login | tail -n 1 | sed 's/\([0-9]\+\):.*/\1/')
    sed -i "$last_auth_entry s/^\(auth.*\)/&\nauth\toptional\tpam_gnome_keyring.so/" /etc/pam.d/login
    last_session_entry=$(grep --line-number -E "^session" /etc/pam.d/login | tail -n 1 | sed 's/\([0-9]\+\):.*/\1/')
    sed -i "$last_auth_entry s/^\(session.*\)/&\session\toptional\tpam_gnome_keyring.so auto_start/" /etc/pam.d/login
}

################################################################################

if [ -t 1 ]; then
    print_msg "ERR: Don't run this manually. Run post_partition.sh instead or read README.md for more information on how to use this installer.\n"
    exit 1
fi

for package in `echo $PACKAGES`; do
    perform_task_arg install_package $package "Installing package $package "
done

perform_task setup_hostname
perform_task setup_root_password
perform_task setup_new_user # NOTE: sudo package required before this step or else multiple installation steps will fail

perform_task setup_timezone 'Setting up timezone '
perform_task setup_localization 'Setting up localization '

for package in `echo $AUR_PACKAGES`; do
    perform_task_arg install_aur_package $package "Installing AUR package $package "
done

intel_integrated_graphics && perform_task_arg install_package xf86-video-intel "Installing intel driver for integrated graphics "
nvidia_dedicated_graphics && perform_task_arg install_package nvidia "Installing nvidia driver for dedicated graphics "
nvidia_dedicated_graphics && intel_integrated_graphics && perform_task_arg install_package nvidia-prime "Instaling nvidia prime (for optimus technology) "

perform_task enable_ly_display_manager 'Enabling Ly display manager '
perform_task enable_network_manager 'Enabling Network Manager '
perform_task configure_gnome_keyring 'Enabling sensitive information encryption through gnome keyring '

perform_task enable_ucode_updates 'Enabling ucode updates '
install_grub_bootloader

perform_task fix_sudo "Adding $g_user in sudoers list "

./reapply_configuration.sh

errors_encountered && print_msg "ERR: Errors were reported during installation. Check $POST_CHROOT_LOG for full install log.\n"
