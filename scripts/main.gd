extends Control

class SlotView:
	extends PanelContainer

	var main: Control
	var slot_index := -1

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if main == null or not main.can_start_slot_drag(slot_index):
			return null

		var tile_type: String = main.tile_type_at(slot_index)
		var preview: Control = main.make_drag_preview(tile_type)
		set_drag_preview(preview)
		return {
			"kind": "placed",
			"type": tile_type,
			"from_slot": slot_index
		}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return main != null and main.can_drop_on_slot(slot_index, data)

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if main != null:
			main.drop_on_slot(slot_index, data)


class TileView:
	extends PanelContainer

	var main: Control
	var tile_type := ""
	var slot_index := -1
	var from_palette := false

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if main == null or not main.can_start_tile_drag(from_palette):
			return null

		var preview: Control = main.make_drag_preview(tile_type)
		set_drag_preview(preview)

		return {
			"kind": "palette" if from_palette else "placed",
			"type": tile_type,
			"from_slot": slot_index
		}


class DeleteDrop:
	extends PanelContainer

	var main: Control

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return main != null and main.can_drop_on_delete(data)

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if main != null:
			main.drop_on_delete(data)


const GameStateScript = preload("res://scripts/game_state.gd")

const GRID_COLUMNS := 4
const GRID_ROWS := 5
const TOTAL_SLOTS := GRID_COLUMNS * GRID_ROWS
const MAX_TILE_CLICKS := 4
const MAX_MANUAL_CLICKS := 8
const HAND_SIZE := 6
const MAX_LOCKED_HAND := 2
const REROLL_COST := 3
const REMOVE_COST_BASE := 4
const STARTING_COINS := 18
const STARTING_HEALTH := 40
const MAX_HEALTH := 46
const STARTING_QUOTA := 1
const ROUND_QUOTAS := [1, 2, 3, 4, 6, 8, 11, 14, 16, 20, 25, 31, 38, 46, 55, 65, 77, 91, 107, 126, 148, 173, 202, 236]
const FLASH_SECONDS := 1.0
const TRIGGER_CHANCE := 0.5
const FINAL_ROUND := 24
const SAVE_PATH := "user://fate_coins_save.json"
const SETTINGS_PATH := "user://fate_coins_settings.json"
const META_PATH := "user://fate_coins_meta.json"

const TILE_TEXTURES := {
	"normal": preload("res://textures/tiles/tile_normal.png"),
	"left": preload("res://textures/tiles/tile_left.png"),
	"right": preload("res://textures/tiles/tile_right.png"),
	"up": preload("res://textures/tiles/tile_up.png"),
	"down": preload("res://textures/tiles/tile_down.png"),
	"star": preload("res://textures/tiles/tile_star.png"),
	"bank": preload("res://textures/tiles/tile_bank.png"),
	"cross": preload("res://textures/tiles/tile_cross.png"),
	"surge": preload("res://textures/tiles/tile_surge.png"),
	"lucky": preload("res://textures/coins/coin_lucky.png"),
	"reverse": preload("res://textures/coins/coin_reverse.png"),
	"glass": preload("res://textures/coins/coin_glass.png"),
	"stock": preload("res://textures/coins/coin_stock.png"),
	"vampire": preload("res://textures/coins/coin_vampire.png"),
	"spirit": preload("res://textures/coins/coin_spirit.png"),
	"angel": preload("res://textures/coins/coin_angel.png"),
	"demon": preload("res://textures/coins/coin_demon.png"),
	"mirror": preload("res://textures/coins/coin_mirror.png"),
	"magnet": preload("res://textures/coins/coin_magnet.png"),
	"echo": preload("res://textures/coins/coin_echo.png"),
	"shield": preload("res://textures/coins/coin_shield.png"),
	"forge": preload("res://textures/coins/coin_forge.png"),
	"compass": preload("res://textures/coins/coin_compass.png"),
	"debt_coin": preload("res://textures/coins/coin_debt.png"),
	"arc": preload("res://textures/coins/coin_arc.png"),
	"bloom": preload("res://textures/coins/coin_bloom.png"),
	"titan": preload("res://textures/coins/coin_titan.png"),
	"hourglass": preload("res://textures/coins/coin_hourglass.png"),
	"joker": preload("res://textures/coins/coin_joker.png"),
	"anchor": preload("res://textures/coins/coin_anchor.png")
}

const UI_TEXTURE_PATHS := {
	"enemy": "res://textures/ui/icon_enemy.png",
	"boss": "res://textures/ui/icon_boss.png",
	"relic": "res://textures/ui/icon_relic.png",
	"consumable": "res://textures/ui/icon_consumable.png",
	"curse": "res://textures/ui/icon_curse.png"
}
const ENEMY_TEXTURE_DIR := "res://textures/enemies"
const RELIC_TEXTURE_DIR := "res://textures/relics"
const CONSUMABLE_TEXTURE_DIR := "res://textures/consumables"
const CURSE_TEXTURE_DIR := "res://textures/curses"
const EVENT_TEXTURE_DIR := "res://textures/events"

const SFX_PATHS := {
	"coin": "res://audio/coin.wav",
	"miss": "res://audio/miss.wav",
	"buy": "res://audio/buy.wav",
	"upgrade": "res://audio/upgrade.wav",
	"chain": "res://audio/chain.wav",
	"settle": "res://audio/settle.wav",
	"error": "res://audio/error.wav"
}

const TILE_TYPES := {
	"normal": {"name": "Normal", "symbol": "N", "cost": 1, "directions": [], "rarity": "common", "coin_value": 1, "trigger_chance": 0.50, "tip": "点击后只结算自己，不触发周围方块。花费 1 金币。"},
	"left": {"name": "Left", "symbol": "<", "cost": 3, "directions": [Vector2i.LEFT], "rarity": "common", "coin_value": 2, "trigger_chance": 0.50, "tip": "点击后有 50% 概率触发左侧方块。花费 3 金币。"},
	"right": {"name": "Right", "symbol": ">", "cost": 3, "directions": [Vector2i.RIGHT], "rarity": "common", "coin_value": 2, "trigger_chance": 0.50, "tip": "点击后有 50% 概率触发右侧方块。花费 3 金币。"},
	"up": {"name": "Up", "symbol": "^", "cost": 3, "directions": [Vector2i.UP], "rarity": "common", "coin_value": 2, "trigger_chance": 0.50, "tip": "点击后有 50% 概率触发上方方块。花费 3 金币。"},
	"down": {"name": "Down", "symbol": "v", "cost": 3, "directions": [Vector2i.DOWN], "rarity": "common", "coin_value": 2, "trigger_chance": 0.50, "tip": "点击后有 50% 概率触发下方方块。花费 3 金币。"},
	"star": {"name": "Star", "symbol": "*", "cost": 6, "directions": [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN], "rarity": "uncommon", "coin_value": 2, "trigger_chance": 0.50, "tip": "点击后四个方向各自有 50% 概率触发。花费 6 金币。"},
	"bank": {"name": "Bank", "symbol": "$", "cost": 5, "directions": [], "rarity": "rare", "coin_value": 2, "trigger_chance": 0.50, "tip": "稀有方块。点击成功获得 2 金币，不触发周围。"},
	"cross": {"name": "Cross", "symbol": "+", "cost": 7, "directions": [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN], "rarity": "rare", "coin_value": 1, "trigger_chance": 0.62, "tip": "稀有方块。四个方向各自有 62% 概率触发。"},
	"surge": {"name": "Surge", "symbol": "!", "cost": 8, "directions": [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN], "rarity": "rare", "coin_value": 2, "trigger_chance": 0.42, "tip": "稀有方块。成功给 2 金币，并有较低概率触发四周。"},
	"lucky": {"name": "Lucky", "symbol": "L", "cost": 5, "directions": [Vector2i.RIGHT], "rarity": "uncommon", "coin_value": 1, "trigger_chance": 0.58, "tip": "正面：金币与伤害，并恢复 1 生命。反面：获得 1 次手动触发。"},
	"reverse": {"name": "Reverse", "symbol": "R", "cost": 5, "directions": [Vector2i.LEFT], "rarity": "uncommon", "coin_value": 2, "trigger_chance": 0.48, "tip": "反面才是大成功。正面小收益；反面获得更高金币与伤害。"},
	"glass": {"name": "Glass", "symbol": "G", "cost": 7, "directions": [], "rarity": "uncommon", "coin_value": 3, "trigger_chance": 0.50, "tip": "正面高收益高伤害；反面有破碎风险，可能摧毁自己并伤到玩家。"},
	"stock": {"name": "Stock", "symbol": "%", "cost": 8, "directions": [], "rarity": "rare", "coin_value": 2, "trigger_chance": 0.50, "tip": "正面：本枚股票涨价，后续收益提高。反面：下跌，但返还 1 金币。"},
	"vampire": {"name": "Vampire", "symbol": "V", "cost": 9, "directions": [Vector2i.UP, Vector2i.DOWN], "rarity": "rare", "coin_value": 1, "trigger_chance": 0.52, "tip": "正面：造成伤害并吸血。反面：扣 1 生命但造成额外伤害。"},
	"spirit": {"name": "Spirit", "symbol": "S", "cost": 9, "directions": [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN], "rarity": "rare", "coin_value": 1, "trigger_chance": 0.40, "tip": "正面：获得额外手动触发。反面：低收益但仍会尝试触发四周。"},
	"angel": {"name": "Angel", "symbol": "A", "cost": 10, "directions": [Vector2i.UP, Vector2i.RIGHT], "rarity": "rare", "coin_value": 1, "trigger_chance": 0.60, "tip": "正面：回血并净化自身干扰。反面：低收益，但净化周围硬币。"},
	"demon": {"name": "Demon", "symbol": "D", "cost": 11, "directions": [Vector2i.LEFT, Vector2i.RIGHT], "rarity": "rare", "coin_value": 3, "trigger_chance": 0.46, "tip": "触发会消耗生命。正面爆发金币和伤害；反面污染自己但仍造成伤害。"},
	"mirror": {"name": "Mirror", "symbol": "M", "cost": 10, "directions": [Vector2i.LEFT, Vector2i.RIGHT], "rarity": "rare", "coin_value": 1, "trigger_chance": 0.50, "tip": "正面：复制左右相邻硬币的少量收益。反面：获得 1 金币并尝试连锁两侧。"},
	"magnet": {"name": "Magnet", "symbol": "@", "cost": 8, "directions": [Vector2i.UP, Vector2i.DOWN], "rarity": "uncommon", "coin_value": 1, "trigger_chance": 0.55, "tip": "正面：按相邻硬币数量获得金币。反面：拉出一点伤害并提高连锁。"},
	"echo": {"name": "Echo", "symbol": "E", "cost": 9, "directions": [Vector2i.LEFT, Vector2i.RIGHT], "rarity": "rare", "coin_value": 1, "trigger_chance": 0.50, "tip": "正面：按本回合已触发历史获得额外收益。反面：获得额外手动触发，适合长连锁。"},
	"shield": {"name": "Shield", "symbol": "#", "cost": 7, "directions": [Vector2i.UP], "rarity": "uncommon", "coin_value": 1, "trigger_chance": 0.62, "tip": "正面：获得金币并恢复生命。反面：净化自身，减少敌人干扰。"},
	"forge": {"name": "Forge", "symbol": "F", "cost": 10, "directions": [Vector2i.DOWN], "rarity": "rare", "coin_value": 1, "trigger_chance": 0.48, "tip": "正面：本枚硬币升温，后续收益提高。反面：降温但返还金币，适合成长流。"},
	"compass": {"name": "Compass", "symbol": "C", "cost": 8, "directions": [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN], "rarity": "uncommon", "coin_value": 1, "trigger_chance": 0.57, "tip": "正面：按相邻空位获得金币，并提高连锁。反面：低收益但四向导航。"},
	"debt_coin": {"name": "Debt", "symbol": "?", "cost": 6, "directions": [], "rarity": "uncommon", "coin_value": 2, "trigger_chance": 0.50, "tip": "正面：立即获得金币。反面：获得金币但增加本局债务压力。"},
	"arc": {"name": "Arc", "symbol": ")", "cost": 8, "directions": [Vector2i.RIGHT, Vector2i.DOWN], "rarity": "uncommon", "coin_value": 1, "trigger_chance": 0.56, "tip": "正面：触发右侧和下方，按连锁深度提高收益。反面：低收益但保留连锁。"},
	"bloom": {"name": "Bloom", "symbol": "&", "cost": 9, "directions": [Vector2i.UP, Vector2i.LEFT], "rarity": "rare", "coin_value": 1, "trigger_chance": 0.58, "tip": "正面：治疗并成长花层。反面：消耗花层换金币，适合生命成长流。"},
	"titan": {"name": "Titan", "symbol": "T", "cost": 12, "directions": [], "rarity": "rare", "coin_value": 4, "trigger_chance": 0.38, "tip": "正面：重型金币和伤害爆发。反面：自我锁定但仍造成少量伤害。"},
	"hourglass": {"name": "Hourglass", "symbol": "H", "cost": 10, "directions": [Vector2i.UP, Vector2i.DOWN], "rarity": "rare", "coin_value": 1, "trigger_chance": 0.52, "tip": "正面：获得额外手动触发并延长自身次数。反面：回收一次触发换金币。"},
	"joker": {"name": "Joker", "symbol": "J", "cost": 9, "directions": [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN], "rarity": "rare", "coin_value": 1, "trigger_chance": 0.50, "tip": "正面和反面都会成功，但收益随机波动，适合赌博流。"},
	"anchor": {"name": "Anchor", "symbol": "O", "cost": 8, "directions": [Vector2i.DOWN], "rarity": "uncommon", "coin_value": 1, "trigger_chance": 0.60, "tip": "正面：护住自己并降低敌人干扰。反面：锁住自己但恢复生命。"}
}

const TILE_ORDER := ["normal", "left", "right", "up", "down", "star", "lucky", "reverse", "glass", "magnet", "shield", "compass", "debt_coin", "arc", "anchor", "bank", "cross", "surge", "stock", "vampire", "spirit", "angel", "demon", "mirror", "echo", "forge", "bloom", "titan", "hourglass", "joker"]
const COMMON_SHOP_TYPES := ["normal", "left", "right", "up", "down", "star", "lucky", "reverse", "magnet", "shield", "compass", "debt_coin", "arc", "anchor"]
const RARE_SHOP_TYPES := ["bank", "cross", "surge", "glass", "stock", "vampire", "spirit", "angel", "demon", "mirror", "echo", "forge", "bloom", "titan", "hourglass", "joker"]
const MAX_TILE_LEVEL := 3
const WAGER_MODES := {
	"safe": {"name": "保守", "coin_mult": 0.80, "damage_mult": 0.80, "fail_damage": 0, "enemy_bonus": 0, "tip": "收益降低，但失败没有反噬。"},
	"standard": {"name": "标准", "coin_mult": 1.00, "damage_mult": 1.00, "fail_damage": 0, "enemy_bonus": 0, "tip": "正常收益与风险。"},
	"greedy": {"name": "贪婪", "coin_mult": 1.55, "damage_mult": 1.25, "fail_damage": 1, "enemy_bonus": 1, "tip": "收益更高，手动失败会受伤，敌人攻击更凶。"},
	"all_in": {"name": "梭哈", "coin_mult": 2.35, "damage_mult": 1.75, "fail_damage": 2, "enemy_bonus": 2, "tip": "爆发极高，但每次手动失败都会痛。"}
}
const WAGER_ORDER := ["safe", "standard", "greedy", "all_in"]
const ENEMY_TYPES := {
	"thief": {"name": "小偷鼠", "hp": 10, "attack": 2, "steal": 3, "reward": 5, "intent": "偷金币并轻咬。"},
	"guard": {"name": "盾牌鼠", "hp": 16, "attack": 3, "shield": 2, "reward": 7, "intent": "用护盾吃掉小额伤害。"},
	"sniper": {"name": "远程鼠", "hp": 8, "attack": 5, "reward": 6, "intent": "远程攻击，血少但很疼。"},
	"debt": {"name": "债主", "hp": 22, "attack": 4, "steal": 5, "reward": 12, "intent": "偷钱，惩罚贪婪下注。"},
	"taxer": {"name": "税吏鼠", "hp": 18, "attack": 2, "steal": 7, "reward": 10, "intent": "偷取大量金币，逼迫玩家清经济压力。"},
	"devourer": {"name": "吞币怪", "hp": 24, "attack": 4, "reward": 14, "intent": "污染高等级硬币，拖慢核心构筑。"},
	"hexer": {"name": "诅咒师", "hp": 14, "attack": 3, "reward": 11, "intent": "同时干扰和污染硬币。"},
	"saboteur": {"name": "拆线工", "hp": 17, "attack": 3, "reward": 11, "intent": "专门干扰方向硬币，切断连锁。"},
	"healer": {"name": "补锅匠", "hp": 20, "attack": 2, "reward": 13, "intent": "修补敌人，让拖延战变危险。"},
	"gambler_rat": {"name": "赌徒鼠", "hp": 19, "attack": 3, "steal": 2, "reward": 13, "intent": "下注越激进，它越兴奋。"},
	"frost": {"name": "霜印使", "hp": 21, "attack": 4, "reward": 15, "intent": "冻结一列硬币，逼你改路线。"},
	"mimic": {"name": "仿币怪", "hp": 26, "attack": 4, "shield": 3, "reward": 16, "intent": "模仿你的核心收益，越拖越硬。"},
	"timekeeper": {"name": "时钟稽查员", "hp": 23, "attack": 3, "reward": 15, "intent": "追查剩余次数最多的硬币，拖慢长回合引擎。"},
	"lock_boss": {"name": "铁锁典狱长", "hp": 42, "attack": 6, "shield": 5, "reward": 24, "intent": "第 8 回合 Boss，锁住核心硬币。"},
	"market_boss": {"name": "泡沫经纪人", "hp": 48, "attack": 6, "steal": 6, "reward": 30, "intent": "第 12 回合 Boss，压低收益并抬高商店压力。"},
	"debt_boss": {"name": "高利贷伯爵", "hp": 58, "attack": 7, "steal": 8, "reward": 34, "intent": "第 16 回合 Boss，用污染和偷钱压垮经济。"},
	"mirror_boss": {"name": "镜厅裁判", "hp": 66, "attack": 8, "shield": 6, "reward": 38, "intent": "第 20 回合 Boss，复制你的核心路线并锁定两侧。"},
	"banker": {"name": "命运庄家", "hp": 55, "attack": 7, "shield": 4, "reward": 40, "intent": "最终 Boss，会检验整套硬币机器。"}
}
const STARTER_BAGS := {
	"balanced": {"name": "稳健", "coins": ["normal", "normal", "normal", "left", "right", "up", "down", "lucky", "reverse", "glass"], "tip": "均衡入口，能体验方向、幸运、反面和玻璃。"},
	"chain": {"name": "连锁", "coins": ["normal", "normal", "left", "right", "up", "down", "star", "lucky", "spirit", "compass"], "tip": "更容易打出连锁，适合机关流。"},
	"gambler": {"name": "赌博", "coins": ["normal", "normal", "reverse", "reverse", "glass", "glass", "lucky", "surge", "stock", "down"], "tip": "波动更高，适合贪婪和梭哈。"},
	"blood": {"name": "鲜血", "coins": ["normal", "normal", "vampire", "demon", "lucky", "reverse", "up", "down", "glass", "spirit"], "tip": "用生命换伤害，再靠吸血和幸运续航。"}
}
const STARTER_BAG_ORDER := ["balanced", "chain", "gambler", "blood"]
const RELICS := {
	"golden_glove": {"name": "黄金手套", "cost": 18, "rarity": "common", "tip": "每次正面额外 +1 金币。"},
	"chain_bell": {"name": "连锁铃", "cost": 22, "rarity": "uncommon", "tip": "所有方向连锁概率 +10%。"},
	"red_heart": {"name": "红心护符", "cost": 20, "rarity": "common", "tip": "每回合第一次自伤会减免 1 点。"},
	"tax_receipt": {"name": "免税票据", "cost": 24, "rarity": "uncommon", "tip": "回合收取费用 -2，最低为 0。"},
	"loaded_die": {"name": "灌铅骰", "cost": 26, "rarity": "rare", "tip": "贪婪和梭哈下注时正面概率 +8%。"},
	"war_banner": {"name": "战旗", "cost": 21, "rarity": "uncommon", "tip": "所有正面额外 +1 伤害。"},
	"merchant_seal": {"name": "商会印章", "cost": 23, "rarity": "uncommon", "tip": "购买硬币便宜 1 金币，最低为 1。"},
	"deep_pockets": {"name": "深口袋", "cost": 28, "rarity": "rare", "tip": "每回合多抽 1 枚手牌。"},
	"silver_lens": {"name": "银透镜", "cost": 24, "rarity": "uncommon", "tip": "所有硬币正面概率 +4%。"},
	"steady_anvil": {"name": "稳固铁砧", "cost": 19, "rarity": "common", "tip": "升级硬币便宜 2 金币，最低为 1。"},
	"void_purse": {"name": "虚空钱袋", "cost": 21, "rarity": "uncommon", "tip": "移除命运袋硬币便宜 3 金币，最低为 1。"},
	"shield_charm": {"name": "盾纹护符", "cost": 25, "rarity": "uncommon", "tip": "每个敌人回合总伤害降低 2，最低为 0。"},
	"blood_cup": {"name": "血杯", "cost": 27, "rarity": "rare", "tip": "Vampire 和 Demon 额外 +2 伤害。"},
	"glass_hammer": {"name": "玻璃锤", "cost": 23, "rarity": "rare", "tip": "Glass 正面额外 +2 金币和 +2 伤害。"},
	"oracle_deck": {"name": "预言牌组", "cost": 26, "rarity": "rare", "tip": "回合事件带来的手动次数和收取减免各额外 +1。"},
	"echo_chamber": {"name": "回声厅", "cost": 25, "rarity": "rare", "tip": "Echo 与 Hourglass 正面概率 +8%，并提高连锁稳定性。"},
	"bloom_crown": {"name": "花冠", "cost": 24, "rarity": "uncommon", "tip": "所有治疗效果额外 +1；Bloom 与 Angel 更稳定。"},
	"titan_gauntlet": {"name": "巨神臂甲", "cost": 29, "rarity": "rare", "tip": "Titan 正面概率 +6%，Titan 额外 +3 伤害。"},
	"debt_ledger": {"name": "债务账本", "cost": 22, "rarity": "uncommon", "tip": "Debt 正面概率 +4%，棋盘债务标记造成的收取压力减半。"},
	"cartographer_map": {"name": "制图师地图", "cost": 23, "rarity": "uncommon", "tip": "Compass 与 Arc 正面概率 +8%。"},
	"joker_mask": {"name": "小丑面具", "cost": 25, "rarity": "rare", "tip": "Joker 正面概率 +5%，随机收益上限提高。"},
	"anchor_chain": {"name": "锚链", "cost": 21, "rarity": "uncommon", "tip": "Anchor 与 Shield 更稳定，并让它们额外 +1 伤害。"},
	"bounty_contract": {"name": "赏金契约", "cost": 27, "rarity": "rare", "tip": "击杀敌人获得的赏金提高 25%。"},
	"furnace_core": {"name": "炉心", "cost": 26, "rarity": "rare", "tip": "Forge 正面概率 +6%，热度上限提高并额外 +1 伤害。"},
	"pocket_watch": {"name": "怀表", "cost": 24, "rarity": "uncommon", "tip": "Hourglass 和 Echo 每回合可多触发 1 次。"}
}
const RELIC_ORDER := ["golden_glove", "chain_bell", "red_heart", "tax_receipt", "loaded_die", "war_banner", "merchant_seal", "deep_pockets", "silver_lens", "steady_anvil", "void_purse", "shield_charm", "blood_cup", "glass_hammer", "oracle_deck", "echo_chamber", "bloom_crown", "titan_gauntlet", "debt_ledger", "cartographer_map", "joker_mask", "anchor_chain", "bounty_contract", "furnace_core", "pocket_watch"]
const CONSUMABLES := {
	"heal_potion": {"name": "生命药水", "cost": 7, "tip": "立即恢复 6 点生命。"},
	"smoke_bomb": {"name": "烟雾弹", "cost": 9, "tip": "清除棋盘上所有锁、扰、污、偷状态。"},
	"lucky_ticket": {"name": "幸运券", "cost": 8, "tip": "本回合获得 2 次额外手动触发。"},
	"market_tip": {"name": "内幕消息", "cost": 10, "tip": "让所有已上阵股票硬币涨 2 层。"},
	"repair_kit": {"name": "修复包", "cost": 8, "tip": "修复所有破碎玻璃硬币。"}
}
const CONSUMABLE_ORDER := ["heal_potion", "smoke_bomb", "lucky_ticket", "market_tip", "repair_kit"]
const CURSE_DEALS := {
	"blood_money": {"name": "血钱契约", "reward": 18, "tip": "立即获得 18 金币，但失去 4 生命。"},
	"heavy_debt": {"name": "高息债务", "reward": 28, "tip": "立即获得 28 金币，但之后每回合收取 +3。"},
	"thin_bag": {"name": "薄命袋", "reward": 16, "tip": "立即获得 16 金币，但每回合少抽 1 枚手牌。"},
	"cursed_coin": {"name": "诅咒硬币", "reward": 22, "tip": "立即获得 22 金币，但命运袋加入 2 枚 Demon。"}
}
const CURSE_ORDER := ["blood_money", "heavy_debt", "thin_bag", "cursed_coin"]
const ROUND_EVENTS := [
	{"name": "黄金潮汐", "desc": "本回合所有成功点击额外 +1 金币。", "coin_bonus": 1, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 0},
	{"name": "连锁顺风", "desc": "所有方向触发概率 +15%。", "coin_bonus": 0, "trigger_bonus": 0.15, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 0},
	{"name": "长线布局", "desc": "本回合手动点击次数 +2。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 2, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 0},
	{"name": "税务宽免", "desc": "结束回合时少收 2 金币，最低收 0。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 2, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 0},
	{"name": "耐久强化", "desc": "每个硬币本回合最大触发次数 +1。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 1, "enemy_attack_delta": 0, "shop_discount": 0},
	{"name": "黑市折扣", "desc": "本回合商店硬币价格 -1。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 1},
	{"name": "低压战线", "desc": "敌人本回合攻击 -1。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": -1, "shop_discount": 0},
	{"name": "高压战线", "desc": "敌人本回合攻击 +1，但成功收益 +1 金币。", "coin_bonus": 1, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 1, "shop_discount": 0},
	{"name": "命运回响", "desc": "本回合手动次数 +1，方向触发概率 +8%。", "coin_bonus": 0, "trigger_bonus": 0.08, "manual_bonus": 1, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 0},
	{"name": "债务喘息", "desc": "结束回合时少收 1 金币，敌人攻击 -1。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 1, "click_bonus": 0, "enemy_attack_delta": -1, "shop_discount": 0},
	{"name": "狂热集市", "desc": "商店硬币价格 -1，但敌人攻击 +1。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 1, "shop_discount": 1},
	{"name": "硬币雨", "desc": "成功额外 +2 金币，但方向触发概率 -8%。", "coin_bonus": 2, "trigger_bonus": -0.08, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 0},
	{"name": "脆弱火花", "desc": "每个硬币可多触发 1 次，但敌人攻击 +1。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 1, "enemy_attack_delta": 1, "shop_discount": 0},
	{"name": "稳态时钟", "desc": "手动次数 +1，结束回合少收 1 金币。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 1, "quota_discount": 1, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 0},
	{"name": "逆风翻面", "desc": "方向触发概率 -10%，但每次成功额外 +1 金币。", "coin_bonus": 1, "trigger_bonus": -0.10, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 0},
	{"name": "静默铸币", "desc": "成功额外 +1 金币，敌人攻击 -1，但没有额外连锁。", "coin_bonus": 1, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": -1, "shop_discount": 0},
	{"name": "熔炉日", "desc": "每个硬币可多触发 1 次，商店硬币价格 -1。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 1, "enemy_attack_delta": 0, "shop_discount": 1},
	{"name": "镜面集市", "desc": "商店硬币价格 -2，但结束回合收取 +1。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": -1, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 2},
	{"name": "债雨", "desc": "成功额外 +2 金币，但结束回合收取 +2。", "coin_bonus": 2, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": -2, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 0},
	{"name": "破晓休整", "desc": "敌人攻击 -2，结束回合少收 1 金币。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 1, "click_bonus": 0, "enemy_attack_delta": -2, "shop_discount": 0},
	{"name": "猎杀悬赏", "desc": "方向触发概率 +6%，敌人攻击 +1。", "coin_bonus": 0, "trigger_bonus": 0.06, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 1, "shop_discount": 0},
	{"name": "钟摆回合", "desc": "手动次数 +2，但每个硬币少 1 次可触发次数。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 2, "quota_discount": 0, "click_bonus": -1, "enemy_attack_delta": 0, "shop_discount": 0},
	{"name": "锚定防线", "desc": "敌人攻击 -1，每个硬币可多触发 1 次。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 1, "enemy_attack_delta": -1, "shop_discount": 0},
	{"name": "小丑庆典", "desc": "手动次数 +1，成功额外 +1 金币，但敌人攻击 +1。", "coin_bonus": 1, "trigger_bonus": 0.0, "manual_bonus": 1, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 1, "shop_discount": 0},
	{"name": "花园低语", "desc": "方向触发概率 +5%，结束回合少收 1 金币。", "coin_bonus": 0, "trigger_bonus": 0.05, "manual_bonus": 0, "quota_discount": 1, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 0},
	{"name": "巨神阴影", "desc": "成功额外 +2 金币，敌人攻击 +2。", "coin_bonus": 2, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 2, "shop_discount": 0},
	{"name": "制图远征", "desc": "方向触发概率 +12%，商店硬币价格 -1。", "coin_bonus": 0, "trigger_bonus": 0.12, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 1},
	{"name": "税务突查", "desc": "结束回合收取 +3，但敌人攻击 -1。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 0, "quota_discount": -3, "click_bonus": 0, "enemy_attack_delta": -1, "shop_discount": 0},
	{"name": "空袋补给", "desc": "商店硬币价格 -1，手动次数 +1。", "coin_bonus": 0, "trigger_bonus": 0.0, "manual_bonus": 1, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 0, "shop_discount": 1},
	{"name": "命运暴走", "desc": "方向触发概率 +18%，但敌人攻击 +2。", "coin_bonus": 0, "trigger_bonus": 0.18, "manual_bonus": 0, "quota_discount": 0, "click_bonus": 0, "enemy_attack_delta": 2, "shop_discount": 0}
]
const DIFFICULTIES := {
	"normal": {"name": "普通", "start_coins": 24, "enemy_mult": 0.76, "quota_mult": 0.76, "tip": "标准挑战，适合首次通关。"},
	"hard": {"name": "困难", "start_coins": 14, "enemy_mult": 1.15, "quota_mult": 1.15, "tip": "敌人更硬，收取更高。达到第 8 回合后解锁。"},
	"fate": {"name": "命运", "start_coins": 10, "enemy_mult": 1.40, "quota_mult": 1.30, "tip": "完整高压挑战。通关后解锁。"}
}
const DIFFICULTY_ORDER := ["normal", "hard", "fate"]
const BG_COLOR := Color(0.018, 0.026, 0.034)
const PANEL_COLOR := Color(0.060, 0.082, 0.088, 0.98)
const PANEL_LIGHT := Color(0.100, 0.135, 0.140)
const SLOT_COLOR := Color(0.050, 0.115, 0.112)
const GOLD := Color(1.00, 0.675, 0.255)
const CREAM := Color(0.88, 0.94, 0.88)
const GREEN := Color(0.33, 0.88, 0.65)
const COIN_FLASH := Color(1.00, 0.36, 0.28)
const BLUE := Color(0.23, 0.75, 0.88)
const INK := Color(0.025, 0.040, 0.048)
const DEEP_PANEL := Color(0.043, 0.060, 0.066)
const MINT := Color(0.40, 0.95, 0.78)
const COPPER := Color(0.86, 0.42, 0.22)
const DANGER := Color(0.96, 0.22, 0.32)
const VIOLET := Color(0.64, 0.45, 1.0)

var game_state: Node
var rng := RandomNumberGenerator.new()
var is_intermission := true
var manual_clicks_left := MAX_MANUAL_CLICKS
var player_health := STARTING_HEALTH
var wager_mode := "standard"
var round_collected := 0
var round_damage := 0
var round_failures := 0
var run_total_collected := 0
var run_total_damage := 0
var run_kills := 0
var run_best_chain := 0
var tutorial_enabled := true
var sfx_volume_db := -8.0
var fullscreen_enabled := false
var difficulty_id := "normal"
var meta_progress := {"best_round": 1, "victories": 0, "unlocked_difficulties": ["normal"]}
var quota := STARTING_QUOTA
var current_event: Dictionary = {}
var enemies: Array[Dictionary] = []
var starter_bag_id := "balanced"
var coin_bag: Array[String] = []
var hand_tiles: Array[String] = []
var locked_hand_tiles: Array[String] = []
var removed_from_bag := 0
var shop_offer_types: Array[String] = []
var relic_offer_ids: Array[String] = []
var consumable_offer_ids: Array[String] = []
var curse_offer_ids: Array[String] = []
var owned_relics: Array[String] = []
var active_curses: Array[String] = []
var round_self_damage_blocked := false
var best_chain_this_round := 0
var last_round_summary: Dictionary = {}
var board_tiles: Array[Dictionary] = []
var slot_views: Array[Dictionary] = []
var palette_views: Dictionary = {}
var ui_texture_cache: Dictionary = {}
var palette_container: GridContainer
var shop_container: VBoxContainer
var relic_container: VBoxContainer
var consumable_container: VBoxContainer
var curse_container: VBoxContainer
var bag_container: VBoxContainer
var enemy_panel_container: HBoxContainer
var sfx_players: Dictionary = {}

var coin_label: Label
var health_label: Label
var round_label: Label
var quota_label: Label
var clicks_label: Label
var enemy_label: Label
var state_label: Label
var notice_label: Label
var progress_label: Label
var event_icon_rect: TextureRect
var combat_feed_label: Label
var tutorial_panel: PanelContainer
var tutorial_label: Label
var tutorial_button: Button
var tutorial_focus := "none"
var starter_select: OptionButton
var wager_select: OptionButton
var action_button: Button
var delete_zone: DeleteDrop
var menu_overlay: PanelContainer
var menu_continue_button: Button
var menu_save_button: Button
var menu_progress_label: Label
var menu_run_label: Label
var menu_save_label: Label
var difficulty_select: OptionButton
var settings_dialog: AcceptDialog
var volume_slider: HSlider
var tutorial_toggle: CheckBox
var fullscreen_toggle: CheckBox
var game_over_dialog: AcceptDialog
var settlement_dialog: AcceptDialog


func _ready() -> void:
	rng.randomize()
	_load_settings()
	_load_meta_progress()
	_create_game_state()
	_initialize_coin_bag()
	_draw_hand()
	_spawn_round_enemies()
	_roll_shop_offers()
	_roll_relic_offers()
	_roll_consumable_offers()
	_roll_curse_offers()
	_pick_round_event()
	manual_clicks_left = _round_manual_click_max()
	_build_interface()
	_build_settings_dialog()
	_build_menu_overlay()
	_update_ui("准备阶段：从命运袋抽到本回合手牌；拖拽手牌上阵，商店购买会加入命运袋。")
	_show_menu()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if menu_overlay != null and menu_overlay.visible:
			_hide_menu()
		else:
			_show_menu()


func _create_game_state() -> void:
	game_state = GameStateScript.new()
	game_state.name = "GameState"
	add_child(game_state)
	game_state.coins = _difficulty_starting_coins()
	game_state.current_round = 1
	game_state.required_coins = STARTING_QUOTA


func _initialize_coin_bag() -> void:
	coin_bag.clear()
	var starter: Dictionary = STARTER_BAGS[starter_bag_id]
	for tile_type in starter["coins"]:
		coin_bag.append(String(tile_type))


func _draw_hand() -> void:
	hand_tiles.clear()
	for tile_type in locked_hand_tiles:
		hand_tiles.append(tile_type)
	var draw_pool := coin_bag.duplicate()
	for tile_type in locked_hand_tiles:
		var locked_index := draw_pool.find(tile_type)
		if locked_index != -1:
			draw_pool.remove_at(locked_index)
	draw_pool.shuffle()
	var hand_limit := HAND_SIZE + (1 if owned_relics.has("deep_pockets") else 0) - _curse_count("thin_bag")
	hand_limit = max(3, hand_limit)
	var slots_to_fill: int = max(0, hand_limit - hand_tiles.size())
	for index in range(min(slots_to_fill, draw_pool.size())):
		hand_tiles.append(String(draw_pool[index]))


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BG_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 14)
	root.add_theme_constant_override("margin_top", 10)
	root.add_theme_constant_override("margin_right", 14)
	root.add_theme_constant_override("margin_bottom", 10)
	add_child(root)

	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 10)
	root.add_child(page)
	page.add_child(_build_header())

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	page.add_child(body)
	body.add_child(_build_board_panel())
	body.add_child(_build_side_panel())

	_build_game_over_dialog()
	_build_settlement_dialog()
	_build_audio_players()


func _build_header() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 78)
	panel.add_theme_stylebox_override("panel", style(DEEP_PANEL, 8, COPPER, 2))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(title_box)

	var title := Label.new()
	title.text = "Fate Coins: Coin Cascade"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", GOLD)
	title_box.add_child(title)

	notice_label = Label.new()
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_label.add_theme_font_size_override("font_size", 15)
	notice_label.add_theme_color_override("font_color", CREAM)
	title_box.add_child(notice_label)

	coin_label = _make_stat_label()
	health_label = _make_stat_label()
	round_label = _make_stat_label()
	quota_label = _make_stat_label()
	clicks_label = _make_stat_label()
	enemy_label = _make_stat_label()
	state_label = _make_stat_label()
	row.add_child(coin_label)
	row.add_child(health_label)
	row.add_child(round_label)
	row.add_child(quota_label)
	row.add_child(clicks_label)
	row.add_child(enemy_label)
	row.add_child(state_label)

	var menu_button := _make_small_button("菜单")
	menu_button.custom_minimum_size = Vector2(70, 46)
	menu_button.pressed.connect(_show_menu)
	row.add_child(menu_button)

	return panel


func _build_board_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", style(Color(0.032, 0.115, 0.108), 8, MINT.darkened(0.35), 2))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var status := PanelContainer.new()
	status.custom_minimum_size = Vector2(0, 52)
	status.add_theme_stylebox_override("panel", style(Color(0.044, 0.069, 0.072), 8, BLUE.darkened(0.28), 2))
	column.add_child(status)

	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
	status.add_child(status_row)

	event_icon_rect = TextureRect.new()
	event_icon_rect.custom_minimum_size = Vector2(44, 44)
	event_icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	event_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	status_row.add_child(event_icon_rect)

	progress_label = Label.new()
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", CREAM)
	status_row.add_child(progress_label)

	var combat_feed := PanelContainer.new()
	combat_feed.custom_minimum_size = Vector2(0, 32)
	combat_feed.add_theme_stylebox_override("panel", style(Color(0.070, 0.040, 0.052), 8, DANGER.darkened(0.25), 1))
	column.add_child(combat_feed)

	combat_feed_label = Label.new()
	combat_feed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combat_feed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_feed_label.add_theme_font_size_override("font_size", 16)
	combat_feed_label.add_theme_color_override("font_color", CREAM)
	combat_feed.add_child(combat_feed_label)

	enemy_panel_container = HBoxContainer.new()
	enemy_panel_container.custom_minimum_size = Vector2(0, 58)
	enemy_panel_container.add_theme_constant_override("separation", 8)
	column.add_child(enemy_panel_container)

	tutorial_panel = PanelContainer.new()
	tutorial_panel.add_theme_stylebox_override("panel", style(Color(0.075, 0.065, 0.038), 8, GOLD.darkened(0.10), 2))
	column.add_child(tutorial_panel)

	var tutorial_row := HBoxContainer.new()
	tutorial_row.add_theme_constant_override("separation", 8)
	tutorial_panel.add_child(tutorial_row)

	tutorial_label = Label.new()
	tutorial_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.add_theme_font_size_override("font_size", 18)
	tutorial_label.add_theme_color_override("font_color", CREAM)
	tutorial_row.add_child(tutorial_label)

	tutorial_button = _make_small_button("跳过教程")
	tutorial_button.custom_minimum_size = Vector2(94, 34)
	tutorial_button.pressed.connect(_skip_tutorial)
	tutorial_row.add_child(tutorial_button)

	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)

	for index in range(TOTAL_SLOTS):
		board_tiles.append({})
		grid.add_child(_build_slot(index))

	return panel


func _build_side_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", style(DEEP_PANEL, 8, BLUE.darkened(0.35), 2))

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var side_stack := VBoxContainer.new()
	side_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_stack.add_theme_constant_override("separation", 8)
	margin.add_child(side_stack)

	var tabs := TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_stack.add_child(tabs)

	var column := _make_side_tab(tabs, "手牌")
	var shop_column := _make_side_tab(tabs, "商店")
	var manage_column := _make_side_tab(tabs, "管理")

	var title := Label.new()
	title.text = "命运手牌"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GOLD)
	column.add_child(title)

	var starter_box := PanelContainer.new()
	starter_box.add_theme_stylebox_override("panel", style(Color(0.056, 0.086, 0.084), 8, MINT.darkened(0.45), 1))
	column.add_child(starter_box)

	var starter_stack := VBoxContainer.new()
	starter_stack.add_theme_constant_override("separation", 4)
	starter_box.add_child(starter_stack)

	var starter_title := Label.new()
	starter_title.text = "初始命运袋"
	starter_title.add_theme_font_size_override("font_size", 20)
	starter_title.add_theme_color_override("font_color", GOLD)
	starter_stack.add_child(starter_title)

	starter_select = OptionButton.new()
	starter_select.fit_to_longest_item = false
	starter_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	starter_select.add_theme_font_size_override("font_size", 14)
	for bag_id in STARTER_BAG_ORDER:
		var config: Dictionary = STARTER_BAGS[bag_id]
		starter_select.add_item(String(config["name"]))
		starter_select.set_item_metadata(starter_select.item_count - 1, bag_id)
	starter_select.selected = STARTER_BAG_ORDER.find(starter_bag_id)
	starter_select.tooltip_text = "选择初始命运袋。悬停命运手牌可查看硬币详情。"
	starter_select.item_selected.connect(_on_starter_bag_selected)
	starter_stack.add_child(starter_select)

	var wager_box := PanelContainer.new()
	wager_box.add_theme_stylebox_override("panel", style(Color(0.075, 0.062, 0.044), 8, GOLD.darkened(0.20), 1))
	column.add_child(wager_box)

	var wager_stack := VBoxContainer.new()
	wager_stack.add_theme_constant_override("separation", 4)
	wager_box.add_child(wager_stack)

	var wager_title := Label.new()
	wager_title.text = "下注模式"
	wager_title.add_theme_font_size_override("font_size", 20)
	wager_title.add_theme_color_override("font_color", GOLD)
	wager_stack.add_child(wager_title)

	wager_select = OptionButton.new()
	wager_select.fit_to_longest_item = false
	wager_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wager_select.add_theme_font_size_override("font_size", 14)
	for mode in WAGER_ORDER:
		var config: Dictionary = WAGER_MODES[mode]
		wager_select.add_item(String(config["name"]))
		wager_select.set_item_metadata(wager_select.item_count - 1, mode)
	wager_select.selected = WAGER_ORDER.find(wager_mode)
	wager_select.tooltip_text = "选择本局风险倍率。更高风险会提高收益，也会放大失败代价。"
	wager_select.item_selected.connect(_on_wager_selected)
	wager_stack.add_child(wager_select)

	palette_container = GridContainer.new()
	palette_container.columns = 2
	palette_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palette_container.add_theme_constant_override("h_separation", 6)
	palette_container.add_theme_constant_override("v_separation", 6)
	column.add_child(palette_container)
	_rebuild_shop_palette()

	var shop_title := Label.new()
	shop_title.text = "命运商店"
	shop_title.add_theme_font_size_override("font_size", 19)
	shop_title.add_theme_color_override("font_color", GOLD)
	shop_column.add_child(shop_title)

	shop_container = VBoxContainer.new()
	shop_container.add_theme_constant_override("separation", 6)
	shop_column.add_child(shop_container)
	_rebuild_market()

	var relic_title := Label.new()
	relic_title.text = "遗物商店"
	relic_title.add_theme_font_size_override("font_size", 19)
	relic_title.add_theme_color_override("font_color", GOLD)
	shop_column.add_child(relic_title)

	relic_container = VBoxContainer.new()
	relic_container.add_theme_constant_override("separation", 6)
	shop_column.add_child(relic_container)
	_rebuild_relic_market()

	var consumable_title := Label.new()
	consumable_title.text = "一次性道具"
	consumable_title.add_theme_font_size_override("font_size", 19)
	consumable_title.add_theme_color_override("font_color", GOLD)
	shop_column.add_child(consumable_title)

	consumable_container = VBoxContainer.new()
	consumable_container.add_theme_constant_override("separation", 6)
	shop_column.add_child(consumable_container)
	_rebuild_consumable_market()

	var curse_title := Label.new()
	curse_title.text = "诅咒交易"
	curse_title.add_theme_font_size_override("font_size", 19)
	curse_title.add_theme_color_override("font_color", GOLD)
	shop_column.add_child(curse_title)

	curse_container = VBoxContainer.new()
	curse_container.add_theme_constant_override("separation", 6)
	shop_column.add_child(curse_container)
	_rebuild_curse_market()

	var bag_title := Label.new()
	bag_title.text = "命运管理"
	bag_title.add_theme_font_size_override("font_size", 19)
	bag_title.add_theme_color_override("font_color", GOLD)
	manage_column.add_child(bag_title)

	bag_container = VBoxContainer.new()
	bag_container.add_theme_constant_override("separation", 5)
	manage_column.add_child(bag_container)
	_rebuild_bag_manager()

	delete_zone = DeleteDrop.new()
	delete_zone.main = self
	delete_zone.custom_minimum_size = Vector2(0, 64)
	delete_zone.add_theme_stylebox_override("panel", style(Color(0.115, 0.035, 0.048), 8, DANGER, 2))
	manage_column.add_child(delete_zone)

	var delete_label := Label.new()
	delete_label.text = "回收区\n拖入已上阵硬币，回收部分升级投资"
	delete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delete_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	delete_label.add_theme_font_size_override("font_size", 14)
	delete_label.add_theme_color_override("font_color", CREAM)
	delete_zone.add_child(delete_label)

	action_button = _make_action_button("开始下一回合", BLUE)
	action_button.pressed.connect(_on_action_button_pressed)
	side_stack.add_child(action_button)

	return panel


func _make_side_tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	tabs.add_child(scroll)

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(0, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	scroll.add_child(column)
	return column


func _build_slot(index: int) -> Control:
	var slot := SlotView.new()
	slot.main = self
	slot.slot_index = index
	slot.custom_minimum_size = Vector2(148, 64)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot.add_theme_stylebox_override("panel", style(SLOT_COLOR, 8, Color(0.34, 0.55, 0.46), 2))

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 1)
	slot.add_child(stack)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(74, 30)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stack.add_child(icon)

	var history := HBoxContainer.new()
	history.custom_minimum_size = Vector2(0, 12)
	history.alignment = BoxContainer.ALIGNMENT_CENTER
	history.add_theme_constant_override("separation", 2)
	stack.add_child(history)

	var info := Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.70, 0.86, 0.80))
	stack.add_child(info)

	var button := Button.new()
	button.flat = true
	button.text = ""
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_slot_pressed.bind(index))
	slot.add_child(button)

	var fx_layer := Control.new()
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.add_child(fx_layer)

	slot_views.append({
		"slot": slot,
		"icon": icon,
		"history": history,
		"info": info,
		"button": button,
		"fx": fx_layer,
		"tile_view": null
	})
	_refresh_slot(index)
	return slot


func _build_palette_tile(tile_type: String) -> Control:
	var config: Dictionary = TILE_TYPES[tile_type]
	var count := _hand_count(tile_type)
	var tile := TileView.new()
	tile.main = self
	tile.tile_type = tile_type
	tile.from_palette = true
	tile.custom_minimum_size = Vector2(190, 68)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.tooltip_text = config["tip"]
	var rarity_border := _rarity_color(String(config["rarity"]))
	if _is_tutorial_focus("place"):
		tile.add_theme_stylebox_override("panel", style(PANEL_LIGHT.lightened(0.08), 8, GOLD.lightened(0.18), 3))
	else:
		tile.add_theme_stylebox_override("panel", style(PANEL_LIGHT, 8, rarity_border, 2))

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	tile.add_child(stack)

	var icon := TextureRect.new()
	icon.texture = TILE_TEXTURES[tile_type]
	icon.custom_minimum_size = Vector2(72, 28)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stack.add_child(icon)

	var label := Label.new()
	label.text = "%s %s x%d\n%s  拖拽上阵" % [config["symbol"], config["name"], count, String(config["rarity"]).to_upper()]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", CREAM)
	stack.add_child(label)

	return tile


func _build_market_offer(offer_index: int, tile_type: String) -> Control:
	var config: Dictionary = TILE_TYPES[tile_type]
	var cost := _shop_coin_cost(tile_type)
	var button := Button.new()
	button.text = "%s %s  %s  %d金" % [
		config["symbol"],
		config["name"],
		String(config["rarity"]).to_upper(),
		cost
	]
	button.tooltip_text = "%s\n购买后进入命运袋，从下一回合开始可能抽到。" % config["tip"]
	button.custom_minimum_size = Vector2(0, 34)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_icon(button, TILE_TEXTURES[tile_type])
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_stylebox_override("normal", style(PANEL_LIGHT, 6, _rarity_color(String(config["rarity"])), 1))
	button.add_theme_stylebox_override("hover", style(PANEL_LIGHT.lightened(0.08), 6, _rarity_color(String(config["rarity"])), 2))
	button.pressed.connect(_buy_shop_offer.bind(offer_index))
	return button


func _roll_shop_offers() -> void:
	shop_offer_types.clear()
	var common_pool := COMMON_SHOP_TYPES.duplicate()
	common_pool.shuffle()
	for index in range(5):
		shop_offer_types.append(common_pool[index % common_pool.size()])
	if rng.randf() < 0.72:
		shop_offer_types.append(RARE_SHOP_TYPES[rng.randi_range(0, RARE_SHOP_TYPES.size() - 1)])
	else:
		shop_offer_types.append(common_pool[5 % common_pool.size()])


func _roll_relic_offers() -> void:
	relic_offer_ids.clear()
	var pool := RELIC_ORDER.duplicate()
	pool.shuffle()
	for relic_id in pool:
		if owned_relics.has(relic_id):
			continue
		relic_offer_ids.append(relic_id)
		if relic_offer_ids.size() >= 3:
			break


func _roll_consumable_offers() -> void:
	consumable_offer_ids.clear()
	var pool := CONSUMABLE_ORDER.duplicate()
	pool.shuffle()
	for index in range(min(3, pool.size())):
		consumable_offer_ids.append(pool[index])


func _roll_curse_offers() -> void:
	curse_offer_ids.clear()
	var pool := CURSE_ORDER.duplicate()
	pool.shuffle()
	for index in range(min(2, pool.size())):
		curse_offer_ids.append(pool[index])


func _rebuild_shop_palette() -> void:
	if palette_container == null:
		return
	for child in palette_container.get_children():
		child.queue_free()
	palette_views.clear()
	var unique_hand: Array[String] = []
	for tile_type in hand_tiles:
		if not unique_hand.has(tile_type):
			unique_hand.append(tile_type)
	if unique_hand.is_empty():
		var empty := Label.new()
		empty.text = "本回合手牌已用完"
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", CREAM)
		palette_container.add_child(empty)
		return
	for tile_type in unique_hand:
		var tile := _build_palette_tile(tile_type)
		palette_views[tile_type] = tile
		palette_container.add_child(tile)


func _rebuild_market() -> void:
	if shop_container == null:
		return
	for child in shop_container.get_children():
		child.queue_free()
	for index in range(shop_offer_types.size()):
		shop_container.add_child(_build_market_offer(index, shop_offer_types[index]))


func _rebuild_relic_market() -> void:
	if relic_container == null:
		return
	for child in relic_container.get_children():
		child.queue_free()

	var owned := Label.new()
	owned.text = "已持有：%s" % _relic_summary()
	owned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owned.add_theme_font_size_override("font_size", 14)
	owned.add_theme_color_override("font_color", CREAM)
	relic_container.add_child(owned)

	for index in range(relic_offer_ids.size()):
		relic_container.add_child(_build_relic_offer(index, relic_offer_ids[index]))


func _rebuild_consumable_market() -> void:
	if consumable_container == null:
		return
	for child in consumable_container.get_children():
		child.queue_free()
	for index in range(consumable_offer_ids.size()):
		consumable_container.add_child(_build_consumable_offer(index, consumable_offer_ids[index]))


func _rebuild_curse_market() -> void:
	if curse_container == null:
		return
	for child in curse_container.get_children():
		child.queue_free()
	var active := Label.new()
	active.text = "已承受：%s" % _curse_summary()
	active.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	active.add_theme_font_size_override("font_size", 14)
	active.add_theme_color_override("font_color", CREAM)
	curse_container.add_child(active)
	for index in range(curse_offer_ids.size()):
		curse_container.add_child(_build_curse_offer(index, curse_offer_ids[index]))


func _rebuild_enemy_panel() -> void:
	if enemy_panel_container == null:
		return
	for child in enemy_panel_container.get_children():
		child.queue_free()
	if enemies.is_empty():
		var empty := Label.new()
		empty.text = "敌阵清空"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.add_theme_font_size_override("font_size", 20)
		empty.add_theme_color_override("font_color", CREAM)
		enemy_panel_container.add_child(empty)
		return
	for enemy in enemies:
		enemy_panel_container.add_child(_build_enemy_card(enemy))


func _build_enemy_card(enemy: Dictionary) -> Control:
	var is_boss := _is_boss_type(String(enemy["type"]))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 68)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.tooltip_text = "%s\n攻击 %d，偷钱 %d，赏金 %d。\n%s" % [
		enemy.get("intent", ""),
		int(enemy.get("attack", 0)),
		int(enemy.get("steal", 0)),
		int(enemy.get("reward", 0)),
		_boss_phase_text(enemy)
	]
	panel.add_theme_stylebox_override("panel", style(Color(0.105, 0.040, 0.055) if is_boss else Color(0.050, 0.075, 0.078), 8, DANGER if is_boss else BLUE.darkened(0.30), 2))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)

	var portrait := TextureRect.new()
	portrait.texture = _enemy_texture(String(enemy["type"]), is_boss)
	portrait.custom_minimum_size = Vector2(46, 46)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 1)
	row.add_child(stack)

	var name := Label.new()
	name.text = "%s%s" % ["BOSS  " if is_boss else "", enemy["name"]]
	name.add_theme_font_size_override("font_size", 12)
	name.add_theme_color_override("font_color", DANGER if is_boss else GOLD)
	stack.add_child(name)

	var hp_bar := ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = max(1, int(enemy.get("max_hp", 1)))
	hp_bar.value = clamp(int(enemy.get("hp", 0)), 0, int(hp_bar.max_value))
	hp_bar.custom_minimum_size = Vector2(0, 10)
	hp_bar.show_percentage = false
	stack.add_child(hp_bar)

	var stats := Label.new()
	stats.text = "HP %d/%d  盾 %d  攻 %d  赏 %d" % [
		int(enemy.get("hp", 0)),
		int(enemy.get("max_hp", 0)),
		int(enemy.get("shield", 0)),
		int(enemy.get("attack", 0)),
		int(enemy.get("reward", 0))
	]
	stats.add_theme_font_size_override("font_size", 10)
	stats.add_theme_color_override("font_color", CREAM)
	stack.add_child(stats)

	var intent := Label.new()
	intent.text = _boss_phase_text(enemy) if is_boss else String(enemy.get("intent", ""))
	intent.add_theme_font_size_override("font_size", 10)
	intent.add_theme_color_override("font_color", Color(0.70, 0.82, 0.78))
	intent.clip_text = true
	stack.add_child(intent)
	return panel


func _build_relic_offer(offer_index: int, relic_id: String) -> Control:
	var config: Dictionary = RELICS[relic_id]
	var button := _make_small_button("%s  %d金" % [config["name"], int(config["cost"])])
	button.custom_minimum_size = Vector2(0, 36)
	_apply_button_icon(button, _relic_texture(relic_id))
	button.tooltip_text = config["tip"]
	button.disabled = not is_intermission or game_state.coins < int(config["cost"])
	button.pressed.connect(_buy_relic_offer.bind(offer_index))
	return button


func _build_consumable_offer(offer_index: int, item_id: String) -> Control:
	var config: Dictionary = CONSUMABLES[item_id]
	var button := _make_small_button("%s  %d金" % [config["name"], int(config["cost"])])
	button.custom_minimum_size = Vector2(0, 36)
	_apply_button_icon(button, _consumable_texture(item_id))
	button.tooltip_text = config["tip"]
	button.disabled = not is_intermission or game_state.coins < int(config["cost"])
	button.pressed.connect(_buy_consumable_offer.bind(offer_index))
	return button


func _build_curse_offer(offer_index: int, curse_id: String) -> Control:
	var config: Dictionary = CURSE_DEALS[curse_id]
	var button := _make_small_button("%s  +%d金" % [config["name"], int(config["reward"])])
	button.custom_minimum_size = Vector2(0, 36)
	_apply_button_icon(button, _curse_texture(curse_id))
	button.tooltip_text = config["tip"]
	button.disabled = not is_intermission
	button.pressed.connect(_accept_curse_offer.bind(offer_index))
	return button


func _buy_relic_offer(offer_index: int) -> void:
	if not is_intermission:
		_update_ui("回合中不能购买遗物。")
		return
	if offer_index < 0 or offer_index >= relic_offer_ids.size():
		return
	var relic_id := relic_offer_ids[offer_index]
	var cost := int(RELICS[relic_id]["cost"])
	if game_state.coins < cost:
		_play_sfx("error")
		_update_ui("金币不足，购买 %s 需要 %d 金币。" % [RELICS[relic_id]["name"], cost])
		return
	game_state.coins -= cost
	owned_relics.append(relic_id)
	relic_offer_ids.remove_at(offer_index)
	_rebuild_relic_market()
	_play_sfx("upgrade")
	_update_ui("获得遗物：%s。%s" % [RELICS[relic_id]["name"], RELICS[relic_id]["tip"]])


func _buy_consumable_offer(offer_index: int) -> void:
	if not is_intermission:
		_update_ui("回合中不能使用商店道具。")
		return
	if offer_index < 0 or offer_index >= consumable_offer_ids.size():
		return
	var item_id := consumable_offer_ids[offer_index]
	var cost := int(CONSUMABLES[item_id]["cost"])
	if game_state.coins < cost:
		_play_sfx("error")
		_update_ui("金币不足，购买 %s 需要 %d 金币。" % [CONSUMABLES[item_id]["name"], cost])
		return
	game_state.coins -= cost
	consumable_offer_ids.remove_at(offer_index)
	var report := _apply_consumable(item_id)
	_rebuild_consumable_market()
	_play_sfx("upgrade")
	_update_ui(report)


func _apply_consumable(item_id: String) -> String:
	match item_id:
		"heal_potion":
			player_health = min(MAX_HEALTH, player_health + 6)
			return "使用生命药水，恢复到 %d/%d 生命。" % [player_health, MAX_HEALTH]
		"smoke_bomb":
			for index in range(TOTAL_SLOTS):
				if not board_tiles[index].is_empty():
					for key in ["locked_turns", "jammed_turns", "polluted_turns", "steal_mark_turns"]:
						board_tiles[index][key] = 0
			return "使用烟雾弹，清除所有棋盘干扰。"
		"lucky_ticket":
			manual_clicks_left += 2
			return "使用幸运券，本回合额外获得 2 次手动触发。"
		"market_tip":
			var boosted := 0
			for index in range(TOTAL_SLOTS):
				if not board_tiles[index].is_empty() and String(board_tiles[index]["type"]) == "stock":
					board_tiles[index]["stock_step"] = min(6, int(board_tiles[index].get("stock_step", 0)) + 2)
					boosted += 1
			return "使用内幕消息，提升 %d 枚股票硬币。" % boosted
		"repair_kit":
			var repaired := 0
			for index in range(TOTAL_SLOTS):
				if not board_tiles[index].is_empty() and bool(board_tiles[index].get("broken", false)):
					board_tiles[index]["broken"] = false
					repaired += 1
			return "使用修复包，修复 %d 枚破碎硬币。" % repaired
	return "使用道具。"


func _accept_curse_offer(offer_index: int) -> void:
	if not is_intermission:
		_update_ui("回合中不能接受诅咒交易。")
		return
	if offer_index < 0 or offer_index >= curse_offer_ids.size():
		return
	var curse_id := curse_offer_ids[offer_index]
	var reward := int(CURSE_DEALS[curse_id]["reward"])
	game_state.coins += reward
	active_curses.append(curse_id)
	curse_offer_ids.remove_at(offer_index)
	_apply_curse_immediate(curse_id)
	_rebuild_curse_market()
	_play_sfx("buy")
	_update_ui("接受诅咒交易：%s。%s" % [CURSE_DEALS[curse_id]["name"], CURSE_DEALS[curse_id]["tip"]])


func _apply_curse_immediate(curse_id: String) -> void:
	match curse_id:
		"blood_money":
			player_health = max(1, player_health - 4)
		"cursed_coin":
			coin_bag.append("demon")
			coin_bag.append("demon")
			_draw_hand()
			_rebuild_shop_palette()


func _rebuild_bag_manager() -> void:
	if bag_container == null:
		return
	for child in bag_container.get_children():
		child.queue_free()

	var summary := Label.new()
	summary.custom_minimum_size = Vector2(300, 0)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.text = "命运袋 %d 枚 | 锁定 %d/%d\n%s" % [
		coin_bag.size(),
		locked_hand_tiles.size(),
		MAX_LOCKED_HAND,
		_bag_summary()
	]
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 15)
	summary.add_theme_color_override("font_color", CREAM)
	bag_container.add_child(summary)

	var reroll := _make_small_button("重抽未锁手牌：%d 金币" % REROLL_COST)
	reroll.disabled = not is_intermission or hand_tiles.size() <= locked_hand_tiles.size()
	reroll.pressed.connect(_reroll_unlocked_hand)
	bag_container.add_child(reroll)

	var lock_label := Label.new()
	lock_label.text = "锁定手牌"
	lock_label.add_theme_font_size_override("font_size", 16)
	lock_label.add_theme_color_override("font_color", GOLD)
	bag_container.add_child(lock_label)

	var lock_row := GridContainer.new()
	lock_row.columns = 2
	lock_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lock_row.add_theme_constant_override("h_separation", 5)
	lock_row.add_theme_constant_override("v_separation", 5)
	bag_container.add_child(lock_row)

	var unique_hand: Array[String] = []
	for tile_type in hand_tiles:
		if not unique_hand.has(tile_type):
			unique_hand.append(tile_type)
	for tile_type in unique_hand:
		var locked_count := _locked_count(tile_type)
		var hand_count := _hand_count(tile_type)
		var text := "解锁 %s" % TILE_TYPES[tile_type]["name"] if locked_count > 0 else "锁定 %s" % TILE_TYPES[tile_type]["name"]
		var button := _make_small_button("%s  %d/%d" % [text, locked_count, hand_count])
		button.disabled = not is_intermission
		button.pressed.connect(_toggle_hand_lock.bind(tile_type))
		lock_row.add_child(button)

	var remove_label := Label.new()
	remove_label.text = "移除袋内硬币"
	remove_label.add_theme_font_size_override("font_size", 16)
	remove_label.add_theme_color_override("font_color", GOLD)
	bag_container.add_child(remove_label)

	var remove_row := GridContainer.new()
	remove_row.columns = 2
	remove_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove_row.add_theme_constant_override("h_separation", 5)
	remove_row.add_theme_constant_override("v_separation", 5)
	bag_container.add_child(remove_row)

	var bag_counts := _tile_counts(coin_bag)
	for tile_type in bag_counts.keys():
		var cost := _remove_cost()
		var button := _make_small_button("移除 %s x%d：%d" % [TILE_TYPES[String(tile_type)]["name"], int(bag_counts[tile_type]), cost])
		button.disabled = not is_intermission or coin_bag.size() <= HAND_SIZE or game_state.coins < cost
		button.pressed.connect(_remove_from_bag.bind(String(tile_type)))
		remove_row.add_child(button)


func _buy_shop_offer(offer_index: int) -> void:
	if not is_intermission:
		_update_ui("回合中不能购买命运商店。")
		return
	if offer_index < 0 or offer_index >= shop_offer_types.size():
		return
	var tile_type := shop_offer_types[offer_index]
	var cost := _shop_coin_cost(tile_type)
	if game_state.coins < cost:
		_play_sfx("error")
		_update_ui("金币不足，购买 %s 需要 %d 金币。" % [TILE_TYPES[tile_type]["name"], cost])
		return
	game_state.coins -= cost
	coin_bag.append(tile_type)
	shop_offer_types.remove_at(offer_index)
	_rebuild_market()
	_rebuild_bag_manager()
	_play_sfx("buy")
	_update_ui("购买 %s 加入命运袋。命运袋现在有 %d 枚硬币。" % [TILE_TYPES[tile_type]["name"], coin_bag.size()])


func _pick_round_event() -> void:
	current_event = Dictionary(ROUND_EVENTS[rng.randi_range(0, ROUND_EVENTS.size() - 1)])


func _spawn_round_enemies() -> void:
	enemies.clear()
	var round_number: int = int(game_state.current_round) if game_state != null else 1
	if round_number >= FINAL_ROUND:
		enemies.append(_make_enemy("banker", round_number))
		return
	if round_number == 20:
		enemies.append(_make_enemy("mirror_boss", round_number))
		return
	if round_number == 16:
		enemies.append(_make_enemy("debt_boss", round_number))
		return
	if round_number == 12:
		enemies.append(_make_enemy("market_boss", round_number))
		return
	if round_number == 8:
		enemies.append(_make_enemy("lock_boss", round_number))
		return

	var enemy_count := _enemy_count_for_round(round_number)

	var pool: Array[String] = ["thief"]
	if round_number >= 3:
		pool.append("guard")
	if round_number >= 5:
		pool.append("sniper")
	if round_number >= 10:
		pool.append("debt")
		pool.append("taxer")
	if round_number >= 12:
		pool.append("devourer")
		pool.append("saboteur")
	if round_number >= 14:
		pool.append("hexer")
		pool.append("healer")
	if round_number >= 17:
		pool.append("gambler_rat")
		pool.append("frost")
	if round_number >= 21:
		pool.append("mimic")
		pool.append("timekeeper")

	for index in range(enemy_count):
		enemies.append(_make_enemy(pool[rng.randi_range(0, pool.size() - 1)], round_number))


func _enemy_count_for_round(round_number: int) -> int:
	if difficulty_id == "normal":
		if round_number >= 19:
			return 3
		if round_number >= 11:
			return 2
		return 1
	if round_number >= 17:
		return 3
	if round_number >= 9:
		return 2
	return 1


func _make_enemy(enemy_type: String, round_number: int) -> Dictionary:
	var config: Dictionary = ENEMY_TYPES[enemy_type]
	var growth := 0.10 if difficulty_id == "normal" else 0.14
	var scale := (1.0 + float(max(0, round_number - 1)) * growth) * _difficulty_enemy_mult()
	if enemy_type == "banker":
		var boss_growth := 0.08 if difficulty_id == "normal" else 0.10
		scale = (1.0 + float(round_number - 1) * boss_growth) * _difficulty_enemy_mult()
	var attack_bias := 0.76 if difficulty_id == "normal" else 0.85
	var attack_scale := 0.17 if difficulty_id == "normal" else 0.20
	var shield_growth := 8 if difficulty_id == "normal" else 6
	var reward_base := 1.05 if difficulty_id == "normal" else 0.90
	var reward_growth := 0.09 if difficulty_id == "normal" else 0.07
	return {
		"type": enemy_type,
		"name": config["name"],
		"hp": int(ceil(float(config["hp"]) * scale)),
		"max_hp": int(ceil(float(config["hp"]) * scale)),
		"attack": int(ceil(float(config["attack"]) * (attack_bias + scale * attack_scale))),
		"shield": int(config.get("shield", 0)) + int(round_number / shield_growth),
		"steal": int(config.get("steal", 0)),
		"reward": int(ceil(float(config["reward"]) * (reward_base + float(round_number) * reward_growth))),
		"intent": config["intent"],
		"phase_applied": 1
	}


func _enemy_phase() -> String:
	if enemies.is_empty():
		return "敌人已被清空。"

	_decay_board_interference()
	var total_damage := 0
	var total_stolen := 0
	var interference_reports: Array[String] = []
	var wager_enemy_bonus := int(WAGER_MODES[wager_mode]["enemy_bonus"])
	var director_attack_delta := -2 if _director_state() == "mercy" else (1 if _director_state() == "pressure" else 0)
	for enemy in enemies:
		total_damage += max(0, int(enemy["attack"]) + wager_enemy_bonus + int(current_event.get("enemy_attack_delta", 0)) + director_attack_delta)
		total_stolen += int(enemy.get("steal", 0))
		var report := _apply_enemy_interference(enemy)
		if report != "":
			interference_reports.append(report)

	if owned_relics.has("shield_charm"):
		total_damage = max(0, total_damage - 2)
	if total_damage > 0:
		player_health = max(0, player_health - total_damage)
	if total_stolen > 0:
		game_state.coins = max(0, game_state.coins - total_stolen)

	if player_health <= 0:
		_play_sfx("error")
		_show_run_end(false, "敌人突破了你的命运棋盘。")

	var interference_text := " " + "；".join(interference_reports) if not interference_reports.is_empty() else ""
	return "敌人造成 %d 伤害，偷走 %d 金币。%s" % [total_damage, total_stolen, interference_text]


func _enemy_summary() -> String:
	if enemies.is_empty():
		return "无敌人"
	var parts: Array[String] = []
	for enemy in enemies:
		var shield_text := "+%d盾" % int(enemy.get("shield", 0)) if int(enemy.get("shield", 0)) > 0 else ""
		parts.append("%s %d/%d%s" % [enemy["name"], int(enemy["hp"]), int(enemy["max_hp"]), shield_text])
	return " | ".join(parts)


func _boss_phase(enemy: Dictionary) -> int:
	if not _is_boss_type(String(enemy.get("type", ""))):
		return 0
	var hp_ratio: float = float(enemy.get("hp", 0)) / max(1.0, float(enemy.get("max_hp", 1)))
	if hp_ratio <= 0.33:
		return 3
	if hp_ratio <= 0.66:
		return 2
	return 1


func _boss_phase_text(enemy: Dictionary) -> String:
	if not _is_boss_type(String(enemy.get("type", ""))):
		return String(enemy.get("intent", ""))
	var phase := _boss_phase(enemy)
	match phase:
		3:
			return "阶段 3：濒死狂暴，额外干扰并提高攻击。"
		2:
			return "阶段 2：压力升级，会追加护盾或偷取。"
		_:
			return "阶段 1：%s" % String(enemy.get("intent", ""))


func _apply_boss_phase(enemy: Dictionary) -> void:
	if not _is_boss_type(String(enemy.get("type", ""))):
		return
	var phase := _boss_phase(enemy)
	var applied := int(enemy.get("phase_applied", 1))
	if phase <= applied:
		return
	enemy["phase_applied"] = phase
	if phase == 2:
		enemy["shield"] = int(enemy.get("shield", 0)) + 4
		enemy["steal"] = int(enemy.get("steal", 0)) + 2
	else:
		enemy["shield"] = int(enemy.get("shield", 0)) + 6
		enemy["attack"] = int(enemy.get("attack", 0)) + 2
	_show_combat_banner("%s 进入 %s" % [enemy["name"], _boss_phase_text(enemy)], Color(1.0, 0.25, 0.18))
	_pulse_stat_label(enemy_label, Color(1.0, 0.25, 0.18))


func _apply_enemy_interference(enemy: Dictionary) -> String:
	var occupied := _occupied_slot_indices()
	if occupied.is_empty():
		return ""

	var enemy_type := String(enemy["type"])
	_apply_boss_phase(enemy)
	match enemy_type:
		"thief":
			var index := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[index]["steal_mark_turns"] = max(1, int(board_tiles[index].get("steal_mark_turns", 0)))
			return "%s 标记了 %s，下回合会偷走其收益" % [enemy["name"], _slot_coin_name(index)]
		"guard":
			var index := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[index]["locked_turns"] = max(1, int(board_tiles[index].get("locked_turns", 0)))
			enemy["shield"] = int(enemy.get("shield", 0)) + 2
			return "%s 锁住了 %s，并获得护盾" % [enemy["name"], _slot_coin_name(index)]
		"sniper":
			var index := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[index]["jammed_turns"] = max(1, int(board_tiles[index].get("jammed_turns", 0)))
			return "%s 干扰了 %s，降低正面概率" % [enemy["name"], _slot_coin_name(index)]
		"debt":
			var index := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[index]["polluted_turns"] = max(1, int(board_tiles[index].get("polluted_turns", 0)))
			return "%s 污染了 %s，触发会扣钱并伤身" % [enemy["name"], _slot_coin_name(index)]
		"taxer":
			var index := _highest_value_slot(occupied)
			board_tiles[index]["steal_mark_turns"] = max(1, int(board_tiles[index].get("steal_mark_turns", 0)))
			board_tiles[index]["jammed_turns"] = max(1, int(board_tiles[index].get("jammed_turns", 0)))
			return "%s 盯上了 %s，偷取并干扰收益" % [enemy["name"], _slot_coin_name(index)]
		"devourer":
			var index := _highest_level_slot(occupied)
			board_tiles[index]["polluted_turns"] = max(1, int(board_tiles[index].get("polluted_turns", 0)))
			return "%s 咬住了 %s，污染你的核心硬币" % [enemy["name"], _slot_coin_name(index)]
		"hexer":
			var first := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[first]["jammed_turns"] = max(1, int(board_tiles[first].get("jammed_turns", 0)))
			var second := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[second]["polluted_turns"] = max(1, int(board_tiles[second].get("polluted_turns", 0)))
			return "%s 诅咒了 %s 和 %s" % [enemy["name"], _slot_coin_name(first), _slot_coin_name(second)]
		"saboteur":
			var index := _highest_direction_slot(occupied)
			board_tiles[index]["jammed_turns"] = max(1, int(board_tiles[index].get("jammed_turns", 0)))
			board_tiles[index]["locked_turns"] = max(1, int(board_tiles[index].get("locked_turns", 0)))
			return "%s 剪断了 %s 的连锁路线" % [enemy["name"], _slot_coin_name(index)]
		"healer":
			for i in range(enemies.size()):
				enemies[i]["hp"] = min(int(enemies[i]["max_hp"]), int(enemies[i]["hp"]) + 3)
			var index := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[index]["steal_mark_turns"] = max(1, int(board_tiles[index].get("steal_mark_turns", 0)))
			return "%s 修补敌阵，并标记了 %s" % [enemy["name"], _slot_coin_name(index)]
		"gambler_rat":
			var index := _highest_value_slot(occupied)
			if wager_mode == "greedy" or wager_mode == "all_in":
				board_tiles[index]["polluted_turns"] = max(1, int(board_tiles[index].get("polluted_turns", 0)))
				enemy["shield"] = int(enemy.get("shield", 0)) + 3
				return "%s 被你的高风险下注刺激，污染了 %s 并加盾" % [enemy["name"], _slot_coin_name(index)]
			board_tiles[index]["jammed_turns"] = max(1, int(board_tiles[index].get("jammed_turns", 0)))
			return "%s 试探性干扰了 %s" % [enemy["name"], _slot_coin_name(index)]
		"frost":
			var column := rng.randi_range(0, GRID_COLUMNS - 1)
			var reports: Array[String] = []
			for row in range(GRID_ROWS):
				var index := row * GRID_COLUMNS + column
				if not board_tiles[index].is_empty():
					board_tiles[index]["locked_turns"] = max(1, int(board_tiles[index].get("locked_turns", 0)))
					reports.append(_slot_coin_name(index))
			if reports.is_empty():
				var index := occupied[rng.randi_range(0, occupied.size() - 1)]
				board_tiles[index]["locked_turns"] = max(1, int(board_tiles[index].get("locked_turns", 0)))
				reports.append(_slot_coin_name(index))
			return "%s 冻住一列：%s" % [enemy["name"], "、".join(reports)]
		"mimic":
			var index := _highest_value_slot(occupied)
			var copied_type := String(board_tiles[index]["type"])
			var copied_level := int(board_tiles[index].get("level", 1))
			var copied: int = max(2, int(ceil(float(_tile_coin_value(copied_type, copied_level)) * 0.5)))
			enemy["shield"] = int(enemy.get("shield", 0)) + copied
			board_tiles[index]["steal_mark_turns"] = max(1, int(board_tiles[index].get("steal_mark_turns", 0)))
			return "%s 模仿 %s，获得 %d 护盾" % [enemy["name"], _slot_coin_name(index), copied]
		"timekeeper":
			var index := _highest_click_slot(occupied)
			board_tiles[index]["jammed_turns"] = max(1, int(board_tiles[index].get("jammed_turns", 0)))
			board_tiles[index]["clicks_left"] = max(1, int(board_tiles[index].get("clicks_left", 1)) - 1)
			return "%s 校准了 %s，减少触发次数并降低概率" % [enemy["name"], _slot_coin_name(index)]
		"lock_boss":
			var reports: Array[String] = []
			var locks: int = 2 + max(0, _boss_phase(enemy) - 1)
			for i in range(min(locks, occupied.size())):
				var index := _highest_level_slot(occupied)
				board_tiles[index]["locked_turns"] = max(1, int(board_tiles[index].get("locked_turns", 0)))
				reports.append(_slot_coin_name(index))
				occupied.erase(index)
			return "%s 锁住核心：%s" % [enemy["name"], "、".join(reports)]
		"market_boss":
			var reports: Array[String] = []
			var marks: int = 3 + max(0, _boss_phase(enemy) - 1)
			for i in range(min(marks, occupied.size())):
				var index := _highest_value_slot(occupied)
				board_tiles[index]["steal_mark_turns"] = max(1, int(board_tiles[index].get("steal_mark_turns", 0)))
				board_tiles[index]["jammed_turns"] = max(1, int(board_tiles[index].get("jammed_turns", 0)))
				reports.append(_slot_coin_name(index))
				occupied.erase(index)
			return "%s 做空了你的核心资产：%s" % [enemy["name"], "、".join(reports)]
		"debt_boss":
			var reports: Array[String] = []
			for effect in ["polluted_turns", "steal_mark_turns", "jammed_turns"]:
				var index := occupied[rng.randi_range(0, occupied.size() - 1)]
				board_tiles[index][effect] = max(1, int(board_tiles[index].get(effect, 0)))
				reports.append(_slot_coin_name(index))
			if _boss_phase(enemy) >= 3:
				var index := _highest_value_slot(occupied)
				board_tiles[index]["polluted_turns"] = max(1, int(board_tiles[index].get("polluted_turns", 0)))
				reports.append(_slot_coin_name(index))
			return "%s 追加债务压力：%s" % [enemy["name"], "、".join(reports)]
		"mirror_boss":
			var core := _highest_value_slot(occupied)
			board_tiles[core]["steal_mark_turns"] = max(1, int(board_tiles[core].get("steal_mark_turns", 0)))
			var reports: Array[String] = [_slot_coin_name(core)]
			for direction in [Vector2i.LEFT, Vector2i.RIGHT]:
				var side := _neighbor_index(core, direction)
				if side != -1 and not board_tiles[side].is_empty():
					board_tiles[side]["locked_turns"] = max(1, int(board_tiles[side].get("locked_turns", 0)))
					reports.append(_slot_coin_name(side))
			enemy["shield"] = int(enemy.get("shield", 0)) + max(4, _neighbor_coin_count(core) * (2 + _boss_phase(enemy)))
			return "%s 映照核心路线：%s" % [enemy["name"], "、".join(reports)]
		"banker":
			var reports: Array[String] = []
			for effect in ["locked_turns", "jammed_turns", "polluted_turns"]:
				var index := occupied[rng.randi_range(0, occupied.size() - 1)]
				board_tiles[index][effect] = max(1, int(board_tiles[index].get(effect, 0)))
				reports.append(_slot_coin_name(index))
			if _boss_phase(enemy) >= 2:
				var index := _highest_value_slot(occupied)
				board_tiles[index]["steal_mark_turns"] = max(1, int(board_tiles[index].get("steal_mark_turns", 0)))
				reports.append(_slot_coin_name(index))
			if _boss_phase(enemy) >= 3:
				var index := _highest_level_slot(occupied)
				board_tiles[index]["locked_turns"] = max(1, int(board_tiles[index].get("locked_turns", 0)))
				reports.append(_slot_coin_name(index))
			return "%s 扭曲了命运：%s" % [enemy["name"], "、".join(reports)]
	return ""


func _occupied_slot_indices() -> Array[int]:
	var indices: Array[int] = []
	for index in range(TOTAL_SLOTS):
		if not board_tiles[index].is_empty():
			indices.append(index)
	return indices


func _placed_tile_count() -> int:
	var count := 0
	for index in range(TOTAL_SLOTS):
		if not board_tiles[index].is_empty():
			count += 1
	return count


func _slot_coin_name(index: int) -> String:
	if index < 0 or index >= TOTAL_SLOTS or board_tiles[index].is_empty():
		return "空位"
	var tile_type := String(board_tiles[index]["type"])
	var x := index % GRID_COLUMNS
	var y := index / GRID_COLUMNS
	return "%s(%d,%d)" % [TILE_TYPES[tile_type]["name"], x + 1, y + 1]


func _highest_level_slot(indices: Array[int]) -> int:
	var best_index := indices[0]
	var best_level := -1
	for index in indices:
		var level := int(board_tiles[index].get("level", 1))
		if level > best_level:
			best_level = level
			best_index = index
	return best_index


func _highest_value_slot(indices: Array[int]) -> int:
	var best_index := indices[0]
	var best_value := -999
	for index in indices:
		var tile_type := String(board_tiles[index]["type"])
		var level := int(board_tiles[index].get("level", 1))
		var value := _tile_coin_value(tile_type, level) + _tile_damage_value(tile_type, level)
		if value > best_value:
			best_value = value
			best_index = index
	return best_index


func _highest_direction_slot(indices: Array[int]) -> int:
	var best_index := indices[0]
	var best_score := -999
	for index in indices:
		var tile_type := String(board_tiles[index]["type"])
		var direction_count := Array(TILE_TYPES[tile_type]["directions"]).size()
		var score := direction_count * 10 + int(board_tiles[index].get("level", 1))
		if score > best_score:
			best_score = score
			best_index = index
	return best_index


func _highest_click_slot(indices: Array[int]) -> int:
	var best_index := indices[0]
	var best_clicks := -999
	for index in indices:
		var clicks := int(board_tiles[index].get("clicks_left", 0))
		if clicks > best_clicks:
			best_clicks = clicks
			best_index = index
	return best_index


func _decay_board_interference() -> void:
	for index in range(TOTAL_SLOTS):
		if board_tiles[index].is_empty():
			continue
		for key in ["locked_turns", "jammed_turns", "polluted_turns", "steal_mark_turns"]:
			board_tiles[index][key] = max(0, int(board_tiles[index].get(key, 0)) - 1)


func _hand_summary() -> String:
	if hand_tiles.is_empty():
		return "空"
	var counts := _tile_counts(hand_tiles)
	var parts: Array[String] = []
	for tile_type in counts.keys():
		parts.append("%s x%d" % [TILE_TYPES[String(tile_type)]["name"], int(counts[tile_type])])
	return " | ".join(parts)


func _bag_summary() -> String:
	if coin_bag.is_empty():
		return "空"
	var counts := _tile_counts(coin_bag)
	var parts: Array[String] = []
	for tile_type in counts.keys():
		parts.append("%s x%d" % [TILE_TYPES[String(tile_type)]["name"], int(counts[tile_type])])
	return " | ".join(parts)


func _relic_summary() -> String:
	if owned_relics.is_empty():
		return "无"
	var parts: Array[String] = []
	for relic_id in owned_relics:
		parts.append(String(RELICS[relic_id]["name"]))
	return " | ".join(parts)


func _curse_summary() -> String:
	if active_curses.is_empty():
		return "无"
	var counts := {}
	for curse_id in active_curses:
		counts[curse_id] = int(counts.get(curse_id, 0)) + 1
	var parts: Array[String] = []
	for curse_id in counts.keys():
		parts.append("%s x%d" % [CURSE_DEALS[String(curse_id)]["name"], int(counts[curse_id])])
	return " | ".join(parts)


func _curse_count(curse_id: String) -> int:
	var count := 0
	for item in active_curses:
		if item == curse_id:
			count += 1
	return count


func _tile_counts(items: Array[String]) -> Dictionary:
	var counts := {}
	for tile_type in items:
		counts[tile_type] = int(counts.get(tile_type, 0)) + 1
	return counts


func _shop_coin_cost(tile_type: String) -> int:
	var cost := int(TILE_TYPES[tile_type]["cost"])
	if owned_relics.has("merchant_seal"):
		cost = max(1, cost - 1)
	cost = max(1, cost - int(current_event.get("shop_discount", 0)))
	if _director_state() == "mercy":
		cost = max(1, cost - 1)
	return cost


func _locked_count(tile_type: String) -> int:
	var count := 0
	for item in locked_hand_tiles:
		if item == tile_type:
			count += 1
	return count


func _round_manual_click_max() -> int:
	var oracle_bonus := 1 if owned_relics.has("oracle_deck") and int(current_event.get("manual_bonus", 0)) > 0 else 0
	var director_bonus := 1 if _director_state() == "mercy" else 0
	return MAX_MANUAL_CLICKS + int(current_event.get("manual_bonus", 0)) + oracle_bonus + director_bonus


func _round_tile_click_max(tile: Dictionary) -> int:
	var tile_type := String(tile.get("type", ""))
	var relic_bonus := 1 if owned_relics.has("pocket_watch") and (tile_type == "hourglass" or tile_type == "echo") else 0
	return max(1, MAX_TILE_CLICKS + int(tile.get("level", 1)) - 1 + int(current_event.get("click_bonus", 0)) + relic_bonus)


func _round_quota_due() -> int:
	var discount := int(current_event.get("quota_discount", 0))
	if owned_relics.has("tax_receipt"):
		discount += 2
	if owned_relics.has("oracle_deck") and int(current_event.get("quota_discount", 0)) > 0:
		discount += 1
	var curse_tax := _curse_count("heavy_debt") * 3 + _board_debt_tax()
	var director_mult := 1.0
	var director := _director_state()
	if director == "mercy":
		discount += 2
		director_mult = 0.90
	if director == "pressure":
		director_mult = 1.08
	return max(0, int(ceil(float(quota + curse_tax - discount) * _difficulty_quota_mult() * director_mult)))


func _tile_trigger_chance(tile_type: String, level: int) -> float:
	var config: Dictionary = TILE_TYPES[tile_type]
	var relic_bonus := 0.10 if owned_relics.has("chain_bell") else 0.0
	if owned_relics.has("silver_lens"):
		relic_bonus += 0.04
	if owned_relics.has("echo_chamber") and (tile_type == "echo" or tile_type == "hourglass"):
		relic_bonus += 0.08
	if owned_relics.has("bloom_crown") and (tile_type == "bloom" or tile_type == "angel"):
		relic_bonus += 0.04
	if owned_relics.has("titan_gauntlet") and tile_type == "titan":
		relic_bonus += 0.06
	if owned_relics.has("debt_ledger") and tile_type == "debt_coin":
		relic_bonus += 0.04
	if owned_relics.has("cartographer_map") and (tile_type == "compass" or tile_type == "arc"):
		relic_bonus += 0.08
	if owned_relics.has("joker_mask") and tile_type == "joker":
		relic_bonus += 0.05
	if owned_relics.has("anchor_chain") and (tile_type == "anchor" or tile_type == "shield"):
		relic_bonus += 0.05
	if owned_relics.has("furnace_core") and tile_type == "forge":
		relic_bonus += 0.06
	return clampf(float(config["trigger_chance"]) + float(current_event.get("trigger_bonus", 0.0)) + relic_bonus + float(level - 1) * 0.08, 0.05, 0.95)


func _tile_coin_value(tile_type: String, level: int) -> int:
	var config: Dictionary = TILE_TYPES[tile_type]
	var relic_bonus := 1 if owned_relics.has("golden_glove") else 0
	var base_value := int(config["coin_value"]) + int(current_event.get("coin_bonus", 0)) + relic_bonus + level - 1
	return max(0, int(round(float(base_value) * float(WAGER_MODES[wager_mode]["coin_mult"]))))


func _tile_damage_value(tile_type: String, level: int) -> int:
	var config: Dictionary = TILE_TYPES[tile_type]
	var direction_bonus: int = min(2, Array(config["directions"]).size())
	var relic_bonus := 1 if owned_relics.has("war_banner") else 0
	if owned_relics.has("blood_cup") and (tile_type == "vampire" or tile_type == "demon"):
		relic_bonus += 2
	if owned_relics.has("titan_gauntlet") and tile_type == "titan":
		relic_bonus += 3
	if owned_relics.has("furnace_core") and tile_type == "forge":
		relic_bonus += 1
	if owned_relics.has("anchor_chain") and (tile_type == "anchor" or tile_type == "shield"):
		relic_bonus += 1
	var base_damage: int = int(config["coin_value"]) + direction_bonus + relic_bonus + level - 1
	return max(1, int(ceil(float(base_damage) * float(WAGER_MODES[wager_mode]["damage_mult"]))))


func _make_stat_label() -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(84, 46)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_stylebox_override("normal", style(PANEL_LIGHT, 6, BLUE.darkened(0.42), 1))
	return label


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"rare":
			return VIOLET
		"uncommon":
			return BLUE
		_:
			return GOLD


func _make_action_button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.025, 0.035, 0.038))
	button.add_theme_stylebox_override("normal", style(color, 8, color.lightened(0.28), 1))
	button.add_theme_stylebox_override("hover", style(color.lightened(0.08), 8, Color.WHITE, 1))
	button.add_theme_stylebox_override("pressed", style(color.darkened(0.14), 8, Color(0, 0, 0, 0.35), 1))
	return button


func _apply_action_button_style(highlight: bool = false) -> void:
	if action_button == null:
		return
	var base := BLUE if is_intermission else GOLD
	if highlight:
		action_button.add_theme_color_override("font_color", Color(0.025, 0.035, 0.038))
		action_button.add_theme_stylebox_override("normal", style(base.lightened(0.12), 8, Color.WHITE, 3))
		action_button.add_theme_stylebox_override("hover", style(base.lightened(0.18), 8, Color.WHITE, 3))
		action_button.add_theme_stylebox_override("pressed", style(base.darkened(0.10), 8, Color(0, 0, 0, 0.35), 2))
		return
	action_button.add_theme_color_override("font_color", Color(0.025, 0.035, 0.038))
	action_button.add_theme_stylebox_override("normal", style(base, 8, base.lightened(0.28), 1))
	action_button.add_theme_stylebox_override("hover", style(base.lightened(0.08), 8, Color.WHITE, 1))
	action_button.add_theme_stylebox_override("pressed", style(base.darkened(0.14), 8, Color(0, 0, 0, 0.35), 1))


func _make_small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 28)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_stylebox_override("normal", style(PANEL_LIGHT, 6, BLUE.darkened(0.38), 1))
	button.add_theme_stylebox_override("hover", style(PANEL_LIGHT.lightened(0.08), 6, MINT.darkened(0.12), 1))
	button.add_theme_stylebox_override("pressed", style(INK, 6, Color(0, 0, 0, 0.3), 1))
	return button


func _apply_button_icon(button: Button, texture: Texture2D) -> void:
	if texture == null:
		return
	button.icon = texture
	button.set("expand_icon", true)
	button.add_theme_constant_override("icon_max_width", 30)


func _ui_texture(key: String) -> Texture2D:
	if ui_texture_cache.has(key):
		return ui_texture_cache[key]
	if not UI_TEXTURE_PATHS.has(key):
		return null
	var texture := ResourceLoader.load(String(UI_TEXTURE_PATHS[key])) as Texture2D
	if texture == null:
		return null
	ui_texture_cache[key] = texture
	return texture


func _enemy_texture(enemy_type: String, is_boss: bool) -> Texture2D:
	var key := "enemy_%s" % enemy_type
	if ui_texture_cache.has(key):
		return ui_texture_cache[key]
	var path := "%s/%s.png" % [ENEMY_TEXTURE_DIR, enemy_type]
	if ResourceLoader.exists(path):
		var texture := ResourceLoader.load(path) as Texture2D
		if texture == null:
			return _ui_texture("boss" if is_boss else "enemy")
		ui_texture_cache[key] = texture
		return texture
	return _ui_texture("boss" if is_boss else "enemy")


func _relic_texture(relic_id: String) -> Texture2D:
	var key := "relic_%s" % relic_id
	if ui_texture_cache.has(key):
		return ui_texture_cache[key]
	var path := "%s/%s.png" % [RELIC_TEXTURE_DIR, relic_id]
	if not ResourceLoader.exists(path):
		var fallback := _ui_texture("relic")
		ui_texture_cache[key] = fallback
		return fallback
	var texture := ResourceLoader.load(path) as Texture2D
	if texture != null:
		ui_texture_cache[key] = texture
		return texture
	var fallback := _ui_texture("relic")
	ui_texture_cache[key] = fallback
	return fallback


func _consumable_texture(item_id: String) -> Texture2D:
	var key := "consumable_%s" % item_id
	if ui_texture_cache.has(key):
		return ui_texture_cache[key]
	var path := "%s/%s.png" % [CONSUMABLE_TEXTURE_DIR, item_id]
	if ResourceLoader.exists(path):
		var texture := ResourceLoader.load(path) as Texture2D
		if texture != null:
			ui_texture_cache[key] = texture
			return texture
	var fallback := _ui_texture("consumable")
	ui_texture_cache[key] = fallback
	return fallback


func _curse_texture(curse_id: String) -> Texture2D:
	var key := "curse_%s" % curse_id
	if ui_texture_cache.has(key):
		return ui_texture_cache[key]
	var path := "%s/%s.png" % [CURSE_TEXTURE_DIR, curse_id]
	if ResourceLoader.exists(path):
		var texture := ResourceLoader.load(path) as Texture2D
		if texture != null:
			ui_texture_cache[key] = texture
			return texture
	var fallback := _ui_texture("curse")
	ui_texture_cache[key] = fallback
	return fallback


func _event_texture(event: Dictionary) -> Texture2D:
	var event_type := _event_icon_type(event)
	var key := "event_%s" % event_type
	if ui_texture_cache.has(key):
		return ui_texture_cache[key]
	var path := "%s/%s.png" % [EVENT_TEXTURE_DIR, event_type]
	if ResourceLoader.exists(path):
		var texture := ResourceLoader.load(path) as Texture2D
		if texture != null:
			ui_texture_cache[key] = texture
			return texture
	var fallback := _ui_texture("relic")
	ui_texture_cache[key] = fallback
	return fallback


func _event_icon_type(event: Dictionary) -> String:
	if int(event.get("enemy_attack_delta", 0)) > 0:
		return "danger"
	if int(event.get("enemy_attack_delta", 0)) < 0:
		return "defense"
	if int(event.get("coin_bonus", 0)) > 0:
		return "coin"
	if float(event.get("trigger_bonus", 0.0)) > 0.0:
		return "chain"
	if float(event.get("trigger_bonus", 0.0)) < 0.0:
		return "reverse"
	if int(event.get("manual_bonus", 0)) > 0:
		return "manual"
	if int(event.get("quota_discount", 0)) > 0:
		return "quota_down"
	if int(event.get("quota_discount", 0)) < 0:
		return "quota_up"
	if int(event.get("shop_discount", 0)) > 0:
		return "shop"
	if int(event.get("click_bonus", 0)) > 0:
		return "durability"
	if int(event.get("click_bonus", 0)) < 0:
		return "fragile"
	return "neutral"


func _skip_tutorial() -> void:
	tutorial_enabled = false
	tutorial_focus = "none"
	_update_tutorial()
	_update_ui("教程已跳过。所有信息仍可通过悬停提示查看。")


func _update_tutorial() -> void:
	if tutorial_panel == null:
		return
	tutorial_panel.visible = tutorial_enabled and game_state.current_round <= 5
	if not tutorial_panel.visible:
		tutorial_focus = "none"
		_apply_action_button_style(false)
		return
	tutorial_focus = _tutorial_focus_for_state()
	tutorial_label.text = _tutorial_text()
	_apply_action_button_style(_is_tutorial_focus("action_start") or _is_tutorial_focus("action_end"))


func _tutorial_text() -> String:
	var step_title := _tutorial_step_title()
	var phase := "准备" if is_intermission else "行动"
	match game_state.current_round:
		1:
			if is_intermission:
				return "%s\n先选一个初始命运袋，再把右侧“命运手牌”拖到棋盘。你不用填满棋盘，先放 3 到 5 枚就能开始。" % step_title
			return "%s\n点击棋盘上发光的硬币触发正反面。正面通常赚钱和造成伤害；反面可能失败，也可能触发特殊效果。" % step_title
		2:
			if is_intermission:
				return "%s\n下注会改变风险。保守更安全，贪婪和梭哈收益高但失败会伤身。生命低时别太逞强。" % step_title
			return "%s\n方向硬币会尝试触发相邻硬币。注意箭头方向，把它们摆成一条链。" % step_title
		3:
			if is_intermission:
				return "%s\n命运商店买到的硬币会进入命运袋，不是立刻上阵。下回合抽到它，构筑才开始成型。" % step_title
			return "%s\n右侧命运管理可以锁定关键手牌，也能重抽未锁手牌。别把钱全花光，回合末还要缴纳收取。" % step_title
		4:
			if is_intermission:
				return "%s\n敌人会干扰棋盘。锁、扰、污、偷会显示在硬币信息里，悬停可以看具体效果。" % step_title
			return "%s\n优先处理被污染或被偷取标记的关键硬币，否则它们会拖慢你的收益和伤害。" % step_title
		5:
			if is_intermission:
				return "%s\n开始提纯命运袋。移除弱硬币、升级核心硬币，围绕一种流派购买。" % step_title
			return "%s\n胜利靠稳定机器，不靠单次好运。观察结算统计，决定下一局走稳健、连锁、赌博还是鲜血。" % step_title
	return "%s\n当前阶段：%s。" % [step_title, phase]


func _tutorial_step_title() -> String:
	match tutorial_focus:
		"place":
			return "教程 %d/5：拖拽发光手牌到发光空位" % game_state.current_round
		"action_start":
			return "教程 %d/5：点击发光按钮开始回合" % game_state.current_round
		"board_coin":
			return "教程 %d/5：点击发光硬币触发" % game_state.current_round
		"action_end":
			return "教程 %d/5：点击发光按钮结算回合" % game_state.current_round
		_:
			return "教程 %d/5" % game_state.current_round


func _tutorial_focus_for_state() -> String:
	if not tutorial_enabled or game_state == null or int(game_state.current_round) > 5:
		return "none"
	if is_intermission:
		if _placed_tile_count() < 3 and not hand_tiles.is_empty():
			return "place"
		return "action_start"
	if manual_clicks_left > 0 and _has_clickable_tile():
		return "board_coin"
	return "action_end"


func _is_tutorial_focus(focus: String) -> bool:
	return tutorial_enabled and tutorial_focus == focus and game_state != null and int(game_state.current_round) <= 5


func _should_highlight_empty_slot(index: int) -> bool:
	return _is_tutorial_focus("place") and index >= 0 and index < board_tiles.size() and board_tiles[index].is_empty()


func _should_highlight_coin_slot(index: int) -> bool:
	return _is_tutorial_focus("board_coin") and _slot_can_tutorial_click(index)


func _has_clickable_tile() -> bool:
	for index in range(TOTAL_SLOTS):
		if _slot_can_tutorial_click(index):
			return true
	return false


func _slot_can_tutorial_click(index: int) -> bool:
	if index < 0 or index >= board_tiles.size() or board_tiles[index].is_empty():
		return false
	var tile: Dictionary = board_tiles[index]
	return int(tile.get("clicks_left", 0)) > 0 and not bool(tile.get("broken", false)) and int(tile.get("locked_turns", 0)) <= 0


func _build_game_over_dialog() -> void:
	game_over_dialog = AcceptDialog.new()
	game_over_dialog.title = "游戏结束"
	game_over_dialog.dialog_text = "金币不足以支付本轮收取。"
	game_over_dialog.ok_button_text = "重新开始"
	game_over_dialog.confirmed.connect(_restart_game)
	game_over_dialog.add_button("回到主菜单", false, "menu")
	game_over_dialog.custom_action.connect(_on_game_over_custom_action)
	add_child(game_over_dialog)


func _build_settlement_dialog() -> void:
	settlement_dialog = AcceptDialog.new()
	settlement_dialog.title = "回合结算"
	settlement_dialog.ok_button_text = "继续布阵"
	add_child(settlement_dialog)


func _build_settings_dialog() -> void:
	settings_dialog = AcceptDialog.new()
	settings_dialog.title = "设置"
	settings_dialog.ok_button_text = "保存设置"
	settings_dialog.confirmed.connect(_save_settings)
	add_child(settings_dialog)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	settings_dialog.add_child(column)

	var display_label := Label.new()
	display_label.text = "显示"
	display_label.add_theme_font_size_override("font_size", 18)
	display_label.add_theme_color_override("font_color", GOLD)
	column.add_child(display_label)

	fullscreen_toggle = CheckBox.new()
	fullscreen_toggle.text = "全屏模式"
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	column.add_child(fullscreen_toggle)

	var volume_label := Label.new()
	volume_label.text = "音效音量"
	volume_label.add_theme_font_size_override("font_size", 18)
	volume_label.add_theme_color_override("font_color", GOLD)
	column.add_child(volume_label)

	volume_slider = HSlider.new()
	volume_slider.min_value = -30.0
	volume_slider.max_value = 0.0
	volume_slider.step = 1.0
	volume_slider.value = sfx_volume_db
	volume_slider.value_changed.connect(_on_volume_changed)
	column.add_child(volume_slider)

	tutorial_toggle = CheckBox.new()
	tutorial_toggle.text = "显示首局教程"
	tutorial_toggle.button_pressed = tutorial_enabled
	tutorial_toggle.toggled.connect(_on_tutorial_setting_toggled)
	column.add_child(tutorial_toggle)


func _build_menu_overlay() -> void:
	menu_overlay = PanelContainer.new()
	menu_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_theme_stylebox_override("panel", style(Color(0.014, 0.020, 0.025, 0.96), 0))
	add_child(menu_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(980, 620)
	panel.add_theme_stylebox_override("panel", style(DEEP_PANEL, 10, COPPER, 2))
	center.add_child(panel)

	var shell := MarginContainer.new()
	shell.add_theme_constant_override("margin_left", 22)
	shell.add_theme_constant_override("margin_top", 18)
	shell.add_theme_constant_override("margin_right", 22)
	shell.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(shell)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	shell.add_child(row)

	var showcase := VBoxContainer.new()
	showcase.custom_minimum_size = Vector2(520, 0)
	showcase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	showcase.add_theme_constant_override("separation", 12)
	row.add_child(showcase)

	var title := Label.new()
	title.text = "FATE COINS"
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", GOLD)
	showcase.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "构筑一台会反噬你的命运铸币机"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", CREAM)
	showcase.add_child(subtitle)

	var coin_frame := PanelContainer.new()
	coin_frame.custom_minimum_size = Vector2(0, 168)
	coin_frame.add_theme_stylebox_override("panel", style(Color(0.026, 0.068, 0.065), 8, MINT.darkened(0.28), 1))
	showcase.add_child(coin_frame)

	var coin_row := HBoxContainer.new()
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_row.add_theme_constant_override("separation", 12)
	coin_frame.add_child(coin_row)
	for texture in [TILE_TEXTURES["normal"], TILE_TEXTURES["lucky"], TILE_TEXTURES["reverse"]]:
		var coin := TextureRect.new()
		coin.texture = texture
		coin.custom_minimum_size = Vector2(138, 88)
		coin.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin_row.add_child(coin)

	menu_run_label = Label.new()
	menu_run_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_run_label.add_theme_font_size_override("font_size", 16)
	menu_run_label.add_theme_color_override("font_color", CREAM)
	menu_run_label.add_theme_stylebox_override("normal", style(Color(0.038, 0.054, 0.058), 8, BLUE.darkened(0.38), 1))
	showcase.add_child(menu_run_label)

	menu_progress_label = Label.new()
	menu_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_progress_label.add_theme_font_size_override("font_size", 16)
	menu_progress_label.add_theme_color_override("font_color", CREAM)
	menu_progress_label.add_theme_stylebox_override("normal", style(Color(0.048, 0.046, 0.034), 8, GOLD.darkened(0.35), 1))
	showcase.add_child(menu_progress_label)

	menu_save_label = Label.new()
	menu_save_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_save_label.add_theme_font_size_override("font_size", 14)
	menu_save_label.add_theme_color_override("font_color", Color(0.70, 0.82, 0.78))
	showcase.add_child(menu_save_label)

	var actions := VBoxContainer.new()
	actions.custom_minimum_size = Vector2(360, 0)
	actions.add_theme_constant_override("separation", 10)
	row.add_child(actions)

	var action_title := Label.new()
	action_title.text = "铸币台"
	action_title.add_theme_font_size_override("font_size", 28)
	action_title.add_theme_color_override("font_color", GOLD)
	actions.add_child(action_title)

	difficulty_select = OptionButton.new()
	difficulty_select.add_theme_font_size_override("font_size", 18)
	for diff_id in DIFFICULTY_ORDER:
		var config: Dictionary = DIFFICULTIES[diff_id]
		difficulty_select.add_item("%s - %s" % [config["name"], config["tip"]])
		difficulty_select.set_item_metadata(difficulty_select.item_count - 1, diff_id)
	difficulty_select.selected = DIFFICULTY_ORDER.find(difficulty_id)
	difficulty_select.item_selected.connect(_on_difficulty_selected)
	actions.add_child(difficulty_select)

	var new_button := _make_action_button("新游戏", BLUE)
	new_button.pressed.connect(_start_new_run_from_menu)
	actions.add_child(new_button)

	menu_continue_button = _make_action_button("继续游戏", GREEN)
	menu_continue_button.pressed.connect(_continue_from_menu)
	actions.add_child(menu_continue_button)

	menu_save_button = _make_action_button("保存当前局", GOLD)
	menu_save_button.pressed.connect(_save_game)
	actions.add_child(menu_save_button)

	var delete_save_button := _make_action_button("删除存档", Color(0.76, 0.32, 0.28))
	delete_save_button.pressed.connect(_delete_save)
	actions.add_child(delete_save_button)

	var settings_button := _make_action_button("设置", Color(0.70, 0.72, 0.76))
	settings_button.pressed.connect(_open_settings)
	actions.add_child(settings_button)

	var close_button := _make_action_button("返回游戏", Color(0.46, 0.58, 0.72))
	close_button.pressed.connect(_hide_menu)
	actions.add_child(close_button)

	var quit_button := _make_action_button("退出到桌面", Color(0.32, 0.36, 0.40))
	quit_button.pressed.connect(_quit_to_desktop)
	actions.add_child(quit_button)


func _build_audio_players() -> void:
	_release_audio_players()
	for key in SFX_PATHS:
		var player := AudioStreamPlayer.new()
		player.stream = _load_wav_stream(SFX_PATHS[key])
		player.volume_db = sfx_volume_db
		add_child(player)
		sfx_players[key] = player


func _load_wav_stream(path: String) -> AudioStreamWAV:
	var stream := ResourceLoader.load(path) as AudioStreamWAV
	if stream == null:
		return AudioStreamWAV.new()
	return stream


func _play_sfx(key: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not sfx_players.has(key):
		return
	var player: AudioStreamPlayer = sfx_players[key]
	player.stop()
	player.play()


func _release_audio_players() -> void:
	for key in sfx_players.keys():
		var player: AudioStreamPlayer = sfx_players[key]
		if player == null:
			continue
		player.stop()
		player.stream = null
		if player.get_parent() != null:
			player.get_parent().remove_child(player)
		player.free()
	sfx_players.clear()


func _exit_tree() -> void:
	_release_audio_players()


func _show_menu() -> void:
	if menu_overlay == null:
		return
	_refresh_menu_state()
	menu_overlay.visible = true


func _hide_menu() -> void:
	if menu_overlay != null:
		menu_overlay.visible = false


func _on_game_over_custom_action(action: StringName) -> void:
	if String(action) == "menu":
		game_over_dialog.hide()
		_show_menu()


func _start_new_run_from_menu() -> void:
	_restart_game()
	_hide_menu()


func _continue_from_menu() -> void:
	if _load_game():
		_hide_menu()


func _open_settings() -> void:
	if volume_slider != null:
		volume_slider.value = sfx_volume_db
	if tutorial_toggle != null:
		tutorial_toggle.button_pressed = tutorial_enabled
	if fullscreen_toggle != null:
		fullscreen_toggle.button_pressed = fullscreen_enabled
	settings_dialog.popup_centered()


func _on_volume_changed(value: float) -> void:
	sfx_volume_db = value
	for key in sfx_players:
		var player: AudioStreamPlayer = sfx_players[key]
		player.volume_db = sfx_volume_db


func _on_tutorial_setting_toggled(enabled: bool) -> void:
	tutorial_enabled = enabled
	_update_tutorial()


func _on_fullscreen_toggled(enabled: bool) -> void:
	fullscreen_enabled = enabled
	_apply_fullscreen_setting()


func _apply_fullscreen_setting() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED)


func _quit_to_desktop() -> void:
	_save_settings()
	get_tree().quit()


func _on_difficulty_selected(index: int) -> void:
	if index < 0 or index >= DIFFICULTY_ORDER.size():
		return
	var selected := String(difficulty_select.get_item_metadata(index))
	if not _is_difficulty_unlocked(selected):
		_play_sfx("error")
		difficulty_select.selected = DIFFICULTY_ORDER.find(difficulty_id)
		_update_ui("该难度尚未解锁。")
		return
	difficulty_id = selected
	_update_ui("难度切换为 %s。新游戏会使用该难度。" % DIFFICULTIES[difficulty_id]["name"])


func _refresh_menu_state() -> void:
	var has_save := FileAccess.file_exists(SAVE_PATH)
	if menu_progress_label != null:
		menu_progress_label.text = "永久进度\n最高回合：%d/%d    通关：%d    已解锁：%s" % [
			int(meta_progress.get("best_round", 1)),
			FINAL_ROUND,
			int(meta_progress.get("victories", 0)),
			_unlocked_difficulty_names()
		]
	if menu_run_label != null:
		menu_run_label.text = _menu_current_run_text()
	if menu_save_label != null:
		menu_save_label.text = _menu_save_preview_text()
	if menu_continue_button != null:
		menu_continue_button.disabled = not has_save
		menu_continue_button.text = "继续存档" if has_save else "没有可继续的存档"
	if menu_save_button != null:
		menu_save_button.disabled = game_state == null
	if difficulty_select != null:
		difficulty_select.selected = DIFFICULTY_ORDER.find(difficulty_id)
		for i in range(DIFFICULTY_ORDER.size()):
			var diff_id := String(DIFFICULTY_ORDER[i])
			difficulty_select.set_item_disabled(i, not _is_difficulty_unlocked(diff_id))


func _menu_current_run_text() -> String:
	if game_state == null:
		return "当前局\n尚未初始化。"
	return "当前局\n难度：%s    阶段：%s    回合：%d/%d\n金币：%d    生命：%d/%d    命运袋：%d    遗物：%d\n本局收益：%d    本局伤害：%d    击败：%d    最高连锁：%d" % [
		DIFFICULTIES[difficulty_id]["name"],
		"布阵" if is_intermission else "行动",
		int(game_state.current_round),
		FINAL_ROUND,
		int(game_state.coins),
		player_health,
		MAX_HEALTH,
		coin_bag.size(),
		owned_relics.size(),
		run_total_collected,
		run_total_damage,
		run_kills,
		run_best_chain
	]


func _menu_save_preview_text() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return "存档\n尚无本地存档。新游戏开始后可手动保存，也会保留永久进度。"
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return "存档\n发现存档，但当前无法读取。"
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return "存档\n发现存档，但格式无效。"
	var data: Dictionary = parsed
	var save_difficulty := String(data.get("difficulty_id", "normal"))
	var save_round := int(data.get("current_round", 1))
	var save_coins := int(data.get("coins", 0))
	var save_health := int(data.get("player_health", STARTING_HEALTH))
	var save_bag := _string_array(data.get("coin_bag", []))
	var save_relics := _string_array(data.get("owned_relics", []))
	var diff_name := String(DIFFICULTIES.get(save_difficulty, DIFFICULTIES["normal"])["name"])
	return "存档\n%s    回合 %d/%d    金币 %d    生命 %d/%d    命运袋 %d    遗物 %d" % [
		diff_name,
		save_round,
		FINAL_ROUND,
		save_coins,
		save_health,
		MAX_HEALTH,
		save_bag.size(),
		save_relics.size()
	]


func _is_difficulty_unlocked(diff_id: String) -> bool:
	var unlocked := _string_array(meta_progress.get("unlocked_difficulties", ["normal"]))
	return unlocked.has(diff_id)


func _unlocked_difficulty_names() -> String:
	var names: Array[String] = []
	for diff_id in DIFFICULTY_ORDER:
		if _is_difficulty_unlocked(diff_id):
			names.append(String(DIFFICULTIES[diff_id]["name"]))
	return " / ".join(names)


func _difficulty_starting_coins() -> int:
	return int(DIFFICULTIES[difficulty_id]["start_coins"])


func _difficulty_enemy_mult() -> float:
	return float(DIFFICULTIES[difficulty_id]["enemy_mult"])


func _difficulty_quota_mult() -> float:
	return float(DIFFICULTIES[difficulty_id]["quota_mult"])


func _quota_for_round(round_number: int) -> int:
	var index: int = clamp(round_number - 1, 0, ROUND_QUOTAS.size() - 1)
	return int(ROUND_QUOTAS[index])


func _director_state() -> String:
	if game_state == null:
		return "steady"
	var raw_due := quota + _curse_count("heavy_debt") * 3
	var round_number := int(game_state.current_round)
	if player_health <= 10 or game_state.coins < raw_due:
		return "mercy"
	if round_number >= 6 and player_health >= 28 and game_state.coins >= raw_due * 3 and owned_relics.size() >= 2:
		return "pressure"
	return "steady"


func _director_label() -> String:
	match _director_state():
		"mercy":
			return "逆风扶正"
		"pressure":
			return "顺风加压"
		_:
			return "稳定"


func _save_settings() -> void:
	var data := {
		"sfx_volume_db": sfx_volume_db,
		"tutorial_enabled": tutorial_enabled,
		"fullscreen_enabled": fullscreen_enabled
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
	_update_ui("设置已保存。")


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	sfx_volume_db = float(parsed.get("sfx_volume_db", sfx_volume_db))
	tutorial_enabled = bool(parsed.get("tutorial_enabled", tutorial_enabled))
	fullscreen_enabled = bool(parsed.get("fullscreen_enabled", fullscreen_enabled))
	_apply_fullscreen_setting()


func _load_meta_progress() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var file := FileAccess.open(META_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	meta_progress = {
		"best_round": int(parsed.get("best_round", 1)),
		"victories": int(parsed.get("victories", 0)),
		"unlocked_difficulties": _string_array(parsed.get("unlocked_difficulties", ["normal"]))
	}
	_unlock_progress_from_stats()


func _save_meta_progress() -> void:
	var file := FileAccess.open(META_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(meta_progress))


func _record_run_progress(victory: bool) -> void:
	meta_progress["best_round"] = max(int(meta_progress.get("best_round", 1)), int(game_state.current_round))
	if victory:
		meta_progress["victories"] = int(meta_progress.get("victories", 0)) + 1
	_unlock_progress_from_stats()
	_save_meta_progress()


func _unlock_progress_from_stats() -> void:
	var unlocked := _string_array(meta_progress.get("unlocked_difficulties", ["normal"]))
	if not unlocked.has("normal"):
		unlocked.append("normal")
	if int(meta_progress.get("best_round", 1)) >= 8 and not unlocked.has("hard"):
		unlocked.append("hard")
	if int(meta_progress.get("victories", 0)) >= 1 and not unlocked.has("fate"):
		unlocked.append("fate")
	meta_progress["unlocked_difficulties"] = unlocked


func _save_game() -> void:
	var data := {
		"coins": game_state.coins,
		"current_round": game_state.current_round,
		"required_coins": game_state.required_coins,
		"player_health": player_health,
		"difficulty_id": difficulty_id,
		"wager_mode": wager_mode,
		"tutorial_enabled": tutorial_enabled,
		"quota": quota,
		"starter_bag_id": starter_bag_id,
		"coin_bag": coin_bag,
		"hand_tiles": hand_tiles,
		"locked_hand_tiles": locked_hand_tiles,
		"removed_from_bag": removed_from_bag,
		"shop_offer_types": shop_offer_types,
		"relic_offer_ids": relic_offer_ids,
		"consumable_offer_ids": consumable_offer_ids,
		"curse_offer_ids": curse_offer_ids,
		"owned_relics": owned_relics,
		"active_curses": active_curses,
		"enemies": enemies,
		"current_event": current_event,
		"board_tiles": board_tiles,
		"is_intermission": is_intermission,
		"manual_clicks_left": manual_clicks_left,
		"round_collected": round_collected,
		"round_damage": round_damage,
		"round_failures": round_failures,
		"run_total_collected": run_total_collected,
		"run_total_damage": run_total_damage,
		"run_kills": run_kills,
		"run_best_chain": run_best_chain,
		"best_chain_this_round": best_chain_this_round
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_play_sfx("error")
		_update_ui("保存失败：无法写入存档。")
		return
	file.store_string(JSON.stringify(data))
	_play_sfx("settle")
	_update_ui("当前局已保存。")
	_show_menu()


func _load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		_update_ui("没有找到存档。")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_update_ui("读取失败：无法打开存档。")
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_update_ui("读取失败：存档格式无效。")
		return false
	_apply_save_data(parsed)
	_play_sfx("settle")
	_update_ui("已读取存档。")
	return true


func _delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_update_ui("存档已删除。")
	_show_menu()


func _apply_save_data(data: Dictionary) -> void:
	game_state.coins = int(data.get("coins", STARTING_COINS))
	game_state.current_round = int(data.get("current_round", 1))
	game_state.required_coins = int(data.get("required_coins", STARTING_QUOTA))
	player_health = int(data.get("player_health", STARTING_HEALTH))
	difficulty_id = String(data.get("difficulty_id", "normal"))
	if not _is_difficulty_unlocked(difficulty_id):
		difficulty_id = "normal"
	wager_mode = String(data.get("wager_mode", "standard"))
	tutorial_enabled = bool(data.get("tutorial_enabled", tutorial_enabled))
	quota = int(data.get("quota", STARTING_QUOTA))
	starter_bag_id = String(data.get("starter_bag_id", "balanced"))
	coin_bag = _string_array(data.get("coin_bag", []))
	hand_tiles = _string_array(data.get("hand_tiles", []))
	locked_hand_tiles = _string_array(data.get("locked_hand_tiles", []))
	removed_from_bag = int(data.get("removed_from_bag", 0))
	shop_offer_types = _string_array(data.get("shop_offer_types", []))
	relic_offer_ids = _string_array(data.get("relic_offer_ids", []))
	consumable_offer_ids = _string_array(data.get("consumable_offer_ids", []))
	curse_offer_ids = _string_array(data.get("curse_offer_ids", []))
	owned_relics = _string_array(data.get("owned_relics", []))
	active_curses = _string_array(data.get("active_curses", []))
	enemies = _dict_array(data.get("enemies", []))
	current_event = Dictionary(data.get("current_event", {}))
	board_tiles = _dict_array(data.get("board_tiles", []))
	while board_tiles.size() < TOTAL_SLOTS:
		board_tiles.append({})
	is_intermission = bool(data.get("is_intermission", true))
	manual_clicks_left = int(data.get("manual_clicks_left", _round_manual_click_max()))
	round_collected = int(data.get("round_collected", 0))
	round_damage = int(data.get("round_damage", 0))
	round_failures = int(data.get("round_failures", 0))
	run_total_collected = int(data.get("run_total_collected", 0))
	run_total_damage = int(data.get("run_total_damage", 0))
	run_kills = int(data.get("run_kills", 0))
	run_best_chain = int(data.get("run_best_chain", 0))
	best_chain_this_round = int(data.get("best_chain_this_round", 0))
	_refresh_everything()


func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		result.append(String(item))
	return result


func _dict_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		result.append(Dictionary(item) if typeof(item) == TYPE_DICTIONARY else {})
	return result


func _refresh_everything() -> void:
	if starter_select != null:
		starter_select.selected = STARTER_BAG_ORDER.find(starter_bag_id)
	if wager_select != null:
		wager_select.selected = WAGER_ORDER.find(wager_mode)
	if difficulty_select != null:
		difficulty_select.selected = DIFFICULTY_ORDER.find(difficulty_id)
	_refresh_menu_state()
	_rebuild_shop_palette()
	_rebuild_market()
	_rebuild_relic_market()
	_rebuild_consumable_market()
	_rebuild_curse_market()
	_rebuild_bag_manager()
	_update_ui()


func _show_settlement() -> void:
	settlement_dialog.title = "回合结算"
	var summary := last_round_summary
	settlement_dialog.dialog_text = "第 %d 回合完成\n事件：%s\n本轮获得金币：%d\n本轮造成伤害：%d\n手动失败次数：%d\n本轮收取金币：%d\n最高连锁：%d\n敌人回合：%s\n当前金币：%d\n当前生命：%d/%d\n命运袋：%d 枚\n\n下一回合事件：%s\n新手牌：%s\n新敌人：%s\n商店已经刷新。" % [
		int(summary.get("round", 0)),
		String(summary.get("event", "")),
		int(summary.get("collected", 0)),
		int(summary.get("damage", 0)),
		int(summary.get("failures", 0)),
		int(summary.get("due", 0)),
		int(summary.get("best_chain", 0)),
		String(summary.get("enemy_report", "")),
		game_state.coins,
		player_health,
		MAX_HEALTH,
		coin_bag.size(),
		String(current_event.get("name", "")),
		_hand_summary(),
		_enemy_summary()
	]
	settlement_dialog.popup_centered()


func _show_run_end(victory: bool, reason: String) -> void:
	_record_run_progress(victory)
	game_over_dialog.title = "命运逆转" if victory else "游戏结束"
	game_over_dialog.dialog_text = "%s\n\n%s\n\n%s" % [
		reason,
		_run_score_summary(),
		_run_advice(victory, reason)
	]
	game_over_dialog.ok_button_text = "重新开始"
	game_over_dialog.popup_centered()


func _run_score_summary() -> String:
	return "难度：%s\n流派：%s\n到达回合：%d/%d\n最终金币：%d\n剩余生命：%d/%d\n命运袋：%d 枚\n遗物：%s\n总金币收益：%d\n总伤害：%d\n击败敌人：%d\n最高连锁：%d" % [
		DIFFICULTIES[difficulty_id]["name"],
		STARTER_BAGS[starter_bag_id]["name"],
		game_state.current_round,
		FINAL_ROUND,
		max(0, game_state.coins),
		player_health,
		MAX_HEALTH,
		coin_bag.size(),
		_relic_summary(),
		run_total_collected,
		run_total_damage,
		run_kills,
		run_best_chain
	]


func _run_advice(victory: bool, reason: String) -> String:
	if victory:
		return "建议：尝试换一个初始命运袋，或者在商店里少买、多移除，挑战更稳定的构筑。"
	if reason.find("金币") != -1:
		return "失败原因：经济不足。建议减少早期升级和重抽，优先买入 Bank、Lucky 或 Stock，必要时选择保守下注。"
	if reason.find("高风险") != -1 or reason.find("代价") != -1:
		return "失败原因：风险透支。建议在生命低于 10 时避免贪婪/梭哈，或用 Vampire、Lucky 先恢复。"
	if reason.find("敌人") != -1:
		return "失败原因：敌人压力过高。建议优先击杀远程鼠和债主，并处理被锁、被污的关键硬币。"
	if run_best_chain < 4:
		return "失败原因：连锁不足。建议尝试连锁命运袋，多买方向硬币、Star、Spirit 和 Cross。"
	return "失败原因：构筑还不稳定。建议移除多余普通硬币，锁定核心手牌，并围绕一种流派购买。"


func style(fill: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.border_color = border
	box.border_width_left = width
	box.border_width_top = width
	box.border_width_right = width
	box.border_width_bottom = width
	box.shadow_color = Color(0, 0, 0, 0.28)
	box.shadow_size = 5 if width > 0 else 2
	box.shadow_offset = Vector2(0, 2)
	box.content_margin_left = 8
	box.content_margin_top = 5
	box.content_margin_right = 8
	box.content_margin_bottom = 5
	return box


func can_start_tile_drag(from_palette: bool) -> bool:
	if not is_intermission:
		return false
	return true if from_palette else true


func _hand_count(tile_type: String) -> int:
	var count := 0
	for item in hand_tiles:
		if item == tile_type:
			count += 1
	return count


func _consume_hand_tile(tile_type: String) -> bool:
	var index := hand_tiles.find(tile_type)
	if index == -1:
		return false
	hand_tiles.remove_at(index)
	var locked_index := locked_hand_tiles.find(tile_type)
	if locked_index != -1:
		locked_hand_tiles.remove_at(locked_index)
	_rebuild_shop_palette()
	_rebuild_bag_manager()
	return true


func _toggle_hand_lock(tile_type: String) -> void:
	if not is_intermission:
		return
	var locked_index := locked_hand_tiles.find(tile_type)
	if locked_index != -1:
		locked_hand_tiles.remove_at(locked_index)
		_rebuild_bag_manager()
		_update_ui("已解锁 %s。" % TILE_TYPES[tile_type]["name"])
		return
	if locked_hand_tiles.size() >= MAX_LOCKED_HAND:
		_play_sfx("error")
		_update_ui("最多锁定 %d 枚手牌。" % MAX_LOCKED_HAND)
		return
	if _locked_count(tile_type) >= _hand_count(tile_type):
		return
	locked_hand_tiles.append(tile_type)
	_rebuild_bag_manager()
	_update_ui("已锁定 %s，下次重抽或下回合会保留。" % TILE_TYPES[tile_type]["name"])


func _reroll_unlocked_hand() -> void:
	if not is_intermission:
		return
	if game_state.coins < REROLL_COST:
		_play_sfx("error")
		_update_ui("金币不足，重抽需要 %d 金币。" % REROLL_COST)
		return
	game_state.coins -= REROLL_COST
	_draw_hand()
	_rebuild_shop_palette()
	_rebuild_bag_manager()
	_play_sfx("upgrade")
	_update_ui("重抽未锁手牌。当前手牌：%s" % _hand_summary())


func _remove_cost() -> int:
	var discount := 3 if owned_relics.has("void_purse") else 0
	return max(1, REMOVE_COST_BASE + removed_from_bag * 2 - discount)


func _remove_from_bag(tile_type: String) -> void:
	if not is_intermission:
		return
	if coin_bag.size() <= HAND_SIZE:
		_play_sfx("error")
		_update_ui("命运袋至少要保留 %d 枚硬币。" % HAND_SIZE)
		return
	var cost := _remove_cost()
	if game_state.coins < cost:
		_play_sfx("error")
		_update_ui("金币不足，移除需要 %d 金币。" % cost)
		return
	var bag_index := coin_bag.find(tile_type)
	if bag_index == -1:
		return
	game_state.coins -= cost
	coin_bag.remove_at(bag_index)
	removed_from_bag += 1
	var hand_index := hand_tiles.find(tile_type)
	if hand_index != -1:
		hand_tiles.remove_at(hand_index)
	var locked_index := locked_hand_tiles.find(tile_type)
	if locked_index != -1:
		locked_hand_tiles.remove_at(locked_index)
	_rebuild_shop_palette()
	_rebuild_bag_manager()
	_play_sfx("buy")
	_update_ui("移除 1 枚 %s。命运袋现在有 %d 枚硬币。" % [TILE_TYPES[tile_type]["name"], coin_bag.size()])


func _on_wager_selected(index: int) -> void:
	if index < 0 or index >= WAGER_ORDER.size():
		return
	wager_mode = String(wager_select.get_item_metadata(index))
	if wager_mode == "greedy" or wager_mode == "all_in":
		_show_combat_banner(_wager_warning_text(), Color(1.0, 0.45, 0.25))
		_pulse_stat_label(state_label, Color(1.0, 0.30, 0.20))
	_update_ui("下注模式切换为 %s：%s" % [WAGER_MODES[wager_mode]["name"], WAGER_MODES[wager_mode]["tip"]])


func _on_starter_bag_selected(index: int) -> void:
	if index < 0 or index >= STARTER_BAG_ORDER.size():
		return
	if game_state.current_round != 1 or not is_intermission or _placed_tile_count() > 0:
		_play_sfx("error")
		starter_select.selected = STARTER_BAG_ORDER.find(starter_bag_id)
		_update_ui("只能在第 1 回合布阵前切换初始命运袋。")
		return
	starter_bag_id = String(starter_select.get_item_metadata(index))
	_initialize_coin_bag()
	locked_hand_tiles.clear()
	removed_from_bag = 0
	_draw_hand()
	_rebuild_shop_palette()
	_rebuild_bag_manager()
	_update_ui("已选择 %s 命运袋。%s" % [STARTER_BAGS[starter_bag_id]["name"], STARTER_BAGS[starter_bag_id]["tip"]])


func can_start_slot_drag(slot_index: int) -> bool:
	return is_intermission and slot_index >= 0 and slot_index < TOTAL_SLOTS and not board_tiles[slot_index].is_empty()


func tile_type_at(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= TOTAL_SLOTS or board_tiles[slot_index].is_empty():
		return "normal"
	return String(board_tiles[slot_index]["type"])


func make_drag_preview(tile_type: String) -> Control:
	var preview := Label.new()
	preview.text = tile_symbol(tile_type)
	preview.custom_minimum_size = Vector2(72, 72)
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_theme_font_size_override("font_size", 40)
	preview.add_theme_color_override("font_color", Color.WHITE)
	preview.add_theme_stylebox_override("normal", style(PANEL_LIGHT, 8, GOLD, 2))
	return preview


func can_drop_on_slot(slot_index: int, data: Variant) -> bool:
	if not is_intermission or typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("kind") or not data.has("type"):
		return false
	if slot_index < 0 or slot_index >= TOTAL_SLOTS:
		return false
	if String(data["kind"]) == "palette":
		var tile_type := String(data["type"])
		if _hand_count(tile_type) <= 0:
			return false
		if board_tiles[slot_index].is_empty():
			return true
		return _can_upgrade_slot(slot_index, tile_type)
	if String(data["kind"]) == "placed":
		var from_slot := int(data["from_slot"])
		return from_slot != slot_index and board_tiles[slot_index].is_empty()
	return false


func drop_on_slot(slot_index: int, data: Variant) -> void:
	var kind := String(data["kind"])
	var tile_type := String(data["type"])
	if kind == "palette":
		if _hand_count(tile_type) <= 0:
			_update_ui("这枚硬币已经不在本回合手牌里了。")
			return
		if board_tiles[slot_index].is_empty():
			if not _consume_hand_tile(tile_type):
				return
			board_tiles[slot_index] = _new_tile(tile_type)
			_refresh_slot(slot_index)
			_play_sfx("buy")
			_update_ui("上阵 %s。本回合剩余手牌 %d 枚。" % [TILE_TYPES[tile_type]["name"], hand_tiles.size()])
		else:
			if _consume_hand_tile(tile_type):
				_upgrade_slot(slot_index)
	elif kind == "placed":
		var from_slot := int(data["from_slot"])
		board_tiles[slot_index] = board_tiles[from_slot]
		board_tiles[from_slot] = {}
		_refresh_slot(from_slot)
		_refresh_slot(slot_index)
		_play_sfx("buy")
		_update_ui("硬币已移动。")


func can_drop_on_delete(data: Variant) -> bool:
	return is_intermission and typeof(data) == TYPE_DICTIONARY and String(data.get("kind", "")) == "placed"


func drop_on_delete(data: Variant) -> void:
	var from_slot := int(data["from_slot"])
	if from_slot < 0 or from_slot >= TOTAL_SLOTS or board_tiles[from_slot].is_empty():
		return
	var tile_type := String(board_tiles[from_slot]["type"])
	var refund := int(floor(float(board_tiles[from_slot].get("invested", 0)) * 0.5))
	game_state.coins += refund
	board_tiles[from_slot] = {}
	_refresh_slot(from_slot)
	_play_sfx("buy")
	_update_ui("回收 %s，返还 %d 金币升级投资。" % [TILE_TYPES[tile_type]["name"], refund])


func _new_tile(tile_type: String) -> Dictionary:
	return {
		"type": tile_type,
		"level": 1,
		"invested": 0,
		"clicks_left": MAX_TILE_CLICKS,
		"stock_step": 0,
		"forge_heat": 0,
		"bloom_growth": 0,
		"broken": false,
		"locked_turns": 0,
		"jammed_turns": 0,
		"polluted_turns": 0,
		"steal_mark_turns": 0,
		"history": []
	}


func _can_upgrade_slot(slot_index: int, tile_type: String) -> bool:
	if board_tiles[slot_index].is_empty() or String(board_tiles[slot_index]["type"]) != tile_type:
		return false
	var level := int(board_tiles[slot_index].get("level", 1))
	return level < MAX_TILE_LEVEL and game_state.coins >= _upgrade_cost(tile_type, level) and _hand_count(tile_type) > 0


func _upgrade_cost(tile_type: String, current_level: int) -> int:
	var discount := 2 if owned_relics.has("steady_anvil") else 0
	return max(1, int(TILE_TYPES[tile_type]["cost"]) * (current_level + 1) - discount)


func _upgrade_slot(slot_index: int) -> void:
	var tile := board_tiles[slot_index]
	var tile_type := String(tile["type"])
	var level := int(tile.get("level", 1))
	if level >= MAX_TILE_LEVEL:
		_update_ui("%s 已经满级。" % TILE_TYPES[tile_type]["name"])
		return
	var cost := _upgrade_cost(tile_type, level)
	if game_state.coins < cost:
		_update_ui("金币不足，升级需要 %d 金币。" % cost)
		return
	game_state.coins -= cost
	tile["level"] = level + 1
	tile["invested"] = int(tile.get("invested", 0)) + cost
	tile["clicks_left"] = _round_tile_click_max(tile)
	tile["broken"] = false
	board_tiles[slot_index] = tile
	_refresh_slot(slot_index)
	_play_sfx("upgrade")
	_update_ui("%s 升到 Lv.%d，收益和触发率提升。" % [TILE_TYPES[tile_type]["name"], int(tile["level"])])


func _on_slot_pressed(index: int) -> void:
	if is_intermission:
		_update_ui("准备阶段不能触发硬币。点击“开始下一回合”后开始收集金币和攻击敌人。")
		return
	if manual_clicks_left <= 0:
		_update_ui("本轮手动点击次数已用完，请结束回合。")
		return
	if board_tiles[index].is_empty():
		_update_ui("空位没有硬币，不会触发金币和伤害。")
		return

	manual_clicks_left -= 1
	var result := _trigger_tile(index, true, 0)
	best_chain_this_round = max(best_chain_this_round, int(result["triggered"]))
	if int(result["triggered"]) > 1:
		_float_slot_text(index, "总计 +%d金 / %d连" % [int(result["coins"]), int(result["triggered"])], GOLD)
	_update_ui("手动触发 %d 枚硬币，获得 %d 金币。" % [result["triggered"], result["coins"]])


func _trigger_tile(index: int, is_manual: bool, depth: int) -> Dictionary:
	if depth > 80 or index < 0 or index >= TOTAL_SLOTS or board_tiles[index].is_empty():
		return {"coins": 0, "triggered": 0}

	var tile := board_tiles[index]
	if int(tile["clicks_left"]) <= 0:
		return {"coins": 0, "triggered": 0}
	if bool(tile.get("broken", false)):
		return {"coins": 0, "triggered": 0}
	if int(tile.get("locked_turns", 0)) > 0:
		_update_ui("%s 被敌人锁住，本回合无法触发。" % TILE_TYPES[String(tile["type"])]["name"])
		return {"coins": 0, "triggered": 0}

	var level := int(tile.get("level", 1))
	tile["clicks_left"] = int(tile["clicks_left"]) - 1
	var success_chance := _coin_success_chance(String(tile["type"]), level)
	if int(tile.get("jammed_turns", 0)) > 0:
		success_chance = max(0.05, success_chance - 0.20)
	if int(tile.get("polluted_turns", 0)) > 0:
		success_chance = max(0.05, success_chance - 0.10)
	var is_heads := rng.randf() < success_chance
	var outcome := _resolve_coin_flip(tile, is_heads, is_manual, index)
	tile = outcome["tile"]
	tile["history"].append(bool(outcome["success"]))
	board_tiles[index] = tile

	var tile_type := String(tile["type"])
	var coins := int(outcome["coins"])
	var damage := int(outcome["damage"])
	if coins > 0 and int(tile.get("steal_mark_turns", 0)) > 0:
		var stolen_by_mark: int = max(1, int(ceil(float(coins) * 0.5)))
		coins = max(0, coins - stolen_by_mark)
	if coins > 0 and int(tile.get("polluted_turns", 0)) > 0:
		coins = max(0, coins - 1)
		player_health = max(0, player_health - 1)
	if coins > 0:
		game_state.coins += coins
		round_collected += coins
	if damage > 0:
		round_damage += damage
		_deal_damage_to_enemies(damage)

	if owned_relics.has("bloom_crown") and int(outcome["heal"]) > 0:
		outcome["heal"] = int(outcome["heal"]) + 1
	if int(outcome["heal"]) > 0:
		player_health = min(MAX_HEALTH, player_health + int(outcome["heal"]))
	if int(outcome["manual_bonus"]) > 0:
		manual_clicks_left += int(outcome["manual_bonus"])
	if int(outcome["self_damage"]) > 0:
		var self_damage := _apply_self_damage_reduction(int(outcome["self_damage"]))
		player_health = max(0, player_health - self_damage)
		if player_health <= 0:
			_show_run_end(false, "你被硬币的代价吞没了。")

	if bool(outcome["success"]):
		_play_sfx("coin")
	elif is_manual:
		round_failures += 1
		_apply_failure_backlash()
		_play_sfx("miss")
	elif depth <= 2:
		_play_sfx("chain")

	_refresh_slot(index)
	_flash_slot(index, COIN_FLASH if bool(outcome["success"]) else GREEN)
	_float_slot_text(index, _outcome_feedback_text(outcome, coins, damage, is_heads), COIN_FLASH if bool(outcome["success"]) else GREEN)

	var triggered := 1
	for direction in outcome["directions"]:
		if rng.randf() >= float(outcome["chain_chance"]):
			continue
		var next_index := _neighbor_index(index, direction)
		if next_index == -1:
			continue
		_float_slot_text(next_index, "连锁", BLUE)
		var result := _trigger_tile(next_index, false, depth + 1)
		coins += int(result["coins"])
		triggered += int(result["triggered"])

	return {"coins": coins, "triggered": triggered}


func _coin_success_chance(tile_type: String, level: int) -> float:
	var relic_bonus := 0.08 if owned_relics.has("loaded_die") and (wager_mode == "greedy" or wager_mode == "all_in") else 0.0
	if owned_relics.has("silver_lens"):
		relic_bonus += 0.04
	match tile_type:
		"lucky":
			return clampf(0.62 + relic_bonus + float(level - 1) * 0.06, 0.05, 0.95)
		"reverse":
			return clampf(0.45 + relic_bonus, 0.05, 0.95)
		"glass":
			return clampf(0.55 + relic_bonus, 0.05, 0.95)
		"spirit":
			return clampf(0.42 + relic_bonus, 0.05, 0.95)
		"shield":
			return clampf(0.64 + relic_bonus + float(level - 1) * 0.04, 0.05, 0.95)
		"compass":
			return clampf(0.58 + relic_bonus, 0.05, 0.95)
		"forge":
			return clampf(0.48 + relic_bonus + float(level - 1) * 0.05, 0.05, 0.95)
		"echo":
			return clampf(0.50 + relic_bonus + float(level - 1) * 0.05, 0.05, 0.95)
		"debt_coin":
			return clampf(0.52 + relic_bonus, 0.05, 0.95)
		"arc":
			return clampf(0.56 + relic_bonus + float(level - 1) * 0.04, 0.05, 0.95)
		"bloom":
			return clampf(0.58 + relic_bonus, 0.05, 0.95)
		"titan":
			return clampf(0.38 + relic_bonus + float(level - 1) * 0.06, 0.05, 0.95)
		"hourglass":
			return clampf(0.52 + relic_bonus, 0.05, 0.95)
		"joker":
			return clampf(0.50 + relic_bonus, 0.05, 0.95)
		"anchor":
			return clampf(0.60 + relic_bonus, 0.05, 0.95)
		_:
			return clampf(0.5 + relic_bonus, 0.05, 0.95)


func _resolve_coin_flip(tile: Dictionary, is_heads: bool, is_manual: bool, slot_index: int) -> Dictionary:
	var tile_type := String(tile["type"])
	var level := int(tile.get("level", 1))
	var base_coins := _tile_coin_value(tile_type, level)
	var base_damage := _tile_damage_value(tile_type, level)
	var result := {
		"tile": tile,
		"success": is_heads,
		"coins": base_coins if is_heads else 0,
		"damage": base_damage if is_heads else 0,
		"heal": 0,
		"manual_bonus": 0,
		"self_damage": 0,
		"directions": TILE_TYPES[tile_type]["directions"],
		"chain_chance": _tile_trigger_chance(tile_type, level) if is_heads else 0.0
	}

	match tile_type:
		"lucky":
			if is_heads:
				result["heal"] = 1
				result["chain_chance"] = min(0.95, float(result["chain_chance"]) + 0.12)
			else:
				result["success"] = true
				result["coins"] = 0
				result["damage"] = 0
				result["manual_bonus"] = 1
				result["chain_chance"] = 0.0
		"reverse":
			if is_heads:
				result["coins"] = max(1, int(floor(float(base_coins) * 0.5)))
				result["damage"] = max(1, int(floor(float(base_damage) * 0.5)))
				result["chain_chance"] = 0.0
			else:
				result["success"] = true
				result["coins"] = base_coins + 2 + level
				result["damage"] = base_damage + 2 + level
				result["chain_chance"] = min(0.95, _tile_trigger_chance(tile_type, level) + 0.18)
		"glass":
			if is_heads:
				result["coins"] = base_coins + 3 + level
				result["damage"] = base_damage + 3 + level
				if owned_relics.has("glass_hammer"):
					result["coins"] = int(result["coins"]) + 2
					result["damage"] = int(result["damage"]) + 2
			else:
				result["success"] = false
				result["coins"] = 0
				result["damage"] = 1 + level
				result["self_damage"] = 1
				result["chain_chance"] = 0.0
				if is_manual and rng.randf() < 0.35:
					tile["broken"] = true
					result["tile"] = tile
		"stock":
			var stock_step := int(tile.get("stock_step", 0))
			if is_heads:
				stock_step = min(6, stock_step + 1)
				tile["stock_step"] = stock_step
				result["tile"] = tile
				result["coins"] = base_coins + stock_step * (1 + level)
				result["damage"] = max(1, base_damage - 1)
			else:
				stock_step = max(-3, stock_step - 1)
				tile["stock_step"] = stock_step
				result["tile"] = tile
				result["success"] = true
				result["coins"] = 1
				result["damage"] = 0
				result["chain_chance"] = 0.0
		"vampire":
			if is_heads:
				result["coins"] = max(0, base_coins - 1)
				result["damage"] = base_damage + 2 + level
				result["heal"] = 1 + int(level >= 3)
			else:
				result["success"] = true
				result["coins"] = 0
				result["damage"] = base_damage + level
				result["self_damage"] = 1
				result["chain_chance"] = 0.0
		"spirit":
			if is_heads:
				result["coins"] = base_coins
				result["damage"] = base_damage
				result["manual_bonus"] = 1
				result["chain_chance"] = min(0.95, _tile_trigger_chance(tile_type, level) + 0.10)
			else:
				result["success"] = true
				result["coins"] = 0
				result["damage"] = 1
				result["chain_chance"] = max(0.15, _tile_trigger_chance(tile_type, level) - 0.15)
		"angel":
			if is_heads:
				result["coins"] = max(0, base_coins - 1)
				result["damage"] = base_damage
				result["heal"] = 2 + int(level >= 3)
				tile = _cleanse_tile(tile)
				result["tile"] = tile
			else:
				result["success"] = true
				result["coins"] = 1
				result["damage"] = 0
				result["heal"] = 1
				result["chain_chance"] = 0.0
				_cleanse_neighbors(slot_index)
		"demon":
			result["self_damage"] = int(result["self_damage"]) + 1
			if is_heads:
				result["coins"] = base_coins + 4 + level
				result["damage"] = base_damage + 5 + level
			else:
				result["success"] = true
				result["coins"] = 0
				result["damage"] = base_damage + 3
				tile["polluted_turns"] = max(1, int(tile.get("polluted_turns", 0)))
				result["tile"] = tile
				result["chain_chance"] = 0.0
		"mirror":
			var neighbor_count := _neighbor_coin_count(slot_index)
			if is_heads:
				result["coins"] = base_coins + neighbor_count
				result["damage"] = base_damage + neighbor_count
				result["chain_chance"] = min(0.95, _tile_trigger_chance(tile_type, level) + 0.08 * neighbor_count)
			else:
				result["success"] = true
				result["coins"] = 1
				result["damage"] = neighbor_count
				result["chain_chance"] = max(0.25, _tile_trigger_chance(tile_type, level) - 0.10)
		"magnet":
			var adjacent := _neighbor_coin_count(slot_index)
			if is_heads:
				result["coins"] = base_coins + adjacent
				result["damage"] = max(1, base_damage - 1)
			else:
				result["success"] = true
				result["coins"] = adjacent
				result["damage"] = 1
				result["chain_chance"] = min(0.85, _tile_trigger_chance(tile_type, level) + 0.12)
		"echo":
			var history_size := Array(tile.get("history", [])).size()
			if is_heads:
				result["coins"] = base_coins + min(6, history_size)
				result["damage"] = base_damage + min(4, int(floor(float(history_size) * 0.5)))
				result["chain_chance"] = min(0.95, _tile_trigger_chance(tile_type, level) + 0.04 * history_size)
			else:
				result["success"] = true
				result["coins"] = 0
				result["damage"] = 1
				result["manual_bonus"] = 1
				result["chain_chance"] = 0.20
		"shield":
			if is_heads:
				result["coins"] = base_coins
				result["damage"] = max(1, base_damage - 1)
				result["heal"] = 1 + int(level >= 3)
			else:
				result["success"] = true
				result["coins"] = 1
				result["damage"] = 0
				tile = _cleanse_tile(tile)
				result["tile"] = tile
				result["chain_chance"] = 0.0
		"forge":
			var forge_heat := int(tile.get("forge_heat", 0))
			var forge_max := 7 if owned_relics.has("furnace_core") else 5
			if is_heads:
				forge_heat = min(forge_max, forge_heat + 1)
				tile["forge_heat"] = forge_heat
				result["tile"] = tile
				result["coins"] = base_coins + forge_heat * (1 + int(level >= 2))
				result["damage"] = base_damage + forge_heat
			else:
				forge_heat = max(0, forge_heat - 1)
				tile["forge_heat"] = forge_heat
				result["tile"] = tile
				result["success"] = true
				result["coins"] = 1 + int(level >= 2)
				result["damage"] = 0
				result["chain_chance"] = 0.0
		"compass":
			var empty_neighbors := _neighbor_empty_count(slot_index)
			if is_heads:
				result["coins"] = base_coins + empty_neighbors
				result["damage"] = base_damage
				result["chain_chance"] = min(0.95, _tile_trigger_chance(tile_type, level) + 0.10)
			else:
				result["success"] = true
				result["coins"] = 1
				result["damage"] = 0
				result["chain_chance"] = max(0.30, _tile_trigger_chance(tile_type, level) - 0.10)
		"debt_coin":
			if is_heads:
				result["coins"] = base_coins + 3 + level
				result["damage"] = max(1, base_damage - 1)
			else:
				result["success"] = true
				result["coins"] = base_coins + 1
				result["damage"] = 0
				tile["debt_marks"] = int(tile.get("debt_marks", 0)) + 1
				result["tile"] = tile
				result["chain_chance"] = 0.0
		"arc":
			var depth_bonus: int = min(5, int(slot_index / GRID_COLUMNS))
			if is_heads:
				result["coins"] = base_coins + depth_bonus
				result["damage"] = base_damage + int(depth_bonus >= 3)
				result["chain_chance"] = min(0.95, _tile_trigger_chance(tile_type, level) + 0.12)
			else:
				result["success"] = true
				result["coins"] = 1
				result["damage"] = 0
				result["chain_chance"] = max(0.25, _tile_trigger_chance(tile_type, level) - 0.12)
		"bloom":
			var bloom_growth := int(tile.get("bloom_growth", 0))
			if is_heads:
				bloom_growth = min(5, bloom_growth + 1)
				tile["bloom_growth"] = bloom_growth
				result["tile"] = tile
				result["coins"] = max(0, base_coins - 1) + bloom_growth
				result["damage"] = max(1, base_damage - 1)
				result["heal"] = 1 + int(bloom_growth >= 3)
			else:
				result["success"] = true
				result["coins"] = max(1, bloom_growth)
				result["damage"] = 0
				result["heal"] = 1
				tile["bloom_growth"] = max(0, bloom_growth - 1)
				result["tile"] = tile
				result["chain_chance"] = 0.0
		"titan":
			if is_heads:
				result["coins"] = base_coins + 6 + level * 2
				result["damage"] = base_damage + 8 + level * 2
				result["chain_chance"] = 0.0
			else:
				result["success"] = true
				result["coins"] = 0
				result["damage"] = max(2, base_damage)
				tile["locked_turns"] = max(1, int(tile.get("locked_turns", 0)))
				result["tile"] = tile
				result["chain_chance"] = 0.0
		"hourglass":
			if is_heads:
				result["coins"] = base_coins
				result["damage"] = base_damage
				result["manual_bonus"] = 1
				tile["clicks_left"] = int(tile.get("clicks_left", 0)) + 1
				result["tile"] = tile
			else:
				result["success"] = true
				result["coins"] = 2 + level
				result["damage"] = 0
				result["chain_chance"] = 0.0
		"joker":
			var joker_bonus := 2 if owned_relics.has("joker_mask") else 0
			var swing := rng.randi_range(0, 3 + level + joker_bonus)
			result["success"] = true
			if is_heads:
				result["coins"] = base_coins + swing
				result["damage"] = base_damage + rng.randi_range(0, 2 + level + joker_bonus)
				result["chain_chance"] = min(0.95, _tile_trigger_chance(tile_type, level) + 0.05 * swing)
			else:
				result["coins"] = rng.randi_range(0, 2 + level)
				result["damage"] = rng.randi_range(0, 3 + level)
				result["manual_bonus"] = 1 if swing >= 3 else 0
				result["chain_chance"] = 0.20
		"anchor":
			if is_heads:
				result["coins"] = base_coins
				result["damage"] = max(1, base_damage - 1)
				tile["jammed_turns"] = 0
				tile["steal_mark_turns"] = 0
				result["tile"] = tile
			else:
				result["success"] = true
				result["coins"] = 0
				result["damage"] = 0
				result["heal"] = 2
				tile["locked_turns"] = max(1, int(tile.get("locked_turns", 0)))
				result["tile"] = tile
				result["chain_chance"] = 0.0

	if bool(tile.get("broken", false)):
		result["directions"] = []
		result["chain_chance"] = 0.0
	return result


func _cleanse_tile(tile: Dictionary) -> Dictionary:
	for key in ["locked_turns", "jammed_turns", "polluted_turns", "steal_mark_turns"]:
		tile[key] = 0
	tile["broken"] = false
	return tile


func _neighbor_coin_count(index: int) -> int:
	var count := 0
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var next_index := _neighbor_index(index, direction)
		if next_index != -1 and not board_tiles[next_index].is_empty():
			count += 1
	return count


func _neighbor_empty_count(index: int) -> int:
	var count := 0
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var next_index := _neighbor_index(index, direction)
		if next_index != -1 and board_tiles[next_index].is_empty():
			count += 1
	return count


func _board_debt_tax() -> int:
	var debt := 0
	for tile in board_tiles:
		if typeof(tile) == TYPE_DICTIONARY and not tile.is_empty():
			debt += int(tile.get("debt_marks", 0))
	if owned_relics.has("debt_ledger"):
		debt = int(ceil(float(debt) * 0.5))
	return debt


func _cleanse_neighbors(index: int) -> void:
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var next_index := _neighbor_index(index, direction)
		if next_index != -1 and not board_tiles[next_index].is_empty():
			board_tiles[next_index] = _cleanse_tile(board_tiles[next_index])


func _deal_damage_to_enemies(amount: int) -> void:
	var remaining := amount
	var total_dealt := 0
	var total_absorbed := 0
	var killed_count := 0
	var total_reward := 0
	var last_killed_name := ""
	while remaining > 0 and enemies.size() > 0:
		var enemy := enemies[0]
		var shield := int(enemy.get("shield", 0))
		var absorbed: int = min(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
		total_absorbed += absorbed
		enemy["shield"] = shield

		if remaining <= 0:
			enemies[0] = enemy
			break

		var dealt: int = min(int(enemy["hp"]), remaining)
		enemy["hp"] = int(enemy["hp"]) - dealt
		remaining -= dealt
		total_dealt += dealt

		if int(enemy["hp"]) <= 0:
			var reward := int(enemy.get("reward", 0))
			if owned_relics.has("bounty_contract"):
				reward = int(ceil(float(reward) * 1.25))
			game_state.coins += reward
			round_collected += reward
			run_kills += 1
			killed_count += 1
			total_reward += reward
			last_killed_name = String(enemy["name"])
			enemies.remove_at(0)
			_update_ui("击败 %s，获得 %d 金币赏金。" % [enemy["name"], reward])
			_play_sfx("settle")
		else:
			enemies[0] = enemy

	if killed_count > 0:
		var kill_text := "击破 %s  +%d 金币赏金" % [last_killed_name, total_reward] if killed_count == 1 else "连破 %d 名敌人  +%d 金币赏金" % [killed_count, total_reward]
		_show_combat_banner(kill_text, GOLD)
		_pulse_stat_label(enemy_label, GOLD)
	elif total_dealt > 0 or total_absorbed > 0:
		var parts: Array[String] = []
		if total_dealt > 0:
			parts.append("敌人受击 %d" % total_dealt)
		if total_absorbed > 0:
			parts.append("护盾吸收 %d" % total_absorbed)
		_show_combat_banner(" / ".join(parts), Color(1.0, 0.78, 0.28))
		_pulse_stat_label(enemy_label, Color(1.0, 0.78, 0.28))


func _apply_failure_backlash() -> void:
	var damage := int(WAGER_MODES[wager_mode]["fail_damage"])
	if damage <= 0:
		return
	damage = _apply_self_damage_reduction(damage)
	player_health -= damage
	if player_health <= 0:
		player_health = 0
		_play_sfx("error")
		_show_run_end(false, "你在高风险下注中透支了命运。")


func _apply_self_damage_reduction(amount: int) -> int:
	if amount <= 0:
		return 0
	if owned_relics.has("red_heart") and not round_self_damage_blocked:
		round_self_damage_blocked = true
		return max(0, amount - 1)
	return amount


func _neighbor_index(index: int, direction: Vector2i) -> int:
	var x := index % GRID_COLUMNS
	var y := index / GRID_COLUMNS
	var nx := x + direction.x
	var ny := y + direction.y
	if nx < 0 or nx >= GRID_COLUMNS or ny < 0 or ny >= GRID_ROWS:
		return -1
	return ny * GRID_COLUMNS + nx


func _on_action_button_pressed() -> void:
	if is_intermission:
		_start_round()
	else:
		_end_round()


func _start_round() -> void:
	is_intermission = false
	wager_select.disabled = true
	_rebuild_bag_manager()
	_update_tutorial()
	manual_clicks_left = _round_manual_click_max()
	round_collected = 0
	round_damage = 0
	round_failures = 0
	round_self_damage_blocked = false
	best_chain_this_round = 0
	if enemies.is_empty():
		_spawn_round_enemies()
	_show_boss_warning_if_needed()
	if wager_mode == "greedy" or wager_mode == "all_in":
		_show_combat_banner(_wager_warning_text(), Color(1.0, 0.45, 0.25))
		_pulse_stat_label(state_label, Color(1.0, 0.30, 0.20))
	for index in range(TOTAL_SLOTS):
		if not board_tiles[index].is_empty():
			board_tiles[index]["clicks_left"] = _round_tile_click_max(board_tiles[index])
			board_tiles[index]["history"] = []
			_refresh_slot(index)
	_update_ui("回合开始：%s。当前下注：%s。先清敌人还是贪金币，交给你。" % [current_event["name"], WAGER_MODES[wager_mode]["name"]])


func _end_round() -> void:
	var due := _round_quota_due()
	var enemy_report := _enemy_phase()
	run_total_collected += round_collected
	run_total_damage += round_damage
	run_best_chain = max(run_best_chain, best_chain_this_round)
	last_round_summary = {
		"round": game_state.current_round,
		"collected": round_collected,
		"damage": round_damage,
		"failures": round_failures,
		"due": due,
		"best_chain": best_chain_this_round,
		"event": current_event.get("name", ""),
		"enemy_report": enemy_report
	}
	if player_health <= 0:
		_update_ui(enemy_report)
		return

	game_state.coins -= due
	if game_state.coins < 0:
		_play_sfx("error")
		_update_ui("金币不足，游戏结束。")
		_show_run_end(false, "金币不足以支付本轮收取。")
		return

	if game_state.current_round >= FINAL_ROUND and enemies.is_empty():
		_show_run_end(true, "你击败了命运庄家，暂时赢回了自己的命运。")
		is_intermission = true
		wager_select.disabled = false
		_update_ui("胜利！当前版本的 24 回合挑战已完成。")
		return

	game_state.current_round += 1
	quota = _next_quota(quota)
	game_state.required_coins = quota
	is_intermission = true
	wager_select.disabled = false
	_roll_shop_offers()
	_roll_relic_offers()
	_roll_consumable_offers()
	_roll_curse_offers()
	_pick_round_event()
	_spawn_round_enemies()
	_draw_hand()
	manual_clicks_left = _round_manual_click_max()
	_rebuild_shop_palette()
	_rebuild_market()
	_rebuild_relic_market()
	_rebuild_consumable_market()
	_rebuild_curse_market()
	_rebuild_bag_manager()
	for index in range(TOTAL_SLOTS):
		if not board_tiles[index].is_empty():
			board_tiles[index]["clicks_left"] = _round_tile_click_max(board_tiles[index])
			board_tiles[index]["history"] = []
			_refresh_slot(index)
	_show_settlement()
	_play_sfx("settle")
	_update_tutorial()
	_update_ui("%s 结算完成并收取 %d 金币。新事件：%s。商店已刷新。" % [enemy_report, due, current_event["name"]])


func _next_quota(current: int) -> int:
	if game_state == null:
		return max(current + 1, int(ceil(float(current) * 1.18)))
	return _quota_for_round(int(game_state.current_round))


func _restart_game() -> void:
	game_state.coins = _difficulty_starting_coins()
	game_state.current_round = 1
	player_health = STARTING_HEALTH
	run_total_collected = 0
	run_total_damage = 0
	run_kills = 0
	run_best_chain = 0
	tutorial_enabled = true
	removed_from_bag = 0
	locked_hand_tiles.clear()
	owned_relics.clear()
	active_curses.clear()
	relic_offer_ids.clear()
	consumable_offer_ids.clear()
	curse_offer_ids.clear()
	_initialize_coin_bag()
	_draw_hand()
	quota = STARTING_QUOTA
	game_state.required_coins = quota
	is_intermission = true
	wager_mode = "standard"
	if wager_select != null:
		wager_select.selected = WAGER_ORDER.find(wager_mode)
		wager_select.disabled = false
	if starter_select != null:
		starter_select.selected = STARTER_BAG_ORDER.find(starter_bag_id)
		starter_select.disabled = false
	if difficulty_select != null:
		difficulty_select.selected = DIFFICULTY_ORDER.find(difficulty_id)
	_roll_shop_offers()
	_roll_relic_offers()
	_roll_consumable_offers()
	_roll_curse_offers()
	_pick_round_event()
	_spawn_round_enemies()
	manual_clicks_left = _round_manual_click_max()
	round_collected = 0
	round_damage = 0
	round_failures = 0
	best_chain_this_round = 0
	game_over_dialog.title = "游戏结束"
	for index in range(TOTAL_SLOTS):
		board_tiles[index] = {}
		_refresh_slot(index)
	_rebuild_shop_palette()
	_rebuild_market()
	_rebuild_relic_market()
	_rebuild_consumable_market()
	_rebuild_curse_market()
	_rebuild_bag_manager()
	_update_tutorial()
	_update_ui("已重新开始。准备阶段：拖拽本回合手牌上阵，商店购买会加入命运袋。")


func _refresh_slot(index: int) -> void:
	var view := slot_views[index]
	var slot: PanelContainer = view["slot"]
	var icon: TextureRect = view["icon"]
	var history: HBoxContainer = view["history"]
	var info: Label = view["info"]
	var button: Button = view["button"]
	var tile := board_tiles[index]

	for child in history.get_children():
		child.queue_free()

	if tile.is_empty():
		icon.texture = null
		info.text = "空位"
		button.disabled = false
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_intermission else Control.MOUSE_FILTER_STOP
		button.tooltip_text = "准备阶段可拖入手牌硬币。回合中空位不会触发。"
		var highlight_empty := _should_highlight_empty_slot(index)
		slot.add_theme_stylebox_override("panel", style(SLOT_COLOR.lightened(0.08) if highlight_empty else SLOT_COLOR, 8, GOLD.lightened(0.16) if highlight_empty else Color(0.34, 0.55, 0.46), 3 if highlight_empty else 2))
		return

	var tile_type := String(tile["type"])
	var config: Dictionary = TILE_TYPES[tile_type]
	icon.texture = TILE_TEXTURES[tile_type]
	var level := int(tile.get("level", 1))
	var max_clicks := _round_tile_click_max(tile)
	var state_text := _tile_state_text(tile)
	info.text = "%s Lv.%d  %d/%d%s" % [config["name"], level, int(tile["clicks_left"]), max_clicks, state_text]
	button.disabled = is_intermission
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_intermission else Control.MOUSE_FILTER_STOP
	button.tooltip_text = "%s\n%s\nLv.%d 正面金币 %d，正面伤害 %d，正面概率 %d%%，方向触发率 %d%%。\n剩余触发次数 %d/%d。同类手牌拖到这里可升级。" % [
		config["tip"],
		_tile_state_description(tile),
		level,
		_tile_coin_value(tile_type, level),
		_tile_damage_value(tile_type, level),
		int(round(_coin_success_chance(tile_type, level) * 100.0)),
		int(round(_tile_trigger_chance(tile_type, level) * 100.0)),
		int(tile["clicks_left"]),
		max_clicks
	]
	var border := _rarity_color(String(config["rarity"])).lightened(0.10 * float(level - 1))
	var highlight_coin := _should_highlight_coin_slot(index)
	var slot_fill := Color(0.13, 0.16, 0.16).lightened(0.06) if highlight_coin else Color(0.13, 0.16, 0.16)
	var slot_border := GOLD.lightened(0.15) if highlight_coin else (border if not is_intermission else border.darkened(0.18))
	var slot_width := 4 if highlight_coin else 2 + level - 1
	slot.add_theme_stylebox_override("panel", style(slot_fill, 8, slot_border, slot_width))

	for item in tile["history"]:
		var mark := Label.new()
		mark.custom_minimum_size = Vector2(16, 16)
		mark.text = "正" if bool(item) else "反"
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.add_theme_font_size_override("font_size", 12)
		mark.add_theme_color_override("font_color", COIN_FLASH if bool(item) else GREEN)
		history.add_child(mark)


func _flash_slot(index: int, color: Color) -> void:
	var slot: PanelContainer = slot_views[index]["slot"]
	slot.pivot_offset = slot.size * 0.5
	slot.add_theme_stylebox_override("panel", style(color, 8, Color.WHITE, 2))
	var tween := create_tween()
	tween.tween_property(slot, "scale", Vector2(1.04, 1.04), 0.08)
	tween.tween_property(slot, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(max(0.0, FLASH_SECONDS - 0.20))
	tween.tween_callback(_refresh_slot.bind(index))


func _float_slot_text(index: int, text: String, color: Color) -> void:
	if text == "" or index < 0 or index >= slot_views.size():
		return
	var layer: Control = slot_views[index]["fx"]
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02))
	label.add_theme_constant_override("outline_size", 4)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.position.y = 14
	layer.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", -20.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.12)
	tween.tween_callback(label.queue_free)


func _show_combat_banner(text: String, color: Color = GOLD) -> void:
	if combat_feed_label == null or text == "":
		return
	combat_feed_label.text = text
	combat_feed_label.modulate = Color.WHITE
	combat_feed_label.add_theme_color_override("font_color", color)
	combat_feed_label.scale = Vector2(1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(combat_feed_label, "scale", Vector2(1.04, 1.04), 0.08)
	tween.tween_property(combat_feed_label, "scale", Vector2.ONE, 0.12)


func _pulse_stat_label(label: Label, color: Color) -> void:
	if label == null:
		return
	var original := label.modulate
	label.modulate = color
	label.pivot_offset = label.size * 0.5
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(label, "scale", Vector2.ONE, 0.12)
	tween.tween_property(label, "modulate", original, 0.25)


func _show_boss_warning_if_needed() -> void:
	for enemy in enemies:
		if _is_boss_type(String(enemy["type"])):
			_show_combat_banner("Boss 出场：%s。%s" % [enemy["name"], enemy.get("intent", "")], Color(1.0, 0.28, 0.20))
			_pulse_stat_label(enemy_label, Color(1.0, 0.28, 0.20))
			return


func _is_boss_type(enemy_type: String) -> bool:
	return enemy_type == "lock_boss" or enemy_type == "market_boss" or enemy_type == "debt_boss" or enemy_type == "mirror_boss" or enemy_type == "banker"


func _wager_warning_text() -> String:
	if wager_mode == "all_in":
		return "梭哈警告：爆发极高，但每次手动失败都会重创生命。"
	if wager_mode == "greedy":
		return "贪婪警告：收益提高，手动失败会扣生命，敌人也更凶。"
	return ""


func _outcome_feedback_text(outcome: Dictionary, coins: int, damage: int, is_heads: bool) -> String:
	var parts: Array[String] = ["正面" if is_heads else "反面"]
	if not bool(outcome["success"]):
		parts.append("失手")
	if coins > 0:
		parts.append("+%d金" % coins)
	if damage > 0:
		parts.append("%d伤" % damage)
	if int(outcome["heal"]) > 0:
		parts.append("+%d生命" % int(outcome["heal"]))
	if int(outcome["manual_bonus"]) > 0:
		parts.append("+%d手动" % int(outcome["manual_bonus"]))
	if int(outcome["self_damage"]) > 0:
		parts.append("-%d生命" % int(outcome["self_damage"]))
	if parts.size() == 1:
		parts.append("无收益")
	return " ".join(parts)


func _tile_state_text(tile: Dictionary) -> String:
	var tile_type := String(tile["type"])
	if bool(tile.get("broken", false)):
		return "  破碎"
	var flags: Array[String] = []
	if int(tile.get("locked_turns", 0)) > 0:
		flags.append("锁")
	if int(tile.get("jammed_turns", 0)) > 0:
		flags.append("扰")
	if int(tile.get("polluted_turns", 0)) > 0:
		flags.append("污")
	if int(tile.get("steal_mark_turns", 0)) > 0:
		flags.append("偷")
	if tile_type == "stock":
		var stock_step := int(tile.get("stock_step", 0))
		if stock_step > 0:
			flags.append("+%d" % stock_step)
		if stock_step < 0:
			flags.append("%d" % stock_step)
	if tile_type == "forge":
		var forge_heat := int(tile.get("forge_heat", 0))
		if forge_heat > 0:
			flags.append("热%d" % forge_heat)
	if tile_type == "debt_coin":
		var debt_marks := int(tile.get("debt_marks", 0))
		if debt_marks > 0:
			flags.append("债%d" % debt_marks)
	if tile_type == "bloom":
		var bloom_growth := int(tile.get("bloom_growth", 0))
		if bloom_growth > 0:
			flags.append("花%d" % bloom_growth)
	return "  " + "/".join(flags) if not flags.is_empty() else ""


func _tile_state_description(tile: Dictionary) -> String:
	var tile_type := String(tile["type"])
	if bool(tile.get("broken", false)):
		return "状态：破碎，无法继续触发。回收或升级替换它。"
	var states: Array[String] = []
	if int(tile.get("locked_turns", 0)) > 0:
		states.append("锁定：本回合无法触发")
	if int(tile.get("jammed_turns", 0)) > 0:
		states.append("干扰：正面概率 -20%")
	if int(tile.get("polluted_turns", 0)) > 0:
		states.append("污染：正面概率 -10%，触发收益 -1 并扣 1 生命")
	if int(tile.get("steal_mark_turns", 0)) > 0:
		states.append("偷取标记：收益会被偷走一半")
	if tile_type == "stock":
		var stock_step := int(tile.get("stock_step", 0))
		states.append("股票涨跌 %d 层，正面会继续涨，反面会回落" % stock_step)
	if tile_type == "forge":
		states.append("熔炉热度 %d 层，正面会升温并提高后续收益" % int(tile.get("forge_heat", 0)))
	if tile_type == "debt_coin":
		states.append("债务标记 %d 层，每层会让本回合收取 +1" % int(tile.get("debt_marks", 0)))
	if tile_type == "bloom":
		states.append("花层 %d 层，正面会成长并提高治疗/收益" % int(tile.get("bloom_growth", 0)))
	if states.is_empty():
		return "状态：正常。"
	return "状态：" + "；".join(states) + "。"


func _update_ui(message: String = "") -> void:
	coin_label.text = "金币\n%d" % game_state.coins
	health_label.text = "生命\n%d/%d" % [player_health, MAX_HEALTH]
	round_label.text = "回合\n%d" % game_state.current_round
	quota_label.text = "收取\n%d" % quota
	clicks_label.text = "手动\n%d/%d" % [manual_clicks_left, _round_manual_click_max()]
	enemy_label.text = "敌人\n%d" % enemies.size()
	state_label.text = "状态\n%s" % ("准备" if is_intermission else "回合中")
	if event_icon_rect != null:
		event_icon_rect.texture = _event_texture(current_event)
		event_icon_rect.tooltip_text = "%s\n%s" % [current_event.get("name", ""), current_event.get("desc", "")]
	progress_label.text = "事件：%s - %s    下注：%s    节奏：%s    命运袋：%d    遗物：%d    手牌：%s\n本轮金币：%d    伤害：%d    结束收取：%d    最高连锁：%d    敌人：%s" % [
		current_event.get("name", ""),
		current_event.get("desc", ""),
		WAGER_MODES[wager_mode]["name"],
		_director_label(),
		coin_bag.size(),
		owned_relics.size(),
		_hand_summary(),
		round_collected,
		round_damage,
		_round_quota_due(),
		best_chain_this_round,
		_enemy_summary()
	]
	notice_label.text = message
	action_button.text = "开始下一回合" if is_intermission else "结束回合"
	delete_zone.modulate = Color.WHITE if is_intermission else Color(0.55, 0.55, 0.55)
	if wager_select != null:
		wager_select.disabled = not is_intermission
	if starter_select != null:
		starter_select.disabled = not (is_intermission and game_state.current_round == 1 and _placed_tile_count() == 0)
	_update_tutorial()
	_rebuild_shop_palette()
	_rebuild_bag_manager()
	_rebuild_relic_market()
	_rebuild_consumable_market()
	_rebuild_curse_market()
	_rebuild_enemy_panel()

	for index in range(TOTAL_SLOTS):
		_refresh_slot(index)


func tile_symbol(tile_type: String) -> String:
	return String(TILE_TYPES[tile_type]["symbol"])
