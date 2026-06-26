#!/usr/bin/env python3
"""Crownfall sprite-sheet merger (macOS / cross-platform).

PixelLab などで書き出した個別フレーム PNG を、ゲーム規格の
「横1列・等間隔・余白ゼロ・透過」スプライトシートに結合する。

規格: docs/art/Sprite_Production_Spec.md (P3-D039 / P3-D039a)
  通常キャラ/敵=96, エリート=128, ボス=192
  コマ順 idle x4 / attack x4 / hurt x2 / death x4 = 14 コマ

フレームはファイル名の昇順に並ぶ。並び順がコマ順になるよう
  01_idle1.png ... 04_idle4.png / 05_atk1.png ... 08_atk4.png /
  09_hurt1.png 10_hurt2.png / 11_death1.png ... 14_death4.png
のように 0 埋め連番で名前を付けること。

使い方:
  python3 tools/merge_sprite_sheet.py \
      --cell 96 --input ./frames \
      --output ./ENM_CrystalHedgehog_Sheet.png

オプション:
  --cell N        セル(1コマ)の正方ピクセル数 (96/128/192 等)
  --per-row N     1行あたりのコマ数 (既定 14 = 横1列)
  --fit {crop,contain}
                  crop=中央切り抜き(既定) / contain=縦横比維持で内接縮小
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow が必要です: pip3 install Pillow")

EXTS = {".png", ".webp", ".gif", ".bmp", ".jpg", ".jpeg"}


def load_frames(folder: Path) -> list[Path]:
    files = sorted(p for p in folder.iterdir() if p.suffix.lower() in EXTS)
    if not files:
        sys.exit(f"フレーム画像が見つかりません: {folder}")
    return files


def fit_cell(img: Image.Image, cell: int, mode: str) -> Image.Image:
    img = img.convert("RGBA")
    canvas = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
    if mode == "contain":
        scale = min(cell / img.width, cell / img.height)
        new_size = (max(1, round(img.width * scale)), max(1, round(img.height * scale)))
        img = img.resize(new_size, Image.NEAREST)
    # 中央配置 (大きければ中央切り抜き / 小さければ中央パディング)
    ox = (cell - img.width) // 2
    oy = (cell - img.height) // 2
    canvas.alpha_composite(img, (max(0, ox), max(0, oy)),
                           (max(0, -ox), max(0, -oy),
                            max(0, -ox) + min(cell, img.width),
                            max(0, -oy) + min(cell, img.height)))
    return canvas


def main() -> None:
    ap = argparse.ArgumentParser(description="Crownfall sprite sheet merger")
    ap.add_argument("--cell", type=int, required=True, help="1コマの正方サイズ (96/128/192)")
    ap.add_argument("--input", type=Path, required=True, help="フレーム PNG フォルダ")
    ap.add_argument("--output", type=Path, required=True, help="出力シート PNG")
    ap.add_argument("--per-row", type=int, default=14, help="1行あたりコマ数 (既定14=横1列)")
    ap.add_argument("--fit", choices=["crop", "contain"], default="crop")
    args = ap.parse_args()

    frames = load_frames(args.input)
    n = len(frames)
    if n != 14:
        print(f"[警告] フレーム数が {n} 枚です（規格は idle4/attack4/hurt2/death4 = 14）。"
              f" 並び順がコマ順か確認してください。", file=sys.stderr)

    cols = args.per_row
    rows = (n + cols - 1) // cols
    sheet = Image.new("RGBA", (args.cell * min(n, cols), args.cell * rows), (0, 0, 0, 0))

    for i, fp in enumerate(frames):
        cell_img = fit_cell(Image.open(fp), args.cell, args.fit)
        cx = (i % cols) * args.cell
        cy = (i // cols) * args.cell
        sheet.alpha_composite(cell_img, (cx, cy))
        print(f"  {i + 1:>2}: {fp.name}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.output)
    print(f"\n完成: {args.output}  ({sheet.width}x{sheet.height}, {n}コマ)")


if __name__ == "__main__":
    main()
