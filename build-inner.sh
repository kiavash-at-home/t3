#!/usr/bin/env sh
set -eux

RUNTIME_REPO="${RUNTIME_REPO:?RUNTIME_REPO must be set}"
BRANCH="${BRANCH:?BRANCH must be set}"
MANIFEST="${MANIFEST:?MANIFEST must be set}"
APP_ID="${APP_ID:?APP_ID must be set}"

flatpak remote-add --system --if-not-exists \
    flathub "$RUNTIME_REPO"

flatpak-builder \
    --force-clean \
    --install-deps-from=flathub \
    --disable-rofiles-fuse \
    --state-dir=/build/state \
    --repo=/build/repo \
    --default-branch="$BRANCH" \
    /build/builddir \
    "$MANIFEST"

flatpak build-bundle \
    /build/repo \
    /out/t3code.flatpak \
    "$APP_ID" \
    "$BRANCH" \
    --runtime-repo="$RUNTIME_REPO"
