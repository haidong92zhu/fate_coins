# Fate Coins 命运之币

Fate Coins 是一款 Godot 4.6 制作的单机硬币构筑 roguelite。玩家在 4x5 棋盘上搭建一台不稳定的硬币机器，在每回合选择保守、标准、贪婪或梭哈下注，用金币收益、连锁触发、遗物和敌人赏金撑过 24 回合挑战。

当前美术方向是 **月相审判厅 / 银蓝命运盘**：冷色石板桌面、月光银蓝边线、硬边棋盘格、仪式盘式硬币、克制青蓝高光、猩红危险提示、独立敌人/Boss 图标和高频遗物图标。

## 当前玩法

- 准备阶段从手牌拖拽硬币到棋盘。
- 开始回合后点击棋盘硬币，触发正反面、失败、连锁、伤害和收益。
- 每回合需要支付收取额度；金币不足或生命归零会失败。
- 击败敌人获得赏金，Boss 回合会检验当前构筑。
- 回合间可以购买硬币、遗物、一次性道具、诅咒交易，或管理命运袋。
- 首局教程会高亮当前应操作的手牌、空格、按钮和可点击硬币，并在第 1 回合结算时给出核心循环复盘。

## 已具备的正式化内容

- 主菜单：新游戏、继续、保存、删除存档、难度、设置、玩法说明、全屏、窗口大小、静音、减少动效、语言入口、退出。
- 主菜单内置鸣谢与许可证入口，说明 Godot/MIT、项目生成素材状态和外部素材登记要求。
- 可访问性/舒适度设置：减少动效会保留战斗文字和颜色反馈，但关闭缩放、浮动和淡入淡出动效。
- 玩法说明面板：主菜单可随时查看目标、30 秒核心循环、下注风险、回合间选择和读盘重点。
- 四种初始袋：稳健、连锁、赌博、鲜血。
- 四种下注：保守、标准、贪婪、梭哈。
- 敌人波次、Boss、遗物商店、一次性道具、诅咒交易、回合事件和导演压力。
- 程序化生成的月相审判厅硬币、方块、敌人、遗物和 UI 图标。
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

中局状态复现测试：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/midrun_state_smoke_test.gd
```

存档/设置恢复测试：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/persistence_recovery_smoke_test.gd
```

平台存储路径测试：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/platform_storage_smoke_test.gd
```

核心本地化测试：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/localization_smoke_test.gd
```

桌面布局测试：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/responsive_layout_smoke_test.gd
```

布局报告会写入 `build/responsive_layout_report.md`，用于检查 1280x800 最小桌面窗口下的菜单/弹窗尺寸约束，以及默认设计布局中的关键 HUD、菜单按钮和棋盘槽位。

音频质量检查：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/audio_quality_check.gd
```

音频质量报告会写入 `build/audio_quality_report.md`，用于检查运行时音效和音乐的文件覆盖、导入元数据、ResourceLoader 可用性、WAV 格式、时长、峰值和削波风险。

Steam 商店页素材检查：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/store_page_materials_check.gd
```

商店页素材报告会写入 `build/store_page_materials_report.md`，用于检查中英文商店草稿、截图引用、品牌图引用、系统需求和内容说明。

商店截图和品牌图视觉质量检查：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/store_visual_quality_check.gd
```

视觉质量报告会写入 `build/store_visual_quality_report.md`，用于检查商店截图和品牌图的尺寸、import 元数据、ResourceLoader 可用性、采样色彩数量、亮度范围和亮暗覆盖，防止空图、断链或过平的候选素材进入发布清单。

首局真人观察材料检查：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/first_run_playtest_materials_check.gd
```

首局观察材料报告会写入 `build/first_run_playtest_materials_report.md`，用于检查 `PLAYTEST_FIRST_RUN_PROTOCOL.md` 和 `PLAYTEST_FIRST_RUN_OBSERVATION_TEMPLATE.md` 是否覆盖 30 秒核心循环、观察任务、摩擦标签和通过门槛。

发布配置与导出模板检查：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/release_config_check.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/export_template_check.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/release_readiness_report.gd
```

发布准备度报告会写入 `build/release_readiness_report.md`，用于汇总项目元数据、品牌素材、商店截图、商店视觉质量、商店文案、法律/鸣谢入口、可访问性/舒适度设置、桌面布局、首局观察材料、三平台导出预设、导出模板和 macOS 签名/公证状态。

安装 Godot export templates 后的三平台导出 smoke：

```bash
tools/export_release_smoke.sh
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
tools/midrun_state_smoke_test.gd 四初始袋中局复现测试
tools/persistence_recovery_smoke_test.gd 存档/设置恢复测试
tools/platform_storage_smoke_test.gd 平台 user:// 写入路径测试
tools/localization_smoke_test.gd 核心菜单/设置/教程本地化测试
tools/responsive_layout_smoke_test.gd 桌面布局 smoke 测试
tools/audio_quality_check.gd 音频素材质量检查
tools/store_page_materials_check.gd Steam 商店页素材检查
tools/store_visual_quality_check.gd 商店截图/品牌图视觉质量检查
tools/first_run_playtest_materials_check.gd 首局观察材料检查
tools/export_template_check.gd Godot 导出模板可用性检查
tools/release_readiness_report.gd 发布准备度报告生成器
tools/export_release_smoke.sh 三平台真实导出 smoke 脚本
tools/balance_simulator.gd     启发式平衡模拟器
tools/generate_audio_assets.gd 程序化音频生成器
tools/generate_midnight_assets.gd 程序化美术生成器
PLAYTEST_FIRST_RUN_PROTOCOL.md 首局真人观察协议
PLAYTEST_FIRST_RUN_OBSERVATION_TEMPLATE.md 首局观察记录模板
```

仓库里仍保留部分早期原型脚本和场景；当前可玩路径以 `scenes/main.tscn` 和 `scripts/main.gd` 为准。

## Steam 化状态

详细记录见 `STEAM_READINESS_AUDIT_CN.md`。

已经推进：

- 从上一版暖铜风格切换到统一的月相审判厅 / 银蓝命运盘视觉方向，并重做主背景、硬边面板、棋盘格、仪式盘式硬币和 Steam 候选截图。
- 完成主菜单、设置、保存/删除存档和退出流程，删除存档与退出桌面都有确认弹窗；设置会保存音效/音乐音量、静音、窗口大小、全屏、减少动效、教程和语言入口。
- 加入减少动效选项，开启后保留槽位颜色、战斗文字和中央提示，但关闭槽位缩放、浮字移动、战斗条缩放和中央冲击浮层的淡入淡出/缩放动画。
- 加入游戏内鸣谢与许可证入口，覆盖 Godot Engine/MIT License、当前项目生成素材状态、外部素材登记要求和最终发行 notices 提醒。
- 完成首局教程高亮、HUD 目标清单、紧凑状态指标、首回合复盘、主菜单玩法说明和自动化首局路径验证。
- 接入敌人/Boss、遗物、道具、诅咒、特殊硬币、事件和 UI 类别图标。
- 加入主循环/低血量警告/Boss 循环音乐、警告/命中/受伤/胜利音效和中央冲击反馈。
- 加入音频质量报告，覆盖 12 个音效和 3 条音乐的文件/import 覆盖、ResourceLoader 可用性、WAV 格式、时长、峰值和削波风险。
- 加入中英文 Steam 商店页草稿和素材完整性检查，覆盖短描述、长描述、核心特色、截图引用、品牌图、系统需求和内容说明。
- 加入商店截图/品牌图视觉质量报告，覆盖 5 张英文截图和 5 张品牌图的尺寸、import、ResourceLoader、采样色彩、亮度范围和亮暗覆盖。
- 加入首局真人观察协议、观察记录模板和材料检查，覆盖 30 秒核心循环、关键操作、摩擦标签和 3 名新玩家通过门槛。
- 加入桌面图标、启动封面、升级版 Steam 胶囊/header/library 候选主视觉、三平台基础导出预设和发布配置检查。
- 加入许可证说明和平台 user:// 存档/设置/进度写入验证。
- 英文语言入口不再只是占位，核心菜单、设置、HUD、教程清单、侧栏标题、首回合复盘、难度、下注、初始袋、硬币/方块、商店/管理操作提示、敌人、战斗反馈、硬币状态、遗物、道具、诅咒、事件说明和终局总结已可切换，并有自动化覆盖。
- 加入桌面布局 smoke test 和报告，检查 1280x800 最小窗口约束、默认设计布局关键控件、菜单按钮顺序和 20 个棋盘槽位。
- 加入平衡模拟报告；普通难度四初始袋启发式胜率已收敛到 47.5%、48.8%、48.8%、47.5%。
- 修复 headless 首局测试中的音频泄漏警告。

仍未达到真正 Steam 上架标准：

- 已有真人首局观察协议和记录模板，但仍需要实际邀请 3 名新玩家观察，验证 30 秒内是否理解拖拽、开局、点击与结算。
- 普通难度仍需真人路径验证和长期曲线复验，确认 20 分钟左右的稳定可重复游玩体验没有过拟合自动玩家。
- 需要 Godot export templates 下的真实 Windows/macOS/Linux 导出包、平台启动测试和 macOS 签名/公证策略。
- 需要人工精选/重拍最终截图、最终胶囊精修和 Steam 后台格式化。
