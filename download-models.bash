#!/usr/bin/env bash
set -euo pipefail

MODEL_DIR="${HOME}/models"
mkdir -p "$MODEL_DIR"

echo "📦 Laptop profile"
echo "📦 Downloading models into: $MODEL_DIR"

download() {
    local repo="$1"
    local include="$2"
    local description="$3"

    echo
    echo "⬇️  $description"

    hf download \
        "$repo" \
        --include "$include" \
        --local-dir "$MODEL_DIR"
}

#
# Laptop Profile
#
# Ryzen 9 8945HS
# 32 GB RAM
# Radeon 780M
#

# --------------------------------------------------
# Primary coding model
# --------------------------------------------------
download \
    "bartowski/Qwen2.5-Coder-14B-Instruct-GGUF" \
    "*Q4_K_M.gguf" \
    "Qwen2.5-Coder-14B-Instruct Q4_K_M (~9 GB)"

# --------------------------------------------------
# Secondary coding model
# --------------------------------------------------
download \
    "bartowski/DeepSeek-Coder-6.7B-Instruct-GGUF" \
    "*Q4_K_M.gguf" \
    "DeepSeek-Coder-6.7B-Instruct Q4_K_M (~4 GB)"

# --------------------------------------------------
# Lightweight coding model
# --------------------------------------------------
download \
    "bartowski/Qwen2.5-Coder-7B-Instruct-GGUF" \
    "*Q4_K_M.gguf" \
    "Qwen2.5-Coder-7B-Instruct Q4_K_M (~5 GB)"

# --------------------------------------------------
# Tiny / utility model
# --------------------------------------------------
download \
    "bartowski/Qwen2.5-Coder-3B-Instruct-GGUF" \
    "*Q4_K_M.gguf" \
    "Qwen2.5-Coder-3B-Instruct Q4_K_M (~2 GB)"

echo
echo "✅ Downloads complete"
echo

find "$MODEL_DIR" -name "*.gguf" -type f