#!/bin/bash

set -Eeuo pipefail

mkdir -p ${WORKSPACE:-"/workspace"}/data/.cache
# Make sure workspace directories exist
mkdir -p ${WORKSPACE:-"/workspace"}/data/models/{checkpoints,clip_vision,configs,controlnet,diffusion_models,unet,hypernetworks,loras,text_encoders,upscale_models,vae,audio_encoders,model_patches}

export DOWNLOAD_LIST="/container/download_list.txt"
export CHECKSUM_LIST="/container/checksum_list.txt"
export DOWNLOAD_DIR="${WORKSPACE:-"/workspace"}/data/models"

rm -f "${DOWNLOAD_LIST}" >/dev/null 2>&1
rm -f "${CHECKSUM_LIST}" >/dev/null 2>&1

# Wan2.2 Models
if [ "${ENABLED_WAN2_MODELS_DOWNLOAD:-"false"}" = "true" ] || [ "${ENABLED_WAN2_MODELS_DOWNLOAD:-"0"}" = "1" ]; then
    echo "WAN2 Models download enabled."
    cat /container/preset_lists/download_wan2.txt >> "${DOWNLOAD_LIST}"
fi
if [ "${ENABLED_WAN2_MODELS_CHECKSUM:-"false"}" = "true" ] || [ "${ENABLED_WAN2_MODELS_CHECKSUM:-"0"}" = "1" ]; then
    echo "WAN2 Models checksum verification enabled."
    cat /container/preset_lists/checksum_wan2.txt >> "${CHECKSUM_LIST}"
fi

# FLUX.2 Models
if [ "${ENABLED_FLUX2_MODELS_DOWNLOAD:-"false"}" = "true" ] || [ "${ENABLED_FLUX2_MODELS_DOWNLOAD:-"0"}" = "1" ]; then
    echo "FLUX.2 Models download enabled."
    cat /container/preset_lists/download_flux2.txt >> "${DOWNLOAD_LIST}"
fi
if [ "${ENABLED_FLUX2_MODELS_CHECKSUM:-"false"}" = "true" ] || [ "${ENABLED_FLUX2_MODELS_CHECKSUM:-"0"}" = "1" ]; then
    echo "FLUX.2 Models checksum verification enabled."
    cat /container/preset_lists/checksum_flux2.txt >> "${CHECKSUM_LIST}"
fi

# Qwen-Image Models
if [ "${ENABLED_QWENIMAGE_MODELS_DOWNLOAD:-"false"}" = "true" ] || [ "${ENABLED_QWENIMAGE_MODELS_DOWNLOAD:-"0"}" = "1" ]; then
    echo "Qwen-Image Models download enabled."
    cat /container/preset_lists/download_qwenimage.txt >> "${DOWNLOAD_LIST}"
fi
if [ "${ENABLED_QWENIMAGE_MODELS_CHECKSUM:-"false"}" = "true" ] || [ "${ENABLED_QWENIMAGE_MODELS_CHECKSUM:-"0"}" = "1" ]; then
    echo "Qwen-Image Models checksum verification enabled."
    cat /container/preset_lists/checksum_qwenimage.txt >> "${CHECKSUM_LIST}"
fi

# Custom user lists
if [ -f "${WORKSPACE:-"/workspace"}/download_list.txt" ]; then
    echo "Custom download list found in download directory. Appending to download list."
    cat "${WORKSPACE:-"/workspace"}/download_list.txt" >> "${DOWNLOAD_LIST}"
fi
if [ -f "${WORKSPACE:-"/workspace"}/checksum_list.txt" ]; then
    echo "Custom checksum list found in download directory. Appending to checksum list."
    cat "${WORKSPACE:-"/workspace"}/checksum_list.txt" >> "${CHECKSUM_LIST}"
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
