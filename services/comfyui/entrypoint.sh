#!/bin/bash

set -Eeuo pipefail

# Make sure workspace directories exist
mkdir -p ${WORKSPACE}/data/models/{checkpoints,clip_vision,configs,controlnet,diffusion_models,unet,hypernetworks,loras,text_encoders,upscale_models,vae,audio_encoders,model_patches}

# Activate virtual environment
source ${VENV_PATH}/bin/activate

echo "===== NVIDIA info ====="
nvidia-smi
echo "===== ComfyUI Entrypoint Info ====="
echo "Workspace: ${WORKSPACE}"
echo "Venv: ${VENV_PATH}"
echo "Python: $(which python) ($(python --version))"
echo "===== torch info ====="
python -c "import torch; print('torch=', torch.__version__); print('torch_cuda=', torch.version.cuda); print('avail=', torch.cuda.is_available())"
echo "==================================="

declare -A MOUNTS
MOUNTS["/root/.cache"]="${WORKSPACE}/data/.cache"
MOUNTS["/comfyui/input"]="${WORKSPACE}/data/input"
MOUNTS["/comfyui/output"]="${WORKSPACE}/output"

# Model directories
for to_path in "${!MOUNTS[@]}"; do
    set -Eeuo pipefail
    from_path="${MOUNTS[${to_path}]}"
    rm -rf "${to_path}"
    if [ ! -f "$from_path" ]; then
        mkdir -vp "$from_path"
    fi
    mkdir -vp "$(dirname "${to_path}")"
    ln -sT "${from_path}" "${to_path}"
    echo Mounted $(basename "${from_path}")
done

# Run user startup script if it exists
if [ -f "${WORKSPACE}/data/startup.sh" ]; then
    pushd ${WORKSPACE}
    . ${WORKSPACE}/data/startup.sh
    popd
fi

exec "$@"
