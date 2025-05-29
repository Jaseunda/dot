#!/bin/bash
set -e

echo "### Updating system..."
sudo pacman -Syu --noconfirm

echo "### Installing NVIDIA drivers and dependencies..."
sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings linux-headers
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf
sudo mkinitcpio -P

echo "### Installing core packages: Hyprland, Kitty, Waybar..."
sudo pacman -S --noconfirm hyprland kitty waybar

echo "### Installing greetd + tuigreet login manager..."
sudo pacman -S --noconfirm greetd tuigreet

echo "### Configuring greetd for Hyprland login..."
sudo mkdir -p /etc/greetd
sudo tee /etc/greetd/config.toml > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd Hyprland"
user = "YOUR_USERNAME"
EOF

echo "### Enabling greetd login service..."
sudo systemctl enable greetd.service

echo "### Installing Bluetooth (bluez)..."
sudo pacman -S --noconfirm bluez bluez-utils
sudo systemctl enable --now bluetooth.service

echo "### Creating Hyprland config..."
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprland.conf <<EOF
source=~/.config/hypr/monitors.conf

exec-once=kitty &
exec-once=waybar &

bind=SUPER+ENTER,exec,kitty
bind=SUPER+Q,killactive
EOF

echo "### Creating monitor auto-config generator..."
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

echo "### Adding monitor config to bash_profile to run before Hyprland starts..."
echo '~/.config/hypr/gen_hypr_monitors.sh' >> ~/.bash_profile

echo "### DONE! Reboot and Hyprland will launch with tuigreet."