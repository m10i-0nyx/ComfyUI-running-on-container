#!/bin/bash

export PRIVATE_REGISTRY_URL=${PRIVATE_REGISTRY_URL:-'push.registry.foundation0.link'}

# ComfyUI tag initial value
export COMFYUI_TAG="v0.14.2"

if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

podman login ${PRIVATE_REGISTRY_URL}

podman tag comfyui:${COMFYUI_TAG:-"latest"} ${PRIVATE_REGISTRY_URL}/comfyui-running-on-container:${COMFYUI_TAG:-"latest"}
podman push ${PRIVATE_REGISTRY_URL}/comfyui-running-on-container:${COMFYUI_TAG:-"latest"}
podman tag ${PRIVATE_REGISTRY_URL}/comfyui-running-on-container:${COMFYUI_TAG:-"latest"} ${PRIVATE_REGISTRY_URL}/comfyui-running-on-container:latest
podman push ${PRIVATE_REGISTRY_URL}/comfyui-running-on-container:latest
podman image rm ${PRIVATE_REGISTRY_URL}/comfyui-running-on-container:latest
podman image rm ${PRIVATE_REGISTRY_URL}/comfyui-running-on-container:${COMFYUI_TAG:-"latest"}
