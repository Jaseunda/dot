#!/bin/bash

echo "🔧 Uninstalling Hyprland and related components..."

# 1. Stop and disable services
echo "⛔ Disabling display and Bluetooth services..."
sudo systemctl disable --now greetd 2>/dev/null
sudo systemctl disable --now sddm 2>/dev/null
sudo systemctl disable --now bluetooth 2>/dev/null

# 2. Remove packages
echo "🧹 Removing packages..."
sudo pacman -Rns --noconfirm hyprland hyprland-git kitty waybar greetd tuigreet sddm \
  xdg-desktop-portal-hyprland wlroots bluez bluez-utils \
  foot alacritty wofi dunst mako rofi 2>/dev/null

# 3. Remove config directories
echo "🗑 Removing config directories..."
rm -rf ~/.config/hypr ~/.config/waybar ~/.config/kitty ~/.config/wofi ~/.config/dunst \
  ~/.config/mako ~/.config/tuigreet ~/.config/sddm ~/.config/rofi ~/.cache/tuigreet

# 4. Clean up unused packages
echo "🧼 Removing orphaned dependencies..."
sudo pacman -Rns --noconfirm $(pacman -Qdtq) 2>/dev/null

# 5. Clear pacman cache
echo "🧽 Clearing package cache..."
sudo pacman -Sc --noconfirm

echo "✅ Uninstall complete. You may reboot or install a new DE or WM now."
