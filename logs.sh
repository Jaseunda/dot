#!/usr/bin/env bash
set -euo pipefail

OUTDIR="$HOME"
echo "→ Checking Hyprland binary dependencies with ldd…"
ldd "$(command -v Hyprland)" &> "$OUTDIR/hyprland-ldd.txt"
echo "  • Wrote: $OUTDIR/hyprland-ldd.txt"

echo
echo "→ Attempting to start Hyprland and capturing logs…"
echo "  (this will block until Hyprland exits; press Ctrl+C to stop)"
Hyprland 2>&1 | tee "$OUTDIR/hyprland-launch.log"
echo "  • Wrote: $OUTDIR/hyprland-launch.log"

echo
echo "✅ Done. Please exit (Ctrl+C) if Hyprland is still running."
echo "Upload both hyprland-ldd.txt and hyprland-launch.log so we can pinpoint the failure."
