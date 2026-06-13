FROM debian:trixie-slim AS debian-dev-root
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

FROM debian-dev-root AS debian-dev-user

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ---------- Create non-root dev user ----------
ARG USERNAME=appuser
ARG UID=1000
ARG GID=1000

ENV USERNAME=${USERNAME}

# ---------- Entry point script ----------
RUN echo '#!/bin/bash\n\
set -e\n\
echo "bash ./.motd" >> ./.bashrc \n\
echo "bash ./.versions" >> ./.bashrc \n\
if [ -f $HOME/project/init.lua ]; then\n\
  echo "🔧 Using local init.lua from project directory."\n\
  mkdir -p ~/.config/nvim\n\
  cp $HOME/project/init.lua ~/.config/nvim/init.lua\n\
  rm default-init.lua\n\
else\n\
  echo "⚙️  Using default Neovim config baked into the image."\n\
  mkdir -p ~/.config/nvim\n\
  mv default-init.lua ~/.config/nvim/init.lua\n\
fi\n\
exec "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

RUN groupadd --gid ${GID} ${USERNAME} \
 && useradd  --uid ${UID} --gid ${GID} \
    --create-home --shell /bin/bash ${USERNAME}

# ---------- Ensure permissions ----------
RUN chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

WORKDIR /home/${USERNAME}
USER ${USERNAME}

# ---------- Install Rust/Julia tools ----------
ARG JULIA_VERSION=1.12
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ENV HOME=/home/${USERNAME}
ENV CARGO_HOME="$HOME/.cargo" 
ENV PATH="$CARGO_HOME/bin:$PATH" 
RUN rustup component add rust-analyzer
RUN cargo install cargo-edit cargo-watch juliaup
RUN juliaup add ${JULIA_VERSION}
RUN echo 'exit()' > juliatest.jl && julia juliatest.jl && rm juliatest.jl
RUN mkdir -p opt \
    && curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
    && rm -rf opt/nvim-linux-x86_64 \
    && tar -C opt -xzf nvim-linux-x86_64.tar.gz \
    && echo 'PATH="$PATH:$HOME/opt/nvim-linux-x86_64/bin"' >> .bashrc \
    && echo 'export PATH' >> .bashrc
RUN ${HOME}/opt/nvim-linux-x86_64/bin/nvim --headless +TSUpdate +qall
RUN echo $PATH && ls -l "$HOME/.cargo/bin"

# ---------- Default Neovim config (fallback) ----------
COPY default-init.lua ./
COPY default-motd.bash ./.motd
COPY default-versions.bash ./.versions

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
