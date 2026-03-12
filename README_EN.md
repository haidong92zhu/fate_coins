# Fate Coins - Game Instructions

## Game Overview
Fate Coins is a strategic coin-flipping game where players collect coins by flipping different types of coins and use coin attack power to defeat enemies.

## System Requirements
- Windows 7/8/10/11
- Mac OS X 10.10+
- Linux (Ubuntu 16.04+)
- 512MB RAM
- 100MB disk space

## Installation

### Windows
1. Download FateCoins-win64.zip
2. Extract to any folder
3. Double-click FateCoins.exe to run

### Mac
1. Download FateCoins-mac.zip
2. Extract to Applications folder
3. Double-click FateCoins.app
4. If prompted "can't be opened", right-click → Open

### Linux
1. Download FateCoins-linux.zip
2. Extract to any folder
3. Add execute permission to FateCoins.x86_64:
   ```bash
   chmod +x FateCoins.x86_64
   ```
4. Run the game:
   ```bash
   ./FateCoins.x86_64
   ```

## How to Play

### Main Menu
- **New Game**: Start a new game
- **Continue**: Continue from previous save
- **Settings**: Adjust game options

### Game Screen
- **Place Coins**: Select coin type from right sidebar, drag to 4x5 grid in center
- **Flip Coins**: Click coins in grid to flip them
- **Check Status**: Top status bar shows flip attempts and results
  - Red = Success (hit)
  - Green = Fail (miss)
  - Gray = Not flipped yet
- **Collect Coins**: Earn coins after successful flips
- **Buy Equipment**: Purchase new coin types and items in shop

### Controls
- **Mouse Left**: Click, select, drag
- **ESC**: Return to previous menu

## Game Rules

### Basic Rules
1. 3 manual flips per round
2. Each coin has attack power
3. Total attack power deals damage to enemies
4. Collect enough coins to proceed to next round
5. Coins needed grow by 30% each round

### Coin Types
- **Normal Coin**: Basic coins, no special effects
- **Reverse Coin**: Double chance, requires fund doubling
- **Glass Coin**: 20% break chance,正面 gains 3
- **Bitcoin**: No flip limit, value grows 20%, 50% drop chance
- **Stock Coin**: +10% or -10% on success, -10% on fail
- **Lucky Coin**: Increases future coin amount
- **Ming Coin**: Reduces HP, greatly reduces final coin count
- **Vampire Coin**: Increases max HP on successful flip
- **Angel Coin**: Restores HP, clears all Demon marks, generates 5 coins per mark, adds Angel mark
- **Demon Coin**: Deducts HP, clears Angel marks, generates 1 coin per mark, adds Demon mark
- **Spirit Stone**: Triggers an extra manual flip, consumes internal spirit power

### Battle System
- Attack mode: Similar to Pinball game
- Enemies come from afar, move forward once per turn
- Attack after 5 turns when reaching cat
- Ranged rats can attack remotely

## Saving
- Game auto-saves
- Manual save supported
- Multiple save slots

## Troubleshooting

**Q: Game won't start**
A: Ensure system meets minimum requirements and re-download.

**Q: Game lags**
A: Close other resource-heavy programs or lower graphics settings.

**Q: Save files lost**
A: Ensure game has write permissions and check save directory.

## Support
For issues, contact:
- Email: support@fatecoins.com
- Discord: https://discord.gg/fatecoins
- Reddit: https://reddit.com/r/FateCoins

## Version Info
- Game Version: v1.0
- Build Date: 2026-03-12
- Engine: Godot Engine 4.x

---

Enjoy the game! 🪙
