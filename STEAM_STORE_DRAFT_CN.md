# Fate Coins Steam 商店页草案

## 简短描述

在月相审判厅里构筑一台会反噬你的命运机器。拖拽硬币、选择下注风险、触发连锁翻面，在 24 回合内偿还债务、击败 Boss，并把每一次贪婪都变成下一局的教训。

## 一句话卖点

硬币构筑 + 方格连锁 + 风险下注的单机 roguelite。

## 长描述

Fate Coins 是一款小体量单机 roguelite。每回合你会从命运袋抽出硬币，把它们摆进 4x5 棋盘，再点击核心硬币触发金币、伤害、治疗和方向连锁。

每枚硬币都有正反面、触发概率、连锁方向和副作用。保守下注可以稳定活下去，贪婪和梭哈则会放大收益，也会让失败更疼。敌人会偷钱、上盾、污染硬币、锁住路线；Boss 会随着血量进入新阶段，迫使你临时改造整台铸币机。

在商店中购买新硬币、遗物、一次性道具，或接受诅咒交易来换取短期优势。你需要在 24 回合内维持经济、处理敌阵压力，并击败最终庄家。

## 核心特色

- 4x5 棋盘式硬币机器：拖拽摆放硬币，用方向和概率制造连锁。
- 风险下注系统：保守、标准、贪婪、梭哈改变金币、伤害和失败代价。
- 命运袋构筑：购买、移除、升级和锁定手牌，逐步压缩随机性。
- 敌人和 Boss 压力：敌人会偷钱、加盾、污染、锁定和干扰你的核心硬币。
- 多种初始流派：稳健、连锁、赌博、鲜血各有不同节奏和风险。
- 单机 24 回合挑战：适合短局反复尝试，围绕构筑路线优化。
- 月相审判厅视觉方向：冷色石板面板、银蓝硬币、青蓝能量和红色危险反馈。

## 当前截图素材

- `screenshots/steam/01_main_menu.png`：英文主菜单、品牌和模式入口。
- `screenshots/steam/02_preparation_board.png`：英文准备阶段、棋盘、教程清单、商店和敌阵信息。
- `screenshots/steam/03_opening_layout.png`：英文早期布阵和手牌构筑。
- `screenshots/steam/04_combat_chain.png`：英文回合中点击、连锁和战斗反馈。
- `screenshots/steam/05_boss_pressure.png`：英文 Boss 压力、状态栏和敌人卡片。
- `screenshots/steam/README.md`：5 张截图的英文用途说明清单。

## 当前商店图素材

- `textures/branding/steam_capsule_616x353.png`
- `textures/branding/steam_header_920x430.png`
- `textures/branding/steam_library_600x900.png`

这些目前是程序化候选主视觉，已经包含棋盘、连锁路线、敌人危险标记和 “CHAIN RISK” 副标题，可用于内部 Steam 页面结构预览；正式上架前仍建议进行人工构图与字体精修。

## 系统需求草案

### Windows

最低配置：

- 操作系统：Windows 10 64-bit
- 处理器：双核 2.0 GHz
- 内存：4 GB RAM
- 显卡：OpenGL 3.3 / Vulkan 1.0 兼容显卡
- 存储空间：300 MB 可用空间

推荐配置：

- 操作系统：Windows 10/11 64-bit
- 处理器：四核 2.5 GHz
- 内存：8 GB RAM
- 显卡：独立或较新的集成显卡
- 存储空间：500 MB 可用空间

### macOS

最低配置：

- 操作系统：macOS 12
- 处理器：Intel 或 Apple Silicon
- 内存：4 GB RAM
- 显卡：Metal 兼容显卡
- 存储空间：300 MB 可用空间

### Linux

最低配置：

- 操作系统：Ubuntu 22.04 或同等级发行版
- 处理器：双核 2.0 GHz
- 内存：4 GB RAM
- 显卡：OpenGL 3.3 / Vulkan 1.0 兼容显卡
- 存储空间：300 MB 可用空间

## 上架前仍需确认

- 安装 Godot 4.6.2.stable export templates，运行 `tools/export_template_check.gd` 确认模板存在，再用 `tools/export_release_smoke.sh` 生成 Windows/macOS/Linux 实包。
- 在真实平台上验证启动、窗口切换、设置保存、存档写入和删除存档。
- 准备许可证说明、第三方字体/素材声明和 macOS 签名/公证策略。
- 人工精选/重拍自动截图中表现较弱的画面。
- 对程序化候选主视觉进行最终构图、字体和商店规格精修。
