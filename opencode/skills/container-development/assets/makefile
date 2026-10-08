SHELL := /bin/bash
.DEFAULT_GOAL := help

ENGINE        ?= $(shell command -v docker >/dev/null 2>&1 && echo docker || echo podman)
COMPOSE       ?= $(ENGINE) compose
IMAGE         ?= {{NAME}}
CONTAINERFILE ?= Containerfile
PORT          ?= {{PORT}}
VERSION       ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
REVISION      ?= $(shell git rev-parse HEAD 2>/dev/null || echo unknown)
CREATED       ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

.PHONY: help build run lint size clean up down logs ps config

help: ## Show available targets
	@grep -hE '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-10s %s\n", $$1, $$2}'

build: ## Build the image locally
	$(ENGINE) build -f $(CONTAINERFILE) \
		--build-arg VERSION=$(VERSION) \
		--build-arg REVISION=$(REVISION) \
		--build-arg CREATED=$(CREATED) \
		-t $(IMAGE):$(VERSION) -t $(IMAGE):dev .

run: build ## Run the image hardened (read-only, no caps, loopback port)
	$(ENGINE) run --rm --init --read-only --tmpfs /tmp \
		--cap-drop ALL --security-opt no-new-privileges \
		-p 127.0.0.1:$(PORT):$(PORT) $(IMAGE):dev

lint: ## Lint the Containerfile (and compose file if present)
	hadolint $(CONTAINERFILE)
	$(COMPOSE) config --quiet # compose-only

size: ## Print the size of the built image
	@$(ENGINE) image inspect $(IMAGE):dev --format '{{.Size}}' | awk '{printf "%.1f MB\n", $$1/1000000}'

clean: ## Remove locally built images
	-$(ENGINE) rmi $(IMAGE):dev $(IMAGE):$(VERSION)

# >>> compose
.env:
	cp .env.example .env

up: .env ## Start the compose stack
	$(COMPOSE) up --build -d

down: ## Stop the stack and remove its containers
	$(COMPOSE) down

logs: ## Tail stack logs
	$(COMPOSE) logs -f

ps: ## Show stack status and health
	$(COMPOSE) ps

config: ## Validate and print the resolved compose config
	$(COMPOSE) config
# <<< compose
