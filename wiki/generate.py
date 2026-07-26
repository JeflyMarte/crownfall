#!/usr/bin/env python3
"""Crownfall 攻略Wiki — .tres リソースから Markdown データページを生成する。

ゲーム本体の resources/*.tres を単一の正として読み取り、
wiki/docs/data/ 配下の記事を再生成する。手書きの世界観/攻略ページは対象外。
"""
from __future__ import annotations

import re
import shutil
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
RES = REPO / "resources"
CODEX_ART = REPO / "assets" / "codex" / "enemies"
DOCS = Path(__file__).resolve().parent / "docs"
DATA = DOCS / "data"
ASSETS = DOCS / "assets"

RARITY = {
    0: "コモン",
    1: "レア",
    2: "エピック",
    3: "レジェンダリー",
    4: "神話",
}
RARITY_GEM = {0: "◇", 1: "◈", 2: "✦", 3: "★", 4: "✧"}
ELEMENT = {
    "fire": "炎",
    "ice": "氷",
    "thunder": "電気",
    "dark": "闇",
    "holy": "聖",
    "light": "光",
    "water": "水",
    "wind": "風",
    "earth": "土",
    "": "無",
}
WTYPE = {
    "sword": "剣",
    "greatsword": "剣",  # 旧互換
    "dagger": "短剣",
    "knife": "短刀",
    "dual_blades": "双刃",
    "bow": "弓",
    "staff": "杖",
    "spear": "槍",
    "mace": "鎚",
}
ETYPE = {0: "通常", 1: "エリート", 2: "ボス"}
ROUTE_LABEL = {
    "main": "メイン",
    "event": "イベント",
    "abyss": "深層",
    "side": "寄り道（未解放）",
    "apex": "征討（未解放）",
}
# プレイ公開中のルートのみ詳細掲載。side/apex は一覧で未解放と明示。
PLAYABLE_ROUTES = {"main", "event", "abyss"}

ARR_RE = re.compile(r"Array\[\w+\]\(\[(.*?)\]\)")
STR_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')


def parse_value(raw: str):
    raw = raw.strip()
    m = ARR_RE.match(raw)
    if m:
        return STR_RE.findall(m.group(1))
    if raw.startswith("{") and raw.endswith("}"):
        d = {}
        for k, v in re.findall(r'"([^"]+)"\s*:\s*([0-9.]+)', raw):
            d[k] = float(v)
        return d
    if raw.startswith('"') and raw.endswith('"'):
        return raw[1:-1]
    try:
        return int(raw)
    except ValueError:
        pass
    try:
        return float(raw)
    except ValueError:
        pass
    if raw in ("true", "false"):
        return raw == "true"
    return raw


def parse_tres(path: Path) -> dict:
    data = {}
    in_res = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip() == "[resource]":
            in_res = True
            continue
        if not in_res:
            continue
        if "=" not in line:
            continue
        key, _, val = line.partition("=")
        key = key.strip()
        if key in ("script",):
            continue
        data[key] = parse_value(val)
    return data


def load_dir(name: str) -> list[dict]:
    out = []
    d = RES / name
    if not d.exists():
        return out
    for f in sorted(d.glob("*.tres")):
        out.append(parse_tres(f))
    return out


def rarity_cell(r) -> str:
    r = int(r) if r is not None else 0
    return f"{RARITY_GEM.get(r, '')} {RARITY.get(r, r)}"


def fmt_elements(ids) -> str:
    if not ids:
        return "—"
    return " / ".join(ELEMENT.get(e, e) for e in ids)


def pct(v) -> str:
    if v in (None, ""):
        return "—"
    try:
        return f"{float(v) * 100:.0f}%"
    except (ValueError, TypeError):
        return str(v)


def write(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + "\n", encoding="utf-8")
    print(f"  wrote {path.relative_to(DOCS)}")


def to_pascal(snake: str) -> str:
    return "".join(p.capitalize() for p in snake.split("_"))


def build_monster_art_map() -> dict[str, str]:
    """enemy id → ART_*.png（assets/codex/enemies から自動対応）。"""
    arts = {
        p.stem.replace("ART_ENM_", "").replace("ART_BOSS_", ""): p.name
        for p in CODEX_ART.glob("ART_*.png")
    }
    mapped: dict[str, str] = {}
    for f in sorted((RES / "enemies").glob("*.tres")):
        eid = parse_tres(f).get("id") or f.stem
        pas = to_pascal(eid)
        art = None
        for key in (pas, eid, eid.replace("_", "")):
            if key in arts:
                art = arts[key]
                break
        if not art:
            for k, v in arts.items():
                if k.lower() == pas.lower() or k.lower() == eid.replace("_", "").lower():
                    art = v
                    break
        if art:
            mapped[eid] = art
    return mapped


def gen_monsters(monster_art: dict[str, str], materials):
    enemies = load_dir("enemies")
    mat_by_id = {m["id"]: m for m in materials}
    lines = [
        "# モンスター図鑑",
        "",
        "出現する生物・遺存体の一覧。弱点属性は与ダメージ **×1.25**、耐性属性は **×0.75**（[属性と状態異常](../guide/elements.md)）。",
        "",
        "!!! note \"数値について\"",
        "    表の HP・攻撃はリソース上の基礎値。Hard／Nightmare・深層では敵レベル補正が乗ります。",
        "",
        "| モンスター | 種別 | HP | 攻撃 | 弱点 | 危険度 | 生息地 |",
        "|---|---|---:|---:|---|---|---|",
    ]
    for e in enemies:
        danger = "★" * int(e.get("codex_danger", 0)) or "—"
        lines.append(
            f"| [{e['display_name']}](#{e['id']}) | {ETYPE.get(int(e.get('enemy_type', 0)), '通常')} "
            f"| {e.get('max_hp', '?')} | {e.get('attack', '?')} | {fmt_elements(e.get('element_weakness'))} "
            f"| {danger} | {e.get('codex_habitat', '—')} |"
        )
    lines.append("")
    for e in enemies:
        eid = e["id"]
        lines.append(f"## {e['display_name']} {{#{eid}}}")
        lines.append("")
        art = monster_art.get(eid)
        if art and (ASSETS / "monsters" / art).exists():
            lines.append(
                f'<img src="../../assets/monsters/{art}" alt="{e["display_name"]}" width="280">'
            )
            lines.append("")
        danger = "★" * int(e.get("codex_danger", 0)) or "—"
        lines += [
            "| 項目 | 値 |",
            "|---|---|",
            f"| 種別 | {ETYPE.get(int(e.get('enemy_type', 0)), '通常')} |",
            f"| 分類 | {e.get('codex_class', '—')} |",
            f"| 危険度 | {danger} |",
            f"| HP | {e.get('max_hp', '?')} |",
            f"| 攻撃力 | {e.get('attack', '?')} |",
            f"| 防御力 | {e.get('defense', '?')} |",
            f"| 攻撃速度 | {e.get('attack_speed', '?')} |",
            f"| クリティカル率 | {pct(e.get('critical_rate'))} |",
            f"| 弱点属性 | {fmt_elements(e.get('element_weakness'))} |",
            f"| 耐性属性 | {fmt_elements(e.get('element_resist'))} |",
            f"| 経験値 | {e.get('exp_reward', '?')} |",
            f"| ゴールド | {e.get('gold_reward', '?')} |",
            f"| 生息地 | {e.get('codex_habitat', '—')} |",
        ]
        if e.get("can_swarm"):
            lines.append(f"| 群れ | {e.get('swarm_min', '?')}〜{e.get('swarm_max', '?')} 体 |")
        if e.get("on_hit_status_id"):
            lines.append(
                f"| 被弾時付与 | {e['on_hit_status_id']} ({pct(e.get('on_hit_status_chance'))}) |"
            )
        lines.append("")
        note = e.get("codex_research_note", "")
        if note:
            lines += ["!!! quote \"調査記録\"", "    " + note.replace("\n", "\n    "), ""]
        mats = e.get("codex_materials") or []
        if mats:
            names = []
            for mid in mats:
                m = mat_by_id.get(mid)
                names.append(m["display_name"] if m else mid)
            lines.append(f"**関連素材:** {' / '.join(names)}")
            lines.append("")
    write(DATA / "monsters.md", "\n".join(lines))


def gen_weapons(skills):
    weapons = load_dir("weapons")
    sk = {s["id"]: s["display_name"] for s in skills}
    lines = [
        "# 武器一覧",
        "",
        "ドロップ・鍛冶生産で入手できる武器の基礎値。個体ごとにランダム補正（属性値・特効・会心など）が乗ります（[装備と鍛冶](../guide/equipment.md)）。",
        "",
        "| 武器 | 種別 | レア度 | 攻撃 | 属性 | クリ | 固有スキル | 特効 |",
        "|---|---|---|---:|---|---:|---|---|",
    ]
    for w in weapons:
        skill = sk.get(w.get("fixed_skill_id", ""), w.get("fixed_skill_id", "—") or "—")
        bane = "—"
        if w.get("bane_class"):
            bane = f"{w['bane_class']} ×{w.get('bane_multiplier', '?')}"
        lines.append(
            f"| **{w['display_name']}** | {WTYPE.get(w.get('weapon_type', ''), w.get('weapon_type', '—'))} "
            f"| {rarity_cell(w.get('rarity'))} | {w.get('base_attack', '?')} "
            f"| {ELEMENT.get(w.get('element', ''), '無')} | {pct(w.get('base_critical_rate'))} "
            f"| {skill} | {bane} |"
        )
    lines.append("")
    lines.append(
        "> 職ごとに装備できる武器種が決まっています。攻撃速度は行動順にも影響します（[戦闘の仕組み](../guide/combat.md)）。"
    )
    write(DATA / "weapons.md", "\n".join(lines))


def gen_equipment():
    armors = load_dir("armors")
    accs = load_dir("accessories")
    lines = [
        "# 防具・装飾品",
        "",
        "基礎ステのみ掲載。個体のランダム補正は拾得／生産時に付与されます。",
        "",
        "## 防具",
        "",
        "| 防具 | レア度 | 防御 | HP+ | 重量 |",
        "|---|---|---:|---:|---:|",
    ]
    for a in armors:
        lines.append(
            f"| **{a['display_name']}** | {rarity_cell(a.get('rarity'))} | {a.get('base_defense', '?')} "
            f"| {a.get('base_hp_bonus', '?')} | {a.get('weight', '?')} |"
        )
    lines += [
        "",
        "## 装飾品",
        "",
        "| 装飾品 | レア度 | 効果 | 説明 |",
        "|---|---|---|---|",
    ]
    for a in accs:
        eff = []
        if a.get("hp_bonus"):
            eff.append(f"HP+{a['hp_bonus']}")
        if a.get("attack_bonus"):
            eff.append(f"攻撃+{a['attack_bonus']}")
        if a.get("defense_bonus"):
            eff.append(f"防御+{a['defense_bonus']}")
        if a.get("crit_rate_bonus"):
            eff.append(f"クリ+{pct(a['crit_rate_bonus'])}")
        lines.append(
            f"| **{a['display_name']}** | {rarity_cell(a.get('rarity'))} | {' / '.join(eff) or '—'} "
            f"| {a.get('description', '')} |"
        )
    write(DATA / "equipment.md", "\n".join(lines))


def gen_jobs(skills):
    jobs = load_dir("jobs")
    sk = {s["id"]: s["display_name"] for s in skills}
    lines = [
        "# ジョブ",
        "",
        "探索隊メンバーの職能。**装備できる武器種**と習得スキルが異なります。一定レベルで上位職へ進化します。",
        "",
    ]
    for j in jobs:
        lines.append(f"## {j['display_name']}")
        lines.append("")
        lines.append(f"*{j.get('description', '')}*")
        lines.append("")
        learn = " / ".join(sk.get(s, s) for s in (j.get("learnable_skill_ids") or []))
        start = " / ".join(sk.get(s, s) for s in (j.get("starting_skill_ids") or []))
        pref = " / ".join(WTYPE.get(t, t) for t in (j.get("preferred_weapon_types") or []))
        lines += [
            "| 項目 | 内容 |",
            "|---|---|",
            f"| 役割 | {j.get('role', '—')} |",
            f"| 装備可能武器 | {pref or '—'} |",
            f"| 初期スキル | {start or '—'} |",
            f"| 習得スキル | {learn or '—'} |",
            f"| 進化先 | {j.get('evolved_display_name', '—')}（Lv{j.get('evolution_level', '?')}）|",
            "",
        ]
    write(DATA / "jobs.md", "\n".join(lines))


def gen_skills():
    skills = load_dir("skills")
    lines = [
        "# スキル一覧",
        "",
        "| スキル | 種別 | 効果 | 倍率 | 属性 | CD | 付与状態 |",
        "|---|---|---|---:|---|---:|---|",
    ]
    for s in skills:
        st = s.get("apply_status_id", "")
        st_txt = f"{st} ({pct(s.get('apply_status_chance'))})" if st else "—"
        lines.append(
            f"| **{s['display_name']}** | {s.get('skill_type', '—')} | {s.get('effect_type', '—')} "
            f"| {s.get('power_multiplier', '—')} | {ELEMENT.get(s.get('element', ''), '継承')} "
            f"| {s.get('cooldown', '—')} | {st_txt} |"
        )
    write(DATA / "skills.md", "\n".join(lines))


def gen_dungeons():
    dungeons = load_dir("dungeons")
    enemies = {e["id"]: e for e in load_dir("enemies")}
    lines = [
        "# ダンジョンデータ",
        "",
        "リソース上の基礎値。メインは各 Biome が **5章**（×-1〜×-5）に分かれ、ボスは原則 **×-5** のみ出現します。",
        "",
        "!!! warning \"未解放コンテンツ\"",
        "    **寄り道**・**征討**はデータのみ残置で、現行バージョンでは選択できません。",
        "",
    ]

    order = ["main", "event", "abyss", "side", "apex"]
    # プレイヤー向けの進行・曜日順（残りは id 昇順）
    sort_keys = {
        "main": {
            "mourngate": 0,
            "whisperwood": 1,
            "mistfen": 2,
            "blackshore": 3,
            "frostridge": 4,
        },
        "event": {
            "cosmic_rift": 0,
            "crown_rookery": 1,
            "golden_nest": 2,
            "shadow_hunt": 3,
            "rock_stampede": 4,
        },
        "abyss": {
            "abyss_mourngate": 0,
            "abyss_whisperwood": 1,
            "abyss_mistfen": 2,
            "abyss_blackshore": 3,
            "abyss_frostridge": 4,
        },
    }
    by_route: dict[str, list] = {k: [] for k in order}
    for d in dungeons:
        rt = d.get("route_type", "main") or "main"
        by_route.setdefault(rt, []).append(d)

    for rt in order:
        group = by_route.get(rt) or []
        if not group:
            continue
        key_map = sort_keys.get(rt, {})
        group = sorted(group, key=lambda d: (key_map.get(d.get("id", ""), 99), d.get("id", "")))
        lines += [f"## {ROUTE_LABEL.get(rt, rt)}", ""]
        if rt not in PLAYABLE_ROUTES:
            lines += [
                "現行バージョンではプレイできません（データ残置）。",
                "",
            ]
        for d in group:
            pool = " / ".join(
                enemies.get(i, {}).get("display_name", i) for i in (d.get("enemy_pool") or [])
            )
            elite = " / ".join(
                enemies.get(i, {}).get("display_name", i) for i in (d.get("elite_pool") or [])
            )
            boss_id = d.get("boss_id", "") or ""
            boss = enemies.get(boss_id, {}).get("display_name", boss_id or "—（章ボス無し／深層）")
            lines += [
                f"### {d['display_name']}",
                "",
                "| 項目 | 内容 |",
                "|---|---|",
                f"| ID | `{d.get('id', '—')}` |",
                f"| 種別 | {ROUTE_LABEL.get(rt, rt)} |",
                f"| 難易度 | {'★' * int(d.get('difficulty', 1))} |",
                f"| 推奨レベル | {d.get('recommended_level', '—')} |",
                f"| 敵レベル | {d.get('enemy_level', '—')} |",
                f"| フロア数 | {d.get('floor_count', '—')} |",
                f"| 部屋数 | {d.get('room_count', '—')} |",
                f"| 出現モンスター | {pool or '—'} |",
                f"| エリート | {elite or '—'} |",
                f"| ボス | {boss} |",
                f"| 影響属性 | {ELEMENT.get(d.get('favored_element', ''), '—')} |",
                "",
            ]
            flavor = (d.get("flavor_text") or "").strip()
            if flavor:
                lines += [f"*{flavor}*", ""]
    write(DATA / "dungeons.md", "\n".join(lines))


def copy_images(monster_art: dict[str, str]):
    dst = ASSETS / "monsters"
    dst.mkdir(parents=True, exist_ok=True)
    for art in sorted(set(monster_art.values())):
        s = CODEX_ART / art
        if s.exists():
            shutil.copy2(s, dst / art)


def main():
    DATA.mkdir(parents=True, exist_ok=True)
    monster_art = build_monster_art_map()
    print(f"Monster art mapped: {len(monster_art)}")
    copy_images(monster_art)
    skills = load_dir("skills")
    materials = load_dir("materials")
    print("Generating data pages...")
    gen_monsters(monster_art, materials)
    gen_weapons(skills)
    gen_equipment()
    gen_jobs(skills)
    gen_skills()
    gen_dungeons()
    print("Done.")


if __name__ == "__main__":
    main()
