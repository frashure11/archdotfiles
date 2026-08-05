#!/bin/bash
# ── battery.sh ─────────────────────────────────────────────
# Description: Streams battery % + charge state as waybar JSON.
#              Long-running: emits once immediately, then again
#              instantly on every AC plug/unplug or charge-state
#              change (via `upower --monitor`), with a periodic
#              fallback so slow capacity drift still stays fresh.
#              No polling interval needed -> no interval-driven lag.
#              Below 10% while discharging, the fallback loop switches
#              to a 0.6s cadence and alternates red/yellow (flash), and
#              fires a swaync notification once at 10% and once at 5%.
# Usage: Waybar `custom/battery` exec (do NOT set "interval")
# Dependencies: upower, awk, seq, printf, notify-send
# ──────────────────────────────────────────────────────────

BAT=/sys/class/power_supply/BAT1

charging_icons=(󰢜 󰂆 󰂇 󰂈 󰢝 󰂉 󰢞 󰂊 󰂋 󰂅)
default_icons=(󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)

emit() {
  local phase=$1
  local capacity status icon index filled empty bar pad ascii_bar fg tooltip

  capacity=$(<"$BAT/capacity")
  status=$(<"$BAT/status")

  index=$((capacity / 10))
  [ "$index" -ge 10 ] && index=9

  if [[ "$status" == "Charging" ]]; then
    icon=${charging_icons[$index]}
  elif [[ "$status" == "Full" ]]; then
    icon="󰂅"
  else
    icon=${default_icons[$index]}
  fi

  filled=$((capacity / 10))
  empty=$((10 - filled))
  bar=""
  pad=""
  [ "$filled" -gt 0 ] && bar=$(printf '█%.0s' $(seq 1 "$filled"))
  [ "$empty" -gt 0 ] && pad=$(printf '░%.0s' $(seq 1 "$empty"))
  ascii_bar="[$bar$pad]"

  if [ "$capacity" -le 10 ] && [[ "$status" == "Discharging" ]] && [ "$phase" = "1" ]; then
    fg="#e5c07b"  # flash: yellow
  elif [ "$capacity" -lt 20 ]; then
    fg="#bf616a"  # red (also flash's red phase)
  elif [ "$capacity" -lt 55 ]; then
    fg="#fab387"  # orange
  else
    fg="#39fb57"  # green
  fi

  tooltip="Status: $status"

  echo "{\"text\":\"<span foreground='$fg'>$icon $ascii_bar $capacity%</span>\",\"tooltip\":\"$tooltip\"}"
}

# Kill the background watchers below if this script is ever killed/replaced
# (e.g. waybar restarting) -- otherwise `upower --monitor` orphans and piles
# up, one leaked process per restart, forever.
trap 'pkill -P $BASHPID 2>/dev/null' EXIT

emit 0

# Periodic fallback so slow capacity drift (no plug/unplug event) still
# keeps the bar fresh even if an upower event is ever missed. Also owns the
# low-battery flash and swaync alerts: it only checks two sysfs reads per
# tick (cheap), and only switches to the fast 0.6s cadence while capacity
# <=10% and discharging -- otherwise it idles at the normal 60s cadence, so
# this adds no meaningful load in the common case. Notification state lives
# only here (not in the upower-monitor loop below) so each threshold fires
# exactly once per discharge dip, never twice from two watchers.
(
  phase=0
  notified10=0
  notified5=0
  while true; do
    capacity=$(<"$BAT/capacity")
    status=$(<"$BAT/status")
    critical=0
    [ "$capacity" -le 10 ] && [ "$status" = "Discharging" ] && critical=1

    if [ "$critical" -eq 1 ]; then
      if [ "$capacity" -le 5 ] && [ "$notified5" -eq 0 ]; then
        notified5=1
        notified10=1
        notify-send -u critical -a "Battery" "Battery critically low" "${capacity}% remaining"
      elif [ "$notified10" -eq 0 ]; then
        notified10=1
        notify-send -u normal -a "Battery" "Battery low" "${capacity}% remaining"
      fi
    else
      notified10=0
      notified5=0
    fi

    if [ "$critical" -eq 1 ]; then
      phase=$((1 - phase))
      emit "$phase"
      sleep 0.6
    else
      sleep 60
      emit 0
    fi
  done
) &

# Re-emit immediately whenever upower reports any change (AC plug/unplug,
# charging state, capacity) instead of waiting on the fallback timer.
upower --monitor | while read -r _; do
  emit 0
done
