#!/bin/sh
set -eu

config_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}/wsl-network-autopilot
user_unit_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}/systemd/user

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user disable --now wsl-network-autopilot.timer 2>/dev/null || true
fi

rm -f "$HOME/.local/bin/wsl-network"
rm -f "$user_unit_dir/wsl-network-autopilot.service"
rm -f "$user_unit_dir/wsl-network-autopilot.timer"

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload 2>/dev/null || true
fi

printf 'Removed program and systemd units. Preserved config: %s\n' "$config_dir/config"
printf '%s\n' 'Remove the shell startup line and Windows scheduled task separately if configured.'
