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

    echo "===================="
fi

