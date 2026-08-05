#!/bin/bash
# ── brightness.sh ─────────────────────────────────────────
# Description: Shows current brightness with ASCII bar + tooltip
# Usage: Waybar `custom/brightness` every 2s
# Dependencies: brightnessctl, seq, printf, awk
# ──────────────────────────────────────────────────────────

# Escape for JSON
escape_json() {
  echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g'
}

# Get brightness info in machine-readable form
# Example output: backlight:intel_backlight: 100:10000:50%
info=$(brightnessctl -m 2>/dev/null)

if [ -z "$info" ]; then
  # No brightness device found
  echo '{"text":"󰛨 [??????????]","tooltip":"No brightness device detected"}'
  exit 0
fi

# Parse fields: device, current, max, percent%
device=$(echo "$info" | awk -F',' '{print $1}')
percent_raw=$(echo "$info" | awk -F',' '{print $4}')   # e.g. "50%"
percent=${percent_raw%%%}                              # strip % → "50"

# Build ASCII bar safely
filled=$((percent / 10))
empty=$((10 - filled))

bar=""
pad=""

if [ "$filled" -gt 0 ]; then
  bar=$(printf '█%.0s' $(seq 1 "$filled"))
fi
if [ "$empty" -gt 0 ]; then
  pad=$(printf '░%.0s' $(seq 1 "$empty"))
fi

ascii_bar="[$bar$pad]"

# Icon
icon="󰛨"

# Color thresholds
if [ "$percent" -lt 20 ]; then
  fg="#bf616a"  # red
elif [ "$percent" -lt 55 ]; then
  fg="#fab387"  # orange
else
  fg="#39fb57"  # green
fi

# Idle mode (toggled via middle-click; see idle-mode-toggle.sh)
idle_mode=$(cat "$HOME/.cache/waybar/idle-mode" 2>/dev/null || echo "default")
if [ "$idle_mode" = "nolock" ]; then
  mode_label="No Lock/Suspend"
else
  mode_label="Default (Lock/Suspend)"
fi

# Tooltip text
tooltip="Display: ${device}
Idle mode: ${mode_label}"
tooltip_esc=$(escape_json "$tooltip")

# JSON output
echo "{\"text\":\"<span foreground='$fg'>$icon $ascii_bar ${percent}%</span>\",\"tooltip\":\"$tooltip_esc\"}"
