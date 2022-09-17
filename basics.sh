#!/bin/bash
# This script is notes on what to do first when booting from archiso
GITHUB_USERNAME=gauntletwizard

# Setup SSH so I can remote in
systemctl start sshd
mkdir -p ~/.ssh
curl "https://github.com/${GITHUB_USERNAME}.keys" > ~/.ssh/authorized_keys

# Start off by syncing
pacman -Sy
# Install git, used for bootstrapping
pacman -S glibc git

# Setup ZFS
git clone https://github.com/eoli3n/archiso-zfs.git
archiso-zfs/init
# Allow grub to detect our root device
export ZPOOL_VDEV_NAME_PATH=YES

tmux new-session -d
tmux set-option -g prefix C-a
tmux bind-key C-a last-window


# Below here are commands for the specific installation:
zpool import toph -R /mnt
zfs load-key -a
zfs mount -a
arch-chroot /mnt

mount -a


EFIFSUUID="$(grub-probe /boot/efi/ --target fs_uuid)"
cat <<EOF > grub.embed.cfg 
search --fs-uuid ${EFIFSUUID} root
set prefix=(\$root)/boot/grub
EOF

grub-mkimage --format=x86_64-efi -p "" -o foo.grub -c grub.embed.cfg

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
cp foo.grub /boot/efi/EFI/GRUB/grubx64.efi
# Check that it's configured and installed
efibootmgr
ZPOOL_VDEV_NAME_PATH=YES grub-mkconfig -o /boot/efi/grub/grub.cfg


# Yay, my preferred tool for interacting with AUR/Replacing pacman
# Install deps for yay
pacman -S binutils fakeroot base-devel make
useradd -m install
su -l install -c 'git clone https://aur.archlinux.org/yay-git.git && cd yay-git && makepkg -si'


