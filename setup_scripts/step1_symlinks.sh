#!/usr/bin/env bash
set -euo pipefail

DOT_CFG="$HOME/Custom/dotfiles/.config"
DOT_HOME="$HOME/Custom/dotfiles"
CFG="$HOME/.config"

# Add config folders here
FOLDERS=(
  fastfetch
  ghostty
  hypr
  libreoffice/4/user/autotext
  libreoffice/4/user/basic
  libreoffice/4/user/config/soffice.cfg
  libreoffice/4/user/gallery
  networkmanager-dmenu
  rofi
  swaync
  Thunar
  waybar
  yazi
)

# Add home-level files here
FILES=(
  .bashrc
)

# Add config-relative files here (targets under ~/.config, not $HOME)
CFG_FILES=(
  libreoffice/4/user/registrymodifications.xcu
)

mkdir -p "$CFG"

# Link ~/.config folders
for name in "${FOLDERS[@]}"; do
  src="$DOT_CFG/$name"
  dst="$CFG/$name"

  echo "Linking config folder: $name"

  if [[ ! -d "$src" ]]; then
    echo "  SKIP: source not found: $src"
    continue
  fi

  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  ln -s "$src" "$dst"
done

# Link home files (like ~/.bashrc)
for name in "${FILES[@]}"; do
  src="$DOT_HOME/$name"
  dst="$HOME/$name"

  echo "Linking home file: $name"

  if [[ ! -f "$src" ]]; then
    echo "  SKIP: source not found: $src"
    continue
  fi

  rm -f "$dst"
  ln -s "$src" "$dst"
done

# Link config-relative files (like libreoffice's registrymodifications.xcu)
for name in "${CFG_FILES[@]}"; do
  src="$DOT_CFG/$name"
  dst="$CFG/$name"

  echo "Linking config file: $name"

  if [[ ! -f "$src" ]]; then
    echo "  SKIP: source not found: $src"
    continue
  fi

  mkdir -p "$(dirname "$dst")"
  rm -f "$dst"
  ln -s "$src" "$dst"
done

echo "Done."
