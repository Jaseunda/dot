#!/usr/bin/env bash
set -euo pipefail

# 1) Install NVIDIA 470xx DKMS driver and build tools
sudo pacman -S --needed --noconfirm nvidia-470xx-dkms git base-devel

# 2) Clone the AUR nvidia-470xx-utils and apply the Linux 6.14 patch
cd "$(mktemp -d)"
git clone https://aur.archlinux.org/nvidia-470xx-utils.git
cd nvidia-470xx-utils

# Fetch the community “kernel-6.14” patch for nvidia-470xx-utils
curl -fsSL \
  https://gist.githubusercontent.com/joanbm/d0cb8790ca610fbd2c2e43f30707ce18/raw/kernel-6.14.patch \
  -o kernel-6.14.patch

# Apply and rebuild
git apply kernel-6.14.patch                # fixes wlr_backend_autocreate() crashes  [oai_citation:0‡Gist](https://gist.github.com/joanbm/d0cb8790ca610fbd2c2e43f30707ce18?permalink_comment_id=5483671&utm_source=chatgpt.com)
makepkg -si --noconfirm                     # builds & installs nvidia-470xx-utils

# 3) Enable NVIDIA DRM modesetting (required by wlroots’ NVIDIA backend)
echo 'options nvidia-drm modeset=1' | sudo tee /etc/modprobe.d/nvidia-drm.conf

# 4) Rebuild initramfs so the new driver & modeset get picked up
sudo mkinitcpio -P

# 5) Ensure Hyprland uses the NVIDIA backend
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
mkdir -p "$(dirname "$HYPR_CONF")"
grep -qxF 'wlr-backend = "nvidia"' "$HYPR_CONF" 2>/dev/null \
  || echo 'wlr-backend = "nvidia"' >> "$HYPR_CONF"

# 6) (Optional) Export the backend env var for TTY launches
grep -qxF 'export WLR_BACKEND=nvidia' "$HOME/.bashrc" 2>/dev/null \
  || echo 'export WLR_BACKEND=nvidia' >> "$HOME/.bashrc"

echo
echo "All done! 🎉"
echo "→ Please reboot now: sudo reboot"
