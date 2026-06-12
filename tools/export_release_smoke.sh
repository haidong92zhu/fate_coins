#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

cd "$ROOT_DIR"

mkdir -p build/windows build/macos build/linux

"$GODOT_BIN" --headless --path "$ROOT_DIR" --script tools/export_template_check.gd
"$GODOT_BIN" --headless --path "$ROOT_DIR" --script tools/release_config_check.gd

"$GODOT_BIN" --headless --path "$ROOT_DIR" --export-release "Windows Desktop" build/windows/FateCoins.exe
"$GODOT_BIN" --headless --path "$ROOT_DIR" --export-release "macOS" build/macos/FateCoins.zip
"$GODOT_BIN" --headless --path "$ROOT_DIR" --export-release "Linux/X11" build/linux/FateCoins.x86_64

test -s build/windows/FateCoins.exe
test -s build/macos/FateCoins.zip
test -s build/linux/FateCoins.x86_64

echo "Export release smoke passed"
