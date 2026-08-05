#!/usr/bin/env bash
set -euo pipefail

# Backed-up SDDM assets, mirroring their destination paths under /
#   sddm/usr-share/... -> /usr/share/...
#   sddm/etc/...        -> /etc/...
SRC="$HOME/Custom/dotfiles/sddm"

if [[ ! -d "$SRC" ]]; then
  echo "Source directory $SRC does not exist."
  exit 1
fi

echo "Installing custom SDDM themes..."
sudo cp -r "$SRC/usr-share/sddm/themes/wismt" /usr/share/sddm/themes/

echo "Installing SDDM Hyprland compositor config..."
sudo mkdir -p /usr/share/hypr/sddm
sudo cp "$SRC/usr-share/hypr/sddm/hyprland.lua" /usr/share/hypr/sddm/hyprland.lua

echo "Installing SDDM config..."
sudo cp "$SRC/etc/sddm.conf" /etc/sddm.conf
sudo mkdir -p /etc/sddm.conf.d
sudo cp "$SRC/etc/sddm.conf.d/sddm-hyprland.conf" /etc/sddm.conf.d/sddm-hyprland.conf

echo "Done."
