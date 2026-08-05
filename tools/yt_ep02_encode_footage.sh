#!/usr/bin/env bash
# yt_ep02 フレーム連番 → mp4 クリップ（30fps）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRAMES="$ROOT/docs/devlog/yt_ep02/footage/frames"
OUT="$ROOT/docs/devlog/yt_ep02/footage"
FPS=30

FFMPEG_BIN="$(command -v ffmpeg || true)"
if [[ -z "$FFMPEG_BIN" ]]; then
  FFMPEG_BIN="$(python3 -c 'import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())' 2>/dev/null || true)"
fi
if [[ -z "$FFMPEG_BIN" || ! -x "$FFMPEG_BIN" ]]; then
  echo "ffmpeg not found (install ffmpeg or imageio-ffmpeg)" >&2
  exit 1
fi
ffmpeg() { "$FFMPEG_BIN" "$@"; }

mkdir -p "$OUT"
for clip in A_hub B_day_loop C_battle D_rarity E_uniques F_result_clear G_result_wipe H_forge I_hub_close; do
  dir="$FRAMES/$clip"
  if [[ ! -d "$dir" ]] || ! ls "$dir"/*.jpg >/dev/null 2>&1; then
    echo "skip (no frames): $clip"
    continue
  fi
  dest="$OUT/${clip}.mp4"
  echo "encode $clip -> $dest"
  ffmpeg -y -hide_banner -loglevel error \
    -framerate "$FPS" -i "$dir/%04d.jpg" \
    -c:v libx264 -pix_fmt yuv420p -crf 20 -r "$FPS" \
    "$dest"
  ls -lh "$dest"
done
echo "done"
