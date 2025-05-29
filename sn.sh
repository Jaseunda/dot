#!/bin/bash

echo "======== Hyprland Nouveau Fix Script ========"

# STEP 1: Remove all NVIDIA proprietary 470xx drivers
echo "[*] Removing NVIDIA 470xx proprietary drivers (if any)..."
sudo pacman -Rns --noconfirm nvidia-470xx-dkms nvidia-470xx-utils lib32-nvidia-470xx-utils nvidia-settings nvidia-utils || echo "[i] NVIDIA 470xx not installed or already removed."

# STEP 2: Install Nouveau and Mesa stack
echo "[*] Installing open-source drivers (nouveau, mesa)..."
sudo pacman -S --noconfirm --needed xf86-video-nouveau mesa libglvnd

# STEP 3: Rebuild initramfs (in case modules changed)
echo "[*] Rebuilding initramfs..."
sudo mkinitcpio -P

# STEP 4: Detect which /dev/dri/cardX is using nouveau
echo "[*] Detecting which GPU is running nouveau..."

NOUVEAU_CARD=""
for CARD in /dev/dri/card*; do
  DRIVER=$(readlink /sys/class/drm/$(basename $CARD)/device/driver 2>/dev/null | awk -F/ '{print $NF}')
  if [[ "$DRIVER" == "nouveau" ]]; then
    NOUVEAU_CARD="$CARD"
    break
  fi
done

if [[ -z "$NOUVEAU_CARD" ]]; then
  echo "[!] No GPU using the 'nouveau' driver found. Check hardware or reboot."
  exit 1
fi

echo "[✓] Nouveau is active on: $NOUVEAU_CARD"

# STEP 5: Patch Hyprland config
echo "[*] Updating Hyprland config with proper DRM settings..."

mkdir -p ~/.config/hypr
HYPER_CONF=~/.config/hypr/hyprland.conf

# Backup if needed
if [[ -f "$HYPER_CONF" ]]; then
  cp "$HYPER_CONF" "${HYPER_CONF}.bak"
  echo "[i] Backed up existing hyprland.conf to hyprland.conf.bak"
fi

# Update or insert WLR_BACKEND and WLR_DRM_DEVICES
grep -q "WLR_BACKEND" "$HYPER_CONF" && \
  sed -i 's|^env = WLR_BACKEND.*|env = WLR_BACKEND,drm|' "$HYPER_CONF" || \
  echo "env = WLR_BACKEND,drm" >> "$HYPER_CONF"

grep -q "WLR_DRM_DEVICES" "$HYPER_CONF" && \
  sed -i "s|^env = WLR_DRM_DEVICES.*|env = WLR_DRM_DEVICES,$NOUVEAU_CARD|" "$HYPER_CONF" || \
  echo "env = WLR_DRM_DEVICES,$NOUVEAU_CARD" >> "$HYPER_CONF"

echo "[✓] Hyprland config updated."

# STEP 6: Inform next steps
echo
echo "============================================"
echo "✅ Nouveau installed and configured!"
echo "→ Reboot your system to apply all changes:"
echo
echo "    sudo reboot"
echo
echo "After reboot, launch Hyprland and it should work without crashing."
echo "============================================"