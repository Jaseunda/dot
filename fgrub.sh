#!/usr/bin/env bash
set -euo pipefail

# ─── CONFIGURE THESE IF NEEDED ─────────────────────────
ROOT_DEV="/dev/nvme0n1p5"
HOME_DEV="/dev/nvme0n1p6"
EFI_DEV ="/dev/nvme0n1p2"
# ────────────────────────────────────────────────────────

echo "⏳ Mounting partitions..."
mkdir -p /mnt /mnt/home /mnt/boot/efi
mount "${ROOT_DEV}" /mnt
mount "${HOME_DEV}" /mnt/home
mount "${EFI_DEV}"  /mnt/boot/efi

echo "🔀 Chrooting and reinstalling GRUB..."
arch-chroot /mnt /bin/bash <<'EOF'
  grub-install --target=x86_64-efi \
                --efi-directory=/boot/efi \
                --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo "✅ Done! You can now reboot into your fixed GRUB."
