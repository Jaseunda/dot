#!/bin/bash

echo ">>> Removing proprietary NVIDIA drivers..."
sudo pacman -Rns --noconfirm nvidia nvidia-utils nvidia-dkms nvidia-settings nvidia-lts

echo ">>> Installing open-source Nouveau drivers..."
sudo pacman -S --needed --noconfirm mesa xf86-video-nouveau libva-mesa-driver mesa-vdpau

echo ">>> Blacklisting leftover NVIDIA kernel modules..."
echo -e "blacklist nvidia\nblacklist nvidia_uvm\nblacklist nvidia_drm\nblacklist nvidia_modeset" | sudo tee /etc/modprobe.d/blacklist-nvidia.conf

echo ">>> Regenerating initramfs..."
sudo mkinitcpio -P

echo ">>> Updating GRUB config (in case nvidia_drm was set)"
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo ">>> Done. Reboot now to apply changes."
