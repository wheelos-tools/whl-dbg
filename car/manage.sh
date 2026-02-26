#!/bin/bash
# 用法: ./car/manage.sh [start|stop|status]

set -u

INSTALL_DIR="${INSTALL_DIR:-/opt/frp/car}"
if [ -d "$INSTALL_DIR" ]; then
    WORK_DIR="$INSTALL_DIR"
else
    WORK_DIR="$PWD"
fi

BIN="$WORK_DIR/frpc"
CONF="$WORK_DIR/frpc.toml"
LOG="$WORK_DIR/frpc.log"
PROC="frpc"
PID_FILE="$WORK_DIR/${PROC}.pid"
ACTION="${1:-}"

is_running() {
    if [ -f "$PID_FILE" ]; then
        pid="$(cat "$PID_FILE")"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

case "$ACTION" in
    start)
        if [ ! -x "$BIN" ]; then
            echo "错误: 不存在可执行文件 $BIN"
            exit 1
        fi
        if [ ! -f "$CONF" ]; then
            echo "错误: 不存在配置文件 $CONF"
            exit 1
        fi
        if is_running; then
            echo "$PROC 已经在运行 (PID: $(cat "$PID_FILE"))"
            exit 0
        fi

        nohup "$BIN" -c "$CONF" > "$LOG" 2>&1 &
        echo $! > "$PID_FILE"
        sleep 1
        if is_running; then
            echo "$PROC 已在后台启动 (PID: $(cat "$PID_FILE"))，日志查看 $LOG"
        else
            echo "启动失败，请检查日志: $LOG"
            rm -f "$PID_FILE"
            exit 1
        fi
        ;;
    stop)
        if is_running; then
            pid="$(cat "$PID_FILE")"
            kill "$pid" 2>/dev/null || true
            sleep 1
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid" 2>/dev/null || true
            fi
            rm -f "$PID_FILE"
            echo "$PROC 已停止"
        else
            echo "$PROC 未运行"
            rm -f "$PID_FILE"
        fi
        ;;
    status)
        echo "--- 进程诊断 ---"
        if is_running; then
            pid="$(cat "$PID_FILE")"
            echo "状态: [运行中] PID=$pid"
        else
            echo "状态: [未启动]"
        fi

        echo "--- 网络连接 ---"
        if is_running; then
            pid="$(cat "$PID_FILE")"
            if command -v lsof >/dev/null 2>&1; then
                lsof -nP -a -p "$pid" -iTCP -sTCP:LISTEN || echo "无监听端口"
            elif command -v netstat >/dev/null 2>&1; then
                netstat -an | grep LISTEN || echo "无监听端口"
            else
                echo "未找到 lsof/netstat，无法显示监听端口"
            fi
        else
            echo "无监听端口"
        fi

        echo "--- 最新日志 ---"
        if [ -f "$LOG" ]; then
            tail -n 5 "$LOG"
        else
            echo "日志文件不存在: $LOG"
        fi
        ;;
    *)
        echo "用法: $0 {start|stop|status}"
        exit 1
        ;;
esac
