#!/usr/bin/env bash
set -Eeuo pipefail

# Build and serve the Godot browser preview without exposing the HTTP server
# directly to the network. Connect from a workstation through an SSH tunnel.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
GODOT_BIN="${GODOT_BIN:-/home/ubuntu/fungi/tools/godot/4.7/godot}"
PRESET="Web Preview"
WEB_DIR="$ROOT_DIR/build/web"
STATE_DIR="$ROOT_DIR/.web-preview"
PID_FILE="$STATE_DIR/server.pid"
LOG_FILE="$STATE_DIR/server.log"
LOCK_FILE="$STATE_DIR/operation.lock"
PORT=8060
HOST=127.0.0.1

mkdir -p "$STATE_DIR"
exec 9>"$LOCK_FILE"
if ! flock -w 30 9; then
    echo "Another web preview operation is still running." >&2
    exit 1
fi

read_pid() {
    [[ -s "$PID_FILE" ]] || return 1
    local pid
    pid="$(cat "$PID_FILE")"
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "$pid"
}

is_our_server() {
    local pid="${1:-}"
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    kill -0 "$pid" 2>/dev/null || return 1
    [[ -r "/proc/$pid/cmdline" ]] || return 1

    local command_line
    command_line="$(tr '\0' ' ' <"/proc/$pid/cmdline")"
    [[ "$command_line" == *"python3 -m http.server $PORT"* ]] &&
        [[ "$command_line" == *"--bind $HOST"* ]] &&
        [[ "$command_line" == *"--directory $WEB_DIR"* ]]
}

remove_stale_pid() {
    local pid
    if ! pid="$(read_pid)"; then
        rm -f "$PID_FILE"
        return
    fi
    if ! is_our_server "$pid"; then
        echo "Removing stale preview PID record: $pid"
        rm -f "$PID_FILE"
    fi
}

server_pid() {
    local pid
    pid="$(read_pid)" || return 1
    is_our_server "$pid" || return 1
    printf '%s\n' "$pid"
}

port_is_busy() {
    if command -v ss >/dev/null 2>&1; then
        ss -H -ltn "sport = :$PORT" | grep -q .
    else
        python3 - "$HOST" "$PORT" <<'PY'
import socket
import sys

with socket.socket() as sock:
    try:
        sock.bind((sys.argv[1], int(sys.argv[2])))
    except OSError:
        raise SystemExit(0)
raise SystemExit(1)
PY
    fi
}

build_preview() {
    [[ -x "$GODOT_BIN" ]] || {
        echo "Godot executable not found: $GODOT_BIN" >&2
        return 1
    }

    local temp_dir="$ROOT_DIR/build/.web-preview-$$"
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"

    cleanup_temp() {
        rm -rf "$temp_dir"
    }
    trap cleanup_temp RETURN

    echo "Exporting '$PRESET'..."
    "$GODOT_BIN" --headless --path "$ROOT_DIR" \
        --export-release "$PRESET" "$temp_dir/index.html"
    [[ -s "$temp_dir/index.html" ]] || {
        echo "Web export did not produce index.html" >&2
        return 1
    }

    rm -rf "$WEB_DIR"
    mv "$temp_dir" "$WEB_DIR"
    trap - RETURN
    echo "Web preview exported to: $WEB_DIR"
}

start_server() {
    remove_stale_pid

    local pid
    if pid="$(server_pid)"; then
        echo "Preview server already running (PID $pid)."
        return
    fi

    if port_is_busy; then
        echo "$HOST:$PORT is already occupied by another process; refusing to start." >&2
        return 1
    fi

    : >"$LOG_FILE"
    nohup python3 -m http.server "$PORT" \
        --bind "$HOST" \
        --directory "$WEB_DIR" >>"$LOG_FILE" 2>&1 9>&- &
    pid=$!
    printf '%s\n' "$pid" >"$PID_FILE.tmp"
    mv "$PID_FILE.tmp" "$PID_FILE"

    for _ in {1..50}; do
        if curl --silent --show-error --fail --output /dev/null \
            "http://$HOST:$PORT/index.html"; then
            echo "Preview server ready: http://$HOST:$PORT/ (PID $pid)"
            return
        fi
        if ! is_our_server "$pid"; then
            break
        fi
        sleep 0.1
    done

    echo "Preview server failed to become ready. Log: $LOG_FILE" >&2
    if is_our_server "$pid"; then
        kill "$pid"
    fi
    rm -f "$PID_FILE"
    return 1
}

stop_server() {
    remove_stale_pid
    local pid
    if ! pid="$(server_pid)"; then
        echo "Preview server is not running."
        return
    fi

    kill "$pid"
    for _ in {1..50}; do
        if ! kill -0 "$pid" 2>/dev/null; then
            rm -f "$PID_FILE"
            echo "Preview server stopped."
            return
        fi
        sleep 0.1
    done
    echo "Preview server PID $pid did not stop after SIGTERM." >&2
    return 1
}

show_status() {
    remove_stale_pid
    local pid
    if pid="$(server_pid)"; then
        echo "running PID=$pid URL=http://$HOST:$PORT/"
        curl --silent --show-error --fail --output /dev/null \
            "http://$HOST:$PORT/index.html"
        echo "HTTP check: OK"
    else
        echo "stopped"
        return 1
    fi
}

case "${1:-start}" in
    start)
        build_preview
        start_server
        ;;
    build)
        build_preview
        ;;
    restart)
        stop_server || true
        build_preview
        start_server
        ;;
    stop)
        stop_server
        ;;
    status)
        show_status
        ;;
    logs)
        tail -n "${2:-80}" "$LOG_FILE"
        ;;
    *)
        echo "Usage: $0 {start|build|restart|stop|status|logs [lines]}" >&2
        exit 2
        ;;
esac
