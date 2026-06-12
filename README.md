# Fate Coins

Fate Coins is a Godot 4.6 single-player roguelite about building a volatile coin machine, surviving hostile rounds, and deciding when to play safe or risk everything.

Current direction: **Moonlit Tribunal / Silver Fate Engine**. The game now uses cold stone-blue table surfaces, moonlit silver borders, ritual-disc coin art, restrained cyan highlights, crimson danger feedback, enemy cards, relic icons, a full main menu, save/settings flow, tutorial highlights, and a repeatable first-run smoke test.

## Current Gameplay

- Drag coin tiles from the hand onto a 4x5 board during intermission.
- Start a round, then click placed coins to flip them.
- Heads, tails, failures, chain triggers, relics, wagers, and enemy pressure all modify the result.
- Earn coins, deal damage, kill enemies for bounties, and pay the round quota.
- Buy new coins, relics, consumables, or curse trades between rounds.
- Survive the 24-round run and defeat the final boss.

## Main Features In Progress

- Main menu with new game, continue, save, delete save, settings, how-to-play rules, difficulty, fullscreen, window size, mute, reduced motion, language entrance, and quit.
- In-game Credits / Licenses entry covering Godot/MIT, current generated-asset status, and external-asset registration requirements.
- Accessibility/comfort setting: Reduced Motion keeps combat text and color feedback while disabling scale, float, fade, and impact-banner motion.
- How-to-play panel from the main menu, covering the goal, 30-second core loop, wager risk, between-round choices, and what to read first.
- Four starter bags: Balanced, Chain, Gambler, Blood.
- Wager modes: Safe, Standard, Greedy, All In.
- Coin bag construction with hand draw, lock, reroll, remove, and upgrade actions.
- Enemy waves, boss rounds, relic shop, consumables, curses, events, and director pressure.
- First-run tutorial focus for hand placement, board slots, start/end action, clickable coins, and a first-settlement recap.
- Procedural Moonlit Tribunal visual assets for coins, tiles, enemies, relics, and UI categories.
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

Mid-run state smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/midrun_state_smoke_test.gd
```

Persistence recovery smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/persistence_recovery_smoke_test.gd
```

Platform storage smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/platform_storage_smoke_test.gd
```

Core localization smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/localization_smoke_test.gd
```

Desktop layout smoke test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/responsive_layout_smoke_test.gd
```

The layout report is written to `build/responsive_layout_report.md` and checks 1280x800 minimum desktop window constraints plus critical HUD, menu-button, and board-slot layout presence in the default design layout.

Audio quality check:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/audio_quality_check.gd
```

The audio quality report is written to `build/audio_quality_report.md` and checks runtime SFX/music coverage, import metadata, ResourceLoader availability, WAV format, duration, peak level, and clipping risk.

Steam store-page materials check:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/store_page_materials_check.gd
```

The store-page materials report is written to `build/store_page_materials_report.md` and checks bilingual store drafts, screenshot references, branding references, system requirements, and content notes.

Store screenshot and branding visual quality check:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/store_visual_quality_check.gd
```

The visual quality report is written to `build/store_visual_quality_report.md` and checks storefront screenshots and branding art for size, import metadata, ResourceLoader availability, sampled color variety, luminance range, and dark/bright coverage.

First-run human-observation materials check:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/first_run_playtest_materials_check.gd
```

The first-run playtest materials report is written to `build/first_run_playtest_materials_report.md` and checks that `PLAYTEST_FIRST_RUN_PROTOCOL.md` and `PLAYTEST_FIRST_RUN_OBSERVATION_TEMPLATE.md` cover the 30-second core loop, observation tasks, friction tags, and pass bar.

Release config and export template checks:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/release_config_check.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/export_template_check.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/admin/Documents/hd/game/fate_coins --script tools/release_readiness_report.gd
```

The readiness report is written to `build/release_readiness_report.md` and summarizes project metadata, branding assets, store screenshots, store visual quality, store copy, legal/credits readiness, accessibility/comfort settings, desktop layout, first-run playtest materials, three-platform export presets, export templates, and macOS signing/notarization status.

Full desktop export smoke test, after installing Godot export templates:

```bash
tools/export_release_smoke.sh
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
tools/midrun_state_smoke_test.gd Four-starter mid-run automation
tools/persistence_recovery_smoke_test.gd Save/settings recovery automation
tools/platform_storage_smoke_test.gd Platform user:// write-path automation
tools/localization_smoke_test.gd Core menu/settings/tutorial localization automation
tools/responsive_layout_smoke_test.gd Desktop layout smoke test
tools/audio_quality_check.gd Runtime audio quality check
tools/store_page_materials_check.gd Steam store-page materials check
tools/store_visual_quality_check.gd Store screenshot/branding visual quality check
tools/first_run_playtest_materials_check.gd First-run observation materials check
tools/export_template_check.gd Godot export-template availability check
tools/release_readiness_report.gd Release readiness report generator
tools/export_release_smoke.sh Three-platform export smoke script
tools/balance_simulator.gd     Heuristic balance simulator
tools/generate_audio_assets.gd Procedural audio generator
tools/generate_midnight_assets.gd Procedural art generator
PLAYTEST_FIRST_RUN_PROTOCOL.md First-run human-observation protocol
PLAYTEST_FIRST_RUN_OBSERVATION_TEMPLATE.md First-run observation note template
```

Some older prototype scripts and scenes still exist in the repository. The current playable path is `scenes/main.tscn` plus `scripts/main.gd`.

## Steam Readiness

The active readiness tracker is `STEAM_READINESS_AUDIT_CN.md`.

Completed since the prototype pass:

- Replaced the previous warm copper style with the Moonlit Tribunal / Silver Fate Engine visual direction, including the main backdrop, hard-edged panels, board cells, ritual-disc coins, and refreshed Steam screenshot candidates.
- Added a productized main menu, delete/quit confirmation dialogs, and persistent settings for audio, mute, window size, fullscreen, reduced motion, tutorial, and language entrance.
- Added a Reduced Motion option that preserves slot colors, combat text, and central alerts while disabling slot scale pulses, floating text motion, combat-feed scaling, and impact-banner fade/scale animation.
- Added an in-game Credits / Licenses entry covering Godot Engine/MIT License, generated-asset status, external-asset registration requirements, and final release notices.
- Added first-run tutorial focus, an in-HUD objective checklist, compact status metrics, first-settlement recap, main-menu how-to-play rules, and automated smoke coverage.
- Added independent icons for enemies/Bosses, relics, consumables, curses, special coins, events, and UI categories.
- Added run/warning/Boss music loops, warning/hit/hurt/victory sounds, and central impact feedback.
- Added an audio quality report covering 12 SFX and 3 music loops for file/import coverage, ResourceLoader availability, WAV format, duration, peak level, and clipping risk.
- Added bilingual Steam store-page drafts and a materials check covering short descriptions, long descriptions, key features, screenshot references, branding art, system requirements, and content notes.
- Added a store screenshot/branding visual quality report covering five English screenshots and five branding assets for size, import metadata, ResourceLoader availability, sampled color variety, luminance range, and dark/bright coverage.
- Added a first-run human-observation protocol, note template, and materials check covering the 30-second core loop, key tasks, friction tags, and the three-new-player pass bar.
- Added desktop icon, boot splash, upgraded Steam capsule/header/library candidate art, three-platform base export presets, and a release config check.
- Added license notes and platform user:// save/settings/progress write verification.
- Turned the English language entry into working core/build localization for menus, settings, HUD, tutorial checklist, side-panel headings, first-settlement recap, difficulty, wagers, starter bags, coin/tile rules, shop/management notices, enemies, combat feedback, coin states, relics, consumables, curses, events, and run-end summaries.
- Added a desktop layout smoke report for 1280x800 minimum-window constraints, default design critical controls, menu-button ordering, and 20 board slots.
- Added balance simulation reporting; Normal starter-bag heuristic win rates now sit at 47.5%, 48.8%, 48.8%, and 47.5%.
- Fixed headless smoke-test audio leaks by using standard resource loading, explicit audio cleanup, and skipping SFX playback in headless runs.

Still required before a real Steam release:

- Actual human first-run observation with three fresh players, using the new protocol/template, to verify the first 30 seconds and readability.
- Human path validation and long-curve checks to confirm stable 20-minute repeatable runs without overfitting the automation.
- Real Windows/macOS/Linux exports with Godot export templates, platform launch tests, and macOS signing/notarization strategy.
- Human-selected final screenshots, final capsule polish, and Steam backend formatting.
