#!/usr/bin/env bash
set -euo pipefail

### ─── 1) SYSTEM UPDATE & CLEANUP ─────────────────────────────────────────

PACMAN_FLAGS=(--noconfirm --needed --overwrite '*')
echo "🔄 Updating system & resolving conflicts..."
sudo pacman -Syu "${PACMAN_FLAGS[@]}"

# Purge leftover orphans and clean cache
orphans=$(pacman -Qtdq || true)
[[ -n "$orphans" ]] && sudo pacman -Rns --noconfirm $orphans
sudo pacman -Sc --noconfirm

### ─── 2) AUR HELPER (yay) INSTALL ────────────────────────────────────────

if ! command -v yay &>/dev/null; then
  echo "📦 Installing yay..."
  sudo pacman -S --noconfirm --needed git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  pushd /tmp/yay
    makepkg -si --noconfirm
  popd
  rm -rf /tmp/yay
fi

# Update AUR packages
yay -Syu --devel --timeupdate "${PACMAN_FLAGS[@]}"

### ─── 3) REMOVE CONFLICTING rofi-wayland ────────────────────────────────

if pacman -Qi rofi-wayland &>/dev/null || yay -Qi rofi-wayland &>/dev/null; then
  echo "⚔️  Removing conflicting rofi-wayland..."
  sudo pacman -Rns --noconfirm rofi-wayland || true
  yay -Rns --noconfirm rofi-wayland || true
fi

### ─── 4) CORE PACKAGE INSTALL ────────────────────────────────────────────

echo "📥 Installing Hyperland stack + tools..."
sudo pacman -S --noconfirm --needed \
  sddm                  \
  hyprland              \
  kitty                 \
  xorg-xwayland         \
  xorg-xlsclients       \
  wayland-protocols     \
  pipewire wireplumber  \
  blueman bluez-utils   \
  rofi                  \
  networkmanager        \
  polkit-gnome          \
  xdg-desktop-portal-hyprland \
  grub efibootmgr       \
  unzip wget curl

### ─── 5) SDDM & REDROCK THEME ──────────────────────────────────────────

echo "🎨 Installing Redrock theme for SDDM..."
yay -S --noconfirm --needed sddm-theme-redrock

echo "🔧 Enabling services: SDDM, Bluetooth, NetworkManager..."
sudo systemctl enable sddm bluetooth NetworkManager

echo "⚙️  Applying Redrock theme..."
sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/00-theme.conf
[Theme]
Current=redrock
CursorTheme=breeze_cursors
CursorSize=24
EOF

### ─── 6) USER Hyprland CONFIG ───────────────────────────────────────────

echo "📝 Writing Hyprland config..."
mkdir -p ~/.config/hypr
cat <<EOF > ~/.config/hypr/hyprland.conf
monitor=,preferred,auto,1.25

exec-once = blueman-applet
exec-once = kitty
exec-once = waybar

input {
  kb_layout = us
  follow_mouse = 1
  touchpad {
    natural_scroll = true
  }
}

bind = SUPER,RETURN,exec,kitty
bind = XF86PowerOff,A,exec,rofi -show drun
EOF

# (Optional) Rofi theme
mkdir -p ~/.config/rofi
cat <<EOF > ~/.config/rofi/config.rasi
rofi.theme: Monokai
EOF

### ─── 7) MINEGRUB THEME FOR GRUB ──────────────────────────────────────

echo "🎨 Cloning MineGRUB theme..."
git clone https://github.com/Lxtharia/minegrub-theme.git /tmp/minegrub-theme

echo "🚚 Installing MineGRUB..."
sudo mkdir -p /boot/grub/themes
sudo cp -r /tmp/minegrub-theme/minegrub /boot/grub/themes/minegrub

echo "⚙️  Configuring GRUB..."
sudo sed -i \
  -e 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/minegrub/theme.txt"|' \
  -e 's|^#GRUB_GFXMODE=.*|GRUB_GFXMODE="auto"|' \
  -e 's|^#GRUB_GFXPAYLOAD_LINUX=.*|GRUB_GFXPAYLOAD_LINUX="keep"|' \
  /etc/default/grub

echo "📦 Reinstalling GRUB & generating config..."
if [[ -d /sys/firmware/efi ]]; then
  sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
  sudo grub-install --target=i386-pc /dev/sda
fi
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Cleanup
rm -rf /tmp/minegrub-theme

echo
echo "✅ ALL SET! Reboot now to enjoy your:"
echo "   • macOS-style SDDM (Redrock)"  
echo "   • Hyperland + Kitty + Blueman + Waybar"  
echo "   • Power + A → Rofi launcher"  
echo "   • MineGRUB-themed GRUB bootloader"