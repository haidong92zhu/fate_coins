#!/bin/bash

# Fate Coins - 游戏启动脚本

echo "========================================"
echo "   Fate Coins - 游戏启动脚本"
echo "========================================"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 尝试定位 Godot 可执行文件（优先级从高到低）
GODOT_BIN=""
if command -v godot4 >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot4)"
elif command -v godot >/dev/null 2>&1; then
    GODOT_BIN="$(command -v godot)"
elif [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
elif [ -x "$HOME/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT_BIN="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
fi

# 检查 Godot 引擎是否可用
if [ -z "$GODOT_BIN" ]; then
    echo "[错误] 未找到 Godot 引擎可执行文件！"
    echo ""
    echo "请先安装 Godot 4.x，或将 Godot 加入 PATH："
    echo "1. 访问 https://godotengine.org/download"
    echo "2. 下载 Godot 4.x Standard 版本"
    echo "3. 安装后确保可通过 godot4 或 godot 命令运行"
    echo ""
    echo "macOS 也可直接放在：/Applications/Godot.app"
    echo ""
    exit 1
fi

echo "[成功] 找到 Godot：$GODOT_BIN"
echo ""
echo "正在启动 Fate Coins..."
echo ""

# 启动 Godot 并加载项目目录
"$GODOT_BIN" --editor --path "$SCRIPT_DIR"

if [ $? -ne 0 ]; then
    echo "[错误] Godot启动失败！"
    echo ""
    exit 1
fi

echo ""
echo "========================================"
echo "   游戏启动成功！"
echo "========================================"
echo ""
echo "游戏控制："
echo "- 从右侧侧边栏选择金币类型"
echo "- 拖拽金币到中间的4x5网格放置"
echo "- 点击 FLIP ALL COINS 按钮开始抛掷"
echo "- 查看上方的状态条显示抛掷结果"
echo "  红色=成功，绿色=失败，灰色=未抛掷"
echo "- 收集金币购买装备"
echo "- 击败敌人完成回合"
echo ""
echo "按Ctrl+C或关闭窗口退出游戏"
