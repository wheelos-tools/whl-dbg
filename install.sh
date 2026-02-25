#!/bin/bash
# 用法: ./install.sh [s|c] (s为服务端, c为车端)

set -u

ROLE="${1:-}"
INSTALL_DIR="${INSTALL_DIR:-/opt/frp}"
FRP_VER="${FRP_VER:-0.54.0}"

usage() {
    echo "用法: $0 [s|c]"
    echo "  s: 服务端"
    echo "  c: 车端"
}

if [ "$ROLE" != "s" ] && [ "$ROLE" != "c" ]; then
    usage
    exit 1
fi

if [ "$(uname -s)" != "Linux" ]; then
    echo "错误: 此安装脚本下载的是 Linux 版 frp，请在 Linux 主机执行。"
    exit 1
fi

mkdir -p "$INSTALL_DIR" && cd "$INSTALL_DIR"

# 1. 自动下载
arch="$(uname -m)"
case "$arch" in
    x86_64)
        suffix="linux_amd64"
        ;;
    aarch64|arm64)
        suffix="linux_arm64"
        ;;
    *)
        echo "错误: 不支持的架构: $arch"
        exit 1
        ;;
esac

url="https://github.com/fatedier/frp/releases/download/v${FRP_VER}/frp_${FRP_VER}_${suffix}.tar.gz"
if command -v curl >/dev/null 2>&1; then
    curl -fL "$url" -o frp.tar.gz
elif command -v wget >/dev/null 2>&1; then
    wget "$url" -O frp.tar.gz
else
    echo "错误: 未找到下载工具，请安装 curl 或 wget"
    exit 1
fi

tar -zxf frp.tar.gz
[ "$ROLE" = "s" ] && cp "frp_${FRP_VER}_${suffix}/frps" . || cp "frp_${FRP_VER}_${suffix}/frpc" .
chmod +x frps frpc 2>/dev/null || true
rm -rf "frp.tar.gz" "frp_${FRP_VER}_${suffix}"

# 2. 默认配置生成
if [ "$ROLE" = "s" ]; then
    cat <<EOF > frps.toml
bindPort = 7000
auth.token = "SECRET_123"
allowPorts = [ { start = 60000, end = 60100 } ]
EOF
    echo "服务端安装完成。目录: $INSTALL_DIR"
else
    read -p "输入服务器IP: " S_IP
    read -p "输入此车编号(如1): " C_ID

    if [ -z "$S_IP" ]; then
        echo "错误: 服务器IP不能为空"
        exit 1
    fi

    if ! [[ "$C_ID" =~ ^[0-9]+$ ]]; then
        echo "错误: 车编号必须是数字"
        exit 1
    fi

    REMOTE_PORT=$((60000 + C_ID))
    cat <<EOF > frpc.toml
serverAddr = "$S_IP"
serverPort = 7000
auth.token = "SECRET_123"
[[proxies]]
name = "car_${C_ID}_ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = $REMOTE_PORT
EOF
    echo "车端安装完成。目录: $INSTALL_DIR，对应端口: $REMOTE_PORT"
fi
