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


class MoonlitBackdrop:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var rect := get_rect()
		var width := rect.size.x
		var height := rect.size.y
		draw_rect(Rect2(Vector2.ZERO, rect.size), Color(0.012, 0.016, 0.025))
		for row in range(24):
			var t := float(row) / 23.0
			var y := t * height
			var row_color := Color(0.018, 0.026, 0.040).lerp(Color(0.030, 0.039, 0.052), t)
			draw_rect(Rect2(0, y, width, height / 24.0 + 1.0), row_color)

		var center := rect.size * 0.5
		var moon_center := center + Vector2(width * 0.25, -height * 0.24)
		draw_circle(moon_center, min(width, height) * 0.28, Color(0.55, 0.70, 0.78, 0.095))
		draw_circle(moon_center + Vector2(width * 0.045, -height * 0.018), min(width, height) * 0.22, Color(0.012, 0.016, 0.025, 0.70))

		for x in range(-220, int(width) + 260, 112):
			draw_line(Vector2(x, 0), Vector2(x + height * 0.22, height), Color(0.46, 0.62, 0.72, 0.070), 1.0)
		for y in range(36, int(height), 88):
			draw_line(Vector2(0, y), Vector2(width, y - width * 0.05), Color(0.75, 0.86, 0.88, 0.042), 1.0)
		for x in range(0, int(width), 196):
			draw_line(Vector2(x, 0), Vector2(x, height), Color(0.72, 0.12, 0.18, 0.035), 2.0)
		for ring in range(11):
			var alpha := 0.025 + float(ring) * 0.010
			var pad := float(ring) * 44.0
			draw_rect(Rect2(Vector2(pad, pad), rect.size - Vector2(pad * 2.0, pad * 2.0)), Color(0.0, 0.0, 0.0, alpha), false, 20.0)
		draw_line(Vector2(width * 0.08, height * 0.86), Vector2(width * 0.92, height * 0.76), Color(0.86, 0.12, 0.18, 0.085), 3.0)
		draw_line(Vector2(width * 0.10, height * 0.90), Vector2(width * 0.80, height * 0.83), Color(0.58, 0.80, 0.86, 0.070), 2.0)


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
const WINDOW_SIZE_OPTIONS := [Vector2i(1280, 800), Vector2i(1600, 1000), Vector2i(1920, 1080)]
const LANGUAGE_OPTIONS := {"zh_CN": "简体中文", "en_US": "English"}
const UI_TEXT := {
	"zh_CN": {
		"menu": "菜单",
		"skip_tutorial": "跳过教程",
		"settings": "设置",
		"save_settings": "保存设置",
		"how_to_play": "玩法说明",
		"credits": "鸣谢与许可证",
		"credits_close": "关闭",
		"rules_close": "知道了",
		"display": "显示",
		"fullscreen": "全屏模式",
		"window_size": "窗口大小",
		"sfx_volume": "音效音量",
		"music_volume": "音乐音量",
		"mute": "静音",
		"accessibility": "可访问性",
		"reduced_motion": "减少动效",
		"language": "语言",
		"show_tutorial": "显示首局教程",
		"hand_tab": "手牌",
		"shop_tab": "商店",
		"manage_tab": "管理",
		"fate_hand": "命运手牌",
		"starter_bag": "初始命运袋",
		"wager_mode": "下注模式",
		"fate_shop": "命运商店",
		"relic_shop": "遗物商店",
		"consumables": "一次性道具",
		"curse_trades": "诅咒交易",
		"fate_management": "命运管理",
		"recycle_zone": "回收区\n拖入已上阵硬币，回收部分升级投资",
		"menu_subtitle": "构筑一台会反噬你的命运铸币机",
		"forge_table": "审判台",
		"new_game": "新游戏",
		"continue_game": "继续游戏",
		"save_run": "保存当前局",
		"delete_save": "删除存档",
		"return_game": "返回游戏",
		"quit_desktop": "退出到桌面",
		"confirm_delete_title": "删除存档？",
		"confirm_delete_body": "这会删除当前本地存档，但不会清除永久进度。确定继续吗？",
		"confirm_quit_title": "退出到桌面？",
		"confirm_quit_body": "退出前会保存设置。当前局需要手动保存才会保留。",
		"confirm": "确认",
		"cancel": "取消",
		"back_to_menu": "回到主菜单",
		"game_over": "游戏结束",
		"continue_save": "继续存档",
		"no_save": "没有可继续的存档",
		"coins": "金币",
		"health": "生命",
		"round": "回合",
		"quota": "收取",
		"manual": "手动",
		"enemy": "敌人",
		"state": "状态",
		"ready": "准备",
		"active": "回合中",
		"start_round": "开始下一回合",
		"end_round": "结束回合",
		"language_changed": "语言已切换为 %s。核心菜单、设置、教程、玩法说明、战斗反馈和结算总结已应用该语言。",
		"settings_saved": "设置已保存。",
		"tutorial_skipped": "教程已跳过。所有信息仍可通过悬停提示查看。",
		"settlement_title": "回合结算",
		"settlement_ok": "继续布阵",
		"tutorial_recap": "教程复盘",
		"tutorial_core_loop": "你已经完成核心循环：布阵、开局、点击硬币、结算。",
		"tutorial_chain_loop": "你已经打出第一段连锁：相邻方向和摆放顺序会决定机器效率。",
		"tutorial_next_steps": "接下来优先看三件事：买 1 枚能配合现有路线的硬币，保留足够金币支付下一轮收取，生命低时把下注调回保守或标准。",
		"rules_body": "目标\n撑过 24 回合并击败最终 Boss。金币不足以支付收取，或生命归零，都会失败。\n\n30 秒核心循环\n1. 准备阶段：把右侧命运手牌拖到棋盘。\n2. 点击开始下一回合。\n3. 回合中：点击棋盘硬币，赚金币、造成伤害，并尝试连锁触发相邻硬币。\n4. 点击结束回合：敌人行动，支付本轮收取，然后进入商店和管理阶段。\n\n风险\n下注越高，收益和伤害越高，但失败、自伤和敌人压力也更危险。生命低或金币紧张时，优先调回保守或标准。\n\n回合间选择\n买能配合路线的硬币，锁定关键手牌，移除拖累命运袋的硬币；遗物、道具和诅咒交易会改变整局节奏。\n\n读盘重点\n先看本轮收取、生命、敌人意图和手动次数，再决定是赚钱、击杀敌人，还是保命。",
		"credits_body": "Fate Coins\n一款 Godot 4.6 制作的单机硬币构筑 roguelite。\n\n项目内容\n当前代码、设计文本、程序化美术、程序化音频、截图和候选商店素材均由本项目仓库工具生成或维护。\n\n引擎\nBuilt with Godot Engine 4.6。\nGodot Engine 使用 MIT License 发布。最终发行包需要附带对应 Godot 版本的许可证文本和第三方声明。\n\n当前素材状态\n仓库中的程序化商店胶囊、截图、图标和音频是当前 Steam 准备素材；若后续替换为外部字体、美术、音乐、音效、中间件或插件，需要在 LICENSES.md 中逐项登记来源、许可证和再分发说明。\n\n发布备注\n最终 Windows/macOS/Linux 导出包仍需随发行记录复查平台签名、公证、Steam redistributable 和第三方 notices。"
	},
	"en_US": {
		"menu": "Menu",
		"skip_tutorial": "Skip",
		"settings": "Settings",
		"save_settings": "Save Settings",
		"how_to_play": "How To Play",
		"credits": "Credits / Licenses",
		"credits_close": "Close",
		"rules_close": "Got It",
		"display": "Display",
		"fullscreen": "Fullscreen",
		"window_size": "Window Size",
		"sfx_volume": "SFX Volume",
		"music_volume": "Music Volume",
		"mute": "Mute",
		"accessibility": "Accessibility",
		"reduced_motion": "Reduced Motion",
		"language": "Language",
		"show_tutorial": "Show First-Run Tutorial",
		"hand_tab": "Hand",
		"shop_tab": "Market",
		"manage_tab": "Manage",
		"fate_hand": "Fate Hand",
		"starter_bag": "Starter Fate Bag",
		"wager_mode": "Wager Mode",
		"fate_shop": "Fate Shop",
		"relic_shop": "Relic Shop",
		"consumables": "Consumables",
		"curse_trades": "Curse Trades",
		"fate_management": "Fate Management",
		"recycle_zone": "Recycle Zone\nDrag placed coins here to refund part of upgrade investment",
		"menu_subtitle": "Build a coin machine that bites back.",
		"forge_table": "Judgment Table",
		"new_game": "New Game",
		"continue_game": "Continue",
		"save_run": "Save Run",
		"delete_save": "Delete Save",
		"return_game": "Return",
		"quit_desktop": "Quit to Desktop",
		"confirm_delete_title": "Delete Save?",
		"confirm_delete_body": "This deletes the current local save, but keeps meta progress. Continue?",
		"confirm_quit_title": "Quit to Desktop?",
		"confirm_quit_body": "Settings will be saved before quitting. Save the current run manually if you want to keep it.",
		"confirm": "Confirm",
		"cancel": "Cancel",
		"back_to_menu": "Back to Menu",
		"game_over": "Game Over",
		"continue_save": "Continue Save",
		"no_save": "No Save Found",
		"coins": "Coins",
		"health": "Health",
		"round": "Round",
		"quota": "Quota",
		"manual": "Manual",
		"enemy": "Enemies",
		"state": "State",
		"ready": "Ready",
		"active": "Action",
		"start_round": "Start Round",
		"end_round": "End Round",
		"language_changed": "Language set to %s. Menus, settings, tutorial, rules, combat feedback, and run summaries now use this language.",
		"settings_saved": "Settings saved.",
		"tutorial_skipped": "Tutorial skipped. Hover tooltips still explain the details.",
		"settlement_title": "Round Settlement",
		"settlement_ok": "Continue Planning",
		"tutorial_recap": "Tutorial Recap",
		"tutorial_core_loop": "You completed the core loop: place coins, start the round, click coins, then settle.",
		"tutorial_chain_loop": "You triggered your first chain: adjacency and coin direction decide how efficient the machine becomes.",
		"tutorial_next_steps": "Next, focus on three choices: buy 1 coin that supports your route, keep enough coins for the next quota, and lower your wager when health gets low.",
		"rules_body": "Goal\nSurvive 24 rounds and defeat the final boss. You lose if health reaches 0 or you cannot pay the round quota.\n\n30-Second Core Loop\n1. Planning: drag fate-hand coins onto the board.\n2. Press Start Round.\n3. Action: click board coins to earn coins, deal damage, and chain into neighbors.\n4. Press End Round: enemies act, quota is paid, then the market and bag-management choices open.\n\nRisk\nHigher wagers increase payouts and damage, but make failures, self-damage, and enemy pressure more dangerous. Drop to Safe or Standard when health or coins are tight.\n\nBetween Rounds\nBuy coins that support your route, lock key hand coins, and remove coins that dilute the fate bag. Relics, consumables, and curse trades can reshape the whole run.\n\nWhat To Read First\nCheck quota due, health, enemy intent, and manual clicks before deciding whether to earn, kill, or stabilize.",
		"credits_body": "Fate Coins\nA single-player coin-building roguelite built with Godot 4.6.\n\nProject Content\nCurrent code, design text, procedural art, procedural audio, screenshots, and candidate storefront assets are generated or maintained by this repository's tools.\n\nEngine\nBuilt with Godot Engine 4.6.\nGodot Engine is distributed under the MIT License. Final release packages must include the license text and third-party notices for the exact Godot build used for export.\n\nCurrent Asset Status\nThe procedural Steam capsules, screenshots, icons, and audio in this repository are current release-preparation assets. If external fonts, art, music, SFX, middleware, or plugins are added later, LICENSES.md must list their source, license, and redistribution notes.\n\nRelease Notes\nFinal Windows/macOS/Linux packages still need platform signing, notarization, Steam redistributable, and third-party-notice review alongside the release build records."
	}
}
const TILE_TEXT_EN := {
	"normal": {"name": "Normal", "tip": "Resolves only itself and does not trigger neighbors. Costs 1 coin."},
	"left": {"name": "Left", "tip": "Has a 50% chance to trigger the coin on the left. Costs 3 coins."},
	"right": {"name": "Right", "tip": "Has a 50% chance to trigger the coin on the right. Costs 3 coins."},
	"up": {"name": "Up", "tip": "Has a 50% chance to trigger the coin above. Costs 3 coins."},
	"down": {"name": "Down", "tip": "Has a 50% chance to trigger the coin below. Costs 3 coins."},
	"star": {"name": "Star", "tip": "Checks all four directions, each with a 50% trigger chance. Costs 6 coins."},
	"bank": {"name": "Bank", "tip": "Rare tile. On success, gains 2 coins and does not trigger neighbors."},
	"cross": {"name": "Cross", "tip": "Rare tile. Checks all four directions with a 62% trigger chance each."},
	"surge": {"name": "Surge", "tip": "Rare tile. Pays 2 coins on success and has a lower chance to trigger all around it."},
	"lucky": {"name": "Lucky", "tip": "Heads: coins, damage, and 1 healing. Tails: gain 1 manual trigger."},
	"reverse": {"name": "Reverse", "tip": "Tails is the big hit. Heads is modest; tails pays more coins and damage."},
	"glass": {"name": "Glass", "tip": "Heads gives high coins and damage. Tails may shatter and hurt you."},
	"stock": {"name": "Stock", "tip": "Heads raises this stock for future value. Tails falls, but refunds 1 coin."},
	"vampire": {"name": "Vampire", "tip": "Heads deals damage and heals you. Tails costs 1 health but deals extra damage."},
	"spirit": {"name": "Spirit", "tip": "Heads grants an extra manual trigger. Tails pays less but still tries to chain outward."},
	"angel": {"name": "Angel", "tip": "Heads heals and cleanses itself. Tails has low payout but cleanses nearby coins."},
	"demon": {"name": "Demon", "tip": "Triggering costs health. Heads bursts coins and damage; tails pollutes itself but still hits."},
	"mirror": {"name": "Mirror", "tip": "Heads copies a small part of adjacent left/right gains. Tails gains 1 coin and tries both sides."},
	"magnet": {"name": "Magnet", "tip": "Heads pays for adjacent coins. Tails pulls a little damage and improves chaining."},
	"echo": {"name": "Echo", "tip": "Heads scales from this round's trigger history. Tails grants a manual trigger for long chains."},
	"shield": {"name": "Shield", "tip": "Heads grants coins and healing. Tails cleanses itself and reduces enemy disruption."},
	"forge": {"name": "Forge", "tip": "Heads heats up for stronger future gains. Tails cools down but refunds coins."},
	"compass": {"name": "Compass", "tip": "Heads pays for adjacent empty slots and improves chaining. Tails pays less but navigates all directions."},
	"debt_coin": {"name": "Debt", "tip": "Heads pays immediately. Tails pays too, but adds debt pressure to the board."},
	"arc": {"name": "Arc", "tip": "Heads triggers right and down, scaling with board depth. Tails pays less but keeps the chain alive."},
	"bloom": {"name": "Bloom", "tip": "Heads heals and grows. Tails spends growth for coins, supporting health-based builds."},
	"titan": {"name": "Titan", "tip": "Heads is a heavy coin and damage burst. Tails locks itself but still deals some damage."},
	"hourglass": {"name": "Hourglass", "tip": "Heads grants a manual trigger and extends itself. Tails converts one trigger into coins."},
	"joker": {"name": "Joker", "tip": "Heads and tails both work, but payouts swing wildly. Best for gamble builds."},
	"anchor": {"name": "Anchor", "tip": "Heads protects itself and reduces disruption. Tails locks itself but heals you."}
}
const STARTER_TEXT_EN := {
	"balanced": {"name": "Balanced", "tip": "A stable start with light defense and navigation. Good for learning the run."},
	"chain": {"name": "Chain", "tip": "Easier directional chains with a small defensive buffer for engine-style builds."},
	"gambler": {"name": "Gambler", "tip": "Higher variance, built for Greedy and All In wagers."},
	"blood": {"name": "Blood", "tip": "Spend health for damage, then recover with Shield, Vampire, Bloom, and Angel."}
}
const WAGER_TEXT_EN := {
	"safe": {"name": "Safe", "tip": "Lower payout, but failed manual flips do not hurt you."},
	"standard": {"name": "Standard", "tip": "Normal payout and risk."},
	"greedy": {"name": "Greedy", "tip": "Higher payout, but manual failures hurt and enemies hit harder."},
	"all_in": {"name": "All In", "tip": "Huge burst potential, but every failed manual flip hurts."}
}
const DIFFICULTY_TEXT_EN := {
	"normal": {"name": "Normal", "tip": "Standard challenge, tuned for a first clear."},
	"hard": {"name": "Hard", "tip": "Tougher enemies and higher quotas. Unlocks after reaching round 8."},
	"fate": {"name": "Fate", "tip": "Full pressure challenge. Unlocks after a victory."}
}
const ENEMY_TEXT_EN := {
	"thief": {"name": "Thief", "intent": "Steals coins and nips at you."},
	"guard": {"name": "Shield Guard", "intent": "Uses shields to absorb small hits."},
	"sniper": {"name": "Sniper", "intent": "Low health, high ranged damage."},
	"debt": {"name": "Debt Collector", "intent": "Steals money and punishes greedy wagers."},
	"taxer": {"name": "Tax Officer", "intent": "Steals a large amount of coins, forcing economic cleanup."},
	"devourer": {"name": "Coin Devourer", "intent": "Pollutes high-level coins and slows your core build."},
	"hexer": {"name": "Hexer", "intent": "Disrupts and pollutes coins at the same time."},
	"saboteur": {"name": "Saboteur", "intent": "Targets directional coins and breaks chain routes."},
	"healer": {"name": "Mender", "intent": "Repairs the enemy line, making slow fights dangerous."},
	"gambler_rat": {"name": "Gambler", "intent": "Gets excited by aggressive wagers."},
	"frost": {"name": "Frost Marker", "intent": "Freezes a column and forces a route change."},
	"mimic": {"name": "Mimic Coin", "intent": "Copies your core gains and grows harder over time."},
	"timekeeper": {"name": "Timekeeper", "intent": "Tracks coins with the most triggers and slows long engines."},
	"lock_boss": {"name": "Iron Lock Warden", "intent": "Round 8 boss. Locks core coins."},
	"market_boss": {"name": "Bubble Broker", "intent": "Round 12 boss. Suppresses payout and pressures the market."},
	"debt_boss": {"name": "Usury Count", "intent": "Round 16 boss. Uses pollution and theft to break your economy."},
	"mirror_boss": {"name": "Mirror Hall Judge", "intent": "Round 20 boss. Copies your core route and locks both sides."},
	"banker": {"name": "Fate Banker", "intent": "Final boss. Tests the whole coin machine."}
}
const RELIC_TEXT_EN := {
	"golden_glove": {"name": "Golden Glove", "tip": "Every heads grants +1 coin."},
	"chain_bell": {"name": "Chain Bell", "tip": "All directional chain chances +10%."},
	"red_heart": {"name": "Red Heart Charm", "tip": "Prevents 1 damage from the first self-damage each round."},
	"tax_receipt": {"name": "Tax Receipt", "tip": "Round quota payment -2, minimum 0."},
	"loaded_die": {"name": "Loaded Die", "tip": "Greedy and All In wagers gain +8% heads chance."},
	"war_banner": {"name": "War Banner", "tip": "All heads deal +1 damage."},
	"merchant_seal": {"name": "Merchant Seal", "tip": "Coin purchases cost 1 less, minimum 1."},
	"deep_pockets": {"name": "Deep Pockets", "tip": "Draw 1 extra hand coin each round."},
	"silver_lens": {"name": "Silver Lens", "tip": "All coins gain +4% heads chance."},
	"steady_anvil": {"name": "Steady Anvil", "tip": "Coin upgrades cost 2 less, minimum 1."},
	"void_purse": {"name": "Void Purse", "tip": "Removing coins from the fate bag costs 3 less, minimum 1."},
	"shield_charm": {"name": "Shield Charm", "tip": "Total enemy phase damage is reduced by 2, minimum 0."},
	"blood_cup": {"name": "Blood Cup", "tip": "Vampire and Demon deal +2 damage."},
	"glass_hammer": {"name": "Glass Hammer", "tip": "Glass heads grants +2 coins and +2 damage."},
	"oracle_deck": {"name": "Oracle Deck", "tip": "Round events with manual triggers or quota relief grant +1 more."},
	"echo_chamber": {"name": "Echo Chamber", "tip": "Echo and Hourglass gain +8% heads chance and better chain stability."},
	"bloom_crown": {"name": "Bloom Crown", "tip": "All healing effects +1; Bloom and Angel become steadier."},
	"titan_gauntlet": {"name": "Titan Gauntlet", "tip": "Titan gains +6% heads chance and +3 damage."},
	"debt_ledger": {"name": "Debt Ledger", "tip": "Debt gains +4% heads chance and board debt pressure is halved."},
	"cartographer_map": {"name": "Cartographer Map", "tip": "Compass and Arc gain +8% heads chance."},
	"joker_mask": {"name": "Joker Mask", "tip": "Joker gains +5% heads chance and a higher random payout ceiling."},
	"anchor_chain": {"name": "Anchor Chain", "tip": "Anchor and Shield become steadier and deal +1 damage."},
	"bounty_contract": {"name": "Bounty Contract", "tip": "Enemy kill bounties increase by 25%."},
	"furnace_core": {"name": "Furnace Core", "tip": "Forge gains +6% heads chance, higher heat cap, and +1 damage."},
	"pocket_watch": {"name": "Pocket Watch", "tip": "Hourglass and Echo can trigger 1 extra time each round."}
}
const CONSUMABLE_TEXT_EN := {
	"heal_potion": {"name": "Healing Potion", "tip": "Immediately restore 6 health."},
	"smoke_bomb": {"name": "Smoke Bomb", "tip": "Clear all lock, jam, pollution, and steal marks on the board."},
	"lucky_ticket": {"name": "Lucky Ticket", "tip": "Gain 2 extra manual triggers this round."},
	"market_tip": {"name": "Market Tip", "tip": "Raise all placed Stock coins by 2 steps."},
	"repair_kit": {"name": "Repair Kit", "tip": "Repair all shattered Glass coins."}
}
const CURSE_TEXT_EN := {
	"blood_money": {"name": "Blood Money", "tip": "Gain 18 coins immediately, but lose 4 health."},
	"heavy_debt": {"name": "Heavy Debt", "tip": "Gain 28 coins immediately, but future quota payments increase by 3."},
	"thin_bag": {"name": "Thin Bag", "tip": "Gain 16 coins immediately, but draw 1 fewer hand coin each round."},
	"cursed_coin": {"name": "Cursed Coin", "tip": "Gain 22 coins immediately, but add 2 Demon coins to the fate bag."}
}
const EVENT_TEXT_EN := {
	"黄金潮汐": {"name": "Golden Tide", "desc": "All successful clicks grant +1 coin this round."},
	"连锁顺风": {"name": "Chain Tailwind", "desc": "All directional trigger chances +15%."},
	"长线布局": {"name": "Long Setup", "desc": "Manual clicks +2 this round."},
	"税务宽免": {"name": "Tax Relief", "desc": "Pay 2 fewer coins at round end, minimum 0."},
	"耐久强化": {"name": "Durability Boost", "desc": "Each coin can trigger 1 more time this round."},
	"黑市折扣": {"name": "Black Market Discount", "desc": "Market coin prices -1 this round."},
	"低压战线": {"name": "Low-Pressure Front", "desc": "Enemy attack -1 this round."},
	"高压战线": {"name": "High-Pressure Front", "desc": "Enemy attack +1, but successful flips grant +1 coin."},
	"命运回响": {"name": "Fate Echo", "desc": "Manual clicks +1 and directional trigger chance +8%."},
	"债务喘息": {"name": "Debt Breather", "desc": "Pay 1 fewer coin at round end and enemy attack -1."},
	"狂热集市": {"name": "Fever Market", "desc": "Market coin prices -1, but enemy attack +1."},
	"硬币雨": {"name": "Coin Rain", "desc": "Successful flips grant +2 coins, but directional trigger chance -8%."},
	"脆弱火花": {"name": "Fragile Spark", "desc": "Each coin can trigger 1 more time, but enemy attack +1."},
	"稳态时钟": {"name": "Steady Clock", "desc": "Manual clicks +1 and pay 1 fewer coin at round end."},
	"逆风翻面": {"name": "Headwind Flip", "desc": "Directional trigger chance -10%, but every success grants +1 coin."},
	"静默铸币": {"name": "Silent Minting", "desc": "Success grants +1 coin and enemy attack -1, but no extra chain help."},
	"熔炉日": {"name": "Furnace Day", "desc": "Each coin can trigger 1 more time and market coin prices -1."},
	"镜面集市": {"name": "Mirror Market", "desc": "Market coin prices -2, but end-round quota +1."},
	"债雨": {"name": "Debt Rain", "desc": "Success grants +2 coins, but end-round quota +2."},
	"破晓休整": {"name": "Dawn Respite", "desc": "Enemy attack -2 and pay 1 fewer coin at round end."},
	"猎杀悬赏": {"name": "Hunt Bounty", "desc": "Directional trigger chance +6%, but enemy attack +1."},
	"钟摆回合": {"name": "Pendulum Round", "desc": "Manual clicks +2, but each coin has 1 fewer trigger."},
	"锚定防线": {"name": "Anchored Line", "desc": "Enemy attack -1 and each coin can trigger 1 more time."},
	"小丑庆典": {"name": "Joker Festival", "desc": "Manual clicks +1 and success grants +1 coin, but enemy attack +1."},
	"花园低语": {"name": "Garden Whisper", "desc": "Directional trigger chance +5% and pay 1 fewer coin at round end."},
	"巨神阴影": {"name": "Titan Shadow", "desc": "Success grants +2 coins, but enemy attack +2."},
	"制图远征": {"name": "Cartographer Expedition", "desc": "Directional trigger chance +12% and market coin prices -1."},
	"税务突查": {"name": "Tax Raid", "desc": "End-round quota +3, but enemy attack -1."},
	"空袋补给": {"name": "Empty Bag Supply", "desc": "Market coin prices -1 and manual clicks +1."},
	"命运暴走": {"name": "Fate Surge", "desc": "Directional trigger chance +18%, but enemy attack +2."},
	"庄家凝视": {"name": "Banker Gaze", "desc": "Enemy attack rises, but chain payouts climb higher too."}
}

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
	"error": "res://audio/error.wav",
	"hit": "res://audio/hit.wav",
	"hurt": "res://audio/hurt.wav",
	"warning": "res://audio/warning.wav",
	"boss": "res://audio/boss_sting.wav",
	"victory": "res://audio/victory.wav"
}
const MUSIC_PATHS := {
	"run": "res://audio/music_run.wav",
	"warning": "res://audio/music_warning.wav",
	"boss": "res://audio/music_boss.wav"
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
	"balanced": {"name": "稳健", "coins": ["normal", "normal", "shield", "left", "right", "up", "down", "lucky", "reverse", "compass"], "tip": "均衡入口，带少量防御和导航，适合稳定熟悉流程。"},
	"chain": {"name": "连锁", "coins": ["normal", "normal", "left", "right", "up", "down", "magnet", "lucky", "arc", "shield"], "tip": "更容易打出方向连锁，带一点防御，适合机关流。"},
	"gambler": {"name": "赌博", "coins": ["normal", "normal", "reverse", "reverse", "glass", "joker", "lucky", "surge", "stock", "mirror"], "tip": "波动更高，适合贪婪和梭哈。"},
	"blood": {"name": "鲜血", "coins": ["normal", "shield", "vampire", "demon", "lucky", "reverse", "up", "down", "bloom", "angel"], "tip": "用生命换伤害，再靠护盾、吸血、花层和天使续航。"}
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
const BG_COLOR := Color(0.012, 0.016, 0.025)
const PANEL_COLOR := Color(0.031, 0.041, 0.055, 0.98)
const PANEL_LIGHT := Color(0.066, 0.083, 0.100)
const SLOT_COLOR := Color(0.024, 0.032, 0.046)
const GOLD := Color(0.86, 0.82, 0.66)
const CREAM := Color(0.86, 0.90, 0.88)
const GREEN := Color(0.42, 0.78, 0.64)
const COIN_FLASH := Color(0.94, 0.16, 0.24)
const BLUE := Color(0.42, 0.68, 0.78)
const INK := Color(0.010, 0.013, 0.022)
const DEEP_PANEL := Color(0.020, 0.026, 0.036)
const MINT := Color(0.58, 0.83, 0.78)
const COPPER := Color(0.58, 0.66, 0.70)
const DANGER := Color(0.88, 0.12, 0.20)
const VIOLET := Color(0.50, 0.50, 0.76)
const MOON := Color(0.74, 0.86, 0.90)
const BLOOD := Color(0.78, 0.08, 0.16)

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
var music_volume_db := -18.0
var audio_muted := false
var fullscreen_enabled := false
var reduced_motion_enabled := false
var window_size := Vector2i(1600, 1000)
var language_id := "zh_CN"
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
var music_player: AudioStreamPlayer
var current_music_key := ""

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
var impact_panel: PanelContainer
var impact_title_label: Label
var impact_detail_label: Label
var side_tabs: TabContainer
var fate_hand_title_label: Label
var starter_title_label: Label
var wager_title_label: Label
var shop_title_label: Label
var relic_title_label: Label
var consumable_title_label: Label
var curse_title_label: Label
var bag_title_label: Label
var delete_zone_label: Label
var tutorial_panel: PanelContainer
var tutorial_label: Label
var tutorial_button: Button
var tutorial_focus := "none"
var header_menu_button: Button
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
var menu_subtitle_label: Label
var menu_action_title_label: Label
var menu_new_button: Button
var menu_delete_save_button: Button
var menu_settings_button: Button
var menu_rules_button: Button
var menu_credits_button: Button
var menu_close_button: Button
var menu_quit_button: Button
var difficulty_select: OptionButton
var settings_dialog: AcceptDialog
var rules_dialog: AcceptDialog
var credits_dialog: AcceptDialog
var settings_display_label: Label
var settings_window_label: Label
var settings_volume_label: Label
var settings_music_label: Label
var settings_accessibility_label: Label
var settings_language_label: Label
var volume_slider: HSlider
var music_volume_slider: HSlider
var mute_toggle: CheckBox
var reduced_motion_toggle: CheckBox
var window_size_select: OptionButton
var language_select: OptionButton
var tutorial_toggle: CheckBox
var fullscreen_toggle: CheckBox
var game_over_dialog: AcceptDialog
var game_over_menu_button: Button
var settlement_dialog: AcceptDialog
var delete_save_confirm_dialog: ConfirmationDialog
var quit_confirm_dialog: ConfirmationDialog


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
	_build_rules_dialog()
	_build_credits_dialog()
	_build_menu_overlay()
	_update_ui("Planning: this round's hand was drawn from the fate bag. Drag hand coins to the board; shop buys enter the fate bag." if language_id == "en_US" else "准备阶段：从命运袋抽到本回合手牌；拖拽手牌上阵，商店购买会加入命运袋。")
	_show_menu()
	_update_music_context()


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
	var backdrop := MoonlitBackdrop.new()
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

	_build_impact_overlay()
	_build_game_over_dialog()
	_build_settlement_dialog()
	_build_confirm_dialogs()
	_build_audio_players()


func _build_header() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 78)
	panel.add_theme_stylebox_override("panel", style(Color(0.024, 0.032, 0.046, 0.96), 4, BLUE.darkened(0.08), 2))

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

	header_menu_button = _make_small_button(_ui("menu"))
	header_menu_button.custom_minimum_size = Vector2(70, 46)
	header_menu_button.pressed.connect(_show_menu)
	row.add_child(header_menu_button)

	return panel


func _build_impact_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 12
	add_child(layer)

	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 120
	center.offset_bottom = -120
	overlay.add_child(center)

	impact_panel = PanelContainer.new()
	impact_panel.visible = false
	impact_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	impact_panel.custom_minimum_size = Vector2(520, 92)
	impact_panel.add_theme_stylebox_override("panel", style(Color(0.036, 0.052, 0.070, 0.95), 4, MINT, 2))
	center.add_child(impact_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 14)
	impact_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)

	impact_title_label = Label.new()
	impact_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	impact_title_label.add_theme_font_size_override("font_size", 30)
	impact_title_label.add_theme_color_override("font_color", GOLD)
	impact_title_label.add_theme_color_override("font_outline_color", Color(0.006, 0.010, 0.018))
	impact_title_label.add_theme_constant_override("outline_size", 5)
	column.add_child(impact_title_label)

	impact_detail_label = Label.new()
	impact_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	impact_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	impact_detail_label.add_theme_font_size_override("font_size", 15)
	impact_detail_label.add_theme_color_override("font_color", CREAM)
	column.add_child(impact_detail_label)


func _build_board_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", style(Color(0.020, 0.029, 0.042, 0.96), 4, Color(0.38, 0.55, 0.64), 2))

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
	status.add_theme_stylebox_override("panel", style(Color(0.034, 0.048, 0.064), 4, BLUE.darkened(0.08), 2))
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
	combat_feed.add_theme_stylebox_override("panel", style(Color(0.070, 0.022, 0.034), 4, DANGER.darkened(0.10), 1))
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
	tutorial_panel.add_theme_stylebox_override("panel", style(Color(0.042, 0.054, 0.066), 4, GOLD.darkened(0.20), 2))
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

	tutorial_button = _make_small_button(_ui("skip_tutorial"))
	tutorial_button.custom_minimum_size = Vector2(94, 34)
	tutorial_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	tutorial_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	panel.add_theme_stylebox_override("panel", style(Color(0.024, 0.032, 0.045, 0.97), 4, Color(0.38, 0.54, 0.62), 2))

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

	side_tabs = TabContainer.new()
	side_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_stack.add_child(side_tabs)

	var column := _make_side_tab(side_tabs, _ui("hand_tab"))
	var shop_column := _make_side_tab(side_tabs, _ui("shop_tab"))
	var manage_column := _make_side_tab(side_tabs, _ui("manage_tab"))

	fate_hand_title_label = Label.new()
	fate_hand_title_label.text = _ui("fate_hand")
	fate_hand_title_label.add_theme_font_size_override("font_size", 22)
	fate_hand_title_label.add_theme_color_override("font_color", GOLD)
	column.add_child(fate_hand_title_label)

	var starter_box := PanelContainer.new()
	starter_box.add_theme_stylebox_override("panel", style(Color(0.036, 0.052, 0.058), 4, MINT.darkened(0.24), 1))
	column.add_child(starter_box)

	var starter_stack := VBoxContainer.new()
	starter_stack.add_theme_constant_override("separation", 4)
	starter_box.add_child(starter_stack)

	starter_title_label = Label.new()
	starter_title_label.text = _ui("starter_bag")
	starter_title_label.add_theme_font_size_override("font_size", 20)
	starter_title_label.add_theme_color_override("font_color", GOLD)
	starter_stack.add_child(starter_title_label)

	starter_select = OptionButton.new()
	starter_select.fit_to_longest_item = false
	starter_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	starter_select.add_theme_font_size_override("font_size", 14)
	for bag_id in STARTER_BAG_ORDER:
		starter_select.add_item(_starter_name(bag_id))
		starter_select.set_item_metadata(starter_select.item_count - 1, bag_id)
	starter_select.selected = STARTER_BAG_ORDER.find(starter_bag_id)
	starter_select.tooltip_text = "Choose a starter fate bag. Hover hand coins for coin details." if language_id == "en_US" else "选择初始命运袋。悬停命运手牌可查看硬币详情。"
	starter_select.item_selected.connect(_on_starter_bag_selected)
	starter_stack.add_child(starter_select)

	var wager_box := PanelContainer.new()
	wager_box.add_theme_stylebox_override("panel", style(Color(0.052, 0.046, 0.062), 4, VIOLET.darkened(0.14), 1))
	column.add_child(wager_box)

	var wager_stack := VBoxContainer.new()
	wager_stack.add_theme_constant_override("separation", 4)
	wager_box.add_child(wager_stack)

	wager_title_label = Label.new()
	wager_title_label.text = _ui("wager_mode")
	wager_title_label.add_theme_font_size_override("font_size", 20)
	wager_title_label.add_theme_color_override("font_color", GOLD)
	wager_stack.add_child(wager_title_label)

	wager_select = OptionButton.new()
	wager_select.fit_to_longest_item = false
	wager_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wager_select.add_theme_font_size_override("font_size", 14)
	for mode in WAGER_ORDER:
		wager_select.add_item(_wager_name(mode))
		wager_select.set_item_metadata(wager_select.item_count - 1, mode)
	wager_select.selected = WAGER_ORDER.find(wager_mode)
	wager_select.tooltip_text = "Choose this run's risk multiplier. Higher risk improves payout and raises failure costs." if language_id == "en_US" else "选择本局风险倍率。更高风险会提高收益，也会放大失败代价。"
	wager_select.item_selected.connect(_on_wager_selected)
	wager_stack.add_child(wager_select)

	palette_container = GridContainer.new()
	palette_container.columns = 2
	palette_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palette_container.add_theme_constant_override("h_separation", 6)
	palette_container.add_theme_constant_override("v_separation", 6)
	column.add_child(palette_container)
	_rebuild_shop_palette()

	shop_title_label = Label.new()
	shop_title_label.text = _ui("fate_shop")
	shop_title_label.add_theme_font_size_override("font_size", 19)
	shop_title_label.add_theme_color_override("font_color", GOLD)
	shop_column.add_child(shop_title_label)

	shop_container = VBoxContainer.new()
	shop_container.add_theme_constant_override("separation", 6)
	shop_column.add_child(shop_container)
	_rebuild_market()

	relic_title_label = Label.new()
	relic_title_label.text = _ui("relic_shop")
	relic_title_label.add_theme_font_size_override("font_size", 19)
	relic_title_label.add_theme_color_override("font_color", GOLD)
	shop_column.add_child(relic_title_label)

	relic_container = VBoxContainer.new()
	relic_container.add_theme_constant_override("separation", 6)
	shop_column.add_child(relic_container)
	_rebuild_relic_market()

	consumable_title_label = Label.new()
	consumable_title_label.text = _ui("consumables")
	consumable_title_label.add_theme_font_size_override("font_size", 19)
	consumable_title_label.add_theme_color_override("font_color", GOLD)
	shop_column.add_child(consumable_title_label)

	consumable_container = VBoxContainer.new()
	consumable_container.add_theme_constant_override("separation", 6)
	shop_column.add_child(consumable_container)
	_rebuild_consumable_market()

	curse_title_label = Label.new()
	curse_title_label.text = _ui("curse_trades")
	curse_title_label.add_theme_font_size_override("font_size", 19)
	curse_title_label.add_theme_color_override("font_color", GOLD)
	shop_column.add_child(curse_title_label)

	curse_container = VBoxContainer.new()
	curse_container.add_theme_constant_override("separation", 6)
	shop_column.add_child(curse_container)
	_rebuild_curse_market()

	bag_title_label = Label.new()
	bag_title_label.text = _ui("fate_management")
	bag_title_label.add_theme_font_size_override("font_size", 19)
	bag_title_label.add_theme_color_override("font_color", GOLD)
	manage_column.add_child(bag_title_label)

	bag_container = VBoxContainer.new()
	bag_container.add_theme_constant_override("separation", 5)
	manage_column.add_child(bag_container)
	_rebuild_bag_manager()

	delete_zone = DeleteDrop.new()
	delete_zone.main = self
	delete_zone.custom_minimum_size = Vector2(0, 64)
	delete_zone.add_theme_stylebox_override("panel", style(Color(0.076, 0.022, 0.034), 4, DANGER, 2))
	manage_column.add_child(delete_zone)

	delete_zone_label = Label.new()
	delete_zone_label.text = _ui("recycle_zone")
	delete_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delete_zone_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	delete_zone_label.add_theme_font_size_override("font_size", 14)
	delete_zone_label.add_theme_color_override("font_color", CREAM)
	delete_zone.add_child(delete_zone_label)

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
	slot.add_theme_stylebox_override("panel", style(SLOT_COLOR, 4, Color(0.32, 0.47, 0.56), 2))

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
	info.add_theme_color_override("font_color", Color(0.70, 0.78, 0.80))
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
	tile.tooltip_text = _tile_tip(tile_type)
	var rarity_border := _rarity_color(String(config["rarity"]))
	if _is_tutorial_focus("place"):
		tile.add_theme_stylebox_override("panel", style(PANEL_LIGHT.lightened(0.08), 4, GOLD.lightened(0.18), 3))
	else:
		tile.add_theme_stylebox_override("panel", style(PANEL_LIGHT, 4, rarity_border, 2))

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
	label.text = "%s %s x%d\n%s  %s" % [config["symbol"], _tile_name(tile_type), count, String(config["rarity"]).to_upper(), "Drag to board" if language_id == "en_US" else "拖拽上阵"]
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
		_tile_name(tile_type),
		String(config["rarity"]).to_upper(),
		cost
	]
	button.tooltip_text = "%s\n%s" % [_tile_tip(tile_type), "Bought coins enter the fate bag and can be drawn on later rounds." if language_id == "en_US" else "购买后进入命运袋，从下一回合开始可能抽到。"]
	button.custom_minimum_size = Vector2(0, 34)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_icon(button, TILE_TEXTURES[tile_type])
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_stylebox_override("normal", style(PANEL_LIGHT, 4, _rarity_color(String(config["rarity"])), 1))
	button.add_theme_stylebox_override("hover", style(PANEL_LIGHT.lightened(0.08), 4, _rarity_color(String(config["rarity"])), 2))
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
	owned.text = "Owned: %s" % _relic_summary() if language_id == "en_US" else "已持有：%s" % _relic_summary()
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
	active.text = "Active: %s" % _curse_summary() if language_id == "en_US" else "已承受：%s" % _curse_summary()
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
		empty.text = "Enemy line clear" if language_id == "en_US" else "敌阵清空"
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
	var enemy_type := String(enemy.get("type", ""))
	var enemy_name := _enemy_name(enemy_type)
	var enemy_intent := _enemy_intent(enemy_type, String(enemy.get("intent", "")))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 68)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.tooltip_text = "%s\nAttack %d, steal %d, bounty %d.\n%s" % [
		enemy_intent,
		int(enemy.get("attack", 0)),
		int(enemy.get("steal", 0)),
		int(enemy.get("reward", 0)),
		_boss_phase_text(enemy)
	] if language_id == "en_US" else "%s\n攻击 %d，偷钱 %d，赏金 %d。\n%s" % [
		enemy_intent,
		int(enemy.get("attack", 0)),
		int(enemy.get("steal", 0)),
		int(enemy.get("reward", 0)),
		_boss_phase_text(enemy)
	]
	panel.add_theme_stylebox_override("panel", style(Color(0.082, 0.024, 0.036) if is_boss else Color(0.034, 0.044, 0.056), 4, DANGER if is_boss else BLUE.darkened(0.10), 2))

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
	name.text = "%s%s" % ["BOSS  " if is_boss else "", enemy_name]
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
	stats.text = "HP %d/%d  Shield %d  Atk %d  Bounty %d" % [
		int(enemy.get("hp", 0)),
		int(enemy.get("max_hp", 0)),
		int(enemy.get("shield", 0)),
		int(enemy.get("attack", 0)),
		int(enemy.get("reward", 0))
	] if language_id == "en_US" else "HP %d/%d  盾 %d  攻 %d  赏 %d" % [
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
	intent.text = _boss_phase_text(enemy) if is_boss else enemy_intent
	intent.add_theme_font_size_override("font_size", 10)
	intent.add_theme_color_override("font_color", Color(0.68, 0.82, 0.86))
	intent.clip_text = true
	stack.add_child(intent)
	return panel


func _build_relic_offer(offer_index: int, relic_id: String) -> Control:
	var config: Dictionary = RELICS[relic_id]
	var button := _make_small_button("%s  %d coins" % [_relic_name(relic_id), int(config["cost"])] if language_id == "en_US" else "%s  %d金" % [_relic_name(relic_id), int(config["cost"])])
	button.custom_minimum_size = Vector2(0, 36)
	_apply_button_icon(button, _relic_texture(relic_id))
	button.tooltip_text = _relic_tip(relic_id)
	button.disabled = not is_intermission or game_state.coins < int(config["cost"])
	button.pressed.connect(_buy_relic_offer.bind(offer_index))
	return button


func _build_consumable_offer(offer_index: int, item_id: String) -> Control:
	var config: Dictionary = CONSUMABLES[item_id]
	var button := _make_small_button("%s  %d coins" % [_consumable_name(item_id), int(config["cost"])] if language_id == "en_US" else "%s  %d金" % [_consumable_name(item_id), int(config["cost"])])
	button.custom_minimum_size = Vector2(0, 36)
	_apply_button_icon(button, _consumable_texture(item_id))
	button.tooltip_text = _consumable_tip(item_id)
	button.disabled = not is_intermission or game_state.coins < int(config["cost"])
	button.pressed.connect(_buy_consumable_offer.bind(offer_index))
	return button


func _build_curse_offer(offer_index: int, curse_id: String) -> Control:
	var config: Dictionary = CURSE_DEALS[curse_id]
	var button := _make_small_button("%s  +%d coins" % [_curse_name(curse_id), int(config["reward"])] if language_id == "en_US" else "%s  +%d金" % [_curse_name(curse_id), int(config["reward"])])
	button.custom_minimum_size = Vector2(0, 36)
	_apply_button_icon(button, _curse_texture(curse_id))
	button.tooltip_text = _curse_tip(curse_id)
	button.disabled = not is_intermission
	button.pressed.connect(_accept_curse_offer.bind(offer_index))
	return button


func _buy_relic_offer(offer_index: int) -> void:
	if not is_intermission:
		_update_ui("Relics can only be bought during planning." if language_id == "en_US" else "回合中不能购买遗物。")
		return
	if offer_index < 0 or offer_index >= relic_offer_ids.size():
		return
	var relic_id := relic_offer_ids[offer_index]
	var cost := int(RELICS[relic_id]["cost"])
	if game_state.coins < cost:
		_play_sfx("hurt")
		_update_ui("Not enough coins. Buying %s costs %d coins." % [_relic_name(relic_id), cost] if language_id == "en_US" else "金币不足，购买 %s 需要 %d 金币。" % [_relic_name(relic_id), cost])
		return
	game_state.coins -= cost
	owned_relics.append(relic_id)
	relic_offer_ids.remove_at(offer_index)
	_rebuild_relic_market()
	_play_sfx("upgrade")
	_update_ui("Gained relic: %s. %s" % [_relic_name(relic_id), _relic_tip(relic_id)] if language_id == "en_US" else "获得遗物：%s。%s" % [_relic_name(relic_id), _relic_tip(relic_id)])


func _buy_consumable_offer(offer_index: int) -> void:
	if not is_intermission:
		_update_ui("Shop items can only be used during planning." if language_id == "en_US" else "回合中不能使用商店道具。")
		return
	if offer_index < 0 or offer_index >= consumable_offer_ids.size():
		return
	var item_id := consumable_offer_ids[offer_index]
	var cost := int(CONSUMABLES[item_id]["cost"])
	if game_state.coins < cost:
		_play_sfx("error")
		_update_ui("Not enough coins. Buying %s costs %d coins." % [_consumable_name(item_id), cost] if language_id == "en_US" else "金币不足，购买 %s 需要 %d 金币。" % [_consumable_name(item_id), cost])
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
			if language_id == "en_US":
				return "Used Health Potion. Health restored to %d/%d." % [player_health, MAX_HEALTH]
			return "使用生命药水，恢复到 %d/%d 生命。" % [player_health, MAX_HEALTH]
		"smoke_bomb":
			for index in range(TOTAL_SLOTS):
				if not board_tiles[index].is_empty():
					for key in ["locked_turns", "jammed_turns", "polluted_turns", "steal_mark_turns"]:
						board_tiles[index][key] = 0
			if language_id == "en_US":
				return "Used Smoke Bomb. Cleared all board disruption."
			return "使用烟雾弹，清除所有棋盘干扰。"
		"lucky_ticket":
			manual_clicks_left += 2
			if language_id == "en_US":
				return "Used Lucky Ticket. Gained 2 extra manual triggers this round."
			return "使用幸运券，本回合额外获得 2 次手动触发。"
		"market_tip":
			var boosted := 0
			for index in range(TOTAL_SLOTS):
				if not board_tiles[index].is_empty() and String(board_tiles[index]["type"]) == "stock":
					board_tiles[index]["stock_step"] = min(6, int(board_tiles[index].get("stock_step", 0)) + 2)
					boosted += 1
			if language_id == "en_US":
				return "Used Market Tip. Boosted %d Stock coin(s)." % boosted
			return "使用内幕消息，提升 %d 枚股票硬币。" % boosted
		"repair_kit":
			var repaired := 0
			for index in range(TOTAL_SLOTS):
				if not board_tiles[index].is_empty() and bool(board_tiles[index].get("broken", false)):
					board_tiles[index]["broken"] = false
					repaired += 1
			if language_id == "en_US":
				return "Used Repair Kit. Repaired %d shattered coin(s)." % repaired
			return "使用修复包，修复 %d 枚破碎硬币。" % repaired
	return "Used item." if language_id == "en_US" else "使用道具。"


func _accept_curse_offer(offer_index: int) -> void:
	if not is_intermission:
		_update_ui("Curse trades can only be accepted during planning." if language_id == "en_US" else "回合中不能接受诅咒交易。")
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
	_update_ui("Accepted curse trade: %s. %s" % [_curse_name(curse_id), _curse_tip(curse_id)] if language_id == "en_US" else "接受诅咒交易：%s。%s" % [_curse_name(curse_id), _curse_tip(curse_id)])


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
	summary.text = "Fate Bag %d | Locked %d/%d\n%s" % [
		coin_bag.size(),
		locked_hand_tiles.size(),
		MAX_LOCKED_HAND,
		_bag_summary()
	] if language_id == "en_US" else "命运袋 %d 枚 | 锁定 %d/%d\n%s" % [
		coin_bag.size(),
		locked_hand_tiles.size(),
		MAX_LOCKED_HAND,
		_bag_summary()
	]
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 15)
	summary.add_theme_color_override("font_color", CREAM)
	bag_container.add_child(summary)

	var reroll := _make_small_button("Reroll unlocked hand: %d coins" % REROLL_COST if language_id == "en_US" else "重抽未锁手牌：%d 金币" % REROLL_COST)
	reroll.disabled = not is_intermission or hand_tiles.size() <= locked_hand_tiles.size()
	reroll.pressed.connect(_reroll_unlocked_hand)
	bag_container.add_child(reroll)

	var lock_label := Label.new()
	lock_label.text = "Lock Hand Coins" if language_id == "en_US" else "锁定手牌"
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
		var text := "Unlock %s" % _tile_name(tile_type) if locked_count > 0 and language_id == "en_US" else "Lock %s" % _tile_name(tile_type) if language_id == "en_US" else "解锁 %s" % _tile_name(tile_type) if locked_count > 0 else "锁定 %s" % _tile_name(tile_type)
		var button := _make_small_button("%s  %d/%d" % [text, locked_count, hand_count])
		button.disabled = not is_intermission
		button.pressed.connect(_toggle_hand_lock.bind(tile_type))
		lock_row.add_child(button)

	var remove_label := Label.new()
	remove_label.text = "Remove From Bag" if language_id == "en_US" else "移除袋内硬币"
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
		var button := _make_small_button("Remove %s x%d: %d" % [_tile_name(String(tile_type)), int(bag_counts[tile_type]), cost] if language_id == "en_US" else "移除 %s x%d：%d" % [_tile_name(String(tile_type)), int(bag_counts[tile_type]), cost])
		button.disabled = not is_intermission or coin_bag.size() <= HAND_SIZE or game_state.coins < cost
		button.pressed.connect(_remove_from_bag.bind(String(tile_type)))
		remove_row.add_child(button)


func _buy_shop_offer(offer_index: int) -> void:
	if not is_intermission:
		_update_ui("Fate shop coins can only be bought during planning." if language_id == "en_US" else "回合中不能购买命运商店。")
		return
	if offer_index < 0 or offer_index >= shop_offer_types.size():
		return
	var tile_type := shop_offer_types[offer_index]
	var cost := _shop_coin_cost(tile_type)
	if game_state.coins < cost:
		_play_sfx("error")
		_update_ui("Not enough coins. Buying %s costs %d coins." % [_tile_name(tile_type), cost] if language_id == "en_US" else "金币不足，购买 %s 需要 %d 金币。" % [_tile_name(tile_type), cost])
		return
	game_state.coins -= cost
	coin_bag.append(tile_type)
	shop_offer_types.remove_at(offer_index)
	_rebuild_market()
	_rebuild_bag_manager()
	_play_sfx("buy")
	_update_ui("Bought %s into the fate bag. Fate bag now has %d coins." % [_tile_name(tile_type), coin_bag.size()] if language_id == "en_US" else "购买 %s 加入命运袋。命运袋现在有 %d 枚硬币。" % [_tile_name(tile_type), coin_bag.size()])


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
		return "Enemies cleared." if language_id == "en_US" else "敌人已被清空。"

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
		_pulse_stat_label(health_label, DANGER)
		if total_damage >= 6 or player_health <= 10:
			_show_impact_banner(
				"Enemy Strike -%d" % total_damage if language_id == "en_US" else "敌人攻势 -%d" % total_damage,
				"Health left %d/%d" % [player_health, MAX_HEALTH] if language_id == "en_US" else "剩余生命 %d/%d" % [player_health, MAX_HEALTH],
				DANGER
			)
			_play_sfx("warning")
		else:
			_show_combat_banner("Enemies dealt %d damage" % total_damage if language_id == "en_US" else "敌人造成 %d 伤害" % total_damage, DANGER)
		_play_sfx("error")
		_update_music_context()
	if total_stolen > 0:
		game_state.coins = max(0, game_state.coins - total_stolen)
		_pulse_stat_label(coin_label, GOLD)
		_show_combat_banner("Enemies stole %d coins" % total_stolen if language_id == "en_US" else "敌人偷走 %d 金币" % total_stolen, Color(1.0, 0.55, 0.24))

	if player_health <= 0:
		_play_sfx("error")
		_show_run_end(false, "敌人突破了你的命运棋盘。")

	var separator := "; " if language_id == "en_US" else "；"
	var interference_text := " " + separator.join(interference_reports) if not interference_reports.is_empty() else ""
	if language_id == "en_US":
		return "Enemies dealt %d damage and stole %d coins.%s" % [total_damage, total_stolen, interference_text]
	return "敌人造成 %d 伤害，偷走 %d 金币。%s" % [total_damage, total_stolen, interference_text]


func _enemy_summary() -> String:
	if enemies.is_empty():
		return "No enemies" if language_id == "en_US" else "无敌人"
	var parts: Array[String] = []
	for enemy in enemies:
		var shield_text := "+%d shield" % int(enemy.get("shield", 0)) if language_id == "en_US" and int(enemy.get("shield", 0)) > 0 else ("+%d盾" % int(enemy.get("shield", 0)) if int(enemy.get("shield", 0)) > 0 else "")
		parts.append("%s %d/%d%s" % [_enemy_name(String(enemy.get("type", ""))), int(enemy["hp"]), int(enemy["max_hp"]), shield_text])
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
		return _enemy_intent(String(enemy.get("type", "")), String(enemy.get("intent", "")))
	var phase := _boss_phase(enemy)
	if language_id == "en_US":
		match phase:
			3:
				return "Phase 3: desperate frenzy, extra disruption and higher attack."
			2:
				return "Phase 2: pressure rises with extra shield or theft."
			_:
				return "Phase 1: %s" % _enemy_intent(String(enemy.get("type", "")), String(enemy.get("intent", "")))
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
	var enemy_name := _enemy_name(String(enemy.get("type", "")))
	_show_combat_banner("%s entered %s" % [enemy_name, _boss_phase_text(enemy)] if language_id == "en_US" else "%s 进入 %s" % [enemy_name, _boss_phase_text(enemy)], Color(1.0, 0.25, 0.18))
	_show_impact_banner("Boss Phase %d" % phase if language_id == "en_US" else "Boss 阶段 %d" % phase, "%s: shields and attack pressure escalated" % enemy_name if language_id == "en_US" else "%s：护盾和攻击压力升级" % enemy_name, DANGER)
	_pulse_stat_label(enemy_label, Color(1.0, 0.25, 0.18))
	_play_sfx("boss")


func _apply_enemy_interference(enemy: Dictionary) -> String:
	var occupied := _occupied_slot_indices()
	if occupied.is_empty():
		return ""

	var enemy_type := String(enemy["type"])
	var enemy_name := _enemy_name(enemy_type)
	_apply_boss_phase(enemy)
	match enemy_type:
		"thief":
			var index := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[index]["steal_mark_turns"] = max(1, int(board_tiles[index].get("steal_mark_turns", 0)))
			return "%s marked %s and will steal its next payout" % [enemy_name, _slot_coin_name(index)] if language_id == "en_US" else "%s 标记了 %s，下回合会偷走其收益" % [enemy_name, _slot_coin_name(index)]
		"guard":
			var index := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[index]["locked_turns"] = max(1, int(board_tiles[index].get("locked_turns", 0)))
			enemy["shield"] = int(enemy.get("shield", 0)) + 2
			return "%s locked %s and gained shield" % [enemy_name, _slot_coin_name(index)] if language_id == "en_US" else "%s 锁住了 %s，并获得护盾" % [enemy_name, _slot_coin_name(index)]
		"sniper":
			var index := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[index]["jammed_turns"] = max(1, int(board_tiles[index].get("jammed_turns", 0)))
			return "%s jammed %s, lowering heads chance" % [enemy_name, _slot_coin_name(index)] if language_id == "en_US" else "%s 干扰了 %s，降低正面概率" % [enemy_name, _slot_coin_name(index)]
		"debt":
			var index := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[index]["polluted_turns"] = max(1, int(board_tiles[index].get("polluted_turns", 0)))
			return "%s polluted %s; triggering it costs coins and health" % [enemy_name, _slot_coin_name(index)] if language_id == "en_US" else "%s 污染了 %s，触发会扣钱并伤身" % [enemy_name, _slot_coin_name(index)]
		"taxer":
			var index := _highest_value_slot(occupied)
			board_tiles[index]["steal_mark_turns"] = max(1, int(board_tiles[index].get("steal_mark_turns", 0)))
			board_tiles[index]["jammed_turns"] = max(1, int(board_tiles[index].get("jammed_turns", 0)))
			return "%s targeted %s, stealing and jamming its payout" % [enemy_name, _slot_coin_name(index)] if language_id == "en_US" else "%s 盯上了 %s，偷取并干扰收益" % [enemy_name, _slot_coin_name(index)]
		"devourer":
			var index := _highest_level_slot(occupied)
			board_tiles[index]["polluted_turns"] = max(1, int(board_tiles[index].get("polluted_turns", 0)))
			return "%s bit into %s, polluting a core coin" % [enemy_name, _slot_coin_name(index)] if language_id == "en_US" else "%s 咬住了 %s，污染你的核心硬币" % [enemy_name, _slot_coin_name(index)]
		"hexer":
			var first := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[first]["jammed_turns"] = max(1, int(board_tiles[first].get("jammed_turns", 0)))
			var second := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[second]["polluted_turns"] = max(1, int(board_tiles[second].get("polluted_turns", 0)))
			return "%s cursed %s and %s" % [enemy_name, _slot_coin_name(first), _slot_coin_name(second)] if language_id == "en_US" else "%s 诅咒了 %s 和 %s" % [enemy_name, _slot_coin_name(first), _slot_coin_name(second)]
		"saboteur":
			var index := _highest_direction_slot(occupied)
			board_tiles[index]["jammed_turns"] = max(1, int(board_tiles[index].get("jammed_turns", 0)))
			board_tiles[index]["locked_turns"] = max(1, int(board_tiles[index].get("locked_turns", 0)))
			return "%s cut off %s's chain route" % [enemy_name, _slot_coin_name(index)] if language_id == "en_US" else "%s 剪断了 %s 的连锁路线" % [enemy_name, _slot_coin_name(index)]
		"healer":
			for i in range(enemies.size()):
				enemies[i]["hp"] = min(int(enemies[i]["max_hp"]), int(enemies[i]["hp"]) + 3)
			var index := occupied[rng.randi_range(0, occupied.size() - 1)]
			board_tiles[index]["steal_mark_turns"] = max(1, int(board_tiles[index].get("steal_mark_turns", 0)))
			return "%s repaired the enemy line and marked %s" % [enemy_name, _slot_coin_name(index)] if language_id == "en_US" else "%s 修补敌阵，并标记了 %s" % [enemy_name, _slot_coin_name(index)]
		"gambler_rat":
			var index := _highest_value_slot(occupied)
			if wager_mode == "greedy" or wager_mode == "all_in":
				board_tiles[index]["polluted_turns"] = max(1, int(board_tiles[index].get("polluted_turns", 0)))
				enemy["shield"] = int(enemy.get("shield", 0)) + 3
				return "%s fed on your risky wager, polluted %s, and gained shield" % [enemy_name, _slot_coin_name(index)] if language_id == "en_US" else "%s 被你的高风险下注刺激，污染了 %s 并加盾" % [enemy_name, _slot_coin_name(index)]
			board_tiles[index]["jammed_turns"] = max(1, int(board_tiles[index].get("jammed_turns", 0)))
			return "%s probed and jammed %s" % [enemy_name, _slot_coin_name(index)] if language_id == "en_US" else "%s 试探性干扰了 %s" % [enemy_name, _slot_coin_name(index)]
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
			return "%s froze a column: %s" % [enemy_name, ", ".join(reports)] if language_id == "en_US" else "%s 冻住一列：%s" % [enemy_name, "、".join(reports)]
		"mimic":
			var index := _highest_value_slot(occupied)
			var copied_type := String(board_tiles[index]["type"])
			var copied_level := int(board_tiles[index].get("level", 1))
			var copied: int = max(2, int(ceil(float(_tile_coin_value(copied_type, copied_level)) * 0.5)))
			enemy["shield"] = int(enemy.get("shield", 0)) + copied
			board_tiles[index]["steal_mark_turns"] = max(1, int(board_tiles[index].get("steal_mark_turns", 0)))
			return "%s copied %s and gained %d shield" % [enemy_name, _slot_coin_name(index), copied] if language_id == "en_US" else "%s 模仿 %s，获得 %d 护盾" % [enemy_name, _slot_coin_name(index), copied]
		"timekeeper":
			var index := _highest_click_slot(occupied)
			board_tiles[index]["jammed_turns"] = max(1, int(board_tiles[index].get("jammed_turns", 0)))
			board_tiles[index]["clicks_left"] = max(1, int(board_tiles[index].get("clicks_left", 1)) - 1)
			return "%s recalibrated %s, reducing triggers and odds" % [enemy_name, _slot_coin_name(index)] if language_id == "en_US" else "%s 校准了 %s，减少触发次数并降低概率" % [enemy_name, _slot_coin_name(index)]
		"lock_boss":
			var reports: Array[String] = []
			var locks: int = 2 + max(0, _boss_phase(enemy) - 1)
			for i in range(min(locks, occupied.size())):
				var index := _highest_level_slot(occupied)
				board_tiles[index]["locked_turns"] = max(1, int(board_tiles[index].get("locked_turns", 0)))
				reports.append(_slot_coin_name(index))
				occupied.erase(index)
			return "%s locked the core: %s" % [enemy_name, ", ".join(reports)] if language_id == "en_US" else "%s 锁住核心：%s" % [enemy_name, "、".join(reports)]
		"market_boss":
			var reports: Array[String] = []
			var marks: int = 3 + max(0, _boss_phase(enemy) - 1)
			for i in range(min(marks, occupied.size())):
				var index := _highest_value_slot(occupied)
				board_tiles[index]["steal_mark_turns"] = max(1, int(board_tiles[index].get("steal_mark_turns", 0)))
				board_tiles[index]["jammed_turns"] = max(1, int(board_tiles[index].get("jammed_turns", 0)))
				reports.append(_slot_coin_name(index))
				occupied.erase(index)
			return "%s shorted your core assets: %s" % [enemy_name, ", ".join(reports)] if language_id == "en_US" else "%s 做空了你的核心资产：%s" % [enemy_name, "、".join(reports)]
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
			return "%s added debt pressure: %s" % [enemy_name, ", ".join(reports)] if language_id == "en_US" else "%s 追加债务压力：%s" % [enemy_name, "、".join(reports)]
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
			return "%s mirrored the core route: %s" % [enemy_name, ", ".join(reports)] if language_id == "en_US" else "%s 映照核心路线：%s" % [enemy_name, "、".join(reports)]
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
			return "%s warped fate: %s" % [enemy_name, ", ".join(reports)] if language_id == "en_US" else "%s 扭曲了命运：%s" % [enemy_name, "、".join(reports)]
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
		return "Empty" if language_id == "en_US" else "空位"
	var tile_type := String(board_tiles[index]["type"])
	var x := index % GRID_COLUMNS
	var y := index / GRID_COLUMNS
	return "%s(%d,%d)" % [_tile_name(tile_type), x + 1, y + 1]


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
		return "Empty" if language_id == "en_US" else "空"
	var counts := _tile_counts(hand_tiles)
	var parts: Array[String] = []
	for tile_type in counts.keys():
		parts.append("%s x%d" % [_tile_name(String(tile_type)), int(counts[tile_type])])
	return " | ".join(parts)


func _bag_summary() -> String:
	if coin_bag.is_empty():
		return "Empty" if language_id == "en_US" else "空"
	var counts := _tile_counts(coin_bag)
	var parts: Array[String] = []
	for tile_type in counts.keys():
		parts.append("%s x%d" % [_tile_name(String(tile_type)), int(counts[tile_type])])
	return " | ".join(parts)


func _relic_summary() -> String:
	if owned_relics.is_empty():
		return "None" if language_id == "en_US" else "无"
	var parts: Array[String] = []
	for relic_id in owned_relics:
		parts.append(_relic_name(relic_id))
	return " | ".join(parts)


func _curse_summary() -> String:
	if active_curses.is_empty():
		return "None" if language_id == "en_US" else "无"
	var counts := {}
	for curse_id in active_curses:
		counts[curse_id] = int(counts.get(curse_id, 0)) + 1
	var parts: Array[String] = []
	for curse_id in counts.keys():
		parts.append("%s x%d" % [_curse_name(String(curse_id)), int(counts[curse_id])])
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
	label.add_theme_stylebox_override("normal", style(Color(0.034, 0.043, 0.056), 4, Color(0.32, 0.46, 0.54), 1))
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
	button.add_theme_color_override("font_color", INK)
	button.add_theme_stylebox_override("normal", style(color.darkened(0.06), 4, color.lightened(0.22), 1))
	button.add_theme_stylebox_override("hover", style(color.lightened(0.05), 4, Color.WHITE, 1))
	button.add_theme_stylebox_override("pressed", style(color.darkened(0.18), 4, Color(0, 0, 0, 0.35), 1))
	return button


func _apply_action_button_style(highlight: bool = false) -> void:
	if action_button == null:
		return
	var base := BLUE if is_intermission else GOLD
	if highlight:
		action_button.add_theme_color_override("font_color", INK)
		action_button.add_theme_stylebox_override("normal", style(base.lightened(0.12), 8, Color.WHITE, 3))
		action_button.add_theme_stylebox_override("hover", style(base.lightened(0.18), 8, Color.WHITE, 3))
		action_button.add_theme_stylebox_override("pressed", style(base.darkened(0.10), 8, Color(0, 0, 0, 0.35), 2))
		return
	action_button.add_theme_color_override("font_color", INK)
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
	_update_ui(_ui("tutorial_skipped"))


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
	var lines: Array[String] = [step_title]
	lines.append_array(_tutorial_progress_lines())
	lines.append(_tutorial_action_line())
	lines.append(_tutorial_reason_line())
	lines.append(_tutorial_next_line())
	return "\n".join(lines)


func _tutorial_progress_lines() -> Array[String]:
	var placed := _placed_tile_count()
	var clicked := best_chain_this_round > 0 or round_collected > 0 or round_damage > 0
	if language_id == "en_US":
		return [
			"Goals: [%s] place 3 coins (%d/3)  [%s] start round  [%s] click coin  [%s] settle" % [
				"x" if placed >= 3 else " ",
				min(3, placed),
				"x" if not is_intermission or game_state.current_round > 1 else " ",
				"x" if clicked else " ",
				"x" if is_intermission and game_state.current_round > 1 else " "
			]
		]
	return [
		"目标：[ %s ] 放置 3 枚硬币（%d/3）  [ %s ] 开始回合  [ %s ] 点击硬币  [ %s ] 结算" % [
			"x" if placed >= 3 else " ",
			min(3, placed),
			"x" if not is_intermission or game_state.current_round > 1 else " ",
			"x" if clicked else " ",
			"x" if is_intermission and game_state.current_round > 1 else " "
		]
	]


func _tutorial_action_line() -> String:
	if language_id == "en_US":
		match tutorial_focus:
			"place":
				return "Now: drag glowing hand coins onto glowing empty slots. Three coins are enough to start."
			"action_start":
				return "Now: press Start Round. Your placed coins will become clickable."
			"board_coin":
				return "Now: click glowing board coins. Each click can pay coins, deal damage, or chain outward."
			"action_end":
				return "Now: press End Round to resolve enemy pressure, pay quota, and open the market."
			_:
				return "Now: read the board, then choose the highest-value action."
	match tutorial_focus:
		"place":
			return "现在：把发光手牌拖到发光空位。先放 3 枚就足够开局。"
		"action_start":
			return "现在：点击“开始下一回合”。上阵硬币会进入可触发状态。"
		"board_coin":
			return "现在：点击发光棋盘硬币。每次点击可能赚钱、造成伤害或向外连锁。"
		"action_end":
			return "现在：点击“结束回合”，结算敌人压力、支付收取并打开商店。"
		_:
			return "现在：观察棋盘，选择收益最高的动作。"


func _tutorial_reason_line() -> String:
	if language_id == "en_US":
		match game_state.current_round:
			1:
				return "Why: this teaches the core loop: place, start, click, settle."
			2:
				return "Why: wagers and arrows decide whether your engine is safe, greedy, or chain-focused."
			3:
				return "Why: shop coins enter your fate bag for future draws, so plan one round ahead."
			4:
				return "Why: enemy marks can lock, jam, pollute, or steal from your best coins."
			5:
				return "Why: stable runs come from removing weak coins and upgrading a clear core."
		return "Why: the best run is a readable machine, not a single lucky flip."
	match game_state.current_round:
		1:
			return "原因：这会教会核心循环：布阵、开局、点击、结算。"
		2:
			return "原因：下注和方向决定你的机器更安全、更贪婪，还是更擅长连锁。"
		3:
			return "原因：商店买到的硬币会进入命运袋，未来抽到后才开始改变构筑。"
		4:
			return "原因：敌人标记会锁定、干扰、污染或偷走关键硬币收益。"
		5:
			return "原因：稳定通关来自移除弱硬币、升级核心硬币，并围绕清晰流派购买。"
	return "原因：最强的局是一台可读的机器，不是一次好运。"


func _tutorial_next_line() -> String:
	if language_id == "en_US":
		if is_intermission:
			return "Next: keep enough coins for quota %d, then buy or remove around one plan." % _round_quota_due()
		return "Next: use manual clicks before settling; finish when no good coin remains."
	if is_intermission:
		return "下一步：先留够本轮收取 %d 金币，再围绕一种计划购买或移除。" % _round_quota_due()
	return "下一步：结算前用完有价值的手动点击；没有好硬币时再结束回合。"


func _tutorial_step_title() -> String:
	if language_id == "en_US":
		match tutorial_focus:
			"place":
				return "Tutorial %d/5: Drag glowing hand coins to glowing slots" % game_state.current_round
			"action_start":
				return "Tutorial %d/5: Click the glowing button to start" % game_state.current_round
			"board_coin":
				return "Tutorial %d/5: Click glowing coins" % game_state.current_round
			"action_end":
				return "Tutorial %d/5: Click the glowing button to settle" % game_state.current_round
			_:
				return "Tutorial %d/5" % game_state.current_round
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
	game_over_dialog.title = _ui("game_over") if UI_TEXT[_valid_language(language_id)].has("game_over") else "游戏结束"
	game_over_dialog.dialog_text = ""
	game_over_dialog.ok_button_text = "Restart" if language_id == "en_US" else "重新开始"
	game_over_dialog.confirmed.connect(_restart_game)
	game_over_menu_button = game_over_dialog.add_button(_ui("back_to_menu"), false, "menu")
	game_over_dialog.custom_action.connect(_on_game_over_custom_action)
	add_child(game_over_dialog)


func _build_settlement_dialog() -> void:
	settlement_dialog = AcceptDialog.new()
	settlement_dialog.title = _ui("settlement_title")
	settlement_dialog.ok_button_text = _ui("settlement_ok")
	add_child(settlement_dialog)


func _build_confirm_dialogs() -> void:
	delete_save_confirm_dialog = ConfirmationDialog.new()
	delete_save_confirm_dialog.confirmed.connect(_delete_save_confirmed)
	add_child(delete_save_confirm_dialog)

	quit_confirm_dialog = ConfirmationDialog.new()
	quit_confirm_dialog.confirmed.connect(_quit_to_desktop_confirmed)
	add_child(quit_confirm_dialog)
	_apply_confirm_dialog_language()


func _apply_confirm_dialog_language() -> void:
	if delete_save_confirm_dialog != null:
		delete_save_confirm_dialog.title = _ui("confirm_delete_title")
		delete_save_confirm_dialog.dialog_text = _ui("confirm_delete_body")
		delete_save_confirm_dialog.ok_button_text = _ui("confirm")
		delete_save_confirm_dialog.get_cancel_button().text = _ui("cancel")
	if quit_confirm_dialog != null:
		quit_confirm_dialog.title = _ui("confirm_quit_title")
		quit_confirm_dialog.dialog_text = _ui("confirm_quit_body")
		quit_confirm_dialog.ok_button_text = _ui("confirm")
		quit_confirm_dialog.get_cancel_button().text = _ui("cancel")


func _build_settings_dialog() -> void:
	settings_dialog = AcceptDialog.new()
	settings_dialog.title = _ui("settings")
	settings_dialog.ok_button_text = _ui("save_settings")
	settings_dialog.confirmed.connect(_save_settings)
	add_child(settings_dialog)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	settings_dialog.add_child(column)

	settings_display_label = Label.new()
	settings_display_label.text = _ui("display")
	settings_display_label.add_theme_font_size_override("font_size", 18)
	settings_display_label.add_theme_color_override("font_color", GOLD)
	column.add_child(settings_display_label)

	fullscreen_toggle = CheckBox.new()
	fullscreen_toggle.text = _ui("fullscreen")
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	column.add_child(fullscreen_toggle)

	settings_window_label = Label.new()
	settings_window_label.text = _ui("window_size")
	settings_window_label.add_theme_font_size_override("font_size", 18)
	settings_window_label.add_theme_color_override("font_color", GOLD)
	column.add_child(settings_window_label)

	window_size_select = OptionButton.new()
	for size in WINDOW_SIZE_OPTIONS:
		window_size_select.add_item("%d x %d" % [size.x, size.y])
		window_size_select.set_item_metadata(window_size_select.item_count - 1, size)
	window_size_select.item_selected.connect(_on_window_size_selected)
	column.add_child(window_size_select)

	settings_volume_label = Label.new()
	settings_volume_label.text = _ui("sfx_volume")
	settings_volume_label.add_theme_font_size_override("font_size", 18)
	settings_volume_label.add_theme_color_override("font_color", GOLD)
	column.add_child(settings_volume_label)

	volume_slider = HSlider.new()
	volume_slider.min_value = -30.0
	volume_slider.max_value = 0.0
	volume_slider.step = 1.0
	volume_slider.value = sfx_volume_db
	volume_slider.value_changed.connect(_on_volume_changed)
	column.add_child(volume_slider)

	settings_music_label = Label.new()
	settings_music_label.text = _ui("music_volume")
	settings_music_label.add_theme_font_size_override("font_size", 18)
	settings_music_label.add_theme_color_override("font_color", GOLD)
	column.add_child(settings_music_label)

	music_volume_slider = HSlider.new()
	music_volume_slider.min_value = -40.0
	music_volume_slider.max_value = -4.0
	music_volume_slider.step = 1.0
	music_volume_slider.value = music_volume_db
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	column.add_child(music_volume_slider)

	mute_toggle = CheckBox.new()
	mute_toggle.text = _ui("mute")
	mute_toggle.button_pressed = audio_muted
	mute_toggle.toggled.connect(_on_mute_toggled)
	column.add_child(mute_toggle)

	settings_accessibility_label = Label.new()
	settings_accessibility_label.text = _ui("accessibility")
	settings_accessibility_label.add_theme_font_size_override("font_size", 18)
	settings_accessibility_label.add_theme_color_override("font_color", GOLD)
	column.add_child(settings_accessibility_label)

	reduced_motion_toggle = CheckBox.new()
	reduced_motion_toggle.text = _ui("reduced_motion")
	reduced_motion_toggle.button_pressed = reduced_motion_enabled
	reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	column.add_child(reduced_motion_toggle)

	settings_language_label = Label.new()
	settings_language_label.text = _ui("language")
	settings_language_label.add_theme_font_size_override("font_size", 18)
	settings_language_label.add_theme_color_override("font_color", GOLD)
	column.add_child(settings_language_label)

	language_select = OptionButton.new()
	language_select.add_item("简体中文")
	language_select.set_item_metadata(0, "zh_CN")
	language_select.add_item("English")
	language_select.set_item_metadata(1, "en_US")
	language_select.item_selected.connect(_on_language_selected)
	column.add_child(language_select)

	tutorial_toggle = CheckBox.new()
	tutorial_toggle.text = _ui("show_tutorial")
	tutorial_toggle.button_pressed = tutorial_enabled
	tutorial_toggle.toggled.connect(_on_tutorial_setting_toggled)
	column.add_child(tutorial_toggle)


func _build_rules_dialog() -> void:
	rules_dialog = AcceptDialog.new()
	rules_dialog.title = _ui("how_to_play")
	rules_dialog.ok_button_text = _ui("rules_close")
	rules_dialog.dialog_text = _rules_text()
	add_child(rules_dialog)


func _build_credits_dialog() -> void:
	credits_dialog = AcceptDialog.new()
	credits_dialog.title = _ui("credits")
	credits_dialog.ok_button_text = _ui("credits_close")
	credits_dialog.dialog_text = _credits_text()
	add_child(credits_dialog)


func _build_menu_overlay() -> void:
	menu_overlay = PanelContainer.new()
	menu_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_theme_stylebox_override("panel", style(Color(0.006, 0.010, 0.018, 0.96), 0))
	add_child(menu_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(980, 620)
	panel.add_theme_stylebox_override("panel", style(Color(0.020, 0.028, 0.040, 0.98), 5, MOON.darkened(0.18), 2))
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

	menu_subtitle_label = Label.new()
	menu_subtitle_label.text = _ui("menu_subtitle")
	menu_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_subtitle_label.add_theme_font_size_override("font_size", 18)
	menu_subtitle_label.add_theme_color_override("font_color", CREAM)
	showcase.add_child(menu_subtitle_label)

	var coin_frame := PanelContainer.new()
	coin_frame.custom_minimum_size = Vector2(0, 168)
	coin_frame.add_theme_stylebox_override("panel", style(Color(0.026, 0.038, 0.052), 4, Color(0.34, 0.52, 0.60), 1))
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
	menu_run_label.add_theme_stylebox_override("normal", style(Color(0.034, 0.044, 0.058), 4, BLUE.darkened(0.16), 1))
	showcase.add_child(menu_run_label)

	menu_progress_label = Label.new()
	menu_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_progress_label.add_theme_font_size_override("font_size", 16)
	menu_progress_label.add_theme_color_override("font_color", CREAM)
	menu_progress_label.add_theme_stylebox_override("normal", style(Color(0.040, 0.044, 0.062), 4, VIOLET.darkened(0.12), 1))
	showcase.add_child(menu_progress_label)

	menu_save_label = Label.new()
	menu_save_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_save_label.add_theme_font_size_override("font_size", 14)
	menu_save_label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.80))
	showcase.add_child(menu_save_label)

	var actions := VBoxContainer.new()
	actions.custom_minimum_size = Vector2(360, 0)
	actions.add_theme_constant_override("separation", 10)
	row.add_child(actions)

	menu_action_title_label = Label.new()
	menu_action_title_label.text = _ui("forge_table")
	menu_action_title_label.add_theme_font_size_override("font_size", 28)
	menu_action_title_label.add_theme_color_override("font_color", GOLD)
	actions.add_child(menu_action_title_label)

	difficulty_select = OptionButton.new()
	difficulty_select.add_theme_font_size_override("font_size", 18)
	for diff_id in DIFFICULTY_ORDER:
		difficulty_select.add_item("%s - %s" % [_difficulty_name(diff_id), _difficulty_tip(diff_id)])
		difficulty_select.set_item_metadata(difficulty_select.item_count - 1, diff_id)
	difficulty_select.selected = DIFFICULTY_ORDER.find(difficulty_id)
	difficulty_select.item_selected.connect(_on_difficulty_selected)
	actions.add_child(difficulty_select)

	menu_new_button = _make_action_button(_ui("new_game"), BLUE)
	menu_new_button.pressed.connect(_start_new_run_from_menu)
	actions.add_child(menu_new_button)

	menu_continue_button = _make_action_button(_ui("continue_game"), GREEN)
	menu_continue_button.pressed.connect(_continue_from_menu)
	actions.add_child(menu_continue_button)

	menu_save_button = _make_action_button(_ui("save_run"), MOON)
	menu_save_button.pressed.connect(_save_game)
	actions.add_child(menu_save_button)

	menu_delete_save_button = _make_action_button(_ui("delete_save"), DANGER)
	menu_delete_save_button.pressed.connect(_request_delete_save)
	actions.add_child(menu_delete_save_button)

	menu_settings_button = _make_action_button(_ui("settings"), Color(0.68, 0.74, 0.82))
	menu_settings_button.pressed.connect(_open_settings)
	actions.add_child(menu_settings_button)

	menu_rules_button = _make_action_button(_ui("how_to_play"), MINT)
	menu_rules_button.pressed.connect(_open_rules)
	actions.add_child(menu_rules_button)

	menu_credits_button = _make_action_button(_ui("credits"), Color(0.54, 0.64, 0.70))
	menu_credits_button.pressed.connect(_open_credits)
	actions.add_child(menu_credits_button)

	menu_close_button = _make_action_button(_ui("return_game"), BLUE)
	menu_close_button.pressed.connect(_hide_menu)
	actions.add_child(menu_close_button)

	menu_quit_button = _make_action_button(_ui("quit_desktop"), Color(0.38, 0.44, 0.50))
	menu_quit_button.pressed.connect(_request_quit_to_desktop)
	actions.add_child(menu_quit_button)


func _build_audio_players() -> void:
	_release_audio_players()
	for key in SFX_PATHS:
		var player := AudioStreamPlayer.new()
		player.stream = _load_wav_stream(SFX_PATHS[key])
		add_child(player)
		sfx_players[key] = player
	music_player = AudioStreamPlayer.new()
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	_apply_audio_settings()


func _load_wav_stream(path: String) -> AudioStreamWAV:
	var stream := ResourceLoader.load(path) as AudioStreamWAV
	if stream == null:
		return AudioStreamWAV.new()
	return stream


func _play_sfx(key: String) -> void:
	if DisplayServer.get_name() == "headless" or audio_muted:
		return
	if not sfx_players.has(key):
		return
	var player: AudioStreamPlayer = sfx_players[key]
	player.stop()
	player.play()


func _play_music(key: String) -> void:
	if DisplayServer.get_name() == "headless" or audio_muted:
		return
	if music_player == null or not MUSIC_PATHS.has(key):
		return
	if current_music_key == key and music_player.playing:
		return
	current_music_key = key
	music_player.stop()
	music_player.stream = _load_wav_stream(MUSIC_PATHS[key])
	_apply_audio_settings()
	music_player.play()


func _stop_music() -> void:
	current_music_key = ""
	if music_player != null:
		music_player.stop()


func _on_music_finished() -> void:
	if current_music_key != "" and music_player != null and not audio_muted:
		music_player.play()


func _update_music_context() -> void:
	if DisplayServer.get_name() == "headless" or audio_muted:
		return
	for enemy in enemies:
		if _is_boss_type(String(enemy.get("type", ""))):
			_play_music("boss")
			return
	if _is_warning_music_state():
		_play_music("warning")
		return
	_play_music("run")


func _is_warning_music_state() -> bool:
	if game_state == null:
		return false
	return player_health <= 10 or int(game_state.coins) < _round_quota_due()


func _release_audio_players() -> void:
	if music_player != null:
		music_player.stop()
		music_player.stream = null
		if music_player.get_parent() != null:
			music_player.get_parent().remove_child(music_player)
		music_player.free()
		music_player = null
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
	_update_ui()


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


func _ui(key: String) -> String:
	var lang := _valid_language(language_id)
	var active: Dictionary = UI_TEXT.get(lang, UI_TEXT["zh_CN"])
	if active.has(key):
		return String(active[key])
	var fallback: Dictionary = UI_TEXT["zh_CN"]
	return String(fallback.get(key, key))


func _rules_text() -> String:
	return _ui("rules_body")


func _credits_text() -> String:
	return _ui("credits_body")


func _localized_content(source: Dictionary, item_id: String, field: String, fallback: String) -> String:
	if language_id != "en_US" or not source.has(item_id):
		return fallback
	var entry: Dictionary = source[item_id]
	return String(entry.get(field, fallback))


func _tile_name(tile_type: String) -> String:
	var config: Dictionary = TILE_TYPES.get(tile_type, {})
	return _localized_content(TILE_TEXT_EN, tile_type, "name", String(config.get("name", tile_type)))


func _tile_tip(tile_type: String) -> String:
	var config: Dictionary = TILE_TYPES.get(tile_type, {})
	return _localized_content(TILE_TEXT_EN, tile_type, "tip", String(config.get("tip", "")))


func _starter_name(bag_id: String) -> String:
	var config: Dictionary = STARTER_BAGS.get(bag_id, {})
	return _localized_content(STARTER_TEXT_EN, bag_id, "name", String(config.get("name", bag_id)))


func _starter_tip(bag_id: String) -> String:
	var config: Dictionary = STARTER_BAGS.get(bag_id, {})
	return _localized_content(STARTER_TEXT_EN, bag_id, "tip", String(config.get("tip", "")))


func _wager_name(mode: String) -> String:
	var config: Dictionary = WAGER_MODES.get(mode, {})
	return _localized_content(WAGER_TEXT_EN, mode, "name", String(config.get("name", mode)))


func _wager_tip(mode: String) -> String:
	var config: Dictionary = WAGER_MODES.get(mode, {})
	return _localized_content(WAGER_TEXT_EN, mode, "tip", String(config.get("tip", "")))


func _difficulty_name(diff_id: String) -> String:
	var config: Dictionary = DIFFICULTIES.get(diff_id, {})
	return _localized_content(DIFFICULTY_TEXT_EN, diff_id, "name", String(config.get("name", diff_id)))


func _difficulty_tip(diff_id: String) -> String:
	var config: Dictionary = DIFFICULTIES.get(diff_id, {})
	return _localized_content(DIFFICULTY_TEXT_EN, diff_id, "tip", String(config.get("tip", "")))


func _enemy_name(enemy_type: String) -> String:
	var config: Dictionary = ENEMY_TYPES.get(enemy_type, {})
	return _localized_content(ENEMY_TEXT_EN, enemy_type, "name", String(config.get("name", enemy_type)))


func _enemy_intent(enemy_type: String, fallback: String = "") -> String:
	var config: Dictionary = ENEMY_TYPES.get(enemy_type, {})
	return _localized_content(ENEMY_TEXT_EN, enemy_type, "intent", fallback if fallback != "" else String(config.get("intent", "")))


func _relic_name(relic_id: String) -> String:
	var config: Dictionary = RELICS.get(relic_id, {})
	return _localized_content(RELIC_TEXT_EN, relic_id, "name", String(config.get("name", relic_id)))


func _relic_tip(relic_id: String) -> String:
	var config: Dictionary = RELICS.get(relic_id, {})
	return _localized_content(RELIC_TEXT_EN, relic_id, "tip", String(config.get("tip", "")))


func _consumable_name(item_id: String) -> String:
	var config: Dictionary = CONSUMABLES.get(item_id, {})
	return _localized_content(CONSUMABLE_TEXT_EN, item_id, "name", String(config.get("name", item_id)))


func _consumable_tip(item_id: String) -> String:
	var config: Dictionary = CONSUMABLES.get(item_id, {})
	return _localized_content(CONSUMABLE_TEXT_EN, item_id, "tip", String(config.get("tip", "")))


func _curse_name(curse_id: String) -> String:
	var config: Dictionary = CURSE_DEALS.get(curse_id, {})
	return _localized_content(CURSE_TEXT_EN, curse_id, "name", String(config.get("name", curse_id)))


func _curse_tip(curse_id: String) -> String:
	var config: Dictionary = CURSE_DEALS.get(curse_id, {})
	return _localized_content(CURSE_TEXT_EN, curse_id, "tip", String(config.get("tip", "")))


func _event_name(event: Dictionary) -> String:
	var raw_name := String(event.get("name", ""))
	if language_id == "en_US" and EVENT_TEXT_EN.has(raw_name):
		return String(EVENT_TEXT_EN[raw_name].get("name", raw_name))
	return raw_name


func _event_desc(event: Dictionary) -> String:
	var raw_name := String(event.get("name", ""))
	if language_id == "en_US" and EVENT_TEXT_EN.has(raw_name):
		return String(EVENT_TEXT_EN[raw_name].get("desc", event.get("desc", "")))
	return String(event.get("desc", ""))


func _set_option_items(select: OptionButton, ids: Array, name_callable: Callable) -> void:
	if select == null:
		return
	select.clear()
	for item_id in ids:
		select.add_item(String(name_callable.call(String(item_id))))
		select.set_item_metadata(select.item_count - 1, String(item_id))


func _refresh_content_language() -> void:
	if side_tabs != null and side_tabs.get_child_count() >= 3:
		side_tabs.get_child(0).name = _ui("hand_tab")
		side_tabs.get_child(1).name = _ui("shop_tab")
		side_tabs.get_child(2).name = _ui("manage_tab")
	if fate_hand_title_label != null:
		fate_hand_title_label.text = _ui("fate_hand")
	if starter_title_label != null:
		starter_title_label.text = _ui("starter_bag")
	if wager_title_label != null:
		wager_title_label.text = _ui("wager_mode")
	if shop_title_label != null:
		shop_title_label.text = _ui("fate_shop")
	if relic_title_label != null:
		relic_title_label.text = _ui("relic_shop")
	if consumable_title_label != null:
		consumable_title_label.text = _ui("consumables")
	if curse_title_label != null:
		curse_title_label.text = _ui("curse_trades")
	if bag_title_label != null:
		bag_title_label.text = _ui("fate_management")
	if delete_zone_label != null:
		delete_zone_label.text = _ui("recycle_zone")
	_set_option_items(starter_select, STARTER_BAG_ORDER, _starter_name)
	if starter_select != null:
		starter_select.selected = STARTER_BAG_ORDER.find(starter_bag_id)
		starter_select.tooltip_text = "Choose a starter fate bag. Hover hand coins for coin details." if language_id == "en_US" else "选择初始命运袋。悬停命运手牌可查看硬币详情。"
	_set_option_items(wager_select, WAGER_ORDER, _wager_name)
	if wager_select != null:
		wager_select.selected = WAGER_ORDER.find(wager_mode)
		wager_select.tooltip_text = "Choose this run's risk multiplier. Higher risk improves payout and raises failure costs." if language_id == "en_US" else "选择本局风险倍率。更高风险会提高收益，也会放大失败代价。"
	if difficulty_select != null:
		difficulty_select.clear()
		for diff_id in DIFFICULTY_ORDER:
			difficulty_select.add_item("%s - %s" % [_difficulty_name(diff_id), _difficulty_tip(diff_id)])
			difficulty_select.set_item_metadata(difficulty_select.item_count - 1, diff_id)
		difficulty_select.selected = DIFFICULTY_ORDER.find(difficulty_id)
	_rebuild_shop_palette()
	_rebuild_market()
	_rebuild_bag_manager()
	for index in range(slot_views.size()):
		_refresh_slot(index)


func _apply_language() -> void:
	if header_menu_button != null:
		header_menu_button.text = _ui("menu")
	if tutorial_button != null:
		tutorial_button.text = _ui("skip_tutorial")
	if settings_dialog != null:
		settings_dialog.title = _ui("settings")
		settings_dialog.ok_button_text = _ui("save_settings")
	if rules_dialog != null:
		rules_dialog.title = _ui("how_to_play")
		rules_dialog.ok_button_text = _ui("rules_close")
		rules_dialog.dialog_text = _rules_text()
	if credits_dialog != null:
		credits_dialog.title = _ui("credits")
		credits_dialog.ok_button_text = _ui("credits_close")
		credits_dialog.dialog_text = _credits_text()
	if game_over_dialog != null:
		game_over_dialog.title = _ui("game_over") if UI_TEXT[_valid_language(language_id)].has("game_over") else game_over_dialog.title
		game_over_dialog.ok_button_text = "Restart" if language_id == "en_US" else "重新开始"
	if game_over_menu_button != null:
		game_over_menu_button.text = _ui("back_to_menu")
	if settlement_dialog != null:
		settlement_dialog.title = _ui("settlement_title")
		settlement_dialog.ok_button_text = _ui("settlement_ok")
	if settings_display_label != null:
		settings_display_label.text = _ui("display")
	if fullscreen_toggle != null:
		fullscreen_toggle.text = _ui("fullscreen")
	if settings_window_label != null:
		settings_window_label.text = _ui("window_size")
	if settings_volume_label != null:
		settings_volume_label.text = _ui("sfx_volume")
	if settings_music_label != null:
		settings_music_label.text = _ui("music_volume")
	if mute_toggle != null:
		mute_toggle.text = _ui("mute")
	if settings_accessibility_label != null:
		settings_accessibility_label.text = _ui("accessibility")
	if reduced_motion_toggle != null:
		reduced_motion_toggle.text = _ui("reduced_motion")
	if settings_language_label != null:
		settings_language_label.text = _ui("language")
	if tutorial_toggle != null:
		tutorial_toggle.text = _ui("show_tutorial")
	if menu_subtitle_label != null:
		menu_subtitle_label.text = _ui("menu_subtitle")
	if menu_action_title_label != null:
		menu_action_title_label.text = _ui("forge_table")
	if menu_new_button != null:
		menu_new_button.text = _ui("new_game")
	if menu_save_button != null:
		menu_save_button.text = _ui("save_run")
	if menu_delete_save_button != null:
		menu_delete_save_button.text = _ui("delete_save")
	if menu_settings_button != null:
		menu_settings_button.text = _ui("settings")
	if menu_rules_button != null:
		menu_rules_button.text = _ui("how_to_play")
	if menu_credits_button != null:
		menu_credits_button.text = _ui("credits")
	if menu_close_button != null:
		menu_close_button.text = _ui("return_game")
	if menu_quit_button != null:
		menu_quit_button.text = _ui("quit_desktop")
	_apply_confirm_dialog_language()
	_refresh_content_language()
	_refresh_menu_state()
	_update_tutorial()
	_update_ui()


func _open_settings() -> void:
	if volume_slider != null:
		volume_slider.value = sfx_volume_db
	if music_volume_slider != null:
		music_volume_slider.value = music_volume_db
	if mute_toggle != null:
		mute_toggle.button_pressed = audio_muted
	if reduced_motion_toggle != null:
		reduced_motion_toggle.button_pressed = reduced_motion_enabled
	if window_size_select != null:
		_select_window_size_option()
	if language_select != null:
		_select_language_option()
	if tutorial_toggle != null:
		tutorial_toggle.button_pressed = tutorial_enabled
	if fullscreen_toggle != null:
		fullscreen_toggle.button_pressed = fullscreen_enabled
	settings_dialog.popup_centered()


func _open_rules() -> void:
	if rules_dialog == null:
		return
	rules_dialog.title = _ui("how_to_play")
	rules_dialog.ok_button_text = _ui("rules_close")
	rules_dialog.dialog_text = _rules_text()
	rules_dialog.popup_centered(Vector2i(780, 620))


func _open_credits() -> void:
	if credits_dialog == null:
		return
	credits_dialog.title = _ui("credits")
	credits_dialog.ok_button_text = _ui("credits_close")
	credits_dialog.dialog_text = _credits_text()
	credits_dialog.popup_centered(Vector2i(780, 640))


func _on_volume_changed(value: float) -> void:
	sfx_volume_db = value
	_apply_audio_settings()


func _on_music_volume_changed(value: float) -> void:
	music_volume_db = value
	_apply_audio_settings()


func _on_mute_toggled(enabled: bool) -> void:
	audio_muted = enabled
	_apply_audio_settings()
	if audio_muted:
		_stop_music()
	else:
		_update_music_context()


func _on_reduced_motion_toggled(enabled: bool) -> void:
	reduced_motion_enabled = enabled


func _on_window_size_selected(index: int) -> void:
	if window_size_select == null or index < 0 or index >= window_size_select.item_count:
		return
	window_size = _normalize_window_size(window_size_select.get_item_metadata(index))
	_apply_window_size_setting()


func _on_language_selected(index: int) -> void:
	if language_select == null or index < 0 or index >= language_select.item_count:
		return
	language_id = _valid_language(String(language_select.get_item_metadata(index)))
	_apply_language()
	_update_ui(_ui("language_changed") % _language_label(language_id))


func _on_tutorial_setting_toggled(enabled: bool) -> void:
	tutorial_enabled = enabled
	_update_tutorial()


func _on_fullscreen_toggled(enabled: bool) -> void:
	fullscreen_enabled = enabled
	_apply_fullscreen_setting()


func _apply_fullscreen_setting() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	if not fullscreen_enabled:
		_apply_window_size_setting()


func _apply_window_size_setting() -> void:
	if DisplayServer.get_name() == "headless" or fullscreen_enabled:
		return
	DisplayServer.window_set_size(window_size)
	var screen_size := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var centered_position := (screen_size - window_size) / 2
	DisplayServer.window_set_position(centered_position)


func _apply_audio_settings() -> void:
	var effective_sfx_volume := -80.0 if audio_muted else sfx_volume_db
	var effective_music_volume := -80.0 if audio_muted else music_volume_db
	for key in sfx_players:
		var player: AudioStreamPlayer = sfx_players[key]
		player.volume_db = effective_sfx_volume
	if music_player != null:
		music_player.volume_db = effective_music_volume


func _select_window_size_option() -> void:
	if window_size_select == null:
		return
	var normalized := _normalize_window_size(window_size)
	for index in range(window_size_select.item_count):
		if window_size_select.get_item_metadata(index) == normalized:
			window_size_select.selected = index
			return


func _select_language_option() -> void:
	if language_select == null:
		return
	for index in range(language_select.item_count):
		if String(language_select.get_item_metadata(index)) == language_id:
			language_select.selected = index
			return


func _valid_language(value: String) -> String:
	return value if LANGUAGE_OPTIONS.has(value) else "zh_CN"


func _language_label(value: String) -> String:
	return String(LANGUAGE_OPTIONS.get(_valid_language(value), "简体中文"))


func _normalize_window_size(value: Variant) -> Vector2i:
	var size := Vector2i(1600, 1000)
	if value is Vector2i:
		size = value
	elif value is Vector2:
		size = Vector2i(int(value.x), int(value.y))
	elif value is Dictionary:
		size = Vector2i(int(value.get("x", size.x)), int(value.get("y", size.y)))
	elif value is Array and value.size() >= 2:
		size = Vector2i(int(value[0]), int(value[1]))
	elif value is String:
		var parts := String(value).split("x")
		if parts.size() == 2:
			size = Vector2i(int(parts[0]), int(parts[1]))
	for option in WINDOW_SIZE_OPTIONS:
		if option == size:
			return option
	return Vector2i(1600, 1000)


func _request_quit_to_desktop() -> void:
	if quit_confirm_dialog == null:
		_quit_to_desktop_confirmed()
		return
	_apply_confirm_dialog_language()
	quit_confirm_dialog.popup_centered()


func _quit_to_desktop_confirmed() -> void:
	_save_settings()
	get_tree().quit()


func _on_difficulty_selected(index: int) -> void:
	if index < 0 or index >= DIFFICULTY_ORDER.size():
		return
	var selected := String(difficulty_select.get_item_metadata(index))
	if not _is_difficulty_unlocked(selected):
		_play_sfx("error")
		difficulty_select.selected = DIFFICULTY_ORDER.find(difficulty_id)
		_update_ui("That difficulty is not unlocked yet." if language_id == "en_US" else "该难度尚未解锁。")
		return
	difficulty_id = selected
	_update_ui("Difficulty changed to %s. New games will use it." % _difficulty_name(difficulty_id) if language_id == "en_US" else "难度切换为 %s。新游戏会使用该难度。" % _difficulty_name(difficulty_id))


func _refresh_menu_state() -> void:
	var has_save := FileAccess.file_exists(SAVE_PATH)
	if menu_progress_label != null:
		if language_id == "en_US":
			menu_progress_label.text = "Meta Progress\nBest Round: %d/%d    Victories: %d    Unlocked: %s" % [
				int(meta_progress.get("best_round", 1)),
				FINAL_ROUND,
			int(meta_progress.get("victories", 0)),
			_unlocked_difficulty_names()
			]
		else:
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
		menu_continue_button.text = _ui("continue_save") if has_save else _ui("no_save")
	if menu_save_button != null:
		menu_save_button.disabled = game_state == null
	if menu_delete_save_button != null:
		menu_delete_save_button.disabled = not has_save
	if difficulty_select != null:
		difficulty_select.selected = DIFFICULTY_ORDER.find(difficulty_id)
		for i in range(DIFFICULTY_ORDER.size()):
			var diff_id := String(DIFFICULTY_ORDER[i])
			difficulty_select.set_item_disabled(i, not _is_difficulty_unlocked(diff_id))


func _menu_current_run_text() -> String:
	if game_state == null:
		return "Current Run\nNot initialized." if language_id == "en_US" else "当前局\n尚未初始化。"
	if language_id == "en_US":
		return "Current Run\nDifficulty: %s    Phase: %s    Round: %d/%d\nCoins: %d    Health: %d/%d    Fate Bag: %d    Relics: %d\nRun Coins: %d    Run Damage: %d    Kills: %d    Best Chain: %d" % [
			_difficulty_name(difficulty_id),
			"Planning" if is_intermission else "Action",
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
	return "当前局\n难度：%s    阶段：%s    回合：%d/%d\n金币：%d    生命：%d/%d    命运袋：%d    遗物：%d\n本局收益：%d    本局伤害：%d    击败：%d    最高连锁：%d" % [
		_difficulty_name(difficulty_id),
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
		return "Save\nNo local save yet. You can save manually after starting a run; meta progress is kept separately." if language_id == "en_US" else "存档\n尚无本地存档。新游戏开始后可手动保存，也会保留永久进度。"
	var parsed = _read_json_dictionary(SAVE_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		return "Save\nA save exists, but its format is invalid." if language_id == "en_US" else "存档\n发现存档，但格式无效。"
	var data: Dictionary = parsed
	var save_difficulty := String(data.get("difficulty_id", "normal"))
	var save_round := int(data.get("current_round", 1))
	var save_coins := int(data.get("coins", 0))
	var save_health := int(data.get("player_health", STARTING_HEALTH))
	var save_bag := _string_array(data.get("coin_bag", []))
	var save_relics := _string_array(data.get("owned_relics", []))
	var diff_name := _difficulty_name(save_difficulty)
	if language_id == "en_US":
		return "Save\n%s    Round %d/%d    Coins %d    Health %d/%d    Fate Bag %d    Relics %d" % [
			diff_name,
			save_round,
			FINAL_ROUND,
			save_coins,
			save_health,
			MAX_HEALTH,
			save_bag.size(),
			save_relics.size()
		]
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
			names.append(_difficulty_name(diff_id))
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
	if language_id == "en_US":
		match _director_state():
			"mercy":
				return "Mercy"
			"pressure":
				return "Pressure"
			_:
				return "Steady"
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
		"music_volume_db": music_volume_db,
		"tutorial_enabled": tutorial_enabled,
		"audio_muted": audio_muted,
		"fullscreen_enabled": fullscreen_enabled,
		"reduced_motion_enabled": reduced_motion_enabled,
		"window_size": {"x": window_size.x, "y": window_size.y},
		"language_id": language_id
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
	_update_ui(_ui("settings_saved"))


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var parsed = _read_json_dictionary(SETTINGS_PATH, true)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	sfx_volume_db = float(data.get("sfx_volume_db", sfx_volume_db))
	music_volume_db = float(data.get("music_volume_db", music_volume_db))
	tutorial_enabled = bool(data.get("tutorial_enabled", tutorial_enabled))
	audio_muted = bool(data.get("audio_muted", audio_muted))
	fullscreen_enabled = bool(data.get("fullscreen_enabled", fullscreen_enabled))
	reduced_motion_enabled = bool(data.get("reduced_motion_enabled", reduced_motion_enabled))
	window_size = _normalize_window_size(data.get("window_size", window_size))
	language_id = _valid_language(String(data.get("language_id", language_id)))
	_apply_audio_settings()
	_apply_fullscreen_setting()


func _load_meta_progress() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var parsed = _read_json_dictionary(META_PATH, true)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	meta_progress = {
		"best_round": int(data.get("best_round", 1)),
		"victories": int(data.get("victories", 0)),
		"unlocked_difficulties": _string_array(data.get("unlocked_difficulties", ["normal"]))
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
		_update_ui("Save failed: could not write the save file." if language_id == "en_US" else "保存失败：无法写入存档。")
		return
	file.store_string(JSON.stringify(data))
	_play_sfx("settle")
	_update_ui("Run saved." if language_id == "en_US" else "当前局已保存。")
	_show_menu()


func _load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		_update_ui("No save file found." if language_id == "en_US" else "没有找到存档。")
		return false
	var parsed = _read_json_dictionary(SAVE_PATH, true)
	if typeof(parsed) != TYPE_DICTIONARY:
		_update_ui("Load failed: invalid save format. The corrupt save was quarantined." if language_id == "en_US" else "读取失败：存档格式无效，已隔离损坏存档。")
		return false
	_apply_save_data(parsed)
	_play_sfx("settle")
	_update_music_context()
	_update_ui("Save loaded." if language_id == "en_US" else "已读取存档。")
	return true


func _request_delete_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_update_ui("No save file to delete." if language_id == "en_US" else "没有可删除的存档。")
		_show_menu()
		return
	if delete_save_confirm_dialog == null:
		_delete_save_confirmed()
		return
	_apply_confirm_dialog_language()
	delete_save_confirm_dialog.popup_centered()


func _delete_save_confirmed() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_update_ui("Save deleted." if language_id == "en_US" else "存档已删除。")
	_show_menu()


func _apply_save_data(data: Dictionary) -> void:
	game_state.coins = max(0, int(data.get("coins", STARTING_COINS)))
	game_state.current_round = clampi(int(data.get("current_round", 1)), 1, FINAL_ROUND)
	game_state.required_coins = max(0, int(data.get("required_coins", STARTING_QUOTA)))
	player_health = clampi(int(data.get("player_health", STARTING_HEALTH)), 0, MAX_HEALTH)
	difficulty_id = String(data.get("difficulty_id", "normal"))
	if not _is_difficulty_unlocked(difficulty_id):
		difficulty_id = "normal"
	wager_mode = String(data.get("wager_mode", "standard"))
	if not WAGER_MODES.has(wager_mode):
		wager_mode = "standard"
	tutorial_enabled = bool(data.get("tutorial_enabled", tutorial_enabled))
	quota = max(STARTING_QUOTA, int(data.get("quota", STARTING_QUOTA)))
	starter_bag_id = String(data.get("starter_bag_id", "balanced"))
	if not STARTER_BAGS.has(starter_bag_id):
		starter_bag_id = "balanced"
	coin_bag = _string_array(data.get("coin_bag", []))
	hand_tiles = _string_array(data.get("hand_tiles", []))
	locked_hand_tiles = _string_array(data.get("locked_hand_tiles", []))
	removed_from_bag = max(0, int(data.get("removed_from_bag", 0)))
	shop_offer_types = _string_array(data.get("shop_offer_types", []))
	relic_offer_ids = _string_array(data.get("relic_offer_ids", []))
	consumable_offer_ids = _string_array(data.get("consumable_offer_ids", []))
	curse_offer_ids = _string_array(data.get("curse_offer_ids", []))
	owned_relics = _string_array(data.get("owned_relics", []))
	active_curses = _string_array(data.get("active_curses", []))
	enemies = _dict_array(data.get("enemies", []))
	current_event = Dictionary(data.get("current_event", {}))
	board_tiles = _dict_array(data.get("board_tiles", []))
	if board_tiles.size() > TOTAL_SLOTS:
		board_tiles.resize(TOTAL_SLOTS)
	while board_tiles.size() < TOTAL_SLOTS:
		board_tiles.append({})
	for index in range(TOTAL_SLOTS):
		board_tiles[index] = _sanitize_saved_tile(board_tiles[index])
	is_intermission = bool(data.get("is_intermission", true))
	if coin_bag.is_empty():
		_initialize_coin_bag()
	if hand_tiles.is_empty():
		_draw_hand()
	if current_event.is_empty():
		_pick_round_event()
	manual_clicks_left = max(0, int(data.get("manual_clicks_left", _round_manual_click_max())))
	round_collected = max(0, int(data.get("round_collected", 0)))
	round_damage = max(0, int(data.get("round_damage", 0)))
	round_failures = max(0, int(data.get("round_failures", 0)))
	run_total_collected = max(0, int(data.get("run_total_collected", 0)))
	run_total_damage = max(0, int(data.get("run_total_damage", 0)))
	run_kills = max(0, int(data.get("run_kills", 0)))
	run_best_chain = max(0, int(data.get("run_best_chain", 0)))
	best_chain_this_round = max(0, int(data.get("best_chain_this_round", 0)))
	_refresh_everything()


func _read_json_dictionary(path: String, quarantine_invalid: bool = false) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK or typeof(json.data) != TYPE_DICTIONARY:
		if quarantine_invalid:
			_quarantine_invalid_file(path)
		return null
	return Dictionary(json.data)


func _sanitize_saved_tile(tile: Dictionary) -> Dictionary:
	if tile.is_empty():
		return {}
	var tile_type := String(tile.get("type", ""))
	if not TILE_TYPES.has(tile_type):
		return {}
	var sanitized := _new_tile(tile_type)
	sanitized["level"] = clampi(int(tile.get("level", 1)), 1, MAX_TILE_LEVEL)
	sanitized["invested"] = max(0, int(tile.get("invested", 0)))
	sanitized["clicks_left"] = clampi(int(tile.get("clicks_left", _round_tile_click_max(sanitized))), 0, _round_tile_click_max(sanitized))
	sanitized["stock_step"] = int(tile.get("stock_step", 0))
	sanitized["forge_heat"] = max(0, int(tile.get("forge_heat", 0)))
	sanitized["bloom_growth"] = max(0, int(tile.get("bloom_growth", 0)))
	sanitized["broken"] = bool(tile.get("broken", false))
	sanitized["locked_turns"] = max(0, int(tile.get("locked_turns", 0)))
	sanitized["jammed_turns"] = max(0, int(tile.get("jammed_turns", 0)))
	sanitized["polluted_turns"] = max(0, int(tile.get("polluted_turns", 0)))
	sanitized["steal_mark_turns"] = max(0, int(tile.get("steal_mark_turns", 0)))
	sanitized["debt_marks"] = max(0, int(tile.get("debt_marks", 0)))
	sanitized["history"] = tile.get("history", []) if typeof(tile.get("history", [])) == TYPE_ARRAY else []
	return sanitized


func _quarantine_invalid_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var source := ProjectSettings.globalize_path(path)
	var target := "%s.corrupt" % source
	if FileAccess.file_exists(target):
		DirAccess.remove_absolute(target)
	DirAccess.rename_absolute(source, target)


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
	settlement_dialog.title = _ui("settlement_title")
	settlement_dialog.ok_button_text = _ui("settlement_ok")
	var summary := last_round_summary
	var recap := _tutorial_settlement_recap(summary)
	if language_id == "en_US":
		settlement_dialog.dialog_text = "Round %d Complete\nEvent: %s\nCoins this round: %d\nDamage this round: %d\nManual failures: %d\nQuota paid: %d\nBest chain: %d\nEnemy phase: %s\nCurrent coins: %d\nCurrent health: %d/%d\nFate bag: %d coins%s\n\nNext event: %s\nNew hand: %s\nNew enemies: %s\nMarket refreshed." % [
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
			recap,
			_event_name(current_event),
			_hand_summary(),
			_enemy_summary()
		]
		settlement_dialog.popup_centered()
		return
	settlement_dialog.dialog_text = "第 %d 回合完成\n事件：%s\n本轮获得金币：%d\n本轮造成伤害：%d\n手动失败次数：%d\n本轮收取金币：%d\n最高连锁：%d\n敌人回合：%s\n当前金币：%d\n当前生命：%d/%d\n命运袋：%d 枚%s\n\n下一回合事件：%s\n新手牌：%s\n新敌人：%s\n商店已经刷新。" % [
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
		recap,
		_event_name(current_event),
		_hand_summary(),
		_enemy_summary()
	]
	settlement_dialog.popup_centered()


func _tutorial_settlement_recap(summary: Dictionary) -> String:
	if not tutorial_enabled or int(summary.get("round", 0)) != 1:
		return ""
	var chain_line := _ui("tutorial_core_loop")
	if int(summary.get("best_chain", 0)) >= 2:
		chain_line = _ui("tutorial_chain_loop")
	return "\n\n%s\n%s\n%s" % [_ui("tutorial_recap"), chain_line, _ui("tutorial_next_steps")]


func _show_run_end(victory: bool, reason: String) -> void:
	_record_run_progress(victory)
	_stop_music()
	_play_sfx("victory" if victory else "error")
	var localized_reason := _run_end_reason_text(reason)
	_show_impact_banner("Fate Reclaimed" if victory and language_id == "en_US" else ("Run Ended" if language_id == "en_US" else ("命运逆转" if victory else "本局终止")), localized_reason, GOLD if victory else DANGER)
	game_over_dialog.title = "Fate Reclaimed" if victory and language_id == "en_US" else ("Game Over" if language_id == "en_US" else ("命运逆转" if victory else "游戏结束"))
	game_over_dialog.dialog_text = "%s\n\n%s\n\n%s" % [
		localized_reason,
		_run_score_summary(),
		_run_advice(victory, reason)
	]
	game_over_dialog.ok_button_text = "Restart" if language_id == "en_US" else "重新开始"
	game_over_dialog.popup_centered()


func _run_end_reason_text(reason: String) -> String:
	if language_id != "en_US":
		return reason
	if reason.find("庄家") != -1:
		return "You defeated the Fate Banker and won back a piece of your fate."
	if reason.find("金币") != -1:
		return "You could not pay this round's quota."
	if reason.find("高风险") != -1:
		return "Your high-risk wager overdrew your fate."
	if reason.find("代价") != -1:
		return "The price of your coins consumed you."
	if reason.find("敌人") != -1:
		return "Enemies broke through your fate board."
	return reason


func _run_score_summary() -> String:
	if language_id == "en_US":
		return "Difficulty: %s\nArchetype: %s\nReached round: %d/%d\nFinal coins: %d\nHealth left: %d/%d\nFate bag: %d coins\nRelics: %s\nTotal coins gained: %d\nTotal damage: %d\nEnemies defeated: %d\nBest chain: %d" % [
			_difficulty_name(difficulty_id),
			_starter_name(starter_bag_id),
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
	if language_id == "en_US":
		if victory:
			return "Suggestion: try another starting fate bag, or buy less and remove more in the shop for a steadier build."
		if reason.find("金币") != -1:
			return "Failure reason: economy failed. Spend less on early upgrades and rerolls, prioritize Bank, Lucky, or Stock, and choose safer wagers when needed."
		if reason.find("高风险") != -1 or reason.find("代价") != -1:
			return "Failure reason: risk overdraw. Avoid Greedy or All In under 10 health, or recover first with Vampire and Lucky coins."
		if reason.find("敌人") != -1:
			return "Failure reason: enemy pressure. Kill Sniper Rat and Debt Collector early, then clear locked or polluted core coins."
		if run_best_chain < 4:
			return "Failure reason: chains were too short. Try the Chain fate bag and buy directional coins, Star, Spirit, and Cross."
		return "Failure reason: the build was unstable. Remove extra basic coins, lock your core hand, and buy around one clear archetype."
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
	var hard_radius: int = min(radius, 5)
	box.corner_radius_top_left = hard_radius
	box.corner_radius_top_right = hard_radius
	box.corner_radius_bottom_left = hard_radius
	box.corner_radius_bottom_right = hard_radius
	box.border_color = border
	box.border_width_left = width
	box.border_width_top = width
	box.border_width_right = width
	box.border_width_bottom = width
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 8 if width > 0 else 3
	box.shadow_offset = Vector2(0, 3)
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
		_update_ui("Unlocked %s." % _tile_name(tile_type) if language_id == "en_US" else "已解锁 %s。" % _tile_name(tile_type))
		return
	if locked_hand_tiles.size() >= MAX_LOCKED_HAND:
		_play_sfx("error")
		_update_ui("You can lock at most %d hand coins." % MAX_LOCKED_HAND if language_id == "en_US" else "最多锁定 %d 枚手牌。" % MAX_LOCKED_HAND)
		return
	if _locked_count(tile_type) >= _hand_count(tile_type):
		return
	locked_hand_tiles.append(tile_type)
	_rebuild_bag_manager()
	_update_ui("Locked %s. It will stay through rerolls and the next draw." % _tile_name(tile_type) if language_id == "en_US" else "已锁定 %s，下次重抽或下回合会保留。" % _tile_name(tile_type))


func _reroll_unlocked_hand() -> void:
	if not is_intermission:
		return
	if game_state.coins < REROLL_COST:
		_play_sfx("error")
		_update_ui("Not enough coins. Reroll costs %d coins." % REROLL_COST if language_id == "en_US" else "金币不足，重抽需要 %d 金币。" % REROLL_COST)
		return
	game_state.coins -= REROLL_COST
	_draw_hand()
	_rebuild_shop_palette()
	_rebuild_bag_manager()
	_play_sfx("upgrade")
	_update_ui("Rerolled unlocked hand coins. Current hand: %s" % _hand_summary() if language_id == "en_US" else "重抽未锁手牌。当前手牌：%s" % _hand_summary())


func _remove_cost() -> int:
	var discount := 3 if owned_relics.has("void_purse") else 0
	return max(1, REMOVE_COST_BASE + removed_from_bag * 2 - discount)


func _remove_from_bag(tile_type: String) -> void:
	if not is_intermission:
		return
	if coin_bag.size() <= HAND_SIZE:
		_play_sfx("error")
		_update_ui("The fate bag must keep at least %d coins." % HAND_SIZE if language_id == "en_US" else "命运袋至少要保留 %d 枚硬币。" % HAND_SIZE)
		return
	var cost := _remove_cost()
	if game_state.coins < cost:
		_play_sfx("error")
		_update_ui("Not enough coins. Remove costs %d coins." % cost if language_id == "en_US" else "金币不足，移除需要 %d 金币。" % cost)
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
	_update_ui("Removed 1 %s. Fate bag now has %d coins." % [_tile_name(tile_type), coin_bag.size()] if language_id == "en_US" else "移除 1 枚 %s。命运袋现在有 %d 枚硬币。" % [_tile_name(tile_type), coin_bag.size()])


func _on_wager_selected(index: int) -> void:
	if index < 0 or index >= WAGER_ORDER.size():
		return
	wager_mode = String(wager_select.get_item_metadata(index))
	if wager_mode == "greedy" or wager_mode == "all_in":
		_show_combat_banner(_wager_warning_text(), Color(1.0, 0.45, 0.25))
		_pulse_stat_label(state_label, Color(1.0, 0.30, 0.20))
	_update_ui("Wager changed to %s: %s" % [_wager_name(wager_mode), _wager_tip(wager_mode)] if language_id == "en_US" else "下注模式切换为 %s：%s" % [_wager_name(wager_mode), _wager_tip(wager_mode)])


func _on_starter_bag_selected(index: int) -> void:
	if index < 0 or index >= STARTER_BAG_ORDER.size():
		return
	if game_state.current_round != 1 or not is_intermission or _placed_tile_count() > 0:
		_play_sfx("error")
		starter_select.selected = STARTER_BAG_ORDER.find(starter_bag_id)
		_update_ui("Starter bag can only be changed before placing coins in round 1." if language_id == "en_US" else "只能在第 1 回合布阵前切换初始命运袋。")
		return
	starter_bag_id = String(starter_select.get_item_metadata(index))
	_initialize_coin_bag()
	locked_hand_tiles.clear()
	removed_from_bag = 0
	_draw_hand()
	_rebuild_shop_palette()
	_rebuild_bag_manager()
	_update_ui("Selected %s fate bag. %s" % [_starter_name(starter_bag_id), _starter_tip(starter_bag_id)] if language_id == "en_US" else "已选择 %s 命运袋。%s" % [_starter_name(starter_bag_id), _starter_tip(starter_bag_id)])


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
			_update_ui("That coin is no longer in this round's hand." if language_id == "en_US" else "这枚硬币已经不在本回合手牌里了。")
			return
		if board_tiles[slot_index].is_empty():
			if not _consume_hand_tile(tile_type):
				return
			board_tiles[slot_index] = _new_tile(tile_type)
			_refresh_slot(slot_index)
			_play_sfx("buy")
			_update_ui("Placed %s. %d hand coins remain this round." % [_tile_name(tile_type), hand_tiles.size()] if language_id == "en_US" else "上阵 %s。本回合剩余手牌 %d 枚。" % [_tile_name(tile_type), hand_tiles.size()])
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
		_update_ui("Coin moved." if language_id == "en_US" else "硬币已移动。")


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
	_update_ui("Recycled %s and refunded %d invested upgrade coins." % [_tile_name(tile_type), refund] if language_id == "en_US" else "回收 %s，返还 %d 金币升级投资。" % [_tile_name(tile_type), refund])


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
		_update_ui("%s is already max level." % _tile_name(tile_type) if language_id == "en_US" else "%s 已经满级。" % _tile_name(tile_type))
		return
	var cost := _upgrade_cost(tile_type, level)
	if game_state.coins < cost:
		_update_ui("Not enough coins. Upgrade costs %d coins." % cost if language_id == "en_US" else "金币不足，升级需要 %d 金币。" % cost)
		return
	game_state.coins -= cost
	tile["level"] = level + 1
	tile["invested"] = int(tile.get("invested", 0)) + cost
	tile["clicks_left"] = _round_tile_click_max(tile)
	tile["broken"] = false
	board_tiles[slot_index] = tile
	_refresh_slot(slot_index)
	_play_sfx("upgrade")
	_update_ui("%s upgraded to Lv.%d. Payout and chain odds improved." % [_tile_name(tile_type), int(tile["level"])] if language_id == "en_US" else "%s 升到 Lv.%d，收益和触发率提升。" % [_tile_name(tile_type), int(tile["level"])])


func _on_slot_pressed(index: int) -> void:
	if is_intermission:
		_update_ui("Planning phase: coins cannot trigger yet. Press Start Round to collect coins and attack enemies." if language_id == "en_US" else "准备阶段不能触发硬币。点击“开始下一回合”后开始收集金币和攻击敌人。")
		return
	if manual_clicks_left <= 0:
		_update_ui("No manual clicks left this round. End the round to settle." if language_id == "en_US" else "本轮手动点击次数已用完，请结束回合。")
		return
	if board_tiles[index].is_empty():
		_update_ui("Empty slots have no coin, so they cannot pay or deal damage." if language_id == "en_US" else "空位没有硬币，不会触发金币和伤害。")
		return

	manual_clicks_left -= 1
	var result := _trigger_tile(index, true, 0)
	best_chain_this_round = max(best_chain_this_round, int(result["triggered"]))
	if int(result["triggered"]) > 1:
		_float_slot_text(index, "Total +%d coins / %d chain" % [int(result["coins"]), int(result["triggered"])] if language_id == "en_US" else "总计 +%d金 / %d连" % [int(result["coins"]), int(result["triggered"])], GOLD)
	if int(result["triggered"]) >= 5:
		_show_impact_banner("Fate Chain x%d" % int(result["triggered"]) if language_id == "en_US" else "命运连锁 x%d" % int(result["triggered"]), "+%d coins, %d total damage this round" % [int(result["coins"]), round_damage] if language_id == "en_US" else "+%d 金币，本轮累计 %d 伤害" % [int(result["coins"]), round_damage], BLUE)
	_update_ui("Manually triggered %d coin(s), gaining %d coins." % [result["triggered"], result["coins"]] if language_id == "en_US" else "手动触发 %d 枚硬币，获得 %d 金币。" % [result["triggered"], result["coins"]])


func _trigger_tile(index: int, is_manual: bool, depth: int) -> Dictionary:
	if depth > 80 or index < 0 or index >= TOTAL_SLOTS or board_tiles[index].is_empty():
		return {"coins": 0, "triggered": 0}

	var tile := board_tiles[index]
	if int(tile["clicks_left"]) <= 0:
		return {"coins": 0, "triggered": 0}
	if bool(tile.get("broken", false)):
		return {"coins": 0, "triggered": 0}
	if int(tile.get("locked_turns", 0)) > 0:
		_update_ui("%s is locked by enemies and cannot trigger this round." % _tile_name(String(tile["type"])) if language_id == "en_US" else "%s 被敌人锁住，本回合无法触发。" % _tile_name(String(tile["type"])))
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
		if self_damage > 0:
			_show_impact_banner("Coin Price" if language_id == "en_US" else "硬币代价", "-%d health" % self_damage if language_id == "en_US" else "-%d 生命" % self_damage, DANGER)
			_pulse_stat_label(health_label, DANGER)
			_play_sfx("warning")
			_update_music_context()
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
		_float_slot_text(next_index, "Chain" if language_id == "en_US" else "连锁", BLUE)
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
				result["heal"] = 2 + int(level >= 3)
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
			last_killed_name = _enemy_name(String(enemy.get("type", "")))
			enemies.remove_at(0)
			_update_ui("Defeated %s and gained %d bounty coins." % [last_killed_name, reward] if language_id == "en_US" else "击败 %s，获得 %d 金币赏金。" % [last_killed_name, reward])
			_play_sfx("settle")
		else:
			enemies[0] = enemy

	if killed_count > 0:
		var kill_text := "Defeated %s  +%d bounty coins" % [last_killed_name, total_reward] if killed_count == 1 and language_id == "en_US" else "Multi-KO x%d  +%d bounty coins" % [killed_count, total_reward] if language_id == "en_US" else "击破 %s  +%d 金币赏金" % [last_killed_name, total_reward] if killed_count == 1 else "连破 %d 名敌人  +%d 金币赏金" % [killed_count, total_reward]
		_show_combat_banner(kill_text, GOLD)
		_show_impact_banner("Defeated %s" % last_killed_name if killed_count == 1 and language_id == "en_US" else "Multi-KO x%d" % killed_count if language_id == "en_US" else "击破 %s" % last_killed_name if killed_count == 1 else "连破 x%d" % killed_count, "+%d bounty coins" % total_reward if language_id == "en_US" else "+%d 金币赏金" % total_reward, GOLD)
		_pulse_stat_label(enemy_label, GOLD)
		_update_music_context()
	elif total_dealt > 0 or total_absorbed > 0:
		var parts: Array[String] = []
		if total_dealt > 0:
			parts.append("Enemy hit %d" % total_dealt if language_id == "en_US" else "敌人受击 %d" % total_dealt)
		if total_absorbed > 0:
			parts.append("Shield absorbed %d" % total_absorbed if language_id == "en_US" else "护盾吸收 %d" % total_absorbed)
		_show_combat_banner(" / ".join(parts), Color(1.0, 0.78, 0.28))
		_pulse_stat_label(enemy_label, Color(1.0, 0.78, 0.28))
		_play_sfx("hit")


func _apply_failure_backlash() -> void:
	var damage := int(WAGER_MODES[wager_mode]["fail_damage"])
	if damage <= 0:
		return
	damage = _apply_self_damage_reduction(damage)
	player_health -= damage
	if damage > 0:
		_show_impact_banner("Wager Backlash" if language_id == "en_US" else "下注反噬", "-%d health" % damage if language_id == "en_US" else "-%d 生命" % damage, DANGER)
		_pulse_stat_label(health_label, DANGER)
		_play_sfx("warning")
		_play_sfx("hurt")
		_update_music_context()
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
	_update_music_context()
	_update_ui("Round started: %s. Current wager: %s. Clear enemies or chase coins; your call." % [_event_name(current_event), _wager_name(wager_mode)] if language_id == "en_US" else "回合开始：%s。当前下注：%s。先清敌人还是贪金币，交给你。" % [_event_name(current_event), _wager_name(wager_mode)])


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
		"event": _event_name(current_event),
		"enemy_report": enemy_report
	}
	if player_health <= 0:
		_update_ui(enemy_report)
		return

	game_state.coins -= due
	if game_state.coins < 0:
		_play_sfx("error")
		_play_sfx("warning")
		_update_ui("Not enough coins. Run over." if language_id == "en_US" else "金币不足，游戏结束。")
		_show_run_end(false, "金币不足以支付本轮收取。")
		return

	if game_state.current_round >= FINAL_ROUND and enemies.is_empty():
		_show_run_end(true, "你击败了命运庄家，暂时赢回了自己的命运。")
		is_intermission = true
		wager_select.disabled = false
		_update_ui("Victory! The 24-round challenge is complete." if language_id == "en_US" else "胜利！当前版本的 24 回合挑战已完成。")
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
	_update_music_context()
	_update_tutorial()
	_update_ui("%s Settlement complete; paid %d coins. New event: %s. Market refreshed." % [enemy_report, due, _event_name(current_event)] if language_id == "en_US" else "%s 结算完成并收取 %d 金币。新事件：%s。商店已刷新。" % [enemy_report, due, _event_name(current_event)])


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
	game_over_dialog.title = "Game Over" if language_id == "en_US" else "游戏结束"
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
	_update_music_context()
	_update_ui("Restarted. Planning phase: drag this round's hand to the board; shop buys enter the fate bag." if language_id == "en_US" else "已重新开始。准备阶段：拖拽本回合手牌上阵，商店购买会加入命运袋。")


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
		info.text = "Empty" if language_id == "en_US" else "空位"
		button.disabled = false
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_intermission else Control.MOUSE_FILTER_STOP
		button.tooltip_text = "Drag a hand coin here during planning. Empty slots do not trigger during action." if language_id == "en_US" else "准备阶段可拖入手牌硬币。回合中空位不会触发。"
		var highlight_empty := _should_highlight_empty_slot(index)
		slot.add_theme_stylebox_override("panel", style(SLOT_COLOR.lightened(0.08) if highlight_empty else SLOT_COLOR, 4, MOON if highlight_empty else Color(0.32, 0.47, 0.56), 3 if highlight_empty else 2))
		return

	var tile_type := String(tile["type"])
	var config: Dictionary = TILE_TYPES[tile_type]
	icon.texture = TILE_TEXTURES[tile_type]
	var level := int(tile.get("level", 1))
	var max_clicks := _round_tile_click_max(tile)
	var state_text := _tile_state_text(tile)
	info.text = "%s Lv.%d  %d/%d%s" % [_tile_name(tile_type), level, int(tile["clicks_left"]), max_clicks, state_text]
	button.disabled = is_intermission
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_intermission else Control.MOUSE_FILTER_STOP
	if language_id == "en_US":
		button.tooltip_text = "%s\n%s\nLv.%d heads coins %d, heads damage %d, heads chance %d%%, chain chance %d%%.\nTriggers left %d/%d. Drag a matching hand coin here to upgrade." % [
			_tile_tip(tile_type),
			_tile_state_description(tile),
			level,
			_tile_coin_value(tile_type, level),
			_tile_damage_value(tile_type, level),
			int(round(_coin_success_chance(tile_type, level) * 100.0)),
			int(round(_tile_trigger_chance(tile_type, level) * 100.0)),
			int(tile["clicks_left"]),
			max_clicks
		]
	else:
		button.tooltip_text = "%s\n%s\nLv.%d 正面金币 %d，正面伤害 %d，正面概率 %d%%，方向触发率 %d%%。\n剩余触发次数 %d/%d。同类手牌拖到这里可升级。" % [
			_tile_tip(tile_type),
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
	var slot_fill := Color(0.038, 0.052, 0.068).lightened(0.06) if highlight_coin else Color(0.032, 0.042, 0.054)
	var slot_border := MOON if highlight_coin else (border if not is_intermission else border.darkened(0.18))
	var slot_width := 4 if highlight_coin else 2 + level - 1
	slot.add_theme_stylebox_override("panel", style(slot_fill, 4, slot_border, slot_width))

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
	slot.add_theme_stylebox_override("panel", style(color, 4, Color.WHITE, 2))
	if reduced_motion_enabled:
		call_deferred("_refresh_slot", index)
		return
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
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 4)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.position.y = 14
	layer.add_child(label)

	if reduced_motion_enabled:
		label.position.y = -6
		label.modulate.a = 0.92
		get_tree().create_timer(0.38).timeout.connect(label.queue_free)
		return
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
	if reduced_motion_enabled:
		return
	var tween := create_tween()
	tween.tween_property(combat_feed_label, "scale", Vector2(1.04, 1.04), 0.08)
	tween.tween_property(combat_feed_label, "scale", Vector2.ONE, 0.12)


func _show_impact_banner(title: String, detail: String = "", color: Color = GOLD) -> void:
	if impact_panel == null or impact_title_label == null or title == "":
		return
	impact_title_label.text = title
	impact_detail_label.text = detail
	impact_title_label.add_theme_color_override("font_color", color)
	impact_panel.add_theme_stylebox_override("panel", style(Color(0.026, 0.038, 0.054, 0.94), 8, color, 2))
	impact_panel.visible = true
	if reduced_motion_enabled:
		impact_panel.modulate = Color(1, 1, 1, 1)
		impact_panel.scale = Vector2.ONE
		get_tree().create_timer(0.95).timeout.connect(func() -> void:
			if impact_panel != null:
				impact_panel.visible = false
		)
		return
	impact_panel.modulate = Color(1, 1, 1, 0)
	impact_panel.scale = Vector2(0.94, 0.94)
	impact_panel.pivot_offset = impact_panel.size * 0.5
	var tween := create_tween()
	tween.tween_property(impact_panel, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(impact_panel, "scale", Vector2(1.02, 1.02), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(impact_panel, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(0.78)
	tween.tween_property(impact_panel, "modulate:a", 0.0, 0.20)
	tween.tween_callback(func() -> void:
		if impact_panel != null:
			impact_panel.visible = false
	)


func _pulse_stat_label(label: Label, color: Color) -> void:
	if label == null:
		return
	var original := label.modulate
	label.modulate = color
	label.pivot_offset = label.size * 0.5
	if reduced_motion_enabled:
		label.modulate = original
		return
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(label, "scale", Vector2.ONE, 0.12)
	tween.tween_property(label, "modulate", original, 0.25)


func _show_boss_warning_if_needed() -> void:
	for enemy in enemies:
		if _is_boss_type(String(enemy["type"])):
			var enemy_name := _enemy_name(String(enemy.get("type", "")))
			var intent := _enemy_intent(String(enemy.get("type", "")), String(enemy.get("intent", "")))
			_show_combat_banner("Boss arrives: %s. %s" % [enemy_name, intent] if language_id == "en_US" else "Boss 出场：%s。%s" % [enemy_name, intent], Color(1.0, 0.28, 0.20))
			_show_impact_banner("Boss Arrives" if language_id == "en_US" else "Boss 出场", "%s: %s" % [enemy_name, intent] if language_id == "en_US" else "%s：%s" % [enemy_name, intent], DANGER)
			_pulse_stat_label(enemy_label, Color(1.0, 0.28, 0.20))
			_play_sfx("boss")
			_update_music_context()
			return


func _is_boss_type(enemy_type: String) -> bool:
	return enemy_type == "lock_boss" or enemy_type == "market_boss" or enemy_type == "debt_boss" or enemy_type == "mirror_boss" or enemy_type == "banker"


func _wager_warning_text() -> String:
	if wager_mode == "all_in":
		if language_id == "en_US":
			return "All In warning: huge burst, but every failed manual flip heavily damages you."
		return "梭哈警告：爆发极高，但每次手动失败都会重创生命。"
	if wager_mode == "greedy":
		if language_id == "en_US":
			return "Greedy warning: higher payout, failed manual flips hurt, and enemies hit harder."
		return "贪婪警告：收益提高，手动失败会扣生命，敌人也更凶。"
	return ""


func _outcome_feedback_text(outcome: Dictionary, coins: int, damage: int, is_heads: bool) -> String:
	if language_id == "en_US":
		var english_parts: Array[String] = ["Heads" if is_heads else "Tails"]
		if not bool(outcome["success"]):
			english_parts.append("miss")
		if coins > 0:
			english_parts.append("+%d coins" % coins)
		if damage > 0:
			english_parts.append("%d dmg" % damage)
		if int(outcome["heal"]) > 0:
			english_parts.append("+%d health" % int(outcome["heal"]))
		if int(outcome["manual_bonus"]) > 0:
			english_parts.append("+%d manual" % int(outcome["manual_bonus"]))
		if int(outcome["self_damage"]) > 0:
			english_parts.append("-%d health" % int(outcome["self_damage"]))
		if english_parts.size() == 1:
			english_parts.append("no gain")
		return " ".join(english_parts)
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
		if language_id == "en_US":
			return "  Broken"
		return "  破碎"
	var flags: Array[String] = []
	if int(tile.get("locked_turns", 0)) > 0:
		flags.append("Lock%d" % int(tile.get("locked_turns", 0)) if language_id == "en_US" else "锁")
	if int(tile.get("jammed_turns", 0)) > 0:
		flags.append("Jam%d" % int(tile.get("jammed_turns", 0)) if language_id == "en_US" else "扰")
	if int(tile.get("polluted_turns", 0)) > 0:
		flags.append("Pollute%d" % int(tile.get("polluted_turns", 0)) if language_id == "en_US" else "污")
	if int(tile.get("steal_mark_turns", 0)) > 0:
		flags.append("Steal%d" % int(tile.get("steal_mark_turns", 0)) if language_id == "en_US" else "偷")
	if tile_type == "stock":
		var stock_step := int(tile.get("stock_step", 0))
		if stock_step > 0:
			flags.append("Stock+%d" % stock_step if language_id == "en_US" else "+%d" % stock_step)
		if stock_step < 0:
			flags.append("Stock%d" % stock_step if language_id == "en_US" else "%d" % stock_step)
	if tile_type == "forge":
		var forge_heat := int(tile.get("forge_heat", 0))
		if forge_heat > 0:
			flags.append("Heat%d" % forge_heat if language_id == "en_US" else "热%d" % forge_heat)
	if tile_type == "debt_coin":
		var debt_marks := int(tile.get("debt_marks", 0))
		if debt_marks > 0:
			flags.append("Debt%d" % debt_marks if language_id == "en_US" else "债%d" % debt_marks)
	if tile_type == "bloom":
		var bloom_growth := int(tile.get("bloom_growth", 0))
		if bloom_growth > 0:
			flags.append("Bloom%d" % bloom_growth if language_id == "en_US" else "花%d" % bloom_growth)
	return "  " + "/".join(flags) if not flags.is_empty() else ""


func _tile_state_description(tile: Dictionary) -> String:
	var tile_type := String(tile["type"])
	if bool(tile.get("broken", false)):
		if language_id == "en_US":
			return "State: shattered. It cannot trigger; recycle or upgrade around it."
		return "状态：破碎，无法继续触发。回收或升级替换它。"
	var states: Array[String] = []
	if int(tile.get("locked_turns", 0)) > 0:
		states.append("locked for %d turn(s)" % int(tile.get("locked_turns", 0)) if language_id == "en_US" else "锁定：本回合无法触发")
	if int(tile.get("jammed_turns", 0)) > 0:
		states.append("jammed for %d turn(s), lowering heads chance" % int(tile.get("jammed_turns", 0)) if language_id == "en_US" else "干扰：正面概率 -20%")
	if int(tile.get("polluted_turns", 0)) > 0:
		states.append("polluted for %d turn(s), costing coins and health when triggered" % int(tile.get("polluted_turns", 0)) if language_id == "en_US" else "污染：正面概率 -10%，触发收益 -1 并扣 1 生命")
	if int(tile.get("steal_mark_turns", 0)) > 0:
		states.append("marked for theft for %d turn(s), enemy may steal its payout" % int(tile.get("steal_mark_turns", 0)) if language_id == "en_US" else "偷取标记：收益会被偷走一半")
	if tile_type == "stock":
		var stock_step := int(tile.get("stock_step", 0))
		states.append("stock trend %+d; heads rises, tails falls" % stock_step if language_id == "en_US" else "股票涨跌 %d 层，正面会继续涨，反面会回落" % stock_step)
	if tile_type == "forge":
		states.append("forge heat %d; heads heats up, tails cools down" % int(tile.get("forge_heat", 0)) if language_id == "en_US" else "熔炉热度 %d 层，正面会升温并提高后续收益" % int(tile.get("forge_heat", 0)))
	if tile_type == "debt_coin":
		states.append("%d debt mark(s), increasing end-round quota" % int(tile.get("debt_marks", 0)) if language_id == "en_US" else "债务标记 %d 层，每层会让本回合收取 +1" % int(tile.get("debt_marks", 0)))
	if tile_type == "bloom":
		states.append("bloom growth %d; heads grows, tails spends growth" % int(tile.get("bloom_growth", 0)) if language_id == "en_US" else "花层 %d 层，正面会成长并提高治疗/收益" % int(tile.get("bloom_growth", 0)))
	if states.is_empty():
		if language_id == "en_US":
			return "State: normal."
		return "状态：正常。"
	if language_id == "en_US":
		return "State: " + "; ".join(states) + "."
	return "状态：" + "；".join(states) + "。"


func _signed_value(value: int) -> String:
	return "+%d" % value if value > 0 else "%d" % value


func _event_effect_summary(event: Dictionary) -> String:
	var parts: Array[String] = []
	var coin_bonus := int(event.get("coin_bonus", 0))
	var trigger_bonus := float(event.get("trigger_bonus", 0.0))
	var manual_bonus := int(event.get("manual_bonus", 0))
	var quota_discount := int(event.get("quota_discount", 0))
	var click_bonus := int(event.get("click_bonus", 0))
	var enemy_attack_delta := int(event.get("enemy_attack_delta", 0))
	var shop_discount := int(event.get("shop_discount", 0))
	if language_id == "en_US":
		if coin_bonus != 0:
			parts.append("Coins %s" % _signed_value(coin_bonus))
		if not is_zero_approx(trigger_bonus):
			parts.append("Chain %s%%" % _signed_value(int(round(trigger_bonus * 100.0))))
		if manual_bonus != 0:
			parts.append("Manual %s" % _signed_value(manual_bonus))
		if quota_discount != 0:
			parts.append("Due %s" % _signed_value(-quota_discount))
		if click_bonus != 0:
			parts.append("Triggers %s" % _signed_value(click_bonus))
		if enemy_attack_delta != 0:
			parts.append("Enemy ATK %s" % _signed_value(enemy_attack_delta))
		if shop_discount != 0:
			parts.append("Market %s" % _signed_value(-shop_discount))
		return " / ".join(parts) if not parts.is_empty() else "No modifier"
	if coin_bonus != 0:
		parts.append("金币%s" % _signed_value(coin_bonus))
	if not is_zero_approx(trigger_bonus):
		parts.append("连锁%s%%" % _signed_value(int(round(trigger_bonus * 100.0))))
	if manual_bonus != 0:
		parts.append("手动%s" % _signed_value(manual_bonus))
	if quota_discount != 0:
		parts.append("收取%s" % _signed_value(-quota_discount))
	if click_bonus != 0:
		parts.append("触发%s" % _signed_value(click_bonus))
	if enemy_attack_delta != 0:
		parts.append("敌攻%s" % _signed_value(enemy_attack_delta))
	if shop_discount != 0:
		parts.append("商店%s" % _signed_value(-shop_discount))
	return " / ".join(parts) if not parts.is_empty() else "无修正"


func _hud_status_text() -> String:
	if language_id == "en_US":
		var top_line := "Event: %s | %s" % [_event_name(current_event), _event_effect_summary(current_event)]
		var bottom_line := "Wager: %s | Tempo: %s | Bag: %d | Relics: %d | Hand: %s | Round: +%dc / %d dmg | Due: %d | Chain: %d | Foes: %s" % [
			_wager_name(wager_mode),
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
		return "%s\n%s" % [top_line, bottom_line]
	var zh_top := "事件：%s | %s" % [_event_name(current_event), _event_effect_summary(current_event)]
	var zh_bottom := "下注：%s | 节奏：%s | 袋：%d | 遗物：%d | 手牌：%s | 本轮：+%d金 / %d伤 | 收取：%d | 连锁：%d | 敌人：%s" % [
		_wager_name(wager_mode),
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
	return "%s\n%s" % [zh_top, zh_bottom]


func _update_ui(message: String = "") -> void:
	coin_label.text = "%s\n%d" % [_ui("coins"), game_state.coins]
	health_label.text = "%s\n%d/%d" % [_ui("health"), player_health, MAX_HEALTH]
	round_label.text = "%s\n%d" % [_ui("round"), game_state.current_round]
	quota_label.text = "%s\n%d" % [_ui("quota"), quota]
	clicks_label.text = "%s\n%d/%d" % [_ui("manual"), manual_clicks_left, _round_manual_click_max()]
	enemy_label.text = "%s\n%d" % [_ui("enemy"), enemies.size()]
	state_label.text = "%s\n%s" % [_ui("state"), _ui("ready") if is_intermission else _ui("active")]
	if event_icon_rect != null:
		event_icon_rect.texture = _event_texture(current_event)
		event_icon_rect.tooltip_text = "%s\n%s" % [_event_name(current_event), _event_desc(current_event)]
	progress_label.text = _hud_status_text()
	notice_label.text = message
	action_button.text = _ui("start_round") if is_intermission else _ui("end_round")
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
