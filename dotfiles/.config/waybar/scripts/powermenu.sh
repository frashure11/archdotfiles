#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Rofi Power Menu
#  Provides a simple system power menu integrated with Waybar.
#  Example:
#      ./powermenu.sh
#      # Opens a Rofi menu with power options
# ─────────────────────────────────────────────────────────────────────────────

rofi_command="rofi -config ~/.config/rofi/powermenuconfig.rasi -dmenu -p Power"

options="Shutdown\nReboot\nLogout\nSuspend\nLock"

chosen="$(echo -e "$options" | $rofi_command)"
case $chosen in
    Shutdown) pkill -TERM firefox; systemctl poweroff ;;
    Reboot) pkill -TERM firefox;  systemctl reboot ;;
    Logout) hyprctl dispatch exit ;;
    Suspend) systemctl suspend ;;
    Lock) pidof hyprlock || hyprlock ;;
#    Lock) ~/.config/hyprlock/lock.sh ;;
esac

