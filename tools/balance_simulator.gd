extends SceneTree

const MainScript = preload("res://scripts/main.gd")

const RUNS_PER_PAIR := 80
const REPORT_PATH := "res://BALANCE_SIMULATION_REPORT_CN.md"
const STARTERS := ["balanced", "chain", "gambler", "blood"]
const DIFFICULTIES := ["normal", "hard", "fate"]
const SHOP_BUY_LIMIT := 2

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20260611
	var rows: Array[Dictionary] = []
	for difficulty in DIFFICULTIES:
		for starter in STARTERS:
			rows.append(_simulate_pair(difficulty, starter))
	_write_report(rows)
	quit()


func _simulate_pair(difficulty: String, starter: String) -> Dictionary:
	var results: Array[Dictionary] = []
	for run_index in range(RUNS_PER_PAIR):
		results.append(_simulate_run(difficulty, starter, run_index))
	return _summarize_pair(difficulty, starter, results)


func _simulate_run(difficulty: String, starter: String, run_index: int) -> Dictionary:
	var state := {
		"difficulty": difficulty,
		"starter": starter,
		"coins": int(MainScript.DIFFICULTIES[difficulty]["start_coins"]),
		"health": MainScript.STARTING_HEALTH,
		"bag": _copy_string_array(MainScript.STARTER_BAGS[starter]["coins"]),
		"board": [],
		"owned_relics": [],
		"relic_offers": [],
		"round": 1,
		"total_coins": 0,
		"total_damage": 0,
		"kills": 0,
		"best_chain": 0,
		"death_reason": "",
		"run_index": run_index
	}
	for round_number in range(1, MainScript.FINAL_ROUND + 1):
		state["round"] = round_number
		var event: Dictionary = MainScript.ROUND_EVENTS[rng.randi_range(0, MainScript.ROUND_EVENTS.size() - 1)]
		var enemies := _spawn_enemies(round_number, difficulty)
		_intermission_build(state, round_number, event)
		var round_result := _play_round(state, enemies, event)
		state["total_coins"] = int(state["total_coins"]) + int(round_result["coins"])
		state["total_damage"] = int(state["total_damage"]) + int(round_result["damage"])
		state["kills"] = int(state["kills"]) + int(round_result["kills"])
		state["best_chain"] = max(int(state["best_chain"]), int(round_result["best_chain"]))

		if int(state["health"]) <= 0:
			state["death_reason"] = "生命耗尽"
			return _run_result(state, false)

		var due := _round_due(round_number, event, difficulty, state)
		state["coins"] = int(state["coins"]) - due
		if int(state["coins"]) < 0:
			state["death_reason"] = "经济断档"
			return _run_result(state, false)

		if round_number == MainScript.FINAL_ROUND and enemies.is_empty():
			return _run_result(state, true)

		_enemy_phase(state, enemies, event, difficulty)
		if int(state["health"]) <= 0:
			state["death_reason"] = "敌人伤害"
			return _run_result(state, false)

	state["death_reason"] = "未击败最终敌人"
	return _run_result(state, false)


func _intermission_build(state: Dictionary, round_number: int, event: Dictionary) -> void:
	_buy_relic_if_useful(state, round_number)
	var hand := _draw_hand(state["bag"], state)
	for tile_type in hand:
		if Array(state["board"]).size() >= MainScript.TOTAL_SLOTS:
			_try_upgrade_board_tile(state["board"], String(tile_type))
			break
		if Array(state["board"]).size() < _target_board_size(round_number):
			Array(state["board"]).append(_new_sim_tile(String(tile_type)))
		else:
			_try_upgrade_board_tile(state["board"], String(tile_type))

	var offers := _roll_shop_offers()
	var buys := 0
	for tile_type in offers:
		if buys >= SHOP_BUY_LIMIT:
			break
		var merchant_discount := 1 if Array(state["owned_relics"]).has("merchant_seal") else 0
		var cost: int = max(1, int(MainScript.TILE_TYPES[tile_type]["cost"]) - int(event.get("shop_discount", 0)) - merchant_discount)
		var reserve: int = _round_due(round_number, event, String(state["difficulty"]), state) + 4
		if int(state["coins"]) >= cost + reserve and _tile_buy_score(String(tile_type), round_number) >= 0:
			state["coins"] = int(state["coins"]) - cost
			Array(state["bag"]).append(String(tile_type))
			buys += 1
	_buy_relic_if_useful(state, round_number)


func _play_round(state: Dictionary, enemies: Array[Dictionary], event: Dictionary) -> Dictionary:
	for tile in Array(state["board"]):
		tile["clicks_left"] = max(1, MainScript.MAX_TILE_CLICKS + int(tile.get("level", 1)) - 1 + int(event.get("click_bonus", 0)))
		tile["history"] = []

	var clicks: int = max(1, MainScript.MAX_MANUAL_CLICKS + int(event.get("manual_bonus", 0)))
	var result := {"coins": 0, "damage": 0, "kills": 0, "best_chain": 0}
	for i in range(clicks):
		var index := _best_click_index(state["board"])
		if index == -1:
			break
		var trigger := _trigger_sim_tile(state, index, event, 0)
		result["coins"] = int(result["coins"]) + int(trigger["coins"])
		result["damage"] = int(result["damage"]) + int(trigger["damage"])
		result["best_chain"] = max(int(result["best_chain"]), int(trigger["chain"]))
		state["coins"] = int(state["coins"]) + int(trigger["coins"])
		_deal_damage(enemies, int(trigger["damage"]), state, result)
	return result


func _trigger_sim_tile(state: Dictionary, index: int, event: Dictionary, depth: int) -> Dictionary:
	if depth > 12 or index < 0 or index >= Array(state["board"]).size():
		return {"coins": 0, "damage": 0, "chain": 0}
	var tile: Dictionary = Array(state["board"])[index]
	if int(tile.get("clicks_left", 0)) <= 0:
		return {"coins": 0, "damage": 0, "chain": 0}
	tile["clicks_left"] = int(tile["clicks_left"]) - 1

	var tile_type := String(tile["type"])
	var level := int(tile.get("level", 1))
	var heads := rng.randf() < _coin_success_chance(state, tile_type, level)
	var flip := _resolve_sim_flip(state, tile, heads, event)
	var coins := int(flip["coins"])
	var damage := int(flip["damage"])
	var chain := 1

	if int(flip.get("heal", 0)) > 0:
		state["health"] = min(MainScript.MAX_HEALTH, int(state["health"]) + int(flip["heal"]))
	if int(flip.get("self_damage", 0)) > 0:
		state["health"] = max(0, int(state["health"]) - int(flip["self_damage"]))

	var directions := int(flip.get("directions", 0))
	for i in range(directions):
		if rng.randf() >= float(flip.get("chain_chance", 0.0)):
			continue
		var next_index := _random_clickable_index(state["board"])
		if next_index == -1:
			continue
		var chained := _trigger_sim_tile(state, next_index, event, depth + 1)
		coins += int(chained["coins"])
		damage += int(chained["damage"])
		chain += int(chained["chain"])

	return {"coins": coins, "damage": damage, "chain": chain}


func _resolve_sim_flip(state: Dictionary, tile: Dictionary, heads: bool, event: Dictionary) -> Dictionary:
	var tile_type := String(tile["type"])
	var level := int(tile.get("level", 1))
	var base_coins := _tile_coin_value(tile_type, level) + int(event.get("coin_bonus", 0))
	var base_damage := _tile_damage_value(tile_type, level)
	if Array(state["owned_relics"]).has("golden_glove"):
		base_coins += 1
	if Array(state["owned_relics"]).has("war_banner"):
		base_damage += 1
	var directions := Array(MainScript.TILE_TYPES[tile_type]["directions"]).size()
	var relic_trigger_bonus := 0.0
	if Array(state["owned_relics"]).has("chain_bell"):
		relic_trigger_bonus += 0.10
	if Array(state["owned_relics"]).has("silver_lens"):
		relic_trigger_bonus += 0.04
	var chain_chance := clampf(float(MainScript.TILE_TYPES[tile_type]["trigger_chance"]) + float(event.get("trigger_bonus", 0.0)) + relic_trigger_bonus + float(level - 1) * 0.05, 0.05, 0.95)
	var result := {
		"coins": base_coins if heads else 0,
		"damage": base_damage if heads else 0,
		"heal": 0,
		"self_damage": 0,
		"directions": directions if heads else 0,
		"chain_chance": chain_chance if heads else 0.0
	}
	match tile_type:
		"bank":
			if heads:
				result["coins"] = base_coins + 1
		"reverse":
			if not heads:
				result["coins"] = base_coins + 3 + level
				result["damage"] = base_damage + 3 + level
				result["directions"] = directions
				result["chain_chance"] = min(0.95, chain_chance + 0.18)
		"glass":
			if heads:
				result["coins"] = base_coins + 3 + level
				result["damage"] = base_damage + 3 + level
			else:
				result["damage"] = 1 + level
				result["self_damage"] = 1
		"lucky":
			if heads:
				result["heal"] = 1
				result["chain_chance"] = min(0.95, chain_chance + 0.12)
			else:
				result["coins"] = 0
		"stock":
			if heads:
				tile["stock_step"] = min(6, int(tile.get("stock_step", 0)) + 1)
				result["coins"] = base_coins + int(tile["stock_step"]) * (1 + level)
			else:
				tile["stock_step"] = max(-3, int(tile.get("stock_step", 0)) - 1)
				result["coins"] = 1
		"vampire":
			if heads:
				result["damage"] = base_damage + 2 + level
				result["heal"] = 1
			else:
				result["damage"] = base_damage + level
				result["self_damage"] = 1
		"spirit":
			if not heads:
				result["damage"] = 1
				result["directions"] = directions
				result["chain_chance"] = max(0.15, chain_chance - 0.15)
		"demon":
			result["self_damage"] = 1
			if heads:
				result["coins"] = base_coins + 4 + level
				result["damage"] = base_damage + 5 + level
			else:
				result["damage"] = base_damage + 3
		"forge":
			if heads:
				tile["forge_heat"] = min(5, int(tile.get("forge_heat", 0)) + 1)
				result["coins"] = base_coins + int(tile["forge_heat"])
				result["damage"] = base_damage + int(tile["forge_heat"])
			else:
				result["coins"] = 1
		"titan":
			if heads:
				result["coins"] = base_coins + 6 + level * 2
				result["damage"] = base_damage + 8 + level * 2
		"anchor":
			if not heads:
				result["heal"] = 2
	return result


func _deal_damage(enemies: Array[Dictionary], damage: int, state: Dictionary, round_result: Dictionary) -> void:
	var remaining := damage
	while remaining > 0 and not enemies.is_empty():
		var enemy := enemies[0]
		var shield_absorb: int = min(remaining, int(enemy.get("shield", 0)))
		enemy["shield"] = int(enemy.get("shield", 0)) - shield_absorb
		remaining -= shield_absorb
		if remaining <= 0:
			break
		var dealt: int = min(remaining, int(enemy["hp"]))
		enemy["hp"] = int(enemy["hp"]) - dealt
		remaining -= dealt
		if int(enemy["hp"]) <= 0:
			var reward := int(enemy["reward"])
			state["coins"] = int(state["coins"]) + reward
			round_result["coins"] = int(round_result["coins"]) + reward
			round_result["kills"] = int(round_result["kills"]) + 1
			enemies.remove_at(0)


func _enemy_phase(state: Dictionary, enemies: Array[Dictionary], event: Dictionary, difficulty: String) -> void:
	var damage := 0
	var stolen := 0
	var due := _round_due(int(state["round"]), event, difficulty, state)
	var director_delta := -2 if int(state["health"]) <= 12 or int(state["coins"]) < due else 0
	for enemy in enemies:
		damage += max(0, int(enemy["attack"]) + int(event.get("enemy_attack_delta", 0)) + director_delta)
		stolen += int(enemy.get("steal", 0))
	if Array(state["owned_relics"]).has("shield_charm"):
		damage = max(0, damage - 2)
	if difficulty == "hard":
		damage = int(ceil(float(damage) * 1.08))
	elif difficulty == "fate":
		damage = int(ceil(float(damage) * 1.16))
	state["health"] = max(0, int(state["health"]) - damage)
	state["coins"] = max(0, int(state["coins"]) - stolen)


func _spawn_enemies(round_number: int, difficulty: String) -> Array[Dictionary]:
	var enemies: Array[Dictionary] = []
	if round_number >= MainScript.FINAL_ROUND:
		enemies.append(_make_enemy("banker", round_number, difficulty))
		return enemies
	if round_number == 20:
		enemies.append(_make_enemy("mirror_boss", round_number, difficulty))
		return enemies
	if round_number == 16:
		enemies.append(_make_enemy("debt_boss", round_number, difficulty))
		return enemies
	if round_number == 12:
		enemies.append(_make_enemy("market_boss", round_number, difficulty))
		return enemies
	if round_number == 8:
		enemies.append(_make_enemy("lock_boss", round_number, difficulty))
		return enemies

	var enemy_count := _enemy_count_for_round(round_number, difficulty)
	var pool: Array[String] = ["thief"]
	if round_number >= 3:
		pool.append("guard")
	if round_number >= 5:
		pool.append("sniper")
	if round_number >= 10:
		pool.append_array(["debt", "taxer"])
	if round_number >= 12:
		pool.append_array(["devourer", "saboteur"])
	if round_number >= 14:
		pool.append_array(["hexer", "healer"])
	if round_number >= 17:
		pool.append_array(["gambler_rat", "frost"])
	if round_number >= 21:
		pool.append_array(["mimic", "timekeeper"])
	for i in range(enemy_count):
		enemies.append(_make_enemy(pool[rng.randi_range(0, pool.size() - 1)], round_number, difficulty))
	return enemies


func _enemy_count_for_round(round_number: int, difficulty: String) -> int:
	if difficulty == "normal":
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


func _make_enemy(enemy_type: String, round_number: int, difficulty: String) -> Dictionary:
	var config: Dictionary = MainScript.ENEMY_TYPES[enemy_type]
	var growth := 0.10 if difficulty == "normal" else 0.14
	var scale := (1.0 + float(max(0, round_number - 1)) * growth) * float(MainScript.DIFFICULTIES[difficulty]["enemy_mult"])
	if enemy_type == "banker":
		var boss_growth := 0.08 if difficulty == "normal" else 0.10
		scale = (1.0 + float(round_number - 1) * boss_growth) * float(MainScript.DIFFICULTIES[difficulty]["enemy_mult"])
	var attack_bias := 0.76 if difficulty == "normal" else 0.85
	var attack_scale := 0.17 if difficulty == "normal" else 0.20
	var shield_growth := 8 if difficulty == "normal" else 6
	var reward_base := 1.05 if difficulty == "normal" else 0.90
	var reward_growth := 0.09 if difficulty == "normal" else 0.07
	return {
		"type": enemy_type,
		"hp": int(ceil(float(config["hp"]) * scale)),
		"max_hp": int(ceil(float(config["hp"]) * scale)),
		"attack": int(ceil(float(config["attack"]) * (attack_bias + scale * attack_scale))),
		"shield": int(config.get("shield", 0)) + int(round_number / shield_growth),
		"steal": int(config.get("steal", 0)),
		"reward": int(ceil(float(config["reward"]) * (reward_base + float(round_number) * reward_growth)))
	}


func _buy_relic_if_useful(state: Dictionary, round_number: int) -> void:
	if Array(state["owned_relics"]).size() >= 4:
		return
	var offers := _copy_string_array(state.get("relic_offers", []))
	if offers.is_empty():
		offers = _roll_relic_offers(state)
		state["relic_offers"] = offers
	var best_id := ""
	var best_score := -9999.0
	for relic_id in offers:
		if Array(state["owned_relics"]).has(relic_id):
			continue
		var config: Dictionary = MainScript.RELICS[relic_id]
		var cost := int(config["cost"])
		var reserve: int = _round_due(round_number, {}, String(state["difficulty"]), state) + (6 if String(state["difficulty"]) == "normal" else 10)
		if int(state["coins"]) < cost + reserve:
			continue
		var score := _relic_buy_score(relic_id, round_number, state)
		if score > best_score:
			best_score = score
			best_id = relic_id
	if best_id == "":
		return
	state["coins"] = int(state["coins"]) - int(MainScript.RELICS[best_id]["cost"])
	Array(state["owned_relics"]).append(best_id)
	offers.erase(best_id)
	state["relic_offers"] = offers


func _roll_relic_offers(state: Dictionary) -> Array[String]:
	var pool: Array[String] = []
	for relic_id in MainScript.RELICS.keys():
		if not Array(state["owned_relics"]).has(String(relic_id)):
			pool.append(String(relic_id))
	_shuffle(pool)
	var offers: Array[String] = []
	for i in range(min(3, pool.size())):
		offers.append(pool[i])
	offers.sort_custom(func(a, b): return _relic_buy_score(a, 1, state) > _relic_buy_score(b, 1, state))
	return offers


func _relic_buy_score(relic_id: String, round_number: int, state: Dictionary) -> float:
	var score := 0.0
	match relic_id:
		"golden_glove":
			score = 8.0
		"war_banner":
			score = 8.5
		"chain_bell":
			score = 9.0
		"silver_lens":
			score = 8.0
		"deep_pockets":
			score = 9.5
		"tax_receipt":
			score = 7.5
		"merchant_seal":
			score = 6.5 if round_number <= 10 else 3.0
		"shield_charm":
			score = 7.5 if int(state["health"]) <= 24 else 5.5
		"red_heart":
			score = 5.0
		"steady_anvil":
			score = 4.0
		"void_purse":
			score = 4.0
		_:
			score = 3.0
	var cost := int(MainScript.RELICS[relic_id]["cost"])
	score -= max(0.0, float(cost - 22)) * 0.20
	return score


func _roll_shop_offers() -> Array[String]:
	var offers: Array[String] = []
	var common := _copy_string_array(MainScript.COMMON_SHOP_TYPES)
	_shuffle(common)
	for i in range(5):
		offers.append(common[i % common.size()])
	if rng.randf() < 0.72:
		offers.append(String(MainScript.RARE_SHOP_TYPES[rng.randi_range(0, MainScript.RARE_SHOP_TYPES.size() - 1)]))
	else:
		offers.append(common[5 % common.size()])
	offers.sort_custom(func(a, b): return _tile_buy_score(a, 1) > _tile_buy_score(b, 1))
	return offers


func _draw_hand(bag: Array, state: Dictionary) -> Array[String]:
	var pool := _copy_string_array(bag)
	_shuffle(pool)
	var hand: Array[String] = []
	var hand_size := MainScript.HAND_SIZE + (1 if Array(state["owned_relics"]).has("deep_pockets") else 0)
	for i in range(min(hand_size, pool.size())):
		hand.append(pool[i])
	return hand


func _best_click_index(board: Array) -> int:
	var best := -1
	var best_score := -9999.0
	for i in range(board.size()):
		var tile: Dictionary = board[i]
		if int(tile.get("clicks_left", 0)) <= 0:
			continue
		var tile_type := String(tile["type"])
		var score := float(_tile_coin_value(tile_type, int(tile.get("level", 1))) + _tile_damage_value(tile_type, int(tile.get("level", 1))))
		score += Array(MainScript.TILE_TYPES[tile_type]["directions"]).size() * 1.5
		if score > best_score:
			best_score = score
			best = i
	return best


func _random_clickable_index(board: Array) -> int:
	var choices: Array[int] = []
	for i in range(board.size()):
		if int(Dictionary(board[i]).get("clicks_left", 0)) > 0:
			choices.append(i)
	if choices.is_empty():
		return -1
	return choices[rng.randi_range(0, choices.size() - 1)]


func _try_upgrade_board_tile(board: Array, tile_type: String) -> bool:
	var best_index := -1
	var best_level := MainScript.MAX_TILE_LEVEL + 1
	for i in range(board.size()):
		var tile: Dictionary = board[i]
		if String(tile["type"]) != tile_type:
			continue
		var level := int(tile.get("level", 1))
		if level >= MainScript.MAX_TILE_LEVEL:
			continue
		if level < best_level:
			best_level = level
			best_index = i
	if best_index == -1:
		return false
	Dictionary(board[best_index])["level"] = best_level + 1
	return true


func _new_sim_tile(tile_type: String) -> Dictionary:
	return {"type": tile_type, "level": 1, "clicks_left": MainScript.MAX_TILE_CLICKS, "stock_step": 0, "forge_heat": 0, "history": []}


func _target_board_size(round_number: int) -> int:
	return min(MainScript.TOTAL_SLOTS, 4 + int(round_number / 2))


func _round_due(round_number: int, event: Dictionary, difficulty: String, state: Dictionary = {}) -> int:
	var index: int = clamp(round_number - 1, 0, MainScript.ROUND_QUOTAS.size() - 1)
	var due := int(ceil(float(MainScript.ROUND_QUOTAS[index]) * float(MainScript.DIFFICULTIES[difficulty]["quota_mult"])))
	var discount := int(event.get("quota_discount", 0))
	if not state.is_empty() and Array(state.get("owned_relics", [])).has("tax_receipt"):
		discount += 2
	due = max(0, due - discount)
	return due


func _tile_coin_value(tile_type: String, level: int) -> int:
	var base := int(MainScript.TILE_TYPES[tile_type]["coin_value"]) + level - 1
	return max(0, base)


func _tile_damage_value(tile_type: String, level: int) -> int:
	var directions := Array(MainScript.TILE_TYPES[tile_type]["directions"]).size()
	return max(1, int(MainScript.TILE_TYPES[tile_type]["coin_value"]) + min(2, directions) + level - 1)


func _coin_success_chance(state: Dictionary, tile_type: String, level: int) -> float:
	var relic_bonus := 0.04 if Array(state["owned_relics"]).has("silver_lens") else 0.0
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
		"forge":
			return clampf(0.48 + relic_bonus + float(level - 1) * 0.05, 0.05, 0.95)
		"titan":
			return clampf(0.38 + relic_bonus + float(level - 1) * 0.06, 0.05, 0.95)
		_:
			return clampf(0.50 + relic_bonus + float(level - 1) * 0.04, 0.05, 0.95)


func _tile_buy_score(tile_type: String, round_number: int) -> float:
	var config: Dictionary = MainScript.TILE_TYPES[tile_type]
	var score := float(config["coin_value"]) * 2.0 + Array(config["directions"]).size() * 1.4 + float(config["trigger_chance"]) * 4.0
	match String(config["rarity"]):
		"rare":
			score += 1.2
		"uncommon":
			score += 0.6
	score -= max(0.0, float(config["cost"]) - 8.0) * 0.25
	if round_number < 5 and String(config["rarity"]) == "rare":
		score -= 1.0
	return score


func _run_result(state: Dictionary, victory: bool) -> Dictionary:
	return {
		"victory": victory,
		"round": int(state["round"]),
		"coins": int(state["coins"]),
		"health": int(state["health"]),
		"total_coins": int(state["total_coins"]),
		"total_damage": int(state["total_damage"]),
		"kills": int(state["kills"]),
		"best_chain": int(state["best_chain"]),
		"death_reason": String(state["death_reason"])
	}


func _summarize_pair(difficulty: String, starter: String, results: Array[Dictionary]) -> Dictionary:
	var wins := 0
	var rounds: Array[int] = []
	var coins: Array[int] = []
	var health: Array[int] = []
	var total_coins: Array[int] = []
	var total_damage: Array[int] = []
	var reasons := {}
	for result in results:
		if bool(result["victory"]):
			wins += 1
		rounds.append(int(result["round"]))
		coins.append(int(result["coins"]))
		health.append(int(result["health"]))
		total_coins.append(int(result["total_coins"]))
		total_damage.append(int(result["total_damage"]))
		var reason := String(result["death_reason"]) if not bool(result["victory"]) else "胜利"
		reasons[reason] = int(reasons.get(reason, 0)) + 1
	return {
		"difficulty": difficulty,
		"starter": starter,
		"runs": results.size(),
		"wins": wins,
		"win_rate": float(wins) / float(max(1, results.size())),
		"avg_round": _avg_int(rounds),
		"p50_round": _percentile_int(rounds, 0.50),
		"avg_coins": _avg_int(coins),
		"avg_health": _avg_int(health),
		"avg_total_coins": _avg_int(total_coins),
		"avg_total_damage": _avg_int(total_damage),
		"reasons": reasons
	}


func _write_report(rows: Array[Dictionary]) -> void:
	var lines: Array[String] = []
	lines.append("# Fate Coins 平衡模拟报告")
	lines.append("")
	lines.append("- 模拟器：`tools/balance_simulator.gd`")
	lines.append("- 每组运行：%d 局" % RUNS_PER_PAIR)
	lines.append("- 随机种子：20260611")
	lines.append("- 说明：这是启发式自动玩家，用于发现经济/伤害曲线风险，不等于真人胜率。")
	lines.append("")
	lines.append("| 难度 | 初始袋 | 胜率 | 平均到达回合 | 中位回合 | 平均最终金币 | 平均最终生命 | 平均总收益 | 平均总伤害 | 主要结果 |")
	lines.append("|---|---|---:|---:|---:|---:|---:|---:|---:|---|")
	for row in rows:
		lines.append("| %s | %s | %.1f%% | %.1f | %d | %.1f | %.1f | %.1f | %.1f | %s |" % [
			MainScript.DIFFICULTIES[String(row["difficulty"])]["name"],
			MainScript.STARTER_BAGS[String(row["starter"])]["name"],
			float(row["win_rate"]) * 100.0,
			float(row["avg_round"]),
			int(row["p50_round"]),
			float(row["avg_coins"]),
			float(row["avg_health"]),
			float(row["avg_total_coins"]),
			float(row["avg_total_damage"]),
			_reason_summary(Dictionary(row["reasons"]))
		])
	lines.append("")
	lines.append("## 初步判读")
	lines.append("")
	lines.append_array(_find_balance_flags(rows))
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines) + "\n")
	print("Wrote balance report to %s" % REPORT_PATH)


func _find_balance_flags(rows: Array[Dictionary]) -> Array[String]:
	var flags: Array[String] = []
	var normal_min := 1.0
	var normal_max := 0.0
	var normal_min_label := ""
	var normal_max_label := ""
	for row in rows:
		var label := "%s/%s" % [MainScript.DIFFICULTIES[String(row["difficulty"])]["name"], MainScript.STARTER_BAGS[String(row["starter"])]["name"]]
		if String(row["difficulty"]) == "normal":
			var rate := float(row["win_rate"])
			if rate < normal_min:
				normal_min = rate
				normal_min_label = label
			if rate > normal_max:
				normal_max = rate
				normal_max_label = label
		if float(row["win_rate"]) < 0.05 and String(row["difficulty"]) == "normal":
			flags.append("- `%s` 普通难度胜率低于 5%%，可能过硬或自动玩家策略过弱，需要真人路径验证。" % label)
		if float(row["win_rate"]) > 0.70 and String(row["difficulty"]) != "normal":
			flags.append("- `%s` 高压难度胜率高于 70%%，可能难度区分不明显。" % label)
		if float(row["avg_round"]) < 8.0:
			flags.append("- `%s` 平均到达回合低于 8，早期死亡/破产风险过高。" % label)
		if float(row["avg_coins"]) < -2.0:
			flags.append("- `%s` 终局经济过低，收取曲线可能压垮构筑。" % label)
	if normal_max - normal_min > 0.30:
		flags.append("- 普通难度初始袋胜率差距为 %.1f 个百分点（最高 `%s`，最低 `%s`），需要继续收敛构筑强弱。" % [(normal_max - normal_min) * 100.0, normal_max_label, normal_min_label])
	if flags.is_empty():
		flags.append("- 本轮启发式模拟未发现极端断崖，但仍需要真人首局路径和更精确的局内状态复现。")
	return flags


func _reason_summary(reasons: Dictionary) -> String:
	var parts: Array[String] = []
	for key in reasons.keys():
		parts.append("%s:%d" % [String(key), int(reasons[key])])
	parts.sort()
	return " / ".join(parts)


func _avg_int(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0
	for value in values:
		total += value
	return float(total) / float(values.size())


func _percentile_int(values: Array[int], pct: float) -> int:
	if values.is_empty():
		return 0
	var sorted := values.duplicate()
	sorted.sort()
	var index: int = clamp(int(floor(float(sorted.size() - 1) * pct)), 0, sorted.size() - 1)
	return int(sorted[index])


func _copy_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for item in value:
		result.append(String(item))
	return result


func _shuffle(values: Array[String]) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp := values[i]
		values[i] = values[j]
		values[j] = temp
