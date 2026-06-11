# Fate Coins

Fate Coins is a Godot 4.6 single-player roguelite about building a volatile coin machine, surviving hostile rounds, and deciding when to play safe or risk everything.

Current direction: **Midnight Mint**. The game now uses dark mechanical panels, copper-gold coin art, blue-green energy feedback, enemy cards, relic icons, a full main menu, save/settings flow, tutorial highlights, and a repeatable first-run smoke test.

## Current Gameplay

- Drag coin tiles from the hand onto a 4x5 board during intermission.
- Start a round, then click placed coins to flip them.
- Heads, tails, failures, chain triggers, relics, wagers, and enemy pressure all modify the result.
- Earn coins, deal damage, kill enemies for bounties, and pay the round quota.
- Buy new coins, relics, consumables, or curse trades between rounds.
- Survive the 24-round run and defeat the final boss.

## Main Features In Progress

- Main menu with new game, continue, save, delete save, settings, difficulty, fullscreen, and quit.
- Four starter bags: Balanced, Chain, Gambler, Blood.
- Wager modes: Safe, Standard, Greedy, All In.
- Coin bag construction with hand draw, lock, reroll, remove, and upgrade actions.
- Enemy waves, boss rounds, relic shop, consumables, curses, events, and director pressure.
- First-run tutorial focus for hand placement, board slots, start/end action, and clickable coins.
- Procedural Midnight Mint visual assets for coins, tiles, enemies, relics, and UI categories.
- Balance simulator for regression checks across starter bags and difficulties.

## Run Locally

Open the project in Godot 4.6 or run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/admin/Documents/hd/game/fate_coins
```

Headless startup check:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --quit-after 1
```

First-run flow smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/first_run_smoke_test.gd
```

Balance simulation:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/balance_simulator.gd
```

Regenerate procedural art:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/generate_midnight_assets.gd
```

## Project Structure

```text
audio/                         Sound effects
scenes/main.tscn               Active game scene
scripts/main.gd                Main gameplay, UI, save/settings, tutorial, audio
scripts/game_state.gd          Runtime state object
textures/coins/                Coin art
textures/tiles/                Board tile art
textures/enemies/              Enemy and boss icons
textures/relics/               Relic icons
textures/ui/                   Category icons
tools/first_run_smoke_test.gd  First-run automation
tools/balance_simulator.gd     Heuristic balance simulator
tools/generate_midnight_assets.gd Procedural art generator
```

Some older prototype scripts and scenes still exist in the repository. The current playable path is `scenes/main.tscn` plus `scripts/main.gd`.

## Steam Readiness

The active readiness tracker is `STEAM_READINESS_AUDIT_CN.md`.

Completed since the prototype pass:

- Replaced the old placeholder style with the Midnight Mint visual direction.
- Added a productized main menu and settings flow.
- Added first-run tutorial focus and automated smoke coverage.
- Added independent enemy/Boss icons and high-frequency relic icons.
- Added balance simulation reporting.
- Fixed headless smoke-test audio leaks by using standard resource loading, explicit audio cleanup, and skipping SFX playback in headless runs.

Still required before a real Steam release:

- Human first-run observation and readability pass.
- Further balance tuning for 20-minute repeatable runs.
- Remaining relic, consumable, curse, event, and special coin icon coverage.
- Export presets, desktop app icon, version metadata, license notes, and platform launch tests.
- Real screenshots, capsule art, store copy, and system requirements.

