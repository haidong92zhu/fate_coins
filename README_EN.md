# Fate Coins

Fate Coins is a Godot 4.6 single-player coin-building roguelite. Build a volatile machine on a 4x5 board, choose how hard to wager each round, chain coin flips, survive enemy pressure, and defeat the final boss across a 24-round run.

The current art direction is **Midnight Mint**: dark green-black mechanical panels, copper-gold coins, blue-green energy feedback, red danger accents, independent enemy/Boss icons, and high-frequency relic icons.

## Current Gameplay

- During intermission, drag coin tiles from your hand onto the board.
- Start a round, then click placed coins to flip them.
- Heads, tails, failures, chain triggers, relics, wagers, and enemy effects modify each result.
- Pay the round quota after enemy pressure resolves; running out of coins or health ends the run.
- Kill enemies for bounties and prepare for boss rounds.
- Between rounds, buy coins, relics, consumables, curse trades, or manage your fate bag.
- The first-run tutorial highlights the current hand, board slots, action button, and clickable coins.

## Productized Systems

- Main menu with new game, continue, save, delete save, difficulty, settings, fullscreen, and quit.
- Four starter bags: Balanced, Chain, Gambler, Blood.
- Four wager modes: Safe, Standard, Greedy, All In.
- Enemy waves, boss rounds, relic shop, consumables, curse trades, events, and director pressure.
- Procedural Midnight Mint art for coins, tiles, enemies, relics, and UI category icons.
- Automated first-run smoke test.
- Balance simulator across difficulties and starter bags.

## Run Locally

Open `project.godot` in Godot 4.6, or run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/admin/Documents/hd/game/fate_coins
```

Startup check:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --quit-after 1
```

First-run flow test:

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
scenes/main.tscn               Current main scene
scripts/main.gd                Main gameplay, UI, save/settings, tutorial, audio
scripts/game_state.gd          Runtime state object
textures/coins/                Coin art
textures/tiles/                Board tile art
textures/enemies/              Enemy and boss icons
textures/relics/               Relic icons
textures/ui/                   UI category icons
tools/first_run_smoke_test.gd  First-run automation
tools/balance_simulator.gd     Heuristic balance simulator
tools/generate_midnight_assets.gd Procedural art generator
```

Some early prototype scripts and scenes remain in the repository. The current playable path is `scenes/main.tscn` plus `scripts/main.gd`.

## Steam Readiness

See `STEAM_READINESS_AUDIT_CN.md` for the active release-readiness tracker.

Improved since the prototype pass:

- Replaced placeholder visuals with a unified Midnight Mint direction.
- Added a main menu, settings, save/delete save, and quit flow.
- Added first-run tutorial highlights and automated first-run verification.
- Added independent enemy/Boss icons and 12 high-frequency relic icons.
- Added balance simulation reporting.
- Fixed audio leak warnings in headless first-run testing.

Still required for a real Steam release:

- Human first-run observation to verify that players understand dragging, starting, clicking, and settlement within the first 30 seconds.
- More balance tuning for stable 20-minute repeatable runs.
- Remaining relic, special coin, consumable, curse, and event icon coverage.
- Export presets, desktop app icon, version metadata, license notes, and platform launch/save tests.
- Real screenshots, capsule art, store copy, and system requirements.

