#!/bin/bash

# Fate Coins - 游戏启动脚本

echo "========================================"
echo "   Fate Coins - 游戏启动脚本"
echo "========================================"
echo ""

# 检查Godot引擎是否安装
if ! command -v godot &> /dev/null
then
    echo "[错误] 未找到Godot引擎！"
    echo ""
    echo "请先安装Godot 4.x："
    echo "1. 访问 https://godotengine.org/download"
    echo "2. 下载"Godot 4.x Standard"版本"
    echo "3. 安装Godot引擎"
    echo ""
    exit 1
fi

echo "[成功] 找到Godot引擎！"
echo ""

echo "正在启动Fate Coins..."
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 启动Godot并加载项目
godot --editor --path "project.godot"

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
echo "- 点击"FLIP ALL COINS"按钮开始抛掷"
echo "- 查看上方的状态条显示抛掷结果"
echo "  红色=成功，绿色=失败，灰色=未抛掷"
echo "- 收集金币购买装备"
echo "- 击败敌人完成回合"
echo ""
echo "按Ctrl+C或关闭窗口退出游戏"
