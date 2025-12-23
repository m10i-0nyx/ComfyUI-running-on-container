#!/bin/bash

if [ -f env ]; then
  set -a
  source ./env
  set +a
fi

# Override with ./.env if it exists
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
  --env "ENABLED_WAN2_MODELS_DOWNLOAD=${ENABLED_WAN2_MODELS_DOWNLOAD:-"false"}" \
  --env "ENABLED_WAN2_MODELS_CHECKSUM=${ENABLED_WAN2_MODELS_CHECKSUM:-"false"}" \
  --volume "$(pwd)/data:/workspace/data" \
  localhost/downloader:latest
