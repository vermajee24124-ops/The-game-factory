#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-v4.2.1}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 --branch "$TAG" https://github.com/hi-godot/godot-ai.git "$TMP/godot-ai"
mkdir -p vendor/godot-ai
rm -rf vendor/godot-ai/*
cp -R "$TMP/godot-ai/plugin/addons/godot_ai/." vendor/godot-ai/

printf 'Synced Godot AI %s into vendor/godot-ai\n' "$TAG"