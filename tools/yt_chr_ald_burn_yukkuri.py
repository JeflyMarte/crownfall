#!/usr/bin/env python3
"""chr_ald: 2話者テロップ＋左右ブラー側帯＋BGM混合を焼き込み。"""
from __future__ import annotations

import json
import subprocess
import wave
from pathlib import Path

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
VOICE = ROOT / "docs/devlog/yt_chr_ald/voice"
EXPORT = ROOT / "docs/devlog/yt_chr_ald/export"
CHAR_ZUNDA = ROOT / "docs/devlog/yt_ep01/assets/zundamon/zundamon_stand.png"
CHAR_METAN = ROOT / "docs/devlog/yt_ep01/assets/zundamon/zundamon_alt.png"
BGM = ROOT / "assets/audio/bgm/hub.mp3"
SRC = EXPORT / "crownfall_chr_ald_silent.mp4"
AUDIO = EXPORT / "full_narration.wav"
OUT = EXPORT / "crownfall_chr_ald_yukkuri.mp4"
ASS_PATH = EXPORT / "_tmp_yukkuri.ass"
FONT = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_NAME = "Hiragino Sans"

W, H = 1920, 1080
DIALOG_H = 280
GAME_H = H - DIALOG_H
CHAR_H = 240
WRAP_WIDTH = 24
BGM_VOL = 0.11

# ASS BGR colors: ずんだ緑 / めたんピンク
COL_ZUNDA = "&H0000FF66"
COL_METAN = "&H00C080FF"
NAME_ZUNDA = "初心者・ずんだもん"
NAME_METAN = "上級者・めたん"


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


def speaker_key(cue: dict) -> str:
    sp = str(cue.get("speaker") or "")
    if "めた" in sp:
        return "metan"
    return "zunda"


def build_ass_from_cues(cues: list[dict], plate_cx: int, plate_cy: int, name_y: int) -> str:
    events: list[str] = []
    t = 0.0
    for cue in cues:
        dur = float(cue["duration"])
        key = speaker_key(cue)
        style = "TalkMetan" if key == "metan" else "TalkZunda"
        name = NAME_METAN if key == "metan" else NAME_ZUNDA
        body = wrap_ass(str(cue["text"]))
        if body:
            name_ov = r"{\an5\pos(%d,%d)\bord3\shad0\fs28}" % (plate_cx, name_y)
            body_ov = r"{\an5\pos(%d,%d)\bord4\shad0}" % (plate_cx, plate_cy + 18)
            events.append(
                f"Dialogue: 0,{ass_time(t)},{ass_time(t + dur)},Name,,0,0,0,,{name_ov}{name}"
            )
            events.append(
                f"Dialogue: 0,{ass_time(t)},{ass_time(t + dur)},{style},,0,0,0,,{body_ov}{body}"
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
Style: TalkZunda,{FONT_NAME},44,{COL_ZUNDA},&H000000FF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,4,0,5,0,0,0,1
Style: TalkMetan,{FONT_NAME},44,{COL_METAN},&H000000FF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,4,0,5,0,0,0,1
Style: Name,{FONT_NAME},28,&H00E8E8E8,&H000000FF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,3,0,5,0,0,0,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    return header + "\n".join(events) + "\n"


def main() -> int:
    for p in (SRC, AUDIO, CHAR_ZUNDA, CHAR_METAN, BGM):
        if not p.exists():
            raise SystemExit(f"missing {p}")

    man = json.loads((VOICE / "manifest.json").read_text(encoding="utf-8"))
    cues = man.get("cues") or []
    if not cues:
        raise SystemExit("no cues in manifest")

    EXPORT.mkdir(parents=True, exist_ok=True)
    pad = 18
    inner_y = GAME_H + pad
    inner_h = DIALOG_H - pad * 2
    char_y = GAME_H + max(8, (DIALOG_H - CHAR_H) // 2)
    # 中央ネームプレート（左右に立ち絵）
    plate_x = 280
    plate_w = W - pad - plate_x - 240
    plate_cx = plate_x + plate_w // 2
    plate_cy = GAME_H + DIALOG_H // 2
    name_y = GAME_H + 42

    ASS_PATH.write_text(
        build_ass_from_cues(cues, plate_cx, plate_cy, name_y), encoding="utf-8"
    )
    cue_total = sum(float(c["duration"]) for c in cues)
    audio_dur = wav_duration(AUDIO)
    print(f"cues={len(cues)} cue_total={cue_total:.2f}s audio={audio_dur:.2f}s")

    ff = ffmpeg_bin()
    ass_esc = str(ASS_PATH.resolve()).replace("\\", "/").replace(":", "\\:")
    fonts_dir = str(Path(FONT).parent.resolve()).replace("\\", "/").replace(":", "\\:")

    # 左右はゲーム映像のブラー拡大。中央にシャープな縦画面。
    # 入力: 0=silent映像, 1=ずんだ, 2=めたんalt, 3=ナレ, 4=BGM
    fc = (
        f"[0:v]split=2[src][srcb];"
        f"[srcb]scale={W}:{GAME_H}:force_original_aspect_ratio=increase,"
        f"crop={W}:{GAME_H},gblur=sigma=24,eq=brightness=-0.10:saturation=0.85[bg];"
        f"[src]scale=-2:{GAME_H}:force_original_aspect_ratio=decrease[fg];"
        f"[bg][fg]overlay=(W-overlay_w)/2:0[game];"
        f"[game]pad={W}:{H}:0:0:black,"
        f"drawbox=x=0:y={GAME_H}:w={W}:h={DIALOG_H}:color=0x0a0a0a:t=fill,"
        f"drawbox=x={pad}:y={inner_y}:w={W - pad * 2}:h={inner_h}:color=0x101010:t=fill,"
        f"drawbox=x={plate_x}:y={inner_y}:w={plate_w}:h={inner_h}:color=black:t=fill,"
        f"drawbox=x={pad}:y={inner_y}:w={W - pad * 2}:h={inner_h}:color=white@0.45:t=2,"
        f"format=yuv420p[base];"
        f"[1:v]scale=-1:{CHAR_H},format=rgba[ch_l];"
        f"[2:v]scale=-1:{CHAR_H},format=rgba[ch_r];"
        f"[base][ch_l]overlay=x=40:y={char_y}:format=auto[mid];"
        f"[mid][ch_r]overlay=x={W - 40 - 180}:y={char_y}:format=auto[vo];"
        f"[vo]ass='{ass_esc}':fontsdir='{fonts_dir}'[v];"
        f"[3:a]volume=1.0[voice];"
        f"[4:a]volume={BGM_VOL}[bgm];"
        f"[voice][bgm]amix=inputs=2:duration=first:dropout_transition=2[a]"
    )
    cmd = [
        ff, "-y", "-hide_banner", "-loglevel", "error",
        "-i", str(SRC),
        "-i", str(CHAR_ZUNDA),
        "-i", str(CHAR_METAN),
        "-i", str(AUDIO),
        "-stream_loop", "-1", "-i", str(BGM),
        "-filter_complex", fc,
        "-map", "[v]",
        "-map", "[a]",
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "medium", "-crf", "20",
        "-c:a", "aac", "-b:a", "192k",
        "-shortest",
        "-movflags", "+faststart",
        str(OUT),
    ]
    print("burning dialogue + side blur + BGM...")
    subprocess.run(cmd, check=True)
    print(f"DONE → {OUT} ({OUT.stat().st_size / 1e6:.1f} MB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
