#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
bin_dir=${HOME}/.local/bin
config_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}/wsl-network-autopilot
user_unit_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}/systemd/user

mkdir -p "$bin_dir" "$config_dir" "$user_unit_dir"
cp "$repo_dir/bin/wsl-network" "$bin_dir/wsl-network"
chmod 755 "$bin_dir/wsl-network"

if [ ! -f "$config_dir/config" ]; then
    cp "$repo_dir/config.example" "$config_dir/config"
    chmod 600 "$config_dir/config"
    printf 'Created config: %s\n' "$config_dir/config"
else
    printf 'Preserved config: %s\n' "$config_dir/config"
fi

cp "$repo_dir/systemd/wsl-network-autopilot.service" "$user_unit_dir/"
cp "$repo_dir/systemd/wsl-network-autopilot.timer" "$user_unit_dir/"
chmod 644 "$user_unit_dir/wsl-network-autopilot.service" "$user_unit_dir/wsl-network-autopilot.timer"

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload 2>/dev/null || true
fi

cat <<'EOF'
Installed wsl-network-autopilot.

Add this line to your interactive shell startup file:
  eval "$(wsl-network env)"

Optional captive-portal timer:
  systemctl --user enable --now wsl-network-autopilot.timer

Review the config before enabling authentication:
  $EDITOR ~/.config/wsl-network-autopilot/config
EOF
