#!/bin/bash

if [ -f env ]; then
  set -a
  source ./env
  set +a
fi

ARGS="--force-fp16"
# --force-fp32 が引数に含まれている場合、ARGSに"--force-fp32"をセット
for arg in "$@"; do
  if [ "$arg" = "--force-fp32" ]; then
    ARGS="--force-fp32"
    break
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
  -e CLI_ARGS="${ARGS}" \
  localhost/comfyui:${COMFYUI_TAG}
