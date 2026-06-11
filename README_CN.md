# Fate Coins 命运之币

Fate Coins 是一款 Godot 4.6 制作的单机硬币构筑 roguelite。玩家在 4x5 棋盘上搭建一台不稳定的硬币机器，在每回合选择保守、标准、贪婪或梭哈下注，用金币收益、连锁触发、遗物和敌人赏金撑过 24 回合挑战。

当前美术方向是 **午夜铸币厂**：深墨绿机械面板、铜金硬币、青蓝能量反馈、红色危险提示、独立敌人/Boss 图标和高频遗物图标。

## 当前玩法

- 准备阶段从手牌拖拽硬币到棋盘。
- 开始回合后点击棋盘硬币，触发正反面、失败、连锁、伤害和收益。
- 每回合需要支付收取额度；金币不足或生命归零会失败。
- 击败敌人获得赏金，Boss 回合会检验当前构筑。
- 回合间可以购买硬币、遗物、一次性道具、诅咒交易，或管理命运袋。
- 首局教程会高亮当前应操作的手牌、空格、按钮和可点击硬币。

## 已具备的正式化内容

- 主菜单：新游戏、继续、保存、删除存档、难度、设置、全屏、退出。
- 四种初始袋：稳健、连锁、赌博、鲜血。
- 四种下注：保守、标准、贪婪、梭哈。
- 敌人波次、Boss、遗物商店、一次性道具、诅咒交易、回合事件和导演压力。
- 程序化生成的午夜铸币厂硬币、方块、敌人、遗物和 UI 图标。
- 首局流程自动化 smoke test。
- 多难度/多初始袋平衡模拟器。

## 本地运行

用 Godot 4.6 打开 `project.godot`，或运行：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/admin/Documents/hd/game/fate_coins
```

启动检查：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --quit-after 1
```

首局流程测试：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/first_run_smoke_test.gd
```

平衡模拟：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/balance_simulator.gd
```

重新生成程序化美术：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/generate_midnight_assets.gd
```

## 主要目录

```text
audio/                         音效
scenes/main.tscn               当前主场景
scripts/main.gd                主玩法、UI、存档、设置、教程、音频
scripts/game_state.gd          运行状态对象
textures/coins/                硬币图
textures/tiles/                棋盘方块图
textures/enemies/              敌人和 Boss 图标
textures/relics/               遗物图标
textures/ui/                   UI 分类图标
tools/first_run_smoke_test.gd  首局流程测试
tools/balance_simulator.gd     启发式平衡模拟器
tools/generate_midnight_assets.gd 程序化美术生成器
```

仓库里仍保留部分早期原型脚本和场景；当前可玩路径以 `scenes/main.tscn` 和 `scripts/main.gd` 为准。

## Steam 化状态

详细记录见 `STEAM_READINESS_AUDIT_CN.md`。

已经推进：

- 从占位风格切换到统一的午夜铸币厂视觉方向。
- 完成主菜单、设置、保存/删除存档和退出流程。
- 完成首局教程高亮和自动化首局路径验证。
- 接入敌人/Boss 独立图标和 12 个高频遗物图标。
- 加入平衡模拟报告。
- 修复 headless 首局测试中的音频泄漏警告。

仍未达到真正 Steam 上架标准：

- 需要真人首局观察，验证 30 秒内是否理解拖拽、开局、点击与结算。
- 普通难度仍需继续调平衡，形成 20 分钟左右的稳定可重复游玩曲线。
- 需要补齐剩余遗物、特殊硬币、道具、诅咒和事件图标。
- 需要导出预设、桌面图标、版本号、许可证说明和三平台启动/存档测试。
- 需要真实游戏截图、胶囊图、商店文案和系统需求。

