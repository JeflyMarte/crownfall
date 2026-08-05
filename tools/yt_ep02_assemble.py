#!/usr/bin/env python3
"""[DEPRECATED] YouTube ep02 旧アセンブラ。

セクション単位でクリップをループ／切断していたため、音声（文単位）と
画面の中身が合わなくなった。本番は使わない。

正: tools/yt_ep02_shot_runner.gd（音声秒数どおりに通し撮り）
    → ffmpeg で silent mp4
    → tools/yt_ep02_burn_yukkuri.py
    詳細は docs/devlog/YOUTUBE_YUKKURI_GUIDE.md
"""
from __future__ import annotations

import json
import subprocess
import wave
from pathlib import Path

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
VOICE = ROOT / "docs/devlog/yt_ep02/voice"
FOOTAGE = ROOT / "docs/devlog/yt_ep02/footage"
EXPORT = ROOT / "docs/devlog/yt_ep02/export"
TMP = EXPORT / "_tmp"
FPS = 30

# セクション番号(1-based) → クリップ配分（台本ブロック順）
SECTION_CLIPS: dict[int, list[tuple[str, float]]] = {
    1: [("A_hub.mp4", 1.0)],  # 前振り
    2: [("B_day_loop.mp4", 1.0)],  # 一日の流れ
    3: [("C_battle.mp4", 1.0)],  # 装備の落ち方
    4: [("D_rarity.mp4", 0.45), ("E_uniques.mp4", 0.55)],  # レア・固有
    5: [("F_result_clear.mp4", 0.72), ("G_result_wipe.mp4", 0.28)],  # 結果
    6: [("H_forge.mp4", 1.0)],  # 鍛冶
    7: [("I_hub_close.mp4", 0.5), ("A_hub.mp4", 0.5)],  # まとめ
    8: [("I_hub_close.mp4", 1.0)],  # 締め
}


def ffmpeg_bin() -> str:
    return imageio_ffmpeg.get_ffmpeg_exe()


def run(cmd: list[str]) -> None:
    print(">", " ".join(str(c) for c in cmd[:10]), "...")
    subprocess.run(cmd, check=True)


def wav_duration(path: Path) -> float:
    with wave.open(str(path), "rb") as w:
        return w.getnframes() / float(w.getframerate())


def concat_wavs(paths: list[Path], out: Path) -> float:
    with wave.open(str(paths[0]), "rb") as first:
        params = first.getparams()
        frames = [first.readframes(first.getnframes())]
    for p in paths[1:]:
        with wave.open(str(p), "rb") as w:
            frames.append(w.readframes(w.getnframes()))
    with wave.open(str(out), "wb") as out_w:
        out_w.setparams(params)
        for fr in frames:
            out_w.writeframes(fr)
    return wav_duration(out)


def make_looped_clip(src: Path, dur: float, out: Path) -> None:
    ff = ffmpeg_bin()
    run([
        ff, "-y", "-hide_banner", "-loglevel", "error",
        "-stream_loop", "-1", "-i", str(src),
        "-t", f"{dur:.3f}",
        "-vf", f"fps={FPS},format=yuv420p",
        "-an",
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "20",
        str(out),
    ])


def main() -> int:
    man_path = VOICE / "manifest.json"
    if not man_path.exists():
        raise SystemExit(f"missing {man_path} — run voicevox_synth.py first")
    man = json.loads(man_path.read_text(encoding="utf-8"))
    cues = man.get("cues") or []
    if not cues:
        raise SystemExit("manifest has no cues")

    EXPORT.mkdir(parents=True, exist_ok=True)
    if TMP.exists():
        for p in TMP.glob("*"):
            if p.is_file():
                p.unlink()
    TMP.mkdir(parents=True, exist_ok=True)

    wav_paths = [VOICE / c["file"] for c in cues]
    for p in wav_paths:
        if not p.exists():
            raise SystemExit(f"missing wav: {p}")
    full_wav = EXPORT / "full_narration.wav"
    total = concat_wavs(wav_paths, full_wav)
    print(f"audio {total:.1f}s → {full_wav}")

    parts: list[Path] = []
    by_sec: dict[int, list[dict]] = {}
    for c in cues:
        by_sec.setdefault(int(c["section"]), []).append(c)

    for sec_i in sorted(by_sec.keys()):
        sec_cues = by_sec[sec_i]
        sec_dur = sum(float(c["duration"]) for c in sec_cues)
        clip_plan = SECTION_CLIPS.get(sec_i, [("A_hub.mp4", 1.0)])
        resolved: list[tuple[Path, float]] = []
        for name, share in clip_plan:
            p = FOOTAGE / name
            if not p.exists():
                raise SystemExit(f"missing footage: {p}")
            resolved.append((p, share))

        t_acc = 0.0
        sec_parts: list[Path] = []
        for j, (clip, share) in enumerate(resolved):
            d = sec_dur * share if j < len(resolved) - 1 else max(0.1, sec_dur - t_acc)
            t_acc += d
            out = TMP / f"sec{sec_i:02d}_p{j}.mp4"
            make_looped_clip(clip, d, out)
            sec_parts.append(out)

        if len(sec_parts) == 1:
            parts.append(sec_parts[0])
        else:
            lst = TMP / f"sec{sec_i:02d}_list.txt"
            lst.write_text("".join(f"file '{p.resolve()}'\n" for p in sec_parts), encoding="utf-8")
            merged = TMP / f"sec{sec_i:02d}.mp4"
            run([
                ffmpeg_bin(), "-y", "-hide_banner", "-loglevel", "error",
                "-f", "concat", "-safe", "0", "-i", str(lst),
                "-c", "copy",
                str(merged),
            ])
            parts.append(merged)
        print(f"section {sec_i}: {sec_dur:.1f}s")

    final_list = TMP / "video_list.txt"
    final_list.write_text("".join(f"file '{p.resolve()}'\n" for p in parts), encoding="utf-8")
    silent = EXPORT / "crownfall_ep02_silent.mp4"
    run([
        ffmpeg_bin(), "-y", "-hide_banner", "-loglevel", "error",
        "-f", "concat", "-safe", "0", "-i", str(final_list),
        "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p",
        "-r", str(FPS),
        "-an",
        str(silent),
    ])
    print(f"DONE silent → {silent}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
