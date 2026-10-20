#!/bin/bash
# dev-versions.sh
# Print Rust, Julia, GCC, libc, Neovim versions

if [ -t 1 ]; then
    echo "🔧 Dev Tool Versions:"
    echo "===================="

    # Rust
    if command -v rustc >/dev/null 2>&1; then
        echo "🦀 Rust: $(rustc --version)"
    else
        echo "🦀 Rust: not installed"
    fi

    # Julia
    if command -v julia >/dev/null 2>&1; then
        echo "🪶 Julia: $(julia --version | head -n1)"
    else
        echo "🪶 Julia: not installed"
    fi

    # GCC
    if command -v gcc >/dev/null 2>&1; then
        echo "⚙️ GCC: $(gcc --version | head -n1)"
    else
        echo "⚙️ GCC: not installed"
    fi

    # libc (glibc)
    if ldd --version >/dev/null 2>&1; then
        echo "🧩 libc: $(ldd --version | head -n1)"
    else
        echo "🧩 libc: unknown"
    fi

    # Neovim
    if command -v nvim >/dev/null 2>&1; then
        echo "🖥️ Neovim: $(nvim --version | head -n1)"
    else
        echo "🖥️ Neovim: not installed"
    fi

    # Local LLM / agents (llama image only)
    if [ -x "$HOME/opt/llama.cpp/build/bin/llama-server" ]; then
        if curl -fsS "http://127.0.0.1:${LLM_PORT:-9090}/health" >/dev/null 2>&1; then
            echo "🦙 llama-server: up on :${LLM_PORT:-9090} ($(curl -fsS "http://127.0.0.1:${LLM_PORT:-9090}/props" 2>/dev/null | jq -r '.model_path // "?"' | xargs -r basename))"
        else
            echo "🦙 llama-server: not running (llm-start.bash --background)"
        fi
    fi
    command -v claude >/dev/null 2>&1 && echo "🤖 Claude Code: $(claude --version 2>/dev/null | head -n1)"
    command -v opencode >/dev/null 2>&1 && echo "🤖 opencode: $(opencode --version 2>/dev/null | head -n1)"

    echo "===================="
fi

