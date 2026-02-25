# whl-dbg

一个基于 [frp](https://github.com/fatedier/frp) 的远程调试脚本集合，用于通过公网服务器统一接入多个车端（如 SSH）。

- `install.sh`：安装并生成 `frps`/`frpc` 默认配置
- `manage.sh`：启动、停止、查看状态

## 适用场景

- 一台公网 Linux 服务器部署 `frps`
- 多台车端 Linux 设备部署 `frpc`
- 通过服务器的不同端口区分不同车端

## 前置要求

- 操作系统：**Linux**（脚本下载 Linux 版 frp）
- 需具备：`tar`，以及 `curl` 或 `wget`
- 建议使用 `root` 或有写入安装目录权限的用户

> 默认安装目录为 `/opt/frp`，可通过环境变量覆盖：
>
> ```bash
> INSTALL_DIR=/your/path ./install.sh s
> ```

## 快速开始

### 1) 服务端安装（公网服务器）

```bash
./install.sh s
```

生成文件（默认在 `/opt/frp`）：

- `frps`
- `frps.toml`

默认配置示例：

- `bindPort = 7000`
- `allowPorts = 60000~60100`
- `auth.token` 由安装时交互输入

### 2) 车端安装（每台车）

```bash
./install.sh c
```

会交互输入：

- 服务器 IP
- 车编号（数字）
- `auth.token`

端口映射规则：

- `remotePort = 60000 + 车编号`
- 例如车编号 `1`，对应端口 `6001`（映射到该车 `22` 端口）

## 运行管理

可在任意目录执行（默认管理 `/opt/frp`）：

```bash
bash manage.sh start
bash manage.sh status
bash manage.sh stop
```

如安装目录不是 `/opt/frp`，可通过环境变量指定：

```bash
INSTALL_DIR=/your/path bash manage.sh status
```

说明：

- 脚本会自动识别当前目录是 `frps` 还是 `frpc`
- 使用 PID 文件（`frps.pid`/`frpc.pid`）管理进程，避免误杀同名进程
- 日志文件：`frps.log` / `frpc.log`

## 连接车端示例

假设：

- 服务器公网 IP：`1.2.3.4`
- 车编号：`1`（对应端口 `6001`）

则可在运维终端执行：

```bash
ssh -p 6001 user@1.2.3.4
```

## 安全建议（强烈建议）

1. 把 `auth.token` 改为强随机字符串。
2. 服务器安全组/防火墙仅放行必要端口（如 `7000` 和已分配的车端端口）。
3. 车端应限制 SSH 账号权限，优先使用密钥登录。
4. 不要把包含真实 token 的配置提交到公开仓库。
5. 脚本会将 `frps.toml` / `frpc.toml` 权限设置为 `600`。

## 常见问题

### Q1: `manage.sh status` 看不到监听端口？

- 脚本优先使用 `lsof`，其次 `netstat`
- 若系统缺少相关命令，仅影响展示，不影响进程本身运行

### Q2: 端口冲突怎么办？

- 调整车编号，或修改 `frps.toml` 的 `allowPorts`
- 确保同一服务器上每台车使用唯一 `remotePort`

### Q3: 在 macOS 上直接运行 `install.sh` 报错？

- 这是预期行为：脚本下载 Linux 二进制，请在目标 Linux 主机执行

## 文件说明

- `install.sh`：安装 frp 并生成配置
- `manage.sh`：进程管理与状态查看
- `LICENSE`：许可证
