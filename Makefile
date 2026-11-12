FREEDESKTOP_VERSION := 26.08

APP_ID   := com.t3tools.t3code
BRANCH   := master
MANIFEST := com.t3tools.t3code.yml

IMAGE        := ghcr.io/flathub-infra/flatpak-github-actions:freedesktop-$(FREEDESKTOP_VERSION)
RUNTIME_REPO := https://dl.flathub.org/repo/flathub.flatpakrepo
RUNTIME_VOLUME := t3code-flatpak-runtime
BUILD_VOLUME   := t3code-flatpak-build

ROOT    := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
OUT_DIR := $(ROOT)/out
BUNDLE  := $(OUT_DIR)/t3code.flatpak

.PHONY: all build clean

all: build

## build: Pull the builder image, compile, and produce out/t3code.flatpak
build: $(OUT_DIR)
	@echo "==> Building $(APP_ID)"
	@echo "==> Freedesktop version: $(FREEDESKTOP_VERSION)"
	@echo "==> Runtime volume : $(RUNTIME_VOLUME)"
	@echo "==> Build volume   : $(BUILD_VOLUME)"
	docker volume create $(RUNTIME_VOLUME) > /dev/null
	docker volume create $(BUILD_VOLUME)   > /dev/null
	docker run --rm \
		--privileged \
		--volume "$(ROOT):/src:ro" \
		--volume "$(OUT_DIR):/out" \
		--volume "$(RUNTIME_VOLUME):/var/lib/flatpak" \
		--volume "$(BUILD_VOLUME):/build" \
		--env RUNTIME_REPO=$(RUNTIME_REPO) \
		--env BRANCH=$(BRANCH) \
		--env MANIFEST=$(MANIFEST) \
		--env APP_ID=$(APP_ID) \
		--workdir /src \
		"$(IMAGE)" \
		sh /src/build-inner.sh
	@echo
	@echo "==> Build completed successfully"
	@echo "==> Freedesktop: $(FREEDESKTOP_VERSION)"
	@echo "==> Bundle: $(BUNDLE)"

## clean: Remove build artifacts (out/ dir) and both Docker build volumes
clean:
	@echo "==> Cleaning build artifacts"
	rm -rf "$(OUT_DIR)"
	@echo "==> Removing Docker volumes: $(RUNTIME_VOLUME) $(BUILD_VOLUME)"
	docker volume rm --force $(RUNTIME_VOLUME) $(BUILD_VOLUME) 2>/dev/null || true
	@echo "==> Clean complete"

$(OUT_DIR):
	mkdir -p $@
