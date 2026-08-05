#!/usr/bin/env bash
set -euo pipefail

STATION="wlan0"

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: required command not found: $1" >&2
    exit 1
  }
}

require iwctl

echo "Scanning for Wi-Fi networks on station: $STATION ..."
# Start a scan (asynchronous internally); ignore failure if already scanning.
iwctl station "$STATION" scan >/dev/null 2>&1 || true

# Give iwd a moment to populate results (no perfect signal from iwctl here).
sleep 2

echo
echo "Available networks:"
# Show networks; if iwd is not running or station name is wrong, this will fail and exit.
iwctl station "$STATION" get-networks || {
  echo "Error: unable to list networks. Is iwd running and is $STATION correct?" >&2
  exit 1
}

echo
echo -n "type your network name: "
IFS= read -r SSID

if [[ -z "${SSID}" ]]; then
  echo "Error: network name cannot be empty." >&2
  exit 1
fi

echo
echo "Connecting to: $SSID"
echo "If a password is required, iwctl will prompt you."
# This should trigger iwctl's interactive passphrase prompt when needed.
iwctl station "$STATION" connect "$SSID"
