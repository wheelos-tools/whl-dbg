#!/bin/bash
# 用法: ./car/install.sh

set -u

INSTALL_DIR="${INSTALL_DIR:-/opt/frp/car}"
FRP_VER="${FRP_VER:-0.54.0}"

if [ "$(uname -s)" != "Linux" ]; then
    echo "错误: 此安装脚本下载的是 Linux 版 frp，请在 Linux 主机执行。"
    exit 1
fi

mkdir -p "$INSTALL_DIR" && cd "$INSTALL_DIR"

TARGET_BIN="frpc"
if [ -x "$TARGET_BIN" ]; then
    echo "检测到已安装 $TARGET_BIN，跳过下载。"
else
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

    PRIMARY_URL="${FRP_PRIMARY_URL:-https://dl.wheelos.cn/assets/third-party/frp_${FRP_VER}_${suffix}.tar.gz}"
    FALLBACK_URL="${FRP_FALLBACK_URL:-https://github.com/fatedier/frp/releases/download/v${FRP_VER}/frp_${FRP_VER}_${suffix}.tar.gz}"

    download_ok=0
    for url in "$PRIMARY_URL" "$FALLBACK_URL"; do
        [ -n "$url" ] || continue
        echo "尝试下载: $url"
        if command -v curl >/dev/null 2>&1; then
            if curl -fL "$url" -o frp.tar.gz; then
                download_ok=1
                break
            fi
        elif command -v wget >/dev/null 2>&1; then
            if wget "$url" -O frp.tar.gz; then
                download_ok=1
                break
            fi
        else
            echo "错误: 未找到下载工具，请安装 curl 或 wget"
            exit 1
        fi
        rm -f frp.tar.gz
    done

    if [ "$download_ok" -ne 1 ]; then
        echo "错误: 两个下载源都失败。"
        echo "已尝试:"
        echo "  1) $PRIMARY_URL"
        echo "  2) $FALLBACK_URL"
        exit 1
    fi

    tar -zxf frp.tar.gz
    cp "frp_${FRP_VER}_${suffix}/frpc" .
    chmod +x frpc
    rm -rf "frp.tar.gz" "frp_${FRP_VER}_${suffix}"
fi

read -p "输入服务器IP: " S_IP
read -p "输入此车编号(如1): " C_ID
read -s -p "输入 auth.token: " AUTH_TOKEN
echo

if [ -z "$S_IP" ]; then
    echo "错误: 服务器IP不能为空"
    exit 1
fi

if ! [[ "$C_ID" =~ ^[0-9]+$ ]]; then
    echo "错误: 车编号必须是数字"
    exit 1
fi

if [ -z "$AUTH_TOKEN" ]; then
    echo "错误: auth.token 不能为空"
    exit 1
fi

REMOTE_PORT=$((60000 + C_ID))
cat <<EOF > frpc.toml
serverAddr = "$S_IP"
serverPort = 7000
auth.token = "$AUTH_TOKEN"
[[proxies]]
name = "car_${C_ID}_ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = $REMOTE_PORT
bindAddr = "127.0.0.1"
EOF
chmod 600 frpc.toml
echo "车端安装完成。目录: $INSTALL_DIR，对应端口: $REMOTE_PORT"
