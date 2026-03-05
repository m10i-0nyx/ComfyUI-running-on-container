# ComfyUI running on container

このリポジトリは、Linux コンテナ上で [ComfyUI](https://github.com/comfyanonymous/ComfyUI) を実行するためのセットアップを提供します。Podman/Docker を使用して、ComfyUI を簡単にセットアップ・実行できます。

## 概要

ComfyUI は、ノードベースの UI を備えた、強力なテキスト・画像生成 AI フレームワークです。本リポジトリは、ComfyUI をコンテナ化して実行するための環境構築スクリプトと設定ファイルを提供します。

### 特徴

- **コンテナベースの環境**：Docker/Podman を使用した再現性のある環境構築
- **NVIDIA GPU サポート**：NVIDIA GPU による高速な推論実行
- **モデルダウンロード機能**：複数の事前学習済みモデル（Wan2.2、FLUX.2、LTX-2 など）を自動ダウンロード可能
- **プレビューギャラリー機能**：生成結果を Web UI で確認可能
- **柔軟な設定**：env ファイルで簡単にカスタマイズ可能

## 必要な要件

### システム要件

- **OS**：Linux（推奨：Fedora 43+）、または Windows 上の WSL2 + Fedora
- **CPU**：4 コア以上（推奨：AMD Ryzen 7 以上）
- **メモリ**：32GB 以上（推奨：64GB）
- **GPU**：NVIDIA GPU（CUDA 対応、推奨：12GB VRAM 以上）
- **ディスク容量**：200GB 以上（モデルファイル用）

### ソフトウェア要件

- **Podman** または **Docker**：コンテナ実行環境
- **NVIDIA Container Toolkit**：GPU サポート
- **Bash**：スクリプト実行用

### 開発環境例

```
OS: Windows 11 Pro 25H2 + WSL2 Fedora 43
CPU: AMD Ryzen 7 9700X
Memory: 64GB DDR5
GPU: NVIDIA GeForce RTX 3060 12GB
```

## インストール方法

### 1. リポジトリのクローン

```bash
git clone https://github.com/h-mineta/comfyui-running-on-container.git
cd comfyui-running-on-container
```

### 2. 環境設定ファイルの作成

```bash
cp env.sample env
```

env ファイルを編集して、必要な設定を行います：

```bash
# ComfyUI バージョン（デフォルト：最新）
COMFYUI_TAG=v0.16.0

# プレビューギャラリーの有効化（デフォルト：false）
ENABLED_COMFYUI_PREVIEW_GALLERY="true"

# モデルダウンロード設定（デフォルト：false）
ENABLED_WAN2_MODELS_DOWNLOAD="false"
ENABLED_FLUX2_MODELS_DOWNLOAD="false"
ENABLED_LTX2_MODELS_DOWNLOAD="false"
ENABLED_QWENImage_MODELS_DOWNLOAD="false"
```

### 3. Podman/Docker のセットアップ（Fedora の場合）

詳細は [README.fedora.md](README.fedora.md) を参照してください。

```bash
# Fedora パッケージのアップグレード
sudo dnf -y upgrade

# NVIDIA コンテナツールキットのインストール
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

# Podman のインストール
sudo dnf install -y podman nvidia-container-toolkit
```

### 4. ComfyUI コンテナのビルド

```bash
./build.sh
```

このスクリプトは、env ファイルで指定されたバージョンの ComfyUI をビルドします。

## 使用方法

### ComfyUI の起動

```bash
./start_comfyui.sh
```

オプション引数：

```bash
# FP16 精度を強制する
./start_comfyui.sh --force-fp16

# FP32 精度を強制する
./start_comfyui.sh --force-fp32
```

起動後、Web UI は以下の URL でアクセス可能です：

- **ComfyUI Web UI**：`http://localhost:8188`
- **プレビューギャラリー**（有効な場合）：`http://localhost:8188/preview`

### ComfyUI の停止

```bash
./stop_comfyui.sh
```

### モデルのダウンロード

```bash
./download_models.sh
```

env ファイルの設定に応じて、指定されたモデルが自動的にダウンロードされます。

## ファイル構成

```
comfyui-running-on-container/
├── build.sh                          # ComfyUI コンテナビルドスクリプト
├── start_comfyui.sh                  # ComfyUI 起動スクリプト
├── stop_comfyui.sh                   # ComfyUI 停止スクリプト
├── download_models.sh                # モデルダウンロードスクリプト
├── env                               # 環境変数設定ファイル（カスタマイズ用）
├── env.sample                        # env ファイルのテンプレート
├── LICENSE                           # MIT ライセンス
├── README.md                         # このファイル
├── README.fedora.md                  # Fedora セットアップガイド
├── services/
│   ├── comfyui/                      # ComfyUI コンテナ設定
│   │   ├── Containerfile             # ComfyUI コンテナイメージ定義
│   │   ├── entrypoint.sh             # 起動時初期化スクリプト
│   │   ├── extra_model_paths.yaml    # カスタムモデルパス設定
│   │   └── preview_gallary.py        # プレビューギャラリー実装
│   └── downloader/                   # モデルダウンロードコンテナ設定
│       ├── Containerfile             # ダウンローダーコンテナイメージ定義
│       ├── entrypoint.sh             # ダウンロード実行スクリプト
│       └── preset_lists/             # ダウンロード対象モデルリスト
│           ├── download_flux2.txt
│           ├── download_ltx2.txt
│           ├── download_ltx2fp8.txt
│           ├── download_qwenimage.txt
│           └── download_wan2.txt
├── tools/
│   └── convert_ckpt2safetensors.py   # モデル形式変換ツール
├── data/                             # ダウンロード済みモデル・キャッシュ（.gitignore）
└── output/                           # 生成される画像出力（.gitignore）
```

## 技術スタック

| コンポーネント | 技術 |
|---|---|
| **ベース OS** | Ubuntu 24.04 |
| **Python** | Python 3.13 |
| **パッケージマネージャー** | uv (Astral) |
| **GPU サポート** | CUDA 13.0 + cuDNN |
| **Deep Learning Framework** | PyTorch 2.10.0+ |
| **コンテナ技術** | Podman / Docker |
| **ComfyUI** | v0.16.0+ |

## 実装概要

### コンテナアーキテクチャ

1. **ComfyUI コンテナ**：
   - 基盤：Ubuntu 24.04
   - Python 3.13 + 仮想環境
   - PyTorch と必要な依存関係をインストール
   - ComfyUI とそのマネージャーを初期化
   - NVIDIA GPU のサポート

2. **ダウンローダーコンテナ**：
   - モデルのダウンロード用の独立したコンテナ
   - Aria2 による並列ダウンロード
   - host マシンとの data ディレクトリ共有

### ボリュームマウント構成

| コンテナパス | ホストパス | 用途 |
|---|---|---|
| `/workspace/data` | `./data` | モデル・キャッシュ共有 |
| `/comfyui/input` | `./data/input` | 入力画像 |
| `/comfyui/output` | `./output` | 生成出力画像 |

## カスタマイズ

### 環境変数の設定

`env` ファイルで以下をカスタマイズできます：

```bash
# ComfyUI バージョン指定
COMFYUI_TAG=v0.16.0

# プレビューギャラリーの有効化
ENABLED_COMFYUI_PREVIEW_GALLERY="true"

# 各モデル系のダウンロード有効化
ENABLED_WAN2_MODELS_DOWNLOAD="false"
ENABLED_FLUX2_MODELS_DOWNLOAD="false"
ENABLED_LTX2_MODELS_DOWNLOAD="false"
ENABLED_LTX2FP8_MODELS_DOWNLOAD="false"
ENABLED_QWENIMAGE_MODELS_DOWNLOAD="false"
```

### モデルパスの拡張

`services/comfyui/extra_model_paths.yaml` を編集することで、カスタムモデルのパスを追加できます。

## トラブルシューティング

### CUDA が認識されない場合

1. NVIDIA ドライバのインストール状態確認：
```bash
nvidia-smi
```

2. NVIDIA Container Toolkit のインストール確認：
```bash
podman run --rm --runtime=nvidia ubuntu nvidia-smi
```

### メモリ不足エラー

- `env` ファイルで `--force-fp16` を使用してメモリ使用量を削減してください
- WSL2 の場合、`.wslconfig` でメモリ割り当てを増加してください

## ライセンス

このプロジェクトは [MIT ライセンス](LICENSE) の下で公開されています。

## 作者

**MINETA "m10i" Hiroki**

## 謝辞

Special thanks to everyone behind these awesome projects, without them, none of this would have been possible:

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- [Astral - uv](https://astral.sh/uv)
- [Podman](https://podman.io/)
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit)
