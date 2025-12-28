#!/bin/bash

set -Eeuo pipefail

# ComfyUI tag initial value
export COMFYUI_TAG=""

if [ -f ./.env ]; then
  set -a
  source ./.env
  set +a
fi

# ComfyUIのコンテナをビルド
podman build -t comfyui:${COMFYUI_TAG:-"latest"} \
  --force-rm \
  --build-arg "COMFYUI_TAG=${COMFYUI_TAG}" \
  --device "nvidia.com/gpu=all" \
  ./services/comfyui
