#!/usr/bin/env python3
"""成長H1＋C′の被ダメ／育ち差ヘッドレス点検（実機前の定量）。"""
from __future__ import annotations

K_MIT = 800.0
HP_PL, ATK_PL, DEF_PL = 48, 16, 8
HP_M, ATK_M, DEF_M = 24, 8, 4
OLD_ATK_K = 0.10
NEW_ATK_K = 0.13

MULT = {
    "アルド": (1.00, 1.05, 1.00),
    "リーヴァ": (0.90, 1.15, 0.85),
    "エリアス": (1.05, 0.90, 1.10),
    "ガレン": (1.15, 0.85, 1.20),
    "ミレイ": (1.00, 1.00, 0.95),
    "カイダ": (0.90, 1.20, 0.85),
    "火鷹": (0.90, 1.25, 0.85),
    "ヴァルデン": (1.10, 0.90, 1.15),
    "ネリ": (0.95, 0.85, 0.95),
    "レノール": (0.85, 1.20, 0.80),
}
BASE = {
    "アルド": (1123, 134, 146),
    "リーヴァ": (1008, 161, 97),
    "エリアス": (1287, 91, 209),
    "ガレン": (1348, 76, 239),
    "ミレイ": (1169, 113, 122),
    "カイダ": (913, 123, 64),
    "火鷹": (1472, 264, 266),
    "ヴァルデン": (1412, 167, 274),
    "ネリ": (835, 44, 52),
    "レノール": (849, 136, 18),
}
STARTERS = ["アルド", "リーヴァ", "エリアス", "ガレン", "ミレイ"]


def mit(defense: float) -> float:
    return K_MIT / (K_MIT + defense)


def growth(per: float, master: float, lv: int, mult: float) -> int:
    if lv <= 1:
        return 0
    soft = 50
    prim = min(lv - 1, soft - 1)
    bonus = round(per * prim * mult)
    if lv > soft:
        bonus += round(master * (lv - soft) * mult)
    return int(bonus)


def gear_def(lv: int) -> float:
    return max(0.0, 8.0 * (lv - 1))


def member_def(name: str, lv: int, h1: bool) -> float:
    _hp, _atk, df = BASE[name]
    if h1:
        hm, am, dm = MULT[name]
        return df + growth(DEF_PL, DEF_M, lv, dm) + gear_def(lv)
    return df + gear_def(lv)


def member_atk(name: str, lv: int, h1: bool) -> float:
    _hp, atk, _df = BASE[name]
    if h1:
        _hm, am, _dm = MULT[name]
        return atk + growth(ATK_PL, ATK_M, lv, am)
    return atk + growth(ATK_PL, ATK_M, lv, 1.0)


def enemy_atk_mult(lv: int, k: float) -> float:
    return 1.0 + k * max(0, lv - 1)


def party_avg_def(names: list[str], lv: int, h1: bool) -> float:
    return sum(member_def(n, lv, h1) for n in names) / len(names)


def main() -> None:
    print("=== 1. 被ダメ（スターター5・防具概算込み）変更前比 ===")
    print("※ 変更前=DEF成長なし+敵ATK_K0.10 / 現行=H1+C′(0.13)")
    for lv in [1, 5, 10, 20, 30, 40, 50]:
        d0 = party_avg_def(STARTERS, lv, False)
        d1 = party_avg_def(STARTERS, lv, True)
        taken = (enemy_atk_mult(lv, NEW_ATK_K) * mit(d1)) / (
            enemy_atk_mult(lv, OLD_ATK_K) * mit(d0)
        )
        print(
            f"Lv{lv:2d}: DEF {d0:.0f}->{d1:.0f}  taken_vs_before={taken:.3f}  "
            f"({'OK ±7%' if abs(taken - 1.0) <= 0.07 else 'WATCH'})"
        )

    print("\n=== 1b. 育ち差（装備なし ATK / DEF @Lv30） ===")
    for name in ["火鷹", "カイダ", "レノール", "アルド", "ガレン", "ヴァルデン", "ネリ"]:
        print(
            f"{name}: ATK {member_atk(name, 30, False):.0f}->{member_atk(name, 30, True):.0f}  "
            f"DEF {member_def(name, 30, False):.0f}->{member_def(name, 30, True):.0f}"
        )

    print("\n=== 2. C′係数の判定 ===")
    watch = []
    for lv in range(5, 41):
        d0 = party_avg_def(STARTERS, lv, False)
        d1 = party_avg_def(STARTERS, lv, True)
        taken = (enemy_atk_mult(lv, NEW_ATK_K) * mit(d1)) / (
            enemy_atk_mult(lv, OLD_ATK_K) * mit(d0)
        )
        if abs(taken - 1.0) > 0.08:
            watch.append((lv, taken))
    if not watch:
        print("Lv5-40: すべて ±8% 以内 → ENEMY_LEVEL_ATK_K=0.13 据置推奨")
    else:
        print("外れ帯:", ", ".join(f"Lv{lv}:{t:.3f}" for lv, t in watch[:8]))
        print("→ 微調整候補を検討")


if __name__ == "__main__":
    main()
