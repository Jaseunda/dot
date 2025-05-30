#!/usr/bin/env bash
set -euo pipefail

# 1) Detect nouveau DRM device
NOUVEAU_CARD=""
for CARD in /dev/dri/card*; do
  DRIVER=$(readlink /sys/class/drm/$(basename "$CARD")/device/driver 2>/dev/null | awk -F/ '{print $NF}')
  if [[ "$DRIVER" == "nouveau" ]]; then
    NOUVEAU_CARD="$CARD"
    break
  fi
done
if [[ -z "$NOUVEAU_CARD" ]]; then
  echo "❌ Could not find a nouveau‑driven /dev/dri/card*. Exiting."
  exit 1
fi

# 2) Detect your primary monitor name and full resolution
MONITOR=$(hyprctl monitors | head -n1 | awk -F': ' '{print $1}')
RES=$(hyprctl monitors | head -n1 | awk '{print $2}')  # e.g. 3440x1440
FULL_W=${RES%x*}
FULL_H=${RES#*x}

# 3) Calculate 75% internal resolution & upscale factor
INNER_W=$(( FULL_W * 75 / 100 ))   # 2580
INNER_H=$(( FULL_H * 75 / 100 ))   # 1080
SCALE=$(awk "BEGIN {printf \"%.4f\", $FULL_W / $INNER_W}")

echo "▶ GPU device: $NOUVEAU_CARD"
echo "▶ Monitor:    $MONITOR @ ${FULL_W}×${FULL_H} 75 Hz"
echo "▶ Render:     ${INNER_W}×${INNER_H} (scale ${SCALE})"

# 4) Use nwg-displays to apply the mode and scale
nwg-displays set "$MONITOR" \
  mode "${FULL_W}x${FULL_H}@75" \
  scale 0.75 \
  refresh 75

# 5) Export Wayland backend vars
export WLR_BACKEND=drm
export WLR_DRM_DEVICES="$NOUVEAU_CARD"

# 6) Launch Hyprland
exec Hyprland