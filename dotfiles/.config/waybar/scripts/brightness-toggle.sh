#!/bin/bash
# ── brightness-toggle.sh ─────────────────────────────
# Description: Cycle screen brightness through 25%, 50%, 75%, 100%,
#              always advancing to the next preset above the current
#              level (wrapping from 100% back to 25%).
# Usage: Waybar `custom/brightness` on-click
# Dependencies: brightnessctl
# ─────────────────────────────────────────────────────

current=$(brightnessctl get)
max=$(brightnessctl max)
# Round to the nearest percent (brightnessctl's own rounding can otherwise
# read a just-set 75% back as 74%, causing the wrong preset to be picked)
percent=$(( (current * 100 + max / 2) / max ))

presets=(25 50 75 100)
next="${presets[0]}"
for p in "${presets[@]}"; do
  if [ "$percent" -lt "$p" ]; then
    next=$p
    break
  fi
done

brightnessctl set "${next}%"

