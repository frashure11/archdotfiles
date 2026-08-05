# Custom

Personal dotfiles and setup scripts for my Arch Linux + Hyprland desktop.

This repo is meant to be cloned to `~/Custom` and then applied to a machine
via the scripts in `setup_scripts/`.

## Layout

- `dotfiles/` — mirrors the real destination paths under `$HOME`.
  - `dotfiles/.config/...` → linked into `~/.config/...`
  - `dotfiles/.bashrc` → linked to `~/.bashrc`
  - `dotfiles/sddm/` — SDDM theme + config, installed to `/etc` and `/usr/share`
    (needs root, handled separately from the symlink step — see below).
- `setup_scripts/` — bootstrap scripts, run in order.
- `assets/` — wallpapers and other static assets referenced by configs.
- `newtab.html` — custom browser new-tab page.

## Bootstrap on a fresh machine

```bash
git clone <this-repo-url> ~/Custom
cd ~/Custom/setup_scripts

./step0_packages.sh   # install everything these dotfiles depend on (pacman + AUR)
./step1_symlinks.sh   # symlink dotfiles/.config/* and .bashrc into place
./step2_chmod.sh      # restore +x on scripts under the symlinked configs
sudo ./step3_sddm.sh  # install the SDDM theme/config system-wide (needs root)
```

`step0_packages.sh` installs from the official repos, then bootstraps `yay`
(if missing) to pull the handful of AUR-only packages (`apple_cursor`,
`waterfox-bin`, `msi-ec-git`). One exception it can't handle: `hyprnotes`
(bound to `SUPER+N`) isn't packaged anywhere — it's a standalone binary this
machine keeps at `~/.local/bin/hyprnotes`, so you'll need to supply that
yourself on a fresh machine.

Other standalone helper scripts (not part of the numbered bootstrap flow):

- `wifi.sh` — interactive Wi-Fi connect via `iwctl`.
- `netlist.fish` — scan and list devices on the local network.
- `configmonitors.fish` — auto-detect monitors and rewrite `hypr/monitors.lua`.
- `batterycharge` — one-off charge-threshold tweak for this laptop's battery.

## Notes

- `step1_symlinks.sh` assumes the repo lives at `~/Custom`.
- A couple of files are intentionally left out of git (see `.gitignore`):
  LibreOffice's `registrymodifications.xcu` (personal recent-document
  history, not portable config) and any `.claude/` directories (local
  Claude Code session state).
