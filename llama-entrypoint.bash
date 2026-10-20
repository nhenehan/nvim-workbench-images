#!/bin/bash
set -e

grep -qxF 'bash ./.motd' .bashrc || echo "bash ./.motd" >>.bashrc
grep -qxF 'bash ./.versions' .bashrc || echo "bash ./.versions" >>.bashrc

mkdir -p ~/.config
if [ -d /home/dev/project/nvim ]; then
    echo "🔧 Using nvim/ config directory from project."
    cp -a /home/dev/project/nvim ~/.config/nvim
elif [ -f /home/dev/project/init.lua ]; then
    echo "🔧 Using local init.lua from project directory."
    mkdir -p ~/.config/nvim && cp /home/dev/project/init.lua ~/.config/nvim/init.lua
elif [ ! -d ~/.config/nvim ]; then
    echo "⚙️  Using LazyVim config baked into the image (NVIM_LANGS=$NVIM_LANGS)."
    cp -a /home/dev/default-nvim-config ~/.config/nvim
fi

# Detect the GPU and bring up llama-server in the background. Never block the shell.
if [ "${LLM_AUTOSTART:-1}" = 1 ]; then
    ~/scripts/llm-start.bash --background || true
fi

exec "$@"
