#!/bin/bash
# ── idle-mode-toggle.sh ──────────────────────────────────────
# Description: Toggle hypridle between two modes:
#              - default: dim/off, lock, and suspend all active
#              - nolock:  dim/off still active, lock + suspend skipped
#              Read by ~/.config/hypr/Scripts/idle-guard.sh on every
#              hypridle lock/suspend timeout.
# Usage: Waybar `custom/brightness` on-click-middle
# Dependencies: notify-send (optional)
# ──────────────────────────────────────────────────────────

MODE_DIR="$HOME/.cache/waybar"
MODE_FILE="$MODE_DIR/idle-mode"
mkdir -p "$MODE_DIR"

mode=$(cat "$MODE_FILE" 2>/dev/null || echo "default")

if [ "$mode" = "default" ]; then
  next="nolock"
  message="Idle lock/suspend disabled (screen will still dim)"
else
  next="default"
  message="Idle lock/suspend restored"
fi

echo "$next" > "$MODE_FILE"

command -v notify-send >/dev/null 2>&1 && notify-send -t 2000 "Idle Mode" "$message"
