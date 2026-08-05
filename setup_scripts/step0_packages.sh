#!/usr/bin/env bash
set -euo pipefail

# Installs every package this dotfiles setup depends on (verified against
# what's actually wired into hyprland.lua, waybar/config, and the scripts
# they call — not just what's installed on the machine this was written on).
# Safe to re-run: pacman/yay skip anything already installed (--needed).
#
# Run this first, before step1_symlinks.sh.

PACMAN_PKGS=(
  # Hyprland session
  hyprland hypridle hyprlock hyprpaper hyprshot hyprpicker
  polkit-gnome xdg-desktop-portal-hyprland uwsm sddm

  # Bar, launcher, notifications
  waybar rofi swaync

  # Bluetooth / network
  blueman bluez bluez-utils
  networkmanager networkmanager-dmenu nm-connection-editor

  # File management
  thunar thunar-volman gvfs gvfs-smb exo

  # Terminals / TUI apps
  kitty ghostty yazi btop

  # Screenshots (hyprshot's region/output capture needs both)
  grim slurp

  # Audio / media / power CLI helpers
  wireplumber pipewire-pulse playerctl brightnessctl upower mpg123

  # Misc utilities used by keybinds/scripts
  jq imagemagick perl-image-exiftool mpv

  # Fonts
  ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols

  # General
  steam git fish nano
)

AUR_PKGS=(
  apple_cursor    # XCURSOR_THEME=macOS in hyprland.lua
  waterfox-bin    # $webBrowser in hyprland.lua
  msi-ec-git      # MSI Katana EC driver -- needed by setup_scripts/batterycharge
)

echo "Installing official-repo packages..."
sudo pacman -S --needed "${PACMAN_PKGS[@]}"

if ! command -v yay >/dev/null 2>&1; then
  echo "yay not found -- bootstrapping it from the AUR first..."
  sudo pacman -S --needed base-devel git
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (cd "$tmpdir/yay" && makepkg -si)
  rm -rf "$tmpdir"
fi

echo "Installing AUR packages..."
yay -S --needed "${AUR_PKGS[@]}"

echo
echo "Done."
echo
echo "NOTE: hyprnotes (SUPER+N in hyprland.lua) is not packaged anywhere --"
echo "it's a standalone binary this machine keeps at ~/.local/bin/hyprnotes."
echo "This script does not install it; you'll need to supply it yourself."
