#!/usr/bin/env bash
set -euo pipefail

LOG=~/hyprland-errors.log
echo "→ Capturing any current Hyprland/WLROOTS errors to $LOG"
journalctl -b -p err -o short-iso | grep -iE 'hyprland|wlr_backend' > "$LOG"
echo "  • Saved: $LOG"

# 1) Check for AUR helper (we need one to install linux612)
if ! command -v yay &>/dev/null; then
  cat <<EOF

ERROR: 'yay' not found.  
We need an AUR helper to install linux612.  
Please install yay (or another AUR helper), for example:

  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si

Then re-run this script.

EOF
  exit 1
fi

# 2) Install linux612 and headers from AUR
echo "→ Installing linux612 & linux612-headers via yay (AUR)…"
yay -S --needed --noconfirm linux612 linux612-headers

# 3) Rebuild bootloader (GRUB) config
echo "→ Rebuilding GRUB configuration…"
if command -v grub-mkconfig &>/dev/null; then
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  echo "  • GRUB updated; on next reboot choose the 6.12 entry."
else
  echo "  • grub-mkconfig not found. Update your bootloader manually to include linux612."
fi

echo
echo "✅ Done."
echo "→ Reboot now: sudo reboot"
echo
echo "After booting linux 6.12, run 'Hyprland'."
echo "If it crashes again, please paste the contents of $LOG here."