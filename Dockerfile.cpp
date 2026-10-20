FROM --platform=linux/amd64 debian:trixie-slim AS debian-dev-root

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ---------------- System dependencies -------------- #
RUN apt-get update && apt-get install -y              \
        gcc                                           \
        g++                                           \
        make                                          \
        unzip                                         \
        cmake                                         \
        git                                           \
        curl                                          \
        wget                                          \
        build-essential                               \
        pkg-config                                    \
        libssl-dev                                    \
        ca-certificates                               \
        locales                                       \
        fontconfig                                    \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen                                     \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && mkdir -p /usr/share/fonts/truetype/nerdfonts \
    && curl -Lo /tmp/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip \
    && unzip -o /tmp/FiraCode.zip -d /usr/share/fonts/truetype/nerdfonts \
    && fc-cache -fv \
    && rm /tmp/FiraCode.zip

# ---- variant packages ----
RUN apt-get update && apt-get install -y clangd clang-format lldb gdb valgrind \
    && rm -rf /var/lib/apt/lists/*

FROM debian-dev-root AS debian-dev-user

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ---------- Create non-root dev user ----------
RUN useradd -ms /bin/bash dev

# ---------- Ensure permissions ----------
RUN chown -R dev:dev /home/dev

USER dev
WORKDIR /home/dev

# ---------- Install Rust/Julia tools ----------
ARG JULIA_VERSION=1.12
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ENV HOME=/home/dev
ENV CARGO_HOME="$HOME/.cargo" 
ENV PATH="$CARGO_HOME/bin:$PATH" 
RUN rustup component add rust-analyzer
RUN cargo install cargo-edit cargo-watch juliaup
RUN juliaup add ${JULIA_VERSION}
RUN echo 'exit()' > juliatest.jl && julia juliatest.jl && rm juliatest.jl
ARG NVIM_VERSION=0.12.5
RUN mkdir -p opt \
    && curl -LO https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz \
    && rm -rf opt/nvim-linux-x86_64 \
    && tar -C opt -xzf nvim-linux-x86_64.tar.gz \
    && echo 'PATH="$PATH:$HOME/opt/nvim-linux-x86_64/bin"' >> .bashrc \
    && echo 'export PATH' >> .bashrc
RUN echo $PATH && ls -l "$HOME/.cargo/bin"

# ---------- Default Neovim config (LazyVim) ----------
ENV NVIM_LANGS="clangd,cmake"
ENV NVIM_CONTAINER=1
COPY --chown=dev:dev nvim-config /home/dev/default-nvim-config
COPY default-motd.bash ./.motd
COPY default-versions.bash ./.versions

# ---------- Pre-warm plugins and language tooling at build time ----------
# Lazy! restore checks out the exact commits in lazy-lock.json (synced from the host).
# Containers are ephemeral; nothing should be downloaded on first launch.
ENV PATH="$HOME/opt/nvim-linux-x86_64/bin:$PATH"
RUN mkdir -p $HOME/.config && cp -a $HOME/default-nvim-config $HOME/.config/nvim \
    && nvim --headless "+Lazy! restore" +qa 2>&1 | tail -5 \
    && nvim --headless -c "MasonInstall codelldb neocmakelsp cmakelang cmakelint" \
         -c "lua vim.wait(900000, function() local r=require('mason-registry') for _,n in ipairs(vim.split('codelldb neocmakelsp cmakelang cmakelint',' ')) do local ok,p=pcall(r.get_package,n) if ok and not p:is_installed() then return false end end return true end, 3000)" \
         -c "qa!" 2>&1 | tail -5 \
    && rm -rf $HOME/.config/nvim

# ---------- Entry point script ----------
RUN echo '#!/bin/bash\n\
set -e\n\
echo "bash ./.motd" >> .bashrc \n\
echo "bash ./.versions" >> .bashrc \n\
mkdir -p ~/.config\n\
if [ -d /home/dev/project/nvim ]; then\n\
  echo "🔧 Using nvim/ config directory from project."\n\
  cp -a /home/dev/project/nvim ~/.config/nvim\n\
elif [ -f /home/dev/project/init.lua ]; then\n\
  echo "🔧 Using local init.lua from project directory."\n\
  mkdir -p ~/.config/nvim && cp /home/dev/project/init.lua ~/.config/nvim/init.lua\n\
else\n\
  echo "⚙️  Using LazyVim config baked into the image (NVIM_LANGS=$NVIM_LANGS)."\n\
  cp -a /home/dev/default-nvim-config ~/.config/nvim\n\
fi\n\
exec "$@"' > /home/dev/entrypoint.sh && chmod +x /home/dev/entrypoint.sh

ENTRYPOINT ["/home/dev/entrypoint.sh"]
CMD ["/bin/bash"]
