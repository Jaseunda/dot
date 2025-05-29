#!/usr/bin/env bash
set -euo pipefail

echo "→ Installing Linux 6.12 kernel and headers…"
sudo pacman -S --needed --noconfirm linux612 linux612-headers

echo "→ Rebuilding GRUB configuration…"
if [ -x "$(command -v grub-mkconfig)" ]; then
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  echo "  • GRUB config updated. On next reboot, choose 'Arch Linux, with Linux 6.12'."
else
  echo "  • Warning: grub-mkconfig not found. If you’re using systemd-boot or another bootloader, update it manually to include the 6.12 kernel."
fi

echo "→ Gathering Hyprland/WLROOTS error logs (if any)…"
journalctl -b -p err -o short-iso | grep -iE 'hyprland|wlr_backend' > ~/hyprland-errors.log
echo "  • Saved errors to ~/hyprland-errors.log"

echo
echo "✅ Done. Now reboot:"
echo "    sudo reboot"
echo
echo " → After reboot select the 6.12 kernel in GRUB, then run 'Hyprland'."
echo " → If it still crashes, please send me the contents of ~/hyprland-errors.log so we can identify the remaining issue."
