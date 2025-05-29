#!/usr/bin/env bash
set -euo pipefail

### ─── 1) SYSTEM UPDATE & CLEANUP ─────────────────────────────────────────

# Ensure pacman uses no-confirm and latest, auto-overwrite conflicting files
PACMAN_FLAGS=(--noconfirm --needed --overwrite '*')
echo "🔄 Updating system & resolving conflicts..."
sudo pacman -Syu "${PACMAN_FLAGS[@]}"

# Remove orphaned packages
orphans=$(pacman -Qtdq || true)
if [[ -n "$orphans" ]]; then
  echo "🗑 Removing orphaned packages..."
  sudo pacman -Rns --noconfirm $orphans
fi

# Clean out cached packages not currently installed
echo "🧹 Cleaning package cache..."
sudo pacman -Sc --noconfirm


### ─── 2) AUR HELPER (yay) INSTALL ────────────────────────────────────────

if ! command -v yay &> /dev/null; then
  echo "📦 Installing yay (AUR helper)..."
  sudo pacman -S --noconfirm --needed git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  pushd /tmp/yay
    makepkg -si --noconfirm
  popd
  rm -rf /tmp/yay
fi

# Keep AUR packages up-to-date & auto-overwrite if needed
YAY_FLAGS=(--noconfirm --needed --overwrite '*')
echo "🔄 Updating AUR packages..."
yay -Syu --devel --timeupdate "${YAY_FLAGS[@]}"


### ─── 3) CORE PACKAGE INSTALL ────────────────────────────────────────────

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


### ─── 4) SDDM + REDROCK (macOS-style) GREETER ───────────────────────

echo "🎨 Installing Redrock theme for SDDM..."
yay -S --noconfirm --needed sddm-theme-redrock

echo "🔧 Enabling services: SDDM, Bluetooth, NetworkManager..."
sudo systemctl enable sddm bluetooth NetworkManager

echo "⚙️  Configuring SDDM to use Redrock theme..."
sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/00-theme.conf
[Theme]
Current=redrock
CursorTheme=breeze_cursors
CursorSize=24
EOF


### ─── 5) USER Hyprland CONFIG ───────────────────────────────────────────

echo "📝 Writing Hyprland config (~/.config/hypr/hyprland.conf)..."
mkdir -p ~/.config/hypr
cat <<EOF > ~/.config/hypr/hyprland.conf
### HiDPI auto-scaling (adjust factor if needed)
monitor=,preferred,auto,1.25

### Autostart
exec-once = blueman-applet
exec-once = kitty
exec-once = waybar

### Input
input {
  kb_layout = us
  follow_mouse = 1
  touchpad {
    natural_scroll = true
  }
}

### Keybindings
# SUPER+Enter → Kitty
bind = SUPER,RETURN,exec,kitty
# POWER key + A → Rofi application launcher
bind = XF86PowerOff,A,exec,rofi -show drun
EOF

# (Optional) Simple Rofi theme
mkdir -p ~/.config/rofi
cat <<EOF > ~/.config/rofi/config.rasi
rofi.theme: Monokai
EOF


### ─── 6) MINEGRUB THEME FOR GRUB ──────────────────────────────────────

echo "🎨 Cloning MineGRUB theme..."
git clone https://github.com/Lxtharia/minegrub-theme.git /tmp/minegrub-theme

echo "🚚 Installing MineGRUB to /boot..."
sudo mkdir -p /boot/grub/themes
sudo cp -r /tmp/minegrub-theme/minegrub /boot/grub/themes/minegrub

echo "⚙️  Configuring GRUB to use the MineGRUB theme..."
sudo sed -i \
  -e 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/minegrub/theme.txt"|' \
  -e 's|^#GRUB_GFXMODE=.*|GRUB_GFXMODE="auto"|' \
  -e 's|^#GRUB_GFXPAYLOAD_LINUX=.*|GRUB_GFXPAYLOAD_LINUX="keep"|' \
  /etc/default/grub

echo "📦 Reinstalling GRUB & regenerating config..."
if [[ -d /sys/firmware/efi ]]; then
  sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
  sudo grub-install --target=i386-pc /dev/sda
fi
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Cleanup
rm -rf /tmp/minegrub-theme

echo
echo "✅ ALL SET! Reboot now to enjoy:"
echo "   • macOS-style SDDM login (Redrock)"  
echo "   • Hyperland + Kitty + Waybar + Blueman"  
echo "   • Power + A → Rofi launcher"  
echo "   • MineGRUB theme on GRUB"  