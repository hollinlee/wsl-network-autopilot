# WSL Network Autopilot

Reliable proxy discovery and optional captive-portal recovery for WSL2.

Windows system proxy settings do not automatically become valid WSL proxy settings. In the default WSL2 NAT mode, a Windows proxy listening on `127.0.0.1` is normally reached through the WSL default gateway. That gateway can change after restart, and exporting an unavailable proxy makes a working direct connection appear offline.

This project handles that boundary without requiring any specific proxy client or captive portal.

## Features

- Discovers the current Windows host address from the WSL default route.
- Exports proxy variables only when the configured Windows proxy port is reachable.
- Clears stale proxy variables when the proxy is unavailable.
- Keeps captive-portal traffic out of the proxy through `NO_PROXY_LIST`.
- Supports no authentication, [`lab-login`](https://github.com/hollinlee/lab-login), or a custom authentication command.
- Includes optional WSL systemd user timer and Windows Task Scheduler integration.
- Stores configuration and credentials outside the repository.

## Install

```sh
git clone https://github.com/hollinlee/wsl-network-autopilot.git
cd wsl-network-autopilot
./install.sh
```

Add this to `~/.bashrc` or the equivalent interactive shell startup file:

```sh
eval "$(wsl-network env)"
```

Open a new shell and inspect the result:

```sh
wsl-network status
env | grep -i proxy
```

The default configuration is `~/.config/wsl-network-autopilot/config`.

## Proxy Configuration

The default mode is safe for proxy-optional environments:

```sh
PROXY_MODE=auto
PROXY_SCHEME=http
PROXY_PORT=7897
NO_PROXY_LIST='localhost,127.0.0.1,::1'
```

Modes:

- `auto`: use the proxy only when its TCP port is reachable.
- `off`: always clear proxy variables and use direct networking.
- `always`: export the proxy without probing it.

This works with Clash Verge, sing-box, v2rayN, or another Windows proxy that accepts connections from WSL. The Windows proxy must listen on a WSL-reachable address; in Clash Verge this normally means enabling LAN access.

Refresh an existing shell after changing the Windows network or proxy:

```sh
eval "$(wsl-network refresh)"
```

## Optional Captive Portal

No authentication provider is enabled by default:

```sh
AUTH_PROVIDER=none
```

### lab-login adapter

Install and configure [lab-login](https://github.com/hollinlee/lab-login), then set:

```sh
AUTH_PROVIDER=lab-login
NO_PROXY_LIST='localhost,127.0.0.1,::1,1.1.1.3'
LAB_LOGIN_BIN="$HOME/.local/share/lab-login/login.sh"
LAB_LOGIN_CONFIG="$HOME/.config/lab-login/env"
```

`wsl-network check` first tests direct internet access. It invokes `lab-login` only when direct access is unavailable. Proxy variables are removed for the whole check and authentication process.

### Custom provider

```sh
AUTH_PROVIDER=command
AUTH_COMMAND="$HOME/.local/bin/my-captive-portal-login"
```

The config is sourced as shell syntax and `AUTH_COMMAND` runs through `sh -c`. Keep the file owned by your user and mode `600`:

```sh
chmod 600 ~/.config/wsl-network-autopilot/config
```

## Scheduling

Enable checks while WSL is running:

```sh
systemctl --user enable --now wsl-network-autopilot.timer
```

To run checks even before opening a WSL terminal, open PowerShell and install the Windows task:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\windows\install-task.ps1 `
  -Distro Debian `
  -LinuxUser your-linux-user
```

The task runs every five minutes and starts the selected WSL distribution when needed. Remove it with:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\windows\uninstall-task.ps1
```

Only enable schedulers when an authentication provider is configured. Proxy environment generation itself happens at shell startup and does not require a timer.

## Commands

```text
wsl-network env       Print shell exports for eval
wsl-network refresh   Alias for env
wsl-network check     Check direct access and run auth when needed
wsl-network auth      Run the configured auth provider immediately
wsl-network status    Show network and provider state
```

## Test

```sh
./tests/test.sh
systemd-analyze --user verify systemd/*.service systemd/*.timer
```

## Security

- The repository contains no credentials.
- Authentication runs without proxy variables to avoid sending portal credentials through a remote proxy.
- `lab-login` credentials remain in its own mode-`600` config file.
- A custom provider is trusted local code. Review it before enabling `AUTH_PROVIDER=command`.

## Uninstall

```sh
./uninstall.sh
```

The uninstaller preserves user configuration. Remove the shell startup line and Windows task separately if they were enabled.

## License

MIT
