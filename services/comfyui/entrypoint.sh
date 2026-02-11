#!/bin/bash

set -Eeuo pipefail

# --- 1. ディレクトリ作成 ---
# Make sure workspace directories exist
mkdir -p ${WORKSPACE}/data/.cache
mkdir -p ${WORKSPACE}/data/comfyui/custom_nodes
mkdir -p ${WORKSPACE}/data/models/{checkpoints,clip_vision,configs,controlnet,diffusion_models,unet,hypernetworks,loras,text_encoders,upscale_models,vae,audio_encoders,model_patches,latent_upscale_models}

declare -A MOUNTS

MOUNTS["/root/.cache"]="${WORKSPACE}/data/.cache"
MOUNTS["/comfyui/input"]="${WORKSPACE}/data/input"
MOUNTS["/comfyui/output"]="${WORKSPACE}/output"

for to_path in "${!MOUNTS[@]}"; do
    set -Eeuo pipefail
    from_path="${MOUNTS[${to_path}]}"
    rm -rf "${to_path}"
    if [ ! -f "${from_path}" ]; then
        mkdir -vp "${from_path}"
    fi
    mkdir -vp "$(dirname "${to_path}")"
    ln -sT "${from_path}" "${to_path}"
    echo Mounted $(basename "${from_path}")
done

# --- 2. Python venv activate & exec ---
source ${VENV_PATH}/bin/activate

# Upgrade torch to latest stable
uv pip install --upgrade "torch>=2.10.0" torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130

# --- 3. Print system info ---
echo "===== NVIDIA info ====="
nvidia-smi
echo "===== ComfyUI Entrypoint Info ====="
echo "Workspace: ${WORKSPACE}"
echo "Venv: ${VENV_PATH}"
echo "Python: $(which python) ($(python --version))"
echo "----- torch info -----"
python -c "import torch; print('torch=', torch.__version__); print('torch_cuda=', torch.version.cuda); print('avail=', torch.cuda.is_available())"

export TORCH_CUDA_AVAILABLE=$(python -c "import torch; print(torch.cuda.is_available())")
if [ "${TORCH_CUDA_AVAILABLE}" = "False" ]; then
    echo "CUDA is not available. Dropping to shell for debugging."
    exec /bin/bash || exec /bin/sh
fi

# --- 4. カスタムノードをインストール ---

# ComfyUI の custom_nodes ディレクトリを workspace 内のものに置き換え
pushd ${COMFYUI_DIR}
rm -rf custom_nodes 2>&1 >/dev/null
ln -s ${WORKSPACE}/data/comfyui/custom_nodes .
popd

# ComfyUI-Manager の設定ファイルを作成
mkdir -p ${COMFYUI_DIR}/user/__manager/
if [ ! -f ${COMFYUI_DIR}/user/__manager/config.ini ]; then
cat << '_EOL_' > ${COMFYUI_DIR}/user/__manager/config.ini
[default]
git_exe =
use_uv = True
channel_url = https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main
share_option = all
bypass_ssl = False
file_logging = True
update_policy = stable-comfyui
windows_selector_event_loop_policy = False
model_download_by_agent = False
downgrade_blacklist =
security_level = normal
always_lazy_install = False
network_mode = private
db_mode = cache
verbose = False
_EOL_
fi

# comfy-cli をインストール
uv pip install comfy-cli
# 初回に Do you agree to enable tracking to improve the application? [y/N]: を聞かれるので自動で "N" を入力して設定する
echo "N" | comfy set-default ${COMFYUI_DIR}
comfy env

# Pixel Socket extensions for ComfyUI をインストール
pushd "${WORKSPACE}/data/comfyui/custom_nodes"
if [ ! -d "pixel-socket-extensions-for-comfyui" ] || [ "${FORCE_UPGRADE_CUSTOM_NODES:-'false'}" = "true" ] ; then
    echo "Installing/upgrading pixel-socket-extensions-for-comfyui..."
    rm -rf pixel-socket-extensions-for-comfyui >/dev/null 2>&1
    git clone -b main --depth 1 https://github.com/0nyx-networks/pixel-socket-extensions-for-comfyui.git
fi
cd pixel-socket-extensions-for-comfyui
uv pip install -r requirements.txt
popd

# comfyui-crystools をインストール
pushd "${WORKSPACE}/data/comfyui/custom_nodes"
if [ ! -d "comfyui-crystools" ] || [ "${FORCE_UPGRADE_CUSTOM_NODES:-'false'}" = "true" ] ; then
    echo "Installing/upgrading comfyui-crystools..."
    rm -rf comfyui-crystools >/dev/null 2>&1
    git clone -b main --depth 1 https://github.com/crystian/comfyui-crystools.git comfyui-crystools
fi
cd comfyui-crystools
uv pip install -r requirements.txt
popd

# ComfyUI-Autocomplete-Plus ノードをインストール
pushd "${WORKSPACE}/data/comfyui/custom_nodes"
if [ ! -d "comfyui-autocomplete-plus" ] || [ "${FORCE_UPGRADE_CUSTOM_NODES:-'false'}" = "true" ] ; then
    echo "Installing/upgrading ComfyUI-Autocomplete-Plus..."
    rm -rf comfyui-autocomplete-plus >/dev/null 2>&1
    git clone -b main --depth 1 https://github.com/newtextdoc1111/ComfyUI-Autocomplete-Plus.git comfyui-autocomplete-plus
fi
popd

# matrix-nio をインストール(ComfyUI-Manager 用)
uv pip install matrix-nio

# pynvml を nvidia-ml-py に置き換え
uv pip uninstall pynvml
uv pip install -U nvidia-ml-py


# --- 5. safetensors の自動ダウンロード機能 ---

# downloader 側で行うので削除

# --- 6. startup.sh があれば実行 ---
if [ -f "${WORKSPACE}/comfyui/startup.sh" ]; then
    pushd ${WORKSPACE}/comfyui
    . ${WORKSPACE}/comfyui/startup.sh
    popd
fi

# --- 7. コマンド実行 ---
pushd ${COMFYUI_DIR}
if [ ${NUMBER_OF_GPUS:-1} -gt 1 ]; then
    echo "***** Starting ${NUMBER_OF_GPUS} ComfyUI processes *****"
    LISTEN_PORT=${LISTEN_PORT:-8188}
    for ((idx=0; idx<${NUMBER_OF_GPUS}; idx++)); do
        CURRENT_PORT=$(($LISTEN_PORT + $idx))
        echo "***** Starting ComfyUI process $(($idx+1))/${NUMBER_OF_GPUS} on port ${CURRENT_PORT} with GPU ${idx} *****"
        CUDA_VISIBLE_DEVICES=${idx} python3 -u main.py --listen 0.0.0.0 --port ${CURRENT_PORT} ${CLI_ARGS} &
    done
else
    echo "***** Starting ComfyUI processes *****"
    python3 -u main.py --listen 0.0.0.0 --port 8188 ${CLI_ARGS} &
fi
popd

wait
