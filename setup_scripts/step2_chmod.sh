#!/usr/bin/env bash
set -euo pipefail

# Directories (under ~/.config, symlinked into dotfiles by step1) whose
# *.sh scripts need the executable bit restored. dotfiles isn't a git repo,
# so a plain copy/sync to a fresh machine won't preserve +x on its own.
SCRIPT_DIRS=(
  "$HOME/.config/waybar/scripts"
  "$HOME/.config/hypr/Scripts"
)

echo "Setting executable bit on dotfiles scripts..."

for dir in "${SCRIPT_DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    echo "  SKIP (missing dir): $dir"
    continue
  fi

  while IFS= read -r -d '' f; do
    chmod +x "$f"
    echo "  +x $f"
  done < <(find "$dir" -type f -name "*.sh" -print0)
done

echo "Done."
