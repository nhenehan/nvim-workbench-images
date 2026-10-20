#!/usr/bin/env bash
# Start llama-server on the best device this container can see, with the largest
# model in ~/models that fits it. GPU layers and context size are left to
# llama-server's --fit (on by default), which sizes them to the device's free memory.
#
# Usage: llm-start.bash [--background]
#
# Environment overrides:
#   LLM_MODEL      path to a .gguf to use instead of auto-selection
#   LLM_BACKEND    cuda | rocm | vulkan | cpu (default: auto-detect)
#   LLM_PORT       listen port (default 9090)
#   LLM_CTX        fixed context size (default: let --fit choose)
#   LLM_PARALLEL   server slots (default 2: one chat, one llama.vim FIM)
#   LLM_ARGS       extra llama-server arguments, appended verbatim
set -uo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LLAMA_BIN="${LLAMA_BIN:-$HOME/opt/llama.cpp/build/bin}"
MODELS_DIR="${LLM_MODELS_DIR:-$HOME/models}"
LOG_DIR="$HOME/logs"
LOG="$LOG_DIR/llama-server.log"
PIDFILE="$LOG_DIR/llama-server.pid"
PORT="${LLM_PORT:-9090}"

BACKGROUND=0
[ "${1:-}" = "--background" ] && BACKGROUND=1

mkdir -p "$LOG_DIR"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "🦙 llama-server already running (pid $(cat "$PIDFILE")) on :$PORT"
    exit 0
fi

# shellcheck source=/dev/null
source <("$SCRIPTS/llm-detect.bash")

# Total size in MiB of a model, summing every shard of a split gguf.
model_mb() {
    local f=$1
    if [[ $f =~ ^(.*)-00001-of-([0-9]{5})\.gguf$ ]]; then
        du -cm --apparent-size "${BASH_REMATCH[1]}"-?????-of-"${BASH_REMATCH[2]}".gguf | tail -1 | cut -f1
    else
        du -m --apparent-size "$f" | cut -f1
    fi
}

pick_model() {
    local f mb best="" best_mb=0 small="" small_mb=0
    # Weights plus room for --fit's 1 GiB margin and a usable KV cache.
    local budget=$((LLM_MEM_MB - 2048))
    while IFS= read -r -d '' f; do
        case "$f" in
            *mmproj*) continue ;;
            *-000[0-9][0-9]-of-*) [[ $f == *-00001-of-* ]] || continue ;;
        esac
        mb=$(model_mb "$f")
        if [ -z "$small" ] || [ "$mb" -lt "$small_mb" ]; then
            small=$f small_mb=$mb
        fi
        if [ $((mb * 110 / 100)) -le "$budget" ] && [ "$mb" -gt "$best_mb" ]; then
            best=$f best_mb=$mb
        fi
    done < <(find -L "$MODELS_DIR" -name '*.gguf' -type f -print0 2>/dev/null)
    # Nothing fits entirely: take the smallest and let --fit split it across GPU and CPU.
    echo "${best:-$small}"
}

MODEL="${LLM_MODEL:-$(pick_model)}"
if [ -z "$MODEL" ] || [ ! -f "$MODEL" ]; then
    echo "🦙 No .gguf models found in $MODELS_DIR -- llama-server not started."
    echo "   On the host: make llama-cpp-models, then mount ~/models (see README.LLAMA.md)."
    exit 0
fi

ARGS=(
    -m "$MODEL"
    --alias local
    --device "$LLM_DEVICE"
    -t "$LLM_THREADS"
    -fa auto
    --jinja
    --parallel "${LLM_PARALLEL:-2}"
    --fit-ctx 8192
    --host 0.0.0.0
    --port "$PORT"
)
[ -n "${LLM_CTX:-}" ] && ARGS+=(-c "$LLM_CTX")
# Tight memory: quantise the KV cache so --fit can keep more layers on the GPU.
[ "$LLM_MEM_MB" -lt $(($(model_mb "$MODEL") + 4096)) ] && ARGS+=(-ctk q8_0 -ctv q8_0)
# shellcheck disable=SC2206
[ -n "${LLM_ARGS:-}" ] && ARGS+=($LLM_ARGS)

echo "🦙 backend=$LLM_BACKEND device=$LLM_DEVICE gpu=\"$LLM_GPU_NAME\" budget=${LLM_MEM_MB}MiB threads=$LLM_THREADS"
echo "   model=$(basename "$MODEL")"

if [ "$BACKGROUND" = 0 ]; then
    exec "$LLAMA_BIN/llama-server" "${ARGS[@]}"
fi

nohup "$LLAMA_BIN/llama-server" "${ARGS[@]}" >"$LOG" 2>&1 &
echo $! >"$PIDFILE"

for _ in $(seq 1 120); do
    if curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
        echo "   ready on http://localhost:$PORT  (log: $LOG)"
        exit 0
    fi
    if ! kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        echo "   llama-server exited during startup; last log lines:"
        tail -n 15 "$LOG" | sed 's/^/   | /'
        rm -f "$PIDFILE"
        exit 0
    fi
    sleep 1
done
echo "   still loading after 120s; check llm-status.bash or $LOG"
exit 0
