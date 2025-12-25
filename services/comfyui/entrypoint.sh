#!/bin/bash

set -Eeuo pipefail

mkdir -p ${WORKSPACE}/data/models/{checkpoints,clip_vision,controlnet,diffusion_models,gligen,hypernetworks,loras,text_encoders,upscale,vae}

declare -A MOUNTS

. ${VENV_PATH}/bin/activate

echo "===== ComfyUI Entrypoint Info ====="
echo "Workspace: ${WORKSPACE}"
echo "Venv: ${VENV_PATH}"
echo "Python: $(which python) ($(python --version))"
echo "----- torch info -----"
python -c "import torch; print('torch=', torch.__version__); print('torch_cuda=', torch.version.cuda); print('avail=', torch.cuda.is_available())"

MOUNTS["/root/.cache"]="${WORKSPACE}/data/.cache"
MOUNTS["${WORKSPACE}/input"]="${WORKSPACE}/data/config/input"
MOUNTS["/comfyui/output"]="${WORKSPACE}/output"

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

if [ -f "${WORKSPACE}/data/config/startup.sh" ]; then
  pushd ${WORKSPACE}
  . ${WORKSPACE}/data/config/startup.sh
  popd
fi

exec "$@"
