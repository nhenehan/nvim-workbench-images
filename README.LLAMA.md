# Llama How-To (Inside The Container)

If you just want a clean path from "I downloaded models" to "I have a working local API", follow this guide top to bottom.

## Running with Devcontainer (easiest)

If you open this repo in VS Code with **Dev Containers: Reopen in Container** and pick the `llama` environment, port 9090 is automatically exposed. Start your server and hit `http://localhost:9090` from your host browser immediately.

## Running with podman run (manual)

If you prefer the command line, make sure to expose the port and mount your models:

```bash
podman run -it --rm --userns=keep-id \
  -p 9090:9090 \
  -v $HOME/models:/home/dev/models \
  nvim-workbench-image-llama
```

If you also want to work on local projects inside the container, add an optional mount:

```bash
podman run -it --rm --userns=keep-id \
  -p 9090:9090 \
  -v $HOME/models:/home/dev/models \
  -v $HOME/repos:/home/dev/repos \
  nvim-workbench-image-llama
```

Then inside the container, launch the server. After that, your host browser can reach `http://localhost:9090`.

## 1) Confirm your model paths first

Start here so we avoid path mistakes later.

```bash id="findmodels"
find ~/models -name "*.gguf" -type f
```

You should see files like:

```text id="examplepaths"
/home/dev/models/Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf
/home/dev/models/DeepSeek-Coder-6.7B-Instruct-Q4_K_M.gguf
...
```

Tip: the exact folder/file names can vary depending on how `hf download` laid them out, so trust this output over memory.

## 2) Smoke-test models with llama-cli

Before launching a server, make sure each model can load and answer a prompt.

### Qwen 3B (quick sanity check)

```bash id="test3b"
llama-cli \
  -m ~/models/Qwen2.5-Coder-3B-Instruct-Q4_K_M.gguf \
  -t 16 \
  -c 8192 \
  -p "Write a Rust hello world program."
```

This one should usually respond quickly and is great for a first check.

### Qwen 7B

```bash id="test7b"
llama-cli \
  -m ~/models/Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf \
  -t 16 \
  -c 8192 \
  -p "Write a Rust hello world program."
```

### Qwen 14B

```bash id="test14b"
llama-cli \
  -m ~/models/Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf \
  -t 16 \
  -c 8192 \
  -p "Write a Rust hello world program."
```

Watch tokens/sec while these run so you can pick the best speed/quality tradeoff for your machine.

## 3) Launch llama-server

Once a model works in `llama-cli`, run it as a server.

### Example: Qwen 14B

```bash id="server14b"
llama-server \
  -m ~/models/Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf \
  -t 16 \
  -c 8192 \
  --host 0.0.0.0 \
  --port 8080
```

When ready, you should see:

```text id="serverready"
HTTP server listening on 0.0.0.0:8080
```

Leave this terminal running.

## 4) Verify the API from another terminal

Open a second shell in the same container and hit the endpoints:

```bash id="apitest"
curl http://localhost:8080/health
```

or:

```bash id="models"
curl http://localhost:8080/v1/models
```

Which endpoint works can depend on your `llama.cpp` version.

## 5) Send a chat completion request

```bash id="chattest"
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {
        "role": "user",
        "content": "Write a Rust hello world program"
      }
    ]
  }'
```

If everything is healthy, you will get JSON back with generated text.

## 6) Save a helper script for daily use

After you pick your preferred model, create a starter script:

```bash id="startserver"
#!/usr/bin/env bash

llama-server \
  -m "$HOME/models/Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf" \
  -t 16 \
  -c 8192 \
  --host 0.0.0.0 \
  --port 8080
```

Save it as:

```text id="filename"
~/scripts/start-llm.sh
```

Then run:

```bash id="runhelper"
bash ~/scripts/start-llm.sh
```

## If something feels off

Run this again and confirm the exact file paths you are using in `-m`:

```bash id="step1"
find ~/models -name "*.gguf" -type f
```

Most startup errors come down to pointing at the wrong model path.
