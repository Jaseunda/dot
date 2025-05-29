#!/usr/bin/env bash
set -euo pipefail

echo "→ Installing NVIDIA 470‑series DKMS driver and build tools…"
sudo pacman -S --needed --noconfirm nvidia-470xx-dkms git base-devel

echo "→ Cloning nvidia-470xx-utils AUR repo…"
BUILD_DIR="$(mktemp -d)"
git clone https://aur.archlinux.org/nvidia-470xx-utils.git "$BUILD_DIR/nvidia-470xx-utils"
cd "$BUILD_DIR/nvidia-470xx-utils"

echo "→ Downloading the Linux 6.14 patch…"
curl -fsSL \
  https://raw.githubusercontent.com/CachyOS/CachyOS-PKGBUILDS/master/nvidia/nvidia-470xx-utils/kernel-6.14.patch \
  -o kernel-6.14.patch                     # fix for 6.14‑rc1+  [oai_citation:0‡GitHub](https://github.com/CachyOS/CachyOS-PKGBUILDS/blob/master/nvidia/nvidia-470xx-utils/kernel-6.14.patch?utm_source=chatgpt.com)

echo "→ Applying patch and building…"
git apply kernel-6.14.patch
makepkg -si --noconfirm                  # builds & installs patched utils

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