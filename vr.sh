#!/usr/bin/env bash
set -euo pipefail

echo "===== RAM BOOSTER FOR HYPRLAND (Nouveau) — 8 GB EDITION ====="

# STEP 1: zram
echo "[1/5] Installing & enabling zram-generator (8 GB swap)…"
sudo pacman -S --needed --noconfirm zram-generator
cat <<EOF | sudo tee /etc/systemd/zram-generator.conf
[zram0]
# half of 16 GB = 8 GB 
zram-size = ram / 2
compression-algorithm = lz4
max-comp-streams = 4
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now systemd-zram-setup@zram0.service

# STEP 2: tmpfs
echo "[2/5] Configuring tmpfs mounts (/tmp → 6 GB, /var/log → 1 GB)…"
sudo sed -i '/\/tmp/d' /etc/fstab
sudo sed -i '/\/var\/log/d' /etc/fstab
echo "tmpfs   /tmp      tmpfs   defaults,noatime,mode=1777,size=6G    0 0" | sudo tee -a /etc/fstab
echo "tmpfs   /var/log  tmpfs   defaults,noatime,size=1G             0 0" | sudo tee -a /etc/fstab
sudo mount -a

# STEP 3: preload (optional)
echo "[3/5] Installing & enabling preload (if available)…"
if pacman -Si preload &>/dev/null; then
  sudo pacman -S --needed --noconfirm preload
  sudo systemctl enable --now preload
elif command -v yay &>/dev/null; then
  echo "→ preload not in official repos, installing via yay…"
  yay -S --needed --noconfirm preload
  sudo systemctl enable --now preload
else
  echo "⚠️  preload not found in repos and no AUR helper detected; skipping."
fi

# STEP 4: sysctl
echo "[4/5] Applying VM cache tunings…"
cat <<EOF | sudo tee /etc/sysctl.d/99-ram-boost.conf
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
EOF
sudo sysctl --system

# STEP 5: RAM‑disk
echo "[5/5] Creating an 8 GB RAM‑disk at ~/ramdisk…"
mkdir -p "$HOME/ramdisk"
if ! mount | grep -q "$HOME/ramdisk"; then
  sudo mount -t tmpfs -o size=8G tmpfs "$HOME/ramdisk"
  echo "[✓] Mounted 8 GB RAM‑disk at ~/ramdisk"
else
  echo "[i] ~/ramdisk already mounted"
fi

echo
echo "🎉 All done! Please reboot now to apply everything:"
echo "    sudo reboot"
echo
echo "After reboot, you’ll have:"
echo "  • 8 GB compressed swap in RAM via systemd-zram-setup@zram0"
echo "  • /tmp in 6 GB RAM‑backed tmpfs"
echo "  • /var/log in 1 GB tmpfs"
echo "  • An 8 GB RAM‑disk at ~/ramdisk"
echo "  • preload (if installed) and VM cache tuning"
echo
echo "Enjoy your buttery‑smooth 4K@75 Hz Hyprland experience on Nouveau!"