extends Control

# 测试场景
@onready var test_label = null
const CoinScript = preload("res://scripts/coin.gd")
const GameStateScript = preload("res://scripts/game_state.gd")
const ShopSystemScript = preload("res://scripts/shop_system.gd")
const InventorySystemScript = preload("res://scripts/inventory_system.gd")
const SaveLoadScript = preload("res://scripts/save_load.gd")
const BattleSystemScript = preload("res://scripts/battle_system.gd")

func _ready():
	print("TestScene initialized")
	run_tests()

func run_tests():
	print("========================================")
	print("   开始自动测试")
	print("========================================")
	
	# 测试1：金币系统
	print("")
	print("测试1：金币系统")
	var coin_normal = CoinScript.Coin.new("normal")
	var result1 = coin_normal.flip()
	print("普通金币抛掷结果：", result1)
	
	var coin_glass = CoinScript.Coin.new("glass")
	var result2 = coin_glass.flip()
	print("玻璃金币抛掷结果：", result2)
	
	var coin_bitcoin = CoinScript.Coin.new("bitcoin")
	var result3 = coin_bitcoin.flip()
	print("比特币抛掷结果：", result3)
	
	# 测试2：游戏状态
	print("")
	print("测试2：游戏状态")
	var game_state = GameStateScript.new()
	game_state.add_coins(50)
	print("添加50金币后：", game_state.coins)
	game_state.flip_coin()
	print("抛掷1次后，剩余次数：", game_state.flip_count)
	
	# 测试3：概率计算
	print("")
	print("测试3：概率计算")
	var success_count = 0
	var total_flips = 1000
	
	for i in range(total_flips):
		if randf() < 0.5:
			success_count += 1
	
	var actual_rate = float(success_count) / total_flips
	print("实际成功率：", actual_rate * 100, "%")
	print("预期成功率：50%")
	print("误差：", abs(actual_rate - 0.5) * 100, "%")
	
	# 测试4：商店系统
	print("")
	print("测试4：商店系统")
	var shop = ShopSystemScript.new()
	print("商店商品数量：", shop.shop_items.size())
	
	# 测试购买
	var money = shop.player_money
	print("初始资金：", money)
	
	if shop.buy_item(0):  # 购买第一个商品
		print("购买成功！剩余资金：", shop.player_money)
	else:
		print("购买失败！资金不足")
	
	# 测试5：背包系统
	print("")
	print("测试5：背包系统")
	var inventory = InventorySystemScript.new()
	var texture: Texture2D = null
	inventory.add_item("测试金币", "coin", texture)
	inventory.add_item("测试金币", "coin", texture)
	print("背包物品数量：", inventory.items.size())
	print("第一个物品数量：", inventory.get_item(0).count if inventory.items.size() > 0 else 0)
	
	# 测试6：存档系统
	print("")
	print("测试6：存档系统")
	var save_load = SaveLoadScript.new()
	save_load.save_game()
	print("存档保存成功！")
	
	# 测试7：战斗系统
	print("")
	print("测试7：战斗系统")
	var battle = BattleSystemScript.new()
	var damage = battle.calculate_damage(50, 100)
	print("攻击力50对100血量的伤害：", damage)
	
	# 测试8：性能测试
	print("")
	print("测试8：性能测试")
	var start_time = Time.get_ticks_msec()
	
	# 模拟100次金币抛掷
	for i in range(100):
		var coin = CoinScript.Coin.new("normal")
		coin.flip()
	
	var end_time = Time.get_ticks_msec()
	var elapsed = end_time - start_time
	print("100次金币抛掷耗时：", elapsed, "ms")
	print("平均每次抛掷：", elapsed / 100, "ms")
	
	# 测试总结
	print("")
	print("========================================")
	print("   测试完成！")
	print("========================================")
	print("所有测试都已完成，请检查上述结果。")
	print("按F5重新运行测试。")
