#!/bin/bash

set -Eeuo pipefail

# ComfyUI tag initial value
export COMFYUI_TAG=""

if [ -f ./.env ]; then
  set -a
  source ./.env
  set +a
fi

ARGS=""
for arg in "$@"; do
  if [ "$arg" = "--force-fp16" ]; then
    # --force-fp16 が引数に含まれている場合、ARGSに"--force-fp16"をセット
    ARGS="--force-fp16"
    continue
  fi
  if [ "$arg" = "--force-fp32" ]; then
    # --force-fp32 が引数に含まれている場合、ARGSに"--force-fp32"をセット
    ARGS="--force-fp32"
    continue
  fi
done

# dont-print-server オプションを追加
ARGS="${ARGS} --dont-print-server"

# ComfyUIのコンテナを実行
# WSL2起動時に実行すればOK
podman run -d --replace \
  --name comfyui \
  -p 8188:8188 \
  -p 8888:8888 \
  --volume "$(pwd)/data:/workspace/data" \
  --volume "$(pwd)/output:/workspace/output" \
  --device "nvidia.com/gpu=all" \
  --env ENABLED_COMFYUI_PREVIEW_GALLERY=${ENABLED_COMFYUI_PREVIEW_GALLERY:-"false"} \
  --env CLI_ARGS="${ARGS}" \
  localhost/comfyui:${COMFYUI_TAG:-"latest"}
