# Llama Workbench

The llama image starts a local `llama-server` on its own when the container starts. It
detects the GPU you passed in, picks the largest model in `~/models` that fits, and
serves it on port **9090** under the model name `local`. Neovim (codecompanion.nvim,
llama.vim), opencode and the `ask-*` scripts all point at that server.

## 1) Get models (on the host, once)

```bash
make llama-cpp-models          # downloads Qwen2.5-Coder 3B/7B/14B (+ DeepSeek 6.7B) into ~/models
```

Any `.gguf` under `~/models` works, including split `-00001-of-0000N.gguf` sets.

## 2) Start the container

### make (recommended)

```bash
make llama-shell
```

This passes through `/dev/dri` (Vulkan) and NVIDIA via CDI when `nvidia-smi` works
on the host. It also maps port 9090 and mounts `~/models`.

ROCm is opt-in: `make llama-shell LLAMA_ROCM=1` also passes `/dev/kfd`. Use it only on
a discrete AMD GPU. On an APU (e.g. the Radeon 780M) Vulkan is faster anyway, and a
ROCm kernel fault there takes down the display along with the container.

### podman run (manual)

```bash
podman run -it --rm --userns=keep-id --group-add keep-groups \
  --device /dev/dri \
  -p 9090:9090 \
  -v $HOME/models:/home/dev/models \
  nvim-workbench-image-llama
```

`/dev/dri` gives Vulkan (AMD, Intel, NVIDIA). Add `--device /dev/kfd` for ROCm on a
discrete AMD GPU only (see above). For CUDA, add
`--device nvidia.com/gpu=all` (needs nvidia-container-toolkit). Leave out any device
your host doesn't have. With Docker, use `--gpus all` for
NVIDIA and drop `--userns`/`--group-add`.

### Devcontainer

Pick the `llama` environment in **Dev Containers: Reopen in Container**. It passes
`/dev/dri` through (not `/dev/kfd`), forwards 9090, and starts the server from
`postStartCommand`. See the comments in `.devcontainer/llama/devcontainer.json` for
NVIDIA.

On startup you should see something like:

```text
🦙 backend=vulkan device=Vulkan0 gpu="AMD Radeon 780M Graphics (RADV PHOENIX)" budget=15600MiB threads=8
   model=Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf
   ready on http://localhost:9090  (log: /home/dev/logs/llama-server.log)
```

## How the GPU is chosen

llama.cpp is built with every backend as a runtime-loaded module (`GGML_BACKEND_DL`),
so the same binary covers all vendors. `llm-detect.bash` asks
`llama-server --list-devices` what it can actually see, then picks:

| Hardware | Backend | Why |
|---|---|---|
| NVIDIA | CUDA | fastest on NVIDIA |
| AMD discrete | ROCm | faster prompt processing than Vulkan |
| AMD APU / iGPU (e.g. 780M) | Vulkan | faster than ROCm on RDNA3 iGPUs, needs no gfx override; budget capped at 60% of RAM |
| Intel / other | Vulkan | |
| nothing passed through | CPU | 70% of available RAM |

GPU layers and context size are left to llama-server's `--fit`, which sizes them to the
device's free memory (minimum context 8192). When memory is tight the KV cache is
quantised to q8_0. `--parallel 2` keeps a slot free for llama.vim completions while you
chat.

## Overrides

| Variable | Effect |
|---|---|
| `LLM_AUTOSTART=0` | don't start the server on container start |
| `LLM_BACKEND=cuda\|rocm\|vulkan\|cpu` | force a backend |
| `LLM_MODEL=/home/dev/models/x.gguf` | force a model |
| `LLM_CTX=16384` | fixed context size instead of `--fit` |
| `LLM_PARALLEL=1` | server slots |
| `LLM_PORT=9090` | listen port (also read by the Neovim plugins and `ask-llm.bash`) |
| `LLM_ARGS="--temp 0.2"` | extra llama-server arguments |

Pass them with `-e`, e.g. `podman run -e LLM_BACKEND=rocm ...`. Inside the container:

```bash
llm-status.bash                 # health, served model, log tail
llm-stop.bash
LLM_MODEL=~/models/Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf llm-start.bash --background
llm-detect.bash                 # just print what would be chosen
```

## Using it

### Neovim

| Keys | Action |
|---|---|
| `<leader>Ac` | toggle codecompanion chat (local model) |
| `<leader>Ai` | inline prompt on the buffer/selection |
| `<leader>Aa` | codecompanion actions |
| `<leader>As` (visual) | add selection to chat |
| `<leader>Ak` | chat with the **Claude Code** agent (ACP) |
| `<leader>Ao` | chat with the **opencode** agent (ACP, local model) |
| `<M-l>` / `<M-j>` / `<M-w>` (insert) | accept llama.vim completion: all / line / word |
| `<leader>ac` | Claude Code in a split (claudecode.nvim, same as the other images) |

The Claude Code agent needs `CLAUDE_CODE_OAUTH_TOKEN` (from `claude setup-token`) or
`ANTHROPIC_API_KEY` in the container environment, or run `claude` once to log in.

### Shell

```bash
opencode                        # agent TUI, preconfigured for llama.cpp/local
claude                          # Claude Code
ask-llm.bash "Write a Rust hello world program."
ask-code.bash "where is the config parsed?"     # greps the repo for context first
curl localhost:9090/v1/chat/completions -H 'Content-Type: application/json' \
  -d '{"model":"local","messages":[{"role":"user","content":"hi"}]}'
```

## Building

`make compose` (or `podman build -f Dockerfile.llama .`) builds the CUDA, ROCm and
Vulkan backends. The image is large (~15-20 GB) and the build is slow. Build args:

| Arg | Default | |
|---|---|---|
| `LLAMA_CUDA` / `LLAMA_HIP` / `LLAMA_VULKAN` | `ON` | drop a backend and its toolkit |
| `CUDA_ARCHS` | `75;80;86;89;90;120` | narrow to your card, e.g. `89` |
| `HIP_TARGETS` | RDNA2-4 + MI200/300 | narrow to your card, e.g. `gfx1100` |
| `BUILD_JOBS` | `8` | lower if nvcc/hipcc get OOM-killed |
| `LLAMA_REF` | `v0.7.0` | llama.cpp release tag |

For this laptop (Radeon 780M) alone, `--build-arg LLAMA_CUDA=OFF --build-arg LLAMA_HIP=OFF`
is enough: it runs on Vulkan anyway.
