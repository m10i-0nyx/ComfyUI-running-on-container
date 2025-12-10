#!/bin/bash

set -Eeuo pipefail

cd /opt/ComfyUI-running-on-container
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
podman build -t comfyui:${COMFYUI_TAG} \
  --force-rm \
  --build-arg COMFYUI_TAG=${COMFYUI_TAG} \
  --device "nvidia.com/gpu=all" \
  --volume "$(pwd)/data:/workspace/data" \
  ./services/comfyui/

# ComfyUIのコンテナをバックグラウンドで起動
#podman run -d --replace \
#  --name comfyui \
#  --volume "$(pwd)/data:/workspace/data" \
#  --device "nvidia.com/gpu=all" \
#  localhost/comfyui:${COMFYUI_TAG} \
#  sleep infinity

# 変換処理
#podman exec -t comfyui bash -c \
#'find /workspace/data/models/diffusion_models/ -type f -name "*.ckpt" -print0 |
# xargs -0 -I {} python3 /docker/convert_ckpt2safetensors.py "{}"'
#podman exec -t comfyui bash -c \
#'find /workspace/data/models/checkpoints/ -type f -name "*.ckpt" -print0 |
# xargs -0 -I {} python3 /docker/convert_ckpt2safetensors.py "{}"'

# コンテナ削除
#podman container rm -f comfyui
