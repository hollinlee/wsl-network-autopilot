# WSL Network Autopilot

为 WSL2 提供动态 Windows 代理发现，以及可选的 captive portal 自动认证恢复。

## 解决的问题

Windows 的系统代理通常是 `127.0.0.1:PORT`，但 NAT 模式下 WSL2 的 `127.0.0.1` 不是 Windows localhost。WSL 应通过默认网关访问 Windows 代理；该网关可能在重启后变化。如果代理未启动却仍保留 `HTTP_PROXY`，WSL 会表现为无法联网。

本项目会：

- 每次 shell 启动时重新发现 Windows host。
- 代理端口可访问时才设置代理变量。
- 代理不可用时清理旧变量并保留直连能力。
- 强制 captive portal 的检查和认证绕过代理。
- 将网络认证设计成可选 provider，不绑定特定实验室网络。

## 安装

```sh
git clone https://github.com/hollinlee/wsl-network-autopilot.git
cd wsl-network-autopilot
./install.sh
```

在 `~/.bashrc` 中加入：

```sh
eval "$(wsl-network env)"
```

配置文件：

```text
~/.config/wsl-network-autopilot/config
```

## 代理配置

```sh
PROXY_MODE=auto
PROXY_SCHEME=http
PROXY_PORT=7897
NO_PROXY_LIST='localhost,127.0.0.1,::1'
```

`PROXY_MODE`：

- `auto`：端口可访问才设置代理，推荐。
- `off`：清除代理，始终直连。
- `always`：不探测端口，始终设置代理。

Clash Verge 等 Windows 代理需要允许 WSL 访问监听端口。Clash Verge 通常需要开启“允许局域网连接”。

当前终端手动刷新：

```sh
eval "$(wsl-network refresh)"
```

## 可选网络认证

默认不启用认证：

```sh
AUTH_PROVIDER=none
```

使用 [`lab-login`](https://github.com/hollinlee/lab-login)：

```sh
AUTH_PROVIDER=lab-login
NO_PROXY_LIST='localhost,127.0.0.1,::1,1.1.1.3'
LAB_LOGIN_BIN="$HOME/.local/share/lab-login/login.sh"
LAB_LOGIN_CONFIG="$HOME/.config/lab-login/env"
```

使用自定义认证程序：

```sh
AUTH_PROVIDER=command
AUTH_COMMAND="$HOME/.local/bin/my-captive-portal-login"
```

配置文件会作为 shell 文件加载，自定义命令通过 `sh -c` 执行。确保权限为 `600`：

```sh
chmod 600 ~/.config/wsl-network-autopilot/config
```

## 定时恢复

WSL 运行期间定时检查：

```sh
systemctl --user enable --now wsl-network-autopilot.timer
```

需要在尚未手动打开 WSL 时也进行检查，可在 Windows PowerShell 中安装任务：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\windows\install-task.ps1 `
  -Distro Debian `
  -LinuxUser your-linux-user
```

默认每 5 分钟运行一次，并按需启动指定 WSL distribution。

只有配置了认证 provider 才需要 timer。普通代理发现只在 shell 启动时运行。

## 状态与测试

```sh
wsl-network status
wsl-network check
./tests/test.sh
systemd-analyze --user verify systemd/*.service systemd/*.timer
```

## 安全边界

- repo 不保存账号密码。
- 网络检查和认证会清空所有代理变量，避免认证信息进入代理链路。
- `lab-login` 凭据保留在它自己的 `600` 权限配置文件中。
- 自定义 provider 属于受信任的本地代码，启用前应自行审查。

完整参数和卸载方式见 [README.md](../README.md)。
