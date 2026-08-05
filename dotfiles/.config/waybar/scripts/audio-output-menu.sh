#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Rofi Audio Output Menu
#  Right-click on the waybar volume module -> pick the default audio sink.
#  Example:
#      ./audio-output-menu.sh
#      # Opens a Rofi menu listing available output devices
# ─────────────────────────────────────────────────────────────────────────────

rofi_command="rofi -config ~/.config/rofi/audiooutputconfig.rasi -dmenu -p Output"

# Parse `wpctl status` Sinks section into "id|star|name" triples
mapfile -t sinks < <(
  wpctl status | awk '
    /Sinks:/{flag=1; next}
    /Sources:/{flag=0}
    flag && /[0-9]+\./ {
      line=$0
      star=(line ~ /\*/) ? "*" : " "
      sub(/^[^0-9]*/,"",line)
      id=line; sub(/\..*/,"",id)
      name=line; sub(/^[0-9]+\.[ \t]*/,"",name); sub(/[ \t]*\[.*/,"",name); sub(/[ \t]+$/,"",name)
      printf "%s|%s|%s\n", id, star, name
    }
  '
)

[ "${#sinks[@]}" -eq 0 ] && exit 0

declare -A id_for_label
menu=""
for entry in "${sinks[@]}"; do
  id="${entry%%|*}"
  rest="${entry#*|}"
  star="${rest%%|*}"
  name="${rest#*|}"
  if [ "$star" = "*" ]; then
    label="${name} (current)"
  else
    label="${name}"
  fi
  id_for_label["$label"]="$id"
  menu+="$label"$'\n'
done

chosen="$(printf '%s' "$menu" | $rofi_command)"
[ -z "$chosen" ] && exit 0

sink_id="${id_for_label[$chosen]}"
[ -n "$sink_id" ] && wpctl set-default-sink "$sink_id"
