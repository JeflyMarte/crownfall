#!/usr/bin/env python3
"""かけあい台本（話者: 文）→ 文単位 WAV + manifest。

使い方:
  python3 tools/voicevox_dialogue_synth.py \\
    --script docs/devlog/youtube_chr_ald_script.md \\
    --out docs/devlog/yt_chr_ald/voice
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import wave
from pathlib import Path

DEFAULT_HOST = "http://127.0.0.1:50021"
SECTION_RE = re.compile(r"^##\s+\[([^\]]+)\]\s*(.*)$")
READ_HEADER = re.compile(r"^###\s*(読み上げ|ナレ|ゆかり|ゆっくり)\s*$")
# 「ずんだもん: 文」「めたん：文」
LINE_RE = re.compile(r"^(ずんだもん|めたん|四国めたん)\s*[:：]\s*(.+)$")

SPEAKER_IDS = {
    "ずんだもん": 3,
    "めたん": 2,
    "四国めたん": 2,
}
SPEAKER_LABEL = {
    "ずんだもん": "初心者",
    "めたん": "上級者",
    "四国めたん": "上級者",
}


def check_engine(host: str) -> None:
    try:
        with urllib.request.urlopen(f"{host}/version", timeout=3) as res:
            print(f"VOICEVOX Engine OK: {res.read().decode('utf-8', errors='replace')}")
    except Exception as e:
        print(f"VOICEVOX に接続できません: {e}", file=sys.stderr)
        sys.exit(1)


def parse_script(text: str) -> list[dict]:
    lines = text.splitlines()
    sections: list[dict] = []
    i = 0
    while i < len(lines):
        m = SECTION_RE.match(lines[i].strip())
        if not m:
            i += 1
            continue
        timing, title = m.group(1).strip(), (m.group(2) or "").strip() or m.group(1).strip()
        i += 1
        utterances: list[dict] = []
        in_read = False
        while i < len(lines) and not lines[i].startswith("## "):
            s = lines[i].rstrip()
            if READ_HEADER.match(s.strip()):
                in_read = True
                i += 1
                continue
            if s.strip().startswith("### "):
                in_read = False
                i += 1
                continue
            if in_read and s.strip() and not s.strip().startswith(">"):
                lm = LINE_RE.match(s.strip())
                if lm:
                    who, body = lm.group(1), lm.group(2).strip()
                    if body and body not in ("---", "***"):
                        utterances.append({"speaker": who, "text": body})
            i += 1
        if utterances:
            sections.append({"timing": timing, "title": title, "utterances": utterances})
    return sections


def synthesize(host: str, text: str, speaker: int, speed: float) -> bytes:
    q = urllib.parse.urlencode({"text": text, "speaker": speaker})
    req = urllib.request.Request(
        f"{host}/audio_query?{q}",
        method="POST",
        data=b"",
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=120) as res:
        query = json.loads(res.read().decode("utf-8"))
    query["speedScale"] = float(speed)
    data = json.dumps(query).encode("utf-8")
    req2 = urllib.request.Request(
        f"{host}/synthesis?speaker={speaker}",
        method="POST",
        data=data,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req2, timeout=300) as res:
        return res.read()


def wav_duration_bytes(data: bytes) -> float:
    import io

    with wave.open(io.BytesIO(data), "rb") as w:
        return w.getnframes() / float(w.getframerate())


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--script", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--speed", type=float, default=1.05, help="会話テンポ用。既定1.05")
    ap.add_argument("--host", default=DEFAULT_HOST)
    args = ap.parse_args()

    check_engine(args.host)
    sections = parse_script(args.script.read_text(encoding="utf-8"))
    if not sections:
        print("読み上げ（話者: 文）が見つかりません", file=sys.stderr)
        return 1

    args.out.mkdir(parents=True, exist_ok=True)
    sent_dir = args.out / "sentences"
    if sent_dir.exists():
        for p in sent_dir.glob("*.wav"):
            p.unlink()
    sent_dir.mkdir(parents=True, exist_ok=True)

    manifest: dict = {
        "speed": args.speed,
        "speakers": SPEAKER_IDS,
        "sections": [],
        "cues": [],
    }
    cue_i = 0
    total = 0.0

    for sec_i, sec in enumerate(sections, start=1):
        print(f"[{sec_i}/{len(sections)}] {sec['title']} ({len(sec['utterances'])}発話)")
        sec_cues: list[dict] = []
        for u_i, u in enumerate(sec["utterances"], start=1):
            who = u["speaker"]
            text = u["text"]
            sid = SPEAKER_IDS.get(who)
            if sid is None:
                print(f"unknown speaker: {who}", file=sys.stderr)
                return 1
            cue_i += 1
            name = f"{cue_i:03d}_{sec_i:02d}_{u_i:02d}_{who}.wav"
            path = sent_dir / name
            try:
                wav = synthesize(args.host, text, sid, args.speed)
            except urllib.error.HTTPError as e:
                print(f"HTTP error: {text[:40]}… {e}", file=sys.stderr)
                return 1
            path.write_bytes(wav)
            dur = wav_duration_bytes(wav)
            total += dur
            cue = {
                "index": cue_i,
                "section": sec_i,
                "section_title": sec["title"],
                "speaker": who,
                "speaker_id": sid,
                "role": SPEAKER_LABEL.get(who, who),
                "file": f"sentences/{name}",
                "text": text,
                "duration": round(dur, 3),
            }
            manifest["cues"].append(cue)
            sec_cues.append(cue)
            print(f"  ({u_i}) {who} {dur:5.2f}s  {text[:40]}")
        manifest["sections"].append(
            {
                "index": sec_i,
                "timing": sec["timing"],
                "title": sec["title"],
                "cues": sec_cues,
            }
        )

    (args.out / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Done: {cue_i} cues / {total:.1f}s → {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
