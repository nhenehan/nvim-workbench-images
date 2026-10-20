#!/usr/bin/env bash
# Show whether llama-server is up, what it is serving, and the tail of its log.
PORT="${LLM_PORT:-9090}"
PIDFILE="$HOME/logs/llama-server.pid"
LOG="$HOME/logs/llama-server.log"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "🦙 pid $(cat "$PIDFILE")"
else
    echo "🦙 llama-server not running (start with llm-start.bash --background)"
fi

echo "health: $(curl -fsS "http://127.0.0.1:$PORT/health" 2>&1)"
curl -fsS "http://127.0.0.1:$PORT/v1/models" 2>/dev/null | jq -r '.data[] | "model:  \(.id)"' 2>/dev/null

if [ -f "$LOG" ]; then
    echo "--- $LOG ---"
    tail -n "${1:-10}" "$LOG"
fi
