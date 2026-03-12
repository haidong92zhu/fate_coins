@echo off
cd /d "%~dp0"

echo ========================================
echo   Fate Coins - 游戏启动脚本
echo ========================================
echo.

REM 检查Godot引擎是否安装
where godot >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未找到Godot引擎！
    echo.
    echo 请先安装Godot 4.x：
    echo 1. 访问 https://godotengine.org/download
    echo 2. 下载"Godot 4.x Standard"版本
    echo 3. 安装Godot引擎
    echo.
    pause
    exit /b 1
)

echo [成功] 找到Godot引擎！
echo.

echo 正在启动Fate Coins...
echo.

REM 启动Godot并加载项目
godot --editor --path "project.godot"

if %ERRORLEVEL% NEQ 0 (
    echo [错误] Godot启动失败！
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   游戏启动成功！
echo ========================================
echo.
echo 游戏控制：
echo - 从右侧侧边栏选择金币类型
echo - 拖拽金币到中间的4x5网格放置
echo - 点击"FLIP ALL COINS"按钮开始抛掷
echo - 查看上方的状态条显示抛掷结果
echo - 红色=成功，绿色=失败，灰色=未抛掷
echo.
echo 点击任意键关闭此窗口...
pause >nul
