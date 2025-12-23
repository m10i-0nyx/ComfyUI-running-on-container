import argparse
import os
import torch
from safetensors.torch import save_file


def extract_tensors(obj, prefix=""):
    """
    オブジェクトから再帰的にtorch.Tensorを抽出する関数。
    """
    tensors = {}
    if isinstance(obj, dict):
        for key, value in obj.items():
            full_key = f"{prefix}.{key}" if prefix else key
            tensors.update(extract_tensors(value, full_key))
    elif isinstance(obj, torch.Tensor):
        tensors[prefix] = obj
    # リストやタプルなどの他の型は無視（必要に応じて拡張）
    return tensors


def main():
    parser = argparse.ArgumentParser(
        description="PyTorch の checkpoint (.ckpt) を safetensors 形式に変換します"
    )
    parser.add_argument(
        "input",
        help=".ckpt ファイルのパス",
    )
    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="出力する .safetensors ファイル名（省略時は拡張子だけ .safetensors に変換）",
    )
    parser.add_argument(
        "--delete",
        action="store_true",
        help="変換完了後に元の .ckpt ファイルを削除します",
    )
    args = parser.parse_args()

    in_path = args.input
    out_path = args.output or in_path.rsplit(".", 1)[0] + ".safetensors"

    print(f"[INFO] Loading checkpoint: {in_path}")
    checkpoint = torch.load(in_path, map_location="cpu")

    # デバッグ: checkpointの構造を確認
    print(f"[DEBUG] Checkpoint type: {type(checkpoint)}")
    if isinstance(checkpoint, dict):
        print(f"[DEBUG] Checkpoint keys: {list(checkpoint.keys())}")
        if "state_dict" in checkpoint:
            print(f"[DEBUG] state_dict keys count: {len(checkpoint['state_dict'])}")
        else:
            print("[DEBUG] No 'state_dict' key found.")
    else:
        print(f"[DEBUG] Checkpoint is not a dict, type: {type(checkpoint)}")

    # checkpoint から再帰的に Tensor を抽出
    model_state = extract_tensors(checkpoint)

    # デバッグ: 抽出後のmodel_stateを確認
    print(f"[DEBUG] Extracted model_state keys count: {len(model_state)}")
    if len(model_state) == 0:
        print("[ERROR] No tensors found in model_state. Conversion aborted.")
        return

    print(f"[INFO] Saving as safetensors: {out_path}")
    save_file(model_state, out_path)
    print("[INFO] Done!")

    # --- ファイルサイズの比較 ---
    in_size = os.path.getsize(in_path)
    out_size = os.path.getsize(out_path)
    ratio = out_size / in_size if in_size > 0 else 0

    print(f"[INFO] Input size : {in_size:,} bytes")
    print(f"[INFO] Output size: {out_size:,} bytes")
    print(f"[INFO] Output/Input ratio: {ratio:.2%}")

    # --- 入力ファイルの削除 ---
    if args.delete:
        try:
            os.remove(in_path)
            print(f"[INFO] Deleted input file: {in_path}")
        except OSError as e:
            print(f"[INFO] Failed to delete input file: {e}")


if __name__ == "__main__":
    main()
