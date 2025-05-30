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

# 2) Detect primary monitor and full resolution
#    expects output like: DP-1: 3440x1440+0+0 ...
MONITOR=$(hyprctl monitors | head -n1 | awk -F': ' '{print $1}')
RES=$(hyprctl monitors | head -n1 | awk '{print $2}')  # e.g. 3440x1440
FULL_W=${RES%x*}
FULL_H=${RES#*x}

# 3) Calculate 75% internal resolution & upscale factor
INNER_W=$(( FULL_W * 75 / 100 ))   # 2580
INNER_H=$(( FULL_H * 75 / 100 ))   # 1080
SCALE=$(awk "BEGIN {printf \"%.4f\", $FULL_W / $INNER_W}")

echo "▶ Using GPU: $NOUVEAU_CARD"
echo "▶ Monitor: $MONITOR at ${FULL_W}×${FULL_H}@75Hz"
echo "▶ Internal render: ${INNER_W}×${INNER_H} (scale factor ${SCALE})"

# 4) Launch under Gamescope
export WLR_BACKEND=drm
export WLR_DRM_DEVICES="$NOUVEAU_CARD"

exec gamescope \
  --width "$INNER_W" \
  --height "$INNER_H" \
  --scale "$SCALE" \
  --refresh 75 \
  --monitor "$MONITOR" \
  Hyprland
