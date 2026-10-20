IMAGE_NAME := nvim-workbench-image
CONTAINER_NAME := my-nvim-workbench-image
ENGINE ?= $(shell if command -v podman >/dev/null 2>&1; then echo podman; elif command -v docker >/dev/null 2>&1; then echo docker; else echo podman; fi)

DOCKERFILES := Dockerfile Dockerfile.cpp Dockerfile.java Dockerfile.llama Dockerfile.rust

# Images track the host: same nvim release, same config (see sync-nvim).
NVIM_VERSION ?= $(shell nvim --version 2>/dev/null | sed -n '1s/^NVIM v//p')
NVIM_VERSION_ARG := $(if $(NVIM_VERSION),--build-arg NVIM_VERSION=$(NVIM_VERSION))
HOST_NVIM_CONFIG ?= $(HOME)/.config/nvim

# Current host user info
USER_NAME := $(shell id -un)
USER_ID   := $(shell id -u)
GROUP_ID  := $(shell id -g)

.PHONY: build run shell clean compose llama-cpp-models sync-nvim llama-shell

build:
	$(ENGINE) build \
		--build-arg USERNAME=$(USER_NAME) \
		--build-arg UID=$(USER_ID) \
		--build-arg GID=$(GROUP_ID) \
		$(NVIM_VERSION_ARG) \
		-t $(IMAGE_NAME) .

compose:
	@set -e; \
	for dockerfile in $(DOCKERFILES); do \
		case "$$dockerfile" in \
			Dockerfile) image_name="$(IMAGE_NAME)" ;; \
			Dockerfile.cpp) image_name="$(IMAGE_NAME)-cpp" ;; \
			Dockerfile.java) image_name="$(IMAGE_NAME)-java" ;; \
			Dockerfile.llama) image_name="$(IMAGE_NAME)-llama" ;; \
			Dockerfile.rust) image_name="$(IMAGE_NAME)-rust" ;; \
		esac; \
		$(ENGINE) build $(NVIM_VERSION_ARG) -f "$$dockerfile" -t "$$image_name" .; \
	done

run:
	$(ENGINE) run --rm \
		--name $(CONTAINER_NAME) \
		-u $(USER_ID):$(GROUP_ID) \
		-v $(PWD):/work \
		-w /work \
		$(IMAGE_NAME)

shell:
	$(ENGINE) run --rm -it \
		--name $(CONTAINER_NAME) \
		-u $(USER_ID):$(GROUP_ID) \
		-v $(PWD):/work \
		-w /work \
		$(IMAGE_NAME) \
		bash

# Copy the host Neovim config (including lazy-lock.json) into the image build context.
sync-nvim:
	rsync -a --delete --exclude .git --exclude README.md --exclude LICENSE \
		$(HOST_NVIM_CONFIG)/ nvim-config/

# Interactive llama workbench with whatever GPUs this host has passed through.
# ROCm is opt-in (LLAMA_ROCM=1 passes /dev/kfd): a ROCm fault on an APU hangs the display.
LLAMA_ROCM ?= 0
llama-shell:
	$(ENGINE) run --rm -it \
		--name $(CONTAINER_NAME)-llama \
		$(if $(filter podman,$(ENGINE)),--userns=keep-id --group-add keep-groups) \
		$(if $(wildcard /dev/dri),--device /dev/dri) \
		$(if $(filter 1,$(LLAMA_ROCM)),$(if $(wildcard /dev/kfd),--device /dev/kfd)) \
		$(shell if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then \
			if [ "$(ENGINE)" = podman ]; then echo --device nvidia.com/gpu=all; else echo --gpus all; fi; fi) \
		-p 9090:9090 \
		-v $(HOME)/models:/home/dev/models \
		$(IMAGE_NAME)-llama

clean:
	$(ENGINE) rmi $(IMAGE_NAME)

llama-cpp-models:
	mkdir -p $(HOME)/models
	$(ENGINE) run --rm \
		-e HOME=/root \
		-v $(HOME)/models:/root/models \
		-v $(PWD)/download-models.bash:/download-models.bash \
		python:3.12-slim \
		bash -c "pip install -q --root-user-action=ignore huggingface_hub && bash /download-models.bash"

