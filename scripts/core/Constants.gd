class_name Constants
extends RefCounted

const MAX_PARTY_SIZE: int = 3
const MAX_SUMMON_COUNT: int = 3
const SUMMON_DURATION_SEC: float = 20.0
const DEFAULT_DUNGEON_ROOM_COUNT: int = 10
const MOURNGATE_DUNGEON_ID: String = "mourngate"
const DEFAULT_DUNGEON_ID: String = MOURNGATE_DUNGEON_ID
## 寄り道(side)・征討(apex)をプレイ対象に含める（P3-DG-OMIT-001）。false=UI非表示・解放不可。
const SUB_DUNGEONS_PLAYABLE: bool = false
## イベントダンジョン（route_type=event）をプレイ対象に含める（P3-DG-DUCK-EVENT-001）。
const EVENT_DUNGEONS_PLAYABLE: bool = true
## 公開β範囲をモーンゲートのみにする（P3-BETA-SCOPE-001）。true=他メインは解放判定 false（UIは🔒表示・データ残置）。
const BETA_MOURNGATE_ONLY: bool = true
## コズミックダック日次イベントDG id。
const COSMIC_RIFT_DUNGEON_ID: String = "cosmic_rift"
## 宝冠レイヴン日次イベントDG id。
const CROWN_ROOKERY_DUNGEON_ID: String = "crown_rookery"
## 初期5人ストーリー編成（P3-STORY-STARTER-001）。true=開始1人選択＋章進行で加入。
const STARTER_STORY_RECRUIT: bool = true
## β検証用: モーンゲート 1-2/1-3/1-4 初回クリアでも未加入スターターを1人加入（本番×-5ルールに加え）。
## 2026-07-19 オーナー指示で OFF（本番寄り＝章5のみ）。
const STARTER_RECRUIT_BETA_EXTRA: bool = false
## ガチャ助っ人をプレイ対象に含める（P3-CHR-OMIT-001 / P3-GACHA-ENABLE-001）。false=招待状ロック・ロスターから除外（データ残置）。
const GACHA_HELPERS_PLAYABLE: bool = true
## サブステージ（1-1 等）分割を有効化（P3-DG-STG-001 / P3-DG-STG-ENABLE）。
## 2026-07-20 一旦オミット → 2026-07-21 実機で単体DGが常時ボス化し序盤出現が崩れたため再有効化。
const SUB_STAGES_PLAYABLE: bool = true
const RESOURCE_STAGES_PATH: String = "res://resources/stages/"
const COMBAT_TICK_INTERVAL: float = 1.5
const DEFAULT_PLAYER_SKILL_ID: String = "slash_attack"
## 1キャラが装備できるスキル数（P3-D077）。
const MAX_EQUIPPED_SKILLS: int = 2
## 1キャラが装備できるパッシブ数（キャラ/ジョブ由来。装備固定パッシブは別）。
const MAX_EQUIPPED_PASSIVES: int = 1
## 1キャラが装備できるレリック数（解放型パッシブ・P3-RELIC-PASSIVE）。
const MAX_EQUIPPED_RELIC_PASSIVES: int = 1
## 必殺技スロットの既定スキル id（P3-D085）。ジョブ未指定時に使用。
const DEFAULT_ULTIMATE_SKILL_ID: String = "ultimate_strike"

# DataRegistry resource paths (P2-Task020)
const RESOURCE_WEAPONS_PATH: String = "res://resources/weapons/"
const RESOURCE_ARMORS_PATH: String = "res://resources/armors/"
const RESOURCE_ACCESSORIES_PATH: String = "res://resources/accessories/"
const RESOURCE_ENEMIES_PATH: String = "res://resources/enemies/"
const RESOURCE_SKILLS_PATH: String = "res://resources/skills/"
const RESOURCE_DUNGEONS_PATH: String = "res://resources/dungeons/"
const RESOURCE_MATERIALS_PATH: String = "res://resources/materials/"
const RESOURCE_JOBS_PATH: String = "res://resources/jobs/"
const RESOURCE_AFFIXES_PATH: String = "res://resources/affixes/"
const RESOURCE_CRAFTING_PATH: String = "res://resources/crafting/"
const RESOURCE_RECIPES_PATH: String = "res://resources/recipes/"
const RESOURCE_MATERIAL_SHOP_PATH: String = "res://resources/material_shop/"
const RESOURCE_STATUS_EFFECTS_PATH: String = "res://resources/status/"
const RESOURCE_GACHA_HELPERS_PATH: String = "res://resources/gacha_helpers/"
const RESOURCE_TICKETS_PATH: String = "res://resources/tickets/"
const RESOURCE_DAILY_MISSIONS_PATH: String = "res://resources/daily_missions/"
const RESOURCE_EVENTS_PATH: String = "res://resources/events/"
## チケット本番配布。false=ストップデータのみ残置（P3-TICKET-001）。
const TICKET_DISTRIBUTION_ENABLED: bool = false
## デバッグセーブ付与枚数（各種）。
const DEBUG_TICKET_GRANT_EACH: int = 10

static func is_playable_dungeon_route(route_type: String) -> bool:
	if route_type == "main":
		return true
	if route_type == "event":
		return EVENT_DUNGEONS_PLAYABLE
	return SUB_DUNGEONS_PLAYABLE

static func is_gacha_helper_id(member_id: String) -> bool:
	return member_id.begins_with("gacha_") or member_id.begins_with("helper_")

static func are_gacha_helpers_playable() -> bool:
	return GACHA_HELPERS_PLAYABLE

static func is_pet_id(member_id: String) -> bool:
	return member_id.begins_with("pet_")
