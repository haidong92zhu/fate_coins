# Fate Coins Steam Store Page Draft

## Short Description

Build a fate machine that bites back in a moonlit tribunal. Drag coins, choose your wager, trigger risky chain flips, survive 24 rounds of quota pressure, and turn every greedy mistake into the next run's lesson.

## One-Line Pitch

A single-player roguelite about coin-building, grid chains, and wager risk.

## Long Description

Fate Coins is a compact single-player roguelite about building an unstable coin machine. Each round, you draw coins from your fate bag, drag them onto a 4x5 board, and click board coins to trigger payouts, damage, healing, failures, and directional chains.

Every coin has odds, facing logic, chain routes, and side effects. Safe wagers keep the machine steady; Greedy and All In wagers amplify rewards while making failures hurt. Enemies steal coins, add shields, jam routes, pollute key pieces, and force awkward repairs. Bosses change phase as their health drops, pressuring you to rebuild the machine mid-run.

Between rounds, buy new coins, relics, consumables, or curse trades for short-term power. Manage the fate bag by locking key hand coins, removing weak pieces, and upgrading board coins into a focused engine. Survive the economy, control enemy pressure, and beat the final banker before the tribunal closes.

## Key Features

- 4x5 coin-machine board: drag coins, read directions, and build chain routes.
- Wager risk system: Safe, Standard, Greedy, and All In change payout, damage, and failure costs.
- Fate-bag construction: buy, remove, upgrade, lock, and reroll coins to shape future hands.
- Enemy and boss pressure: thieves, guards, taxers, saboteurs, and bosses disrupt your strongest routes.
- Four starter archetypes: Balanced, Chain, Gambler, and Blood each push a different risk profile.
- Short single-player challenge: a 24-round run designed for repeated route optimization.
- Moonlit Tribunal art direction: cold stone panels, silver-blue coins, cyan energy, and crimson danger feedback.

## Screenshot Candidates

- `screenshots/steam/01_main_menu.png` - Productized main menu with settings, how-to-play rules, save preview, difficulty, and first-run entry.
- `screenshots/steam/02_preparation_board.png` - Planning phase with drag-and-drop fate hand, tutorial checklist, quota pressure, and enemy information.
- `screenshots/steam/03_opening_layout.png` - Early board construction with directional and special coins forming a risky engine.
- `screenshots/steam/04_combat_chain.png` - Action phase with manual triggers, coin flips, chain routes, and combat feedback.
- `screenshots/steam/05_boss_pressure.png` - Boss disruption with locks, jams, pollution, theft, and status pressure.

## Current Store Art

- `textures/branding/steam_capsule_616x353.png`
- `textures/branding/steam_header_920x430.png`
- `textures/branding/steam_library_600x900.png`

These are programmatic candidate assets for internal Steam page layout previews. They include the board, chain route, enemy danger mark, and "CHAIN RISK" subtitle. Final release should still receive human composition, typography, and capsule polish.

## Suggested Tags

- Roguelite
- Deckbuilding
- Strategy
- Turn-Based Tactics
- Board Game
- Singleplayer
- Difficult
- Replay Value

## Content Notes

Fate Coins uses abstract coin, debt, wager, and risk themes. It does not include real-money gambling, online wagering, microtransactions, or loot boxes.

## Draft System Requirements

### Windows

Minimum:

- OS: Windows 10 64-bit
- Processor: Dual-core 2.0 GHz
- Memory: 4 GB RAM
- Graphics: OpenGL 3.3 / Vulkan 1.0 compatible GPU
- Storage: 300 MB available space

Recommended:

- OS: Windows 10/11 64-bit
- Processor: Quad-core 2.5 GHz
- Memory: 8 GB RAM
- Graphics: Dedicated GPU or recent integrated GPU
- Storage: 500 MB available space

### macOS

Minimum:

- OS: macOS 12
- Processor: Intel or Apple Silicon
- Memory: 4 GB RAM
- Graphics: Metal-compatible GPU
- Storage: 300 MB available space

### Linux

Minimum:

- OS: Ubuntu 22.04 or equivalent
- Processor: Dual-core 2.0 GHz
- Memory: 4 GB RAM
- Graphics: OpenGL 3.3 / Vulkan 1.0 compatible GPU
- Storage: 300 MB available space

## Pre-Release Follow-Up

- Install Godot 4.6.2.stable export templates, run `tools/export_template_check.gd`, then build Windows/macOS/Linux packages with `tools/export_release_smoke.sh`.
- Validate launch, window mode, settings persistence, save writes, and delete-save behavior on real platforms.
- Finalize license notes, third-party declarations, and macOS signing/notarization strategy.
- Human-select or reshoot weaker automated screenshots.
- Polish final capsule composition, title typography, and store-page formatting in Steamworks.
