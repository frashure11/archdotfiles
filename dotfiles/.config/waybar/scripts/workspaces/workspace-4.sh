#!/bin/bash
# workspace-4.sh — highlight workspace 4 if active

active=$(hyprctl activeworkspace -j | jq '.id')

if [ "$active" -eq 4 ]; then
  echo "<span foreground='#9cdef2'>[4]</span>"
else
  echo "[4]"
fi

