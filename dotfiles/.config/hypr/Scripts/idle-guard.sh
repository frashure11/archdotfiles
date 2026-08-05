#!/bin/bash
# ── idle-guard.sh ────────────────────────────────────────────
# Description: Runs a hypridle on-timeout action only when the
#              idle mode (toggled from waybar's brightness module,
#              middle-click) is "default". In "nolock" mode, lock
#              and shutdown timeouts are skipped so the screen can
#              still dim/off but the session won't lock or suspend.
# Usage: hypridle.conf `on-timeout = ~/.config/hypr/Scripts/idle-guard.sh '<cmd>'`
# ───────────────────────────────────────────────────────────
MODE_FILE="$HOME/.cache/waybar/idle-mode"
mode=$(cat "$MODE_FILE" 2>/dev/null || echo "default")

if [ "$mode" = "nolock" ]; then
  exit 0
fi

exec bash -c "$1"
