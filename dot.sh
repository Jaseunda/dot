#!/bin/bash
set -e

echo "### Updating system..."
sudo pacman -Syu --noconfirm

echo "### Installing NVIDIA drivers and dependencies..."
sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings linux-headers

echo "### Enabling NVIDIA DRM modeset..."
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf

echo "### Rebuilding initramfs..."
sudo mkinitcpio -P

echo "### Installing Hyprland, kitty terminal, waybar, sddm..."
sudo pacman -S --noconfirm hyprland kitty waybar sddm

echo "### Enabling SDDM display manager..."
sudo systemctl enable sddm.service

echo "### Creating minimal Hyprland config..."
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprland.conf <<EOF
monitor=*
dpi=96

exec-once=kitty &
exec-once=waybar &

bind=SUPER+ENTER,kitty
bind=SUPER+Q,exit

# Basic floating window for popups
floatinglayout=titlebar

EOF

echo "### All done! Please reboot and select Hyprland session in SDDM."
