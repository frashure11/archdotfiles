#!/bin/bash

active=$(hyprctl activeworkspace -j | jq '.id')

if [ "$active" -eq 1 ]; then
  echo "<span foreground='#9cdef2'>[1]</span>"
else
  echo "[1]"
fi

