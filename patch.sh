#!/usr/bin/env bash
set -euo pipefail

echo "→ Installing NVIDIA 470‑series DKMS driver and build tools…"
sudo pacman -S --needed --noconfirm nvidia-470xx-dkms git base-devel

echo "→ Cloning CachyOS-PKGBUILDS (with 6.14 patch)…"
BUILD_DIR="$(mktemp -d)"
git clone https://github.com/CachyOS/CachyOS-PKGBUILDS.git "$BUILD_DIR/CachyOS-PKGBUILDS"

echo "→ Building nvidia-470xx-utils from CachyOS PKGBUILDS…"
cd "$BUILD_DIR/CachyOS-PKGBUILDS/nvidia/nvidia-470xx-utils"
# This directory already contains kernel-6.14.patch to fix wlroots’ NVIDIA backend crashes  [oai_citation:0‡GitHub](https://github.com/CachyOS/CachyOS-PKGBUILDS/blob/master/nvidia/nvidia-470xx-utils/kernel-6.14.patch?utm_source=chatgpt.com)
makepkg -si --noconfirm

echo "→ Enabling NVIDIA DRM modesetting…"
echo 'options nvidia-drm modeset=1' | sudo tee /etc/modprobe.d/nvidia-drm.conf

echo "→ Rebuilding initramfs…"
sudo mkinitcpio -P

echo "→ Ensuring Hyprland uses the NVIDIA backend…"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
mkdir -p "${HYPR_CONF%/*}"
grep -qxF 'wlr-backend = "nvidia"' "$HYPR_CONF" 2>/dev/null \
  || echo 'wlr-backend = "nvidia"' >> "$HYPR_CONF"

grep -qxF 'export WLR_BACKEND=nvidia' "$HOME/.bashrc" 2>/dev/null \
  || echo 'export WLR_BACKEND=nvidia' >> "$HOME/.bashrc"

echo
echo "✅ All done! Please reboot now with: sudo reboot"