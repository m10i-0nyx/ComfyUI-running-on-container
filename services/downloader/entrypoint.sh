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
if [ -n "${ENABLED_WAN2_MODELS_DOWNLOAD:-''}" ] && [ "${ENABLED_WAN2_MODELS_DOWNLOAD:-'false'}" = "true" ]; then
    echo "WAN2 Models download enabled."
    cat /container/preset_lists/download_wan2.txt >> "${DOWNLOAD_LIST}"
fi

# FLUX.2 Models
if [ -n "${ENABLED_FLUX2_MODELS_DOWNLOAD:-''}" ] && [ "${ENABLED_FLUX2_MODELS_DOWNLOAD:-'false'}" = "true" ]; then
    echo "FLUX.2 Models download enabled."
    cat /container/preset_lists/download_flux2.txt >> "${DOWNLOAD_LIST}"
fi

# Qwen-Image Models
if [ -n "${ENABLED_QWENIMAGE_MODELS_DOWNLOAD:-''}" ] && [ "${ENABLED_QWENIMAGE_MODELS_DOWNLOAD:-'false'}" = "true" ]; then
    echo "Qwen-Image Models download enabled."
    cat /container/preset_lists/download_qwenimage.txt >> "${DOWNLOAD_LIST}"
fi

# LTX-2 Models
if [ -n "${ENABLED_LTX2_MODELS_DOWNLOAD:-''}" ] && [ "${ENABLED_LTX2_MODELS_DOWNLOAD:-'false'}" = "true" ]; then
    echo "LTX-2 Models download enabled."
    cat /container/preset_lists/download_ltx2.txt >> "${DOWNLOAD_LIST}"
fi
if [ -n "${ENABLED_LTX2FP8_MODELS_DOWNLOAD:-''}" ] && [ "${ENABLED_LTX2FP8_MODELS_DOWNLOAD:-'false'}" = "true" ]; then
    echo "LTX-2(FP8) Models download enabled."
    cat /container/preset_lists/download_ltx2fp8.txt >> "${DOWNLOAD_LIST}"
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
