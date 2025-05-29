#!/bin/bash

set -e

echo "Running Hyde post-install patch..."

# Detect current user (assumes running as that user)
CURRENT_USER=$(logname)
echo "Detected user: $CURRENT_USER"

# Remove legacy NVIDIA drivers if installed
echo "Removing legacy NVIDIA drivers if present..."
sudo pacman -Rns --noconfirm nvidia-470xx-dkms nvidia-470xx-utils || true

# Install latest NVIDIA drivers (skip if already installed)
if ! pacman -Qs nvidia | grep -q nvidia; then
  echo "Installing latest NVIDIA drivers..."
  sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
else
  echo "Latest NVIDIA drivers already installed, skipping."
fi

# Enable and start Bluetooth
echo "Enabling Bluetooth service..."
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service

# Fix Hyprland config user ownership (if needed)
HYPR_CONFIG="/home/$CURRENT_USER/.config/hypr"
if [ -d "$HYPR_CONFIG" ]; then
  echo "Fixing ownership for $HYPR_CONFIG"
  sudo chown -R "$CURRENT_USER":"$CURRENT_USER" "$HYPR_CONFIG"
fi

# Optional: regenerate Hyprland environment file or fix display detection here if needed

echo "Post-install patch complete. You can now reboot and try running Hyprland."
