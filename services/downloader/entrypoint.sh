#!/bin/bash

set -Eeuo pipefail

mkdir -p /workspace/data/.cache
mkdir -p /workspace/data/models/{checkpoints,clip,clip_vision,controlnet,diffusion_models,gligen,hypernetworks,loras,text_encoders,upscale,vae}

export DOWNLOAD_LIST="/container/download_list.txt"
export CHECKSUM_LIST="/container/checksum_list.txt"
export DOWNLOAD_DIR="/workspace/data/models"

rm -f "${DOWNLOAD_LIST}" >/dev/null 2>&1
rm -f "${CHECKSUM_LIST}" >/dev/null 2>&1

if [ "${ENABLED_WAN2_MODELS_DOWNLOAD:-"false"}" = "true" ] || [ "${ENABLED_WAN2_MODELS_DOWNLOAD:-"0"}" = "1" ]; then
    echo "WAN2 Models download enabled."
    cat /container/preset_lists/download_wan2.txt >> "${DOWNLOAD_LIST}"
fi
if [ "${ENABLED_WAN2_MODELS_CHECKSUM:-"false"}" = "true" ] || [ "${ENABLED_WAN2_MODELS_CHECKSUM:-"0"}" = "1" ]; then
    echo "WAN2 Models checksum verification enabled."
    cat /container/preset_lists/checksum_wan2.txt >> "${CHECKSUM_LIST}"
fi

if [ -f "${DOWNLOAD_DIR}/download_list.txt" ]; then
    echo "Custom download list found in download directory. Appending to download list."
    cat "${DOWNLOAD_DIR}/download_list.txt" >> "${DOWNLOAD_LIST}"
fi
if [ -f "${DOWNLOAD_DIR}/checksum_list.txt" ]; then
    echo "Custom checksum list found in download directory. Appending to checksum list."
    cat "${DOWNLOAD_DIR}/checksum_list.txt" >> "${CHECKSUM_LIST}"
fi

if [ -f "${DOWNLOAD_LIST}" ]; then
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

if [ -f "${CHECKSUM_LIST}" ]; then
    echo "${CHECKSUM_LIST} found. Starting sha256sum verification..."

    grep -E -v '^[#|;]' "${CHECKSUM_LIST}" | parallel --will-cite -n1 'echo -n {} | sha256sum -c'

    echo "Checksum verification finished."
else
    echo "No ${CHECKSUM_LIST} found. Skipping checksum verification."
fi
