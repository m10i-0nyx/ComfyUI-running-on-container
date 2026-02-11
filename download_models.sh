#!/bin/bash

if [ -f ./.env ]; then
  set -a
  source ./.env
  set +a
fi

# モデルをダウンロードするためのコンテナをビルド
podman build -t downloader:latest \
  --force-rm \
  ./services/downloader/

# モデルをダウンロードするためのコンテナを実行
podman run -it --rm \
  --name downloader \
  --env "WORKSPACE=/workspace" \
  --env "ENABLED_WAN2_MODELS_DOWNLOAD=${ENABLED_WAN2_MODELS_DOWNLOAD:-'false'}" \
  --env "ENABLED_FLUX2_MODELS_DOWNLOAD=${ENABLED_FLUX2_MODELS_DOWNLOAD:-'false'}" \
  --env "ENABLED_LTX2FP8_MODELS_DOWNLOAD=${ENABLED_LTX2FP8_MODELS_DOWNLOAD:-'false'}" \
  --env "ENABLED_QWENIMAGE_MODELS_DOWNLOAD=${ENABLED_QWENIMAGE_MODELS_DOWNLOAD:-'false'}" \
  --volume "$(pwd)/data:/workspace/data" \
  localhost/downloader:latest
