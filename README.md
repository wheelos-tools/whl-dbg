# whl-dbg

一个基于 [frp](https://github.com/fatedier/frp) 的远程调试脚本集合，采用 **Bastion(SSH 跳板) + FRP** 架构：

- 公网仅开放服务器 `22` / `7000`
- 车端映射端口（`60000+`）仅服务器本机可访问
- 用户必须通过 SSH 跳板访问车端

## 1) 服务端配置（Server）

### 安装

```bash
bash server/install.sh
```

脚本生成（默认 `/opt/frp/server`）：

- `frps`
- `frps.toml`

默认配置要点：

```toml
bindPort = 7000
auth.token = "<交互输入>"
proxyBindAddr = "127.0.0.1"
allowPorts = [ { start = 60000, end = 60100 } ]
```

说明：`proxyBindAddr = "127.0.0.1"` 会让 `60000+` 端口不对公网暴露。

### 安全组/防火墙

只放行：

- TCP `22`（跳板 SSH）
- TCP `7000`（frpc -> frps）

不要放行 `60000-60100` 到公网。

### 创建跳板用户（示例）

```bash
sudo useradd -m -s /bin/bash user_a
sudo passwd user_a
```

推荐仅密钥登录，不给 root 直连公网。

## 2) 车端配置（Client/Car）

### 安装

```bash
bash car/install.sh
```

会交互输入：

- 服务器 IP
- 车编号（数字）
- `auth.token`

生成配置示例：

```toml
serverAddr = "<服务器公网IP>"
serverPort = 7000
auth.token = "<交互输入>"

[[proxies]]
name = "car_01_ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 60001
bindAddr = "127.0.0.1"
```

说明：`bindAddr = "127.0.0.1"` 使该车端映射口只能被服务器本机访问。

### 运行管理

```bash
bash server/manage.sh start
bash server/manage.sh status
bash server/manage.sh stop

bash car/manage.sh start
bash car/manage.sh status
bash car/manage.sh stop
```

## 下载源策略（主源 + 官方回退）

安装脚本默认按以下顺序下载：

1. 自托管源（主源）
2. GitHub 官方 release（回退源）

可通过环境变量覆盖：

```bash
FRP_PRIMARY_URL="https://your.mirror/frp_0.54.0_linux_amd64.tar.gz" \
FRP_FALLBACK_URL="https://github.com/fatedier/frp/releases/download/v0.54.0/frp_0.54.0_linux_amd64.tar.gz" \
bash server/install.sh
```

建议仅覆盖主源，保留官方回退，确保可用性。

## 3) 用户端配置（User PC）

用户端无需安装 frp，仅配置 SSH。

编辑 `~/.ssh/config`：

```text
Host bastion
	HostName 服务器公网IP
	User user_a
	Port 22

Host car1
	HostName 127.0.0.1
	Port 60001
	User root
	ProxyJump bastion
```

连接：

```bash
ssh car1
```

## 4) 访问链路（诊断流程）

1. 用户执行 `ssh car1`
2. 本机先连 `bastion:22`
3. 再通过跳板访问服务器侧 `127.0.0.1:60001`
4. frps 将请求经 `7000` 隧道转发到车端 `22`
5. 获得车端 Shell

## 安全收益

- 隐身性：公网扫描看不到车端 `60000+` 端口
- 可控性：禁用服务器用户即可回收访问权限
- 分层防护：SSH 跳板 + FRP token

## 文件说明

- `server/install.sh`：服务端安装与配置生成
- `server/manage.sh`：服务端进程管理与状态查看
- `car/install.sh`：车端安装与配置生成
- `car/manage.sh`：车端进程管理与状态查看
- `LICENSE`：许可证
