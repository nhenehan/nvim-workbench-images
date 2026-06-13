# nvim-workbench-images

This repository provides container images for development environments built from the various `Dockerfile.*` files in the repo.

## Podman usage

The `Dockerfile.llama` image is built and started with Podman like this:

```bash
podman build -f Dockerfile.llama -t vibecode-dev .
podman run -it --rm --userns=keep-id \
  -v $HOME/Source/Workspaces/sample-dashboard:/home/dev/repos/sample-dashboard \
  vibecode-dev
```

`--userns=keep-id` keeps file ownership aligned with your host user, and the `-v` mount makes the target repository available inside the container at `/home/dev/repos/sample-dashboard`.

The other Dockerfiles are started in the same or a similar way: build the desired `Dockerfile.*` into an image, then run that image with the repository you want mounted into `/home/dev/repos/<repo-name>`.

## Makefile usage

The repository also includes a `Makefile` with targets for the default image and for building all images.

```bash
make build
make compose
make run
make shell
```

`make build` builds the default image as `nvim-workbench-image`. `make compose` builds every `Dockerfile.*` image in the repo, tagging them as `nvim-workbench-image`, `nvim-workbench-image-cpp`, `nvim-workbench-image-java`, `nvim-workbench-image-llama`, and `nvim-workbench-image-rust`. `make run` starts the default image with the current directory mounted at `/work`, and `make shell` starts the same container with an interactive `bash` session. Those targets use the current host user and group so files created in the container stay writable on the host.

The Makefile auto-selects `podman` when it is available and falls back to `docker`. If you want to force one engine, override `ENGINE`, for example `make ENGINE=docker compose`.

## Devcontainer usage

Each Dockerfile has a matching configuration under `.devcontainer/`:

| Subfolder | Dockerfile |
|---|---|
| `default` | `Dockerfile` (Rust + Julia + Neovim) |
| `cpp` | `Dockerfile.cpp` |
| `java` | `Dockerfile.java` |
| `rust` | `Dockerfile.rust` |
| `llama` | `Dockerfile.llama` (llama.cpp + LLM tools) |

Open this repo (or any repo whose workspace you want to develop in) in VS Code, then run **Dev Containers: Reopen in Container** and pick the environment you want. VS Code will build the image if it doesn't exist and mount your workspace at `/home/dev/repos/<workspace-name>` inside the container, matching the same path the manual run commands use.

The `llama` configuration also bind-mounts `$HOME/models` on your host to `/home/dev/models` in the container so downloaded models survive container rebuilds.

### Using Podman with VS Code

The configs include `--userns=keep-id` in `runArgs` so file ownership stays aligned with your host user. For VS Code to call Podman instead of Docker, add this to your VS Code `settings.json`:

```json
"dev.containers.dockerPath": "podman"
```

Remove the `--userns=keep-id` line from `runArgs` if you switch to Docker.