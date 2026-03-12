# Fate Coins - 开发说明

## 项目概述
游戏名称：Fate Coins (命运之币)
开发引擎：Godot 4.x
开发语言：GDScript
当前版本：v1.0

## 项目结构
```
fate_coins/
├── project.godot           # Godot项目配置
├── res/                   # 资源文件夹
│   ├── textures/          # 纹理图片（金币、UI、背景）
│   ├── audio/             # 音效和音乐
│   └── fonts/             # 字体文件
├── scripts/               # GDScript脚本
│   ├── main.gd            # 主游戏脚本
│   ├── coin.gd            # 金币系统
│   ├── grid.gd            # 网格系统
│   ├── game_state.gd      # 游戏状态
│   ├── ui_manager.gd       # UI管理
│   ├── battle_system.gd    # 战斗系统
│   ├── shop_system.gd       # 商店系统
│   ├── inventory_system.gd  # 背包系统
│   ├── coin_animation.gd   # 金币动画
│   ├── save_load.gd        # 存档系统
│   └── game_logic_manager.gd # 游戏逻辑
└── scenes/                # 场景文件夹
    ├── main.tscn           # 主场景
    ├── game.tscn           # 游戏场景
    ├── shop.tscn           # 商店场景
    └── inventory.tscn      # 背包场景
```

## 如何打开游戏

### 步骤1：下载Godot引擎
1. 访问 https://godotengine.org/download
2. 下载Godot 4.x Standard版本（Windows/Mac/Linux）
3. 安装Godot引擎

### 步骤2：打开项目
1. 启动Godot引擎
2. 点击"Import"按钮
3. 选择 `fate_coins/project.godot` 文件
4. 点击"Import & Edit"按钮

### 步骤3：运行游戏
1. 点击顶部工具栏的"运行"按钮（▶️）
2. 或者按F5键
3. 游戏窗口将弹出

## 游戏玩法说明

### 基础操作
- 从右侧侧边栏选择金币类型
- 拖拽金币到中间的4x5网格放置
- 点击"FLIP ALL COINS"按钮开始抛掷
- 查看上方的状态条（红色=成功，绿色=失败，灰色=未抛掷）
- 收集金币购买装备
- 击败敌人完成回合

### 金币类型
1. **普通金币** - 基础金币，50%成功率
2. **反面金币** - 翻倍机会，需要2次抛掷
3. **玻璃金币** - 20%破碎，正面获得3金币
4. **比特币** - 无抛掷限制，每次获得50金币
5. **股票金币** - 涨跌10%
6. **幸运金币** - 增加后续金币金额

### 游戏阶段
1. **放置阶段** - 选择金币类型并放置到网格
2. **抛掷阶段** - 点击抛掷，查看结果
3. **战斗阶段** - 使用金币攻击力对抗敌人
4. **商店阶段** - 使用金币购买装备和特殊物品
5. **背包阶段** - 查看和管理你的物品

## 开发进度

### ✅ 已完成
- [x] 项目配置文件
- [x] 核心脚本系统
- [x] 场景文件创建
- [x] 游戏逻辑框架

### 🔄 进行中
- [ ] 美术资源生成
- [ ] 音效系统集成
- [ ] 完整测试

### ⏳ 待完成
- [ ] 打包发布
- [ ] Steam上架准备
- [ ] 成就系统实现

## 资源需求

### 需要的美术资源
1. 金币图片
   - 金币正面 (coin_normal.png)
   - 金币反面 (coin_reverse.png)
   - 玻璃金币 (coin_glass.png)
   - 比特币图标 (coin_bitcoin.png)
   - 股票图标 (coin_stock.png)
   - 幸运金币图标 (coin_lucky.png)

2. UI元素
   - 状态条背景 (status_bar_bg.png)
   - 按钮样式 (button_normal.png)
   - 格子背景 (grid_cell_bg.png)

3. 场景背景
   - 主场景背景 (bg_main.png)
   - 战斗场景背景 (bg_battle.png)
   - 商店场景背景 (bg_shop.png)

### 需要的音频资源
1. 音效
   - 金币抛掷音效 (coin_flip.wav)
   - 命中音效 (hit_success.wav)
   - 失败音效 (hit_fail.wav)
   - 购买音效 (buy_item.wav)
   - 收集音效 (collect_coin.wav)

2. 音乐
   - 主场景背景音乐 (bgm_main.ogg)
   - 战斗场景音乐 (bgm_battle.ogg)
   - 商店场景音乐 (bgm_shop.ogg)
   - 胜利音乐 (music_victory.ogg)
   - 失败音乐 (music_defeat.ogg)

## 测试清单

### 功能测试
- [ ] 金币抛掷是否正常工作
- [ ] 概率计算是否准确
- [ ] 网格放置是否正常
- [ ] 状态条是否正确显示
- [ ] 背包系统是否正常

### 性能测试
- [ ] 帧率是否稳定在60FPS
- [ ] 内存占用是否正常
- [ ] 加载时间是否可接受

### 兼容性测试
- [ ] Windows版本是否正常运行
- [ ] Mac版本是否正常运行
- [ ] Linux版本是否正常运行

## 已知问题

1. **美术资源缺失** - 当前使用占位符，需要替换为实际美术资源
2. **音效未集成** - 音效系统已实现，但未添加实际音频文件
3. **UI需要优化** - 当前UI为基本布局，需要美化

## 下一步计划

### 即将完成
1. 生成美术资源（使用AI生成）
2. 添加音效和音乐
3. UI美化
4. 完整测试

### 发布计划
1. 打包Windows、Mac、Linux版本
2. 准备Steam商店页面
3. 上传Steam
4. 发布

## 联系方式

如有问题，请联系开发团队。

---

**文档版本**：v1.0
**最后更新**：2026-03-12
**游戏版本**：v1.0-alpha
