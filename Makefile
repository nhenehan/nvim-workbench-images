IMAGE_NAME := nvim-workbench-image
CONTAINER_NAME := my-nvim-workbench-image
ENGINE ?= $(shell if command -v podman >/dev/null 2>&1; then echo podman; elif command -v docker >/dev/null 2>&1; then echo docker; else echo podman; fi)

DOCKERFILES := Dockerfile Dockerfile.cpp Dockerfile.java Dockerfile.llama Dockerfile.rust

# Current host user info
USER_NAME := $(shell id -un)
USER_ID   := $(shell id -u)
GROUP_ID  := $(shell id -g)

.PHONY: build run shell clean compose llama-cpp-models

build:
	$(ENGINE) build \
		--build-arg USERNAME=$(USER_NAME) \
		--build-arg UID=$(USER_ID) \
		--build-arg GID=$(GROUP_ID) \
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
		$(ENGINE) build -f "$$dockerfile" -t "$$image_name" .; \
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

