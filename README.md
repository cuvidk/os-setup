# os-setup

Installer scripts for arch-linux that also automates a lot of setup steps and installs additional usefull software like i3 window manager, a login manager, a bunch of developer tools like urxvt terminal emulator, vim, zsh, software for configuring a network connection, software for controlling volume settings, google chrome, etc (for a full list see PACKAGES variable in post_chroot.sh).

**NOTE**: This installer supports only UEFI/GPT layout; for more details, see https://wiki.archlinux.org/index.php/Partitioning#Example_layouts

## Installation
    1. Create a bootable arch-linux USB and boot into it in UEFI mode
    2. Create some swap partition using a tool of your preference e.g fdisk
    3. mkswap /dev/<swap_partition>
    4. swapon /dev/<swap_partition>
    5. Create a root partition
    6. mkfs.ext4 /dev/<root_partition>
    7. mount /dev/<root_partition> /mnt
    8. Check for existent EFI partition. You should have one if you're planning to dualboot alongside another OS that you have installed (e.g windows). If you're missing it, you have to create it. See: https://wiki.archlinux.org/index.php/EFI_system_partition#Create_the_partition
    9. mkdir /mnt/efi && mount /dev/<efi_partition>  /mnt/efi
    10. [ Optional ] Create any additional partition, format it and mount it wherever you want under /mnt
    11. pacman -Sy && pacman -S git
    12. git clone --recursive https://github.com/cuvidk/os-setup && cd os-setup
    13. Edit config.template with your information removing any additional user rows if you don't need them
    14. ./install.sh --config config.template

