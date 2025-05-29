#!/bin/bash
set -e

# Update system
sudo pacman -Syu --noconfirm

# Install NVIDIA drivers and dependencies
sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings linux-headers
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf
sudo mkinitcpio -P

# Install core packages
sudo pacman -S --noconfirm hyprland kitty waybar

# Install greetd and tuigreet
sudo pacman -S --noconfirm greetd greetd-tuigreet

# Configure greetd
USERNAME=$(whoami)
sudo tee /etc/greetd/config.toml > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd Hyprland"
user = "$USERNAME"
EOF

# Enable greetd service
sudo systemctl enable greetd.service

# Install and enable Bluetooth
sudo pacman -S --noconfirm bluez bluez-utils
sudo systemctl enable --now bluetooth.service

# Create Hyprland configuration
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprland.conf <<EOF
source=~/.config/hypr/monitors.conf

exec-once=kitty &
exec-once=waybar &

bind=SUPER+ENTER,exec,kitty
bind=SUPER+Q,killactive
EOF

# Create monitor auto-config generator
cat > ~/.config/hypr/gen_hypr_monitors.sh <<'EOS'
#!/bin/bash
CONF="$HOME/.config/hypr/monitors.conf"
echo "# Auto-generated monitor config" > "$CONF"

monitors=$(hyprctl monitors | grep 'Name:' | awk '{print $2}')
for mon in $monitors; do
    refresh=$(hyprctl monitors | grep -A5 "Name: $mon" | grep 'Refresh:' | awk '{print int($2)}')
    [[ "$refresh" -lt 60 ]] && refresh=60
    echo "monitor=$mon,preferred,$refresh" >> "$CONF"
done
EOS

chmod +x ~/.config/hypr/gen_hypr_monitors.sh

# Add monitor config to bash_profile
echo '~/.config/hypr/gen_hypr_monitors.sh' >> ~/.bash_profile

echo "Setup complete. Please reboot to start Hyprland with tuigreet."