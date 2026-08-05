#!/usr/bin/env python3
"""ep02: 16:9横＋下バナー＋文単位同期テロップを焼き込み。"""
from __future__ import annotations

import json
import subprocess
import wave
from pathlib import Path

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
VOICE = ROOT / "docs/devlog/yt_ep02/voice"
EXPORT = ROOT / "docs/devlog/yt_ep02/export"
CHAR = ROOT / "docs/devlog/yt_ep01/assets/zundamon/zundamon_stand.png"
SRC = EXPORT / "crownfall_ep02_silent.mp4"
AUDIO = EXPORT / "full_narration.wav"
OUT = EXPORT / "crownfall_ep02_yukkuri.mp4"
ASS_PATH = EXPORT / "_tmp_yukkuri.ass"
FONT = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_NAME = "Hiragino Sans"

W, H = 1920, 1080
DIALOG_H = 280
GAME_H = H - DIALOG_H
CHAR_H = 250
WRAP_WIDTH = 26


def ffmpeg_bin() -> str:
    return imageio_ffmpeg.get_ffmpeg_exe()


def wav_duration(path: Path) -> float:
    with wave.open(str(path), "rb") as w:
        return w.getnframes() / float(w.getframerate())


def ass_time(sec: float) -> str:
    if sec < 0:
        sec = 0
    h = int(sec // 3600)
    m = int((sec % 3600) // 60)
    s = int(sec % 60)
    cs = int(round((sec - int(sec)) * 100))
    if cs >= 100:
        s += 1
        cs = 0
    return f"{h}:{m:02d}:{s:02d}.{cs:02d}"


def wrap_ass(text: str, max_chars: int = WRAP_WIDTH) -> str:
    text = text.replace("---", "").strip()
    if not text:
        return ""
    lines: list[str] = []
    buf = ""
    for ch in text:
        buf += ch
        at_break = ch in "、。！？　 "
        if len(buf) >= max_chars and at_break:
            lines.append(buf.strip())
            buf = ""
        elif len(buf) >= max_chars + 8:
            cut = max(buf.rfind("、"), buf.rfind("。"), buf.rfind("　"))
            if cut >= max_chars // 2:
                lines.append(buf[: cut + 1].strip())
                buf = buf[cut + 1 :]
            else:
                lines.append(buf.strip())
                buf = ""
    if buf.strip():
        lines.append(buf.strip())
    return "\\N".join(lines[:3])


def build_ass_from_cues(cues: list[dict], pos_x: int, pos_y: int) -> str:
    events: list[str] = []
    t = 0.0
    for cue in cues:
        dur = float(cue["duration"])
        body = wrap_ass(str(cue["text"]))
        if body:
            override = r"{\an5\pos(%d,%d)\bord4\shad0}" % (pos_x, pos_y)
            events.append(
                f"Dialogue: 0,{ass_time(t)},{ass_time(t + dur)},Talk,,0,0,0,,{override}{body}"
            )
        t += dur

    header = f"""[Script Info]
ScriptType: v4.00+
PlayResX: {W}
PlayResY: {H}
WrapStyle: 0
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Talk,{FONT_NAME},46,&H0000FF66,&H000000FF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,4,0,5,0,0,0,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    return header + "\n".join(events) + "\n"


def main() -> int:
    if not SRC.exists():
        raise SystemExit(f"missing {SRC} — run yt_ep02_assemble.py first")
    if not AUDIO.exists():
        raise SystemExit(f"missing {AUDIO}")
    if not CHAR.exists():
        raise SystemExit(f"missing {CHAR}")

    man = json.loads((VOICE / "manifest.json").read_text(encoding="utf-8"))
    cues = man.get("cues") or []
    if not cues:
        raise SystemExit("no cues in manifest")

    EXPORT.mkdir(parents=True, exist_ok=True)
    pad = 18
    inner_y = GAME_H + pad
    inner_h = DIALOG_H - pad * 2
    char_y = GAME_H + max(10, (DIALOG_H - CHAR_H) // 2)
    plate_x = 300
    plate_w = W - pad - plate_x
    plate_cx = plate_x + plate_w // 2
    plate_cy = GAME_H + DIALOG_H // 2

    ASS_PATH.write_text(build_ass_from_cues(cues, plate_cx, plate_cy), encoding="utf-8")
    cue_total = sum(float(c["duration"]) for c in cues)
    audio_dur = wav_duration(AUDIO)
    print(f"cues={len(cues)} cue_total={cue_total:.2f}s audio={audio_dur:.2f}s")

    ff = ffmpeg_bin()
    ass_esc = str(ASS_PATH.resolve()).replace("\\", "/").replace(":", "\\:")
    fonts_dir = str(Path(FONT).parent.resolve()).replace("\\", "/").replace(":", "\\:")
    fc = (
        f"[0:v]scale=-2:{GAME_H}:force_original_aspect_ratio=decrease,"
        f"pad={W}:{H}:(ow-iw)/2:0:black,"
        f"drawbox=x=0:y={GAME_H}:w={W}:h={DIALOG_H}:color=0x0a0a0a:t=fill,"
        f"drawbox=x={pad}:y={inner_y}:w={W - pad * 2}:h={inner_h}:color=0x101010:t=fill,"
        f"drawbox=x={plate_x}:y={inner_y}:w={plate_w}:h={inner_h}:color=black:t=fill,"
        f"drawbox=x={pad}:y={inner_y}:w={W - pad * 2}:h={inner_h}:color=white@0.55:t=3,"
        f"format=yuv420p[base];"
        f"[1:v]scale=-1:{CHAR_H},format=rgba[ch];"
        f"[base][ch]overlay=x=56:y={char_y}:format=auto[vo];"
        f"[vo]ass='{ass_esc}':fontsdir='{fonts_dir}'[v]"
    )
    cmd = [
        ff, "-y", "-hide_banner", "-loglevel", "error",
        "-i", str(SRC),
        "-i", str(CHAR),
        "-i", str(AUDIO),
        "-filter_complex", fc,
        "-map", "[v]",
        "-map", "2:a",
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "medium", "-crf", "20",
        "-c:a", "aac", "-b:a", "192k",
        "-shortest",
        "-movflags", "+faststart",
        str(OUT),
    ]
    print("burning landscape + synced teleops...")
    subprocess.run(cmd, check=True)
    print(f"DONE → {OUT} ({OUT.stat().st_size / 1e6:.1f} MB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
