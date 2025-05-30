#!/usr/bin/env bash
set -euo pipefail

# 1) Find your nouveau GPU
NOUVEAU_CARD=""
for C in /dev/dri/card*; do
  D=$(readlink "/sys/class/drm/$(basename "$C")/device/driver" 2>/dev/null \
        | awk -F/ '{print $NF}')
  [[ "$D" == "nouveau" ]] && NOUVEAU_CARD="$C" && break
done
if [[ -z "$NOUVEAU_CARD" ]]; then
  echo "❌ No nouveau‑driven GPU found." >&2
  exit 1
fi

# 2) Detect primary monitor (or default to HDMI-A-1)
RAW_MON=$(hyprctl monitors 2>/dev/null | head -n1 | awk -F': ' '{print $1}')
MONITOR=${RAW_MON:-"HDMI-A-1"}   # fallback if hyprctl fails  [oai_citation:1‡LabEx](https://labex.io/tutorials/shell-how-to-handle-unbound-variable-issue-415857?utm_source=chatgpt.com)

# 3) Get its resolution, with defaults
RAW_RES=$(hyprctl monitors 2>/dev/null | head -n1 | awk '{print $2}')
RES=${RAW_RES:-"3440x1440"}      # fallback resolution
FULL_W=${RES%x*}
FULL_H=${RES#*x}

# 4) Compute 75% internal size & scale factor
INNER_W=$(( FULL_W * 75 / 100 ))
INNER_H=$(( FULL_H * 75 / 100 ))
SCALE=$(awk "BEGIN{printf \"%.4f\", $FULL_W/$INNER_W}")

echo "▶ GPU:    $NOUVEAU_CARD"
echo "▶ Panel:  $MONITOR @ ${FULL_W}×${FULL_H}"
echo "▶ Render: ${INNER_W}×${INNER_H}  (scale $SCALE)"

# 5) Apply with nwg-displays (guarding against empty MONITOR)
if [[ -n "$MONITOR" ]]; then
  nwg-displays set "$MONITOR" \
    mode "${FULL_W}x${FULL_H}@75" \
    scale 0.75 \
    refresh 75
else
  echo "⚠️  Skipping display setup: no monitor name available."
fi

# 6) Launch Hyprland on nouveau
export WLR_BACKEND=drm
export WLR_DRM_DEVICES="$NOUVEAU_CARD"
exec Hyprland