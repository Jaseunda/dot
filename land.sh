#!/usr/bin/env bash
set -euo pipefail

### ─── VARIABLES ──────────────────────────────────────────────────────────

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PACMAN_FLAGS=(--noconfirm --needed --overwrite '*')
BASE_PACKAGES=(
    sddm
    hyprland
    kitty
    waybar
    xorg-xwayland
    xorg-xlsclients
    wayland-protocols
    wlroots
    pipewire
    wireplumber
    blueman
    bluez-utils
    rofi
    networkmanager
    polkit-gnome
    xdg-desktop-portal-hyprland
    grub
    efibootmgr
    unzip
    wget
    curl
    git
    grim
    slurp
    wl-clipboard
    ttf-jetbrains-mono-nerd
)

### ─── HELPER FUNCTIONS ───────────────────────────────────────────────────

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

### ─── 1) SYSTEM UPDATE & CLEANUP ─────────────────────────────────────────

log "Updating system & resolving conflicts..."
sudo pacman -Syu "${PACMAN_FLAGS[@]}"

log "Cleaning up orphaned packages..."
orphans=$(pacman -Qtdq || true)
[[ -n "$orphans" ]] && sudo pacman -Rns --noconfirm $orphans
sudo pacman -Sc --noconfirm

### ─── 2) YAY INSTALLATION ─────────────────────────────────────────────────

if ! command -v yay &>/dev/null; then
    log "Installing yay..."
    sudo pacman -S --noconfirm --needed git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
fi

log "Updating AUR packages..."
yay -Syu --devel --timeupdate "${PACMAN_FLAGS[@]}"

### ─── 3) REMOVE CONFLICTING rofi-wayland ────────────────────────────────

if pacman -Qi rofi-wayland &>/dev/null || yay -Qi rofi-wayland &>/dev/null; then
    log "Removing conflicting rofi-wayland..."
    sudo pacman -Rns --noconfirm rofi-wayland || true
    yay -Rns --noconfirm rofi-wayland || true
fi

### ─── 4) PACKAGE INSTALLATION ───────────────────────────────────────────

log "Installing base packages..."
sudo pacman -S "${PACMAN_FLAGS[@]}" "${BASE_PACKAGES[@]}"

### ─── 5) SDDM & THEME CONFIGURATION ───────────────────────────────────────

log "Installing SDDM Redrock theme..."
yay -S --noconfirm --needed sddm-theme-redrock

log "Configuring SDDM..."
sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/00-theme.conf
[Theme]
Current=redrock
CursorTheme=breeze_cursors
CursorSize=24
EOF

### ─── 6) HYPRLAND CONFIGURATION ────────────────────────────────────────────

log "Configuring Hyprland..."
mkdir -p ~/.config/hypr
cat <<'EOF' > ~/.config/hypr/hyprland.conf
# Monitor configuration
monitor=,preferred,auto,1.25

# Set variables
$mainMod = SUPER
$terminal = kitty
$menu = rofi -show drun

# Autostart
exec-once = waybar
exec-once = blueman-applet
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
        tap-to-click = true
        drag_lock = true
    }
    sensitivity = 0
}

# General window layout
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Decoration
decoration {
    rounding = 10
    blur = true
    blur_size = 3
    blur_passes = 1
    blur_new_optimizations = true
    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Keybindings
bind = $mainMod, RETURN, exec, $terminal
bind = $mainMod, Q, killactive,
bind = $mainMod, SPACE, exec, $menu
bind = $mainMod, F, fullscreen
bind = XF86PowerOff, A, exec, rofi -show drun

# Workspace bindings
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
EOF

### ─── 7) ROFI CONFIGURATION ───────────────────────────────────────────────

log "Configuring Rofi..."
mkdir -p ~/.config/rofi
cat <<'EOF' > ~/.config/rofi/config.rasi
configuration {
    modi: "drun,run";
    show-icons: true;
    icon-theme: "Papirus";
}

@theme "Monokai"
EOF

### ─── 8) WAYBAR CONFIGURATION ─────────────────────────────────────────────

log "Configuring Waybar..."
mkdir -p ~/.config/waybar
cat <<'EOF' > ~/.config/waybar/config
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}"
    },
    "clock": {
        "format": "{:%I:%M %p}",
        "format-alt": "{:%Y-%m-%d}"
    },
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    "network": {
        "format-wifi": "{essid} ",
        "format-ethernet": "󰈁",
        "format-disconnected": "󰖪"
    },
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "",
        "format-icons": {
            "default": ["", "", ""]
        }
    },
    "tray": {
        "spacing": 10
    }
}
EOF

### ─── 9) MINEGRUB THEME INSTALLATION ─────────────────────────────────────

log "Installing MineGRUB theme..."
git clone https://github.com/Lxtharia/minegrub-theme.git /tmp/minegrub-theme
sudo mkdir -p /boot/grub/themes/minegrub
sudo cp -r /tmp/minegrub-theme/minegrub/* /boot/grub/themes/minegrub/

log "Configuring GRUB..."
# Remove existing theme settings
sudo sed -i '/^GRUB_THEME=/d' /etc/default/grub
sudo sed -i '/^GRUB_GFXMODE=/d' /etc/default/grub
sudo sed -i '/^GRUB_GFXPAYLOAD_LINUX=/d' /etc/default/grub

# Add new theme settings
cat <<'EOF' | sudo tee -a /etc/default/grub
GRUB_THEME="/boot/grub/themes/minegrub/theme.txt"
GRUB_GFXMODE="auto"
GRUB_GFXPAYLOAD_LINUX="keep"
EOF

log "Installing GRUB..."
if [[ -d /sys/firmware/efi ]]; then
    sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
    # Detect the primary disk
    DISK=$(lsblk -dno NAME,TYPE | awk '$2=="disk" {print $1}' | head -n1)
    [[ -n "$DISK" ]] && sudo grub-install --target=i386-pc "/dev/${DISK}"
fi

log "Generating GRUB configuration..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

### ─── 10) ENABLE SERVICES ────────────────────────────────────────────────

log "Enabling system services..."
sudo systemctl enable sddm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

### ─── 11) CLEANUP ───────────────────────────────────────────────────────

log "Cleaning up temporary files..."
rm -rf /tmp/{yay,minegrub-theme}

### ─── 12) COMPLETION ──────────────────────────────────────────────────────

success "Installation complete! Your system is now configured with:"
echo "   • Hyprland with modern animations and layouts"
echo "   • SDDM with Redrock theme"
echo "   • Waybar with custom styling"
echo "   • MineGRUB theme for GRUB"
echo "   • Configured Rofi launcher"
echo
echo "Keyboard shortcuts:"
echo "   • Super + Return: Launch terminal"
echo "   • Super + Space: Launch Rofi"
echo "   • Super + Q: Close window"
echo "   • Super + F: Toggle fullscreen"
echo "   • Power + A: Launch Rofi"
echo
echo "Please reboot your system to complete the installation."