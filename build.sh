#!/bin/bash

set -Eeuo pipefail

# ComfyUI tag initial value
export COMFYUI_TAG=""

if [ -f env ]; then
  set -a
  source ./env
  set +a
fi

# モデルをダウンロードするためのコンテナをビルド
podman build -t comfyui-model-downloader:latest \
  --force-rm \
  ./services/download/

# モデルをダウンロードするためのコンテナを実行
# 初回にだけ実行
podman run -it --rm \
  --name comfyui-model-downloader \
  --volume "$(pwd)/data:/workspace/data" \
  localhost/comfyui-model-downloader:latest

# ComfyUIのコンテナをビルド
podman build -t comfyui:${COMFYUI_TAG:-"latest"} \
  --force-rm \
  --build-arg "COMFYUI_TAG=${COMFYUI_TAG}" \
  --device "nvidia.com/gpu=all" \
  --volume "$(pwd)/data:/workspace/data" \
  ./services/comfyui/
