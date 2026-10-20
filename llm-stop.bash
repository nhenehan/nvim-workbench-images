#!/usr/bin/env bash
# Stop the llama-server started by llm-start.bash.
PIDFILE="$HOME/logs/llama-server.pid"

if [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "🦙 llama-server stopped"
else
    echo "🦙 llama-server not running"
fi
rm -f "$PIDFILE"
