#!/bin/bash
# ── volume.sh ─────────────────────────────────────────────
# Description: Shows current audio volume with ASCII bar + tooltip
# Usage: Waybar `custom/volume` every 1s
# Dependencies: wpctl, awk, seq, printf, sed, grep, cut
# ───────────────────────────────────────────────────────────

# Escape for JSON
escape_json() {
  echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Get volume status once
status=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)

# Volume as integer 0–100
vol_int=$(awk '{ printf "%d", $2 * 100 }' <<< "$status")

# Check mute status
if grep -q 'MUTED' <<< "$status"; then
  is_muted=true
else
  is_muted=false
fi

# Get default sink description (human-readable)
sink=$(
  wpctl status \
    | awk '/Sinks:/,/Sources:/' \
    | grep '\*' \
    | cut -d'.' -f2- \
    | sed 's/^[[:space:]]*//; s/\[.*//'
)

# Icon logic
if [ "$is_muted" = true ]; then
  icon=" "
  vol_int=0
elif [ "$vol_int" -lt 50 ]; then
  icon=" "
else
  icon="  "
fi

# ASCII bar
filled=$((vol_int / 10))
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

# Color logic
if [ "$is_muted" = true ] || [ "$vol_int" -lt 10 ]; then
  fg="#bf616a" # red
elif [ "$vol_int" -lt 50 ]; then
  fg="#fab387" # orange
else
  fg="#39fb57" # green
fi

# Tooltip text
tooltip="Output Device: $sink"
tooltip_esc=$(escape_json "$tooltip")

# Final JSON output
echo "{\"text\":\"<span foreground='$fg'>$icon  $ascii_bar ${vol_int}%</span>\",\"tooltip\":\"$tooltip_esc\"}"
