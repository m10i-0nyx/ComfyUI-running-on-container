#!/usr/bin/env bash

set -Eeuo pipefail

# TODO: maybe just use the .gitignore file to create all of these
mkdir -p /workspace/data/.cache
mkdir -p /workspace/data/models/{checkpoints,clip,clip_vision,controlnet,diffusion_models,gligen,hypernetworks,loras,text_encoders,upscale,vae}

DOWNLOAD_LIST="/container/download.list"
DOWNLOAD_DIR="/workspace/data/models"

if [ -f "$DOWNLOAD_LIST" ]; then
    echo "${DOWNLOAD_LIST} found. Starting aria2c downloads..."
    mkdir -p "$DOWNLOAD_DIR"

    aria2c \
        --continue=true \
        --allow-overwrite=false \
        --auto-file-renaming=false \
        --max-connection-per-server=4 \
        --split=16 \
        --dir="${DOWNLOAD_DIR}" \
        --input-file="${DOWNLOAD_LIST}"

    echo "Download finished."
else
    echo "No ${DOWNLOAD_LIST} found. Skipping download."
fi

CHECKSUM_LIST="/container/checksums.list"
if [ -f "$CHECKSUM_LIST" ]; then
    echo "${CHECKSUM_LIST} found. Starting sha256sum verification..."

    parallel --will-cite -a "${CHECKSUM_LIST}" "echo -n {} | sha256sum -c"

    echo "Checksum verification finished."
else
    echo "No ${CHECKSUM_LIST} found. Skipping checksum verification."
fi


cat <<EOF
By using this software, you agree to the following licenses:
https://github.com/comfyanonymous/ComfyUI/blob/master/LICENSE
And licenses of all UIs, third party libraries, and extensions.
EOF
