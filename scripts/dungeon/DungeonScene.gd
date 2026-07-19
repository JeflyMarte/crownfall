extends Control

# 戦闘演出用アクセントフォントは UiTypography.impact_font() に統一（P3-UI-TYPE-001）。

# ダメージ計算のグローバル倍率は BalanceConfig に集約（P3-BAL-005）。
const CRITICAL_MULTIPLIER: float = BalanceConfig.CRITICAL_MULTIPLIER
const HEAL_AMOUNT: int = BalanceConfig.ROOM_HEAL_AMOUNT
# P3-D084: CT/ATB の 1 パルス（1 行動）間隔。倍率は COMBAT_TICK_BASE / mult。
const COMBAT_TICK_BASE: float = 0.75
const AUTO_DELAY_BASE: float = 1.2
const NON_COMBAT_FLOOR_GRACE_SEC: float = 1.6
const SPEED_MULT_NORMAL: float = 0.75
const SPEED_MULT_FAST: float = 1.5
const COMBAT_WAIT_GRIND: float = 0.28
const AUTO_DELAY_GRIND: float = 0.6
# 味方CHRの「見える体格」を揃える目標高さ（実体=α領域の高さ基準）
const CHR_BODY_TARGET_PX: float = 140.0
const _LOG_MAX: int = 60

const ENEMY_SPRITE_MAP: Dictionary = {
	"blood_leech": "res://resources/animation/ENM_BloodLeech.tres",
	"blood_bloom": "res://resources/animation/ENM_BloodLeech.tres",
	"bloom_serpent": "res://resources/animation/ENM_BloomSerpent.tres",
	"clock_moth": "res://resources/animation/ENM_ClockMoth.tres",
	"crown_eater_rat": "res://resources/animation/ENM_CrownEaterRat.tres",
	"crystal_scorpion": "res://resources/animation/ENM_CrystalScorpion.tres",
	"crystal_hedgehog": "res://resources/animation/ENM_CrystalHedgehog.tres",
	"grave_bell_bat": "res://resources/animation/ENM_GraveBellBat.tres",
	"dead_poison_frog": "res://resources/animation/ENM_DeadPoisonFrog.tres",
	"frost_claw_raptor": "res://resources/animation/ENM_FrostClawRaptor.tres",
	"great_claw": "res://resources/animation/ENM_GreatClaw.tres",
	"greios": "res://resources/animation/ENM_Greios.tres",
	"iron_horn": "res://resources/animation/ENM_MossShell.tres",
	"marsh_king": "res://resources/animation/ENM_MarshKing.tres",
	"mist_mantis": "res://resources/animation/ENM_MistMantis.tres",
	"mirror_boa": "res://resources/animation/ENM_BloomSerpent.tres",
	"mist_wyvern": "res://resources/animation/ENM_MistWyvern.tres",
	"moss_boar": "res://resources/animation/ENM_MossBoar.tres",
	"moss_shell": "res://resources/animation/ENM_MossShell.tres",
	"ninja_octopus": "res://resources/animation/ENM_NinjaOctopus.tres",
	"oldrex": "res://resources/animation/ENM_Oldrex.tres",
	"rune_carcinos": "res://resources/animation/ENM_ShipEaterCrab.tres",
	"rune_roach": "res://resources/animation/ENM_RuneRoach.tres",
	"samurai_fish": "res://resources/animation/ENM_SamuraiFish.tres",
	"sepia_hound": "res://resources/animation/ENM_SepiaHound.tres",
	"skullface_mantis": "res://resources/animation/ENM_SkullfaceMantis.tres",
	"ship_eater_crab": "res://resources/animation/ENM_ShipEaterCrab.tres",
	"skull_turtle": "res://resources/animation/ENM_SkullTurtle.tres",
	"spore_widow": "res://resources/animation/ENM_SporeWidow.tres",
	"storm_joe": "res://resources/animation/ENM_StormJoe.tres",
	"undertaker_shark": "res://resources/animation/ENM_UndertakerShark.tres",
	"vergaron": "res://resources/animation/ENM_Vergaron.tres",
	"cosmic_duck": "res://resources/animation/ENM_MistWyvern.tres",
	"crown_raven": "res://resources/animation/ENM_MossShell.tres",
	## 旧IDエイリアス（プレースホルダ）
	"wayfarer_sparrow": "res://resources/animation/ENM_MistWyvern.tres",
	"reliquary_beetle": "res://resources/animation/ENM_MossShell.tres",
}
## Hard/Nightmare 専用シート。キーは TIER_HARD=1 / TIER_NIGHTMARE=2 のみ。
## ノーマルでは参照しない。Hard 資産を Nightmare にフォールバックしない。
const ENEMY_SPRITE_MAP_BY_TIER: Dictionary = {
	"grave_bell_bat": {
		1: "res://resources/animation/ENM_GraveBellBat_Hard.tres",
		2: "res://resources/animation/ENM_GraveBellBat_Nightmare.tres",
	},
	"crystal_scorpion": {
		1: "res://resources/animation/ENM_CrystalScorpion_Hard.tres",
		2: "res://resources/animation/ENM_CrystalScorpion_Nightmare.tres",
	},
	"skullface_mantis": {
		1: "res://resources/animation/ENM_SkullfaceMantis_Hard.tres",
		2: "res://resources/animation/ENM_SkullfaceMantis_Nightmare.tres",
	},
	"sepia_hound": {
		1: "res://resources/animation/ENM_SepiaHound_Hard.tres",
		2: "res://resources/animation/ENM_SepiaHound_Nightmare.tres",
	},
	"rune_roach": {
		1: "res://resources/animation/ENM_RuneRoach_Hard.tres",
		2: "res://resources/animation/ENM_RuneRoach_Nightmare.tres",
	},
	"crown_eater_rat": {
		1: "res://resources/animation/ENM_CrownEaterRat_Hard.tres",
		2: "res://resources/animation/ENM_CrownEaterRat_Nightmare.tres",
	},
	"crystal_hedgehog": {
		1: "res://resources/animation/ENM_CrystalHedgehog_Hard.tres",
		2: "res://resources/animation/ENM_CrystalHedgehog_Nightmare.tres",
	},
	"clock_moth": {
		1: "res://resources/animation/ENM_ClockMoth_Hard.tres",
		2: "res://resources/animation/ENM_ClockMoth_Nightmare.tres",
	},
}
const BOSS_ENEMY_SPRITE_MAP: Dictionary = {
	"serdion": "res://resources/animation/BOSS_Serdion.tres",
	"granvel": "res://resources/animation/BOSS_Granvel.tres",
	"moldgar": "res://resources/animation/BOSS_Moldgar.tres",
	"nereion": "res://resources/animation/BOSS_Nereion.tres",
	"nereion_depths": "res://resources/animation/BOSS_Nereion.tres",
	"eldion": "res://resources/animation/BOSS_Eldion.tres",
}
## ボス Hard/NM 限定（ノーマルは BOSS_ENEMY_SPRITE_MAP / BOSS_SPRITE_MAP）
const BOSS_ENEMY_SPRITE_MAP_BY_TIER: Dictionary = {
	"serdion": {
		1: "res://resources/animation/BOSS_Serdion_Hard.tres",
		2: "res://resources/animation/BOSS_Serdion_Nightmare.tres",
	},
}
const BOSS_SPRITE_MAP_BY_TIER: Dictionary = {
	"mourngate": {
		1: "res://resources/animation/BOSS_Serdion_Hard.tres",
		2: "res://resources/animation/BOSS_Serdion_Nightmare.tres",
	},
	"mourngate_deep": {
		1: "res://resources/animation/BOSS_Serdion_Hard.tres",
		2: "res://resources/animation/BOSS_Serdion_Nightmare.tres",
	},
	"storm_crown_ruins": {
		1: "res://resources/animation/BOSS_Serdion_Hard.tres",
		2: "res://resources/animation/BOSS_Serdion_Nightmare.tres",
	},
}
const BOSS_SPRITE_MAP: Dictionary = {
	"astoria_ruins": "res://resources/animation/ENM_ClockMoth.tres",
	"blackshore": "res://resources/animation/BOSS_Nereion.tres",
	"broken_marsh": "res://resources/animation/ENM_GreatClaw.tres",
	"frostridge": "res://resources/animation/BOSS_Eldion.tres",
	"frostwall_path": "res://resources/animation/ENM_FrostClawRaptor.tres",
	"green_hollow": "res://resources/animation/ENM_MossBoar.tres",
	"mistfen": "res://resources/animation/BOSS_Moldgar.tres",
	"mourngate": "res://resources/animation/BOSS_Serdion.tres",
	"westbay_flats": "res://resources/animation/ENM_ShipEaterCrab.tres",
	"whisperwood": "res://resources/animation/BOSS_Granvel.tres",
	"mourngate_deep": "res://resources/animation/BOSS_Serdion.tres",
	"storm_crown_ruins": "res://resources/animation/BOSS_Serdion.tres",
	"red_ridge_mine": "res://resources/animation/BOSS_Granvel.tres",
	"mistfen_depths": "res://resources/animation/BOSS_Moldgar.tres",
	"thunder_peak": "res://resources/animation/BOSS_Moldgar.tres",
	"blackshore_abyss": "res://resources/animation/BOSS_Nereion.tres",
	"red_forge_depths": "res://resources/animation/BOSS_Eldion.tres",
	"north_reach": "res://resources/animation/BOSS_Eldion.tres",
}
const CHR_SPRITE_MAP: Dictionary = {
	"swordsman": "res://resources/animation/CHR_Swordsman.tres",
	"ranger": "res://resources/animation/CHR_Ranger.tres",
	"alchemist": "res://resources/animation/CHR_Alchemist.tres",
	"vanguard": "res://resources/animation/CHR_Vanguard.tres",
	"beast_tamer": "res://resources/animation/CHR_BeastTamer.tres",
}
const BATTLE_BG_MAP: Dictionary = {
	"mourngate": "res://assets/dungeon/mourngate/env/BG_Battle_Mourngate.png",
	"astoria_ruins": "res://assets/dungeon/astoria_ruins/env/BG_Battle_AstoriaRuins.png",
	"whisperwood": "res://assets/dungeon/whisperwood/env/BG_Battle_Whisperwood.png",
	"green_hollow": "res://assets/dungeon/green_hollow/env/BG_Battle_GreenHollow.png",
	"mistfen": "res://assets/dungeon/mistfen/env/BG_Battle_Mistfen.png",
	"broken_marsh": "res://assets/dungeon/broken_marsh/env/BG_Battle_BrokenMarsh.png",
	"blackshore": "res://assets/dungeon/blackshore/env/BG_Battle_Blackshore.png",
	"westbay_flats": "res://assets/dungeon/westbay_flats/env/BG_Battle_WestbayFlats.png",
	"frostridge": "res://assets/dungeon/frostridge/env/BG_Battle_Frostridge.png",
	"frostwall_path": "res://assets/dungeon/frostwall_path/env/BG_Battle_FrostwallPath.png",
	"mourngate_deep": "res://assets/dungeon/mourngate/env/BG_Battle_Mourngate.png",
	"storm_crown_ruins": "res://assets/dungeon/astoria_ruins/env/BG_Battle_AstoriaRuins.png",
	"red_ridge_mine": "res://assets/dungeon/whisperwood/env/BG_Battle_Whisperwood.png",
	"mistfen_depths": "res://assets/dungeon/mistfen/env/BG_Battle_Mistfen.png",
	"thunder_peak": "res://assets/dungeon/broken_marsh/env/BG_Battle_BrokenMarsh.png",
	"blackshore_abyss": "res://assets/dungeon/blackshore/env/BG_Battle_Blackshore.png",
	"red_forge_depths": "res://assets/dungeon/frostridge/env/BG_Battle_Frostridge.png",
	"north_reach": "res://assets/dungeon/frostridge/env/BG_Battle_Frostridge.png",
}
const TREASURE_CLOSED_OBJ_MAP: Dictionary = {
	"mourngate": "res://assets/dungeon/mourngate/env/OBJ_TreasureChest_Closed.png",
	"astoria_ruins": "res://assets/dungeon/astoria_ruins/env/OBJ_TreasureChest_Closed.png",
	"whisperwood": "res://assets/dungeon/whisperwood/env/OBJ_TreasureChest_Closed.png",
	"green_hollow": "res://assets/dungeon/green_hollow/env/OBJ_TreasureChest_Closed.png",
	"mistfen": "res://assets/dungeon/mistfen/env/OBJ_TreasureChest_Closed.png",
	"broken_marsh": "res://assets/dungeon/broken_marsh/env/OBJ_TreasureChest_Closed.png",
	"blackshore": "res://assets/dungeon/blackshore/env/OBJ_TreasureChest_Closed.png",
	"westbay_flats": "res://assets/dungeon/westbay_flats/env/OBJ_TreasureChest_Closed.png",
	"frostridge": "res://assets/dungeon/frostridge/env/OBJ_TreasureChest_Closed.png",
	"frostwall_path": "res://assets/dungeon/frostwall_path/env/OBJ_TreasureChest_Closed.png",
	"mourngate_deep": "res://assets/dungeon/mourngate/env/OBJ_TreasureChest_Closed.png",
	"storm_crown_ruins": "res://assets/dungeon/astoria_ruins/env/OBJ_TreasureChest_Closed.png",
	"red_ridge_mine": "res://assets/dungeon/whisperwood/env/OBJ_TreasureChest_Closed.png",
	"mistfen_depths": "res://assets/dungeon/mistfen/env/OBJ_TreasureChest_Closed.png",
	"thunder_peak": "res://assets/dungeon/broken_marsh/env/OBJ_TreasureChest_Closed.png",
	"blackshore_abyss": "res://assets/dungeon/blackshore/env/OBJ_TreasureChest_Closed.png",
	"red_forge_depths": "res://assets/dungeon/frostridge/env/OBJ_TreasureChest_Closed.png",
	"north_reach": "res://assets/dungeon/frostridge/env/OBJ_TreasureChest_Closed.png",
}
const EXIT_OBJ_MAP: Dictionary = {
	"mourngate": "res://assets/dungeon/mourngate/env/OBJ_ExitGate_Mourngate.png",
	"astoria_ruins": "res://assets/dungeon/astoria_ruins/env/OBJ_ExitGate_AstoriaRuins.png",
	"whisperwood": "res://assets/dungeon/whisperwood/env/OBJ_ExitGate_Whisperwood.png",
	"green_hollow": "res://assets/dungeon/green_hollow/env/OBJ_ExitGate_GreenHollow.png",
	"mistfen": "res://assets/dungeon/mistfen/env/OBJ_ExitGate_Mistfen.png",
	"broken_marsh": "res://assets/dungeon/broken_marsh/env/OBJ_ExitGate_BrokenMarsh.png",
	"blackshore": "res://assets/dungeon/blackshore/env/OBJ_ExitGate_Blackshore.png",
	"westbay_flats": "res://assets/dungeon/westbay_flats/env/OBJ_ExitGate_WestbayFlats.png",
	"frostridge": "res://assets/dungeon/frostridge/env/OBJ_ExitGate_Frostridge.png",
	"frostwall_path": "res://assets/dungeon/frostwall_path/env/OBJ_ExitGate_FrostwallPath.png",
	"mourngate_deep": "res://assets/dungeon/mourngate/env/OBJ_ExitGate_Mourngate.png",
	"storm_crown_ruins": "res://assets/dungeon/astoria_ruins/env/OBJ_ExitGate_AstoriaRuins.png",
	"red_ridge_mine": "res://assets/dungeon/whisperwood/env/OBJ_ExitGate_Whisperwood.png",
	"mistfen_depths": "res://assets/dungeon/mistfen/env/OBJ_ExitGate_Mistfen.png",
	"thunder_peak": "res://assets/dungeon/broken_marsh/env/OBJ_ExitGate_BrokenMarsh.png",
	"blackshore_abyss": "res://assets/dungeon/blackshore/env/OBJ_ExitGate_Blackshore.png",
	"red_forge_depths": "res://assets/dungeon/frostridge/env/OBJ_ExitGate_Frostridge.png",
	"north_reach": "res://assets/dungeon/frostridge/env/OBJ_ExitGate_Frostridge.png",
}
const FLOOR_TILE_MAP: Dictionary = {
	"mourngate": "res://assets/dungeon/mourngate/env/TILE_Floor.png",
	"astoria_ruins": "res://assets/dungeon/astoria_ruins/env/TILE_Floor.png",
	"whisperwood": "res://assets/dungeon/whisperwood/env/TILE_Floor.png",
	"green_hollow": "res://assets/dungeon/green_hollow/env/TILE_Floor.png",
	"mistfen": "res://assets/dungeon/mistfen/env/TILE_Floor.png",
	"broken_marsh": "res://assets/dungeon/broken_marsh/env/TILE_Floor.png",
	"blackshore": "res://assets/dungeon/blackshore/env/TILE_Floor.png",
	"westbay_flats": "res://assets/dungeon/westbay_flats/env/TILE_Floor.png",
	"frostridge": "res://assets/dungeon/frostridge/env/TILE_Floor.png",
	"frostwall_path": "res://assets/dungeon/frostwall_path/env/TILE_Floor.png",
	"mourngate_deep": "res://assets/dungeon/mourngate/env/TILE_Floor.png",
	"storm_crown_ruins": "res://assets/dungeon/astoria_ruins/env/TILE_Floor.png",
	"red_ridge_mine": "res://assets/dungeon/whisperwood/env/TILE_Floor.png",
	"mistfen_depths": "res://assets/dungeon/mistfen/env/TILE_Floor.png",
	"thunder_peak": "res://assets/dungeon/broken_marsh/env/TILE_Floor.png",
	"blackshore_abyss": "res://assets/dungeon/blackshore/env/TILE_Floor.png",
	"red_forge_depths": "res://assets/dungeon/frostridge/env/TILE_Floor.png",
	"north_reach": "res://assets/dungeon/frostridge/env/TILE_Floor.png",
}
const _FLOOR_ROOM_TYPES: Array[int] = [
	Enums.RoomType.EXIT,
]
const _PHASE_BG_ROOM_TYPES: Array[int] = [
	Enums.RoomType.HEAL,
	Enums.RoomType.TREASURE,
	Enums.RoomType.EVENT,
	Enums.RoomType.TRAP,
]
const ROOM_OBJ_DISPLAY_PX: float = 64.0
const TREASURE_OBJ_DISPLAY_PX: float = 128.0
const TREASURE_OPEN_SHAKE: float = 5.0
const TREASURE_OPEN_PRE_SWAP_SEC: float = 0.14
const TREASURE_OPEN_HOLD_SEC: float = 0.24
const STATUS_ICON_DEF: Dictionary = {
	"poison": {"abbrev": "毒", "color": Color(0.25, 0.75, 0.3)},
	"chill": {"abbrev": "冷", "color": Color(0.35, 0.65, 0.95)},
	"shock": {"abbrev": "感", "color": Color(0.95, 0.85, 0.2)},
	"ignite": {"abbrev": "炎", "color": Color(0.95, 0.4, 0.15)},
	"curse": {"abbrev": "呪", "color": Color(0.55, 0.25, 0.75)},
	"stun": {"abbrev": "麻", "color": Color(0.7, 0.7, 0.75)},
	"fear": {"abbrev": "恐", "color": Color(0.55, 0.35, 0.6)},
	"vulnerable": {"abbrev": "脆", "color": Color(0.95, 0.45, 0.45)},
	"armor_break": {"abbrev": "破", "color": Color(0.8, 0.6, 0.3)},
	"mark": {"abbrev": "標", "color": Color(0.95, 0.35, 0.55)},
	"empower": {"abbrev": "攻", "color": Color(0.95, 0.55, 0.2)},
	"guard": {"abbrev": "防", "color": Color(0.4, 0.55, 0.85)},
}
const HEAL_SKILL_BASE: int = BalanceConfig.HEAL_SKILL_BASE
const STATUS_ICON_SIZE: float = 26.0
const STATUS_ICON_GAP: float = 3.0
const VFX_HIT_PATH: String = "res://resources/animation/FX_Hit_Normal.tres"
const VFX_CRIT_PATH: String = "res://resources/animation/FX_Hit_Critical.tres"
const VFX_HEAL_PATH: String = "res://resources/animation/FX_Heal.tres"
const SUPPORT_VFX_TINT: Dictionary = {
	"heal": Color(0.5, 1.0, 0.55, 1.0),
	"empower": Color(1.0, 0.72, 0.25, 1.0),
	"guard": Color(0.45, 0.78, 1.0, 1.0),
	"default_buff": Color(1.0, 0.9, 0.45, 1.0),
}
const ULTIMATE_GOLD: Color = Color(1.0, 0.78, 0.22)
const ULTIMATE_FLASH_DAMAGE: Color = Color(1.0, 0.88, 0.45)
const ULTIMATE_FLASH_HEAL: Color = Color(0.55, 1.0, 0.72)
## 攻撃アニメ中のヒット位置（全体尺に対する比率）。ダメージ／ヒットVFXはここまで遅延。
const ATTACK_IMPACT_FRAME_RATIO: float = 0.42
const ATTACK_IMPACT_FALLBACK_SEC: float = 0.22
## 戦闘フロア入場〜実際の戦闘開始までの余白。
const COMBAT_START_DELAY_SEC: float = 1.5
# バトルログ BBCode 色（モック準拠・P3-UI2 拡張）
const LOG_MUTED: Color = UiTypography.COLOR_LOG
const LOG_TAG: Color = Color("#C9A0FF")
const LOG_DAMAGE_OUT: Color = Color("#FFD700")
const LOG_DAMAGE_CRIT: Color = Color("#FFF176")
const LOG_DAMAGE_IN: Color = Color("#FF8A65")
const LOG_HEAL: Color = Color("#81C784")
const LOG_ENEMY_NORMAL: Color = Color("#E8C4B0")
const LOG_ENEMY_ELITE: Color = Color("#FF9E7A")
const LOG_ENEMY_BOSS: Color = Color("#FF6B6B")
const LOG_ENEMY_TIER_BY_ID: Dictionary = {
	"mirror_boa": "elite",
	"mist_wyvern": "elite",
	"clock_moth": "elite",
	"serdion": "boss",
	"granvel": "boss",
	"moldgar": "boss",
	"nereion": "boss",
	"eldion": "boss",
	"chronos_wave": "boss",
	"valgard": "boss",
	"skarpedion": "boss",
	"mycolga_ancient": "boss",
	"karna_smoke": "boss",
	"nereion_depths": "boss",
	"forgedormient": "boss",
	"albark": "boss",
}
const LOG_BRACKET_TAGS: PackedStringArray = [
	"【必殺】", "【スキル】", "【エリート】", "【ボス】", "【混成】", "【フェーズ移行】",
	"[パッシブ]", "[レリック]", "[防御]", "[詠唱]", "[探索]", "[罠]", "[コンボ]", "[連携]", "[戦術]",
]
const NOW_PLAYING_PARTY_COLOR: Color = Color(0.92, 0.88, 0.78, 1.0)
const NOW_PLAYING_ENEMY_COLOR: Color = Color(1.0, 0.55, 0.45, 1.0)
const PARTY_CARD_CRITICAL_HP_RATIO: float = 0.25
const COMBAT_BIG_DAMAGE_THRESHOLD: int = 100
const COMBAT_CRIT_SHAKE_INTENSITY: float = 12.0
const COMBAT_BIG_DAMAGE_SHAKE_INTENSITY: float = 7.5
const COMBAT_CRIT_DAMAGE_SCALE: float = 1.35
const COMBAT_SHAKE_COOLDOWN_SEC: float = 0.18
const DIVE_INTRO_FADE_SEC: float = 0.35
const DIVE_INTRO_HOLD_SEC: float = 1.55
const DIVE_INTRO_START_SEC: float = 0.85
const RUN_HUD_HEIGHT: float = 28.0
const BOSS_INTRO_WARNING_TEXT: String = "警告"
const ELITE_INTRO_TEXT: String = "エリート"
## 属性ごとの演出色（命中VFXの modulate / スキル名フォント色に共用）。
## 未設定/無属性は WHITE（VFX）・既定の青系（スキル名）にフォールバック。
const ELEMENT_COLOR: Dictionary = {
	"fire": Color(1.0, 0.5, 0.2),
	"ice": Color(0.45, 0.82, 1.0),
	"thunder": Color(1.0, 0.93, 0.35),
	"dark": Color(0.78, 0.5, 1.0),
	"holy": Color(1.0, 0.93, 0.6),
}
## 属性別の専用命中VFX（任意）。CC0素材から作った SpriteFrames を置けば自動採用。
## 未配置の属性は FX_Hit_Normal をティント着色してフォールバックする（非破壊）。
const ELEMENT_VFX_PATH: Dictionary = {
	"fire": "res://resources/animation/FX_Hit_Fire.tres",
	"ice": "res://resources/animation/FX_Hit_Ice.tres",
	"thunder": "res://resources/animation/FX_Hit_Thunder.tres",
	"dark": "res://resources/animation/FX_Hit_Dark.tres",
	"holy": "res://resources/animation/FX_Hit_Holy.tres",
}
const SkillExecutorScript: Script = preload("res://scripts/combat/SkillExecutor.gd")
const CombatVfxManagerScript: Script = preload("res://scripts/combat/CombatVfxManager.gd")
const EvolutionVisualScript: Script = preload("res://scripts/systems/EvolutionVisual.gd")
const ElementResolverScript: Script = preload("res://scripts/combat/ElementResolver.gd")
const AffixStatCalculatorScript: Script = preload("res://scripts/equipment/AffixStatCalculator.gd")
const JobStatCalculatorScript: Script = preload("res://scripts/equipment/JobStatCalculator.gd")
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _CommanderLifetime = preload("res://scripts/commander/CommanderLifetime.gd")

var _auto_delay: float = AUTO_DELAY_BASE / SPEED_MULT_NORMAL
var _auto_progress_paused_remaining: float = 0.0
var _auto_progress_finishes: bool = false
var _pending_room_continuation: bool = false
var _discovery_toast_tween: Tween
var _skill_executor: RefCounted = SkillExecutorScript.new()
var _combat_vfx: RefCounted = CombatVfxManagerScript.new()
var _is_paused: bool = false
var _combat_speed_mult: float = SPEED_MULT_NORMAL
var _fast_run_enabled: bool = false
var _btn_fast_run: Button = null
# ラウンド処理中フラグ（P3-D083・逐次awaitの多重実行防止）
var _round_active: bool = false
var _request_scroll_to_bottom: bool = false
var _trap_presentation_active: bool = false
var _heal_presentation_active: bool = false
var _treasure_presentation_active: bool = false
var _event_presentation_active: bool = false
var _combat_clear_active: bool = false
var _combat_cinematic_lock: bool = false
var _ultimate_presentation_active: bool = false
var _ultimate_center_telop: Control = null
var _combat_clear_tween: Tween
var _dive_intro_active: bool = false
var _room_transition_busy: bool = false
var _dive_intro_tween: Tween
var _dive_intro_panel: PanelContainer
var _transition_fx_host: Control
var _run_hud_panel: PanelContainer
var _run_hud_progress: ProgressBar
var _run_hud_floor_label: Label
var _run_hud_room_chip: Label
var _run_hud_discovery: Label
var _boss_intro_active: bool = false
var _boss_intro_tween: Tween
var _boss_warning_label: Label
var _boss_intro_base_scale: Vector2 = Vector2.ONE
var _elite_intro_active: bool = false
var _elite_intro_tween: Tween
var _elite_intro_label: Label
var _elite_enemy_slide_sprite: AnimatedSprite2D
var _elite_enemy_slide_target: Vector2 = Vector2.ZERO
var _event_telop_panel: PanelContainer
var _event_telop_bg: TextureRect
var _event_telop_dim: ColorRect
var _event_telop_scene_label: Label
var _event_telop_result_label: Label

@onready var _boss_sprite: AnimatedSprite2D = $BossSprite
@onready var _enemy_sprite: AnimatedSprite2D = $EnemySprite
@onready var _hit_vfx_sprite: AnimatedSprite2D = $HitVfxSprite
@onready var _heal_vfx_sprite: AnimatedSprite2D = $HealVfxSprite
@onready var _damage_numbers_layer: CanvasLayer = $DamageNumbers
@onready var _discovery_toast: PanelContainer = $DiscoveryToastLayer/DiscoveryToast
@onready var _label_discovery_text: Label = $DiscoveryToastLayer/DiscoveryToast/LabelDiscoveryText
@onready var _bg_texture: TextureRect = $BgTexture
@onready var _chr_sprite_0: AnimatedSprite2D = $ChrSprite0
@onready var _chr_sprite_1: AnimatedSprite2D = $ChrSprite1
@onready var _chr_sprite_2: AnimatedSprite2D = $ChrSprite2
@onready var _chr_sprite_3: AnimatedSprite2D = $ChrSprite3

@onready var _battle_log_panel: PanelContainer = $MainVBox/BattleLogPanel
@onready var _battle_log_scroll: ScrollContainer = $MainVBox/BattleLogPanel/BattleLogScroll
@onready var _battle_log_content: VBoxContainer = $MainVBox/BattleLogPanel/BattleLogScroll/BattleLogContent
@onready var _party_status_panel: PanelContainer = $MainVBox/PartyStatusPanel
@onready var _party_cards_row: HBoxContainer = $MainVBox/PartyStatusPanel/PartyStatusVBox/PartyCardsRow
@onready var _narrative_panel: PanelContainer = $MainVBox/NarrativePanel
@onready var _label_narrative: Label = $MainVBox/NarrativePanel/LabelNarrative
@onready var _label_dungeon_name: Label = $MainVBox/HeaderBar/LabelDungeonName
@onready var _label_room: Label = $MainVBox/HeaderBar/LabelRoom
var _dungeon_header_icon: TextureRect
@onready var _label_enemy: Label = $MainVBox/BottomZone/LabelEnemy
@onready var _room_tile_bg: TextureRect = $MainVBox/BattlefieldArea/RoomTileBg
@onready var _room_object: TextureRect = $MainVBox/BattlefieldArea/RoomObject
@onready var _combat_tier_frame: PanelContainer = $MainVBox/BattlefieldArea/CombatTierFrame
@onready var _label_combat_tier: Label = $MainVBox/BattlefieldArea/CombatTierFrame/LabelCombatTier
@onready var _label_status_enemy: Label = $MainVBox/BottomZone/LabelStatusEnemy
@onready var _label_status_party: Label = $MainVBox/BottomZone/LabelStatusParty
@onready var _auto_combat_row: HBoxContainer = $MainVBox/PartyStatusPanel/PartyStatusVBox/AutoCombatRow
@onready var _non_combat_zone: VBoxContainer = $MainVBox/BottomZone/NonCombatZone
@onready var _btn_next_room: Button = $MainVBox/BottomZone/NonCombatZone/ButtonNextRoom
@onready var _btn_finish: Button = $MainVBox/BottomZone/NonCombatZone/ButtonFinish
@onready var _menu_overlay: PanelContainer = $MenuOverlay
@onready var _pause_overlay: Control = $PauseOverlay
@onready var _hp_bar_chr0: ProgressBar = $HpBarChr0
@onready var _hp_bar_chr1: ProgressBar = $HpBarChr1
@onready var _hp_bar_chr2: ProgressBar = $HpBarChr2
@onready var _hp_bar_chr3: ProgressBar = $HpBarChr3
@onready var _hp_bar_enemy: ProgressBar = $HpBarEnemy
@onready var _enemy_nameplate: Label = $EnemyNamePlate
@onready var _transition_overlay: ColorRect = $TransitionLayer/TransitionOverlay
@onready var _label_transition: Label = $TransitionLayer/TransitionOverlay/LabelTransition

var _chr_sprites: Array[AnimatedSprite2D] = []
# 1フレームのみの idle 素材（Ranger/Alchemist 等）向けのコード擬似 idle（呼吸）tween 保持
var _chr_idle_tweens: Array = [null, null, null, null]
# メンバーごとの表示中スキル名ラベル（重なり防止のため tick 毎に置換・段組み）
var _chr_skill_labels: Array = [[], [], [], []]
# 同一メンバーが同 tick に複数スキルを発動した際、ラベルを縦にずらす間隔(px)
const SKILL_LABEL_STACK_GAP: float = 34.0
var _chr_hp_bars: Array[ProgressBar] = []
var _party_card_hp_bars: Array[ProgressBar] = []
var _party_card_hp_labels: Array[Label] = []
var _party_card_skill_cd_bars: Array = []
var _skill_cd_visual_rem: Dictionary = {}
var _last_ct_step_ui: float = 0.0
var _party_card_portraits: Array[TextureRect] = []
var _party_card_roots: Array[PanelContainer] = []
var _party_card_active_turn: int = -1
var _combat_tier_vignette: ColorRect
var _tier_frame_pulse_tween: Tween
var _threat_banner: PanelContainer
var _label_threat_banner: Label
var _threat_vignette: ColorRect
var _threat_banner_pulse_tween: Tween
var _party_card_state_badges: Array[Label] = []
var _party_card_pulse_tweens: Array = []
var _combat_shake_cooldown_until: float = 0.0
var _status_icon_swarm_rows: Array[HBoxContainer] = []
var _status_icon_chr_rows: Array[HBoxContainer] = []
var _combat_sprites_host: Node2D

# 群れ（複数敵）表示スロット（P3-D082）。slot0 は既存ノード（_enemy_sprite/_hp_bar_enemy/_enemy_nameplate）を流用し、
# 2体目以降は duplicate で動的生成する。ボス戦では使用しない（BossSprite を使う）。
var _swarm_sprites: Array[AnimatedSprite2D] = []
var _swarm_hp_bars: Array[ProgressBar] = []
var _swarm_nameplates: Array[Label] = []
const SWARM_SPACING_RATIO: float = 0.201
const SWARM_CENTER_X_RATIO: float = 0.694
const SWARM_Y_RATIO: float = 0.48
## エリートは通常雑魚より上（ボスに近い高さ）に置く。
const ELITE_Y_RATIO: float = 0.34
# BattlefieldArea 内の足元Y比率へ加算（全体を下げる）
const COMBAT_Y_BIAS: float = 0.08
# 編成スロット別の戦闘配置（BattlefieldArea 内の比率・足元基準）。
# スロット 0,1=前衛 / 2,3=後衛（combat_index ではなく formation_slot で参照）。
const FORMATION_SLOT_RATIOS: Array[Vector2] = [
	Vector2(0.368, 0.61),  # 0 前衛左
	Vector2(0.583, 0.72),  # 1 前衛右（敵寄り）
	Vector2(0.174, 0.71),  # 2 後衛左（奥）
	Vector2(0.368, 0.80),  # 3 後衛右
]
const PARTY_CARD_SLOT_COUNT: int = 4
const BATTLE_LOG_VISIBLE_LINES: int = 4
# 1行の実描画高（フォント22＋アウトライン余白）＋行間3。
const BATTLE_LOG_LINE_HEIGHT: float = 38.0
const BATTLE_LOG_LINE_GAP: float = 3.0
const BATTLE_LOG_SCROLL_MARGIN_V: float = 10.0
const BATTLE_LOG_SCROLL_HEIGHT: float = (
	BATTLE_LOG_LINE_HEIGHT * float(BATTLE_LOG_VISIBLE_LINES)
	+ BATTLE_LOG_LINE_GAP * float(BATTLE_LOG_VISIBLE_LINES - 1)
	+ BATTLE_LOG_SCROLL_MARGIN_V
)
# パネル content_margin 上下 6+6 を加算。
const BATTLE_LOG_PANEL_HEIGHT: float = BATTLE_LOG_SCROLL_HEIGHT + 12.0
const TRAP_HIT_PAUSE_SEC: float = 0.45
const TRAP_FEEDBACK_FLASH_COLOR: Color = Color(1.0, 0.32, 0.22)
const TRAP_FEEDBACK_DMG_COLOR: Color = Color(1.0, 0.35, 0.35)
const TrapPresentationScript: Script = preload("res://scripts/dungeon/TrapPresentation.gd")
const UltimatePresentationConfigScript: Script = preload("res://scripts/combat/UltimatePresentationConfig.gd")
const HealRoomPresentationScript: Script = preload("res://scripts/dungeon/HealRoomPresentation.gd")
const TreasureRoomPresentationScript: Script = preload("res://scripts/dungeon/TreasureRoomPresentation.gd")
const LoreRoomPresentationScript: Script = preload("res://scripts/dungeon/LoreRoomPresentation.gd")
const EventPresentationScript: Script = preload("res://scripts/dungeon/EventPresentation.gd")
const PartyLogColorsScript: Script = preload("res://scripts/ui/PartyLogColors.gd")
const ExpRunSnapshotScript: Script = preload("res://scripts/result/ExpRunSnapshot.gd")
const BOSS_POSITION_RATIO: Vector2 = Vector2(0.688, 0.25)
const BOSS_BODY_TARGET_PX: float = 360.0
const COMBAT_UI_Z: int = 40
const COMBAT_OVERLAY_Z: int = 25
const PARTY_CARD_ICON_PX: float = 72.0
const PARTY_CARD_WEAPON_ICON_PX: float = 24.0
const PARTY_CARD_HP_HEIGHT: float = 14.0
const PARTY_CARD_CD_HEIGHT: float = 5.0
const SKILL_CD_LERP_RATE: float = 14.0
const PARTY_CARD_HP_FILL: Color = Color("#41D16A")
const PARTY_CARD_SKILL_CD_READY: Color = Color(0.55, 0.82, 0.55, 1.0)
const PARTY_CARD_SKILL_CD_WAIT: Color = Color(0.95, 0.72, 0.35, 1.0)
const PARTY_CARD_EMPTY_MODULATE: Color = Color(0.45, 0.45, 0.5, 0.55)
const PARTY_CARD_DEAD_MODULATE: Color = Color(0.55, 0.55, 0.55, 0.75)
const UI_TEXT_PRIMARY: Color = Color(0.98, 0.96, 0.92, 1.0)
const UI_TEXT_SECONDARY: Color = Color(0.92, 0.90, 0.84, 1.0)
const UI_TEXT_WEAPON: Color = Color(0.95, 0.91, 0.82, 1.0)
const CHR_HP_BAR_FRONT_Y_OFFSET: float = 0.0
const CHR_HP_BAR_BACK_Y_OFFSET: float = 0.0
const CHR_HP_BAR_GAP_ABOVE_SPRITE: float = 12.0
const CHR_HP_BAR_HEIGHT: float = 8.0
const CHR_STATUS_GAP_ABOVE_BAR: float = 4.0

# 行動順（ターンオーダー）表示（P3-D083）。
var _turn_order_col_left: VBoxContainer
var _turn_order_col_right: VBoxContainer
var _turn_order_items: Array = []  # [{kind, index, node, icon, badge}]
var _label_now_playing: Label
var _combat_now_playing_active: bool = false
const TURN_ORDER_SIDE_ICON_PX: float = 52.0
const TURN_ORDER_SIDE_FRAME_PAD: float = 5.0
const TURN_ORDER_SIDE_GAP: float = 4.0
const TURN_ORDER_SIDE_MARGIN: float = 6.0
const TURN_ORDER_SIDE_TOP: float = 36.0
const TURN_ORDER_BADGE_FONT_PX: int = 12

func _ready() -> void:
	## 探索BGM（非戦闘ルームへ入るまで / dive 中も探索曲）。
	AudioManager.play_bgm("dungeon_explore")
	_btn_next_room.pressed.connect(_on_next_room_pressed)
	_btn_finish.pressed.connect(_on_finish_button_pressed)
	$CombatTimer.timeout.connect(_on_combat_timer_timeout)
	$AutoProgressTimer.timeout.connect(_on_auto_progress_timeout)
	$MainVBox/HeaderBar/ButtonMenu.pressed.connect(_on_menu_button_pressed)
	$MainVBox/HeaderBar/ButtonSpeedX1.pressed.connect(_on_speed_x1_pressed)
	$MainVBox/HeaderBar/ButtonSpeedX2.pressed.connect(_on_speed_x2_pressed)
	_ensure_fast_run_button()
	$MainVBox/HeaderBar/ButtonStop.pressed.connect(_on_stop_pressed)
	_menu_overlay.get_node("MenuVBox/ButtonFinishFromMenu").pressed.connect(_on_menu_finish_pressed)
	_menu_overlay.get_node("MenuVBox/ButtonCloseMenu").pressed.connect(_on_close_menu_pressed)
	$MainVBox/PartyStatusPanel/PartyStatusVBox/AutoCombatRow/ButtonPause.pressed.connect(_on_pause_button_pressed)
	_pause_overlay.get_node("PausePanel/PauseVBox/ButtonPauseResume").pressed.connect(_on_pause_resume_pressed)
	_pause_overlay.get_node("PausePanel/PauseVBox/ButtonPauseRetire").pressed.connect(_on_pause_retire_pressed)
	EventBus.weapon_obtained.connect(_on_weapon_obtained)
	_hit_vfx_sprite.animation_finished.connect(func(): _hit_vfx_sprite.visible = false)
	_heal_vfx_sprite.animation_finished.connect(func(): _heal_vfx_sprite.visible = false)
	_chr_sprites = [_chr_sprite_0, _chr_sprite_1, _chr_sprite_2, _chr_sprite_3]
	_chr_hp_bars = [_hp_bar_chr0, _hp_bar_chr1, _hp_bar_chr2, _hp_bar_chr3]
	_init_status_icon_rows()
	_init_turn_order_row()
	for sprite: AnimatedSprite2D in _chr_sprites:
		sprite.animation_finished.connect(func():
			if sprite.visible and sprite.sprite_frames != null:
				if sprite.animation in ["attack", "hurt"]:
					sprite.play("idle")
		)
	_enemy_sprite.animation_finished.connect(func():
		if _enemy_sprite.visible and _enemy_sprite.sprite_frames != null:
			if _enemy_sprite.animation in ["attack", "hurt"]:
				_enemy_sprite.play("idle")
	)
	_boss_sprite.animation_finished.connect(func():
		if _boss_sprite.visible and _boss_sprite.sprite_frames != null:
			if _boss_sprite.animation in ["attack", "hurt"]:
				_boss_sprite.play("idle")
	)
	_style_hp_bars()
	_style_combat_ui_panels()
	_init_now_playing_label()
	$MainVBox/BattlefieldArea.resized.connect(_on_battlefield_resized)
	_apply_scene_typography()
	_setup_dungeon_header_icon()
	call_deferred("_setup_combat_sprite_layer")
	var dungeon_id: String = GameState.get_active_dungeon_id()
	if Constants.SUB_STAGES_PLAYABLE:
		var stage_id: String = GameState.resolve_stage_for_run(dungeon_id)
		if not stage_id.is_empty():
			GameState.current_stage_id = stage_id
			$DungeonController.start_stage(stage_id)
		else:
			GameState.current_stage_id = ""
			$DungeonController.start_dungeon(dungeon_id)
	else:
		GameState.current_stage_id = ""
		$DungeonController.start_dungeon(dungeon_id)
	$CombatController.reset_party_hp_for_run()
	GameState.last_run_accessory_dropped = ""
	GameState.last_run_relic_dropped = ""
	GameState.last_run_outcome = ""
	GameState.last_run_starter_recruited_id = ""
	GameState.last_run_starter_recruited_name = ""
	GameState.last_run_exploration_policy = ""
	GameState.last_run_modifier_counts = {}
	GameState.reset_run_combat_stats()
	GameState.begin_run_material_tracking()
	_CommanderLifetime.record_run_started()
	GameState.migrate_formation_slots_if_needed()
	_update_room_label()
	_update_room_art()
	_update_enemy_label()
	_update_hp_bars()
	_update_next_room_button()
	var dungeon_name: String = $DungeonController.get_run_display_name()
	_update_dungeon_header(dungeon_name)
	_setup_weather()
	var weather_suffix: String = ""
	if not GameState.get_weather().is_empty():
		weather_suffix = "（天候: %s）" % CombatWeather.label(GameState.get_weather())
	_set_narrative("%s の探索を開始した%s" % [dungeon_name, weather_suffix])
	if EventSystem.PERIODIC_EVENTS_ENABLED and EventSystem.is_event_running():
		var field_line: String = EventSystem.run_intro_line()
		if not field_line.is_empty():
			_append_log(field_line)
	if not dungeon_id.is_empty():
		_try_register_discovery("dungeon", dungeon_id)
	_update_combat_visibility()
	_apply_combat_speed(SettingsPrefs.get_combat_speed_mult())
	_init_dungeon_presentation_ui()
	_begin_dungeon_dive_intro()

# 天候の可視化（P3-D101）。HUD ラベル併記＋procedural オーバーレイ（新規アセット無し）。
func _setup_weather() -> void:
	var weather: String = GameState.get_weather()
	if weather.is_empty():
		return
	var layer := CanvasLayer.new()
	layer.name = "WeatherLayer"
	layer.layer = 3
	add_child(layer)
	var view: Vector2 = get_viewport_rect().size
	match weather:
		CombatWeather.NIGHT:
			var tint := ColorRect.new()
			tint.color = Color(0.04, 0.06, 0.16, 0.30)
			tint.set_anchors_preset(Control.PRESET_FULL_RECT)
			tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.add_child(tint)
		CombatWeather.FOG:
			var haze := ColorRect.new()
			haze.color = Color(0.76, 0.78, 0.82, 0.16)
			haze.set_anchors_preset(Control.PRESET_FULL_RECT)
			haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.add_child(haze)
			var tw := create_tween().set_loops()
			tw.tween_property(haze, "color:a", 0.24, 2.2).set_trans(Tween.TRANS_SINE)
			tw.tween_property(haze, "color:a", 0.10, 2.2).set_trans(Tween.TRANS_SINE)
		CombatWeather.RAIN:
			var rain := CPUParticles2D.new()
			rain.texture = _make_raindrop_texture()
			rain.amount = 150
			rain.lifetime = 0.7
			rain.local_coords = false
			rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			rain.emission_rect_extents = Vector2(view.x * 0.6, 2.0)
			rain.position = Vector2(view.x * 0.5, -12.0)
			rain.direction = Vector2(0.1, 1.0)
			rain.spread = 4.0
			rain.gravity = Vector2(20.0, 900.0)
			rain.initial_velocity_min = 420.0
			rain.initial_velocity_max = 540.0
			rain.modulate = Color(0.75, 0.82, 1.0, 0.7)
			rain.emitting = true
			layer.add_child(rain)

func _make_raindrop_texture() -> Texture2D:
	var img := Image.create(2, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.8, 0.86, 1.0, 0.55))
	return ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	if _request_scroll_to_bottom:
		_request_scroll_to_bottom = false
		_battle_log_scroll.scroll_vertical = _battle_log_scroll.get_v_scroll_bar().max_value
	_update_party_skill_cd_bars_smooth(delta)
	if $DungeonController.is_combat_room():
		_update_chr_hp_bar_positions()

func _set_narrative(text: String) -> void:
	_combat_now_playing_active = false
	_label_narrative.text = text
	_reset_narrative_typography()

# ---- 戦闘可読性（P3-UX-002: E 今の一手 / F 戦術ログ / G ターン順バッジ） ----

func _update_combat_now_playing_for(kind: String, index: int) -> void:
	if not $DungeonController.is_combat_room() or not $CombatController.is_in_combat:
		return
	var text: String = _build_now_playing_text(kind, index)
	_set_combat_now_playing(text, kind == "enemy")

func _refresh_combat_now_playing_next() -> void:
	if not $DungeonController.is_combat_room() or not $CombatController.is_in_combat:
		return
	var order: Array = $CombatController.get_ct_order()
	if order.is_empty():
		return
	var next: Dictionary = order[0]
	_update_combat_now_playing_for(str(next.get("kind", "")), int(next.get("index", -1)))

func _set_combat_now_playing(_text: String, _is_enemy: bool) -> void:
	# 「◆ XX — 通常攻撃」帯はバトルログと重複するため非表示。
	_combat_now_playing_active = false
	if _label_now_playing != null:
		_label_now_playing.visible = false
		_label_now_playing.text = ""

func _build_now_playing_text(kind: String, index: int) -> String:
	if kind == "party":
		var member: Resource = GameState.get_combatant(index)
		var mname: String = member.display_name if member != null else "?"
		if $CombatController.has_pending_cast("party", index):
			var pending: Dictionary = $CombatController.get_pending_cast("party", index)
			var skill_data: Resource = DataRegistry.get_skill_data(str(pending.get("skill_id", "")))
			var sname: String = skill_data.display_name if skill_data != null else "スキル"
			var left: int = maxi(1, int(pending.get("turns_left", 0)) + 1)
			return "◆ %s — 詠唱中「%s」（あと%d）" % [mname, sname, left]
		if $CombatController.should_member_skip_action_at(index):
			return "◆ %s — 行動不能" % mname
		return "◆ %s — %s" % [mname, _party_action_label(index)]
	var enemy_data: Resource = $CombatController.get_enemy_data_at(index)
	var ename: String = enemy_data.display_name if enemy_data != null else "敵"
	if $CombatController.has_pending_cast("enemy", index):
		var pending_e: Dictionary = $CombatController.get_pending_cast("enemy", index)
		var skill_e: Resource = DataRegistry.get_skill_data(str(pending_e.get("skill_id", "")))
		var esname: String = skill_e.display_name if skill_e != null else "スキル"
		var eleft: int = maxi(1, int(pending_e.get("turns_left", 0)) + 1)
		return "⚠ %s — 【%s】詠唱中！（あと%d）" % [ename, esname, eleft]
	if $CombatController.should_enemy_skip_action_at(index):
		return "⚠ %s — 行動遅延" % ename
	if index == $CombatController.active_enemy_index and _enemy_has_castable_skill(index):
		return "⚠ %s — スキル/攻撃" % ename
	return "⚠ %s — 攻撃" % ename

func _party_action_label(member_idx: int) -> String:
	var badge: String = _party_action_badge(member_idx)
	match badge:
		"必":
			return "必殺技"
		"防":
			return "防御"
		"技":
			return "スキル"
		"攻":
			return "通常攻撃"
		"—":
			return "行動不能"
		_:
			if badge.begins_with("詠"):
				return "詠唱中"
			return "通常攻撃"

func _party_action_badge(member_idx: int) -> String:
	if not $CombatController.is_member_alive(member_idx):
		return ""
	if $CombatController.has_pending_cast("party", member_idx):
		var left: int = maxi(1, int($CombatController.get_pending_cast("party", member_idx).get("turns_left", 0)) + 1)
		return "詠%d" % left
	if $CombatController.should_member_skip_action_at(member_idx):
		return "—"
	var member: Resource = GameState.get_combatant(member_idx)
	var ctx: Dictionary = _build_tactics_context(member_idx)
	for rule: Dictionary in CombatGambit.plan_from_member(member):
		if not CombatTactics.condition_met(rule, ctx):
			continue
		match str(rule.get("slot", "")):
			"ultimate":
				if _is_member_ultimate_ready(member_idx):
					return "必"
			"defend":
				if not _member_has_status(member_idx, "guard"):
					return "防"
			"skill":
				var skill_idx: int = int(rule.get("skill_index", -1))
				if skill_idx >= 0:
					if _member_has_ready_skill_at(member_idx, skill_idx, ctx):
						return "技"
				elif _member_has_ready_skill(member_idx, ctx):
					return "技"
			"attack":
				return "攻"
	return "攻"

func _enemy_action_badge(slot: int) -> String:
	if not $CombatController.is_enemy_slot_alive(slot):
		return ""
	if $CombatController.has_pending_cast("enemy", slot):
		var left: int = maxi(1, int($CombatController.get_pending_cast("enemy", slot).get("turns_left", 0)) + 1)
		return "詠%d" % left
	if $CombatController.should_enemy_skip_action_at(slot):
		return "—"
	if slot == $CombatController.active_enemy_index and _enemy_has_castable_skill(slot):
		return "技"
	return "攻"

func _turn_order_action_badge(kind: String, index: int) -> String:
	if kind == "party":
		return _party_action_badge(index)
	return _enemy_action_badge(index)

func _member_has_ready_skill_at(member_idx: int, skill_index: int, ctx: Dictionary) -> bool:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return false
	var ids: Array[String] = GameState.get_equipped_skill_ids(member)
	if skill_index < 0 or skill_index >= ids.size():
		return false
	var sd: Resource = DataRegistry.get_skill_data(str(ids[skill_index]))
	if sd == null:
		return false
	if not CombatTactics.skill_reserve_met(sd, ctx):
		return false
	return _skill_executor.can_cast(sd, _member_skill_cd_key(member_idx, sd))

func _member_has_ready_skill(member_idx: int, ctx: Dictionary) -> bool:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return false
	for sid: String in GameState.get_equipped_skill_ids(member):
		var sd: Resource = DataRegistry.get_skill_data(sid)
		if sd == null:
			continue
		if not CombatTactics.skill_reserve_met(sd, ctx):
			continue
		if _skill_executor.can_cast(sd, _member_skill_cd_key(member_idx, sd)):
			return true
	var weapon_skill_id: String = WeaponSkillHelper.get_weapon_skill_id(member)
	if weapon_skill_id.is_empty():
		return false
	var wsd: Resource = DataRegistry.get_skill_data(weapon_skill_id)
	if wsd == null:
		return false
	if not CombatTactics.skill_reserve_met(wsd, ctx):
		return false
	return _skill_executor.can_cast(wsd, _member_skill_cd_key(member_idx, wsd))

func _enemy_has_castable_skill(slot: int) -> bool:
	var enemy_data: Resource = $CombatController.get_enemy_data_at(slot)
	if enemy_data == null or enemy_data.skill_ids.is_empty():
		return false
	for sid in enemy_data.skill_ids:
		var sd: Resource = DataRegistry.get_skill_data(str(sid))
		if sd != null and _skill_executor.can_cast(sd, "enemy:%s" % sd.id):
			return true
	return false

func _append_tactics_log(rule: Dictionary, member_idx: int) -> void:
	var member: Resource = GameState.get_combatant(member_idx)
	_append_log("[戦術] %s" % CombatGambit.rule_preview(rule, member))

func _append_tactics_fallback_log(any_condition_met: bool) -> void:
	if any_condition_met:
		_append_log("[戦術] 不発 → 通常攻撃")
	else:
		_append_log("[戦術] 条件未達 → 通常攻撃")

# ---- 戦闘演出横展開（P3-UX-002-D） ----

func _init_combat_drama_ui() -> void:
	if _threat_banner != null and is_instance_valid(_threat_banner):
		return
	var battlefield: Control = $MainVBox/BattlefieldArea
	_threat_vignette = ColorRect.new()
	_threat_vignette.name = "ThreatVignette"
	_threat_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_threat_vignette.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_threat_vignette.grow_vertical = Control.GROW_DIRECTION_BOTH
	_threat_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_threat_vignette.color = Color(0, 0, 0, 0)
	_threat_vignette.z_index = 35
	battlefield.add_child(_threat_vignette)
	_threat_banner = PanelContainer.new()
	_threat_banner.name = "ThreatBanner"
	_threat_banner.visible = false
	_threat_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_threat_banner.z_index = 42
	_threat_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_threat_banner.offset_left = -210.0
	_threat_banner.offset_right = 210.0
	_threat_banner.offset_top = 8.0
	_threat_banner.offset_bottom = 44.0
	_threat_banner.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_THREAT))
	battlefield.add_child(_threat_banner)
	_label_threat_banner = Label.new()
	_label_threat_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_threat_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_threat_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_threat_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_threat_banner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiTypography.apply_display(_label_threat_banner, UiTypography.SIZE_BODY_SMALL, Color(1.0, 0.88, 0.82))
	_threat_banner.add_child(_label_threat_banner)

func _find_enemy_threat_cast() -> Dictionary:
	for slot: int in $CombatController.get_living_enemy_indices():
		if not $CombatController.has_pending_cast("enemy", slot):
			continue
		var pending: Dictionary = $CombatController.get_pending_cast("enemy", slot)
		var skill_data: Resource = DataRegistry.get_skill_data(str(pending.get("skill_id", "")))
		var skill_name: String = skill_data.display_name if skill_data != null else "スキル"
		var left: int = maxi(1, int(pending.get("turns_left", 0)) + 1)
		var enemy_data: Resource = $CombatController.get_enemy_data_at(slot)
		var ename: String = enemy_data.display_name if enemy_data != null else "敵"
		return {
			"slot": slot,
			"skill_name": skill_name,
			"enemy_name": ename,
			"turns_left": left,
		}
	return {}

func _update_combat_threat_banner() -> void:
	if not $CombatController.is_in_combat or not $DungeonController.is_combat_room():
		_hide_combat_threat_banner()
		return
	var threat: Dictionary = _find_enemy_threat_cast()
	if threat.is_empty():
		_hide_combat_threat_banner()
		return
	_init_combat_drama_ui()
	_label_threat_banner.text = "⚠ %s — 【%s】詠唱中！（あと%d）" % [
		threat.get("enemy_name", "敵"),
		threat.get("skill_name", "スキル"),
		int(threat.get("turns_left", 1)),
	]
	_threat_banner.visible = true
	if _threat_vignette != null:
		_threat_vignette.color = CombatUiFrames.vignette_color(CombatUiFrames.TIER_THREAT)
	_start_threat_banner_pulse()

func _hide_combat_threat_banner() -> void:
	_stop_threat_banner_pulse()
	if _threat_banner != null and is_instance_valid(_threat_banner):
		_threat_banner.visible = false
	if _threat_vignette != null and is_instance_valid(_threat_vignette):
		_threat_vignette.color = Color(0, 0, 0, 0)

func _start_threat_banner_pulse() -> void:
	if _threat_banner == null or not is_instance_valid(_threat_banner):
		return
	if _threat_banner_pulse_tween != null and is_instance_valid(_threat_banner_pulse_tween):
		return
	_threat_banner.modulate = Color.WHITE
	_threat_banner_pulse_tween = create_tween().set_loops()
	_threat_banner_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_threat_banner_pulse_tween.tween_property(_threat_banner, "modulate", Color(1.12, 0.82, 0.78), 0.55)
	_threat_banner_pulse_tween.tween_property(_threat_banner, "modulate", Color.WHITE, 0.55)

func _stop_threat_banner_pulse() -> void:
	if _threat_banner_pulse_tween != null and is_instance_valid(_threat_banner_pulse_tween):
		_threat_banner_pulse_tween.kill()
	_threat_banner_pulse_tween = null
	if _threat_banner != null and is_instance_valid(_threat_banner):
		_threat_banner.modulate = Color.WHITE

func _on_enemy_cast_threat_started(slot: int, skill: Resource) -> void:
	if skill == null or float(skill.cast_time) <= 0.0:
		return
	_update_combat_threat_banner()
	_flash_battlefield(Color(1.0, 0.35, 0.28), 0.18)
	_request_combat_shake(8.5)

func _member_hp_ratio(member_idx: int) -> float:
	if member_idx < 0 or member_idx >= $CombatController.party_max_hp.size():
		return 1.0
	var max_hp: int = $CombatController.party_max_hp[member_idx]
	if max_hp <= 0:
		return 1.0
	return float($CombatController.party_combat_hp[member_idx]) / float(max_hp)

func _party_card_visual_tier(member_idx: int, alive: bool) -> String:
	if not alive:
		return CombatUiFrames.TIER_CARD
	if member_idx == _party_card_active_turn:
		return CombatUiFrames.TIER_CARD_ACTIVE
	if _is_member_ultimate_ready(member_idx):
		return CombatUiFrames.TIER_CARD_ULTIMATE
	if _member_hp_ratio(member_idx) <= PARTY_CARD_CRITICAL_HP_RATIO:
		return CombatUiFrames.TIER_CARD_CRITICAL
	return CombatUiFrames.TIER_CARD

func _party_card_state_badge_text(member_idx: int, alive: bool) -> String:
	if not alive:
		return ""
	if _member_hp_ratio(member_idx) <= PARTY_CARD_CRITICAL_HP_RATIO:
		return "瀕死"
	if _is_member_ultimate_ready(member_idx) and member_idx != _party_card_active_turn:
		return "必殺"
	return ""

func _stop_party_card_pulse(member_idx: int) -> void:
	if member_idx < 0 or member_idx >= _party_card_pulse_tweens.size():
		return
	var tw = _party_card_pulse_tweens[member_idx]
	if tw != null and is_instance_valid(tw):
		tw.kill()
	_party_card_pulse_tweens[member_idx] = null
	if member_idx < _party_card_roots.size():
		_party_card_roots[member_idx].modulate = Color.WHITE

func _start_party_card_critical_pulse(member_idx: int) -> void:
	if member_idx < 0 or member_idx >= _party_card_roots.size():
		return
	if member_idx < _party_card_pulse_tweens.size():
		var existing = _party_card_pulse_tweens[member_idx]
		if existing != null and is_instance_valid(existing):
			return
	var card: PanelContainer = _party_card_roots[member_idx]
	_stop_party_card_pulse(member_idx)
	var tw: Tween = create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(card, "modulate", Color(1.08, 0.72, 0.72), 0.65)
	tw.tween_property(card, "modulate", Color.WHITE, 0.65)
	_party_card_pulse_tweens[member_idx] = tw

func _update_party_card_dramatics(member_idx: int, alive: bool) -> void:
	if member_idx >= _party_card_roots.size():
		return
	var tier: String = _party_card_visual_tier(member_idx, alive)
	_party_card_roots[member_idx].add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(tier)
	)
	if member_idx < _party_card_state_badges.size():
		var badge: Label = _party_card_state_badges[member_idx]
		var badge_text: String = _party_card_state_badge_text(member_idx, alive)
		badge.text = badge_text
		badge.visible = not badge_text.is_empty()
	if not alive:
		_stop_party_card_pulse(member_idx)
		return
	if _member_hp_ratio(member_idx) <= PARTY_CARD_CRITICAL_HP_RATIO:
		_start_party_card_critical_pulse(member_idx)
	else:
		_stop_party_card_pulse(member_idx)

func _request_combat_shake(intensity: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < _combat_shake_cooldown_until:
		return
	_combat_shake_cooldown_until = now + COMBAT_SHAKE_COOLDOWN_SEC
	_shake_battlefield(intensity)

func _trigger_combat_impact_feedback(is_critical: bool, damage_value: int) -> void:
	if is_critical:
		_request_combat_shake(COMBAT_CRIT_SHAKE_INTENSITY)
		_flash_battlefield(Color(1.0, 0.85, 0.35), 0.22)
		_maybe_vibrate(40)
	elif damage_value >= COMBAT_BIG_DAMAGE_THRESHOLD:
		_request_combat_shake(COMBAT_BIG_DAMAGE_SHAKE_INTENSITY)
		_maybe_vibrate(25)


func _maybe_vibrate(duration_ms: int) -> void:
	if not SettingsPrefs.is_vibration_enabled():
		return
	Input.vibrate_handheld(duration_ms)

# ---- 潜入演出（P3-UX-003: A/C/B/D/E） ----

func _init_dungeon_presentation_ui() -> void:
	_init_run_hud()
	if _transition_fx_host != null and is_instance_valid(_transition_fx_host):
		return
	_transition_fx_host = Control.new()
	_transition_fx_host.name = "TransitionFxHost"
	_transition_fx_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_fx_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$TransitionLayer.add_child(_transition_fx_host)
	_dive_intro_panel = PanelContainer.new()
	_dive_intro_panel.name = "DiveIntroPanel"
	_dive_intro_panel.visible = false
	_dive_intro_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_dive_intro_panel.set_anchors_preset(Control.PRESET_CENTER)
	_dive_intro_panel.custom_minimum_size = Vector2(640, 420)
	_dive_intro_panel.offset_left = -320.0
	_dive_intro_panel.offset_top = -210.0
	_dive_intro_panel.offset_right = 320.0
	_dive_intro_panel.offset_bottom = 210.0
	_dive_intro_panel.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_BOSS))
	_dive_intro_panel.gui_input.connect(_on_dive_intro_gui_input)
	$TransitionLayer.add_child(_dive_intro_panel)

func _init_run_hud() -> void:
	if _run_hud_panel != null and is_instance_valid(_run_hud_panel):
		return
	_run_hud_panel = PanelContainer.new()
	_run_hud_panel.name = "RunHudPanel"
	_run_hud_panel.visible = false
	_run_hud_panel.custom_minimum_size = Vector2(0, RUN_HUD_HEIGHT)
	_run_hud_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	_run_hud_panel.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL))
	var row := MarginContainer.new()
	row.add_theme_constant_override("margin_left", 10)
	row.add_theme_constant_override("margin_right", 10)
	row.add_theme_constant_override("margin_top", 4)
	row.add_theme_constant_override("margin_bottom", 4)
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	_run_hud_floor_label = Label.new()
	_run_hud_floor_label.custom_minimum_size = Vector2(52, 0)
	UiTypography.apply_body(_run_hud_floor_label, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	_run_hud_progress = ProgressBar.new()
	_run_hud_progress.show_percentage = false
	_run_hud_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_run_hud_progress.custom_minimum_size = Vector2(120, 12)
	_style_hp_bar_readable(_run_hud_progress, Color(0.82, 0.68, 0.28))
	_run_hud_room_chip = Label.new()
	_run_hud_room_chip.custom_minimum_size = Vector2(64, 0)
	_run_hud_room_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(_run_hud_room_chip, UiTypography.SIZE_CAPTION, Color(0.95, 0.92, 0.84))
	_run_hud_discovery = Label.new()
	_run_hud_discovery.custom_minimum_size = Vector2(72, 0)
	_run_hud_discovery.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_body(_run_hud_discovery, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	row.add_child(inner)
	inner.add_child(_run_hud_floor_label)
	inner.add_child(_run_hud_progress)
	inner.add_child(_run_hud_room_chip)
	inner.add_child(_run_hud_discovery)
	_run_hud_panel.add_child(row)
	$MainVBox.add_child(_run_hud_panel)
	$MainVBox.move_child(_run_hud_panel, $MainVBox/BattlefieldArea.get_index())

func _run_discovery_percent() -> int:
	var dungeon_id: String = GameState.get_active_dungeon_id()
	var prog: Dictionary = GameState.dungeon_progress.get(dungeon_id, {})
	return int(round(float(prog.get("discovery", 0.0)) * 100.0))

func _room_type_chip_color(room_type: int) -> Color:
	match room_type:
		Enums.RoomType.ELITE:
			return Color(1.0, 0.7, 0.2)
		Enums.RoomType.TRAP:
			return Color(1.0, 0.45, 0.25)
		Enums.RoomType.BOSS:
			return Color(1.0, 0.35, 0.35)
		Enums.RoomType.TREASURE:
			return Color(1.0, 0.86, 0.35)
		Enums.RoomType.HEAL:
			return Color(0.55, 0.95, 0.62)
		Enums.RoomType.EXIT:
			return Color(0.55, 0.78, 1.0)
		Enums.RoomType.EVENT:
			return Color(0.78, 0.72, 1.0)
		_:
			return Color(0.92, 0.9, 0.84)

func _update_run_hud() -> void:
	if _run_hud_panel == null:
		return
	if $DungeonController.current_dungeon_data == null:
		_run_hud_panel.visible = false
		return
	_run_hud_panel.visible = true
	var floor_current: int = $DungeonController.get_display_floor_current()
	var floor_max: int = $DungeonController.get_display_floor_max()
	var floor_text: String = $DungeonController.get_display_floor_text()
	_run_hud_floor_label.text = floor_text
	_run_hud_progress.max_value = float(floor_max)
	_run_hud_progress.value = float(floor_current)
	var room_type: int = $DungeonController.current_room_type
	_run_hud_room_chip.text = "[%s]" % _get_room_type_name()
	UiTypography.apply_display(
		_run_hud_room_chip,
		UiTypography.SIZE_CAPTION,
		_room_type_chip_color(room_type)
	)
	_run_hud_discovery.text = "発見 %d%%" % _run_discovery_percent()

func _dungeon_meta_line(data: Resource) -> String:
	var parts: PackedStringArray = []
	var stage: Resource = $DungeonController.current_stage_data
	if GameState.current_dungeon_tier != _DungeonTierConfig.TIER_NORMAL:
		parts.append(_DungeonTierConfig.display_name(GameState.current_dungeon_tier))
	else:
		parts.append("ノーマル")
	var recommended: int = $DungeonController.get_run_recommended_level()
	if recommended > 0:
		parts.append("推奨Lv.%d" % recommended)
	if stage != null:
		parts.append("%dF" % int(stage.floor_count))
		if bool(stage.has_boss_floor()):
			parts.append("ボス")
		elif bool(stage.requires_elite):
			parts.append("エリート")
	elif data != null and int(data.recommended_level) > 0:
		var dungeon_rec: int = _DungeonTierConfig.apply_tier_level(
			int(data.recommended_level), GameState.current_dungeon_tier
		)
		parts.append("推奨Lv.%d〜" % dungeon_rec)
	if not GameState.get_weather().is_empty():
		parts.append("天候:%s" % CombatWeather.label(GameState.get_weather()))
	return " · ".join(parts)

func _run_location_prefix() -> String:
	var chapter: String = $DungeonController.get_run_chapter_label()
	if not chapter.is_empty():
		return chapter
	if GameState.current_dungeon_tier != _DungeonTierConfig.TIER_NORMAL:
		return _DungeonTierConfig.display_name(GameState.current_dungeon_tier)
	return "B1"

func _begin_dungeon_dive_intro() -> void:
	_init_dungeon_presentation_ui()
	_dive_intro_active = true
	$AutoProgressTimer.stop()
	_clear_transition_fx()
	_label_transition.text = ""
	_transition_overlay.modulate.a = 0.0
	_dive_intro_panel.visible = true
	_dive_intro_panel.modulate.a = 0.0
	for c in _dive_intro_panel.get_children():
		c.queue_free()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dive_intro_panel.add_child(root)
	var data: Resource = $DungeonController.current_dungeon_data
	var stage: Resource = $DungeonController.current_stage_data
	var dungeon_id: String = GameState.get_active_dungeon_id()
	var banner := TextureRect.new()
	banner.custom_minimum_size = Vector2(600, 140)
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var stage_id: String = GameState.get_active_stage_id()
	var stage_tex: Texture2D = IconPaths.get_stage_icon_texture(stage_id)
	if stage_tex != null:
		banner.texture = stage_tex
	else:
		var thumb: Texture2D = IconPaths.get_icon_texture(dungeon_id, "dungeon")
		if thumb != null:
			banner.texture = thumb
	root.add_child(banner)
	var name_lbl := Label.new()
	if stage != null and data != null:
		name_lbl.text = "%s — %s" % [str(data.display_name), str(stage.display_name)]
	elif data != null:
		name_lbl.text = str(data.display_name)
	else:
		name_lbl.text = "ダンジョン"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(name_lbl, UiTypography.SIZE_DISPLAY, UiTypography.COLOR_GOLD)
	root.add_child(name_lbl)
	if stage != null:
		var chapter_lbl := Label.new()
		chapter_lbl.text = $DungeonController.get_run_display_name()
		chapter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTypography.apply_body(chapter_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
		root.add_child(chapter_lbl)
	if data != null and not str(data.flavor_text).is_empty():
		var flavor := Label.new()
		flavor.text = str(data.flavor_text)
		flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTypography.apply_body(flavor, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB)
		root.add_child(flavor)
	var meta := Label.new()
	meta.text = _dungeon_meta_line(data) if data != null else ""
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(meta, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	root.add_child(meta)
	var party_row := HBoxContainer.new()
	party_row.alignment = BoxContainer.ALIGNMENT_CENTER
	party_row.add_theme_constant_override("separation", 10)
	root.add_child(party_row)
	for slot: int in PARTY_CARD_SLOT_COUNT:
		if slot >= GameState.party_members.size():
			continue
		var member: Resource = GameState.party_members[slot]
		if member == null:
			continue
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.modulate.a = 0.0
		icon.scale = Vector2(0.88, 0.88)
		var tex: Texture2D = _get_member_icon_texture(member)
		if tex != null:
			icon.texture = tex
		party_row.add_child(icon)
		var slide_tw: Tween = create_tween()
		slide_tw.tween_interval(0.12 + float(slot) * 0.08)
		slide_tw.set_parallel(true)
		slide_tw.tween_property(icon, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		slide_tw.tween_property(icon, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var start_lbl := Label.new()
	start_lbl.text = "探索開始"
	start_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_lbl.modulate.a = 0.0
	UiTypography.apply_display(start_lbl, UiTypography.SIZE_BODY, Color(1.0, 0.92, 0.55))
	root.add_child(start_lbl)
	if _dive_intro_tween != null and is_instance_valid(_dive_intro_tween):
		_dive_intro_tween.kill()
	_dive_intro_tween = create_tween()
	_dive_intro_tween.tween_property(_transition_overlay, "modulate:a", 1.0, DIVE_INTRO_FADE_SEC)
	_dive_intro_tween.parallel().tween_property(_dive_intro_panel, "modulate:a", 1.0, DIVE_INTRO_FADE_SEC)
	_dive_intro_tween.tween_interval(DIVE_INTRO_HOLD_SEC)
	_dive_intro_tween.tween_property(start_lbl, "modulate:a", 1.0, 0.18)
	_dive_intro_tween.tween_interval(DIVE_INTRO_START_SEC)
	_dive_intro_tween.tween_property(_transition_overlay, "modulate:a", 0.0, DIVE_INTRO_FADE_SEC)
	_dive_intro_tween.parallel().tween_property(_dive_intro_panel, "modulate:a", 0.0, DIVE_INTRO_FADE_SEC)
	_dive_intro_tween.tween_callback(_finish_dungeon_dive_intro)

func _on_dive_intro_gui_input(event: InputEvent) -> void:
	if not _dive_intro_active:
		return
	if event is InputEventMouseButton and event.pressed:
		_skip_dungeon_dive_intro()
	elif event is InputEventScreenTouch and event.pressed:
		_skip_dungeon_dive_intro()

func _skip_dungeon_dive_intro() -> void:
	if not _dive_intro_active:
		return
	if _dive_intro_tween != null and is_instance_valid(_dive_intro_tween):
		_dive_intro_tween.kill()
	_finish_dungeon_dive_intro()

func _finish_dungeon_dive_intro() -> void:
	_dive_intro_active = false
	_dive_intro_tween = null
	if _dive_intro_panel != null and is_instance_valid(_dive_intro_panel):
		_dive_intro_panel.visible = false
	_transition_overlay.modulate.a = 0.0
	_update_run_hud()
	_transition_to_current_room()

func _transition_to_current_room() -> void:
	if _room_transition_busy or _dive_intro_active or _combat_clear_active:
		return
	_room_transition_busy = true
	$AutoProgressTimer.stop()
	var tw: Tween = create_tween()
	tw.tween_property(_transition_overlay, "modulate:a", 1.0, 0.2)
	tw.tween_callback(_on_current_room_transition_midpoint)

func _on_current_room_transition_midpoint() -> void:
	_enter_current_room()
	_label_transition.text = _room_transition_caption()
	_play_room_transition_fx($DungeonController.current_room_type)
	var timing: Dictionary = _room_transition_timing($DungeonController.current_room_type)
	var hold: float = float(timing.get("hold", 0.55))
	var fade: float = float(timing.get("fade", 0.2))
	var tw: Tween = create_tween()
	tw.tween_interval(hold)
	tw.tween_property(_transition_overlay, "modulate:a", 0.0, fade)
	tw.tween_callback(_on_room_transition_finished)

func _room_transition_timing(room_type: int) -> Dictionary:
	match room_type:
		Enums.RoomType.BOSS, Enums.RoomType.ELITE:
			return {"fade": 0.28, "hold": 0.85}
		Enums.RoomType.TREASURE, Enums.RoomType.EXIT:
			return {"fade": 0.24, "hold": 0.72}
		Enums.RoomType.TRAP:
			return {"fade": 0.18, "hold": 0.42}
		_:
			return {"fade": 0.2, "hold": 0.55}


func _sync_room_bgm() -> void:
	## 非戦闘・探索中 = dungeon_explore。戦闘 = battle / boss。
	if not $DungeonController.is_combat_room():
		AudioManager.play_bgm("dungeon_explore")
		return
	if $DungeonController.current_room_type == Enums.RoomType.BOSS:
		AudioManager.play_bgm("boss")
	else:
		AudioManager.play_bgm("battle")

func _room_transition_caption() -> String:
	var floor_text: String = $DungeonController.get_display_floor_text()
	return "[%s]\n%s" % [_get_room_type_name(), floor_text]

func _room_transition_label_color(room_type: int) -> Color:
	return _room_type_chip_color(room_type)

func _clear_transition_fx() -> void:
	if _transition_fx_host == null or not is_instance_valid(_transition_fx_host):
		return
	for c in _transition_fx_host.get_children():
		c.queue_free()

func _spawn_transition_sparkles(color: Color, amount: int = 36, at_global: Variant = null) -> void:
	if _transition_fx_host == null:
		return
	var parts := CPUParticles2D.new()
	parts.amount = amount
	parts.lifetime = 0.65
	parts.one_shot = true
	parts.explosiveness = 0.92
	parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	parts.emission_sphere_radius = 18.0
	if at_global == null:
		parts.position = get_viewport_rect().size * 0.5
	else:
		parts.global_position = at_global as Vector2
	parts.direction = Vector2(0, -1)
	parts.spread = 180.0
	parts.gravity = Vector2(0, 120.0)
	parts.initial_velocity_min = 80.0
	parts.initial_velocity_max = 180.0
	parts.modulate = color
	_transition_fx_host.add_child(parts)
	parts.emitting = true
	parts.finished.connect(parts.queue_free)

func _spawn_transition_party_silhouettes() -> void:
	if _transition_fx_host == null:
		return
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_bottom = -120.0
	row.offset_top = -200.0
	_transition_fx_host.add_child(row)
	for slot: int in PARTY_CARD_SLOT_COUNT:
		if slot >= GameState.party_members.size():
			continue
		var member: Resource = GameState.party_members[slot]
		if member == null or not $CombatController.is_member_alive(slot):
			continue
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(64, 64)
		icon.modulate = Color(1, 1, 1, 0.55)
		var tex: Texture2D = _get_member_icon_texture(member)
		if tex != null:
			icon.texture = tex
		row.add_child(icon)
	var tw: Tween = create_tween()
	row.modulate.a = 0.0
	row.position.x = -40.0
	tw.set_parallel(true)
	tw.tween_property(row, "modulate:a", 1.0, 0.22)
	tw.tween_property(row, "position:x", 0.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _play_room_transition_fx(room_type: int) -> void:
	_clear_transition_fx()
	UiTypography.apply_display(
		_label_transition,
		UiTypography.SIZE_DISPLAY_TITLE,
		_room_transition_label_color(room_type)
	)
	match room_type:
		Enums.RoomType.COMBAT:
			pass
		Enums.RoomType.ELITE:
			_spawn_transition_sparkles(Color(1.0, 0.78, 0.28), 32)
			_transition_overlay.color = Color(0.12, 0.06, 0.02, 1.0)
		Enums.RoomType.BOSS:
			_update_combat_tier_frame()
			_start_tier_frame_pulse()
			_transition_overlay.color = Color(0.08, 0.02, 0.02, 1.0)
		Enums.RoomType.TREASURE:
			_spawn_transition_sparkles(Color(1.0, 0.86, 0.28), 48)
		Enums.RoomType.EVENT:
			_spawn_transition_sparkles(Color(0.72, 0.68, 1.0), 24)
		Enums.RoomType.TRAP:
			_transition_overlay.color = Color(0.22, 0.03, 0.03, 1.0)
			_flash_battlefield(Color(1.0, 0.25, 0.2), 0.28)
		Enums.RoomType.HEAL:
			_transition_overlay.color = Color(0.02, 0.12, 0.06, 1.0)
			_spawn_transition_sparkles(Color(0.45, 0.95, 0.55), 28)
		Enums.RoomType.EXIT:
			_transition_overlay.color = Color(0.03, 0.08, 0.18, 1.0)
		_:
			_transition_overlay.color = Color(0.02, 0.02, 0.05, 1.0)

func _restore_transition_overlay_color() -> void:
	_transition_overlay.color = Color(0.02, 0.02, 0.05, 1.0)
	_stop_tier_frame_pulse()

func _on_room_transition_midpoint() -> void:
	_advance_to_next_room()
	_label_transition.text = _room_transition_caption()
	_play_room_transition_fx($DungeonController.current_room_type)
	var timing: Dictionary = _room_transition_timing($DungeonController.current_room_type)
	var hold: float = float(timing.get("hold", 0.55))
	var fade: float = float(timing.get("fade", 0.2))
	var tw: Tween = create_tween()
	tw.tween_interval(hold)
	tw.tween_property(_transition_overlay, "modulate:a", 0.0, fade)
	tw.tween_callback(_on_room_transition_finished)

func _on_room_transition_finished() -> void:
	_restore_transition_overlay_color()
	_clear_transition_fx()
	_room_transition_busy = false
	_update_run_hud()
	if not $CombatController.is_in_combat and not _auto_progress_finishes:
		if _room_handles_own_progression($DungeonController.current_room_type):
			return
		_start_auto_progress()

# 戦闘可読性（P3-UX-001）: ログ行に現れる補正マーカーをラン単位で集計する。
# Result の「効いた戦闘要素」の材料。キー=ログ内マーカー / 値=表示ラベル。
const RUN_MODIFIER_MARKERS: Dictionary = {
	"[弱点:": "弱点属性",
	"[特効:": "生態特効",
	"[シナジー:": "属性シナジー",
	"[地形:": "地形相性",
	"[天候:": "天候補正",
	"[防御DOWN]": "防御DOWN",
	"[コンボ]": "状態コンボ",
	"[連携]": "パーティ連携",
	"[パッシブ]": "パッシブ",
	"[レリック]": "レリック",
	"【必殺】": "必殺技",
}

func _record_run_modifiers(line: String) -> void:
	for marker: String in RUN_MODIFIER_MARKERS:
		if line.contains(marker):
			GameState.record_run_modifier(RUN_MODIFIER_MARKERS[marker])

func _append_log(text: String) -> void:
	for line: String in text.split("\n"):
		if line.is_empty():
			continue
		_record_run_modifiers(line)
		if not SettingsPrefs.show_battle_log():
			continue
		var entry := RichTextLabel.new()
		entry.bbcode_enabled = true
		entry.fit_content = true
		entry.scroll_active = false
		# 日本語は単語境界がなく AUTOWRAP_WORD では折り返せない行が出る
		entry.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		UiTypography.apply_log_rich(entry)
		entry.text = _format_log_line_bbcode(line)
		_prepare_battle_log_entry(entry)
		_battle_log_content.add_child(entry)
	# 上限超過分を間引く。queue_free() は遅延削除で get_child_count() が即座に減らず
	# while が無限ループ→フリーズするため、remove_child() で即時 detach してから解放する。
	while _battle_log_content.get_child_count() > _LOG_MAX:
		var oldest: Node = _battle_log_content.get_child(0)
		_battle_log_content.remove_child(oldest)
		oldest.queue_free()
	_request_scroll_to_bottom = true
	call_deferred("_refit_all_battle_log_entries")

func _append_trap_hit_log(line: String) -> void:
	if line.is_empty():
		return
	_record_run_modifiers(line)
	if not SettingsPrefs.show_battle_log():
		return
	var entry := RichTextLabel.new()
	entry.bbcode_enabled = true
	entry.fit_content = true
	entry.scroll_active = false
	entry.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiTypography.apply_log_rich(entry, UiTypography.SIZE_LOG + 2)
	entry.text = "[b]%s[/b]" % _format_log_line_bbcode(line)
	_prepare_battle_log_entry(entry)
	_battle_log_content.add_child(entry)
	while _battle_log_content.get_child_count() > _LOG_MAX:
		var oldest: Node = _battle_log_content.get_child(0)
		_battle_log_content.remove_child(oldest)
		oldest.queue_free()
	_request_scroll_to_bottom = true
	call_deferred("_refit_all_battle_log_entries")

func _log_color_hex(color: Color) -> String:
	return "#" + color.to_html(false)

func _battle_log_entry_width() -> float:
	if _battle_log_scroll == null:
		return 0.0
	var width: float = _battle_log_scroll.size.x
	var margin: MarginContainer = _battle_log_scroll.get_node_or_null("BattleLogMargin") as MarginContainer
	if margin != null:
		width -= float(margin.get_theme_constant("margin_left"))
		width -= float(margin.get_theme_constant("margin_right"))
	var panel_style: StyleBox = _battle_log_panel.get_theme_stylebox("panel") if _battle_log_panel != null else null
	if panel_style != null:
		width -= panel_style.get_margin(Side.SIDE_LEFT)
		width -= panel_style.get_margin(Side.SIDE_RIGHT)
	return maxf(32.0, width)

func _prepare_battle_log_entry(entry: RichTextLabel) -> void:
	var width: float = _battle_log_entry_width()
	entry.custom_minimum_size.x = width
	entry.reset_size()

func _refit_all_battle_log_entries() -> void:
	if _battle_log_content == null:
		return
	for child in _battle_log_content.get_children():
		if child is RichTextLabel:
			_prepare_battle_log_entry(child as RichTextLabel)

func _battlefield_size() -> Vector2:
	var bf: Control = $MainVBox/BattlefieldArea
	return bf.size if bf != null else Vector2.ZERO

func _battlefield_combat_position(ratio: Vector2) -> Vector2:
	var size: Vector2 = _battlefield_size()
	if size.x <= 1.0 or size.y <= 1.0:
		return Vector2.ZERO
	var y_ratio: float = clampf(ratio.y + COMBAT_Y_BIAS, 0.0, 0.96)
	return Vector2(size.x * ratio.x, size.y * y_ratio)


func _enemy_swarm_y_ratio() -> float:
	if $DungeonController.current_room_type == Enums.RoomType.ELITE:
		return ELITE_Y_RATIO
	return SWARM_Y_RATIO

func _global_to_root_pos(global_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_pos

func _sprite_center_in_root(sprite: Node2D) -> Vector2:
	return _global_to_root_pos(sprite.global_position + sprite.offset)

func _sprite_top_y_in_root(sprite: AnimatedSprite2D) -> float:
	var local_top: float = _sprite_visible_top_y(sprite)
	return _global_to_root_pos(
		sprite.global_position + Vector2(0.0, local_top - sprite.position.y)
	).y

func _formation_slot_position(slot: int) -> Vector2:
	if slot < 0 or slot >= FORMATION_SLOT_RATIOS.size():
		return Vector2.ZERO
	return _battlefield_combat_position(FORMATION_SLOT_RATIOS[slot])

func _init_now_playing_label() -> void:
	if _label_now_playing != null and is_instance_valid(_label_now_playing):
		return
	_label_now_playing = Label.new()
	_label_now_playing.name = "LabelNowPlaying"
	_label_now_playing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_now_playing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_now_playing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_now_playing.visible = false
	_auto_combat_row.add_child(_label_now_playing)
	_auto_combat_row.move_child(_label_now_playing, 1)

func _update_dungeon_header(dungeon_name: String) -> void:
	_label_dungeon_name.text = dungeon_name
	_label_room.visible = false
	var dungeon_id: String = GameState.get_active_dungeon_id()
	_update_dungeon_header_icon(dungeon_id)

func _setup_combat_sprite_layer() -> void:
	if _combat_sprites_host != null and is_instance_valid(_combat_sprites_host):
		return
	var bf: Control = $MainVBox/BattlefieldArea
	bf.clip_contents = true
	_combat_sprites_host = Node2D.new()
	_combat_sprites_host.name = "CombatSprites"
	bf.add_child(_combat_sprites_host)
	var nodes: Array[Node2D] = [
		_boss_sprite, _enemy_sprite, _hit_vfx_sprite, _heal_vfx_sprite,
	]
	nodes.append_array(_chr_sprites)
	for node: Node2D in nodes:
		if node == null or not is_instance_valid(node):
			continue
		var gp: Vector2 = node.global_position
		node.reparent(_combat_sprites_host)
		node.position = _combat_sprites_host.to_local(gp)
	if $DungeonController.is_combat_room():
		_on_battlefield_resized()

func _on_battlefield_resized() -> void:
	var bf_size: Vector2 = _battlefield_size()
	if bf_size.y < 8.0:
		return
	for i in GameState.combatant_count():
		if i >= _chr_sprites.size():
			break
		var sprite: AnimatedSprite2D = _chr_sprites[i]
		if not sprite.visible:
			continue
		var slot: int = _formation_slot_for_combat_index(i)
		sprite.position = _formation_slot_position(slot)
	_reposition_enemy_sprites()
	_update_chr_hp_bar_positions()
	_update_status_icons()
	_layout_turn_order_columns()

func _wrap_log_color(text: String, color: Color) -> String:
	return "[color=%s]%s[/color]" % [_log_color_hex(color), text]

func _party_log_color(member: Resource) -> Color:
	return PartyLogColorsScript.party_color(member)

func _enemy_log_color_for_id(enemy_id: String) -> Color:
	match str(LOG_ENEMY_TIER_BY_ID.get(enemy_id, "normal")):
		"boss":
			return LOG_ENEMY_BOSS
		"elite":
			return LOG_ENEMY_ELITE
		_:
			return LOG_ENEMY_NORMAL

func _collect_log_party_name_entries() -> Array:
	var entries: Array = []
	for i: int in GameState.combatant_count():
		var member: Resource = GameState.get_combatant(i)
		if member == null or member.display_name.is_empty():
			continue
		entries.append({
			"name": member.display_name,
			"color": _party_log_color(member),
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a["name"]).length() > str(b["name"]).length()
	)
	return entries

func _collect_log_enemy_name_entries() -> Array:
	var seen: Dictionary = {}
	var entries: Array = []
	for data: Resource in DataRegistry.get_all_enemy_data():
		if data == null or data.display_name.is_empty():
			continue
		var eid: String = str(data.id)
		if seen.has(eid):
			continue
		seen[eid] = true
		entries.append({
			"name": data.display_name,
			"color": _enemy_log_color_for_id(eid),
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a["name"]).length() > str(b["name"]).length()
	)
	return entries

func _color_log_names(line: String, entries: Array) -> String:
	var out: String = line
	for entry: Dictionary in entries:
		var name: String = str(entry.get("name", ""))
		if name.length() < 2 or not out.contains(name):
			continue
		var wrapped: String = _wrap_log_color(name, entry.get("color", LOG_MUTED))
		out = out.replace(name, wrapped)
	return out

func _regex_color_capture(text: String, pattern: String, color: Color, group: int = 1) -> String:
	var re := RegEx.new()
	if re.compile(pattern) != OK:
		return text
	var out: String = ""
	var last: int = 0
	for m: RegExMatch in re.search_all(text):
		var start: int = m.get_start(group)
		if start < 0:
			continue
		out += text.substr(last, start - last)
		out += _wrap_log_color(m.get_string(group), color)
		last = m.get_end(group)
	out += text.substr(last)
	return out

func _color_log_numbers(line: String, incoming: bool, crit: bool) -> String:
	var dmg_color: Color = LOG_DAMAGE_CRIT if crit else (LOG_DAMAGE_IN if incoming else LOG_DAMAGE_OUT)
	var out: String = line
	out = _regex_color_capture(out, "（軽減(\\d+)）", LOG_MUTED, 1)
	out = _regex_color_capture(out, "(\\d+)回復", LOG_HEAL, 1)
	out = _regex_color_capture(out, "\\+(\\d+)", LOG_DAMAGE_OUT, 1)
	out = _regex_color_capture(out, "(\\d+)\\s*ダメージ", dmg_color, 1)
	out = _regex_color_capture(out, "(\\d+)（撃破）", dmg_color, 1)
	if incoming:
		out = _regex_color_capture(out, " に (\\d+)", dmg_color, 1)
	return out

func _color_log_tags(line: String) -> String:
	var out: String = line
	for tag: String in LOG_BRACKET_TAGS:
		if out.contains(tag):
			out = out.replace(tag, _wrap_log_color(tag, LOG_TAG))
	if out.contains("CRITICAL!"):
		out = out.replace("CRITICAL!", _wrap_log_color("CRITICAL!", LOG_DAMAGE_CRIT))
	return out

func _log_line_incoming_damage(line: String) -> bool:
	if line.begins_with("敵の攻撃"):
		return true
	if (line.begins_with("[探索]") or line.begins_with("[罠]")) and "ダメージ" in line:
		return true
	if line.begins_with("  ") and " に " in line:
		return true
	return false

func _format_log_line_bbcode(line: String) -> String:
	var incoming: bool = _log_line_incoming_damage(line)
	var crit: bool = "CRITICAL" in line
	var formatted: String = _color_log_tags(line)
	formatted = _color_log_numbers(formatted, incoming, crit)
	formatted = _color_log_names(formatted, _collect_log_party_name_entries())
	formatted = _color_log_names(formatted, _collect_log_enemy_name_entries())
	return formatted

func _style_hp_bars() -> void:
	_style_hp_bar_readable(_hp_bar_enemy, Color(0.85, 0.25, 0.25))
	_apply_combat_overlay_z(_hp_bar_enemy)
	for bar: ProgressBar in _chr_hp_bars:
		_style_hp_bar_readable(bar, Color(0.25, 0.82, 0.32))
		_apply_combat_overlay_z(bar)
	_style_enemy_nameplate(_enemy_nameplate)
	_apply_combat_overlay_z(_enemy_nameplate, 1)

func _apply_combat_overlay_z(node: CanvasItem, z_offset: int = 0) -> void:
	node.z_index = COMBAT_OVERLAY_Z + z_offset

func _style_hp_bar_readable(bar: ProgressBar, fill_color: Color) -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.06, 0.06, 0.08, 0.9)
	bg_style.set_border_width_all(1)
	bg_style.border_color = Color(0, 0, 0, 0.95)
	bg_style.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg_style)

func _style_readable_label(label: Label, color: Color, outline_size: int = UiTypography.OUTLINE_BODY) -> void:
	UiTypography.apply_body(label, UiTypography.SIZE_BODY_SMALL, color, outline_size)

func _style_enemy_nameplate(label: Label) -> void:
	UiTypography.apply_display(label, UiTypography.SIZE_BODY_SMALL, Color(1.0, 0.97, 0.88, 1.0), UiTypography.OUTLINE_STRONG)
	label.clip_text = false
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING

func _nameplate_half_width(text: String, font_size: int) -> float:
	const MIN_HALF: float = 72.0
	const MAX_HALF: float = 340.0
	const PAD: float = 14.0
	var font: Font = UiTypography.display_font()
	if font == null:
		return clampf(float(text.length()) * float(font_size) * 0.35, MIN_HALF, MAX_HALF)
	var sz: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	return clampf(sz.x * 0.5 + PAD, MIN_HALF, MAX_HALF)

func _setup_dungeon_header_icon() -> void:
	var header: HBoxContainer = $MainVBox/HeaderBar
	_dungeon_header_icon = TextureRect.new()
	_dungeon_header_icon.name = "DungeonHeaderIcon"
	_dungeon_header_icon.custom_minimum_size = Vector2(40, 40)
	_dungeon_header_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dungeon_header_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dungeon_header_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dungeon_header_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_dungeon_header_icon)
	header.move_child(_dungeon_header_icon, _label_dungeon_name.get_index())

func _update_dungeon_header_icon(dungeon_id: String) -> void:
	if _dungeon_header_icon == null:
		return
	var tex: Texture2D = IconPaths.get_icon_texture(dungeon_id, "dungeon")
	if tex == null:
		tex = IconPaths.get_icon_texture(Constants.MOURNGATE_DUNGEON_ID, "dungeon")
	_dungeon_header_icon.texture = tex
	_dungeon_header_icon.visible = tex != null

func _apply_scene_typography() -> void:
	UiTypography.apply_body(_label_dungeon_name, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	_label_dungeon_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_dungeon_name.clip_text = true
	_label_dungeon_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label_room.visible = false
	UiTypography.apply_body(_label_narrative, UiTypography.SIZE_BODY_SMALL)
	UiTypography.apply_display(_label_combat_tier, UiTypography.SIZE_DISPLAY_TITLE)
	UiTypography.apply_body(_label_enemy, UiTypography.SIZE_BODY_SMALL)
	UiTypography.apply_body(_label_status_enemy, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	UiTypography.apply_body(_label_status_party, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	UiTypography.apply_display(_label_transition, UiTypography.SIZE_DISPLAY_TITLE)
	UiTypography.apply_display(_label_discovery_text, UiTypography.SIZE_BODY_SMALL)
	UiTypography.apply_button($MainVBox/HeaderBar/ButtonMenu, false)
	UiTypography.apply_button($MainVBox/HeaderBar/ButtonSpeedX1, false)
	UiTypography.apply_button($MainVBox/HeaderBar/ButtonSpeedX2, false)
	$MainVBox/HeaderBar/ButtonSpeedX1.toggle_mode = true
	$MainVBox/HeaderBar/ButtonSpeedX2.toggle_mode = true
	UiTypography.apply_button($MainVBox/HeaderBar/ButtonStop, false)
	UiTypography.apply_button($MainVBox/PartyStatusPanel/PartyStatusVBox/AutoCombatRow/ButtonPause, false)
	_style_enemy_nameplate(_enemy_nameplate)

func _update_hp_bars() -> void:
	var in_combat: bool = $CombatController.is_in_combat
	var on_combat_floor: bool = $DungeonController.is_combat_room()
	if _boss_sprite.visible:
		# ボス: 単体オーバーレイ
		_hp_bar_enemy.visible = in_combat
		if _hp_bar_enemy.visible:
			_hp_bar_enemy.max_value = $CombatController.get_enemy_max_hp()
			_hp_bar_enemy.value = $CombatController.current_enemy_hp
			_position_enemy_overlays(_boss_sprite)
		else:
			_enemy_nameplate.visible = false
	else:
		# 通常/群れ: スロットごとに HPバー＋ネームプレートを更新（死亡スロットは隠す）
		for slot in _swarm_sprites.size():
			var spr: AnimatedSprite2D = _swarm_sprites[slot]
			var bar: ProgressBar = _swarm_hp_bars[slot]
			var np: Label = _swarm_nameplates[slot]
			var alive: bool = $CombatController.is_enemy_slot_alive(slot)
			var show: bool = in_combat and spr.visible and alive
			bar.visible = show
			if show:
				bar.max_value = $CombatController.get_enemy_max_hp_at(slot)
				bar.value = $CombatController.get_enemy_hp_at(slot)
				_position_swarm_overlay(slot)
			else:
				np.visible = false
	for i: int in _chr_hp_bars.size():
		var bar: ProgressBar = _chr_hp_bars[i]
		var sprite: AnimatedSprite2D = _chr_sprites[i]
		bar.visible = sprite.visible and on_combat_floor
		if bar.visible and i < $CombatController.party_combat_hp.size():
			bar.max_value = $CombatController.party_max_hp[i]
			bar.value = $CombatController.party_combat_hp[i]
			_set_hp_bar_above_sprite(bar, sprite, _formation_slot_for_combat_index(i))
	_update_party_cards_hp()
	if in_combat:
		_update_combat_threat_banner()

func _update_chr_hp_bar_positions() -> void:
	for i: int in _chr_hp_bars.size():
		var bar: ProgressBar = _chr_hp_bars[i]
		var sprite: AnimatedSprite2D = _chr_sprites[i]
		if not bar.visible or not sprite.visible:
			continue
		_set_hp_bar_above_sprite(bar, sprite, _formation_slot_for_combat_index(i))

func _chr_hp_bar_row_y_offset(formation_slot: int) -> float:
	if formation_slot <= 1:
		return CHR_HP_BAR_FRONT_Y_OFFSET
	if formation_slot <= 3:
		return CHR_HP_BAR_BACK_Y_OFFSET
	return 0.0

func _chr_hp_bar_top_y(sprite: AnimatedSprite2D, formation_slot: int) -> float:
	return _sprite_visible_top_y(sprite) - CHR_HP_BAR_GAP_ABOVE_SPRITE - CHR_HP_BAR_HEIGHT + _chr_hp_bar_row_y_offset(formation_slot)

func _sprite_visible_top_y(sprite: AnimatedSprite2D) -> float:
	if sprite.sprite_frames == null:
		return sprite.position.y
	var anim: String = sprite.animation
	if not sprite.sprite_frames.has_animation(anim):
		anim = "idle"
	if not sprite.sprite_frames.has_animation(anim):
		return sprite.position.y
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(anim, 0)
	if tex == null:
		return sprite.position.y
	var frame_h: float = float(tex.get_height())
	var top_in_tex: float = 0.0
	var img: Image = tex.get_image()
	if img != null:
		var used: Rect2i = img.get_used_rect()
		if used.size.y > 0:
			top_in_tex = float(used.position.y)
	var center_y: float = _sprite_visual_center(sprite).y
	return center_y - (frame_h * 0.5 - top_in_tex) * absf(sprite.scale.y)

func _sprite_visual_center(sprite: AnimatedSprite2D) -> Vector2:
	return sprite.position + sprite.offset

func _sprite_visual_center_global(sprite: AnimatedSprite2D) -> Vector2:
	return sprite.global_position + sprite.offset

func _sprite_top_y_global(sprite: AnimatedSprite2D) -> float:
	# _sprite_visible_top_y はローカル基準。global へ変換して返す。
	return _sprite_visible_top_y(sprite) + (sprite.global_position.y - sprite.position.y)

func _set_hp_bar_above_sprite(bar: ProgressBar, sprite: AnimatedSprite2D, formation_slot: int = 0) -> void:
	const BAR_HALF_W: float = 40.0
	var center: Vector2 = _sprite_center_in_root(sprite)
	var bar_ty: float = _sprite_top_y_in_root(sprite) - CHR_HP_BAR_GAP_ABOVE_SPRITE - CHR_HP_BAR_HEIGHT + _chr_hp_bar_row_y_offset(formation_slot)
	bar.offset_left = center.x - BAR_HALF_W
	bar.offset_top = bar_ty
	bar.offset_right = center.x + BAR_HALF_W
	bar.offset_bottom = bar_ty + CHR_HP_BAR_HEIGHT

# 注: 以下 _sprite_top_y は offset 補正込み（非透明領域上端基準）
func _sprite_top_y(sprite: AnimatedSprite2D) -> float:
	return _sprite_visible_top_y(sprite)

# 敵HPバー＋頭上ネームプレートを、スプライト実上端の上に積んで配置（重なり回避）。
# 小型敵は従来位置を下限に維持し、大型(ボス)時のみ上方向へ押し上げる。
func _position_enemy_overlays(sprite: AnimatedSprite2D) -> void:
	var is_boss: bool = _boss_sprite.visible
	var bar_half_w: float = 56.0 if is_boss else 40.0
	var bar_height: float = 10.0
	var name_half_w: float = 210.0 if is_boss else 120.0
	var name_height: float = 32.0 if is_boss else 30.0
	var name_font: int = UiTypography.SIZE_DISPLAY if is_boss else UiTypography.SIZE_DISPLAY
	const GAP_ABOVE_SPRITE: float = 12.0
	const GAP_BAR_NAME: float = 6.0
	var center: Vector2 = _sprite_center_in_root(sprite)
	var cx: float = clampf(center.x, name_half_w + 12.0, 720.0 - name_half_w - 12.0)
	var top_y: float = _sprite_top_y_in_root(sprite)
	var bar_ty: float = minf(center.y - 50.0, top_y - GAP_ABOVE_SPRITE - bar_height)
	_hp_bar_enemy.offset_left = cx - bar_half_w
	_hp_bar_enemy.offset_top = bar_ty
	_hp_bar_enemy.offset_right = cx + bar_half_w
	_hp_bar_enemy.offset_bottom = bar_ty + bar_height
	var enemy_data: Resource = $CombatController.current_enemy_data
	if enemy_data == null:
		_enemy_nameplate.visible = false
		return
	var lv: int = $CombatController.enemy_level
	var name_text: String = "Lv%d %s" % [lv, enemy_data.display_name]
	_enemy_nameplate.text = name_text
	_enemy_nameplate.add_theme_font_size_override("font_size", name_font)
	name_half_w = _nameplate_half_width(name_text, name_font)
	cx = clampf(center.x, name_half_w + 12.0, 720.0 - name_half_w - 12.0)
	_hp_bar_enemy.offset_left = cx - bar_half_w
	_hp_bar_enemy.offset_right = cx + bar_half_w
	var name_ty: float = bar_ty - GAP_BAR_NAME - name_height
	_enemy_nameplate.offset_left = cx - name_half_w
	_enemy_nameplate.offset_top = name_ty
	_enemy_nameplate.offset_right = cx + name_half_w
	_enemy_nameplate.offset_bottom = name_ty + name_height
	_enemy_nameplate.visible = true

func _init_status_icon_rows() -> void:
	for _i in _chr_sprites.size():
		var row: HBoxContainer = _make_status_icon_row()
		add_child(row)
		_status_icon_chr_rows.append(row)

func _ensure_swarm_status_icon_rows(n: int) -> void:
	while _status_icon_swarm_rows.size() < n:
		var row: HBoxContainer = _make_status_icon_row()
		add_child(row)
		_status_icon_swarm_rows.append(row)

func _make_status_icon_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(STATUS_ICON_GAP))
	row.visible = false
	return row

func _build_status_icon(entry: Dictionary) -> PanelContainer:
	var effect_id: String = entry.get("effect_id", "")
	var def: Dictionary = STATUS_ICON_DEF.get(effect_id, {"abbrev": "?", "color": Color(0.45, 0.45, 0.45)})
	var stacks: int = int(entry.get("stacks", 1))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
	var icon_tex: Texture2D = IconPaths.get_icon_texture(effect_id, "status")
	if icon_tex != null:
		var style := StyleBoxEmpty.new()
		panel.add_theme_stylebox_override("panel", style)
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(STATUS_ICON_SIZE, STATUS_ICON_SIZE)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)
	else:
		var abbrev: String = def["abbrev"]
		if stacks > 1:
			abbrev += str(stacks)
		var style := StyleBoxFlat.new()
		style.bg_color = def["color"]
		style.set_corner_radius_all(4)
		style.set_border_width_all(1)
		style.border_color = Color(0, 0, 0, 0.85)
		panel.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.text = abbrev
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.add_child(label)
	if stacks > 1:
		var stack_lbl := Label.new()
		stack_lbl.text = str(stacks)
		stack_lbl.add_theme_font_size_override("font_size", 10)
		stack_lbl.add_theme_color_override("font_color", Color.WHITE)
		stack_lbl.add_theme_constant_override("outline_size", 1)
		stack_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		stack_lbl.position = Vector2(STATUS_ICON_SIZE - 12.0, 0.0)
		stack_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(stack_lbl)
	var display_name: String = entry.get("display_name", effect_id)
	var tooltip: String = display_name
	if stacks > 1:
		tooltip += "×%d" % stacks
	var ticks: int = int(entry.get("remaining_ticks", 0))
	if ticks > 0:
		tooltip += " (%dt)" % ticks
	panel.tooltip_text = tooltip
	return panel

func _populate_status_icon_row(row: HBoxContainer, statuses: Array) -> void:
	for child: Node in row.get_children():
		child.queue_free()
	for entry: Dictionary in statuses:
		row.add_child(_build_status_icon(entry))

func _set_status_row_above_sprite(row: HBoxContainer, sprite: AnimatedSprite2D, statuses: Array, formation_slot: int = -1) -> void:
	_populate_status_icon_row(row, statuses)
	var show: bool = sprite.visible and not statuses.is_empty()
	row.visible = show
	if not show:
		return
	var count: int = statuses.size()
	var total_w: float = count * STATUS_ICON_SIZE + maxf(0.0, float(count - 1)) * STATUS_ICON_GAP
	var center: Vector2 = _sprite_center_in_root(sprite)
	var icon_y: float
	if formation_slot >= 0:
		icon_y = _sprite_top_y_in_root(sprite) - CHR_HP_BAR_GAP_ABOVE_SPRITE - CHR_HP_BAR_HEIGHT - CHR_STATUS_GAP_ABOVE_BAR - STATUS_ICON_SIZE + _chr_hp_bar_row_y_offset(formation_slot)
	else:
		icon_y = _sprite_top_y_in_root(sprite) - STATUS_ICON_SIZE - 4.0
	row.position = Vector2(center.x - total_w * 0.5, icon_y)

func _update_status_icons() -> void:
	var in_combat: bool = $CombatController.is_in_combat
	if not in_combat:
		for row: HBoxContainer in _status_icon_swarm_rows:
			row.visible = false
		for row: HBoxContainer in _status_icon_chr_rows:
			row.visible = false
		return
	# ボスはドット絵が大きく状態異常アイコンが重なるため非表示。
	if _boss_sprite.visible:
		for row: HBoxContainer in _status_icon_swarm_rows:
			row.visible = false
	else:
		_ensure_swarm_status_icon_rows(_swarm_sprites.size())
		for slot: int in _swarm_sprites.size():
			if slot >= _status_icon_swarm_rows.size():
				continue
			var row: HBoxContainer = _status_icon_swarm_rows[slot]
			if not $CombatController.is_enemy_slot_alive(slot):
				row.visible = false
				continue
			_set_status_row_above_sprite(
				row,
				_swarm_sprites[slot],
				$CombatController.get_enemy_status_list_at(slot)
			)
	for i: int in _status_icon_chr_rows.size():
		var sprite: AnimatedSprite2D = _chr_sprites[i]
		var statuses: Array = $CombatController.get_member_status_list(i)
		_set_status_row_above_sprite(
			_status_icon_chr_rows[i],
			sprite,
			statuses,
			_formation_slot_for_combat_index(i)
		)
	_sync_status_auras()
	_sync_status_sprite_tints()

func _sync_status_sprite_tints() -> void:
	if not $CombatController.is_in_combat:
		return
	if _boss_sprite.visible:
		var boss_slot: int = $CombatController.active_enemy_index
		var boss_alive: bool = $CombatController.is_enemy_slot_alive(boss_slot)
		var boss_statuses: Array = (
			$CombatController.get_enemy_status_list_at(boss_slot) if boss_alive else []
		)
		_apply_status_tint_to_sprite(_boss_sprite, boss_alive and _boss_sprite.visible, boss_statuses)
		for slot: int in _swarm_sprites.size():
			_apply_status_tint_to_sprite(_swarm_sprites[slot], false, [])
	else:
		for slot: int in _swarm_sprites.size():
			if slot >= _swarm_sprites.size():
				continue
			var alive: bool = $CombatController.is_enemy_slot_alive(slot)
			var statuses: Array = (
				$CombatController.get_enemy_status_list_at(slot) if alive else []
			)
			_apply_status_tint_to_sprite(
				_swarm_sprites[slot],
				alive and _swarm_sprites[slot].visible,
				statuses
			)
	for i: int in _chr_sprites.size():
		var member_alive: bool = $CombatController.is_member_alive(i)
		var member_statuses: Array = (
			$CombatController.get_member_status_list(i) if member_alive else []
		)
		_apply_status_tint_to_sprite(
			_chr_sprites[i],
			member_alive and _chr_sprites[i].visible,
			member_statuses,
			GameState.get_combatant(i)
		)

func _apply_status_tint_to_sprite(
	sprite: CanvasItem,
	apply_tint: bool,
	statuses: Array,
	member: Resource = null
) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	if not apply_tint:
		var reset: Color = (
			EvolutionVisualScript.base_modulate(member) if member != null else Color.WHITE
		)
		if sprite.modulate != reset:
			sprite.modulate = reset
		return
	if member != null:
		sprite.modulate = EvolutionVisualScript.sprite_modulate(member, statuses)
	else:
		sprite.modulate = CombatVfxManager.unit_tint_from_statuses(statuses)

func _outgoing_damage_telop_color(is_critical: bool, is_ultimate: bool = false) -> Color:
	if is_critical:
		return LOG_DAMAGE_CRIT
	if is_ultimate:
		return ULTIMATE_GOLD
	return Color(1.0, 0.98, 0.92)

func _sync_status_auras() -> void:
	if not $CombatController.is_in_combat:
		_combat_vfx.clear_all()
		return
	if _boss_sprite.visible:
		var boss_slot: int = $CombatController.active_enemy_index
		var boss_statuses: Array = $CombatController.get_enemy_status_list_at(boss_slot)
		_combat_vfx.sync_unit_auras(
			"enemy_%d" % boss_slot,
			_boss_sprite,
			boss_statuses,
			_boss_sprite.visible
		)
		for slot: int in _swarm_sprites.size():
			_combat_vfx.sync_unit_auras("enemy_%d" % slot, _swarm_sprites[slot], [], false)
	else:
		for slot: int in _swarm_sprites.size():
			if slot >= _swarm_sprites.size():
				continue
			var alive: bool = $CombatController.is_enemy_slot_alive(slot)
			var statuses: Array = (
				$CombatController.get_enemy_status_list_at(slot) if alive else []
			)
			_combat_vfx.sync_unit_auras(
				"enemy_%d" % slot,
				_swarm_sprites[slot],
				statuses,
				alive and _swarm_sprites[slot].visible
			)
	for i: int in _chr_sprites.size():
		var member_alive: bool = $CombatController.is_member_alive(i)
		var member_statuses: Array = (
			$CombatController.get_member_status_list(i) if member_alive else []
		)
		_combat_vfx.sync_unit_auras(
			"party_%d" % i,
			_chr_sprites[i],
			member_statuses,
			member_alive and _chr_sprites[i].visible
		)

func _enemy_sprite_for_slot(slot: int) -> AnimatedSprite2D:
	if _boss_sprite.visible:
		return _boss_sprite
	if slot >= 0 and slot < _swarm_sprites.size():
		return _swarm_sprites[slot]
	return null

func _on_enemy_status_applied(slot: int, status_id: String) -> void:
	if status_id.is_empty():
		return
	var sprite: AnimatedSprite2D = _enemy_sprite_for_slot(slot)
	if sprite == null or not sprite.visible:
		return
	var statuses: Array = $CombatController.get_enemy_status_list_at(slot)
	_play_status_apply_vfx(sprite, _sprite_visual_center_global(sprite), status_id, statuses)
	_update_status_icons()

func _on_party_status_applied(member_idx: int, status_id: String) -> void:
	if status_id.is_empty() or member_idx < 0 or member_idx >= _chr_sprites.size():
		return
	var sprite: AnimatedSprite2D = _chr_sprites[member_idx]
	if not sprite.visible:
		return
	var statuses: Array = $CombatController.get_member_status_list(member_idx)
	_play_status_apply_vfx(
		sprite,
		_sprite_visual_center_global(sprite),
		status_id,
		statuses,
		GameState.get_combatant(member_idx)
	)
	_update_status_icons()

func _play_status_apply_vfx(
	sprite: AnimatedSprite2D,
	world_pos: Vector2,
	status_id: String,
	statuses_after: Array,
	member: Resource = null
) -> void:
	if sprite == null or not is_instance_valid(sprite) or status_id.is_empty():
		return
	var is_buff: bool = CombatVfxManagerScript.is_buff_status(status_id)
	_combat_vfx.spawn_apply_burst(self, world_pos, status_id)
	if is_buff:
		var buff_tint: Color = SUPPORT_VFX_TINT.get(status_id, SUPPORT_VFX_TINT["default_buff"])
		_spawn_support_sprite_vfx(world_pos, VFX_HEAL_PATH, buff_tint)
	else:
		var element: String = CombatVfxManagerScript.status_element(status_id)
		if not element.is_empty():
			_spawn_hit_vfx(world_pos, element, 0.85, false)
		elif ResourceLoader.exists(VFX_HIT_PATH):
			var tinted := AnimatedSprite2D.new()
			var frames: SpriteFrames = load(VFX_HIT_PATH) as SpriteFrames
			if frames != null:
				tinted.sprite_frames = frames
				tinted.scale = _hit_vfx_sprite.scale * 0.85
				_spawn_transient_vfx_sprite(
					tinted, world_pos, CombatVfxManagerScript.status_color(status_id)
				)
				tinted.play("default")
				tinted.animation_finished.connect(func() -> void: tinted.queue_free())
	_pulse_sprite_on_status_apply(sprite, is_buff)
	_flash_sprite_status_apply(sprite, status_id, statuses_after, member)
	_spawn_status_apply_name(world_pos, status_id, is_buff)

func _pulse_sprite_on_status_apply(sprite: AnimatedSprite2D, is_buff: bool) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var base_scale: Vector2 = sprite.scale
	var tw: Tween = create_tween()
	if is_buff:
		tw.tween_property(sprite, "scale", base_scale * 1.1, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(sprite, "scale", base_scale, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		var base_pos: Vector2 = sprite.position
		tw.tween_property(sprite, "position", base_pos + Vector2(-5.0, 0.0), 0.04)
		tw.tween_property(sprite, "position", base_pos + Vector2(5.0, 0.0), 0.05)
		tw.tween_property(sprite, "position", base_pos + Vector2(-3.0, 0.0), 0.04)
		tw.tween_property(sprite, "position", base_pos, 0.05)

func _flash_sprite_status_apply(
	sprite: CanvasItem,
	status_id: String,
	statuses_after: Array,
	member: Resource = null
) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var flash_color: Color = CombatVfxManagerScript.apply_flash_color(status_id)
	var settle: Color = (
		EvolutionVisualScript.sprite_modulate(member, statuses_after)
		if member != null
		else CombatVfxManagerScript.unit_tint_from_statuses(statuses_after)
	)
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "modulate", flash_color, 0.08)
	tw.tween_property(sprite, "modulate", settle, 0.24)

func _spawn_status_apply_name(world_pos: Vector2, status_id: String, is_buff: bool) -> void:
	var effect: Resource = DataRegistry.get_status_effect(status_id)
	var label_text: String = effect.display_name if effect != null else status_id
	if label_text.is_empty():
		return
	const FONT_SIZE: int = 20
	var lbl := Label.new()
	lbl.text = label_text
	var af: Font = UiTypography.impact_font()
	if af != null:
		lbl.add_theme_font_override("font", af)
	lbl.add_theme_font_size_override("font_size", FONT_SIZE)
	var color: Color = Color(0.55, 0.95, 0.55) if is_buff else CombatVfxManagerScript.status_color(status_id).lightened(0.25)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.pivot_offset = Vector2(float(label_text.length()) * FONT_SIZE * 0.28, FONT_SIZE * 0.5)
	lbl.position = world_pos + Vector2(-lbl.pivot_offset.x, -72.0)
	lbl.scale = Vector2(0.7, 0.7)
	lbl.modulate.a = 0.0
	_damage_numbers_layer.add_child(lbl)
	var tw: Tween = create_tween()
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 1.0, 0.1)
	tw.chain().set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 22.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4).set_delay(0.2)
	tw.chain().tween_callback(lbl.queue_free)

func _get_room_type_name() -> String:
	match $DungeonController.current_room_type:
		Enums.RoomType.START:    return "開始"
		Enums.RoomType.COMBAT:   return "戦闘"
		Enums.RoomType.EVENT:    return "碑文"
		Enums.RoomType.TREASURE: return "宝箱"
		Enums.RoomType.ELITE:    return "エリート"
		Enums.RoomType.TRAP:     return "罠"
		Enums.RoomType.BOSS:     return "ボス"
		Enums.RoomType.EXIT:     return "出口"
		Enums.RoomType.HEAL:     return "回復"
	return ""

func _update_room_label() -> void:
	if $DungeonController.current_dungeon_data == null:
		_label_room.text = ""
		_label_room.visible = false
		return
	_label_room.visible = false
	_update_run_hud()

func _on_next_room_pressed() -> void:
	_advance_to_next_room()

func _advance_to_next_room() -> void:
	$DungeonController.advance_room()
	_enter_current_room()

func _enter_current_room() -> void:
	_update_room_label()
	_update_room_art()
	_sync_room_bgm()
	if $DungeonController.is_combat_room():
		var group: Array[Resource] = $DungeonController.pick_combat_enemy_group()
		if not group.is_empty():
			var lead: Resource = group[0]
			$CombatController.start_combat_group(group, $DungeonController.get_enemy_level())
			_update_combat_visibility()
			_skill_executor.reset()
			_skill_cd_visual_rem.clear()
			_round_active = false
			_ct_status_accum = 0.0
			_passive_cd.clear()
			_passive_attack_hits.clear()
			_passive_first_attack_used.clear()
			_passive_next_attack_mult.clear()
			_passive_once_fired.clear()
			_passive_counter_depth = 0
			_passive_skill_echo_depth = 0
			_clear_party_links()
			_set_paused(false)
			var enemy_ids: Array = []
			for e in group:
				enemy_ids.append(e.id)
			_show_enemy_swarm(enemy_ids)
			_update_hp_bars()
			_show_chr_sprites(false)
			_try_exploration_trap()
			_update_turn_order_ui($CombatController.get_ct_order())
			_log_party_passives_on_combat_enter()
			_fire_combat_start_passives()
			if $DungeonController.current_room_type == Enums.RoomType.BOSS:
				_begin_boss_combat_entrance(lead)
				return
			if $DungeonController.current_room_type == Enums.RoomType.ELITE:
				_begin_elite_combat_entrance(lead)
				return
			if group.size() > 1:
				if _enemy_group_is_mixed(group):
					var names: PackedStringArray = []
					for e: Resource in group:
						names.append(e.display_name)
					_append_log("【混成】%s" % " / ".join(names))
				else:
					_append_log("%s の群れ（%d体）があらわれた" % [lead.display_name, group.size()])
			elif bool(lead.is_wandering):
				_append_log("【放浪】%s があらわれた" % lead.display_name)
			else:
				_append_log("%s があらわれた" % lead.display_name)
			if _try_combat_skip():
				return
			_start_combat_after_appear_delay()
		else:
			_set_narrative("敵が現れなかった")
			_boss_sprite.visible = false
			_hide_enemy_sprite()
			_hide_chr_sprites()
	else:
		_boss_sprite.visible = false
		_hide_enemy_sprite()
		_hide_chr_sprites()
		_fire_noncombat_enter_passives()
		match $DungeonController.current_room_type:
			Enums.RoomType.HEAL:
				_resolve_heal_room()
			Enums.RoomType.TREASURE:
				_resolve_treasure_room()
			Enums.RoomType.EVENT:
				_handle_event_room()
			Enums.RoomType.TRAP:
				_resolve_trap_room()
			_:
				_set_narrative(_get_room_type_name() + "の部屋に入った")
				_finish_room_and_continue()
	_update_enemy_label()
	_update_status_labels()
	_update_hp_bars()
	_update_next_room_button()
	_register_discoveries_for_room()

func _on_weapon_obtained(weapon_id: String) -> void:
	_try_register_discovery("weapon", weapon_id)

func _try_register_discovery(category: String, entry_id: String) -> void:
	if DiscoveryRegistry.register(category, entry_id):
		_append_discovery_log(category, entry_id)

func _append_discovery_log(category: String, entry_id: String) -> void:
	_show_discovery_toast(category, entry_id)
	_update_run_hud()
	if $CombatController.is_in_combat:
		var cat_label: String = DiscoveryRegistry.get_category_label(category)
		var name_label: String = DiscoveryRegistry.get_display_label(category, entry_id)
		_append_log("図鑑登録: [%s] %s" % [cat_label, name_label])

func _show_discovery_toast(category: String, entry_id: String) -> void:
	var cat_label: String = DiscoveryRegistry.get_category_label(category)
	var name_label: String = DiscoveryRegistry.get_display_label(category, entry_id)
	_label_discovery_text.text = "図鑑に登録: [%s] %s" % [cat_label, name_label]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.08, 0.92)
	style.border_color = Color(0.85, 0.7, 0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	_discovery_toast.add_theme_stylebox_override("panel", style)
	_discovery_toast.visible = true
	_discovery_toast.modulate.a = 0.0
	if _discovery_toast_tween != null and _discovery_toast_tween.is_valid():
		_discovery_toast_tween.kill()
	_discovery_toast_tween = create_tween()
	_discovery_toast_tween.tween_property(_discovery_toast, "modulate:a", 1.0, 0.25)
	_discovery_toast_tween.tween_interval(2.5)
	_discovery_toast_tween.tween_property(_discovery_toast, "modulate:a", 0.0, 0.35)
	_discovery_toast_tween.tween_callback(func() -> void:
		_discovery_toast.visible = false
	)

func _format_material_reward_log(material_id: String, amount: int, fallback_label: String) -> String:
	var display_name: String = fallback_label
	var mat_data: Resource = DataRegistry.get_material_data(material_id)
	if mat_data != null and not mat_data.display_name.is_empty():
		display_name = mat_data.display_name
	elif display_name.is_empty():
		display_name = DataRegistry.get_material_name(material_id)
	if display_name.is_empty() or display_name == material_id:
		display_name = "素材"
	return "%s x%d" % [display_name, amount]

func _register_discoveries_for_room() -> void:
	var room_type: int = $DungeonController.current_room_type
	if DiscoveryRegistry.is_special_room(room_type):
		_try_register_discovery("room", DiscoveryRegistry.room_type_to_id(room_type))
	if $CombatController.is_in_combat and $CombatController.current_enemy_data != null:
		_try_register_discovery("enemy", $CombatController.current_enemy_data.id)

# ---- Event ----

func _handle_event_room() -> void:
	_handle_event_room_async()

func _handle_event_room_async() -> void:
	_event_presentation_active = true
	$AutoProgressTimer.stop()
	_set_non_combat_phase_bg(LoreRoomPresentationScript.bg_path_for_phase("setup"))
	var setup_text: String = LoreRoomPresentationScript.pick_setup_line()
	_set_room_narrative(setup_text)
	var setup_hold: float = float(
		LoreRoomPresentationScript.timings(_fast_run_enabled).get("setup_hold", 1.0)
	)
	await get_tree().create_timer(setup_hold).timeout
	if not LoreRoomPresentationScript.is_deciphered():
		var fail_text: String = LoreRoomPresentationScript.pick_fail_line()
		_set_non_combat_phase_bg(LoreRoomPresentationScript.bg_path_for_phase("fail"))
		_set_room_narrative(fail_text, LoreRoomPresentationScript.COLOR_FAIL)
		_append_log("[碑文] %s" % fail_text)
		_event_presentation_active = false
		_reset_narrative_typography()
		_finish_room_and_continue()
		return
	var event: Dictionary = $DungeonController.pick_event()
	if event.is_empty():
		var empty_text: String = "碑文は見つからなかった"
		_set_non_combat_phase_bg(LoreRoomPresentationScript.bg_path_for_phase("fail"))
		_set_room_narrative(empty_text, LoreRoomPresentationScript.COLOR_FAIL)
		_event_presentation_active = false
		_reset_narrative_typography()
		_finish_room_and_continue()
		return
	var event_id: String = event.get("id", "")
	if not event_id.is_empty() and not $DungeonController._is_lore_event(event):
		_try_register_discovery("event", event_id)
	_set_non_combat_phase_bg(LoreRoomPresentationScript.bg_path_for_phase("success"))
	var outcome: Dictionary = $DungeonController.auto_resolve_event()
	var log_text: String = await _play_event_room_presentation(event, outcome)
	var explore_lines: PackedStringArray = _apply_exploration_event_skills(outcome)
	for line: String in explore_lines:
		log_text += "\n" + line
	_set_room_narrative(
		"%s\n%s" % [event["description"], log_text],
		LoreRoomPresentationScript.COLOR_SUCCESS
	)
	_event_presentation_active = false
	_reset_narrative_typography()
	_finish_room_and_continue()

func _ensure_event_telop_panel() -> PanelContainer:
	if _event_telop_panel != null and is_instance_valid(_event_telop_panel):
		return _event_telop_panel
	_event_telop_bg = TextureRect.new()
	_event_telop_bg.name = "EventTelopBg"
	_event_telop_bg.visible = false
	_event_telop_bg.z_index = 0
	_event_telop_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_event_telop_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_event_telop_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_event_telop_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_telop_bg.modulate = Color(1.0, 1.0, 1.0, 0.0)
	$TransitionLayer.add_child(_event_telop_bg)
	_event_telop_dim = ColorRect.new()
	_event_telop_dim.name = "EventTelopDim"
	_event_telop_dim.visible = false
	_event_telop_dim.z_index = 1
	_event_telop_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_event_telop_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_telop_dim.color = Color(0.02, 0.02, 0.06, 0.0)
	$TransitionLayer.add_child(_event_telop_dim)
	_event_telop_panel = PanelContainer.new()
	_event_telop_panel.name = "EventTelopPanel"
	_event_telop_panel.visible = false
	_event_telop_panel.z_index = 2
	_event_telop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_telop_panel.set_anchors_preset(Control.PRESET_CENTER)
	_event_telop_panel.custom_minimum_size = Vector2(620, 0)
	_event_telop_panel.offset_left = -310.0
	_event_telop_panel.offset_right = 310.0
	_event_telop_panel.offset_top = -88.0
	_event_telop_panel.offset_bottom = 88.0
	_event_telop_panel.add_theme_stylebox_override(
		"panel",
		CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	_event_telop_scene_label = Label.new()
	_event_telop_scene_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_telop_scene_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(
		_event_telop_scene_label,
		UiTypography.SIZE_BODY,
		Color(0.95, 0.93, 0.88),
		UiTypography.OUTLINE_BODY
	)
	_event_telop_result_label = Label.new()
	_event_telop_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_telop_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_telop_result_label.visible = false
	stack.add_child(_event_telop_scene_label)
	stack.add_child(_event_telop_result_label)
	margin.add_child(stack)
	_event_telop_panel.add_child(margin)
	$TransitionLayer.add_child(_event_telop_panel)
	return _event_telop_panel

func _set_event_telop_lines(scene_text: String, result_text: String, result_color: Color) -> void:
	_event_telop_scene_label.text = scene_text
	if result_text.is_empty():
		_event_telop_result_label.visible = false
		_event_telop_result_label.text = ""
		return
	_event_telop_result_label.visible = true
	_event_telop_result_label.text = result_text
	UiTypography.apply_display(
		_event_telop_result_label,
		UiTypography.SIZE_DISPLAY,
		result_color,
		UiTypography.OUTLINE_STRONG
	)

func _set_event_telop_background(outcome_type: String) -> void:
	if _event_telop_bg == null:
		return
	var path: String = EventPresentationScript.background_path(outcome_type)
	if path.is_empty():
		_event_telop_bg.texture = null
		_event_telop_bg.visible = false
		return
	_event_telop_bg.texture = load(path) as Texture2D
	_event_telop_bg.visible = _event_telop_bg.texture != null

func _hide_event_telop() -> void:
	if _event_telop_panel != null and is_instance_valid(_event_telop_panel):
		_event_telop_panel.visible = false
		_event_telop_panel.modulate = Color.WHITE
	if _event_telop_bg != null and is_instance_valid(_event_telop_bg):
		_event_telop_bg.visible = false
		_event_telop_bg.modulate = Color(1.0, 1.0, 1.0, 0.0)
	if _event_telop_dim != null and is_instance_valid(_event_telop_dim):
		_event_telop_dim.visible = false
		_event_telop_dim.color.a = 0.0

func _event_presentation_anchor() -> Vector2:
	return get_viewport_rect().size * Vector2(0.5, 0.42)

func _play_event_room_presentation(event: Dictionary, outcome: Dictionary) -> String:
	_init_dungeon_presentation_ui()
	var panel: PanelContainer = _ensure_event_telop_panel()
	var timings: Dictionary = EventPresentationScript.timings(_fast_run_enabled)
	var scene_text: String = EventPresentationScript.format_scene_line(
		str(event.get("description", "古い碑文を見つけた"))
	)
	var outcome_type: String = EventPresentationScript.outcome_type(outcome)
	var result_text: String = EventPresentationScript.format_result_line(outcome)
	var result_color: Color = EventPresentationScript.outcome_color(outcome_type)
	var flash: Color = EventPresentationScript.flash_color(outcome_type)
	var applied_log: String = ""
	_set_event_telop_lines(scene_text, "", result_color)
	_set_event_telop_background(outcome_type)
	panel.visible = true
	panel.modulate.a = 0.0
	_event_telop_dim.visible = true
	_event_telop_dim.color.a = 0.0
	if _event_telop_bg != null:
		_event_telop_bg.modulate.a = 0.0
	var bg_alpha: float = EventPresentationScript.BG_ALPHA
	var dim_alpha: float = EventPresentationScript.DIM_ALPHA
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, float(timings["scene_fade_in"]))
	tw.tween_property(_event_telop_dim, "color:a", dim_alpha, float(timings["scene_fade_in"]))
	if _event_telop_bg != null and _event_telop_bg.texture != null:
		tw.tween_property(_event_telop_bg, "modulate:a", bg_alpha, float(timings["scene_fade_in"]))
	tw.chain().tween_interval(float(timings["scene_hold"]))
	tw.tween_callback(func() -> void:
		_set_event_telop_lines(scene_text, result_text, result_color)
		_event_telop_result_label.modulate.a = 0.0
		_event_telop_result_label.scale = Vector2(0.92, 0.92)
	)
	tw.tween_property(_event_telop_result_label, "modulate:a", 1.0, float(timings["result_fade_in"]))
	tw.parallel().tween_property(
		_event_telop_result_label,
		"scale",
		Vector2.ONE,
		float(timings["result_fade_in"])
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		applied_log = _apply_event_outcome(outcome)
		_request_combat_shake(float(timings["shake"]))
	)
	tw.tween_interval(float(timings["pre_fx"]))
	tw.tween_callback(func() -> void:
		_spawn_transition_sparkles(
			flash,
			EventPresentationScript.spark_amount(outcome_type),
			_event_presentation_anchor()
		)
		_flash_battlefield(flash, 0.14)
	)
	tw.tween_interval(float(timings["fx"]))
	tw.tween_interval(float(timings["result_hold"]))
	tw.tween_property(panel, "modulate:a", 0.0, float(timings["fade_out"]))
	tw.parallel().tween_property(_event_telop_dim, "color:a", 0.0, float(timings["fade_out"]))
	if _event_telop_bg != null:
		tw.parallel().tween_property(_event_telop_bg, "modulate:a", 0.0, float(timings["fade_out"]))
	tw.chain().tween_callback(_hide_event_telop)
	await tw.finished
	return applied_log

func _apply_event_outcome(outcome: Dictionary) -> String:
	match outcome.get("type", "nothing"):
		"heal":
			var amount: int = _apply_healing_bonus(outcome.get("amount", 5))
			$CombatController.heal_party(amount)
			_play_heal_vfx()
			_update_hp_bars()
			return "パーティが%dHP回復した" % amount
		"gold":
			var gold_amount: int = outcome.get("amount", 0)
			$DungeonController.accumulate_rewards(0, gold_amount)
			return "ゴールド +%d を得た" % gold_amount
		"buff":
			var mult: float = outcome.get("multiplier", 1.0)
			$DungeonController.run_damage_multiplier = mult
			return "攻撃力が一時的に強化された（x%.2f）" % mult
		"material":
			var mat_id: String = outcome.get("material_id", outcome.get("discovery_id", "relic_shard"))
			var mat_amount: int = _apply_material_bonus(int(outcome.get("amount", 1)))
			GameState.add_material(mat_id, mat_amount)
			_try_register_discovery("material", mat_id)
			return _format_material_reward_log(mat_id, mat_amount, outcome.get("label", ""))
		"lore":
			var lore_id: String = outcome.get("discovery_id", "unknown_lore")
			var body: String = CatalogHelper.get_lore_body(lore_id)
			_try_register_discovery("lore", lore_id)
			if not body.is_empty():
				return "【碑文】%s\n%s" % [outcome.get("label", "碑文"), body]
			return "%s を記録した。" % outcome.get("label", "碑文")
		_:
			return "何も起こらなかった"

# ---- 高速周回（P3-D118） ----

func _ensure_fast_run_button() -> void:
	var header: HBoxContainer = $MainVBox/HeaderBar
	if header.get_node_or_null("ButtonFastRun") != null:
		_btn_fast_run = header.get_node("ButtonFastRun")
		return
	_btn_fast_run = Button.new()
	_btn_fast_run.name = "ButtonFastRun"
	_btn_fast_run.toggle_mode = true
	var stop_idx: int = header.get_node("ButtonStop").get_index()
	header.add_child(_btn_fast_run)
	header.move_child(_btn_fast_run, stop_idx)
	_btn_fast_run.pressed.connect(_on_fast_run_pressed)
	_refresh_fast_run_button()

func _on_fast_run_pressed() -> void:
	var dungeon_id: String = GameState.get_active_dungeon_id()
	if not CombatFastRun.can_enable(dungeon_id):
		_fast_run_enabled = false
		_refresh_fast_run_button()
		return
	_fast_run_enabled = _btn_fast_run.button_pressed if _btn_fast_run != null else false
	if _fast_run_enabled:
		_apply_combat_grind_speed()
	_refresh_fast_run_button()

func _refresh_fast_run_button() -> void:
	if _btn_fast_run == null:
		return
	var can_use: bool = CombatFastRun.can_enable(GameState.get_active_dungeon_id())
	_btn_fast_run.disabled = not can_use
	_btn_fast_run.button_pressed = _fast_run_enabled and can_use
	_btn_fast_run.text = "周回ON" if _btn_fast_run.button_pressed else "周回"

func _try_combat_skip() -> bool:
	var room_type: int = $DungeonController.current_room_type
	if not CombatFastRun.can_skip_room(room_type, _fast_run_enabled):
		return false
	if not CombatFastRun.can_enable(GameState.get_active_dungeon_id()):
		return false
	_execute_combat_skip()
	return true

func _execute_combat_skip() -> void:
	_append_log(CombatFastRun.skip_log_message($DungeonController.current_room_type))
	$CombatTimer.stop()
	_clear_all_member_skill_labels()
	var slots: Array[int] = []
	for i: int in $CombatController.swarm_hp.size():
		if $CombatController.is_enemy_slot_alive(i):
			slots.append(i)
	for slot: int in slots:
		if $CombatController.living_enemy_count() <= 0:
			break
		var hp: int = $CombatController.get_enemy_hp_at(slot)
		if hp > 0:
			$CombatController.apply_damage_to_enemy_slot(slot, hp)
		if $CombatController.get_enemy_hp_at(slot) <= 0:
			if _on_enemy_slot_killed(slot):
				return
	if $CombatController.living_enemy_count() == 0:
		_finalize_combat_cleared()

# ---- 探索スキル（P3-D117） ----

func _apply_exploration_treasure_skills(treasure: Dictionary) -> PackedStringArray:
	var members: Array = GameState.party_members
	var room_type: int = Enums.RoomType.TREASURE
	var lines: PackedStringArray = []
	if ExplorationSkills.has_skill_for_room(members, "mine", room_type):
		var bonus_gold: int = 12
		$DungeonController.accumulate_rewards(0, bonus_gold)
		treasure["gold"] = int(treasure.get("gold", 0)) + bonus_gold
		lines.append("[探索] 採掘: ゴールド +%d" % bonus_gold)
	if ExplorationSkills.has_skill_for_room(members, "lockpick", room_type):
		if str(treasure.get("accessory_id", "")).is_empty() and randf() < 0.35:
			var acc_id: String = $DungeonController.generate_accessory_loot()
			if not acc_id.is_empty():
				treasure["accessory_id"] = acc_id
				lines.append(
					"[探索] 鍵開け: 装飾品を入手 — %s" % DataRegistry.get_accessory_name(acc_id)
				)
	return lines

# ---- 回復部屋（P3-UX-HEAL-001） ----

func _resolve_heal_room() -> void:
	_resolve_heal_room_async()

func _resolve_heal_room_async() -> void:
	_heal_presentation_active = true
	$AutoProgressTimer.stop()
	$CombatController.ensure_party_hp_for_combat()
	_set_non_combat_phase_bg(HealRoomPresentationScript.bg_path_for_phase("setup"))
	var setup_text: String = HealRoomPresentationScript.pick_setup_line()
	_set_room_narrative(setup_text)
	var setup_hold: float = float(
		HealRoomPresentationScript.timings(_fast_run_enabled).get("setup_hold", 1.0)
	)
	await get_tree().create_timer(setup_hold).timeout
	if not HealRoomPresentationScript.is_successful():
		var fail_text: String = HealRoomPresentationScript.pick_fail_line()
		_set_non_combat_phase_bg(HealRoomPresentationScript.bg_path_for_phase("fail"))
		_set_room_narrative(fail_text, HealRoomPresentationScript.COLOR_FAIL)
		_append_log("[回復] %s" % fail_text)
		_heal_presentation_active = false
		_reset_narrative_typography()
		_finish_room_and_continue()
		return
	var heal_amount: int = _apply_healing_bonus(HEAL_AMOUNT)
	$CombatController.heal_party(heal_amount)
	_play_heal_vfx()
	_update_hp_bars()
	_set_non_combat_phase_bg(HealRoomPresentationScript.bg_path_for_phase("success"))
	var success_line: String = HealRoomPresentationScript.pick_success_line()
	var narrative: String = HealRoomPresentationScript.format_success_narrative(success_line, heal_amount)
	_set_room_narrative(narrative, HealRoomPresentationScript.COLOR_SUCCESS)
	_append_log("[回復] %s" % success_line)
	_heal_presentation_active = false
	_reset_narrative_typography()
	_finish_room_and_continue()

# ---- 宝箱開封（P3-UX-006 / P3-UX-TREASURE-001） ----

func _resolve_treasure_room() -> void:
	_resolve_treasure_room_async()

func _resolve_treasure_room_async() -> void:
	_treasure_presentation_active = true
	$AutoProgressTimer.stop()
	_set_non_combat_phase_bg(TreasureRoomPresentationScript.bg_path_for_phase("setup"))
	var setup_text: String = TreasureRoomPresentationScript.pick_setup_line()
	_set_room_narrative(setup_text)
	var setup_hold: float = float(
		TreasureRoomPresentationScript.timings(_fast_run_enabled).get("setup_hold", 1.0)
	)
	await get_tree().create_timer(setup_hold).timeout
	if not TreasureRoomPresentationScript.is_successful():
		var treasure_fail: Dictionary = $DungeonController.generate_treasure_loot_failure()
		var fail_line: String = TreasureRoomPresentationScript.pick_fail_line()
		var fail_text: String = TreasureRoomPresentationScript.format_fail_narrative(
			fail_line, int(treasure_fail.get("gold", 0))
		)
		_set_non_combat_phase_bg(TreasureRoomPresentationScript.bg_path_for_phase("fail"))
		_set_room_narrative(fail_text, TreasureRoomPresentationScript.COLOR_FAIL)
		_append_log("[宝箱] %s" % fail_line)
		_treasure_presentation_active = false
		_reset_narrative_typography()
		_finish_room_and_continue()
		return
	var treasure: Dictionary = $DungeonController.generate_treasure_loot()
	var explore_treasure: PackedStringArray = _apply_exploration_treasure_skills(treasure)
	var accessory_name: String = ""
	if not (treasure["accessory_id"] as String).is_empty():
		accessory_name = DataRegistry.get_accessory_name(treasure["accessory_id"])
		GameState.last_run_accessory_dropped = treasure["accessory_id"]
	var success_line: String = TreasureRoomPresentationScript.pick_success_line()
	var log_text: String = TreasureRoomPresentationScript.format_success_narrative(
		success_line, int(treasure["gold"]), accessory_name
	)
	for line: String in explore_treasure:
		log_text += "\n" + line
	var has_accessory: bool = not (treasure["accessory_id"] as String).is_empty()
	_set_non_combat_phase_bg(TreasureRoomPresentationScript.bg_path_for_phase("success"))
	AudioManager.play_sfx("treasure")
	await _play_treasure_open_presentation(has_accessory)
	_set_room_narrative(log_text, TreasureRoomPresentationScript.COLOR_SUCCESS)
	_treasure_presentation_active = false
	_reset_narrative_typography()
	_finish_room_and_continue()

func _dungeon_treasure_open_path(dungeon_id: String) -> String:
	var fallback_id: String = Constants.MOURNGATE_DUNGEON_ID
	var closed_path: String = TREASURE_CLOSED_OBJ_MAP.get(dungeon_id, TREASURE_CLOSED_OBJ_MAP[fallback_id])
	var open_path: String = closed_path.replace("Closed.png", "Open.png")
	if ResourceLoader.exists(open_path):
		return open_path
	return closed_path

func _treasure_chest_world_pos() -> Vector2:
	return get_viewport_rect().size * Vector2(0.5, 0.55)

func _play_treasure_open_presentation(has_rare_loot: bool) -> void:
	_init_dungeon_presentation_ui()
	_request_combat_shake(TREASURE_OPEN_SHAKE)
	await get_tree().create_timer(TREASURE_OPEN_PRE_SWAP_SEC).timeout
	var spark_amount: int = 56 if has_rare_loot else 36
	_spawn_transition_sparkles(Color(1.0, 0.86, 0.28), spark_amount, _treasure_chest_world_pos())
	_flash_battlefield(Color(1.0, 0.86, 0.38), 0.16)
	await get_tree().create_timer(TREASURE_OPEN_HOLD_SEC).timeout

func _apply_exploration_event_skills(outcome: Dictionary) -> PackedStringArray:
	var members: Array = GameState.party_members
	var room_type: int = Enums.RoomType.EVENT
	var lines: PackedStringArray = []
	var outcome_type: String = str(outcome.get("type", ""))
	if ExplorationSkills.has_skill_for_room(members, "gather", room_type):
		if outcome_type == "material":
			var mat_id: String = str(outcome.get("material_id", outcome.get("discovery_id", "relic_shard")))
			var bonus_amt: int = _apply_material_bonus(1)
			GameState.add_material(mat_id, bonus_amt)
			lines.append("[探索] 採取: %s" % _format_material_reward_log(mat_id, bonus_amt, ""))
			_try_register_discovery("material", mat_id)
		elif randf() < 0.40:
			var shard_amt: int = _apply_material_bonus(1)
			GameState.add_material("relic_shard", shard_amt)
			lines.append("[探索] 採取: %s" % _format_material_reward_log("relic_shard", shard_amt, ""))
			_try_register_discovery("material", "relic_shard")
	if (
		outcome_type == "lore"
		and ExplorationSkills.has_skill_for_room(members, "decipher", room_type)
	):
		var bonus_gold: int = 20
		$DungeonController.accumulate_rewards(0, bonus_gold)
		lines.append("[探索] 解読: ゴールド +%d" % bonus_gold)
	return lines

func _try_exploration_trap() -> void:
	var room_type: int = $DungeonController.current_room_type
	if room_type != Enums.RoomType.COMBAT and room_type != Enums.RoomType.ELITE:
		return
	if not ExplorationSkills.should_roll_trap():
		return
	var members: Array = GameState.party_members
	if ExplorationSkills.can_disarm(members):
		_append_log("[探索] 罠解除: パーティは無事だった")
		return
	var living: Array[int] = _living_exploration_damage_targets()
	if living.is_empty():
		_append_log("[探索] 罠: 辺境の踏破により被害なし")
		return
	var aoe: bool = ExplorationSkills.roll_trap_aoe()
	var targets: Array[int] = []
	if aoe:
		targets = living.duplicate()
	else:
		targets.append(living[randi() % living.size()])
	_apply_trap_damage_hits(targets, false, aoe, "[探索] 罠")
	_update_hp_bars()

func _resolve_trap_room() -> void:
	_resolve_trap_room_async()

func _resolve_trap_room_async() -> void:
	_trap_presentation_active = true
	$AutoProgressTimer.stop()
	$CombatController.ensure_party_hp_for_combat()
	_set_non_combat_phase_bg(TrapPresentationScript.bg_path_for_phase("setup"))
	var setup_text: String = TrapPresentationScript.pick_setup_line()
	_set_trap_setup_narrative(setup_text)
	var setup_hold: float = float(TrapPresentationScript.timings(_fast_run_enabled).get("setup_hold", 1.0))
	await get_tree().create_timer(setup_hold).timeout
	if not TrapPresentationScript.is_triggered():
		var avoid_text: String = TrapPresentationScript.pick_avoid_line()
		_set_non_combat_phase_bg(TrapPresentationScript.bg_path_for_phase("avoid"))
		_set_trap_avoid_narrative(avoid_text)
		_append_log("[罠] %s" % avoid_text)
		_trap_presentation_active = false
		_reset_narrative_typography()
		_finish_room_and_continue()
		return
	var living: Array[int] = _living_exploration_damage_targets()
	if living.is_empty():
		var avoid_immune: String = "辺境の踏破により罠の被害を受けなかった"
		_set_non_combat_phase_bg(TrapPresentationScript.bg_path_for_phase("avoid"))
		_set_trap_avoid_narrative(avoid_immune)
		_append_log("[罠] %s" % avoid_immune)
		_trap_presentation_active = false
		_reset_narrative_typography()
		_finish_room_and_continue()
		return
	var aoe: bool = ExplorationSkills.roll_trap_aoe()
	var hit_text: String = (
		TrapPresentationScript.pick_hit_line_aoe()
		if aoe
		else TrapPresentationScript.pick_hit_line()
	)
	_set_non_combat_phase_bg(TrapPresentationScript.bg_path_for_phase("hit"))
	_begin_trap_hit_presentation()
	if aoe:
		_set_trap_aoe_hit_narrative(hit_text, living.size())
	else:
		var preview_target: int = living[randi() % living.size()]
		var preview_m: Resource = GameState.get_combatant(preview_target)
		var preview_nm: String = preview_m.display_name if preview_m != null else "?"
		var preview_dmg: int = ExplorationSkills.trap_damage_for_max_hp(
			_member_max_hp_for_trap(preview_target), true, false
		)
		_set_trap_hit_narrative(hit_text, preview_nm, preview_dmg)
		## 単体はナラティブ用に選んだ対象へ固定
		var single_targets: Array[int] = []
		single_targets.append(preview_target)
		living = single_targets
	_apply_trap_damage_hits(living, true, aoe, "[罠]")
	_update_hp_bars()
	if $CombatController.is_party_wiped():
		await get_tree().create_timer(TRAP_HIT_PAUSE_SEC).timeout
		_end_trap_hit_presentation()
		_handle_party_wipe()
		return
	await get_tree().create_timer(TRAP_HIT_PAUSE_SEC).timeout
	_end_trap_hit_presentation()
	_finish_room_and_continue()

func _begin_trap_hit_presentation() -> void:
	_trap_presentation_active = true
	_party_status_panel.visible = true
	_battle_log_panel.visible = true
	_narrative_panel.visible = true
	_auto_combat_row.visible = false
	_lock_combat_ui_layout()
	_show_chr_sprites()
	_update_hp_bars()
	call_deferred("_refit_all_battle_log_entries")

func _end_trap_hit_presentation() -> void:
	_trap_presentation_active = false
	_reset_narrative_typography()
	_hide_chr_sprites()
	_update_combat_visibility()

func _set_trap_setup_narrative(text: String) -> void:
	_label_narrative.text = text
	UiTypography.apply_body(_label_narrative, UiTypography.SIZE_BODY, UiTypography.COLOR_BODY)

func _set_trap_avoid_narrative(text: String) -> void:
	_label_narrative.text = text
	UiTypography.apply_body(_label_narrative, UiTypography.SIZE_BODY, TrapPresentationScript.COLOR_AVOID)

func _set_trap_hit_narrative(hit_line: String, member_name: String, dmg: int) -> void:
	_label_narrative.text = TrapPresentationScript.format_hit_narrative(hit_line, member_name, dmg)
	UiTypography.apply_body(_label_narrative, UiTypography.SIZE_BODY, TrapPresentationScript.COLOR_HIT)


func _set_trap_aoe_hit_narrative(hit_line: String, hit_count: int) -> void:
	_label_narrative.text = TrapPresentationScript.format_aoe_hit_narrative(hit_line, hit_count)
	UiTypography.apply_body(_label_narrative, UiTypography.SIZE_BODY, TrapPresentationScript.COLOR_HIT)


## 罠ダメージ適用（最大HP割合・単体/全体）。log_prefix 例: "[罠]" / "[探索] 罠"
func _apply_trap_damage_hits(
	targets: Array[int], trap_room: bool, aoe: bool, log_prefix: String
) -> void:
	if targets.is_empty():
		return
	if aoe:
		_append_trap_hit_log("%s: パーティ全体にダメージ！" % log_prefix)
	for target: int in targets:
		var max_hp: int = _member_max_hp_for_trap(target)
		var dmg: int = ExplorationSkills.trap_damage_for_max_hp(max_hp, trap_room, aoe)
		var m: Resource = GameState.get_combatant(target)
		var nm: String = m.display_name if m != null else "?"
		$CombatController.apply_damage_to_member(target, dmg)
		_on_member_damaged(target)
		_apply_trap_hit_feedback(target, dmg, trap_room)
		_append_trap_hit_log("%s: %s に %d ダメージ！" % [log_prefix, nm, dmg])


func _member_max_hp_for_trap(index: int) -> int:
	if index >= 0 and index < $CombatController.party_max_hp.size():
		return maxi(1, int($CombatController.party_max_hp[index]))
	return 1

func _set_room_narrative(text: String, accent: Color = UiTypography.COLOR_BODY) -> void:
	_label_narrative.text = text
	UiTypography.apply_body(_label_narrative, UiTypography.SIZE_BODY, accent)

func _reset_narrative_typography() -> void:
	UiTypography.apply_body(_label_narrative, UiTypography.SIZE_BODY_SMALL)
	_label_narrative.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _label_now_playing != null:
		_label_now_playing.visible = false
		_label_now_playing.text = ""

func _apply_trap_hit_feedback(target_idx: int, dmg: int, trap_room: bool = false) -> void:
	AudioManager.play_sfx("combat_hit", 1.0, 0.05)
	var pos: Vector2 = _trap_feedback_world_pos(target_idx)
	var dmg_scale: float = TrapPresentationScript.damage_scale(trap_room)
	if pos != Vector2.ZERO:
		_spawn_damage_number(
			str(dmg), pos, TRAP_FEEDBACK_DMG_COLOR, dmg_scale, dmg, true
		)
	_flash_member_sprite(target_idx, Color(1.0, 0.55, 0.45))
	_flash_trap_alert(trap_room)
	if trap_room:
		_shake_battlefield(TrapPresentationScript.SHAKE_INTENSITY)

func _flash_trap_alert(trap_room: bool) -> void:
	var alphas: Array[float] = TrapPresentationScript.peak_alphas(trap_room, _fast_run_enabled)
	if alphas.is_empty():
		return
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(
		TRAP_FEEDBACK_FLASH_COLOR.r,
		TRAP_FEEDBACK_FLASH_COLOR.g,
		TRAP_FEEDBACK_FLASH_COLOR.b,
		0.0
	)
	flash.z_index = 120
	_damage_numbers_layer.add_child(flash)
	var tw: Tween = create_tween()
	for peak: float in alphas:
		tw.tween_property(flash, "color:a", peak, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(flash, "color:a", 0.0, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(flash.queue_free)

func _trap_feedback_world_pos(member_idx: int) -> Vector2:
	if member_idx < 0 or member_idx >= _chr_sprites.size():
		return Vector2.ZERO
	var sprite: AnimatedSprite2D = _chr_sprites[member_idx]
	if sprite.visible:
		return _member_sprite_world_pos(member_idx, 0.55)
	if member_idx < _party_card_roots.size():
		var card: Control = _party_card_roots[member_idx]
		if card != null and is_instance_valid(card):
			return card.global_position + Vector2(card.size.x * 0.5, 18.0)
	return sprite.to_global(Vector2(0.0, -CHR_BODY_TARGET_PX * 0.45))

# ---- Combat timer ----

# P3-D084: CT/ATB 制。CombatTimer の 1 パルス＝CT クロックを次の行動者まで進め、
# その 1 体だけが行動する。速いユニットほど CT が早く溜まり多く動く。スキルCDは進行した
# CT 量で、状態異常は一定 CT（CT_PER_STATUS_TICK）ごとに 1 tick 進める。
# 同期実行（await無し）のため再入は起きないが、安全のため _round_active を残す。
const CT_PER_STATUS_TICK: float = 2.0
var _ct_status_accum: float = 0.0
# パッシブCD（P3-D088）。key="<member_idx>:<passive_id>" → 残りCT。
var _passive_cd: Dictionary = {}
var _passive_attack_hits: Dictionary = {}
var _passive_first_attack_used: Dictionary = {}
var _passive_next_attack_mult: Dictionary = {}
var _passive_once_fired: Dictionary = {}
var _passive_counter_depth: int = 0
var _passive_skill_echo_depth: int = 0
# パーティ連携連鎖（P3-D115）。
var _taunt_link_source: int = -1
var _taunt_link_charges: int = 0
var _debuff_marks: Dictionary = {}
var _heal_rally_member: int = -1

func _on_combat_timer_timeout() -> void:
	if not $CombatController.is_in_combat:
		$CombatTimer.stop()
		return
	if _combat_cinematic_lock:
		return
	if _round_active:
		return
	_round_active = true
	_run_combat_step()
	_round_active = false

func _run_combat_step() -> void:
	if not $CombatController.is_in_combat:
		return
	if _combat_cinematic_lock:
		return
	var actor: Dictionary = $CombatController.advance_to_next_actor()
	var delta: float = $CombatController.consume_last_ct_step()
	_last_ct_step_ui = delta
	# スキルCD・パッシブCDは進行した CT 量だけ進める
	if delta > 0.0:
		_skill_executor.tick(delta)
		_tick_passive_cd(delta)
	# 状態異常（DoT/バフ等）は一定 CT ごとに 1 tick
	_ct_status_accum += delta
	while _ct_status_accum >= CT_PER_STATUS_TICK:
		_ct_status_accum -= CT_PER_STATUS_TICK
		_process_status_ticks()
		if $CombatController.living_enemy_count() == 0:
			return
		if $CombatController.is_party_wiped():
			_handle_party_wipe()
			return
	if actor.is_empty():
		return
	var kind: String = actor["kind"]
	var idx: int = actor["index"]
	if kind == "party":
		if $CombatController.is_member_alive(idx):
			_do_member_turn(idx)
			if $CombatController.living_enemy_count() == 0:
				return
	else:
		if $CombatController.is_enemy_slot_alive(idx):
			_do_enemy_turn(idx)
			if $CombatController.is_party_wiped():
				_handle_party_wipe()
				return
	_update_hp_bars()
	_update_status_labels()
	# CT 表示を更新し、次に動くユニット（CT 残量最小＝先頭）を強調
	var order: Array[Dictionary] = $CombatController.get_ct_order()
	_update_turn_order_ui(order)
	if not order.is_empty():
		_set_turn_order_active(order[0])
	_refresh_combat_now_playing_next()

# 敵スロット1体の行動（P3-D083）。アクティブ敵のみ 鈍化判定＋ボス/エリートのスキル発動を行い、
# それ以外は通常攻撃。状態異常/スキルはアクティブ敵のみに作用（P3-D082）。
func _do_enemy_turn(slot: int) -> void:
	if $CombatController.get_wander_flee_after_turns(slot) > 0:
		if $CombatController.get_wander_action_count(slot) >= $CombatController.get_wander_flee_after_turns(slot):
			_on_enemy_wander_fled(slot)
			return
	_update_combat_now_playing_for("enemy", slot)
	if $CombatController.has_pending_cast("enemy", slot):
		_advance_enemy_cast(slot)
		return
	if $CombatController.should_enemy_skip_action_at(slot):
		var skip_label: String = $CombatController.get_enemy_skip_action_label_at(slot)
		if skip_label.is_empty():
			skip_label = "鈍化"
		_append_log("[%s] 敵の行動が遅れた" % skip_label)
		return
	if slot == $CombatController.active_enemy_index:
		if _try_enemy_skill():
			_record_wander_enemy_action(slot)
			return
	_do_enemy_attack(slot)
	_record_wander_enemy_action(slot)

func _record_wander_enemy_action(slot: int) -> void:
	if $CombatController.get_wander_flee_after_turns(slot) > 0:
		$CombatController.increment_wander_action_count(slot)

func _on_enemy_wander_fled(slot: int) -> void:
	var enemy_data: Resource = $CombatController.get_enemy_data_at(slot)
	var name: String = enemy_data.display_name if enemy_data != null else "放浪個体"
	$CombatController.clear_pending_cast("enemy", slot)
	$CombatController.flee_enemy_slot(slot)
	_debuff_marks.erase(slot)
	if slot < _swarm_sprites.size() and _swarm_sprites[slot].visible:
		_swarm_sprites[slot].visible = false
	if slot < _swarm_hp_bars.size():
		_swarm_hp_bars[slot].visible = false
	if slot < _swarm_nameplates.size():
		_swarm_nameplates[slot].visible = false
	_append_log("[放浪] %s は気流に乗って消えた" % name)
	if $CombatController.living_enemy_count() == 0:
		_finalize_combat_fled()
		return
	_update_status_labels()
	_update_hp_bars()
	_update_turn_order_ui($CombatController.get_ct_order())

func _process_status_ticks() -> void:
	$CombatController.decay_threat()
	for result: Dictionary in $CombatController.tick_all_statuses():
		var unit_id: String = result.get("unit_id", "")
		var dmg: int = result.get("damage", 0)
		var display_name: String = result.get("display_name", "")
		if dmg <= 0:
			continue
		if unit_id.begins_with("enemy_"):
			var slot: int = int(unit_id.substr(6))
			$CombatController.apply_damage_to_enemy_slot(slot, dmg)
			_check_boss_phase_transition(slot)
			if slot < _swarm_sprites.size() and _swarm_sprites[slot].visible:
				var tick_pos: Vector2 = _sprite_visual_center_global(_swarm_sprites[slot])
				var effect_id: String = str(result.get("effect_id", ""))
				_spawn_damage_number(
					str(dmg),
					_swarm_sprites[slot].global_position,
					CombatVfxManager.dot_telop_color(effect_id)
				)
				if not effect_id.is_empty():
					_combat_vfx.spawn_dot_tick(self, tick_pos, effect_id)
			elif _boss_sprite.visible and slot == $CombatController.active_enemy_index:
				var boss_pos: Vector2 = _sprite_visual_center_global(_boss_sprite)
				var boss_effect: String = str(result.get("effect_id", ""))
				_spawn_damage_number(
					str(dmg),
					_boss_sprite.global_position,
					CombatVfxManager.dot_telop_color(boss_effect)
				)
				if not boss_effect.is_empty():
					_combat_vfx.spawn_dot_tick(self, boss_pos, boss_effect)
			if $CombatController.get_enemy_hp_at(slot) <= 0:
				if _on_enemy_slot_killed(slot):
					return
		elif unit_id.begins_with("party_"):
			var idx: int = int(unit_id.substr(7))
			$CombatController.apply_damage_to_member(idx, dmg)
			if idx < _chr_sprites.size():
				var party_pos: Vector2 = _sprite_visual_center_global(_chr_sprites[idx])
				var party_effect: String = str(result.get("effect_id", ""))
				_spawn_damage_number(
					str(dmg),
					_chr_sprites[idx].global_position,
					CombatVfxManager.dot_telop_color(party_effect)
				)
				if not party_effect.is_empty():
					_combat_vfx.spawn_dot_tick(self, party_pos, party_effect)
		_append_log("[%s] %dダメージ" % [display_name, dmg])
	_update_hp_bars()
	_update_status_icons()

func _try_apply_skill_status() -> void:
	if $CombatController.is_enemy_defeated():
		return
	var member_idx: int = _first_alive_member_index()
	var skill_data: Resource = _get_player_skill_data(member_idx)
	if skill_data == null or skill_data.apply_status_id.is_empty():
		return
	if skill_data.apply_status_chance <= 0.0 or randf() > EvolutionTraits.effective_status_chance(member_idx, skill_data.apply_status_chance):
		return
	var base_info: Dictionary = _calc_attack_base(member_idx)
	if not $CombatController.apply_status_to_active_enemy(
		skill_data.apply_status_id,
		1,
		base_info["base_damage"]
	):
		return
	_on_enemy_status_applied($CombatController.active_enemy_index, skill_data.apply_status_id)
	var effect: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
	var label: String = skill_data.apply_status_id
	if effect != null:
		label = effect.display_name
	_append_log("[%s] 付与" % label)

func _try_apply_secondary_skill_status() -> void:
	if $CombatController.is_enemy_defeated():
		return
	var member_idx: int = _first_alive_member_index()
	var skill_data: Resource = _get_job_skill_data(member_idx)
	if skill_data == null or skill_data.apply_status_id.is_empty():
		return
	var primary: Resource = _get_player_skill_data(member_idx)
	if primary != null and skill_data.id == primary.id:
		return
	if skill_data.apply_status_chance <= 0.0 or randf() > EvolutionTraits.effective_status_chance(member_idx, skill_data.apply_status_chance):
		return
	var base_info: Dictionary = _calc_attack_base(member_idx)
	if not $CombatController.apply_status_to_active_enemy(
		skill_data.apply_status_id,
		1,
		base_info["base_damage"]
	):
		return
	_on_enemy_status_applied($CombatController.active_enemy_index, skill_data.apply_status_id)
	var effect: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
	var label: String = skill_data.apply_status_id
	if effect != null:
		label = effect.display_name
	_append_log("[%s] 付与" % label)

func _try_apply_affix_statuses(member_index: int) -> void:
	if not _member_has_living_target(member_index):
		return
	var bonuses: Dictionary = AffixStatCalculatorScript.get_bonuses(member_index)
	var rules: Array[Dictionary] = [
		{"chance_key": "shock_chance", "status_id": "shock", "label": "感電"},
		{"chance_key": "ignite_chance", "status_id": "ignite", "label": "炎上"},
		{"chance_key": "chill_chance", "status_id": "chill", "label": "冷却"},
		{"chance_key": "poison_chance", "status_id": "poison", "label": "毒"},
	]
	for rule: Dictionary in rules:
		var chance: float = float(bonuses.get(rule["chance_key"], 0.0))
		if chance <= 0.0 or randf() > chance:
			continue
		if not _apply_status_to_member_target(member_index, rule["status_id"], 1, 0):
			continue
		_append_log("[%s] 付与" % rule["label"])

func _try_apply_weapon_on_hit_status(member_index: int) -> void:
	if not _member_has_living_target(member_index):
		return
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	var status_id: String = WeaponStatResolver.resolve_on_hit_status_id(weapon)
	if status_id.is_empty():
		return
	var chance: float = WeaponStatResolver.resolve_on_hit_status_chance(weapon)
	if chance <= 0.0 or randf() > EvolutionTraits.effective_status_chance(member_index, chance):
		return
	var base_info: Dictionary = _calc_attack_base(member_index)
	if not _apply_status_to_member_target(
		member_index, status_id, 1, int(base_info.get("base_damage", 0))
	):
		return
	var effect: Resource = DataRegistry.get_status_effect(status_id)
	var label: String = status_id
	if effect != null:
		label = effect.display_name
	_append_log("[%s] 付与" % label)

# 単一スキルの発動（ダメージ＋状態異常付与）。CDはメンバー×スキルで独立管理。
# cast_index: この tick でそのメンバーが発動した順番（0始まり）。ラベル段組みに使用。
# suppress_resolve_label: 詠唱完了後の再表示を抑止（詠唱中ラベルは呼び出し側で除去済み）。
func _execute_member_skill(
	member_idx: int,
	skill_data: Resource,
	cast_index: int = 0,
	suppress_resolve_label: bool = false
) -> String:
	match skill_data.effect_type:
		"heal":
			return _execute_member_heal(member_idx, skill_data, cast_index, suppress_resolve_label)
		"buff":
			return _execute_member_buff(member_idx, skill_data, cast_index, suppress_resolve_label)
	if not _member_has_living_target(member_idx):
		return ""
	var target_slot: int = $CombatController.get_member_target_slot(member_idx)
	var cd_key: String = _member_skill_cd_key(member_idx, skill_data)
	var base_info: Dictionary = _calc_attack_base(member_idx)
	var is_critical: bool = randf() < base_info["crit_rate"]
	var run_mult: float = $DungeonController.run_damage_multiplier
	var result: Dictionary = _skill_executor.execute_damage_skill(
		skill_data,
		base_info["base_damage"],
		is_critical,
		CRITICAL_MULTIPLIER,
		run_mult,
		cd_key
	)
	if not result.get("executed", false):
		return ""
	var attack_element: String = _resolve_skill_element(skill_data, member_idx)
	var action_range: String = CombatRange.resolve_for_action(member_idx, skill_data)
	var form_tag: String = GameState.formation_range_log_tag(member_idx, action_range)
	var skill_dmg: int = maxi(
		1,
		int(float(result["damage"]) * $CombatController.get_member_outgoing_damage_multiplier(
			member_idx, action_range, true, attack_element, target_slot
		))
	)
	var wpn_skill_mods: Dictionary = CombatPassives.skill_stat_modifiers_for_member(member_idx)
	var weapon_skill_mult: float = 1.0
	if _is_ultimate_skill(skill_data):
		weapon_skill_mult = float(wpn_skill_mods.get("ultimate_power_mult", 1.0))
	else:
		weapon_skill_mult = float(wpn_skill_mods.get("skill_power_mult", 1.0))
	skill_dmg = maxi(1, int(round(float(skill_dmg) * float(weapon_skill_mult))))
	var elem_result: Dictionary = _apply_enemy_mitigation(skill_dmg, attack_element, member_idx, target_slot)
	var final_dmg: int = maxi(
		1,
		int(float(elem_result["damage"]) * $CombatController.get_enemy_incoming_damage_multiplier_at(target_slot))
	)
	final_dmg += _consume_combo_bonus(
		member_idx, final_dmg, _member_action_tags(member_idx, skill_data), skill_data, target_slot
	)
	var skill_is_crit: bool = result.get("is_critical", false)
	var spawn_pos: Vector2 = _enemy_slot_pos(target_slot)
	var is_ultimate: bool = _is_ultimate_skill(skill_data)
	var crit_tag: String = "  CRITICAL!" if skill_is_crit else ""
	var tgt_tag: String = _member_target_tag(member_idx)
	var log_line: String = "\n【スキル】%s: %dダメージ%s%s%s%s" % [
		result["display_name"], final_dmg, crit_tag, elem_result["element_tag"], form_tag, tgt_tag,
	]
	if is_ultimate:
		if cast_index == 0:
			_clear_member_skill_labels(member_idx)
		_play_ultimate_presentation_async({
			"kind": "damage",
			"member_idx": member_idx,
			"skill_data": skill_data,
			"display_name": str(result["display_name"]),
			"final_dmg": final_dmg,
			"target_slot": target_slot,
			"attack_element": attack_element,
			"skill_is_crit": skill_is_crit,
			"spawn_pos": spawn_pos,
			"log_line": log_line,
			"skill_id": str(skill_data.id) if skill_data != null else "",
		})
		return ""
	_play_chr_attack_one(member_idx)
	if cast_index == 0:
		_clear_member_skill_labels(member_idx)
	if not suppress_resolve_label:
		_spawn_skill_name(result["display_name"], member_idx, float(cast_index) * SKILL_LABEL_STACK_GAP, attack_element)
	_resolve_party_skill_damage_impact_async({
		"member_idx": member_idx,
		"skill_data": skill_data,
		"final_dmg": final_dmg,
		"target_slot": target_slot,
		"attack_element": attack_element,
		"skill_is_crit": skill_is_crit,
		"spawn_pos": spawn_pos,
		"log_line": log_line,
		"display_name": str(result.get("display_name", "スキル")),
		"skill_id": str(skill_data.id) if skill_data != null else "",
	})
	return ""

# スキルの状態異常付与（apply_status_id / apply_status_chance）。
func _apply_skill_status(member_idx: int, skill_data: Resource) -> void:
	if not _member_has_living_target(member_idx):
		return
	if skill_data == null or skill_data.apply_status_id.is_empty():
		return
	if skill_data.apply_status_chance <= 0.0 or randf() > EvolutionTraits.effective_status_chance(member_idx, skill_data.apply_status_chance):
		return
	var base_info: Dictionary = _calc_attack_base(member_idx)
	if not _apply_status_to_member_target(member_idx, skill_data.apply_status_id, 1, base_info["base_damage"]):
		return
	var effect: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
	var label: String = skill_data.apply_status_id
	if effect != null:
		label = effect.display_name
	_append_log("[%s] 付与" % label)

# スキルの副次状態付与（apply_status_id2 / apply_status_chance2・P3-D107）。
# 主状態のロール成否とは独立に判定する。
func _apply_skill_secondary_status(member_idx: int, skill_data: Resource) -> void:
	if not _member_has_living_target(member_idx):
		return
	if skill_data == null or skill_data.apply_status_id2.is_empty():
		return
	if skill_data.apply_status_chance2 <= 0.0 or randf() > EvolutionTraits.effective_status_chance(member_idx, skill_data.apply_status_chance2):
		return
	var base_info: Dictionary = _calc_attack_base(member_idx)
	if not _apply_status_to_member_target(member_idx, skill_data.apply_status_id2, 1, base_info["base_damage"]):
		return
	var effect2: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id2)
	var label2: String = skill_data.apply_status_id2
	if effect2 != null:
		label2 = effect2.display_name
	_append_log("[%s] 付与" % label2)

# 回復スキル: 最も負傷した生存メンバーを回復する。負傷者が居なければCDを消費せず発動しない。
func _execute_member_heal(
	member_idx: int,
	skill_data: Resource,
	cast_index: int = 0,
	suppress_resolve_label: bool = false
) -> String:
	var target_idx: int = $CombatController.get_most_injured_member_index()
	if target_idx < 0:
		return ""
	var cd_key: String = _member_skill_cd_key(member_idx, skill_data)
	var result: Dictionary = _skill_executor.execute_support_skill(skill_data, cd_key)
	if not result.get("executed", false):
		return ""
	var heal_amount: int = _apply_healing_bonus(int(round(skill_data.power_multiplier * float(HEAL_SKILL_BASE))), member_idx)
	var is_ultimate: bool = _is_ultimate_skill(skill_data)
	var target_name: String = ""
	var target_member: Resource = GameState.get_combatant(target_idx)
	if target_member != null:
		target_name = target_member.display_name
	if is_ultimate:
		if cast_index == 0:
			_clear_member_skill_labels(member_idx)
		_play_ultimate_presentation_async({
			"kind": "heal",
			"member_idx": member_idx,
			"skill_data": skill_data,
			"display_name": str(result["display_name"]),
			"target_idx": target_idx,
			"target_name": target_name,
			"heal_amount": heal_amount,
		})
		return ""
	var healed: int = $CombatController.heal_member(target_idx, heal_amount)
	if healed > 0:
		GameState.record_run_heal(member_idx, healed)
	_set_heal_rally(target_idx)
	_update_hp_bars()
	if cast_index == 0:
		_clear_member_skill_labels(member_idx)
	if not suppress_resolve_label:
		_spawn_skill_name(result["display_name"], member_idx, float(cast_index) * SKILL_LABEL_STACK_GAP)
	if healed > 0:
		_spawn_member_heal_vfx(target_idx)
		if target_idx >= 0 and target_idx < _chr_sprites.size() and _chr_sprites[target_idx].visible:
			var heal_pos: Vector2 = _chr_sprites[target_idx].global_position + Vector2(0.0, -CHR_BODY_TARGET_PX * 0.5)
			_spawn_damage_number("+%d" % healed, heal_pos, Color(0.45, 1.0, 0.5), 1.1)
	return "\n【スキル】%s: %s を %d回復" % [result["display_name"], target_name, healed]

# バフスキル: 生存中のメイン編成全員に apply_status_id（鼓舞=与ダメ上昇）を付与する。
func _execute_member_buff(
	member_idx: int,
	skill_data: Resource,
	cast_index: int = 0,
	suppress_resolve_label: bool = false
) -> String:
	if skill_data.apply_status_id.is_empty():
		return ""
	var cd_key: String = _member_skill_cd_key(member_idx, skill_data)
	var result: Dictionary = _skill_executor.execute_support_skill(skill_data, cd_key)
	if not result.get("executed", false):
		return ""
	var applied: int = 0
	var status_id: String = skill_data.apply_status_id
	for i: int in GameState.party_members.size():
		if not $CombatController.is_member_alive(i):
			continue
		if $CombatController.apply_status("party_%d" % i, status_id, 1, 0):
			applied += 1
			_on_party_status_applied(i, status_id)
	_update_status_icons()
	if cast_index == 0:
		_clear_member_skill_labels(member_idx)
	if not suppress_resolve_label:
		_spawn_skill_name(result["display_name"], member_idx, float(cast_index) * SKILL_LABEL_STACK_GAP)
	var effect: Resource = DataRegistry.get_status_effect(skill_data.apply_status_id)
	var label: String = skill_data.apply_status_id
	if effect != null:
		label = effect.display_name
	return "\n【スキル】%s: 味方%d体に[%s]" % [result["display_name"], applied, label]

func _get_player_skill_data(member_index: int = -1) -> Resource:
	var skill_id: String = Constants.DEFAULT_PLAYER_SKILL_ID
	var member: Resource = GameState.get_combatant(member_index)
	if member != null:
		var weapon_skill_id: String = WeaponSkillHelper.get_weapon_skill_id(member)
		if not weapon_skill_id.is_empty():
			skill_id = weapon_skill_id
	var skill_data: Resource = DataRegistry.get_skill_data(skill_id)
	if skill_data != null:
		return skill_data
	return DataRegistry.get_skill_data(Constants.DEFAULT_PLAYER_SKILL_ID)

func _member_skill_cd_key(member_idx: int, skill_data: Resource) -> String:
	if skill_data == null:
		return ""
	var member: Resource = GameState.get_combatant(member_idx)
	if member != null and WeaponSkillHelper.get_weapon_skill_id(member) == skill_data.id:
		return WeaponSkillHelper.cooldown_key(member_idx, skill_data.id)
	return "%d:%s" % [member_idx, skill_data.id]

func _get_equipped_weapon_display_name(member_index: int = -1) -> String:
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	return EquipmentEnhancer.get_display_name(weapon)

func _try_cast_player_skill() -> String:
	if $CombatController.is_enemy_defeated():
		return ""
	var member_idx: int = _first_alive_member_index()
	var skill_data: Resource = _get_player_skill_data(member_idx)
	if skill_data == null:
		return ""
	var base_info: Dictionary = _calc_attack_base(member_idx)
	var is_critical: bool = randf() < base_info["crit_rate"]
	var run_mult: float = $DungeonController.run_damage_multiplier
	var result: Dictionary = _skill_executor.execute_damage_skill(
		skill_data,
		base_info["base_damage"],
		is_critical,
		CRITICAL_MULTIPLIER,
		run_mult
	)
	if not result.get("executed", false):
		return ""
	var attack_element: String = _resolve_skill_element(skill_data, member_idx)
	var action_range: String = CombatRange.resolve_for_action(member_idx, skill_data)
	var form_tag: String = GameState.formation_range_log_tag(member_idx, action_range)
	var player_target: int = $CombatController.get_member_target_slot(member_idx)
	var skill_dmg: int = maxi(
		1,
		int(float(result["damage"]) * $CombatController.get_member_outgoing_damage_multiplier(
			member_idx, action_range, true, attack_element, player_target
		))
	)
	var wpn_skill_mods: Dictionary = CombatPassives.skill_stat_modifiers_for_member(member_idx)
	var weapon_skill_mult: float = 1.0
	if _is_ultimate_skill(skill_data):
		weapon_skill_mult = float(wpn_skill_mods.get("ultimate_power_mult", 1.0))
	else:
		weapon_skill_mult = float(wpn_skill_mods.get("skill_power_mult", 1.0))
	skill_dmg = maxi(1, int(round(float(skill_dmg) * float(weapon_skill_mult))))
	var elem_result: Dictionary = _apply_enemy_mitigation(skill_dmg, attack_element)
	var final_dmg: int = maxi(
		1,
		int(
			float(elem_result["damage"])
			* $CombatController.get_enemy_incoming_damage_multiplier()
		)
	)
	final_dmg += _consume_combo_bonus(member_idx, final_dmg, _member_action_tags(member_idx, skill_data), skill_data)
	GameState.record_run_damage(
		member_idx,
		final_dmg,
		str(skill_data.id) if skill_data != null else "",
		str(result.get("display_name", "スキル"))
	)
	$CombatController.apply_damage_to_enemy(final_dmg)
	$CombatController.add_threat(member_idx, float(final_dmg) * CombatController.THREAT_DAMAGE_K)
	var skill_is_crit: bool = result.get("is_critical", false)
	var skill_spawn_pos: Vector2 = _active_enemy_pos()
	_spawn_hit_vfx(skill_spawn_pos, attack_element, 1.0, skill_is_crit)
	_spawn_damage_number(
		str(final_dmg),
		skill_spawn_pos + Vector2(12.0, 0.0),
		_outgoing_damage_telop_color(skill_is_crit),
		1.25 if skill_is_crit else 1.0
	)
	_spawn_skill_name(result["display_name"], member_idx, 0.0, attack_element)
	var skill_crit_tag: String = "  CRITICAL!" if skill_is_crit else ""
	var weapon_name: String = _get_equipped_weapon_display_name(member_idx)
	var skill_header: String = result["display_name"]
	if not weapon_name.is_empty():
		skill_header = "%s / %s" % [weapon_name, result["display_name"]]
	return "\n【スキル】%s: %dダメージ%s%s%s" % [
		skill_header,
		final_dmg,
		skill_crit_tag,
		elem_result["element_tag"],
		form_tag,
	]

func _get_job_skill_data(member_index: int) -> Resource:
	if member_index < 0 or member_index >= GameState.party_members.size():
		return null
	var member: Resource = GameState.party_members[member_index]
	if member == null or member.job_id.is_empty():
		return null
	var job_data: Resource = DataRegistry.get_job_data(member.job_id)
	if job_data == null or job_data.starting_skill_ids.is_empty():
		return null
	return DataRegistry.get_skill_data(job_data.starting_skill_ids[0])

func _try_cast_secondary_skill(primary_skill_id: String) -> String:
	if $CombatController.is_enemy_defeated():
		return ""
	var member_idx: int = _first_alive_member_index()
	var skill_data: Resource = _get_job_skill_data(member_idx)
	if skill_data == null:
		return ""
	if skill_data.id == primary_skill_id:
		return ""
	var base_info: Dictionary = _calc_attack_base(member_idx)
	var is_critical: bool = randf() < base_info["crit_rate"]
	var run_mult: float = $DungeonController.run_damage_multiplier
	var result: Dictionary = _skill_executor.execute_damage_skill(
		skill_data,
		base_info["base_damage"],
		is_critical,
		CRITICAL_MULTIPLIER,
		run_mult
	)
	if not result.get("executed", false):
		return ""
	var attack_element: String = _resolve_skill_element(skill_data, member_idx)
	var action_range: String = CombatRange.resolve_for_action(member_idx, skill_data)
	var form_tag: String = GameState.formation_range_log_tag(member_idx, action_range)
	var sec_target: int = $CombatController.get_member_target_slot(member_idx)
	var skill_dmg: int = maxi(
		1,
		int(float(result["damage"]) * $CombatController.get_member_outgoing_damage_multiplier(
			member_idx, action_range, true, attack_element, sec_target
		))
	)
	var wpn_skill_mods: Dictionary = CombatPassives.skill_stat_modifiers_for_member(member_idx)
	var weapon_skill_mult: float = 1.0
	if _is_ultimate_skill(skill_data):
		weapon_skill_mult = float(wpn_skill_mods.get("ultimate_power_mult", 1.0))
	else:
		weapon_skill_mult = float(wpn_skill_mods.get("skill_power_mult", 1.0))
	skill_dmg = maxi(1, int(round(float(skill_dmg) * float(weapon_skill_mult))))
	var elem_result: Dictionary = _apply_enemy_mitigation(skill_dmg, attack_element)
	var final_dmg: int = maxi(
		1,
		int(
			float(elem_result["damage"])
			* $CombatController.get_enemy_incoming_damage_multiplier()
		)
	)
	final_dmg += _consume_combo_bonus(member_idx, final_dmg, _member_action_tags(member_idx, skill_data), skill_data)
	GameState.record_run_damage(
		member_idx,
		final_dmg,
		str(skill_data.id) if skill_data != null else "",
		str(result.get("display_name", "スキル"))
	)
	$CombatController.apply_damage_to_enemy(final_dmg)
	$CombatController.add_threat(member_idx, float(final_dmg) * CombatController.THREAT_DAMAGE_K)
	var sec_is_crit: bool = result.get("is_critical", false)
	var sec_spawn_pos: Vector2 = _active_enemy_pos()
	_spawn_hit_vfx(sec_spawn_pos, attack_element, 1.0, sec_is_crit)
	_spawn_damage_number(
		str(final_dmg),
		sec_spawn_pos + Vector2(-12.0, 8.0),
		_outgoing_damage_telop_color(sec_is_crit),
		1.25 if sec_is_crit else 1.0
	)
	_spawn_skill_name(result["display_name"], member_idx, 34.0, attack_element)
	var skill_crit_tag: String = "  CRITICAL!" if sec_is_crit else ""
	return "\n【ジョブスキル】%s: %dダメージ%s%s%s" % [
		result["display_name"],
		final_dmg,
		skill_crit_tag,
		elem_result["element_tag"],
		form_tag,
	]

func _get_weapon_element(member_index: int = -1) -> String:
	return DamageCalculator.weapon_element(member_index)

func _resolve_skill_element(skill_data: Resource, member_index: int = -1) -> String:
	return DamageCalculator.resolve_skill_element(skill_data, member_index)

# ── ダメージ計算は DamageCalculator へ分離（P3-REF-001）。以下は薄い委譲。 ──

func _is_biome_favored(attack_element: String) -> bool:
	return DamageCalculator.is_biome_favored(attack_element, $DungeonController.current_dungeon_data)

func _apply_enemy_mitigation(
	damage: int,
	attack_element: String,
	member_index: int = -1,
	target_slot: int = -1
) -> Dictionary:
	return DamageCalculator.enemy_mitigation(
		$CombatController, $DungeonController.current_dungeon_data,
		damage, attack_element, member_index, target_slot
	)

# 状態異常コンボ起爆（P3-D089）。味方の攻撃ヒット時、アクティブ敵に前提状態が
# 乗っていれば 1 つだけ起爆し、追加ダメージを返してその状態を消費する。
# 戻り値は攻撃ダメージへ上乗せする（既存の撃破判定をそのまま通すため）。
func _consume_enemy_combo_bonus(
	member_idx: int,
	hit_damage: int,
	attacker_tags: Array = [],
	target_slot: int = -1
) -> int:
	if target_slot < 0:
		target_slot = $CombatController.get_member_target_slot(member_idx)
	if not $CombatController.is_enemy_slot_alive(target_slot):
		return 0
	for trigger_id: String in CombatCombos.trigger_ids():
		var stacks: int = $CombatController.get_enemy_status_stacks_at(target_slot, trigger_id)
		if stacks <= 0:
			continue
		if not CombatCombos.tag_eligible(trigger_id, attacker_tags):
			continue
		var bonus: int = CombatCombos.bonus_for(trigger_id, stacks, hit_damage)
		if bonus <= 0:
			continue
		$CombatController.consume_enemy_status_at(target_slot, trigger_id)
		var label: String = str(CombatCombos.rule(trigger_id).get("label", "コンボ"))
		var pos: Vector2 = _enemy_slot_pos(target_slot)
		_spawn_damage_number("%s +%d" % [label, bonus], pos + Vector2(0.0, -34.0), Color(1.0, 0.55, 0.15), 1.15)
		_append_log("[コンボ] %s +%d" % [label, bonus])
		return bonus
	return 0

# 1ヒット1コンボ（敵側優先→味方バフ側・P3-D109）＋パーティ連携（P3-D115・コンボと併用可）。
func _consume_combo_bonus(
	member_idx: int,
	hit_damage: int,
	attacker_tags: Array = [],
	skill_data: Resource = null,
	target_slot: int = -1
) -> int:
	var total: int = 0
	var enemy_bonus: int = _consume_enemy_combo_bonus(member_idx, hit_damage, attacker_tags, target_slot)
	if enemy_bonus > 0:
		total += enemy_bonus
	else:
		total += _consume_ally_combo_bonus(member_idx, hit_damage, attacker_tags, skill_data)
	total += _consume_link_bonus(member_idx, hit_damage, target_slot)
	return total

# 味方バフコンボ（鼓舞→必殺等）。攻撃者自身のバフ状態を消費する。
func _consume_ally_combo_bonus(
	member_idx: int,
	hit_damage: int,
	attacker_tags: Array = [],
	skill_data: Resource = null
) -> int:
	if skill_data == null or str(skill_data.slot_type) != "ultimate":
		return 0
	for trigger_id: String in CombatCombos.ally_trigger_ids():
		var stacks: int = $CombatController.get_member_status_stacks(member_idx, trigger_id)
		if stacks <= 0:
			continue
		if not CombatCombos.ally_tag_eligible(trigger_id, attacker_tags):
			continue
		var bonus: int = CombatCombos.ally_bonus_for(trigger_id, stacks, hit_damage)
		if bonus <= 0:
			continue
		$CombatController.consume_member_status(member_idx, trigger_id)
		_update_status_icons()
		var label: String = str(CombatCombos.ally_rule(trigger_id).get("label", "コンボ"))
		var slot: int = $CombatController.get_member_target_slot(member_idx)
		var pos: Vector2 = _enemy_slot_pos(slot)
		_spawn_damage_number("%s +%d" % [label, bonus], pos + Vector2(0.0, -48.0), Color(1.0, 0.75, 0.35), 1.2)
		_append_log("[コンボ] %s +%d" % [label, bonus])
		return bonus
	return 0

# メンバーの現在アクションのシナジータグ（P3-D094）。武器タグ∪スキルタグ。未知idは除外。
func _member_action_tags(member_idx: int, skill_data: Resource = null) -> Array:
	var tags: Array = []
	var winst: Resource = GameState.get_member_equipped_weapon(member_idx)
	if winst != null and not str(winst.weapon_id).is_empty():
		var wd: Resource = DataRegistry.get_weapon_data(winst.weapon_id)
		if wd != null and "tags" in wd:
			for t in wd.tags:
				if CombatTags.is_known(str(t)) and str(t) not in tags:
					tags.append(str(t))
	if skill_data != null and "tags" in skill_data:
		for t in skill_data.tags:
			if CombatTags.is_known(str(t)) and str(t) not in tags:
				tags.append(str(t))
	return tags

func _get_weapon_bane(member_index: int) -> Dictionary:
	return DamageCalculator.weapon_bane(member_index)

func _apply_enemy_defense(damage: int, enemy_data: Resource, def_reduction: float = 0.0) -> int:
	return DamageCalculator.apply_enemy_defense(damage, enemy_data, def_reduction)

func _calc_attack_base(member_index: int = -1) -> Dictionary:
	return DamageCalculator.attack_base($CombatController, member_index)

func _apply_job_attack_multiplier(base_damage: int, member_index: int) -> int:
	return DamageCalculator.apply_job_attack_multiplier(base_damage, member_index)

func _first_alive_member_index() -> int:
	for i in GameState.party_members.size():
		if $CombatController.is_member_alive(i):
			return i
	return -1

# 戦闘中のアクティブ敵スプライト（群れ時は先頭生存スロット、ボス部屋は BossSprite）を返す
func _active_enemy_sprite() -> AnimatedSprite2D:
	if _boss_sprite.visible:
		return _boss_sprite
	var ai: int = $CombatController.active_enemy_index
	if ai >= 0 and ai < _swarm_sprites.size():
		return _swarm_sprites[ai]
	return _enemy_sprite

# VFX/ドロップの発生位置に使うアクティブ敵のグローバル座標。
func _active_enemy_pos() -> Vector2:
	return _enemy_slot_pos($CombatController.active_enemy_index)

func _enemy_slot_pos(slot: int) -> Vector2:
	if slot >= 0 and slot < _swarm_sprites.size() and _swarm_sprites[slot].visible:
		return _swarm_sprites[slot].global_position
	return _active_enemy_sprite().global_position

func _member_target_tag(member_idx: int) -> String:
	if $CombatController.living_enemy_count() <= 1:
		return ""
	var slot: int = $CombatController.get_member_target_slot(member_idx)
	var data: Resource = $CombatController.get_enemy_data_at(slot)
	if data == null:
		return ""
	return " → %s" % data.display_name

func _member_has_living_target(member_idx: int) -> bool:
	return $CombatController.is_enemy_slot_alive($CombatController.get_member_target_slot(member_idx))

# 味方攻撃ダメージをメンバー個別ターゲットへ適用。撃破時は true（全滅で戦闘終了）。
func _deal_member_damage_to_enemy(
	member_idx: int,
	damage: int,
	target_slot: int = -1,
	skill_id: String = "basic_attack",
	skill_name: String = "通常攻撃"
) -> bool:
	if target_slot < 0:
		target_slot = $CombatController.get_member_target_slot(member_idx)
	if not $CombatController.is_enemy_slot_alive(target_slot):
		return false
	GameState.record_run_damage(member_idx, damage, skill_id, skill_name)
	$CombatController.apply_damage_to_enemy_slot(target_slot, damage)
	$CombatController.add_threat(member_idx, float(damage) * CombatController.THREAT_DAMAGE_K)
	_check_boss_phase_transition(target_slot)
	if damage > 0:
		_fire_member_passives(
			member_idx, "on_attack", {"damage": damage, "target_slot": target_slot}
		)
	if $CombatController.get_enemy_hp_at(target_slot) <= 0:
		var frac: float = CombatPassives.on_kill_refund_fraction(member_idx)
		if frac > 0.0:
			$CombatController.refund_member_ct(member_idx, frac)
		return _on_enemy_slot_killed(target_slot)
	return false

func _apply_status_to_member_target(
	member_idx: int,
	effect_id: String,
	stacks: int = 1,
	source_attack: int = 0
) -> bool:
	var slot: int = $CombatController.get_member_target_slot(member_idx)
	var applied: bool = $CombatController.apply_status_to_enemy_slot(slot, effect_id, stacks, source_attack)
	if applied and CombatLinks.is_debuff_mark_status(effect_id):
		_debuff_marks[slot] = member_idx
	if applied:
		_on_enemy_status_applied(slot, effect_id)
	return applied

# ボス/エリートのスキル発動を試行。発動したら true（通常攻撃をスキップ）。
func _try_enemy_skill() -> bool:
	var enemy_data: Resource = $CombatController.current_enemy_data
	if enemy_data == null or enemy_data.skill_ids.is_empty():
		return false
	var slot: int = $CombatController.active_enemy_index
	var enemy_id: String = $CombatController.get_enemy_id_at(slot)
	var phase_idx: int = $CombatController.get_enemy_phase_index(slot)
	var use_chance: float = CombatBossPhases.skill_use_chance(
		enemy_id, phase_idx, float(enemy_data.skill_use_chance)
	)
	if use_chance <= 0.0 or randf() > use_chance:
		return false
	var phase_def: Dictionary = CombatBossPhases.phase_def(enemy_id, phase_idx)
	var skill: Resource = _pick_enemy_skill(enemy_data, phase_def)
	if skill == null:
		return false
	return _try_cast_enemy_skill(slot, skill)

func _pick_enemy_skill(enemy_data: Resource, phase_def: Dictionary) -> Resource:
	var weights: Dictionary = phase_def.get("skill_weight", {})
	var pool: Array = []
	var total: float = 0.0
	for sid in enemy_data.skill_ids:
		var sd: Resource = DataRegistry.get_skill_data(str(sid))
		if sd == null:
			continue
		if not _skill_executor.can_cast(sd, "enemy:%s" % sd.id):
			continue
		var w: float = float(weights.get(str(sid), 1.0))
		pool.append({"skill": sd, "weight": w})
		total += w
	if pool.is_empty():
		return null
	var roll: float = randf() * total
	var acc: float = 0.0
	for item: Dictionary in pool:
		acc += float(item["weight"])
		if roll <= acc:
			return item["skill"]
	return pool[pool.size() - 1]["skill"]

# 敵スキルの詠唱開始または即時発動（P3-D112）。
func _try_cast_enemy_skill(slot: int, skill: Resource) -> bool:
	if skill == null:
		return false
	var cast_time: float = float(skill.cast_time)
	if cast_time <= 0.0:
		return _execute_enemy_skill(skill)
	var cd_key: String = "enemy:%s" % skill.id
	if not _skill_executor.can_cast(skill, cd_key):
		return false
	var turns: int = int(ceil(cast_time))
	$CombatController.begin_enemy_cast(slot, skill.id, turns)
	_play_enemy_slot_animation(slot, "attack")
	_spawn_enemy_cast_name(skill.display_name, slot)
	_append_log("敵が【%s】を詠唱している" % skill.display_name)
	_on_enemy_cast_threat_started(slot, skill)
	return true

func _advance_enemy_cast(slot: int) -> void:
	if $CombatController.should_enemy_skip_action_at(slot):
		var skip_label: String = $CombatController.get_enemy_skip_action_label_at(slot)
		if skip_label.is_empty():
			skip_label = "鈍化"
		$CombatController.clear_pending_cast("enemy", slot)
		_append_log("[%s] 敵の詠唱が中断された" % skip_label)
		return
	var pending: Dictionary = $CombatController.get_pending_cast("enemy", slot)
	if pending.is_empty():
		return
	var skill: Resource = DataRegistry.get_skill_data(str(pending.get("skill_id", "")))
	if skill == null:
		$CombatController.clear_pending_cast("enemy", slot)
		return
	var state: String = $CombatController.advance_pending_cast("enemy", slot)
	if state == "chant":
		_play_enemy_slot_animation(slot, "attack")
		_spawn_enemy_cast_name(skill.display_name, slot)
		_append_log("敵の【%s】詠唱中…" % skill.display_name)
		_update_combat_now_playing_for("enemy", slot)
		return
	$CombatController.clear_pending_cast("enemy", slot)
	_execute_enemy_skill(skill)

func _execute_enemy_skill(skill: Resource) -> bool:
	var res: Dictionary = _skill_executor.execute_support_skill(skill, "enemy:%s" % skill.id)
	if not res.get("executed", false):
		return false
	match skill.effect_type:
		"buff":
			_execute_enemy_buff(skill)
			return true
		"damage":
			_execute_enemy_damage(skill)
			return true
	return false

# 敵の自己強化スキル（激昂など）。enemy ユニットに状態付与し与ダメを上昇。
func _execute_enemy_buff(skill: Resource) -> void:
	_play_active_enemy_animation("attack")
	_spawn_enemy_skill_name(skill.display_name)
	var label: String = skill.display_name
	if not skill.apply_status_id.is_empty():
		if $CombatController.apply_status_to_active_enemy(skill.apply_status_id, 1, 0):
			_on_enemy_status_applied($CombatController.active_enemy_index, skill.apply_status_id)
		var eff: Resource = DataRegistry.get_status_effect(skill.apply_status_id)
		if eff != null:
			label = eff.display_name
	_append_log("敵スキル【%s】: 自身に[%s]" % [skill.display_name, label])

# 敵の攻撃スキル（全体/列/単体）。power_multiplier 分のダメージを対象へ。
func _execute_enemy_damage(skill: Resource) -> void:
	_play_active_enemy_animation("attack")
	_spawn_enemy_skill_name(skill.display_name)
	var party_size: int = $CombatController.party_combat_hp.size()
	var target_type: String = str(skill.target_type)
	var used_fallback: bool = false
	var targets: Array[int] = []
	var dist_tag: String = ""
	var shares: Dictionary = {}
	if target_type in [CombatFormation.TARGET_PARTY_FRONT, CombatFormation.TARGET_PARTY_BACK]:
		var resolved: Dictionary = CombatFormation.resolve_column_members_with_fallback(
			target_type,
			party_size,
			Callable($CombatController, "is_member_alive")
		)
		targets = resolved["indices"]
		used_fallback = bool(resolved.get("fallback", false))
		if not targets.is_empty():
			shares = CombatFormation.threat_damage_shares(
				targets, Callable($CombatController, "get_member_threat")
			)
			dist_tag = CombatFormation.column_distribution_log_tag(targets)
	else:
		targets = CombatFormation.resolve_enemy_party_targets(
			skill,
			party_size,
			Callable($CombatController, "is_member_alive"),
			Callable($CombatController, "pick_enemy_target_for_melee_attack").bind(
				$CombatController.active_enemy_index
			)
		)
		for ti: int in targets:
			shares[ti] = 1.0
	if targets.is_empty():
		var empty_tag: String = CombatFormation.enemy_target_row_log_tag(target_type, used_fallback)
		_append_log("敵スキル【%s】%s\n  対象なし" % [skill.display_name, empty_tag])
		return
	_resolve_enemy_skill_damage_impact_async({
		"skill": skill,
		"targets": targets,
		"shares": shares,
		"dist_tag": dist_tag,
		"target_type": target_type,
		"used_fallback": used_fallback,
	})


func _resolve_enemy_skill_damage_impact_async(payload: Dictionary) -> void:
	var skill: Resource = payload.get("skill") as Resource
	var targets: Array[int] = payload.get("targets", []) as Array[int]
	var shares: Dictionary = payload.get("shares", {}) as Dictionary
	var dist_tag: String = str(payload.get("dist_tag", ""))
	var target_type: String = str(payload.get("target_type", ""))
	var used_fallback: bool = bool(payload.get("used_fallback", false))
	_begin_combat_cinematic_lock()
	var sprite: AnimatedSprite2D = _active_enemy_sprite()
	await get_tree().create_timer(_attack_anim_impact_delay(sprite)).timeout
	if not $CombatController.is_in_combat:
		_end_combat_cinematic_lock()
		return
	_apply_enemy_damage_to_targets(skill, targets, shares, dist_tag, target_type, used_fallback)
	_update_hp_bars()
	if $CombatController.is_party_wiped():
		_end_combat_cinematic_lock()
		_handle_party_wipe()
		return
	_end_combat_cinematic_lock()

func _apply_enemy_damage_to_targets(
	skill: Resource,
	targets: Array[int],
	shares: Dictionary,
	dist_tag: String,
	target_type: String,
	used_fallback: bool
) -> void:
	var row_tag: String = CombatFormation.enemy_target_row_log_tag(target_type, used_fallback)
	var lines: PackedStringArray = []
	var atk_slot: int = $CombatController.active_enemy_index
	for ti: int in targets:
		var share: float = float(shares.get(ti, 0.0))
		if share <= 0.0:
			continue
		var power: float = float(skill.power_multiplier) * share
		var dmg_result: Dictionary = _calc_enemy_damage_to_member(ti, power, -1, atk_slot)
		var member: Resource = GameState.get_combatant(ti)
		var mname: String = member.display_name if member != null else "?"
		if dmg_result.get("missed", false):
			if ti < _chr_sprites.size():
				_spawn_miss_telop(_chr_sprites[ti].global_position)
			lines.append("%s は Miss!" % mname)
			continue
		var dmg: int = int(dmg_result["final"])
		if targets.size() > 1:
			dmg = maxi(1, dmg)
		$CombatController.apply_damage_to_member(ti, dmg)
		$CombatController.add_threat(ti, float(dmg) * CombatController.THREAT_TAKEN_K)
		_play_chr_hurt(ti)
		if dmg > 0 and ti < _chr_sprites.size():
			_spawn_hit_vfx(_chr_sprites[ti].global_position)
			_spawn_damage_number(str(dmg), _chr_sprites[ti].global_position, Color(1.0, 0.35, 0.35))
		var density_tag: String = $CombatController.get_density_log_tag(ti)
		if not $CombatController.is_member_alive(ti):
			if ti < _chr_sprites.size():
				_chr_sprites[ti].visible = false
			lines.append("%s に %d（撃破）%s" % [mname, dmg, density_tag])
		else:
			lines.append("%s に %d%s" % [mname, dmg, density_tag])
		_on_member_damaged(ti, {"attacker_slot": atk_slot})
	_append_log("敵スキル【%s】%s%s\n  %s" % [skill.display_name, row_tag, dist_tag, " / ".join(lines)])

# 敵スキル発動時、敵ドット絵の頭上にスキル名を赤系でポップ表示
func _spawn_enemy_skill_name(skill_name: String) -> void:
	if skill_name.is_empty():
		return
	var spr: AnimatedSprite2D = _active_enemy_sprite()
	if not spr.visible:
		return
	const ENEMY_SKILL_FONT_SIZE: int = 26
	var lbl := Label.new()
	lbl.text = skill_name
	var af: Font = UiTypography.impact_font()
	if af != null:
		lbl.add_theme_font_override("font", af)
	lbl.add_theme_font_size_override("font_size", ENEMY_SKILL_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0, 0.95))
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	var base_y: float = spr.global_position.y - 150.0
	lbl.pivot_offset = Vector2(float(skill_name.length()) * ENEMY_SKILL_FONT_SIZE * 0.5, ENEMY_SKILL_FONT_SIZE * 0.5)
	lbl.position = Vector2(
		spr.global_position.x - float(skill_name.length()) * ENEMY_SKILL_FONT_SIZE * 0.5,
		base_y
	)
	# ボス/敵技は一瞬大きく出して威圧感を出す
	lbl.scale = Vector2(1.3, 1.3)
	lbl.modulate.a = 0.0
	_damage_numbers_layer.add_child(lbl)
	var tw: Tween = create_tween()
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(lbl, "modulate:a", 1.0, 0.12)
	tw.chain().set_parallel(true)
	tw.tween_property(lbl, "position:y", base_y - 26.0, 0.7)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.35)
	tw.chain().tween_callback(lbl.queue_free)

# 敵の詠唱中ポップ（P3-D112・紫系で通常スキル名と差別化）
func _spawn_enemy_cast_name(skill_name: String, slot: int) -> void:
	if skill_name.is_empty():
		return
	if slot < 0 or slot >= _swarm_sprites.size():
		_spawn_enemy_skill_name(skill_name)
		return
	var spr: AnimatedSprite2D = _swarm_sprites[slot]
	if not spr.visible:
		_spawn_enemy_skill_name(skill_name)
		return
	const CAST_FONT_SIZE: int = 22
	var lbl := Label.new()
	lbl.text = "◆ %s" % skill_name
	var af: Font = UiTypography.impact_font()
	if af != null:
		lbl.add_theme_font_override("font", af)
	lbl.add_theme_font_size_override("font_size", CAST_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.55, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.0, 0.12, 0.95))
	lbl.add_theme_constant_override("outline_size", 6)
	var base_y: float = spr.global_position.y - 130.0
	lbl.position = Vector2(
		spr.global_position.x - float(lbl.text.length()) * CAST_FONT_SIZE * 0.28,
		base_y
	)
	lbl.modulate.a = 0.0
	_damage_numbers_layer.add_child(lbl)
	var tw: Tween = create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.12)
	tw.chain().set_parallel(true)
	tw.tween_property(lbl, "position:y", base_y - 18.0, 0.55)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4).set_delay(0.25)
	tw.chain().tween_callback(lbl.queue_free)

func _do_enemy_attack(slot: int = -1) -> void:
	if $CombatController.current_enemy_data == null:
		return
	var target_idx: int = $CombatController.pick_enemy_target_for_melee_attack(slot)
	if target_idx < 0:
		return
	if slot >= 0:
		_play_enemy_slot_animation(slot, "attack")
	else:
		_play_active_enemy_animation("attack")
	_resolve_enemy_attack_impact_async({
		"slot": slot,
		"target_idx": target_idx,
	})


func _resolve_enemy_attack_impact_async(payload: Dictionary) -> void:
	var slot: int = int(payload.get("slot", -1))
	var target_idx: int = int(payload.get("target_idx", -1))
	_begin_combat_cinematic_lock()
	var sprite: AnimatedSprite2D = null
	if slot >= 0 and slot < _swarm_sprites.size() and _swarm_sprites[slot].visible:
		sprite = _swarm_sprites[slot]
	elif _boss_sprite.visible:
		sprite = _boss_sprite
	elif _enemy_sprite.visible:
		sprite = _enemy_sprite
	await get_tree().create_timer(_attack_anim_impact_delay(sprite)).timeout
	if not $CombatController.is_in_combat:
		_end_combat_cinematic_lock()
		return
	if target_idx < 0 or not $CombatController.is_member_alive(target_idx):
		_end_combat_cinematic_lock()
		return
	var attacker_atk: int = $CombatController.get_enemy_attack_at(slot) if slot >= 0 else -1
	var enemy_result: Dictionary = _calc_enemy_damage_to_member(target_idx, 1.0, attacker_atk, slot)
	var target_combatant: Resource = GameState.get_combatant(target_idx)
	var member_name: String = target_combatant.display_name if target_combatant != null else "?"
	var guard_prefix: String = ""
	if target_combatant != null and target_combatant.job_id == "swordsman":
		guard_prefix = "[前衛] "
	if enemy_result.get("missed", false):
		if target_idx < _chr_sprites.size():
			_spawn_miss_telop(_chr_sprites[target_idx].global_position)
		_append_log("敵の攻撃: %s%s は Miss!" % [guard_prefix, member_name])
		_end_combat_cinematic_lock()
		return
	$CombatController.apply_damage_to_member(target_idx, enemy_result["final"])
	$CombatController.add_threat(target_idx, float(enemy_result["final"]) * CombatController.THREAT_TAKEN_K)
	_play_chr_hurt(target_idx)
	if enemy_result["final"] > 0 and target_idx < _chr_sprites.size():
		_spawn_hit_vfx(_chr_sprites[target_idx].global_position)
		_spawn_damage_number(str(enemy_result["final"]), _chr_sprites[target_idx].global_position, Color(1.0, 0.35, 0.35))
	if not $CombatController.is_member_alive(target_idx) and target_idx < _chr_sprites.size():
		_chr_sprites[target_idx].visible = false
	var resist_tag: String = ""
	if enemy_result.get("elem_resisted", false):
		resist_tag = "  [耐性:%s]" % ElementResolverScript.get_display_name(_enemy_attack_element_at(slot))
	var density_tag: String = $CombatController.get_density_log_tag(target_idx)
	var log_text: String
	if enemy_result["mitigated"] > 0:
		log_text = "敵の攻撃: %s%s に %dダメージ（軽減%d）%s%s" % [
			guard_prefix, member_name, enemy_result["final"], enemy_result["mitigated"], density_tag, resist_tag,
		]
	else:
		log_text = "敵の攻撃: %s%s に %dダメージ%s%s" % [
			guard_prefix, member_name, enemy_result["final"], density_tag, resist_tag,
		]
	if not $CombatController.is_member_alive(target_idx):
		log_text += "\n%s が倒れた！" % member_name
	_append_log(log_text)
	_on_member_damaged(target_idx, {"attacker_slot": slot})
	_try_apply_enemy_hit_status(target_idx, slot)
	_update_hp_bars()
	if $CombatController.is_party_wiped():
		_end_combat_cinematic_lock()
		_handle_party_wipe()
		return
	_end_combat_cinematic_lock()

func _try_apply_enemy_hit_status(target_idx: int, attacker_slot: int = -1) -> void:
	var slot: int = attacker_slot if attacker_slot >= 0 else $CombatController.active_enemy_index
	var enemy_data: Resource = $CombatController.get_enemy_data_at(slot)
	if enemy_data == null or enemy_data.on_hit_status_id.is_empty():
		return
	if enemy_data.on_hit_status_id == "curse":
		var room_type: int = $DungeonController.current_room_type
		var is_elevated: bool = (
			room_type == Enums.RoomType.ELITE
			or room_type == Enums.RoomType.BOSS
		)
		if not is_elevated:
			return
	if enemy_data.on_hit_status_chance <= 0.0 or randf() > enemy_data.on_hit_status_chance:
		return
	var unit_id: String = "party_%d" % target_idx
	var source_atk: int = $CombatController.get_enemy_attack_at(slot)
	if not $CombatController.apply_status(unit_id, enemy_data.on_hit_status_id, 1, source_atk):
		return
	_on_party_status_applied(target_idx, enemy_data.on_hit_status_id)
	var effect: Resource = DataRegistry.get_status_effect(enemy_data.on_hit_status_id)
	var label: String = enemy_data.on_hit_status_id
	if effect != null:
		label = effect.display_name
	var hit_target: Resource = GameState.get_combatant(target_idx)
	var member_name: String = hit_target.display_name if hit_target != null else "?"
	_append_log("[%s] %s に付与" % [label, member_name])

func _calc_damage(member_index: int = -1, target_slot: int = -1) -> Dictionary:
	return DamageCalculator.member_attack_damage(
		$CombatController, $DungeonController.current_dungeon_data,
		$DungeonController.run_damage_multiplier, member_index, target_slot
	)

func _calc_enemy_damage_to_member(
	target_index: int,
	power_multiplier: float = 1.0,
	attacker_atk: int = -1,
	attacker_slot: int = -1
) -> Dictionary:
	return DamageCalculator.enemy_damage_to_member(
		$CombatController, target_index, power_multiplier, attacker_atk, attacker_slot
	)

func _active_enemy_attack_element() -> String:
	return _enemy_attack_element_at($CombatController.active_enemy_index)

func _enemy_attack_element_at(slot: int) -> String:
	return DamageCalculator.enemy_attack_element_at($CombatController, slot)

func _member_resists_element(target_index: int, attack_element: String) -> bool:
	return DamageCalculator.member_resists_element(target_index, attack_element)

# 武器強化素材のみドロップ（炉研ぎ消費素材＝P3-D152 / P3-D067 改）。
const ENHANCEMENT_DROP_CHANCE: Dictionary = {0: 0.65, 1: 0.35, 2: 0.12, 3: 0.05}
const CODEX_INVESTIGATION_EXP_BONUS: float = 1.10
const CODEX_INVESTIGATION_MATERIAL_MULT: float = 1.50

func _roll_enhancement_material_drops(
	_enemy_data: Resource,
	log_lines: PackedStringArray,
	drop_icons: Array = []
) -> void:
	var mat_id: String = EquipmentEnhancer.pick_combat_drop_material()
	if not EquipmentEnhancer.is_enhancement_material(mat_id):
		return
	var mat_data: Resource = DataRegistry.get_material_data(mat_id)
	var rarity: int = 0 if mat_data == null else int(mat_data.rarity)
	var chance: float = float(ENHANCEMENT_DROP_CHANCE.get(rarity, 0.05))
	var codex_boost: bool = (
		GameState.get_exploration_policy() == "codex"
		and _enemy_data != null
		and GameState.get_enemy_stage(str(_enemy_data.id)) < 5
	)
	if codex_boost:
		chance = minf(chance * CODEX_INVESTIGATION_MATERIAL_MULT, 1.0)
	if randf() > chance:
		return
	var amount: int = _apply_material_bonus(1)
	GameState.add_material(mat_id, amount)
	log_lines.append("採取: %s" % _format_material_reward_log(mat_id, amount, ""))
	_try_register_discovery("material", mat_id)
	_append_material_drop_icons(drop_icons, mat_id, amount)

# アクティブ敵 1体の撃破ブックキーピング（P3-D082/D083/D111）。
func _award_enemy_kill_at(killed_slot: int) -> void:
	var room_type: int = $DungeonController.current_room_type
	$CombatController.clear_enemy_slot_status(killed_slot)
	$CombatController.capture_rewards_at(killed_slot)
	var defeated_enemy: Resource = $CombatController.get_enemy_data_at(killed_slot)
	var codex_investigation: bool = false
	if defeated_enemy != null:
		codex_investigation = (
			GameState.get_exploration_policy() == "codex"
			and GameState.get_enemy_stage(str(defeated_enemy.id)) < 5
		)
		GameState.add_enemy_kill(defeated_enemy.id)
		var field_codex_extra: int = EventSystem.get_codex_kill_extra_count()
		if field_codex_extra > 0 and GameState.get_enemy_stage(str(defeated_enemy.id)) < 5:
			for _i in field_codex_extra:
				GameState.add_enemy_kill(defeated_enemy.id)
		# 探索方針（図鑑優先）撃破1回につき図鑑進捗を加速（P3-D098）
		if GameState.get_exploration_policy() == "codex":
			GameState.add_enemy_kill(defeated_enemy.id)
	var mult: float = $DungeonController.get_reward_multiplier()
	var exp_event_mult: float = EventSystem.get_modifier_mult(EventSystem.MOD_EXP)
	var gold_event_mult: float = EventSystem.get_modifier_mult(EventSystem.MOD_GOLD)
	var tier_reward_mult: float = _DungeonTierConfig.reward_mult(GameState.current_dungeon_tier)
	var evo_exp_mult: float = EvolutionTraits.party_exp_mult()
	var final_exp: int = int($CombatController.last_exp_reward * mult * exp_event_mult * tier_reward_mult * evo_exp_mult)
	var final_gold: int = int($CombatController.last_gold_reward * mult * gold_event_mult * tier_reward_mult)
	if codex_investigation:
		final_exp = int(round(float(final_exp) * CODEX_INVESTIGATION_EXP_BONUS))
	$DungeonController.accumulate_rewards(final_exp, final_gold)
	if room_type == Enums.RoomType.BOSS:
		$DungeonController.update_discovery($DungeonController.DISCOVERY_BOSS_BONUS)
		_play_boss_animation("death")
	else:
		_play_enemy_slot_animation(killed_slot, "death")
		if killed_slot >= 0 and killed_slot < _swarm_hp_bars.size():
			_swarm_hp_bars[killed_slot].visible = false
			_swarm_nameplates[killed_slot].visible = false
	var bonus_tag: String = " (x%.1f)" % mult if mult > 1.0 else ""
	if exp_event_mult > 1.0 or gold_event_mult > 1.0:
		bonus_tag += " [野外]"
	if tier_reward_mult > 1.0:
		bonus_tag += " [%s]" % _DungeonTierConfig.display_name(GameState.current_dungeon_tier)
	if codex_investigation:
		bonus_tag += " [図鑑調査]"
	var log_lines: PackedStringArray = [
		"撃破!  経験値 +%d  ゴールド +%d%s" % [final_exp, final_gold, bonus_tag],
	]
	var kill_pos: Vector2 = _enemy_slot_pos(killed_slot)
	var drop_icons: Array = []
	if final_gold > 0:
		_append_gold_drop_icons(drop_icons, final_gold)
	if room_type == Enums.RoomType.COMBAT and defeated_enemy != null:
		_roll_enhancement_material_drops(defeated_enemy, log_lines, drop_icons)
	# P3-D074/D082/WANDER-002: 撃破ごとの装備直ドロップ（各敵個別判定）
	var equip_drop: Dictionary = $DungeonController.roll_kill_equip_drop(room_type, defeated_enemy)
	if not equip_drop.is_empty():
		var drop_cat: String = str(equip_drop.get("category", "weapon"))
		var drop_id: String = str(equip_drop.get("id", ""))
		match drop_cat:
			"armor":
				GameState.last_run_armor_dropped = drop_id
				log_lines.append("防具ドロップ: %s" % DataRegistry.get_armor_name(drop_id))
			"accessory":
				GameState.last_run_accessory_dropped = drop_id
				log_lines.append("装飾ドロップ: %s" % DataRegistry.get_accessory_name(drop_id))
			_:
				GameState.last_run_weapon_dropped = drop_id
				log_lines.append("武器ドロップ: %s" % DataRegistry.get_weapon_name(drop_id))
		_append_equipment_drop_icon(drop_icons, drop_id, drop_cat)
	if room_type == Enums.RoomType.BOSS:
		var stage: Resource = $DungeonController.current_stage_data
		if stage != null:
			var legendary_bonus: Dictionary = $DungeonController.apply_boss_legendary_loot(stage)
			if not str(legendary_bonus.get("armor_id", "")).is_empty():
				GameState.last_run_armor_dropped = str(legendary_bonus["armor_id"])
				log_lines.append(
					"ボス報酬: 防具 %s" % DataRegistry.get_armor_name(str(legendary_bonus["armor_id"]))
				)
				_append_equipment_drop_icon(drop_icons, str(legendary_bonus["armor_id"]), "armor")
			if not str(legendary_bonus.get("accessory_id", "")).is_empty():
				GameState.last_run_accessory_dropped = str(legendary_bonus["accessory_id"])
				log_lines.append(
					"ボス報酬: 装飾品 %s" % DataRegistry.get_accessory_name(str(legendary_bonus["accessory_id"]))
				)
				_append_equipment_drop_icon(drop_icons, str(legendary_bonus["accessory_id"]), "accessory")
			var mythic_bonus: Dictionary = $DungeonController.apply_boss_mythic_loot(stage)
			var mythic_id: String = str(mythic_bonus.get("id", ""))
			var mythic_cat: String = str(mythic_bonus.get("category", ""))
			if not mythic_id.is_empty():
				match mythic_cat:
					"weapon":
						GameState.last_run_weapon_dropped = mythic_id
						log_lines.append("神話の招き: 武器 %s" % DataRegistry.get_weapon_name(mythic_id))
					"armor":
						GameState.last_run_armor_dropped = mythic_id
						log_lines.append("神話の招き: 防具 %s" % DataRegistry.get_armor_name(mythic_id))
					"accessory":
						GameState.last_run_accessory_dropped = mythic_id
						log_lines.append("神話の招き: 装飾品 %s" % DataRegistry.get_accessory_name(mythic_id))
				_append_equipment_drop_icon(drop_icons, mythic_id, mythic_cat)
		var boss_mat: Dictionary = $DungeonController.apply_boss_material_loot()
		var boss_mat_id: String = str(boss_mat.get("material_id", "elite_relic_shard"))
		var boss_mat_amt: int = int(boss_mat.get("amount", 1))
		log_lines.append(
			"ボス報酬: %s" % _format_material_reward_log(boss_mat_id, boss_mat_amt, "")
		)
		_append_material_drop_icons(drop_icons, boss_mat_id, boss_mat_amt)
		var boss_bonus_mat_id: String = str(boss_mat.get("bonus_material_id", ""))
		var boss_bonus_mat_amt: int = int(boss_mat.get("bonus_material_amount", 0))
		if not boss_bonus_mat_id.is_empty() and boss_bonus_mat_amt > 0:
			log_lines.append(
				"ボス報酬: %s" % _format_material_reward_log(boss_bonus_mat_id, boss_bonus_mat_amt, "")
			)
			_append_material_drop_icons(drop_icons, boss_bonus_mat_id, boss_bonus_mat_amt)
	if room_type == Enums.RoomType.ELITE:
		var elite_bonus: Dictionary = $DungeonController.apply_elite_bonus_loot()
		if not (elite_bonus["armor_id"] as String).is_empty():
			GameState.last_run_armor_dropped = elite_bonus["armor_id"]
			log_lines.append("エリート報酬: 防具 %s" % DataRegistry.get_armor_name(elite_bonus["armor_id"]))
			_append_equipment_drop_icon(drop_icons, str(elite_bonus["armor_id"]), "armor")
		if not (elite_bonus["accessory_id"] as String).is_empty():
			log_lines.append("エリート報酬: 装飾品 %s" % DataRegistry.get_accessory_name(elite_bonus["accessory_id"]))
			GameState.last_run_accessory_dropped = elite_bonus["accessory_id"]
			_append_equipment_drop_icon(drop_icons, str(elite_bonus["accessory_id"]), "accessory")
		if not str(elite_bonus.get("material_id", "")).is_empty():
			var elite_mat_amt: int = int(elite_bonus.get("material_amount", 1))
			log_lines.append(
				"エリート報酬: %s" % _format_material_reward_log(
					str(elite_bonus["material_id"]),
					elite_mat_amt,
					""
				)
			)
			_append_material_drop_icons(drop_icons, str(elite_bonus["material_id"]), elite_mat_amt)
	_spawn_pickup_drop_burst(kill_pos, drop_icons)
	# P3-D093: 撃破時の遺物ドロップ（解放型）
	var dropped_relic: String = $DungeonController.roll_kill_relic_drop(room_type)
	if not dropped_relic.is_empty():
		GameState.last_run_relic_dropped = dropped_relic
		log_lines.append("レリック入手: %s" % CombatRelics.display_name(dropped_relic))
		_play_relic_get_celebration(dropped_relic)
	_append_log("\n".join(log_lines))

# 敵スロット撃破時。全滅なら true（戦闘終了済み）。
func _on_enemy_slot_killed(killed_slot: int) -> bool:
	$CombatController.clear_pending_cast("enemy", killed_slot)
	_debuff_marks.erase(killed_slot)
	_award_enemy_kill_at(killed_slot)
	if killed_slot == $CombatController.active_enemy_index:
		$CombatController.advance_active_enemy()
	elif not $CombatController.is_enemy_slot_alive($CombatController.active_enemy_index):
		$CombatController.advance_active_enemy()
	if $CombatController.living_enemy_count() == 0:
		_finalize_combat_cleared()
		return true
	_append_log("残り %d 体" % $CombatController.living_enemy_count())
	_update_status_labels()
	_update_hp_bars()
	_update_turn_order_ui($CombatController.get_ct_order())
	return false

func _on_active_enemy_killed() -> bool:
	return _on_enemy_slot_killed($CombatController.active_enemy_index)

# 群れ全滅で戦闘を終了する（P3-D083）。
func _finalize_combat_cleared() -> void:
	$CombatTimer.stop()
	$CombatController.end_combat()
	_combat_vfx.clear_all()
	_clear_all_member_skill_labels()
	_update_status_labels()
	_clear_turn_order_ui()
	DailyMissionSystem.report_progress("combat_win")
	var enemy_lv: int = 1
	if $DungeonController.current_stage_data != null:
		enemy_lv = int($DungeonController.current_stage_data.enemy_level)
	elif $DungeonController.current_dungeon_data != null:
		enemy_lv = int($DungeonController.current_dungeon_data.enemy_level)
	EquipmentEnhancer.grant_party_combat_exp(enemy_lv, GameState.party_members)
	_append_log("累計  経験値 %d  ゴールド %d" % [
		$DungeonController.run_exp_reward,
		$DungeonController.run_gold_reward,
	])
	_update_enemy_label()
	_update_hp_bars()
	_update_next_room_button()
	_show_chr_sprites(false)
	# クリアBGMは ResultScene のみ。戦闘直後は探索へ戻す。
	AudioManager.play_bgm("dungeon_explore")
	if $DungeonController.is_on_last_floor_before_exit():
		_play_combat_clear_celebration(true)
	else:
		_start_auto_progress()

# 放浪個体が逃走して戦闘が空になった場合（報酬・日課なし）。
func _finalize_combat_fled() -> void:
	$CombatTimer.stop()
	$CombatController.end_combat()
	_combat_vfx.clear_all()
	_clear_all_member_skill_labels()
	_update_status_labels()
	_clear_turn_order_ui()
	_append_log("放浪個体は去った…")
	_update_enemy_label()
	_update_hp_bars()
	_update_next_room_button()
	_start_auto_progress()

# 単体メンバーの 1 行動（P3-D086）。戦術プラン（優先度＋発動条件）に従い、
# 条件成立かつ実際に発動できた最初のスロットで行動を確定する。
func _do_member_turn(member_idx: int) -> void:
	if not $CombatController.is_member_alive(member_idx):
		if $CombatController.has_pending_cast("party", member_idx):
			$CombatController.clear_pending_cast("party", member_idx)
			_clear_member_skill_labels(member_idx)
		return
	_update_combat_now_playing_for("party", member_idx)
	if $CombatController.has_pending_cast("party", member_idx):
		_advance_member_cast(member_idx)
		return
	if $CombatController.should_member_skip_action_at(member_idx):
		var skip_member: Resource = GameState.get_combatant(member_idx)
		var skip_label: String = $CombatController.get_member_skip_action_label_at(member_idx)
		if skip_label.is_empty():
			skip_label = "鈍化"
		var mname: String = skip_member.display_name if skip_member != null else "?"
		_append_log("[%s] %s は行動できなかった" % [skip_label, mname])
		return
	_fire_member_passives(member_idx, "on_action_start")
	var member: Resource = GameState.get_combatant(member_idx)
	$CombatController.resolve_member_target(member_idx, CombatGambit.target_from_member(member))
	var ctx: Dictionary = _build_tactics_context(member_idx)
	var any_condition_met: bool = false
	for rule: Dictionary in CombatGambit.plan_from_member(member):
		if not CombatTactics.condition_met(rule, ctx):
			continue
		any_condition_met = true
		var slot_id: String = str(rule.get("slot", ""))
		var fired: bool = false
		match slot_id:
			"ultimate":
				fired = _try_member_ultimate(member_idx)
			"defend":
				fired = _do_member_defend_slot(member_idx)
			"skill":
				var skill_idx: int = int(rule.get("skill_index", -1))
				if skill_idx >= 0:
					fired = _try_member_equipped_skill_at(member_idx, skill_idx)
				else:
					fired = _try_member_equipped_skill(member_idx)
				if not fired:
					fired = _try_member_weapon_skill(member_idx)
			"attack":
				_do_member_basic_attack(member_idx)
				fired = true
		if fired:
			_append_tactics_log(rule, member_idx)
			return
	_append_tactics_fallback_log(any_condition_met)
	_do_member_basic_attack(member_idx)

# 群れ(2体以上)時のみ作用（P3-D110: 敵別状態スロットで個体ごと保持・切替可）。
# 廃止（P3-D111）: パーティ一括フォーカス → メンバー個別ターゲットへ移行。

# 戦術条件の評価に使う戦闘コンテキスト。
func _build_tactics_context(member_idx: int) -> Dictionary:
	var hp_ratio: float = 1.0
	if member_idx >= 0 and member_idx < $CombatController.party_max_hp.size():
		var maxhp: int = $CombatController.party_max_hp[member_idx]
		if maxhp > 0:
			hp_ratio = float($CombatController.party_combat_hp[member_idx]) / float(maxhp)
	var room_type: int = $DungeonController.current_room_type
	var ally_dead: bool = false
	for i: int in GameState.party_members.size():
		if not $CombatController.is_member_alive(i):
			ally_dead = true
			break
	var target_slot: int = $CombatController.get_member_target_slot(member_idx)
	return {
		"self_hp_ratio": hp_ratio,
		"enemy_is_boss": room_type == Enums.RoomType.BOSS,
		"enemy_is_elite": room_type == Enums.RoomType.ELITE,
		"enemy_count": $CombatController.living_enemy_count(),
		"ally_dead": ally_dead,
		"enemy_has_bleed": $CombatController.get_enemy_status_stacks_at(target_slot, "bleed") > 0,
		"enemy_has_poison": $CombatController.get_enemy_status_stacks_at(target_slot, "poison") > 0,
		"enemy_has_mark": _any_enemy_has_status("mark"),
		"enemy_has_stun": _any_enemy_has_status("stun"),
		"enemy_has_vulnerable": _any_enemy_has_status("vulnerable"),
		"enemy_has_armor_break": _any_enemy_has_status("armor_break"),
		"enemy_has_fear": _any_enemy_has_status("fear"),
		"ultimate_ready": _is_member_ultimate_ready(member_idx),
		"self_range": _member_combat_range(member_idx),
		"ally_injured": $CombatController.get_most_injured_member_index() >= 0,
	}

# 必殺技が CT/CD 待ちなしで撃てるか（P3-D108 ultimate_ready）。
func _is_member_ultimate_ready(member_idx: int) -> bool:
	var ult: Resource = _get_member_ultimate_skill(member_idx)
	if ult == null:
		return false
	return _skill_executor.can_cast(ult, "%d:%s" % [member_idx, ult.id])

# 戦術「距離」判定用（CombatRange SSOT に委譲）。
func _member_combat_range(member_idx: int) -> String:
	return CombatRange.resolve_member_default(member_idx)

func _any_enemy_has_status(status_id: String) -> bool:
	for slot: int in $CombatController.get_living_enemy_indices():
		if $CombatController.get_enemy_status_stacks_at(slot, status_id) > 0:
			return true
	return false

# 必殺技スロット（長CD・高威力）。発動できたら true。
func _try_member_ultimate(member_idx: int) -> bool:
	var ult: Resource = _get_member_ultimate_skill(member_idx)
	if ult == null:
		return false
	return _try_cast_member_skill(member_idx, ult, true)

# 防御スロット（被ダメ減バフを自身に付与）。発動条件は戦術プラン側で判定する。
# 既に guard 中なら不発（毎行動の重ね掛けで硬直しないようガード）。付与できたら true。
func _do_member_defend_slot(member_idx: int) -> bool:
	if _member_has_status(member_idx, "guard"):
		return false
	if not $CombatController.apply_status("party_%d" % member_idx, "guard", 1, 0):
		return false
	_on_party_status_applied(member_idx, "guard")
	# 防御＝挑発（Threat スパイク・P3-D104）。身を固めて敵の attention を引く。
	$CombatController.apply_taunt(member_idx)
	_activate_taunt_link(member_idx)
	_update_status_icons()
	_clear_member_skill_labels(member_idx)
	_spawn_skill_name("防御", member_idx, 0.0)
	var m: Resource = GameState.get_combatant(member_idx)
	var nm: String = m.display_name if m != null else "?"
	_append_log("[防御] %s は身を固めた" % nm)
	return true

# スキル①②の指定枠（P3-UX-GAMBIT-002）。温存・CD を考慮し1つのみ試行。
func _try_member_equipped_skill_at(member_idx: int, skill_index: int) -> bool:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return false
	var ids: Array[String] = GameState.get_equipped_skill_ids(member)
	if skill_index < 0 or skill_index >= ids.size():
		return false
	var ctx: Dictionary = _build_tactics_context(member_idx)
	var sd: Resource = DataRegistry.get_skill_data(str(ids[skill_index]))
	if sd == null:
		return false
	if not CombatTactics.skill_reserve_met(sd, ctx):
		return false
	if _try_cast_member_skill(member_idx, sd, false):
		$CombatController.set_skill_rotation_after_cast(member_idx, skill_index, ids.size())
		return true
	return false

# スキル①②スロット（装備スキル）。ローテ＋温存を考慮し発動可能な1つを撃つ（P3-D113）。
func _try_member_equipped_skill(member_idx: int) -> bool:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return false
	var ids: Array[String] = GameState.get_equipped_skill_ids(member)
	if ids.is_empty():
		return false
	var ctx: Dictionary = _build_tactics_context(member_idx)
	var start: int = $CombatController.get_skill_rotation_index(member_idx) % ids.size()
	for attempt: int in ids.size():
		var pick: int = (start + attempt) % ids.size()
		var sd: Resource = DataRegistry.get_skill_data(ids[pick])
		if sd == null:
			continue
		if not CombatTactics.skill_reserve_met(sd, ctx):
			continue
		if _try_cast_member_skill(member_idx, sd, false):
			$CombatController.set_skill_rotation_after_cast(member_idx, pick, ids.size())
			return true
	return false

# レジェンド武器の固有スキル（装備枠外・P3-SKILL-004）。
func _try_member_weapon_skill(member_idx: int) -> bool:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return false
	var skill_id: String = WeaponSkillHelper.get_weapon_skill_id(member)
	if skill_id.is_empty():
		return false
	var sd: Resource = DataRegistry.get_skill_data(skill_id)
	if sd == null:
		return false
	var ctx: Dictionary = _build_tactics_context(member_idx)
	if not CombatTactics.skill_reserve_met(sd, ctx):
		return false
	return _try_cast_member_skill(member_idx, sd, false)

# スキル詠唱開始または即時発動（P3-D112）。Action Lock 中は _do_member_turn がここを経由しない。
func _try_cast_member_skill(member_idx: int, skill_data: Resource, is_ultimate: bool) -> bool:
	if skill_data == null:
		return false
	var cd_key: String = _member_skill_cd_key(member_idx, skill_data)
	if not _skill_executor.can_cast(skill_data, cd_key):
		return false
	match skill_data.effect_type:
		"heal":
			if $CombatController.get_most_injured_member_index() < 0:
				return false
		"damage":
			if not _member_has_living_target(member_idx):
				return false
	var cast_time: float = float(skill_data.cast_time)
	if cast_time <= 0.0:
		var log_text: String = _execute_member_skill(member_idx, skill_data, 0).strip_edges()
		if log_text.is_empty():
			# 必殺／ヒット遅延スキルはログを後で出すため、ロック中なら発動成功とみなす
			if _ultimate_presentation_active or _combat_cinematic_lock:
				_update_hp_bars()
				return true
			return false
		if is_ultimate:
			_append_log("【必殺】" + log_text.trim_prefix("【スキル】"))
		else:
			_append_log(log_text)
		_update_hp_bars()
		return true
	var target_slot: int = $CombatController.get_member_target_slot(member_idx)
	var turns: int = int(ceil(cast_time))
	$CombatController.begin_party_cast(member_idx, skill_data.id, target_slot, turns)
	var member: Resource = GameState.get_combatant(member_idx)
	var mname: String = member.display_name if member != null else "?"
	_append_log("[詠唱] %s が%sを唱え始めた" % [mname, skill_data.display_name])
	_clear_member_skill_labels(member_idx)
	if is_ultimate:
		_play_ultimate_cast_vfx(member_idx, skill_data)
		_spawn_skill_name(
			"%s…" % skill_data.display_name,
			member_idx,
			0.0,
			_resolve_skill_element(skill_data, member_idx),
			true
		)
	else:
		_spawn_skill_name(
			skill_data.display_name,
			member_idx,
			0.0,
			_resolve_skill_element(skill_data, member_idx),
			true
		)
	return true

func _advance_member_cast(member_idx: int) -> void:
	if $CombatController.should_member_skip_action_at(member_idx):
		var skip_label: String = $CombatController.get_member_skip_action_label_at(member_idx)
		if skip_label.is_empty():
			skip_label = "鈍化"
		_append_log("[%s] 詠唱が中断された" % skip_label)
		$CombatController.clear_pending_cast("party", member_idx)
		_clear_member_skill_labels(member_idx)
		return
	var pending: Dictionary = $CombatController.get_pending_cast("party", member_idx)
	if pending.is_empty():
		return
	var skill_data: Resource = DataRegistry.get_skill_data(str(pending.get("skill_id", "")))
	if skill_data == null:
		$CombatController.clear_pending_cast("party", member_idx)
		_clear_member_skill_labels(member_idx)
		return
	var state: String = $CombatController.advance_pending_cast("party", member_idx)
	if state == "chant":
		_append_log("[詠唱] %s…" % skill_data.display_name)
		_update_combat_now_playing_for("party", member_idx)
		return
	$CombatController.clear_pending_cast("party", member_idx)
	_clear_member_skill_labels(member_idx)
	if pending.has("target_slot"):
		var frozen: int = int(pending["target_slot"])
		if member_idx >= 0 and member_idx < $CombatController.member_target_slot.size():
			$CombatController.member_target_slot[member_idx] = frozen
	var log_text: String = _execute_member_skill(member_idx, skill_data, 0).strip_edges()
	if log_text.is_empty():
		if _ultimate_presentation_active:
			_update_hp_bars()
			return
		return
	if str(skill_data.slot_type) == "ultimate":
		_append_log("【必殺】" + log_text.trim_prefix("【スキル】"))
	else:
		_append_log(log_text)
	_update_hp_bars()

# 通常攻撃スロット（武器ベース）。
func _apply_basic_attack_passive_mult(member_idx: int, damage: int) -> int:
	if damage <= 0:
		return damage
	var mult: float = 1.0
	if _passive_next_attack_mult.has(member_idx):
		mult = maxf(mult, float(_passive_next_attack_mult[member_idx]))
		_passive_next_attack_mult.erase(member_idx)
	elif not bool(_passive_first_attack_used.get(member_idx, false)):
		mult = maxf(
			mult,
			float(CombatPassives.character_stat_modifiers_for_member(member_idx).get("first_attack_mult", 1.0))
		)
		_passive_first_attack_used[member_idx] = true
	if mult <= 1.0:
		return damage
	return maxi(1, int(round(float(damage) * mult)))

func _execute_counter_attack(member_idx: int, target_slot: int, passive_name: String) -> bool:
	if _passive_counter_depth > 0:
		return false
	if not $CombatController.is_member_alive(member_idx):
		return false
	if target_slot < 0 or not $CombatController.is_enemy_slot_alive(target_slot):
		target_slot = $CombatController.get_member_target_slot(member_idx)
	if target_slot < 0 or not $CombatController.is_enemy_slot_alive(target_slot):
		return false
	_passive_counter_depth += 1
	var result: Dictionary = _calc_damage(member_idx, target_slot)
	var dmg: int = int(result["damage"])
	_play_chr_attack_one(member_idx)
	_resolve_party_attack_impact_async({
		"kind": "counter",
		"member_idx": member_idx,
		"target_slot": target_slot,
		"dmg": dmg,
		"is_critical": bool(result.get("is_critical", false)),
		"passive_name": passive_name,
	})
	return dmg > 0

func _do_member_basic_attack(member_idx: int) -> void:
	if not _member_has_living_target(member_idx):
		return
	var target_slot: int = $CombatController.get_member_target_slot(member_idx)
	var result: Dictionary = _calc_damage(member_idx, target_slot)
	result["damage"] = int(result["damage"]) + _consume_combo_bonus(
		member_idx, int(result["damage"]), _member_action_tags(member_idx), null, target_slot
	)
	var dmg: int = _apply_basic_attack_passive_mult(member_idx, int(result["damage"]))
	result["damage"] = dmg
	# アニメを先に開始し、ダメージはヒットタイミングまで遅延（見た目上の先行ダメージを防ぐ）
	_play_chr_attack_one(member_idx)
	_resolve_party_attack_impact_async({
		"kind": "basic",
		"member_idx": member_idx,
		"target_slot": target_slot,
		"dmg": dmg,
		"is_critical": bool(result.get("is_critical", false)),
		"element_tag": str(result.get("element_tag", "")),
		"formation_tag": str(result.get("formation_tag", "")),
	})

# 必殺技スロットのスキル（ジョブ ultimate_skill_id → 既定 ultimate_strike）。
func _get_member_ultimate_skill(member_idx: int) -> Resource:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return null
	var ult_id: String = Constants.DEFAULT_ULTIMATE_SKILL_ID
	if not str(member.job_id).is_empty():
		var job: Resource = DataRegistry.get_job_data(member.job_id)
		if job != null and "ultimate_skill_id" in job and not str(job.ultimate_skill_id).is_empty():
			ult_id = str(job.ultimate_skill_id)
	if ult_id.is_empty():
		return null
	return DataRegistry.get_skill_data(ult_id)

func _member_has_status(member_idx: int, effect_id: String) -> bool:
	for e: Dictionary in $CombatController.get_member_status_list(member_idx):
		if str(e.get("effect_id", "")) == effect_id:
			return true
	return false

# ---- パッシブ / リアクション（P3-D088） ----

func _tick_passive_cd(delta: float) -> void:
	for k in _passive_cd.keys():
		_passive_cd[k] = maxf(0.0, float(_passive_cd[k]) - delta)

# 戦闘開始時パッシブを生存メンバーで発火。
func _log_party_passives_on_combat_enter() -> void:
	for i: int in GameState.party_members.size():
		if not $CombatController.is_member_alive(i):
			continue
		var member: Resource = GameState.get_combatant(i)
		if member == null:
			continue
		var mname: String = str(member.display_name)
		for entry: Variant in CombatPassives.combat_loadout_log_entries(member):
			if entry is not Dictionary:
				continue
			var tag: String = str(entry.get("tag", "パッシブ"))
			var pname: String = str(entry.get("name", ""))
			if pname.is_empty():
				continue
			_append_log("[%s] %s — %s" % [tag, mname, pname])

func _fire_combat_start_passives() -> void:
	for i: int in GameState.party_members.size():
		if $CombatController.is_member_alive(i):
			_fire_member_passives(i, "on_combat_start")


func _fire_noncombat_enter_passives() -> void:
	$CombatController.ensure_party_hp_for_combat()
	for i: int in GameState.party_members.size():
		if $CombatController.is_member_alive(i):
			_fire_member_passives(i, "on_noncombat_enter")


func _living_exploration_damage_targets() -> Array[int]:
	var living: Array[int] = []
	for i: int in GameState.party_members.size():
		if not $CombatController.is_member_alive(i):
			continue
		var m: Resource = GameState.get_combatant(i)
		if CombatPassives.member_ignores_exploration_damage(m):
			continue
		living.append(i)
	return living

# メンバー被弾フック: 生存なら on_hit_taken、死亡なら生存者の on_ally_death を発火。
func _on_member_damaged(target_idx: int, ctx: Dictionary = {}) -> void:
	if $CombatController.is_member_alive(target_idx):
		_fire_member_passives(target_idx, "on_hit_taken", ctx)
		return
	AudioManager.play_sfx("combat_death", 1.0, 0.06)
	$CombatController.clear_pending_cast("party", target_idx)
	_clear_member_skill_labels(target_idx)
	for i: int in GameState.party_members.size():
		if i == target_idx:
			continue
		if $CombatController.is_member_alive(i):
			_fire_member_passives(i, "on_ally_death", ctx)

# 指定メンバーの該当 trigger パッシブを順に試行。
func _fire_member_passives(member_idx: int, trigger: String, ctx: Dictionary = {}) -> void:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return
	for p: Dictionary in CombatPassives.for_member(member):
		if str(p.get("trigger", "")) != trigger:
			continue
		if trigger == "on_attack":
			var every_n: int = int(p.get("every_n", 0))
			if every_n > 0:
				var hits: int = int(_passive_attack_hits.get(member_idx, 0)) + 1
				_passive_attack_hits[member_idx] = hits
				if hits % every_n != 0:
					continue
		_try_fire_passive(member_idx, p, ctx)

func _try_fire_passive(member_idx: int, p: Dictionary, ctx: Dictionary = {}) -> void:
	var pid: String = str(p.get("id", ""))
	var key: String = "%d:%s" % [member_idx, pid]
	if float(_passive_cd.get(key, 0.0)) > 0.0:
		return
	if bool(p.get("once_per_combat", false)) and bool(_passive_once_fired.get(key, false)):
		return
	# 条件
	if str(p.get("condition", "always")) == "self_hp_below":
		var ratio: float = 1.0
		if member_idx < $CombatController.party_max_hp.size():
			var maxhp: int = $CombatController.party_max_hp[member_idx]
			if maxhp > 0:
				ratio = float($CombatController.party_combat_hp[member_idx]) / float(maxhp)
		if ratio >= float(p.get("value", 0.0)):
			return
	# 効果
	var applied: bool = false
	match str(p.get("effect", "")):
		"apply_status":
			if p.has("status_chance") and randf() > float(p.get("status_chance", 1.0)):
				return
			var sid: String = str(p.get("status_id", ""))
			if sid.is_empty():
				return
			var target_kind: String = str(p.get("target", "self"))
			if target_kind == "party":
				for i: int in GameState.party_members.size():
					if not $CombatController.is_member_alive(i):
						continue
					if $CombatController.apply_status("party_%d" % i, sid, 1, 0):
						applied = true
						_on_party_status_applied(i, sid)
			elif target_kind == "enemy_all":
				for slot: int in $CombatController.get_living_enemy_indices():
					if not $CombatController.is_enemy_slot_alive(slot):
						continue
					if $CombatController.apply_status_to_enemy_slot(slot, sid, 1, 0):
						applied = true
			elif target_kind == "enemy":
				var enemy_slot: int = int(
					ctx.get("attacker_slot", ctx.get("target_slot", $CombatController.get_member_target_slot(member_idx)))
				)
				if enemy_slot >= 0 and $CombatController.is_enemy_slot_alive(enemy_slot):
					applied = $CombatController.apply_status_to_enemy_slot(enemy_slot, sid, 1, 0)
			else:
				applied = $CombatController.apply_status("party_%d" % member_idx, sid, 1, 0)
				if applied:
					_on_party_status_applied(member_idx, sid)
			_update_status_icons()
		"random_enemy_status":
			var pool: Array = p.get("status_pool", [])
			if pool.is_empty():
				return
			var rand_sid: String = str(pool[randi() % pool.size()])
			var enemy_slot: int = int(
				ctx.get("attacker_slot", ctx.get("target_slot", $CombatController.get_member_target_slot(member_idx)))
			)
			if enemy_slot >= 0 and $CombatController.is_enemy_slot_alive(enemy_slot):
				applied = $CombatController.apply_status_to_enemy_slot(enemy_slot, rand_sid, 1, 0)
		"heal":
			# heal_value: condition 閾値の "value" と衝突する場合の回復量キー（P3-D155）
			var frac: float = float(p.get("heal_max_hp_fraction", -1.0))
			if frac >= 0.0:
				if str(p.get("target", "party")) == "self":
					var max_hp_self: int = 0
					if member_idx < $CombatController.party_max_hp.size():
						max_hp_self = int($CombatController.party_max_hp[member_idx])
					var amt_self: int = maxi(1, int(round(float(max_hp_self) * frac)))
					$CombatController.heal_member(member_idx, amt_self)
					_update_hp_bars()
					_spawn_member_heal_vfx(member_idx)
				else:
					for i: int in GameState.party_members.size():
						if not $CombatController.is_member_alive(i):
							continue
						var max_hp_i: int = 0
						if i < $CombatController.party_max_hp.size():
							max_hp_i = int($CombatController.party_max_hp[i])
						var amt_i: int = maxi(1, int(round(float(max_hp_i) * frac)))
						$CombatController.heal_member(i, amt_i)
						_spawn_member_heal_vfx(i)
					_update_hp_bars()
				applied = true
			else:
				var amount: int = _apply_healing_bonus(int(p.get("heal_value", p.get("value", 10))), member_idx)
				if str(p.get("target", "party")) == "self":
					$CombatController.heal_member(member_idx, amount)
					_update_hp_bars()
					_spawn_member_heal_vfx(member_idx)
				else:
					$CombatController.heal_party(amount)
					_update_hp_bars()
					for i: int in GameState.party_members.size():
						if $CombatController.is_member_alive(i):
							_spawn_member_heal_vfx(i)
				applied = true
		"grant_party_incoming_mult":
			var ward: float = clampf(float(p.get("mult", 0.9)), 0.05, 1.0)
			$CombatController.party_temp_incoming_mult = minf(
				float($CombatController.party_temp_incoming_mult), ward
			)
			applied = true
		"chance_cast_equipped_skill":
			if _passive_skill_echo_depth > 0:
				return
			if p.has("status_chance") and randf() > float(p.get("status_chance", 1.0)):
				return
			_passive_skill_echo_depth += 1
			applied = _try_member_equipped_skill(member_idx)
			_passive_skill_echo_depth -= 1
		"bonus_damage":
			var slot: int = int(ctx.get("target_slot", -1))
			var base_dmg: int = int(ctx.get("damage", 0))
			var frac: float = float(p.get("bonus_fraction", 0.25))
			var bonus: int = maxi(1, int(round(float(base_dmg) * frac))) if base_dmg > 0 else 0
			if slot >= 0 and bonus > 0 and $CombatController.is_enemy_slot_alive(slot):
				$CombatController.apply_damage_to_enemy_slot(slot, bonus)
				$CombatController.add_threat(member_idx, float(bonus) * CombatController.THREAT_DAMAGE_K)
				_update_hp_bars()
				applied = true
				_check_boss_phase_transition(slot)
				if $CombatController.get_enemy_hp_at(slot) <= 0:
					_on_enemy_slot_killed(slot)
		"counter_attack":
			var counter_slot: int = int(ctx.get("attacker_slot", -1))
			if counter_slot < 0 or not $CombatController.is_enemy_slot_alive(counter_slot):
				counter_slot = $CombatController.get_member_target_slot(member_idx)
			applied = _execute_counter_attack(member_idx, counter_slot, str(p.get("display_name", "")))
		"grant_next_attack_mult":
			var mult: float = float(p.get("mult", 2.0))
			var target_kind: String = str(p.get("target", "self"))
			if target_kind == "party_alive":
				for i: int in GameState.party_members.size():
					if not $CombatController.is_member_alive(i):
						continue
					_passive_next_attack_mult[i] = maxf(float(_passive_next_attack_mult.get(i, 1.0)), mult)
				applied = true
			else:
				_passive_next_attack_mult[member_idx] = maxf(
					float(_passive_next_attack_mult.get(member_idx, 1.0)), mult
				)
				applied = true
	if not applied:
		return
	if bool(p.get("once_per_combat", false)):
		_passive_once_fired[key] = true
	var cd: float = float(p.get("cooldown", 0.0))
	if cd > 0.0:
		_passive_cd[key] = cd
	var is_relic: bool = CombatPassives.is_relic_passive(pid)
	var is_weapon: bool = CombatPassives.is_weapon_passive(pid)
	_clear_member_skill_labels(member_idx)
	var prefix: String = "◈" if is_relic else ("⚔" if is_weapon else "◇")
	var tag: String = "レリック" if is_relic else ("武器" if is_weapon else "パッシブ")
	_spawn_skill_name(prefix + str(p.get("display_name", "")), member_idx, 0.0)
	_append_log("[%s] %s 発動" % [tag, str(p.get("display_name", ""))])

# ---- パーティ連携連鎖（P3-D115） ----

func _clear_party_links() -> void:
	_taunt_link_source = -1
	_taunt_link_charges = 0
	_debuff_marks.clear()
	_heal_rally_member = -1

func _activate_taunt_link(source_idx: int) -> void:
	_taunt_link_source = source_idx
	_taunt_link_charges = CombatLinks.taunt_max_charges()

func _set_heal_rally(member_idx: int) -> void:
	if member_idx >= 0 and $CombatController.is_member_alive(member_idx):
		_heal_rally_member = member_idx

func _consume_link_bonus(member_idx: int, hit_damage: int, target_slot: int = -1) -> int:
	if hit_damage <= 0:
		return 0
	if target_slot < 0:
		target_slot = $CombatController.get_member_target_slot(member_idx)
	if not $CombatController.is_enemy_slot_alive(target_slot):
		return 0
	if _heal_rally_member == member_idx:
		var rally_bonus: int = CombatLinks.bonus_for("heal_rally", hit_damage)
		if rally_bonus > 0:
			_heal_rally_member = -1
			_report_link_bonus("heal_rally", rally_bonus, member_idx, target_slot)
			return rally_bonus
	if _debuff_marks.has(target_slot):
		var applier: int = int(_debuff_marks[target_slot])
		if applier != member_idx:
			var mark_bonus: int = CombatLinks.bonus_for("debuff_mark", hit_damage)
			if mark_bonus > 0:
				_debuff_marks.erase(target_slot)
				_report_link_bonus("debuff_mark", mark_bonus, member_idx, target_slot)
				return mark_bonus
	if _taunt_link_charges > 0 and member_idx != _taunt_link_source:
		var taunt_bonus: int = CombatLinks.bonus_for("taunt_link", hit_damage)
		if taunt_bonus > 0:
			_taunt_link_charges -= 1
			if _taunt_link_charges <= 0:
				_taunt_link_source = -1
			_report_link_bonus("taunt_link", taunt_bonus, member_idx, target_slot)
			return taunt_bonus
	return 0

# ---- ボスフェーズ移行（P3-D116） ----

func _check_boss_phase_transition(slot: int) -> void:
	if not $CombatController.is_enemy_slot_alive(slot):
		return
	var enemy_id: String = $CombatController.get_enemy_id_at(slot)
	if not CombatBossPhases.has_phases(enemy_id):
		return
	var ratio: float = $CombatController.get_enemy_hp_ratio_at(slot)
	var new_idx: int = CombatBossPhases.resolve_phase_index(enemy_id, ratio)
	var cur_idx: int = $CombatController.get_enemy_phase_index(slot)
	if new_idx <= cur_idx:
		return
	$CombatController.set_enemy_phase_index(slot, new_idx)
	var phase: Dictionary = CombatBossPhases.phase_def(enemy_id, new_idx)
	var log_line: String = str(phase.get("log", ""))
	if log_line.is_empty():
		log_line = "【フェーズ移行】%s" % str(phase.get("label", ""))
	_append_log(log_line)
	GameState.mark_boss_phase_seen(enemy_id, new_idx)
	if slot == $CombatController.active_enemy_index:
		_play_boss_animation("attack")
		_spawn_enemy_skill_name(str(phase.get("label", "")))

func _report_link_bonus(link_id: String, bonus: int, member_idx: int, target_slot: int) -> void:
	var label: String = CombatLinks.label_for(link_id)
	var pos: Vector2 = _enemy_slot_pos(target_slot)
	_spawn_damage_number("%s +%d" % [label, bonus], pos + Vector2(0.0, -62.0), Color(0.45, 0.9, 1.0), 1.18)
	_append_log("[連携] %s +%d" % [label, bonus])

func _play_chr_attack_one(idx: int) -> void:
	if idx < 0 or idx >= _chr_sprites.size():
		return
	var s: AnimatedSprite2D = _chr_sprites[idx]
	if s.visible and s.sprite_frames != null and s.sprite_frames.has_animation("attack"):
		s.play("attack")


func _attack_anim_impact_delay(sprite: AnimatedSprite2D) -> float:
	var delay: float = ATTACK_IMPACT_FALLBACK_SEC
	if sprite != null and sprite.visible and sprite.sprite_frames != null \
			and sprite.sprite_frames.has_animation("attack"):
		var frame_n: int = sprite.sprite_frames.get_frame_count("attack")
		var speed: float = sprite.sprite_frames.get_animation_speed("attack")
		if frame_n > 0 and speed > 0.0:
			delay = (float(frame_n) / speed) * ATTACK_IMPACT_FRAME_RATIO
	var combat_speed: float = _combat_speed_mult if _combat_speed_mult > 0.0 else 1.0
	return maxf(0.05, delay / combat_speed)


## 通常攻撃／反撃: アニメ開始後、ヒットタイミングでダメージ・VFXを適用する。
func _resolve_party_attack_impact_async(payload: Dictionary) -> void:
	var member_idx: int = int(payload.get("member_idx", -1))
	var target_slot: int = int(payload.get("target_slot", -1))
	var kind: String = str(payload.get("kind", "basic"))
	var dmg: int = int(payload.get("dmg", 0))
	var is_critical: bool = bool(payload.get("is_critical", false))
	_begin_combat_cinematic_lock()
	var sprite: AnimatedSprite2D = null
	if member_idx >= 0 and member_idx < _chr_sprites.size():
		sprite = _chr_sprites[member_idx]
	await get_tree().create_timer(_attack_anim_impact_delay(sprite)).timeout
	if not $CombatController.is_in_combat:
		if kind == "counter":
			_passive_counter_depth = maxi(0, _passive_counter_depth - 1)
		_end_combat_cinematic_lock()
		return
	if not $CombatController.is_member_alive(member_idx):
		if kind == "counter":
			_passive_counter_depth = maxi(0, _passive_counter_depth - 1)
		_end_combat_cinematic_lock()
		return
	if target_slot < 0 or not $CombatController.is_enemy_slot_alive(target_slot):
		target_slot = $CombatController.get_member_target_slot(member_idx)
	var member: Resource = GameState.get_combatant(member_idx)
	var mname: String = member.display_name if member != null else "?"
	var crit_tag: String = "  CRITICAL!" if is_critical else ""
	if dmg > 0 and target_slot >= 0 and $CombatController.is_enemy_slot_alive(target_slot):
		_play_hit_vfx(_get_weapon_element(member_idx), is_critical)
		_spawn_damage_number(
			str(dmg),
			_enemy_slot_pos(target_slot),
			_outgoing_damage_telop_color(is_critical),
			1.25 if is_critical else 1.0
		)
	if kind == "counter":
		_append_log("%s の反撃: %dダメージ%s" % [mname, dmg, crit_tag])
		var killed: bool = _deal_member_damage_to_enemy(
			member_idx, dmg, target_slot, "counter_attack", "反撃"
		)
		if not killed and dmg > 0 and $CombatController.is_enemy_slot_alive(target_slot):
			_play_enemy_slot_animation(target_slot, "hurt")
		_try_apply_affix_statuses(member_idx)
		_try_apply_weapon_on_hit_status(member_idx)
		_passive_counter_depth = maxi(0, _passive_counter_depth - 1)
	else:
		var elem_tag: String = str(payload.get("element_tag", ""))
		var form_tag: String = str(payload.get("formation_tag", ""))
		var tgt_tag: String = _member_target_tag(member_idx)
		_append_log("%s の攻撃: %dダメージ%s%s%s%s" % [mname, dmg, crit_tag, elem_tag, form_tag, tgt_tag])
		if not _deal_member_damage_to_enemy(member_idx, dmg, target_slot):
			if $CombatController.is_enemy_slot_alive(target_slot):
				_play_enemy_slot_animation(target_slot, "hurt")
			_try_apply_affix_statuses(member_idx)
			_try_apply_weapon_on_hit_status(member_idx)
	_update_hp_bars()
	_end_combat_cinematic_lock()


## スキル攻撃: アニメ開始後、ヒットタイミングで敵へダメージを適用する。
func _resolve_party_skill_damage_impact_async(payload: Dictionary) -> void:
	var member_idx: int = int(payload.get("member_idx", -1))
	var target_slot: int = int(payload.get("target_slot", -1))
	var final_dmg: int = int(payload.get("final_dmg", 0))
	var attack_element: String = str(payload.get("attack_element", ""))
	var skill_is_crit: bool = bool(payload.get("skill_is_crit", false))
	var spawn_pos: Vector2 = payload.get("spawn_pos", Vector2.ZERO) as Vector2
	var log_line: String = str(payload.get("log_line", ""))
	var skill_data: Resource = payload.get("skill_data") as Resource
	var skill_id: String = str(payload.get("skill_id", ""))
	var display_name: String = str(payload.get("display_name", "スキル"))
	_begin_combat_cinematic_lock()
	var sprite: AnimatedSprite2D = null
	if member_idx >= 0 and member_idx < _chr_sprites.size():
		sprite = _chr_sprites[member_idx]
	await get_tree().create_timer(_attack_anim_impact_delay(sprite)).timeout
	if not $CombatController.is_in_combat:
		_end_combat_cinematic_lock()
		return
	if not $CombatController.is_member_alive(member_idx):
		_end_combat_cinematic_lock()
		return
	if target_slot < 0 or not $CombatController.is_enemy_slot_alive(target_slot):
		target_slot = $CombatController.get_member_target_slot(member_idx)
		spawn_pos = _enemy_slot_pos(target_slot)
	if final_dmg > 0 and target_slot >= 0 and $CombatController.is_enemy_slot_alive(target_slot):
		_spawn_hit_vfx(spawn_pos, attack_element, 1.0, skill_is_crit)
		_spawn_damage_number(
			str(final_dmg),
			spawn_pos + Vector2(12.0, 0.0),
			_outgoing_damage_telop_color(skill_is_crit),
			1.25 if skill_is_crit else 1.0
		)
	if not log_line.is_empty():
		_append_log(log_line)
	if not _deal_member_damage_to_enemy(member_idx, final_dmg, target_slot, skill_id, display_name):
		if $CombatController.is_enemy_slot_alive(target_slot):
			_play_enemy_slot_animation(target_slot, "hurt")
		_apply_skill_status(member_idx, skill_data)
		_apply_skill_secondary_status(member_idx, skill_data)
	_update_hp_bars()
	_end_combat_cinematic_lock()

func _commit_commander_run_stats(outcome: String) -> void:
	var context: Dictionary = {
		"dungeon_id": GameState.get_active_dungeon_id(),
		"stage_id": GameState.last_run_stage_id,
	}
	if str(context["stage_id"]).is_empty() and $DungeonController.current_stage_data != null:
		context["stage_id"] = str($DungeonController.current_stage_data.id)
	_CommanderLifetime.record_run_finished(
		outcome,
		GameState.last_run_combat_stats,
		context
	)

func _handle_party_wipe() -> void:
	$CombatTimer.stop()
	$CombatController.end_combat()
	_update_status_labels()
	_clear_turn_order_ui()
	# 勝利した敵はその場に残す（撃破ではなく味方全滅の演出）
	_play_active_enemy_animation("idle")
	_hide_chr_sprites()
	_clear_damage_numbers_layer()
	_update_combat_visibility()
	_non_combat_zone.visible = false
	_append_log("全員が倒れた... 探索失敗")
	GameState.last_run_exp_reward = $DungeonController.run_exp_reward
	GameState.last_run_gold_reward = $DungeonController.run_gold_reward
	GameState.last_run_token_reward = 0
	GameState.last_run_weapon_dropped = ""
	GameState.last_run_armor_dropped = ""
	GameState.last_run_accessory_dropped = ""
	GameState.last_run_relic_dropped = ""
	GameState.last_run_level_ups = {}
	GameState.last_run_exp_snapshots = {}
	GameState.last_run_combat_stats = GameState.get_run_combat_stats().snapshot()
	_commit_commander_run_stats(GameState.RUN_OUTCOME_WIPE)
	GameState.last_run_outcome = GameState.RUN_OUTCOME_WIPE
	GameState.snapshot_last_run_context()
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	SceneRouter.change_scene("res://scenes/result/ResultScene.tscn")

func _apply_healing_bonus(base_amount: int, member_idx: int = -1) -> int:
	var amount: int = AffixStatCalculatorScript.apply_healing_bonus(base_amount)
	var heal_mult: float = $CombatController.get_party_role_heal_multiplier()
	if member_idx >= 0:
		heal_mult *= EvolutionTraits.member_heal_mult(member_idx)
	return maxi(0, int(round(float(amount) * heal_mult)))

func _apply_material_bonus(base_amount: int) -> int:
	return AffixStatCalculatorScript.apply_material_bonus(base_amount)

func _update_enemy_label() -> void:
	# 敵名は頭上ネームプレート(_position_enemy_overlays)へ集約（モック準拠）。
	# 下部固定ラベルは常に非表示にする。
	_label_enemy.text = ""
	_label_enemy.visible = false

func _update_status_labels() -> void:
	_update_status_icons()
	if not $CombatController.is_in_combat:
		_label_status_enemy.text = ""
		_label_status_enemy.visible = false
		_label_status_party.text = ""
		_label_status_party.visible = false
		return
	_label_status_enemy.visible = false
	_label_status_party.visible = false

func _update_enemy_hp_label() -> void:
	_update_hp_bars()

func _update_party_hp_label() -> void:
	_update_hp_bars()

func _update_next_room_button() -> void:
	_btn_next_room.visible = false
	_update_combat_visibility()

func _update_combat_visibility() -> void:
	if _trap_presentation_active:
		return
	# レイアウトは「戦闘中フラグ」ではなく「戦闘フロアか」で切り替える。
	# これにより撃破直後（is_in_combat=false）でも次フロア進入までバトルログ等を残し、
	# 非戦闘フロアに入った時点で初めて消す（敵味方位置のズレ防止）。
	var on_combat_floor: bool = $DungeonController.is_combat_room()
	_non_combat_zone.visible = not on_combat_floor
	_auto_combat_row.visible = on_combat_floor
	$MainVBox/BattleLogPanel.visible = on_combat_floor
	_party_status_panel.visible = on_combat_floor
	_narrative_panel.visible = not on_combat_floor
	_lock_combat_ui_layout()
	_update_combat_tier_frame()
	if on_combat_floor:
		call_deferred("_refit_all_battle_log_entries")
		call_deferred("_refresh_combat_now_playing_next")
	elif _combat_now_playing_active:
		_reset_narrative_typography()
		_combat_now_playing_active = false

func _lock_combat_ui_layout() -> void:
	var battlefield: Control = $MainVBox/BattlefieldArea
	battlefield.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battlefield.size_flags_stretch_ratio = 1.0
	_battle_log_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	_battle_log_panel.custom_minimum_size = Vector2(0, BATTLE_LOG_PANEL_HEIGHT)
	_battle_log_scroll.size_flags_vertical = Control.SIZE_SHRINK_END
	_battle_log_scroll.custom_minimum_size = Vector2(0, BATTLE_LOG_SCROLL_HEIGHT)
	_party_status_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	if $DungeonController.is_combat_room():
		_narrative_panel.custom_minimum_size = Vector2(0, 0)
		_narrative_panel.visible = false
	else:
		_narrative_panel.custom_minimum_size = Vector2(0, 72)
		_narrative_panel.visible = true
		if _label_now_playing != null:
			_label_now_playing.visible = false
			_label_now_playing.text = ""
	_narrative_panel.size_flags_vertical = Control.SIZE_SHRINK_END

func _update_combat_tier_frame() -> void:
	_stop_tier_frame_pulse()
	var show: bool = false
	var tier: String = CombatUiFrames.TIER_NORMAL
	if $CombatController.is_in_combat:
		tier = CombatUiFrames.tier_from_room_type($DungeonController.current_room_type)
		show = tier == CombatUiFrames.TIER_BOSS or tier == CombatUiFrames.TIER_ELITE
	_combat_tier_frame.visible = show
	if not show:
		_label_combat_tier.text = ""
		if _combat_tier_vignette != null:
			_combat_tier_vignette.color = Color(0, 0, 0, 0)
		return
	_ensure_combat_tier_vignette()
	_combat_tier_frame.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(tier))
	_combat_tier_vignette.color = CombatUiFrames.vignette_color(tier)
	_combat_tier_frame.modulate = Color.WHITE
	var banner: String = _combat_tier_banner_text(tier)
	_label_combat_tier.visible = not banner.is_empty()
	_label_combat_tier.text = banner
	if tier == CombatUiFrames.TIER_ELITE:
		UiTypography.apply_display(_label_combat_tier, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	elif tier == CombatUiFrames.TIER_BOSS:
		UiTypography.apply_display(_label_combat_tier, UiTypography.SIZE_BODY_SMALL, Color(1.0, 0.45, 0.4))
	if tier == CombatUiFrames.TIER_BOSS:
		_start_tier_frame_pulse()

func _combat_tier_banner_text(tier: String) -> String:
	match tier:
		CombatUiFrames.TIER_ELITE:
			return "【エリート】"
		CombatUiFrames.TIER_BOSS:
			return ""
		_:
			return ""

func _start_auto_progress() -> void:
	if _is_paused or _dive_intro_active or _room_transition_busy or _boss_intro_active or _elite_intro_active or _heal_presentation_active or _treasure_presentation_active or _trap_presentation_active or _event_presentation_active or _combat_clear_active:
		if _is_paused:
			_auto_progress_paused_remaining = _auto_delay
		return
	$AutoProgressTimer.wait_time = _auto_delay
	$AutoProgressTimer.start()

func _room_handles_own_progression(room_type: int) -> bool:
	return room_type in [
		Enums.RoomType.HEAL,
		Enums.RoomType.TREASURE,
		Enums.RoomType.EVENT,
		Enums.RoomType.TRAP,
	]

func _finish_room_and_continue() -> void:
	var grace: float = 0.0
	if not $DungeonController.is_combat_room():
		grace = NON_COMBAT_FLOOR_GRACE_SEC
	if grace > 0.0:
		_pending_room_continuation = true
		$AutoProgressTimer.stop()
		$AutoProgressTimer.wait_time = grace
		$AutoProgressTimer.start()
		return
	_on_room_continue_after_grace()

func _on_room_continue_after_grace() -> void:
	if $DungeonController.is_on_last_floor_before_exit():
		_play_combat_clear_celebration(true)
	else:
		_start_auto_progress()

func _on_auto_progress_timeout() -> void:
	if _pending_room_continuation:
		_pending_room_continuation = false
		_on_room_continue_after_grace()
		return
	if _auto_progress_finishes:
		_auto_progress_finishes = false
		_on_finish_button_pressed()
	else:
		_transition_to_next_room()

# 部屋移動トランジション（P3-UX-003 B: 部屋種別一幕）
func _transition_to_next_room() -> void:
	if _room_transition_busy or _dive_intro_active or _combat_clear_active:
		return
	AudioManager.play_sfx("room_enter", 1.0, 0.2)
	_room_transition_busy = true
	$AutoProgressTimer.stop()
	var tw: Tween = create_tween()
	tw.tween_property(_transition_overlay, "modulate:a", 1.0, 0.2)
	tw.tween_callback(_on_room_transition_midpoint)

func _advance_with_caption() -> void:
	_advance_to_next_room()
	var floor_text: String = $DungeonController.get_display_floor_text()
	_label_transition.text = "[%s] %s" % [_get_room_type_name(), floor_text]

func _on_finish_button_pressed() -> void:
	_btn_finish.disabled = true
	$CombatTimer.stop()
	_clear_all_member_skill_labels()
	_clear_turn_order_ui()
	$CombatController.end_combat()
	$DungeonController.generate_run_loot()
	GameState.last_run_exp_reward = $DungeonController.run_exp_reward
	GameState.last_run_exp_snapshots = ExpRunSnapshotScript.build_party_snapshots($DungeonController.run_exp_reward)
	GameState.last_run_level_ups = {}
	GameState.last_run_gold_reward = $DungeonController.run_gold_reward
	GameState.last_run_token_reward = randi_range(1, 2)
	GameState.last_run_weapon_dropped = $DungeonController.last_weapon_dropped
	GameState.last_run_armor_dropped = $DungeonController.last_armor_dropped
	if not $DungeonController.last_accessory_dropped.is_empty():
		GameState.last_run_accessory_dropped = $DungeonController.last_accessory_dropped
	var dungeon_id: String = GameState.get_active_dungeon_id()
	var tier: int = GameState.current_dungeon_tier
	if $DungeonController.current_stage_data != null:
		var stage_id: String = str($DungeonController.current_stage_data.id)
		GameState.last_run_stage_id = stage_id
		GameState.mark_stage_cleared(stage_id, tier)
	else:
		GameState.last_run_stage_id = ""
		GameState.mark_dungeon_tier_cleared(dungeon_id, tier)
		if tier == _DungeonTierConfig.TIER_NORMAL:
			GameState.mark_dungeon_cleared(dungeon_id)
	DailyMissionSystem.report_progress("dungeon_clear", dungeon_id)
	GameState.last_run_outcome = GameState.RUN_OUTCOME_CLEAR
	GameState.last_run_combat_stats = GameState.get_run_combat_stats().snapshot()
	_commit_commander_run_stats(GameState.RUN_OUTCOME_CLEAR)
	GameState.snapshot_last_run_context()
	SceneRouter.change_scene("res://scenes/result/ResultScene.tscn")

# ---- Menu Overlay ----

func _on_menu_button_pressed() -> void:
	_menu_overlay.visible = true

func _on_close_menu_pressed() -> void:
	_menu_overlay.visible = false

func _can_finish_dungeon_run() -> bool:
	return $DungeonController.is_on_last_floor() and not $CombatController.is_in_combat

func _on_menu_finish_pressed() -> void:
	_menu_overlay.visible = false
	if $CombatController.is_in_combat:
		_retire_from_dungeon()
		return
	if not _can_finish_dungeon_run():
		_set_narrative("最終フロアを踏破するまで探索を続ける")
		return
	_on_finish_button_pressed()

# ---- Speed / Pause ----

func _combat_wait_for_mult(speed_mult: float) -> float:
	return COMBAT_TICK_BASE / speed_mult

func _auto_delay_for_mult(speed_mult: float) -> float:
	return AUTO_DELAY_BASE / speed_mult

func _refresh_speed_buttons() -> void:
	var btn_normal: Button = $MainVBox/HeaderBar/ButtonSpeedX1
	var btn_fast: Button = $MainVBox/HeaderBar/ButtonSpeedX2
	var is_normal: bool = is_equal_approx(_combat_speed_mult, SPEED_MULT_NORMAL)
	var is_fast: bool = is_equal_approx(_combat_speed_mult, SPEED_MULT_FAST)
	btn_normal.button_pressed = is_normal
	btn_fast.button_pressed = is_fast
	UiTypography.apply_button(btn_normal, is_normal)
	UiTypography.apply_button(btn_fast, is_fast)

func _apply_combat_speed(speed_mult: float) -> void:
	_combat_speed_mult = speed_mult
	$CombatTimer.wait_time = _combat_wait_for_mult(speed_mult)
	_auto_delay = _auto_delay_for_mult(speed_mult)
	_refresh_speed_buttons()
	## 周回中の切替も次回探索の既定に反映（×1 / ×2 のみ。×1.5 は設定画面）。
	if is_equal_approx(speed_mult, SPEED_MULT_NORMAL) or is_equal_approx(speed_mult, SPEED_MULT_FAST):
		SettingsPrefs.set_combat_speed_mult(speed_mult)
	if _is_paused:
		return
	if $CombatController.is_in_combat:
		$CombatTimer.start()
	if $AutoProgressTimer.time_left > 0:
		$AutoProgressTimer.start(_auto_delay)

func _apply_combat_grind_speed() -> void:
	_combat_speed_mult = 0.0
	$CombatTimer.wait_time = COMBAT_WAIT_GRIND
	_auto_delay = AUTO_DELAY_GRIND
	_refresh_speed_buttons()
	if _is_paused:
		return
	if $CombatController.is_in_combat:
		$CombatTimer.start()
	if $AutoProgressTimer.time_left > 0:
		$AutoProgressTimer.start(_auto_delay)

func _on_speed_x1_pressed() -> void:
	_apply_combat_speed(SPEED_MULT_NORMAL)

func _on_speed_x2_pressed() -> void:
	_apply_combat_speed(SPEED_MULT_FAST)

func _set_paused(paused: bool) -> void:
	if _is_paused == paused:
		return
	_is_paused = paused
	var resume_label: String = "再開" if paused else "一時停止"
	$MainVBox/PartyStatusPanel/PartyStatusVBox/AutoCombatRow/ButtonPause.text = resume_label
	$MainVBox/HeaderBar/ButtonStop.text = "再開" if paused else "停止"
	_pause_overlay.visible = paused
	if paused:
		$CombatTimer.stop()
		_auto_progress_paused_remaining = $AutoProgressTimer.time_left
		$AutoProgressTimer.stop()
	else:
		if $CombatController.is_in_combat:
			$CombatTimer.start()
		if _auto_progress_paused_remaining > 0:
			$AutoProgressTimer.start(_auto_progress_paused_remaining)
			_auto_progress_paused_remaining = 0.0

func _on_pause_button_pressed() -> void:
	_set_paused(not _is_paused)

func _on_stop_pressed() -> void:
	_set_paused(not _is_paused)

func _on_pause_resume_pressed() -> void:
	_set_paused(false)

func _on_pause_retire_pressed() -> void:
	if not _is_paused:
		return
	_retire_from_dungeon()

func _retire_from_dungeon() -> void:
	_pause_overlay.visible = false
	_is_paused = false
	$CombatTimer.stop()
	$AutoProgressTimer.stop()
	_clear_all_member_skill_labels()
	_clear_turn_order_ui()
	if $CombatController.is_in_combat:
		$CombatController.end_combat()
	_append_log("リタイアして帰還した")
	GameState.last_run_exp_reward = $DungeonController.run_exp_reward
	GameState.last_run_exp_snapshots = ExpRunSnapshotScript.build_party_snapshots($DungeonController.run_exp_reward)
	GameState.last_run_level_ups = {}
	GameState.last_run_gold_reward = $DungeonController.run_gold_reward
	GameState.last_run_token_reward = 0
	if GameState.last_run_armor_dropped.is_empty():
		GameState.last_run_armor_dropped = $DungeonController.last_armor_dropped
	GameState.last_run_outcome = GameState.RUN_OUTCOME_RETIRE
	GameState.last_run_combat_stats = GameState.get_run_combat_stats().snapshot()
	_commit_commander_run_stats(GameState.RUN_OUTCOME_RETIRE)
	GameState.snapshot_last_run_context()
	SceneRouter.change_scene("res://scenes/result/ResultScene.tscn")

# ---- Enemy Sprite ----

## 現状ティア専用スプライト。Hard↔Nightmare 相互フォールバックなし。
## ノーマル、または該当ティア資産なし → ノーマルシート。
func _enemy_sprite_path(enemy_id: String) -> String:
	var tier: int = _DungeonTierConfig.clamp_tier(GameState.current_dungeon_tier)
	if tier > _DungeonTierConfig.TIER_NORMAL:
		var by_tier: Variant = ENEMY_SPRITE_MAP_BY_TIER.get(enemy_id, null)
		if by_tier is Dictionary:
			var tier_path: String = str((by_tier as Dictionary).get(tier, ""))
			if not tier_path.is_empty() and ResourceLoader.exists(tier_path):
				return tier_path
	return str(ENEMY_SPRITE_MAP.get(enemy_id, ""))


func _show_enemy_sprite(enemy_id: String) -> void:
	if $DungeonController.current_room_type == Enums.RoomType.BOSS:
		_enemy_sprite.visible = false
		return
	var path: String = _enemy_sprite_path(enemy_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		_enemy_sprite.visible = false
		return
	var frames: SpriteFrames = load(path) as SpriteFrames
	if frames == null:
		_enemy_sprite.visible = false
		return
	_enemy_sprite.sprite_frames = frames
	_normalize_enemy_scale(_enemy_sprite, frames)
	_enemy_sprite.play("idle")
	_enemy_sprite.visible = true

# 敵セルサイズが種別で異なる（通常 96px / エリート 128px 等）ため表示高さを揃える。
# 固定 scale だと 128px が突出して巨大化するのを防ぐ。
func _normalize_enemy_scale(sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	# 味方CHR(_normalize_chr_scale)と同様、フレーム高ではなく実体(α非透明領域)の高さを
	# 基準にスケールする。モック準拠で「敵≒味方サイズ(やや大)」へ揃える（縮小も許可）。
	const ENEMY_BODY_TARGET_PX: float = 132.0
	var tex: Texture2D = frames.get_frame_texture("idle", 0)
	if tex == null:
		return
	var frame_h: float = tex.get_height()
	if frame_h <= 0.0:
		return
	var body_h: float = frame_h
	var img: Image = tex.get_image()
	if img != null:
		var used: Rect2i = img.get_used_rect()
		if used.size.y > 0:
			body_h = float(used.size.y)
	var s: float = clampf(ENEMY_BODY_TARGET_PX / body_h, 0.05, 20.0)
	sprite.scale = Vector2(s, s)
	sprite.centered = true

func _hide_enemy_sprite() -> void:
	_clear_swarm_slots()
	_clear_turn_order_ui()
	_enemy_sprite.visible = false
	_hp_bar_enemy.visible = false
	_enemy_nameplate.visible = false

# ---- 群れ表示（P3-D082） ----

func _reposition_enemy_sprites() -> void:
	if _boss_sprite.visible:
		_apply_boss_sprite_transform()
		_update_hp_bars()
		return
	var n: int = 0
	for spr: AnimatedSprite2D in _swarm_sprites:
		if spr.visible:
			n += 1
	if n <= 0:
		return
	var start_ratio: float = SWARM_CENTER_X_RATIO - float(n - 1) * SWARM_SPACING_RATIO * 0.5
	var y_ratio: float = _enemy_swarm_y_ratio()
	for i in _swarm_sprites.size():
		var spr: AnimatedSprite2D = _swarm_sprites[i]
		if not spr.visible:
			continue
		spr.position = _battlefield_combat_position(
			Vector2(start_ratio + float(i) * SWARM_SPACING_RATIO, y_ratio)
		)
	_update_hp_bars()

# 動的生成した 2体目以降のスロットを解放し、スロット配列を空に戻す（slot0 の既存ノードは残す）。
func _clear_swarm_slots() -> void:
	for i in range(1, _swarm_sprites.size()):
		if is_instance_valid(_swarm_sprites[i]):
			_swarm_sprites[i].queue_free()
	for i in range(1, _swarm_hp_bars.size()):
		if is_instance_valid(_swarm_hp_bars[i]):
			_swarm_hp_bars[i].queue_free()
	for i in range(1, _swarm_nameplates.size()):
		if is_instance_valid(_swarm_nameplates[i]):
			_swarm_nameplates[i].queue_free()
	for i in range(_status_icon_swarm_rows.size()):
		if is_instance_valid(_status_icon_swarm_rows[i]):
			_status_icon_swarm_rows[i].queue_free()
	_swarm_sprites.clear()
	_swarm_hp_bars.clear()
	_swarm_nameplates.clear()
	_status_icon_swarm_rows.clear()

# 必要なスロット数を確保する。slot0 は既存ノードを流用、追加分は duplicate で生成。
func _ensure_swarm_slots(n: int) -> void:
	if _swarm_sprites.is_empty():
		_swarm_sprites.append(_enemy_sprite)
		_swarm_hp_bars.append(_hp_bar_enemy)
		_swarm_nameplates.append(_enemy_nameplate)
	while _swarm_sprites.size() < n:
		var spr: AnimatedSprite2D = _enemy_sprite.duplicate()
		var spr_parent: Node = _combat_sprites_host if _combat_sprites_host != null else self
		spr_parent.add_child(spr)
		var spr_ref := spr
		spr.animation_finished.connect(func():
			if spr_ref.visible and spr_ref.sprite_frames != null:
				if spr_ref.animation in ["attack", "hurt"]:
					spr_ref.play("idle"))
		var bar: ProgressBar = _hp_bar_enemy.duplicate()
		add_child(bar)
		_style_hp_bar_readable(bar, Color(0.85, 0.25, 0.25))
		_apply_combat_overlay_z(bar)
		var np: Label = _enemy_nameplate.duplicate()
		add_child(np)
		_style_enemy_nameplate(np)
		_apply_combat_overlay_z(np, 1)
		_swarm_sprites.append(spr)
		_swarm_hp_bars.append(bar)
		_swarm_nameplates.append(np)
	_ensure_swarm_status_icon_rows(n)

func _enemy_group_is_mixed(group: Array) -> bool:
	if group.size() < 2:
		return false
	var lead_id: String = str(group[0].id)
	for i in range(1, group.size()):
		if str(group[i].id) != lead_id:
			return true
	return false

# 群れ（または単体）の敵スプライトを横並びで表示する。ボス戦は BossSprite を使うため対象外。
func _show_enemy_swarm(enemy_ids: Array) -> void:
	_clear_swarm_slots()
	if $DungeonController.current_room_type == Enums.RoomType.BOSS:
		_enemy_sprite.visible = false
		_hp_bar_enemy.visible = false
		_enemy_nameplate.visible = false
		if enemy_ids.size() > 0:
			if not _prepare_boss_sprite_for_entrance(str(enemy_ids[0])):
				_show_boss_sprite(str(enemy_ids[0]))
		else:
			_update_boss_sprite_visibility()
		return
	_boss_sprite.visible = false
	var n: int = enemy_ids.size()
	if n <= 0:
		_hide_enemy_sprite()
		return
	_ensure_swarm_slots(n)
	# 群れは名前が密集するため小さめフォントに、単体は従来サイズ。
	var name_fs: int = 15 if n > 1 else 22
	var start_ratio: float = SWARM_CENTER_X_RATIO - float(n - 1) * SWARM_SPACING_RATIO * 0.5
	var y_ratio: float = _enemy_swarm_y_ratio()
	for i in n:
		_style_enemy_nameplate(_swarm_nameplates[i])
		_swarm_nameplates[i].add_theme_font_size_override("font_size", name_fs)
		var spr: AnimatedSprite2D = _swarm_sprites[i]
		var id: String = str(enemy_ids[i])
		var path: String = _enemy_sprite_path(id)
		if path.is_empty() or not ResourceLoader.exists(path):
			spr.visible = false
			continue
		var frames: SpriteFrames = load(path) as SpriteFrames
		if frames == null:
			spr.visible = false
			continue
		spr.sprite_frames = frames
		_normalize_enemy_scale(spr, frames)
		spr.position = _battlefield_combat_position(
			Vector2(start_ratio + float(i) * SWARM_SPACING_RATIO, y_ratio)
		)
		spr.play("idle")
		spr.visible = true
	for j in range(n, _swarm_sprites.size()):
		_swarm_sprites[j].visible = false
	if $DungeonController.current_room_type == Enums.RoomType.ELITE and n > 0:
		_prepare_elite_enemy_for_entrance()

# 指定スロットの HPバー＋ネームプレートをスプライト上端の上に配置
func _position_swarm_overlay(slot: int) -> void:
	if slot < 0 or slot >= _swarm_sprites.size():
		return
	var sprite: AnimatedSprite2D = _swarm_sprites[slot]
	var bar: ProgressBar = _swarm_hp_bars[slot]
	var np: Label = _swarm_nameplates[slot]
	const BAR_HALF_W: float = 36.0
	const BAR_HEIGHT: float = 10.0
	const NAME_HEIGHT: float = 24.0
	const GAP_ABOVE_SPRITE: float = 12.0
	const GAP_BAR_NAME: float = 6.0
	var center: Vector2 = _sprite_center_in_root(sprite)
	var cx: float = center.x
	var top_y: float = _sprite_top_y_in_root(sprite)
	var bar_ty: float = minf(center.y - 50.0, top_y - GAP_ABOVE_SPRITE - BAR_HEIGHT)
	bar.offset_left = cx - BAR_HALF_W
	bar.offset_top = bar_ty
	bar.offset_right = cx + BAR_HALF_W
	bar.offset_bottom = bar_ty + BAR_HEIGHT
	var data: Resource = $CombatController.get_enemy_data_at(slot)
	if data == null:
		np.visible = false
		return
	var name_text: String = "Lv%d %s" % [$CombatController.enemy_level, data.display_name]
	np.text = name_text
	var name_fs: int = np.get_theme_font_size("font_size")
	var name_half_w: float = _nameplate_half_width(name_text, name_fs)
	cx = clampf(center.x, name_half_w + 12.0, 720.0 - name_half_w - 12.0)
	bar.offset_left = cx - BAR_HALF_W
	bar.offset_right = cx + BAR_HALF_W
	var name_ty: float = bar_ty - GAP_BAR_NAME - NAME_HEIGHT
	np.offset_left = cx - name_half_w
	np.offset_top = name_ty
	np.offset_right = cx + name_half_w
	np.offset_bottom = name_ty + NAME_HEIGHT
	np.visible = true

func _play_enemy_animation(anim: String) -> void:
	_play_enemy_slot_animation($CombatController.active_enemy_index, anim)

# 指定スロットの敵スプライトにアニメを再生する。
func _play_enemy_slot_animation(slot: int, anim: String) -> void:
	if slot < 0 or slot >= _swarm_sprites.size():
		return
	var spr: AnimatedSprite2D = _swarm_sprites[slot]
	if spr.visible and spr.sprite_frames != null and spr.sprite_frames.has_animation(anim):
		spr.play(anim)

# 戦闘中の敵（通常は アクティブスロット、ボス部屋は BossSprite）にアニメを再生
func _play_active_enemy_animation(anim: String) -> void:
	if _boss_sprite.visible:
		_play_boss_animation(anim)
	else:
		_play_enemy_slot_animation($CombatController.active_enemy_index, anim)

# ---- CHR Sprites ----

func _show_chr_sprites(with_entrance: bool = false) -> void:
	# 既存の擬似 idle tween を一旦全停止（死亡/再入室時の残留防止。生存者は下で再付与）
	for ti in _chr_idle_tweens.size():
		var old_tw = _chr_idle_tweens[ti]
		if old_tw != null and is_instance_valid(old_tw) and old_tw.is_valid():
			old_tw.kill()
		_chr_idle_tweens[ti] = null
	var entrance_count: int = 0
	for i in GameState.combatant_count():
		if i >= _chr_sprites.size():
			break
		var sprite: AnimatedSprite2D = _chr_sprites[i]
		if not $CombatController.is_member_alive(i):
			sprite.visible = false
			continue
		var member: Resource = GameState.get_combatant(i)
		var path: String = _chr_sprite_path_for_member(member)
		if path.is_empty() or not ResourceLoader.exists(path):
			push_warning("DungeonScene: missing CHR sprite for member=%s job=%s" % [
				str(member.id) if member != null else "?",
				str(member.job_id) if member != null else "?",
			])
			sprite.visible = false
			continue
		var frames: SpriteFrames = load(path) as SpriteFrames
		if frames == null:
			sprite.visible = false
			continue
		sprite.sprite_frames = frames
		_normalize_chr_scale(sprite, frames)
		var slot: int = _formation_slot_for_combat_index(i)
		if slot < FORMATION_SLOT_RATIOS.size():
			sprite.position = _formation_slot_position(slot)
			sprite.z_index = _chr_depth_z_index(sprite.position.y)
		sprite.play("idle")
		if with_entrance:
			var target_pos: Vector2 = sprite.position
			var from_left: bool = slot <= 1
			sprite.position = target_pos + Vector2(-36.0 if from_left else 36.0, 8.0)
			_apply_chr_sprite_modulate(i, sprite)
			sprite.modulate.a = 0.0
			sprite.visible = true
			var delay: float = 0.0 if slot <= 1 else 0.15
			var tw: Tween = create_tween()
			if delay > 0.0:
				tw.tween_interval(delay)
			tw.set_parallel(true)
			tw.tween_property(sprite, "modulate:a", 1.0, 0.22)
			tw.tween_property(sprite, "position", target_pos, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			var idx: int = i
			tw.chain().tween_callback(func() -> void: _setup_chr_idle_motion(idx, sprite, frames))
			entrance_count += 1
		else:
			sprite.modulate.a = 1.0
			sprite.visible = true
			_apply_chr_sprite_modulate(i, sprite)
			_setup_chr_idle_motion(i, sprite, frames)
	_rebuild_party_cards()

func _apply_chr_sprite_modulate(member_idx: int, sprite: CanvasItem) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var member: Resource = GameState.get_combatant(member_idx)
	var statuses: Array = []
	if $CombatController.is_in_combat and $CombatController.is_member_alive(member_idx):
		statuses = $CombatController.get_member_status_list(member_idx)
	var alpha: float = sprite.modulate.a
	sprite.modulate = EvolutionVisualScript.sprite_modulate(member, statuses)
	sprite.modulate.a = alpha

# 足元Yから深度 z_index を算出（下＝手前＝大）。味方4スロット（y≈668〜748）を
# 10〜14 に収め、PauseOverlay(z=15) より下・従来帯(10〜12)と互換の範囲に留める。
func _chr_depth_z_index(foot_y: float) -> int:
	var bf_h: float = maxf(1.0, _battlefield_size().y)
	var ratio: float = foot_y / bf_h
	return clampi(10 + roundi(ratio * 4.0), 10, 14)

# idle が1フレームのみの素材は SpriteFrames でフレーム送りできず静止する。
# その場合のみ offset を上下させる「呼吸」idle をコードで付与する（HPバー等は position 基準のため非干渉）。
func _setup_chr_idle_motion(idx: int, sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	if idx < 0 or idx >= _chr_idle_tweens.size():
		return
	var existing = _chr_idle_tweens[idx]
	if existing != null and is_instance_valid(existing) and existing.is_valid():
		existing.kill()
	_chr_idle_tweens[idx] = null
	if frames == null or frames.get_frame_count("idle") > 1:
		return
	var base_y: float = sprite.offset.y
	var sy: float = sprite.scale.y if absf(sprite.scale.y) > 0.001 else 1.0
	var bob_local: float = 6.0 / sy  # 画面上 ~6px の上下動
	var tw: Tween = create_tween()
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(sprite, "offset:y", base_y - bob_local, 0.85)
	tw.tween_property(sprite, "offset:y", base_y, 0.85)
	_chr_idle_tweens[idx] = tw

# バトルログ下のパーティカード列（左:アイコン80px / 右:HP・名前・職業・武器）
func _rebuild_party_cards() -> void:
	for c in _party_cards_row.get_children():
		c.queue_free()
	_party_card_hp_bars.clear()
	_party_card_hp_labels.clear()
	_party_card_skill_cd_bars.clear()
	_party_card_portraits.clear()
	_party_card_roots.clear()
	_party_card_state_badges.clear()
	for tw in _party_card_pulse_tweens:
		if tw != null and is_instance_valid(tw):
			tw.kill()
	_party_card_pulse_tweens.clear()
	for slot in PARTY_CARD_SLOT_COUNT:
		if slot < GameState.party_members.size():
			var member: Resource = GameState.party_members[slot]
			if member == null:
				_party_cards_row.add_child(_make_empty_party_card())
				continue
			var built: Dictionary = _make_party_card(member, slot)
			_party_cards_row.add_child(built["card"])
			_party_card_hp_bars.append(built["hp_bar"])
			_party_card_hp_labels.append(built["hp_label"])
			_party_card_skill_cd_bars.append(built["skill_cd_bars"])
			_party_card_portraits.append(built["portrait"])
			_party_card_roots.append(built["card"])
			_party_card_state_badges.append(built["state_badge"])
			_party_card_pulse_tweens.append(null)
		else:
			_party_cards_row.add_child(_make_empty_party_card())
	_update_party_cards_hp()
	_update_party_skill_cd_bars_smooth(1.0)

func _party_card_short_name(display_name: String) -> String:
	var paren: int = display_name.find("（")
	if paren > 0:
		return display_name.substr(0, paren)
	paren = display_name.find("(")
	if paren > 0:
		return display_name.substr(0, paren)
	return display_name

func _make_party_card_panel_style(active: bool) -> StyleBoxTexture:
	return CombatUiFrames.panel_style(
		CombatUiFrames.TIER_CARD_ACTIVE if active else CombatUiFrames.TIER_CARD
	)

func _style_combat_ui_panels() -> void:
	_battle_log_panel.add_theme_stylebox_override("panel", _battle_log_panel_style())
	_party_status_panel.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL))
	_battle_log_panel.z_index = COMBAT_UI_Z
	_party_status_panel.z_index = COMBAT_UI_Z
	_configure_battle_log_layout()
	_init_combat_tier_decoration()
	_init_combat_drama_ui()

func _battle_log_panel_style() -> StyleBoxTexture:
	var style: StyleBoxTexture = CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
	style.content_margin_left = 12.0
	style.content_margin_top = 6.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 6.0
	return style

func _configure_battle_log_layout() -> void:
	_lock_combat_ui_layout()
	_battle_log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battle_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin: MarginContainer = _battle_log_scroll.get_node_or_null("BattleLogMargin") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "BattleLogMargin"
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_battle_log_scroll.remove_child(_battle_log_content)
		margin.add_child(_battle_log_content)
		_battle_log_scroll.add_child(margin)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 4)
	_battle_log_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battle_log_content.add_theme_constant_override("separation", BATTLE_LOG_LINE_GAP)
	if not _battle_log_scroll.resized.is_connected(_on_battle_log_scroll_resized):
		_battle_log_scroll.resized.connect(_on_battle_log_scroll_resized)

func _on_battle_log_scroll_resized() -> void:
	call_deferred("_refit_all_battle_log_entries")

func _init_combat_tier_decoration() -> void:
	_ensure_combat_tier_vignette()

func _ensure_combat_tier_vignette() -> void:
	if _combat_tier_vignette != null and is_instance_valid(_combat_tier_vignette):
		return
	_combat_tier_vignette = ColorRect.new()
	_combat_tier_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combat_tier_vignette.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_combat_tier_vignette.grow_vertical = Control.GROW_DIRECTION_BOTH
	_combat_tier_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_tier_vignette.color = Color(0, 0, 0, 0)
	_combat_tier_frame.add_child(_combat_tier_vignette)
	_combat_tier_frame.move_child(_combat_tier_vignette, 0)

func _start_tier_frame_pulse() -> void:
	_stop_tier_frame_pulse()
	_tier_frame_pulse_tween = create_tween().set_loops()
	_tier_frame_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tier_frame_pulse_tween.tween_property(_combat_tier_frame, "modulate", Color(1.08, 0.92, 0.88), 0.95)
	_tier_frame_pulse_tween.tween_property(_combat_tier_frame, "modulate", Color.WHITE, 0.95)

func _stop_tier_frame_pulse() -> void:
	if _tier_frame_pulse_tween != null and is_instance_valid(_tier_frame_pulse_tween):
		_tier_frame_pulse_tween.kill()
	_tier_frame_pulse_tween = null
	_combat_tier_frame.modulate = Color.WHITE


func _style_party_card_skill_cd_bar(bar: ProgressBar) -> void:
	_style_hp_bar_readable(bar, PARTY_CARD_SKILL_CD_WAIT)
	bar.custom_minimum_size = Vector2(0, PARTY_CARD_CD_HEIGHT)

# 装備スキル①②のCD表示（CTとは別。満タン=使用可・≠自動発動）（P3-FIX-008）。
func _make_skill_cd_row() -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var header := Label.new()
	header.text = "再使用"
	UiTypography.apply_caption(header, PARTY_CARD_SKILL_CD_WAIT)
	header.tooltip_text = "スキル再使用までの待ち時間（使用可になっても自動では発動しません）"
	header.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(header)
	var bars: Array[ProgressBar] = []
	for slot_num in [1, 2]:
		var slot_col := HBoxContainer.new()
		slot_col.add_theme_constant_override("separation", 2)
		slot_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tag := Label.new()
		tag.text = "①" if slot_num == 1 else "②"
		UiTypography.apply_caption(tag, PARTY_CARD_SKILL_CD_READY)
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot_col.add_child(tag)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = 1.0
		bar.value = 1.0
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_style_party_card_skill_cd_bar(bar)
		slot_col.add_child(bar)
		row.add_child(slot_col)
		bars.append(bar)
	return {"row": row, "bars": bars}

func _party_card_skill_cd_info(member_idx: int, skill_slot: int) -> Dictionary:
	var member: Resource = GameState.get_combatant(member_idx)
	if member == null:
		return {"cd_key": "", "max_cd": 0.0, "ready": true, "has_skill": false}
	var ids: Array[String] = GameState.get_equipped_skill_ids(member)
	if skill_slot >= ids.size() or str(ids[skill_slot]).is_empty():
		return {"cd_key": "", "max_cd": 0.0, "ready": true, "has_skill": false}
	var skill_data: Resource = DataRegistry.get_skill_data(str(ids[skill_slot]))
	if skill_data == null or float(skill_data.cooldown) <= 0.0:
		return {"cd_key": "", "max_cd": 0.0, "ready": true, "has_skill": true}
	var cd_key: String = _member_skill_cd_key(member_idx, skill_data)
	var max_cd: float = float(skill_data.cooldown)
	var rem: float = _skill_executor.get_cooldown_remaining(cd_key)
	return {
		"cd_key": cd_key,
		"max_cd": max_cd,
		"ready": rem <= 0.05,
		"has_skill": true,
	}

func _update_party_skill_cd_bars_smooth(delta: float) -> void:
	if not $DungeonController.is_combat_room():
		return
	var ct_rate: float = 0.0
	if not $CombatTimer.is_stopped() and $CombatTimer.wait_time > 0.0 and _last_ct_step_ui > 0.0:
		ct_rate = _last_ct_step_ui / $CombatTimer.wait_time
	var blend: float = minf(1.0, SKILL_CD_LERP_RATE * delta)
	for i in _party_card_skill_cd_bars.size():
		if i >= $CombatController.party_max_hp.size():
			continue
		var cd_bars: Array = _party_card_skill_cd_bars[i]
		var alive: bool = $CombatController.is_member_alive(i)
		for s in mini(2, cd_bars.size()):
			var bar: ProgressBar = cd_bars[s]
			if not alive:
				bar.value = 0.0
				_style_party_card_skill_cd_bar(bar)
				continue
			var info: Dictionary = _party_card_skill_cd_info(i, s)
			if not bool(info.get("has_skill", false)):
				bar.value = 0.0
				_style_party_card_skill_cd_bar(bar)
				continue
			var cd_key: String = str(info.get("cd_key", ""))
			if cd_key.is_empty():
				bar.value = 1.0
				_style_hp_bar_readable(bar, PARTY_CARD_SKILL_CD_READY)
				continue
			var max_cd: float = float(info.get("max_cd", 1.0))
			var actual_rem: float = _skill_executor.get_cooldown_remaining(cd_key)
			var visual_rem: float = float(_skill_cd_visual_rem.get(cd_key, actual_rem))
			if actual_rem > visual_rem + 0.05:
				visual_rem = actual_rem
			elif actual_rem + 0.05 < visual_rem and ct_rate > 0.0:
				visual_rem = maxf(actual_rem, visual_rem - ct_rate * delta)
			else:
				visual_rem = lerpf(visual_rem, actual_rem, blend)
			_skill_cd_visual_rem[cd_key] = visual_rem
			var ready: bool = visual_rem <= 0.05
			bar.value = 1.0 if ready else clampf(1.0 - visual_rem / maxf(max_cd, 0.001), 0.0, 1.0)
			_style_hp_bar_readable(
				bar,
				PARTY_CARD_SKILL_CD_READY if ready else PARTY_CARD_SKILL_CD_WAIT
			)

func _make_party_card(member: Resource, combat_index: int) -> Dictionary:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	card.add_child(root)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	root.add_child(top_row)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(PARTY_CARD_ICON_PX, PARTY_CARD_ICON_PX)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tex: Texture2D = _get_member_icon_texture(member)
	if tex != null:
		portrait.texture = tex
	portrait.modulate = EvolutionVisualScript.portrait_modulate(member)
	top_row.add_child(portrait)
	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_col.alignment = BoxContainer.ALIGNMENT_CENTER
	name_col.add_theme_constant_override("separation", 4)
	var name_label := Label.new()
	name_label.text = _party_card_short_name(member.display_name)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiTypography.apply_display(name_label, UiTypography.SIZE_BODY_SMALL, _party_log_color(member), UiTypography.OUTLINE_BODY)
	name_col.add_child(name_label)
	var weapon_wrap := Control.new()
	weapon_wrap.custom_minimum_size = Vector2(PARTY_CARD_WEAPON_ICON_PX, PARTY_CARD_WEAPON_ICON_PX)
	weapon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var weapon_icon := TextureRect.new()
	weapon_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var weapon: Resource = GameState.get_member_equipped_weapon(combat_index)
	if weapon != null and not weapon.weapon_id.is_empty():
		var weapon_tex: Texture2D = IconPaths.get_icon_texture(weapon.weapon_id, "weapon")
		if weapon_tex != null:
			weapon_icon.texture = weapon_tex
	weapon_wrap.add_child(weapon_icon)
	if weapon != null:
		EquipmentUiHelper.apply_enhance_badge(
			weapon_wrap,
			weapon,
			"weapon",
			Vector2(PARTY_CARD_WEAPON_ICON_PX, PARTY_CARD_WEAPON_ICON_PX)
		)
	name_col.add_child(weapon_wrap)
	top_row.add_child(name_col)
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 4)
	root.add_child(hp_row)
	var hp_bar := ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(0, PARTY_CARD_HP_HEIGHT)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_hp_bar_readable(hp_bar, PARTY_CARD_HP_FILL)
	hp_row.add_child(hp_bar)
	var hp_label := Label.new()
	hp_label.custom_minimum_size = Vector2(56, 0)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_body(hp_label, UiTypography.SIZE_CAPTION, UI_TEXT_PRIMARY, UiTypography.OUTLINE_BODY)
	hp_row.add_child(hp_label)
	var skill_cd: Dictionary = _make_skill_cd_row()
	root.add_child(skill_cd["row"])
	var state_badge := Label.new()
	state_badge.visible = false
	state_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_display(state_badge, 11, Color(1.0, 0.88, 0.82), UiTypography.OUTLINE_STRONG)
	card.add_child(state_badge)
	state_badge.set_anchors_preset(Control.PRESET_TOP_WIDE)
	state_badge.offset_top = 2.0
	state_badge.offset_bottom = 16.0
	return {
		"card": card,
		"hp_bar": hp_bar,
		"hp_label": hp_label,
		"skill_cd_bars": skill_cd["bars"],
		"portrait": portrait,
		"state_badge": state_badge,
	}

func _make_empty_party_card() -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.modulate = PARTY_CARD_EMPTY_MODULATE
	card.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	card.add_child(root)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	root.add_child(top_row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(PARTY_CARD_ICON_PX, PARTY_CARD_ICON_PX)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_row.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	for line in ["—", "—"]:
		var label := Label.new()
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		UiTypography.apply_caption(label, UiTypography.COLOR_MUTED)
		info.add_child(label)
	top_row.add_child(info)
	var hp_bar := ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(0, PARTY_CARD_HP_HEIGHT)
	_style_hp_bar_readable(hp_bar, PARTY_CARD_HP_FILL)
	root.add_child(hp_bar)
	return card

func _get_member_job_display_name(member: Resource) -> String:
	var mods: Dictionary = JobStatCalculatorScript.get_member_modifiers(member)
	return str(mods.get("display_name", ""))

## ガチャ助っ人は専用 SpriteFrames（`GachaHelperData.sprite_resource_path`）。未設定時は職デフォルト。
func _chr_sprite_path_for_member(member: Resource) -> String:
	if member == null:
		return ""
	var member_id: String = str(member.id)
	if Constants.is_gacha_helper_id(member_id):
		var helper_id: String = member_id.trim_prefix("gacha_")
		var helper: Resource = DataRegistry.get_gacha_helper_data(helper_id)
		if helper != null:
			var helper_path: String = str(helper.sprite_resource_path)
			if not helper_path.is_empty() and ResourceLoader.exists(helper_path):
				return helper_path
	return str(CHR_SPRITE_MAP.get(str(member.job_id), ""))

func _get_member_icon_texture(member: Resource) -> Texture2D:
	if member == null:
		return null
	var icon: Texture2D = RosterUiHelper.get_member_portrait_texture(member)
	if icon != null:
		return icon
	# バスト未配置時は戦闘スプライト idle へフォールバック
	var path: String = _chr_sprite_path_for_member(member)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var frames: SpriteFrames = load(path) as SpriteFrames
	if frames == null or not frames.has_animation("idle"):
		return null
	return frames.get_frame_texture("idle", 0)

func _get_chr_icon_texture(job_id: String) -> Texture2D:
	# 互換: 職のみ分かる経路向け。可能なら _get_member_icon_texture を使う。
	var icon: Texture2D = IconPaths.get_icon_texture(job_id, "chr")
	if icon != null:
		return icon
	var path: String = CHR_SPRITE_MAP.get(job_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var frames: SpriteFrames = load(path) as SpriteFrames
	if frames == null or not frames.has_animation("idle"):
		return null
	return frames.get_frame_texture("idle", 0)

func _get_enemy_turn_icon_texture(enemy_id: String) -> Texture2D:
	## 行動順専用の枠焼込アイコン。無ければ null（図鑑 `enemy:` は使わない）。
	return IconPaths.get_icon_texture(enemy_id, "enemy_turn")

func _get_enemy_icon_texture(enemy_id: String) -> Texture2D:
	var turn_icon: Texture2D = _get_enemy_turn_icon_texture(enemy_id)
	if turn_icon != null:
		return turn_icon
	var path: String = BOSS_ENEMY_SPRITE_MAP.get(enemy_id, "")
	if path.is_empty():
		path = _enemy_sprite_path(enemy_id)
	if path.is_empty() and $DungeonController.current_dungeon_data != null:
		path = BOSS_SPRITE_MAP.get($DungeonController.current_dungeon_data.id, "")
	if not path.is_empty() and ResourceLoader.exists(path):
		var frames: SpriteFrames = load(path) as SpriteFrames
		if frames != null and frames.has_animation("idle"):
			return frames.get_frame_texture("idle", 0)
	var icon: Texture2D = IconPaths.get_icon_texture(enemy_id, "enemy")
	if icon != null:
		return icon
	return null

func _make_turn_order_frame_style(active: bool) -> StyleBoxTexture:
	return CombatUiFrames.panel_style(
		CombatUiFrames.TIER_CARD_ACTIVE if active else CombatUiFrames.TIER_CARD
	)

func _turn_order_side_cell_size() -> float:
	return TURN_ORDER_SIDE_ICON_PX + TURN_ORDER_SIDE_FRAME_PAD * 2.0

# ---- 行動順（CT プレビュー）表示（P3-D084 / P3-UX-002 G） ----

func _init_turn_order_row() -> void:
	var battlefield: Control = $MainVBox/BattlefieldArea
	_turn_order_col_left = VBoxContainer.new()
	_turn_order_col_left.name = "TurnOrderLeft"
	_turn_order_col_left.add_theme_constant_override("separation", int(TURN_ORDER_SIDE_GAP))
	_turn_order_col_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn_order_col_left.visible = false
	_turn_order_col_left.z_index = 30
	battlefield.add_child(_turn_order_col_left)
	_turn_order_col_right = VBoxContainer.new()
	_turn_order_col_right.name = "TurnOrderRight"
	_turn_order_col_right.add_theme_constant_override("separation", int(TURN_ORDER_SIDE_GAP))
	_turn_order_col_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn_order_col_right.visible = false
	_turn_order_col_right.z_index = 30
	battlefield.add_child(_turn_order_col_right)

func _make_turn_order_cell(entry: Dictionary) -> PanelContainer:
	var cell: float = _turn_order_side_cell_size()
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(cell, cell)
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex: Texture2D = null
	var baked_enemy_frame: bool = false
	if entry["kind"] == "party":
		var m: Resource = GameState.get_combatant(entry["index"])
		if m != null:
			tex = _get_member_icon_texture(m)
		icon.custom_minimum_size = Vector2(TURN_ORDER_SIDE_ICON_PX, TURN_ORDER_SIDE_ICON_PX)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		holder.add_theme_stylebox_override("panel", _make_turn_order_frame_style(false))
	else:
		var d: Resource = $CombatController.get_enemy_data_at(entry["index"])
		if d != null:
			baked_enemy_frame = _get_enemy_turn_icon_texture(d.id) != null
			tex = _get_enemy_icon_texture(d.id)
		if baked_enemy_frame:
			# 枠はテクスチャに焼込済み。汎用 CombatUiFrames を重ねない。
			icon.custom_minimum_size = Vector2(cell, cell)
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			holder.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		else:
			icon.custom_minimum_size = Vector2(TURN_ORDER_SIDE_ICON_PX, TURN_ORDER_SIDE_ICON_PX)
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			holder.add_theme_stylebox_override("panel", _make_turn_order_frame_style(false))
	holder.set_meta("baked_enemy_frame", baked_enemy_frame)
	icon.texture = tex
	icon.modulate = Color(1.0, 1.0, 1.0, 0.7)
	holder.add_child(icon)
	var badge := Label.new()
	badge.text = _turn_order_action_badge(str(entry.get("kind", "")), int(entry.get("index", -1)))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	badge.offset_top = -16.0
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_display(badge, TURN_ORDER_BADGE_FONT_PX, Color(1.0, 0.95, 0.82, 1.0), UiTypography.OUTLINE_STRONG)
	holder.add_child(badge)
	return holder

func _layout_turn_order_columns() -> void:
	if _turn_order_col_left == null or _turn_order_col_right == null:
		return
	var bf_size: Vector2 = _battlefield_size()
	var cell: float = _turn_order_side_cell_size()
	_turn_order_col_left.position = Vector2(TURN_ORDER_SIDE_MARGIN, TURN_ORDER_SIDE_TOP)
	_turn_order_col_right.position = Vector2(
		maxf(TURN_ORDER_SIDE_MARGIN, bf_size.x - cell - TURN_ORDER_SIDE_MARGIN),
		TURN_ORDER_SIDE_TOP
	)

# CT 順アイコン列を再構築する（味方=左縦列 / 敵=右縦列）。
func _update_turn_order_ui(order: Array) -> void:
	if _turn_order_col_left == null or _turn_order_col_right == null:
		return
	for c in _turn_order_col_left.get_children():
		c.queue_free()
	for c in _turn_order_col_right.get_children():
		c.queue_free()
	_turn_order_items.clear()
	if not $DungeonController.is_combat_room() or order.is_empty():
		_turn_order_col_left.visible = false
		_turn_order_col_right.visible = false
		_party_card_active_turn = -1
		_update_party_cards_hp()
		return
	for entry: Dictionary in order:
		var holder: PanelContainer = _make_turn_order_cell(entry)
		if entry["kind"] == "party":
			_turn_order_col_left.add_child(holder)
		else:
			_turn_order_col_right.add_child(holder)
		_turn_order_items.append({
			"kind": entry["kind"],
			"index": entry["index"],
			"icon": holder.get_child(0),
			"frame": holder,
			"badge": holder.get_child(1),
			"baked_frame": bool(holder.get_meta("baked_enemy_frame", false)),
		})
	_turn_order_col_left.visible = _turn_order_col_left.get_child_count() > 0
	_turn_order_col_right.visible = _turn_order_col_right.get_child_count() > 0
	_layout_turn_order_columns()
	_party_card_active_turn = -1
	if not order.is_empty() and order[0].get("kind", "") == "party":
		_party_card_active_turn = int(order[0].get("index", -1))
	_update_party_cards_hp()

# 次に行動するユニットの枠を強調する。
func _set_turn_order_active(entry: Dictionary) -> void:
	for item: Dictionary in _turn_order_items:
		var icon: TextureRect = item["icon"]
		var frame: PanelContainer = item["frame"]
		var active: bool = item["kind"] == entry["kind"] and item["index"] == entry["index"]
		if bool(item.get("baked_frame", false)):
			frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		else:
			frame.add_theme_stylebox_override("panel", _make_turn_order_frame_style(active))
		frame.scale = Vector2(1.06, 1.06) if active else Vector2.ONE
		icon.modulate = Color(1.0, 1.0, 1.0, 1.0) if active else Color(1.0, 1.0, 1.0, 0.55)

func _clear_turn_order_ui() -> void:
	if _turn_order_col_left == null or _turn_order_col_right == null:
		return
	for c in _turn_order_col_left.get_children():
		c.queue_free()
	for c in _turn_order_col_right.get_children():
		c.queue_free()
	_turn_order_items.clear()
	_turn_order_col_left.visible = false
	_turn_order_col_right.visible = false
	_party_card_active_turn = -1
	_hide_combat_threat_banner()
	_update_party_cards_hp()

func _update_party_cards_hp() -> void:
	for i in _party_card_hp_bars.size():
		if i >= $CombatController.party_max_hp.size() or i >= $CombatController.party_combat_hp.size():
			continue
		var alive: bool = $CombatController.is_member_alive(i)
		var hp_bar: ProgressBar = _party_card_hp_bars[i]
		hp_bar.max_value = $CombatController.party_max_hp[i]
		hp_bar.value = $CombatController.party_combat_hp[i] if alive else 0
		_party_card_hp_labels[i].text = "%d/%d" % [
			$CombatController.party_combat_hp[i], $CombatController.party_max_hp[i],
		]
		if i < _party_card_portraits.size():
			var member: Resource = GameState.get_combatant(i)
			_party_card_portraits[i].modulate = EvolutionVisualScript.portrait_modulate(member, alive)
		if i < _party_card_roots.size():
			var card: PanelContainer = _party_card_roots[i]
			_update_party_card_dramatics(i, alive)
			if not alive:
				card.modulate = PARTY_CARD_DEAD_MODULATE

func _normalize_chr_scale(sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	# 実体（α非透明領域）のバウンディングボックスを CHR_BODY_TARGET_PX に揃える。
	# 足元（下端中央）をノード position に合わせる。
	var tex: Texture2D = frames.get_frame_texture("idle", 0)
	if tex == null:
		return
	var frame_w: float = tex.get_width()
	var frame_h: float = tex.get_height()
	if frame_h <= 0.0:
		return
	var body_w: float = frame_w
	var body_h: float = frame_h
	var body_cx: float = frame_w / 2.0
	var body_bottom: float = frame_h
	var img: Image = tex.get_image()
	if img != null:
		var used: Rect2i = img.get_used_rect()
		if used.size.y > 0:
			body_w = float(used.size.x)
			body_h = float(used.size.y)
			body_cx = float(used.position.x) + body_w * 0.5
			body_bottom = float(used.position.y + used.size.y)
	var body_max: float = maxf(body_w, body_h)
	var s: float = clampf(CHR_BODY_TARGET_PX / body_max, 0.05, 20.0)
	sprite.scale = Vector2(s, s)
	sprite.centered = true
	sprite.offset = Vector2(frame_w / 2.0 - body_cx, frame_h / 2.0 - body_bottom)

func _formation_slot_for_combat_index(combat_index: int) -> int:
	return GameState.get_combatant_formation_slot(combat_index)

func _hide_chr_sprites() -> void:
	for i in _chr_idle_tweens.size():
		var tw = _chr_idle_tweens[i]
		if tw != null and is_instance_valid(tw) and tw.is_valid():
			tw.kill()
		_chr_idle_tweens[i] = null
	for i in _chr_skill_labels.size():
		_clear_member_skill_labels(i)
	for sprite: AnimatedSprite2D in _chr_sprites:
		sprite.modulate.a = 1.0
		sprite.visible = false

func _play_chr_attack() -> void:
	for sprite: AnimatedSprite2D in _chr_sprites:
		if sprite.visible and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("attack"):
			sprite.play("attack")

func _play_chr_hurt(member_idx: int) -> void:
	if member_idx < 0 or member_idx >= _chr_sprites.size():
		return
	var sprite: AnimatedSprite2D = _chr_sprites[member_idx]
	if sprite.visible and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")

# ---- VFX ----

func _spawn_transient_vfx_sprite(spr: AnimatedSprite2D, world_pos: Vector2, tint: Color = Color.WHITE) -> void:
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = true
	spr.modulate = tint
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spr.material = mat
	var host: Node = _combat_sprites_host if _combat_sprites_host != null and is_instance_valid(_combat_sprites_host) else self
	host.add_child(spr)
	if host == _combat_sprites_host:
		spr.position = _combat_sprites_host.to_local(world_pos)
	else:
		spr.global_position = world_pos

func _play_combat_clear_celebration(finish_dungeon_after: bool = false) -> void:
	if _combat_clear_active:
		return
	_combat_clear_active = true
	# クリアBGMは結果ウィザード（ResultScene）入室時のみ。
	AudioManager.play_sfx("victory")
	$AutoProgressTimer.stop()
	if _combat_clear_tween != null and is_instance_valid(_combat_clear_tween):
		_combat_clear_tween.kill()
	var battlefield: Control = $MainVBox/BattlefieldArea
	_spawn_combat_clear_confetti(64)
	var lbl := Label.new()
	lbl.name = "CombatClearLabel"
	lbl.text = "クリア!!"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiTypography.apply_display(lbl, 56, Color(1.0, 0.92, 0.38), UiTypography.OUTLINE_STRONG)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.offset_left = -220.0
	lbl.offset_right = 220.0
	lbl.offset_top = -36.0
	lbl.offset_bottom = 36.0
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.modulate.a = 0.0
	lbl.scale = Vector2(0.55, 0.55)
	lbl.z_index = 48
	battlefield.add_child(lbl)
	_combat_clear_tween = create_tween()
	_combat_clear_tween.tween_property(lbl, "modulate:a", 1.0, 0.18)
	_combat_clear_tween.parallel().tween_property(lbl, "scale", Vector2(1.12, 1.12), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_combat_clear_tween.chain().tween_property(lbl, "scale", Vector2.ONE, 0.1)
	_combat_clear_tween.chain().tween_interval(1.35)
	_combat_clear_tween.chain().tween_property(lbl, "modulate:a", 0.0, 0.22)
	_combat_clear_tween.chain().tween_callback(func() -> void:
		if is_instance_valid(lbl):
			lbl.queue_free()
		_combat_clear_active = false
		_combat_clear_tween = null
		if finish_dungeon_after:
			$DungeonController.is_completed = true
			_on_finish_button_pressed()
		else:
			_start_auto_progress()
	)

func _spawn_combat_clear_confetti(piece_count: int = 56) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var bf: Control = $MainVBox/BattlefieldArea
	var host: Node = bf
	for _i: int in piece_count:
		var piece := ColorRect.new()
		piece.size = Vector2(rng.randf_range(5.0, 11.0), rng.randf_range(7.0, 16.0))
		piece.color = Color.from_hsv(rng.randf(), rng.randf_range(0.75, 1.0), 1.0, 0.92)
		piece.rotation = rng.randf_range(-0.8, 0.8)
		piece.position = Vector2(
			rng.randf_range(0.0, bf.size.x),
			rng.randf_range(-24.0, bf.size.y * 0.35)
		)
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece.z_index = 44
		host.add_child(piece)
		var drift_x: float = rng.randf_range(-120.0, 120.0)
		var fall_y: float = bf.size.y + rng.randf_range(24.0, 80.0)
		var duration: float = rng.randf_range(1.0, 2.2)
		var tw: Tween = create_tween()
		tw.set_parallel(true)
		tw.tween_property(piece, "position:y", fall_y, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(piece, "position:x", piece.position.x + drift_x, duration)
		tw.tween_property(piece, "rotation", piece.rotation + rng.randf_range(-2.5, 2.5), duration)
		tw.tween_property(piece, "modulate:a", 0.0, 0.5).set_delay(maxf(0.0, duration - 0.5))
		tw.chain().tween_callback(piece.queue_free)

func _play_hit_vfx(element: String = "", is_critical: bool = false) -> void:
	# 後方互換: 引数なし呼び出しは敵スプライト位置で発火
	if not _enemy_sprite.visible and not _boss_sprite.visible:
		return
	var enemy_pos: Vector2 = _active_enemy_pos()
	_spawn_hit_vfx(enemy_pos, element, 1.0, is_critical)

# 命中ごとに使い捨ての Hit VFX を生成（敵味方両対応・同一tick内の複数ヒットも個別表示）。
# 属性専用VFX(ELEMENT_VFX_PATH)があればそれを無着色で再生、無ければ
# FX_Hit_Normal を ELEMENT_COLOR でティント着色してフォールバックする。
func _spawn_hit_vfx(world_pos: Vector2, element: String = "", scale_mult: float = 1.0, is_critical: bool = false) -> void:
	AudioManager.play_sfx("combat_crit" if is_critical else "combat_hit", 1.0, 0.03)
	if is_critical and ResourceLoader.exists(VFX_CRIT_PATH):
		var crit_frames: SpriteFrames = load(VFX_CRIT_PATH) as SpriteFrames
		if crit_frames != null:
			var crit_spr := AnimatedSprite2D.new()
			crit_spr.sprite_frames = crit_frames
			crit_spr.scale = _hit_vfx_sprite.scale * maxf(scale_mult, 1.15)
			_spawn_transient_vfx_sprite(crit_spr, world_pos, Color.WHITE)
			crit_spr.play("default")
			crit_spr.animation_finished.connect(func() -> void: crit_spr.queue_free())
			return
	var elem_path: String = str(ELEMENT_VFX_PATH.get(element, ""))
	var use_dedicated: bool = not elem_path.is_empty() and ResourceLoader.exists(elem_path)
	var frames: SpriteFrames = null
	if use_dedicated:
		frames = load(elem_path) as SpriteFrames
	# 専用素材が無い/未インポートで読めない場合は通常VFXをティント着色してフォールバック
	if frames == null:
		use_dedicated = false
		if not ResourceLoader.exists(VFX_HIT_PATH):
			return
		frames = load(VFX_HIT_PATH) as SpriteFrames
	if frames == null:
		return
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.scale = _hit_vfx_sprite.scale * scale_mult
	var tint: Color = Color.WHITE if use_dedicated else ELEMENT_COLOR.get(element, Color.WHITE)
	_spawn_transient_vfx_sprite(spr, world_pos, tint)
	spr.play("default")
	spr.animation_finished.connect(func() -> void: spr.queue_free())

func _spawn_miss_telop(world_pos: Vector2) -> void:
	_spawn_damage_number("Miss!", world_pos, Color(0.82, 0.86, 0.95), 1.05, 0, true)

func _spawn_damage_number(
	text: String,
	world_pos: Vector2,
	color: Color = Color.WHITE,
	scale: float = 1.0,
	damage_value: int = 0,
	skip_impact_feedback: bool = false
) -> void:
	const DMG_FONT_SIZE: int = 40
	const DMG_OUTLINE_SIZE: int = 10
	var is_crit: bool = scale > 1.0
	if is_crit and scale < COMBAT_CRIT_DAMAGE_SCALE:
		scale = COMBAT_CRIT_DAMAGE_SCALE
	var parsed_damage: int = damage_value
	if parsed_damage <= 0:
		var digits := RegEx.new()
		if digits.compile("(\\d+)") == OK:
			var m: RegExMatch = digits.search(text)
			if m != null:
				parsed_damage = int(m.get_string(1))
	if not skip_impact_feedback:
		_trigger_combat_impact_feedback(is_crit, parsed_damage)
	if not SettingsPrefs.show_damage_numbers():
		return
	var lbl := Label.new()
	lbl.text = text
	# ゲームらしい打撃感: 重厚ゴシック体＋太い黒縁＋ドロップシャドウ
	var af: Font = UiTypography.impact_font()
	if af != null:
		lbl.add_theme_font_override("font", af)
	lbl.add_theme_font_size_override("font_size", DMG_FONT_SIZE)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	lbl.add_theme_constant_override("outline_size", DMG_OUTLINE_SIZE)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	lbl.add_theme_constant_override("shadow_offset_x", 3)
	lbl.add_theme_constant_override("shadow_offset_y", 4)
	lbl.pivot_offset = Vector2(DMG_FONT_SIZE * 0.5, DMG_FONT_SIZE * 0.5)
	lbl.position = world_pos + Vector2(-DMG_FONT_SIZE * 0.5, -DMG_FONT_SIZE)
	var target_scale: Vector2 = Vector2(scale, scale)
	lbl.scale = target_scale * 0.35
	_damage_numbers_layer.add_child(lbl)
	var rise: float = -64.0 if is_crit else -56.0
	var tw: Tween = create_tween()
	# 出現: ポップ（オーバーシュート）
	tw.tween_property(lbl, "scale", target_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# クリティカルは回転ワブルで強調
	if is_crit:
		tw.tween_property(lbl, "rotation_degrees", -5.0, 0.05)
		tw.tween_property(lbl, "rotation_degrees", 5.0, 0.05)
		tw.tween_property(lbl, "rotation_degrees", 0.0, 0.05)
	# 上昇＋減衰（フェードは上昇に並列）
	tw.tween_property(lbl, "position:y", lbl.position.y + rise, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tw.chain().tween_callback(lbl.queue_free)

func _ultimate_presentation_speed_mult() -> float:
	if _combat_speed_mult > 0.0:
		return _combat_speed_mult
	return SPEED_MULT_NORMAL

func _begin_combat_cinematic_lock() -> void:
	_combat_cinematic_lock = true
	_ultimate_presentation_active = true
	if not $CombatTimer.is_stopped():
		$CombatTimer.stop()

func _end_combat_cinematic_lock() -> void:
	_combat_cinematic_lock = false
	_ultimate_presentation_active = false
	if $CombatController.is_in_combat and not _is_paused:
		$CombatTimer.start()


## 敵出現ログのあと、実際のCT戦闘開始まで間を空ける。
func _start_combat_after_appear_delay() -> void:
	$CombatTimer.stop()
	_combat_cinematic_lock = true
	await get_tree().create_timer(COMBAT_START_DELAY_SEC).timeout
	_combat_cinematic_lock = false
	if not $CombatController.is_in_combat or _is_paused:
		return
	if _boss_intro_active or _elite_intro_active:
		return
	$CombatTimer.start()

func _show_ultimate_center_telop(skill_name: String, element: String = "") -> void:
	_dismiss_ultimate_center_telop(0.0)
	if skill_name.is_empty():
		return
	const TITLE_FONT_SIZE: int = 22
	const NAME_FONT_SIZE: int = 52
	var layer := Control.new()
	layer.name = "UltimateCenterTelop"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = 140
	var wrap := VBoxContainer.new()
	wrap.set_anchors_preset(Control.PRESET_CENTER)
	wrap.offset_left = -280.0
	wrap.offset_right = 280.0
	wrap.offset_top = -72.0
	wrap.offset_bottom = 72.0
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = "必殺技"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var af: Font = UiTypography.impact_font()
	if af != null:
		title.add_theme_font_override("font", af)
		title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	title.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.0, 0.95))
	title.add_theme_constant_override("outline_size", 6)
	var name_lbl := Label.new()
	name_lbl.text = skill_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if af != null:
		name_lbl.add_theme_font_override("font", af)
	name_lbl.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	var name_color: Color = ELEMENT_COLOR.get(element, ULTIMATE_GOLD)
	name_lbl.add_theme_color_override("font_color", name_color)
	name_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.0, 0.95))
	name_lbl.add_theme_constant_override("outline_size", 12)
	name_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	name_lbl.add_theme_constant_override("shadow_offset_x", 4)
	name_lbl.add_theme_constant_override("shadow_offset_y", 5)
	wrap.add_child(title)
	wrap.add_child(name_lbl)
	layer.add_child(wrap)
	$TransitionLayer.add_child(layer)
	_ultimate_center_telop = layer
	wrap.pivot_offset = wrap.size * 0.5
	wrap.scale = Vector2(0.35, 0.35)
	wrap.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(wrap, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(wrap, "modulate:a", 1.0, 0.16)

func _dismiss_ultimate_center_telop(fade_sec: float = 0.25) -> void:
	if _ultimate_center_telop == null or not is_instance_valid(_ultimate_center_telop):
		_ultimate_center_telop = null
		return
	var node: Control = _ultimate_center_telop
	_ultimate_center_telop = null
	if fade_sec <= 0.0:
		node.queue_free()
		return
	var tw: Tween = create_tween()
	tw.tween_property(node, "modulate:a", 0.0, fade_sec)
	tw.chain().tween_callback(node.queue_free)

func _play_ultimate_presentation_async(payload: Dictionary) -> void:
	var speed: float = _ultimate_presentation_speed_mult()
	var t: Dictionary = UltimatePresentationConfigScript.scaled(speed)
	_begin_combat_cinematic_lock()
	var member_idx: int = int(payload.get("member_idx", -1))
	var skill_data: Resource = payload.get("skill_data") as Resource
	var display_name: String = str(payload.get("display_name", ""))
	var kind: String = str(payload.get("kind", "damage"))
	var element: String = str(payload.get("attack_element", ""))
	var is_heal: bool = kind == "heal"
	AudioManager.play_sfx("combat_ultimate")
	_show_ultimate_center_telop(display_name, element)
	_pulse_member_ultimate(member_idx)
	await get_tree().create_timer(float(t["announce"])).timeout
	if not $CombatController.is_in_combat:
		_dismiss_ultimate_center_telop(0.1)
		_end_combat_cinematic_lock()
		return
	var caster_pos: Vector2 = _member_sprite_world_pos(member_idx, 0.35)
	var ring_tint: Color = Color(0.65, 1.0, 0.78) if is_heal else ULTIMATE_GOLD
	_spawn_ultimate_ring_burst(caster_pos, ring_tint, 1.65)
	_flash_battlefield(ULTIMATE_FLASH_HEAL if is_heal else ULTIMATE_FLASH_DAMAGE, 0.22 if is_heal else 0.2)
	_flash_member_sprite(member_idx, ring_tint)
	await get_tree().create_timer(float(t["windup"])).timeout
	if not $CombatController.is_in_combat:
		_dismiss_ultimate_center_telop(0.1)
		_end_combat_cinematic_lock()
		return
	if is_heal:
		var target_idx: int = int(payload.get("target_idx", -1))
		var focus_pos: Vector2 = _member_sprite_world_pos(target_idx, 0.5)
		_play_ultimate_resolve_vfx(member_idx, skill_data, focus_pos, "")
		_apply_ultimate_heal_impact(payload)
	else:
		var focus_pos: Vector2 = payload.get("spawn_pos", Vector2.ZERO) as Vector2
		_play_ultimate_resolve_vfx(member_idx, skill_data, focus_pos, element)
		_play_chr_attack_one(member_idx)
		_apply_ultimate_damage_impact(payload)
	_dismiss_ultimate_center_telop(float(t["release"]))
	await get_tree().create_timer(float(t["release"])).timeout
	_end_combat_cinematic_lock()
	_update_hp_bars()

func _apply_ultimate_damage_impact(payload: Dictionary) -> void:
	var member_idx: int = int(payload.get("member_idx", -1))
	var final_dmg: int = int(payload.get("final_dmg", 0))
	var target_slot: int = int(payload.get("target_slot", -1))
	var skill_is_crit: bool = bool(payload.get("skill_is_crit", false))
	var spawn_pos: Vector2 = payload.get("spawn_pos", Vector2.ZERO) as Vector2
	var ult_dmg_scale: float = 1.65 if skill_is_crit else 1.4
	_spawn_damage_number(
		str(final_dmg),
		spawn_pos + Vector2(12.0, 0.0),
		_outgoing_damage_telop_color(skill_is_crit, true),
		ult_dmg_scale
	)
	var skill_data: Resource = payload.get("skill_data") as Resource
	var log_line: String = str(payload.get("log_line", ""))
	if _deal_member_damage_to_enemy(
		member_idx,
		final_dmg,
		target_slot,
		str(payload.get("skill_id", "")),
		str(payload.get("display_name", "スキル"))
	):
		pass
	else:
		_apply_skill_status(member_idx, skill_data)
		_apply_skill_secondary_status(member_idx, skill_data)
	if not log_line.is_empty():
		_append_log("【必殺】" + log_line.trim_prefix("【スキル】"))

func _apply_ultimate_heal_impact(payload: Dictionary) -> void:
	var member_idx: int = int(payload.get("member_idx", -1))
	var target_idx: int = int(payload.get("target_idx", -1))
	var heal_amount: int = int(payload.get("heal_amount", 0))
	var display_name: String = str(payload.get("display_name", ""))
	var target_name: String = str(payload.get("target_name", ""))
	var healed: int = $CombatController.heal_member(target_idx, heal_amount)
	if healed > 0:
		GameState.record_run_heal(member_idx, healed)
	_set_heal_rally(target_idx)
	if healed > 0:
		_spawn_member_heal_vfx(target_idx)
		if target_idx >= 0 and target_idx < _chr_sprites.size() and _chr_sprites[target_idx].visible:
			var heal_pos: Vector2 = _chr_sprites[target_idx].global_position + Vector2(0.0, -CHR_BODY_TARGET_PX * 0.5)
			_spawn_damage_number("+%d" % healed, heal_pos, ULTIMATE_GOLD, 1.45)
	_append_log(
		"【必殺】"
		+ ("\n【スキル】%s: %s を %d回復" % [display_name, target_name, healed]).trim_prefix("【スキル】")
	)

func _is_ultimate_skill(skill_data: Resource) -> bool:
	return skill_data != null and str(skill_data.slot_type) == "ultimate"

func _flash_battlefield(flash_color: Color, peak_alpha: float = 0.38) -> void:
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
	flash.z_index = 120
	_damage_numbers_layer.add_child(flash)
	var tw: Tween = create_tween()
	tw.tween_property(flash, "color:a", peak_alpha, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(flash, "color:a", 0.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(flash.queue_free)

func _shake_battlefield(intensity: float = 9.0) -> void:
	var base: Vector2 = position
	var tw: Tween = create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position", base + Vector2(intensity, -intensity * 0.45), 0.04)
	tw.tween_property(self, "position", base + Vector2(-intensity * 0.85, intensity * 0.35), 0.04)
	tw.tween_property(self, "position", base + Vector2(intensity * 0.5, intensity * 0.25), 0.035)
	tw.tween_property(self, "position", base, 0.055).set_ease(Tween.EASE_OUT)

func _pulse_member_ultimate(member_idx: int) -> void:
	if member_idx < 0 or member_idx >= _chr_sprites.size():
		return
	var sprite: AnimatedSprite2D = _chr_sprites[member_idx]
	if not sprite.visible:
		return
	var orig_scale: Vector2 = sprite.scale
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "scale", orig_scale * 1.14, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", orig_scale, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flash_member_sprite(member_idx, Color(1.0, 0.9, 0.5))

func _spawn_ultimate_ring_burst(world_pos: Vector2, tint: Color, peak_scale: float = 2.1) -> void:
	if world_pos == Vector2.ZERO or not ResourceLoader.exists(VFX_HEAL_PATH):
		return
	var frames: SpriteFrames = load(VFX_HEAL_PATH) as SpriteFrames
	if frames == null:
		return
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.global_position = world_pos
	spr.modulate = tint
	spr.scale = Vector2(0.35, 0.35)
	spr.z_index = 20
	add_child(spr)
	spr.play("default")
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(spr, "scale", Vector2(peak_scale, peak_scale), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "modulate:a", 0.0, 0.32).set_delay(0.08)
	tw.chain().tween_callback(spr.queue_free)

func _spawn_ultimate_impact_vfx(world_pos: Vector2, element: String = "") -> void:
	if world_pos == Vector2.ZERO:
		return
	var offsets: Array[Vector2] = [Vector2(-26.0, -10.0), Vector2.ZERO, Vector2(30.0, -14.0)]
	for i: int in offsets.size():
		var hit_pos: Vector2 = world_pos + offsets[i]
		var delay: float = float(i) * 0.055
		var tw: Tween = create_tween()
		tw.tween_interval(delay)
		tw.tween_callback(func() -> void: _spawn_hit_vfx(hit_pos, element, 1.5))

func _play_ultimate_cast_vfx(member_idx: int, skill_data: Resource) -> void:
	var caster_pos: Vector2 = _member_sprite_world_pos(member_idx, 0.35)
	var is_heal: bool = skill_data != null and str(skill_data.effect_type) == "heal"
	var ring_tint: Color = Color(0.65, 1.0, 0.78) if is_heal else ULTIMATE_GOLD
	_spawn_ultimate_ring_burst(caster_pos, ring_tint, 1.45)
	_flash_battlefield(ULTIMATE_FLASH_HEAL if is_heal else ULTIMATE_FLASH_DAMAGE, 0.16)
	_flash_member_sprite(member_idx, ring_tint)

func _play_ultimate_resolve_vfx(
	member_idx: int,
	skill_data: Resource,
	focus_pos: Vector2,
	element: String = ""
) -> void:
	var is_heal: bool = skill_data != null and str(skill_data.effect_type) == "heal"
	_flash_battlefield(ULTIMATE_FLASH_HEAL if is_heal else ULTIMATE_FLASH_DAMAGE, 0.44 if is_heal else 0.4)
	_shake_battlefield(11.5 if is_heal else 12.0)
	_pulse_member_ultimate(member_idx)
	var caster_pos: Vector2 = _member_sprite_world_pos(member_idx, 0.35)
	var ring_tint: Color = Color(0.7, 1.0, 0.82) if is_heal else ULTIMATE_GOLD
	_spawn_ultimate_ring_burst(caster_pos, ring_tint, 2.25)
	if is_heal:
		for i: int in GameState.party_members.size():
			if $CombatController.is_member_alive(i):
				_spawn_ultimate_ring_burst(_member_sprite_world_pos(i, 0.4), Color(0.55, 1.0, 0.72), 1.35)
	elif focus_pos != Vector2.ZERO:
		_spawn_ultimate_impact_vfx(focus_pos, element)

func _spawn_ultimate_skill_name(
	skill_name: String,
	member_idx: int,
	element: String = "",
	persist: bool = false
) -> void:
	if skill_name.is_empty():
		return
	if member_idx < 0 or member_idx >= _chr_sprites.size():
		return
	var sprite: AnimatedSprite2D = _chr_sprites[member_idx]
	if not sprite.visible:
		return
	const TITLE_FONT_SIZE: int = 16
	const NAME_FONT_SIZE: int = 36
	var wrap := VBoxContainer.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = "必殺技"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var af: Font = UiTypography.impact_font()
	if af != null:
		title.add_theme_font_override("font", af)
		title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	title.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.0, 0.95))
	title.add_theme_constant_override("outline_size", 5)
	var name_lbl := Label.new()
	name_lbl.text = skill_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if af != null:
		name_lbl.add_theme_font_override("font", af)
	name_lbl.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	var name_color: Color = ELEMENT_COLOR.get(element, ULTIMATE_GOLD)
	name_lbl.add_theme_color_override("font_color", name_color)
	name_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.0, 0.95))
	name_lbl.add_theme_constant_override("outline_size", 10)
	name_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	name_lbl.add_theme_constant_override("shadow_offset_x", 3)
	name_lbl.add_theme_constant_override("shadow_offset_y", 4)
	wrap.add_child(title)
	wrap.add_child(name_lbl)
	var wrap_w: float = maxf(float(skill_name.length()) * 26.0, 120.0)
	var wrap_h: float = float(TITLE_FONT_SIZE + NAME_FONT_SIZE + 10)
	wrap.custom_minimum_size = Vector2(wrap_w, wrap_h)
	var head_center: Vector2 = _sprite_visual_center_global(sprite)
	var head_top: float = _sprite_top_y_global(sprite) - 72.0
	var base_x: float = head_center.x
	wrap.position = Vector2(base_x - wrap_w * 0.5, head_top)
	wrap.pivot_offset = Vector2(wrap_w * 0.5, wrap_h * 0.5)
	wrap.scale = Vector2(0.25, 0.25)
	wrap.modulate.a = 0.0
	wrap.z_index = 16
	_damage_numbers_layer.add_child(wrap)
	if member_idx < _chr_skill_labels.size():
		_chr_skill_labels[member_idx].append(wrap)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(wrap, "scale", Vector2(1.12, 1.12), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(wrap, "modulate:a", 1.0, 0.14)
	tw.chain().tween_property(wrap, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if persist:
		_arm_chant_label_failsafe(wrap, member_idx, 14.0)
		return
	tw.chain().set_parallel(true)
	tw.tween_property(wrap, "position:y", head_top - 36.0, 0.85)
	tw.tween_property(wrap, "modulate:a", 0.0, 0.6).set_delay(0.45)
	tw.chain().tween_callback(func() -> void:
		if member_idx < _chr_skill_labels.size():
			_chr_skill_labels[member_idx].erase(wrap)
		if is_instance_valid(wrap):
			wrap.queue_free()
	)

# スキル発動時、発動者(ドット絵)の頭上にスキル名をポップ表示する。
# persist=true のときは詠唱中ラベルとして表示を維持（_clear_member_skill_labels で除去）。
func _spawn_skill_name(
	skill_name: String,
	member_idx: int,
	stack_offset: float = 0.0,
	element: String = "",
	persist: bool = false
) -> void:
	if skill_name.is_empty():
		return
	if member_idx < 0 or member_idx >= _chr_sprites.size():
		return
	var sprite: AnimatedSprite2D = _chr_sprites[member_idx]
	if not sprite.visible:
		return
	## 詠唱中ラベルは静音。resolve / 即時発動のみ combat_skill（必殺は combat_ultimate）。
	if not persist:
		AudioManager.play_sfx("combat_skill", 1.0, 0.08)
	const SKILL_FONT_SIZE: int = 28
	var lbl := Label.new()
	lbl.text = skill_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var af: Font = UiTypography.impact_font()
	if af != null:
		lbl.add_theme_font_override("font", af)
	lbl.add_theme_font_size_override("font_size", SKILL_FONT_SIZE)
	lbl.add_theme_color_override("font_color", ELEMENT_COLOR.get(element, Color(0.72, 0.93, 1.0)))
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.05, 0.12, 0.95))
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	lbl.reset_size()
	var text_w: float = maxf(lbl.size.x, float(skill_name.length()) * float(SKILL_FONT_SIZE) * 0.55)
	var head_center: Vector2 = _sprite_visual_center_global(sprite)
	var head_top: float = _sprite_top_y_global(sprite) - 44.0 + stack_offset
	var base_x: float = head_center.x - text_w * 0.5
	lbl.custom_minimum_size = Vector2(text_w, lbl.size.y)
	lbl.pivot_offset = Vector2(text_w * 0.5, lbl.size.y * 0.5)
	lbl.position = Vector2(base_x - 18.0, head_top)
	lbl.scale = Vector2(0.7, 0.7)
	lbl.modulate.a = 0.0
	lbl.z_index = 8
	_damage_numbers_layer.add_child(lbl)
	if member_idx < _chr_skill_labels.size():
		_chr_skill_labels[member_idx].append(lbl)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:x", base_x, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.12)
	if persist:
		_arm_chant_label_failsafe(lbl, member_idx, 14.0)
		return
	tw.chain().set_parallel(true)
	tw.tween_property(lbl, "position:y", head_top - 30.0, 0.75)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.55).set_delay(0.4)
	tw.chain().tween_callback(func() -> void:
		if member_idx < _chr_skill_labels.size():
			_chr_skill_labels[member_idx].erase(lbl)
		if is_instance_valid(lbl):
			lbl.queue_free()
	)

# 味方の詠唱中ポップ（P3-D112）— 互換のため残すが、通常は _spawn_skill_name(persist=true) を使用。
func _spawn_cast_chant_label(skill_name: String, member_idx: int) -> void:
	_spawn_skill_name(skill_name, member_idx, 0.0, "", true)

# 詠唱ラベルが除去漏れした場合の安全弁（必殺テキスト残留の再発防止）。
func _arm_chant_label_failsafe(node: Node, member_idx: int, seconds: float) -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(maxf(seconds, 1.0))
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(node):
			return
		if member_idx < 0 or member_idx >= _chr_skill_labels.size():
			node.queue_free()
			return
		if node in _chr_skill_labels[member_idx]:
			_chr_skill_labels[member_idx].erase(node)
		node.queue_free()
	)

# メンバーの表示中スキル名ラベルを即時除去（新しい tick の発動で旧ラベルを置換する）
func _clear_member_skill_labels(member_idx: int) -> void:
	if member_idx < 0 or member_idx >= _chr_skill_labels.size():
		return
	for lbl in _chr_skill_labels[member_idx]:
		if is_instance_valid(lbl):
			lbl.free()
	_chr_skill_labels[member_idx] = []

func _clear_all_member_skill_labels() -> void:
	for i in _chr_skill_labels.size():
		_clear_member_skill_labels(i)

func _clear_damage_numbers_layer() -> void:
	for child in _damage_numbers_layer.get_children():
		child.queue_free()

func _rainbow_bbcode_text(plain: String, hue_phase: float) -> String:
	var parts: PackedStringArray = []
	var n: int = plain.length()
	for i: int in n:
		var hue: float = fmod(hue_phase + float(i) / float(maxi(n, 1)), 1.0)
		var col: Color = Color.from_hsv(hue, 0.92, 1.0)
		parts.append("[color=#%s]%s[/color]" % [col.to_html(false), plain[i]])
	return "[b]%s[/b]" % "".join(parts)

func _spawn_relic_confetti(piece_count: int = 44) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var vp: Rect2 = get_viewport().get_visible_rect()
	for _i: int in piece_count:
		var piece := ColorRect.new()
		piece.size = Vector2(rng.randf_range(5.0, 11.0), rng.randf_range(7.0, 16.0))
		piece.color = Color.from_hsv(rng.randf(), rng.randf_range(0.75, 1.0), 1.0, 0.95)
		piece.rotation = rng.randf_range(-0.8, 0.8)
		piece.position = Vector2(rng.randf_range(0.0, vp.size.x), rng.randf_range(-40.0, vp.size.y * 0.25))
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece.z_index = 180
		_damage_numbers_layer.add_child(piece)
		var drift_x: float = rng.randf_range(-160.0, 160.0)
		var fall_y: float = vp.size.y + rng.randf_range(40.0, 120.0)
		var duration: float = rng.randf_range(1.1, 2.4)
		var tw: Tween = create_tween()
		tw.set_parallel(true)
		tw.tween_property(piece, "position:y", fall_y, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(piece, "position:x", piece.position.x + drift_x, duration)
		tw.tween_property(piece, "rotation", piece.rotation + rng.randf_range(-2.5, 2.5), duration)
		tw.tween_property(piece, "modulate:a", 0.0, 0.55).set_delay(maxf(0.0, duration - 0.55))
		tw.chain().tween_callback(piece.queue_free)

func _set_relic_telop_rainbow(lbl: RichTextLabel, plain: String, phase: float) -> void:
	if is_instance_valid(lbl):
		lbl.text = _rainbow_bbcode_text(plain, phase)

func _play_relic_get_telop(plain: String) -> void:
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var af: Font = UiTypography.impact_font()
	if af != null:
		lbl.add_theme_font_override("normal_font", af)
	lbl.add_theme_font_size_override("normal_font_size", 44)
	lbl.text = _rainbow_bbcode_text(plain, 0.0)
	lbl.z_index = 220
	_damage_numbers_layer.add_child(lbl)
	var vp: Rect2 = get_viewport().get_visible_rect()
	var est_w: float = maxf(float(plain.length()) * 30.0, 220.0)
	var y: float = vp.size.y * 0.36
	lbl.position = Vector2(vp.size.x + 32.0, y)
	var tw: Tween = create_tween()
	tw.tween_property(lbl, "position:x", -est_w - 48.0, 3.4).set_trans(Tween.TRANS_LINEAR)
	tw.parallel().tween_method(_set_relic_telop_rainbow.bind(lbl, plain), 0.0, 1.6, 3.4)
	tw.chain().tween_callback(lbl.queue_free)

func _play_relic_get_celebration(relic_id: String) -> void:
	var relic_name: String = CombatRelics.display_name(relic_id)
	if relic_name.is_empty() or relic_name == "なし":
		return
	_spawn_relic_confetti(48)
	_flash_battlefield(Color(1.0, 0.92, 0.55), 0.32)
	_play_relic_get_telop("%s Get!!" % relic_name)

# P3-D074 / 撃破ドロップ演出: 実際の入手物（金・素材・装備）ごとにアイコンをポップ。
const GOLD_DROP_ICON_PATH: String = "res://assets/ui/batch2/ICO_Gold.png"
const MATERIAL_DROP_FALLBACK_ICON_PATH: String = "res://assets/ui/materials/ICO_Drop_Ore.png"
## 128px 素材／金アイコンは scale=1.0 だと戦場で過大。武器より一回り小さくする。
const MATERIAL_DROP_PEAK_SCALE: float = 0.7
const GOLD_DROP_PEAK_SCALE: float = 0.7
const EQUIPMENT_DROP_PEAK_SCALE: float = 1.0
const DROP_FAN_SPACING_PX: float = 28.0
const DROP_ICON_MAX_PER_KIND: int = 4


func _resolve_material_drop_texture(material_id: String) -> Texture2D:
	var tex: Texture2D = IconPaths.get_icon_texture(material_id, "material")
	if tex != null:
		return tex
	if ResourceLoader.exists(MATERIAL_DROP_FALLBACK_ICON_PATH):
		return load(MATERIAL_DROP_FALLBACK_ICON_PATH) as Texture2D
	return null


func _append_gold_drop_icons(drop_icons: Array, gold_amount: int) -> void:
	if gold_amount <= 0 or not ResourceLoader.exists(GOLD_DROP_ICON_PATH):
		return
	var tex: Texture2D = load(GOLD_DROP_ICON_PATH) as Texture2D
	if tex == null:
		return
	# 多めの金は最大3枚まで並べる（個別コイン演出）。
	var count: int = clampi(ceili(float(gold_amount) / 25.0), 1, 3)
	for _i in range(count):
		drop_icons.append({"tex": tex, "peak_scale": GOLD_DROP_PEAK_SCALE})


func _append_material_drop_icons(drop_icons: Array, material_id: String, amount: int = 1) -> void:
	var tex: Texture2D = _resolve_material_drop_texture(material_id)
	if tex == null:
		return
	var count: int = clampi(amount, 1, DROP_ICON_MAX_PER_KIND)
	for _i in range(count):
		drop_icons.append({"tex": tex, "peak_scale": MATERIAL_DROP_PEAK_SCALE})


func _append_equipment_drop_icon(drop_icons: Array, item_id: String, category: String) -> void:
	var tex: Texture2D = IconPaths.get_icon_texture(item_id, category)
	if tex == null:
		return
	drop_icons.append({"tex": tex, "peak_scale": EQUIPMENT_DROP_PEAK_SCALE})


func _spawn_pickup_drop_burst(world_pos: Vector2, drop_icons: Array) -> void:
	if drop_icons.is_empty() or world_pos == Vector2.ZERO:
		return
	var count: int = drop_icons.size()
	for i in range(count):
		var entry: Dictionary = drop_icons[i]
		var tex: Texture2D = entry.get("tex") as Texture2D
		if tex == null:
			continue
		var peak_scale: float = float(entry.get("peak_scale", 1.0))
		var offset_x: float = (float(i) - float(count - 1) * 0.5) * DROP_FAN_SPACING_PX
		_spawn_pickup_drop(
			tex,
			world_pos + Vector2(offset_x, 0.0),
			0.05 * float(i),
			peak_scale
		)


func _spawn_pickup_drop(
	tex: Texture2D,
	world_pos: Vector2,
	start_delay: float = 0.0,
	peak_scale: float = 1.0
) -> void:
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.global_position = world_pos
	spr.scale = Vector2(0.1, 0.1) * peak_scale
	spr.z_index = 50
	add_child(spr)
	var settle_y: float = world_pos.y - 24.0
	var pickup_target: Vector2 = world_pos + Vector2(0.0, 200.0)
	var tw: Tween = create_tween()
	# 敵の死亡アニメ後に出現させるための待機
	tw.tween_interval(0.35 + start_delay)
	# ポップ（拡大＋上方へ放物）
	tw.tween_property(spr, "scale", Vector2(peak_scale, peak_scale), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(spr, "global_position:y", world_pos.y - 56.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 着地
	tw.tween_property(spr, "global_position:y", settle_y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# 入手（吸い込み＋縮小＋フェード）
	tw.tween_interval(0.2)
	tw.tween_property(spr, "global_position", pickup_target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(spr, "scale", Vector2(peak_scale * 0.3, peak_scale * 0.3), 0.35)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 0.35)
	tw.tween_callback(spr.queue_free)

func _member_sprite_world_pos(member_idx: int, height_ratio: float = 0.5) -> Vector2:
	if member_idx < 0 or member_idx >= _chr_sprites.size():
		return Vector2.ZERO
	var sprite: AnimatedSprite2D = _chr_sprites[member_idx]
	if not sprite.visible:
		return Vector2.ZERO
	return sprite.global_position + Vector2(0.0, -CHR_BODY_TARGET_PX * height_ratio)

func _spawn_support_sprite_vfx(world_pos: Vector2, vfx_path: String, tint: Color) -> void:
	if world_pos == Vector2.ZERO or not ResourceLoader.exists(vfx_path):
		return
	var frames: SpriteFrames = load(vfx_path) as SpriteFrames
	if frames == null:
		return
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.global_position = world_pos
	spr.modulate = tint
	spr.scale = Vector2(0.85, 0.85)
	add_child(spr)
	spr.play("default")
	spr.animation_finished.connect(func() -> void: spr.queue_free())

func _flash_member_sprite(member_idx: int, flash_color: Color) -> void:
	if member_idx < 0 or member_idx >= _chr_sprites.size():
		return
	var sprite: AnimatedSprite2D = _chr_sprites[member_idx]
	if not sprite.visible:
		return
	var orig: Color = sprite.modulate
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "modulate", flash_color, 0.08)
	tw.tween_property(sprite, "modulate", orig, 0.22)

func _spawn_member_heal_vfx(member_idx: int) -> void:
	AudioManager.play_sfx("combat_heal", 1.0, 0.05)
	var pos: Vector2 = _member_sprite_world_pos(member_idx)
	_spawn_support_sprite_vfx(pos, VFX_HEAL_PATH, SUPPORT_VFX_TINT["heal"])
	_flash_member_sprite(member_idx, Color(0.65, 1.0, 0.7))

func _spawn_member_buff_vfx(member_idx: int, status_id: String = "") -> void:
	var tint: Color = SUPPORT_VFX_TINT.get(status_id, SUPPORT_VFX_TINT["default_buff"])
	var pos: Vector2 = _member_sprite_world_pos(member_idx)
	_spawn_support_sprite_vfx(pos, VFX_HEAL_PATH, tint)
	_flash_member_sprite(member_idx, tint)

func _play_heal_vfx() -> void:
	for i: int in GameState.party_members.size():
		if $CombatController.is_member_alive(i):
			_spawn_member_heal_vfx(i)

# ---- Elite Intro ----

func _elite_intro_timings(short: bool) -> Dictionary:
	if short:
		return {
			"warning": 0.14,
			"hold": 0.1,
			"reveal": 0.16,
			"shake": 5.0,
			"flash": 0.12,
			"slide_offset": 96.0,
		}
	return {
		"warning": 0.32,
		"hold": 0.18,
		"reveal": 0.28,
		"shake": 8.0,
		"flash": 0.18,
		"slide_offset": 140.0,
	}

func _ensure_elite_intro_label() -> Label:
	if _elite_intro_label != null and is_instance_valid(_elite_intro_label):
		return _elite_intro_label
	_elite_intro_label = Label.new()
	_elite_intro_label.name = "EliteIntroLabel"
	_elite_intro_label.visible = false
	_elite_intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_elite_intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_elite_intro_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_elite_intro_label.set_anchors_preset(Control.PRESET_CENTER)
	_elite_intro_label.offset_left = -220.0
	_elite_intro_label.offset_right = 220.0
	_elite_intro_label.offset_top = -96.0
	_elite_intro_label.offset_bottom = -36.0
	$TransitionLayer.add_child(_elite_intro_label)
	return _elite_intro_label

func _clear_elite_intro_fx() -> void:
	if _elite_intro_label != null and is_instance_valid(_elite_intro_label):
		_elite_intro_label.visible = false
		_elite_intro_label.modulate = Color.WHITE
		_elite_intro_label.scale = Vector2.ONE

func _prepare_elite_enemy_for_entrance() -> void:
	_elite_enemy_slide_sprite = null
	_elite_enemy_slide_target = Vector2.ZERO
	var offset_x: float = float(_elite_intro_timings(false).get("slide_offset", 140.0))
	for i in _swarm_sprites.size():
		var spr: AnimatedSprite2D = _swarm_sprites[i]
		if not spr.visible:
			continue
		_elite_enemy_slide_sprite = spr
		_elite_enemy_slide_target = spr.position
		spr.position = _elite_enemy_slide_target + Vector2(offset_x, 0.0)
		spr.modulate = Color(1.0, 1.0, 1.0, 0.0)
		if i < _swarm_hp_bars.size():
			_swarm_hp_bars[i].visible = false
		if i < _swarm_nameplates.size():
			_swarm_nameplates[i].visible = false
		break

func _reveal_elite_enemy(duration: float) -> void:
	if _elite_enemy_slide_sprite == null or not is_instance_valid(_elite_enemy_slide_sprite):
		_update_hp_bars()
		return
	var spr: AnimatedSprite2D = _elite_enemy_slide_sprite
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(spr, "position", _elite_enemy_slide_target, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "modulate:a", 1.0, duration * 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(_update_hp_bars)

func _pulse_elite_tier_frame_once() -> void:
	_stop_tier_frame_pulse()
	var tw: Tween = create_tween()
	tw.tween_property(_combat_tier_frame, "modulate", Color(1.15, 1.05, 0.65), 0.22)
	tw.tween_property(_combat_tier_frame, "modulate", Color.WHITE, 0.28)

func _finish_elite_combat_entrance(lead: Resource) -> void:
	_elite_intro_active = false
	_elite_intro_tween = null
	_clear_elite_intro_fx()
	_elite_enemy_slide_sprite = null
	if lead != null:
		_append_log("【エリート】%s があらわれた" % lead.display_name)
	_refresh_combat_now_playing_next()
	if _try_combat_skip():
		return
	_start_combat_after_appear_delay()

func _begin_elite_combat_entrance(lead: Resource) -> void:
	if lead == null:
		_finish_elite_combat_entrance(lead)
		return
	_elite_intro_active = true
	$CombatTimer.stop()
	var short: bool = _fast_run_enabled
	var t: Dictionary = _elite_intro_timings(short)
	_clear_elite_intro_fx()
	if _elite_enemy_slide_sprite == null or not is_instance_valid(_elite_enemy_slide_sprite):
		var slide_offset: float = float(t.get("slide_offset", 140.0))
		_prepare_elite_enemy_for_entrance()
		if _elite_enemy_slide_sprite != null and is_instance_valid(_elite_enemy_slide_sprite):
			_elite_enemy_slide_sprite.position = _elite_enemy_slide_target + Vector2(slide_offset, 0.0)
	_update_combat_tier_frame()
	_pulse_elite_tier_frame_once()
	var intro_lbl: Label = _ensure_elite_intro_label()
	intro_lbl.text = ELITE_INTRO_TEXT
	intro_lbl.visible = true
	intro_lbl.modulate = Color(1.0, 1.0, 1.0, 0.0)
	intro_lbl.scale = Vector2(0.88, 0.88)
	UiTypography.apply_display(
		intro_lbl,
		UiTypography.SIZE_DISPLAY,
		Color(1.0, 0.82, 0.28),
		UiTypography.OUTLINE_STRONG
	)
	_request_combat_shake(float(t.get("shake", 8.0)))
	_flash_battlefield(Color(1.0, 0.72, 0.28), float(t.get("flash", 0.18)))
	if _elite_intro_tween != null and is_instance_valid(_elite_intro_tween):
		_elite_intro_tween.kill()
	_elite_intro_tween = create_tween()
	_elite_intro_tween.tween_property(intro_lbl, "modulate:a", 1.0, 0.1)
	_elite_intro_tween.parallel().tween_property(intro_lbl, "scale", Vector2(1.04, 1.04), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_elite_intro_tween.tween_interval(float(t.get("warning", 0.32)))
	_elite_intro_tween.tween_property(intro_lbl, "modulate:a", 0.0, 0.12)
	_elite_intro_tween.tween_callback(func() -> void: _reveal_elite_enemy(float(t.get("reveal", 0.28))))
	_elite_intro_tween.tween_interval(float(t.get("hold", 0.18)))
	_elite_intro_tween.tween_callback(func() -> void: _finish_elite_combat_entrance(lead))

# ---- Boss Sprite ----

func _boss_intro_timings(short: bool) -> Dictionary:
	if short:
		return {
			"warning": 0.18,
			"hold": 0.12,
			"reveal": 0.18,
			"shake": 8.0,
			"flash": 0.15,
			"debris_amount": 28,
			"debris_life": 0.75,
		}
	return {
		"warning": 0.48,
		"hold": 0.35,
		"reveal": 0.38,
		"shake": 14.0,
		"flash": 0.24,
		"debris_amount": 72,
		"debris_life": 1.35,
	}

func _boss_debris_color(dungeon_id: String) -> Color:
	match dungeon_id:
		"blackshore", "broken_marsh":
			return Color(0.72, 0.58, 0.38, 0.88)
		"frostridge", "north_reach":
			return Color(0.88, 0.92, 1.0, 0.82)
		"whisperwood", "mistfen":
			return Color(0.55, 0.48, 0.34, 0.85)
		_:
			return Color(0.62, 0.58, 0.54, 0.9)

func _make_debris_texture() -> Texture2D:
	var img := Image.create(6, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.55, 0.52, 0.48, 0.95))
	return ImageTexture.create_from_image(img)

func _ensure_boss_warning_label() -> Label:
	if _boss_warning_label != null and is_instance_valid(_boss_warning_label):
		return _boss_warning_label
	_boss_warning_label = Label.new()
	_boss_warning_label.name = "BossWarningLabel"
	_boss_warning_label.visible = false
	_boss_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_boss_warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_warning_label.set_anchors_preset(Control.PRESET_CENTER)
	_boss_warning_label.offset_left = -260.0
	_boss_warning_label.offset_right = 260.0
	_boss_warning_label.offset_top = -120.0
	_boss_warning_label.offset_bottom = -40.0
	$TransitionLayer.add_child(_boss_warning_label)
	return _boss_warning_label

func _clear_boss_intro_fx() -> void:
	if _boss_warning_label != null and is_instance_valid(_boss_warning_label):
		_boss_warning_label.visible = false
		_boss_warning_label.modulate = Color.WHITE
		_boss_warning_label.scale = Vector2.ONE
	if _transition_fx_host != null and is_instance_valid(_transition_fx_host):
		for c in _transition_fx_host.get_children():
			if str(c.name).begins_with("BossDebris"):
				c.queue_free()

func _spawn_boss_debris_fall(short: bool) -> void:
	_init_dungeon_presentation_ui()
	if _transition_fx_host == null:
		return
	var t: Dictionary = _boss_intro_timings(short)
	var dungeon_id: String = GameState.get_active_dungeon_id()
	var parts := CPUParticles2D.new()
	parts.name = "BossDebrisParticles"
	parts.texture = _make_debris_texture()
	parts.amount = int(t.get("debris_amount", 64))
	parts.lifetime = float(t.get("debris_life", 1.0))
	parts.one_shot = false
	parts.emitting = true
	var view: Vector2 = get_viewport_rect().size
	parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	parts.emission_rect_extents = Vector2(view.x * 0.55, 6.0)
	parts.position = Vector2(view.x * 0.5, 12.0)
	parts.direction = Vector2(0.08, 1.0)
	parts.spread = 24.0
	parts.gravity = Vector2(30.0, 720.0)
	parts.initial_velocity_min = 140.0
	parts.initial_velocity_max = 320.0
	parts.angular_velocity_min = -180.0
	parts.angular_velocity_max = 180.0
	parts.modulate = _boss_debris_color(dungeon_id)
	_transition_fx_host.add_child(parts)
	var stop_after: float = float(t.get("debris_life", 1.0)) + 0.35
	get_tree().create_timer(stop_after).timeout.connect(func() -> void:
		if is_instance_valid(parts):
			parts.emitting = false
			parts.finished.connect(parts.queue_free)
	)

func _reveal_boss_sprite(duration: float) -> void:
	if not _boss_sprite.visible:
		_boss_sprite.visible = true
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(_boss_sprite, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_boss_sprite, "scale", _boss_intro_base_scale, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _finish_boss_combat_entrance(lead: Resource) -> void:
	_boss_intro_active = false
	_boss_intro_tween = null
	_clear_boss_intro_fx()
	if lead != null:
		_append_log("【ボス】%s があらわれた" % lead.display_name)
	_refresh_combat_now_playing_next()
	if _try_combat_skip():
		return
	_start_combat_after_appear_delay()

func _begin_boss_combat_entrance(lead: Resource) -> void:
	if lead == null or not _boss_sprite.visible:
		_finish_boss_combat_entrance(lead)
		return
	_boss_intro_active = true
	$CombatTimer.stop()
	AudioManager.play_sfx("room_enter", 1.05, 0.2)
	var short: bool = _fast_run_enabled
	var t: Dictionary = _boss_intro_timings(short)
	_clear_boss_intro_fx()
	var warn_lbl: Label = _ensure_boss_warning_label()
	warn_lbl.text = BOSS_INTRO_WARNING_TEXT
	warn_lbl.visible = true
	warn_lbl.modulate = Color(1.0, 1.0, 1.0, 0.0)
	warn_lbl.scale = Vector2(0.82, 0.82)
	UiTypography.apply_display(
		warn_lbl,
		UiTypography.SIZE_DISPLAY_TITLE,
		Color(1.0, 0.18, 0.14),
		UiTypography.OUTLINE_STRONG
	)
	_spawn_boss_debris_fall(short)
	_request_combat_shake(float(t.get("shake", 12.0)))
	_flash_battlefield(Color(1.0, 0.28, 0.22), float(t.get("flash", 0.22)))
	if _boss_intro_tween != null and is_instance_valid(_boss_intro_tween):
		_boss_intro_tween.kill()
	_boss_intro_tween = create_tween()
	_boss_intro_tween.tween_property(warn_lbl, "modulate:a", 1.0, 0.12)
	_boss_intro_tween.parallel().tween_property(warn_lbl, "scale", Vector2(1.06, 1.06), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_boss_intro_tween.tween_interval(float(t.get("warning", 0.4)))
	_boss_intro_tween.tween_property(warn_lbl, "modulate:a", 0.0, 0.14)
	_boss_intro_tween.tween_callback(func() -> void: _reveal_boss_sprite(float(t.get("reveal", 0.35))))
	_boss_intro_tween.tween_interval(float(t.get("hold", 0.3)))
	_boss_intro_tween.tween_callback(func() -> void: _finish_boss_combat_entrance(lead))

func _resolve_boss_sprite_path(enemy_id: String, dungeon_id: String) -> String:
	var tier: int = _DungeonTierConfig.clamp_tier(GameState.current_dungeon_tier)
	if tier > _DungeonTierConfig.TIER_NORMAL:
		if not enemy_id.is_empty():
			var by_enemy_tier: Variant = BOSS_ENEMY_SPRITE_MAP_BY_TIER.get(enemy_id, null)
			if by_enemy_tier is Dictionary:
				var tier_path: String = str((by_enemy_tier as Dictionary).get(tier, ""))
				if not tier_path.is_empty() and ResourceLoader.exists(tier_path):
					return tier_path
		if not dungeon_id.is_empty():
			var by_dg_tier: Variant = BOSS_SPRITE_MAP_BY_TIER.get(dungeon_id, null)
			if by_dg_tier is Dictionary:
				var dg_tier_path: String = str((by_dg_tier as Dictionary).get(tier, ""))
				if not dg_tier_path.is_empty() and ResourceLoader.exists(dg_tier_path):
					return dg_tier_path
	if not enemy_id.is_empty():
		var by_enemy: String = BOSS_ENEMY_SPRITE_MAP.get(enemy_id, "")
		if not by_enemy.is_empty() and ResourceLoader.exists(by_enemy):
			return by_enemy
		var enm_path: String = _enemy_sprite_path(enemy_id)
		if not enm_path.is_empty() and ResourceLoader.exists(enm_path):
			return enm_path
	if not dungeon_id.is_empty():
		var by_dungeon: String = BOSS_SPRITE_MAP.get(dungeon_id, "")
		if not by_dungeon.is_empty() and ResourceLoader.exists(by_dungeon):
			return by_dungeon
	return ""

func _load_boss_sprite(enemy_id: String) -> bool:
	var dungeon_id: String = ""
	if $DungeonController.current_dungeon_data != null:
		dungeon_id = $DungeonController.current_dungeon_data.id
	var path: String = _resolve_boss_sprite_path(enemy_id, dungeon_id)
	if path.is_empty():
		return false
	var frames: SpriteFrames = load(path) as SpriteFrames
	if frames == null or not frames.has_animation("idle"):
		return false
	for spr: AnimatedSprite2D in _swarm_sprites:
		spr.visible = false
	_enemy_sprite.visible = false
	_boss_sprite.sprite_frames = frames
	_apply_boss_sprite_transform()
	_boss_sprite.play("idle")
	_boss_sprite.z_index = 14
	return true

func _prepare_boss_sprite_for_entrance(enemy_id: String) -> bool:
	if not _load_boss_sprite(enemy_id):
		return false
	_boss_intro_base_scale = _boss_sprite.scale
	_boss_sprite.scale = _boss_intro_base_scale * 0.28
	_boss_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_boss_sprite.visible = true
	return true

func _show_boss_sprite(enemy_id: String) -> void:
	if not _load_boss_sprite(enemy_id):
		_boss_sprite.visible = false
		return
	_boss_sprite.modulate = Color.WHITE
	_boss_sprite.visible = true

func _update_boss_sprite_visibility() -> void:
	var is_boss_room: bool = $DungeonController.current_room_type == Enums.RoomType.BOSS
	if not is_boss_room:
		_boss_sprite.visible = false
		return
	var enemy_id: String = ""
	if $CombatController.is_in_combat and $CombatController.current_enemy_data != null:
		enemy_id = str($CombatController.current_enemy_data.id)
	if enemy_id.is_empty():
		var boss_data: Resource = $DungeonController.pick_boss_enemy_data()
		if boss_data != null:
			enemy_id = str(boss_data.id)
	if enemy_id.is_empty():
		_boss_sprite.visible = false
		return
	_show_boss_sprite(enemy_id)

func _apply_boss_sprite_transform() -> void:
	if _boss_sprite.sprite_frames != null:
		_normalize_boss_scale(_boss_sprite, _boss_sprite.sprite_frames)
	else:
		_boss_sprite.scale = Vector2(3.0, 3.0)
	_boss_sprite.centered = true
	_boss_sprite.offset = Vector2.ZERO
	_boss_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_boss_sprite.position = _battlefield_combat_position(BOSS_POSITION_RATIO)
	_boss_sprite.z_index = 14

func _normalize_boss_scale(sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	var tex: Texture2D = frames.get_frame_texture("idle", 0)
	if tex == null:
		return
	var frame_w: float = tex.get_width()
	var frame_h: float = tex.get_height()
	if frame_h <= 0.0:
		return
	var body_w: float = frame_w
	var body_h: float = frame_h
	var body_cx: float = frame_w / 2.0
	var body_bottom: float = frame_h
	var img: Image = tex.get_image()
	if img != null:
		var used: Rect2i = img.get_used_rect()
		if used.size.y > 0:
			body_w = float(used.size.x)
			body_h = float(used.size.y)
			body_cx = float(used.position.x) + body_w * 0.5
			body_bottom = float(used.position.y + used.size.y)
	var body_max: float = maxf(body_w, body_h)
	var s: float = clampf(BOSS_BODY_TARGET_PX / body_max, 0.05, 20.0)
	sprite.scale = Vector2(s, s)
	sprite.centered = true
	sprite.offset = Vector2(frame_w / 2.0 - body_cx, frame_h / 2.0 - body_bottom)

func _play_boss_animation(anim: String) -> void:
	if not _boss_sprite.visible:
		return
	if _boss_sprite.sprite_frames != null and _boss_sprite.sprite_frames.has_animation(anim):
		_boss_sprite.play(anim)

# ---- Room Art ----

func _dungeon_env_obj_path(dungeon_id: String, room_type: int) -> String:
	var fallback_id: String = Constants.MOURNGATE_DUNGEON_ID
	if room_type == Enums.RoomType.TREASURE:
		return TREASURE_CLOSED_OBJ_MAP.get(dungeon_id, TREASURE_CLOSED_OBJ_MAP[fallback_id])
	if room_type == Enums.RoomType.EXIT:
		return EXIT_OBJ_MAP.get(dungeon_id, EXIT_OBJ_MAP[fallback_id])
	return ""

func _dungeon_battle_bg_path(dungeon_id: String) -> String:
	var fallback_id: String = Constants.MOURNGATE_DUNGEON_ID
	return BATTLE_BG_MAP.get(dungeon_id, BATTLE_BG_MAP[fallback_id])

func _phase_bg_setup_path(room_type: int) -> String:
	match room_type:
		Enums.RoomType.HEAL:
			return HealRoomPresentationScript.bg_path_for_phase("setup")
		Enums.RoomType.TREASURE:
			return TreasureRoomPresentationScript.bg_path_for_phase("setup")
		Enums.RoomType.EVENT:
			return LoreRoomPresentationScript.bg_path_for_phase("setup")
		Enums.RoomType.TRAP:
			return TrapPresentationScript.bg_path_for_phase("setup")
		_:
			return ""

func _uses_phase_bg(room_type: int) -> bool:
	return room_type in _PHASE_BG_ROOM_TYPES

func _set_non_combat_phase_bg(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		_room_tile_bg.visible = false
		_room_tile_bg.texture = null
		return
	_set_room_texture_covered(_room_tile_bg, path)
	if _room_object != null:
		_room_object.visible = false

func _update_room_art() -> void:
	var room_type: int = $DungeonController.current_room_type
	var dungeon_id: String = ""
	if $DungeonController.current_dungeon_data != null:
		dungeon_id = $DungeonController.current_dungeon_data.id
	var fallback_id: String = Constants.MOURNGATE_DUNGEON_ID
	var battle_bg_path: String = _dungeon_battle_bg_path(dungeon_id)
	_set_room_texture(_bg_texture, battle_bg_path)
	if _uses_phase_bg(room_type):
		_set_non_combat_phase_bg(_phase_bg_setup_path(room_type))
	elif room_type in _FLOOR_ROOM_TYPES:
		var floor_path: String = FLOOR_TILE_MAP.get(dungeon_id, FLOOR_TILE_MAP[fallback_id])
		if floor_path.is_empty() or not ResourceLoader.exists(floor_path):
			_room_tile_bg.visible = false
			_room_tile_bg.texture = null
		else:
			_set_room_texture_tiled(_room_tile_bg, floor_path)
	else:
		_room_tile_bg.visible = false
		_room_tile_bg.texture = null
	var obj_path: String = ""
	if not _uses_phase_bg(room_type) and room_type != Enums.RoomType.EXIT:
		obj_path = _dungeon_env_obj_path(dungeon_id, room_type)
	_apply_room_object_layout(room_type)
	_set_room_texture(_room_object, obj_path)

func _apply_room_object_layout(room_type: int) -> void:
	var half: float = TREASURE_OBJ_DISPLAY_PX * 0.5 if room_type == Enums.RoomType.TREASURE else ROOM_OBJ_DISPLAY_PX * 0.5
	_room_object.offset_left = -half
	_room_object.offset_top = -half
	_room_object.offset_right = half
	_room_object.offset_bottom = half

func _set_room_texture_tiled(node: TextureRect, path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		node.texture = null
		node.visible = false
		return
	node.texture = load(path) as Texture2D
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	node.stretch_mode = TextureRect.STRETCH_TILE
	node.visible = true

func _set_room_texture(node: TextureRect, path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		node.texture = null
		node.visible = false
		return
	node.texture = load(path) as Texture2D
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.visible = true

func _set_room_texture_covered(node: TextureRect, path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		node.texture = null
		node.visible = false
		return
	node.texture = load(path) as Texture2D
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	node.visible = true
