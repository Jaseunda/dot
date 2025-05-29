#!/usr/bin/env bash
set -e

### 1) Update system & install base helpers
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git base-devel

### 2) Install yay (AUR helper) if missing
if ! command -v yay &>/dev/null; then
  pushd /opt
  sudo git clone https://aur.archlinux.org/yay.git
  sudo chown -R "$USER":"$USER" yay
  cd yay
  makepkg -si --noconfirm
  popd
fi

### 3) Install Wayland stack + Hyprland + apps
sudo pacman -S --noconfirm \
  sddm \
  hyprland \
  kitty \
  xorg-xwayland xorg-xlsclients \
  wayland wayland-protocols wlroots \
  pipewire wireplumber \
  blueman bluez bluez-utils \
  rofi \
  networkmanager \
  polkit-gnome \
  xdg-desktop-portal-hyprland \
  grub efibootmgr \
  unzip wget curl

### 4) Install macOS-style SDDM theme (“Redrock”)
yay -S --noconfirm sddm-theme-redrock

### 5) Enable essential services
sudo systemctl enable sddm
sudo systemctl enable bluetooth
sudo systemctl enable NetworkManager

### 6) Configure SDDM to use Redrock theme
sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/00-theme.conf
[Theme]
Current=redrock
CursorTheme=breeze_cursors
CursorSize=24
EOF

### 7) User’s Hyprland config
mkdir -p ~/.config/hypr
cat <<EOF > ~/.config/hypr/hyprland.conf
### HiDPI auto-scaling (adjust factor as needed)
monitor=,preferred,auto,1.25

### Autostart apps
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
# POWER key + A → Rofi drun
bind = XF86PowerOff,A,exec,rofi -show drun
EOF

### 8) (Optional) Simple Rofi theme
mkdir -p ~/.config/rofi
cat <<EOF > ~/.config/rofi/config.rasi
rofi.theme: Monokai
EOF

### 9) Install & configure MineGRUB theme
# Clone theme
git clone https://github.com/Lxtharia/minegrub-theme.git /tmp/minegrub-theme

# Copy into /boot
sudo mkdir -p /boot/grub/themes
sudo cp -r /tmp/minegrub-theme/minegrub /boot/grub/themes/minegrub

# Point GRUB at the new theme, enable auto gfx
sudo sed -i \
  -e 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/minegrub/theme.txt"|' \
  -e 's|^#GRUB_GFXMODE=.*|GRUB_GFXMODE="auto"|' \
  -e 's|^#GRUB_GFXPAYLOAD_LINUX=.*|GRUB_GFXPAYLOAD_LINUX="keep"|' \
  /etc/default/grub

### 10) Reinstall GRUB & regenerate config
if [ -d /sys/firmware/efi ]; then
  sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
  sudo grub-install --target=i386-pc /dev/sda
fi
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo
echo "✅ Done! Reboot, select the Hyprland session in SDDM, and enjoy:"
echo "   • macOS-style login (Redrock theme)  "
echo "   • Hyperland + Kitty + Blueman + Waybar  "
echo "   • Power + A launcher  "
echo "   • MineGRUB theme on GRUB  "
