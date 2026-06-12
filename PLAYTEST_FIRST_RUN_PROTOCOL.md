# Fate Coins First-Run Playtest Protocol

## Purpose

Verify whether a new player can understand and perform the first-run core loop without coaching:

- understand the goal within 30 seconds
- drag fate-hand coins onto the board
- start the round
- click board coins
- end the round and read the settlement recap
- recover rules from the main-menu How To Play panel when confused

This protocol is for release-readiness observation, not balance tuning.

## Participant Setup

- Use a player who has not played Fate Coins before.
- Do not explain the rules before the test.
- Ask the player to think aloud.
- Run the latest Godot build or editor launch at 1600x1000 if possible.
- Start from a fresh local save/settings state when possible.

## Observer Rules

- Do not teach unless the player is fully stuck for more than 90 seconds.
- Record what the player tries before helping.
- Record exact confusion words when possible.
- Do not count a step as understood if the player only succeeds after direct instruction.

## First 30 Seconds

Pass target: the player can answer at least two of these without coaching:

- "What is the game asking you to do first?"
- "Where do you think your playable coins are?"
- "What button starts the action phase?"
- "What resource looks dangerous or important?"

## Core Loop Tasks

Record pass/fail and time-to-action for each task:

1. Open or notice How To Play from the main menu.
2. Start a new game.
3. Identify the fate hand.
4. Drag 3 hand coins onto the board.
5. Start the round.
6. Click at least 1 board coin.
7. End the round.
8. Read the settlement recap.
9. Describe one next-step choice: buy, remove, lock, lower wager, or fight enemies.

## Friction Tags

Use these tags in the observation template:

- `unclear_goal`
- `missed_drag`
- `missed_start`
- `missed_click`
- `missed_end`
- `hud_overload`
- `text_too_small`
- `rules_needed`
- `shop_confusion`
- `enemy_confusion`
- `wager_confusion`
- `good_surprise`

## Pass Bar For Steam-Readiness

This build is not first-run ready until at least 3 fresh players satisfy all of the following:

- 2/3 understand the first action within 30 seconds.
- 2/3 place 3 coins without direct instruction.
- 2/3 complete the first round within 5 minutes.
- 2/3 can explain quota or health as a lose condition after the first settlement.
- No player gets blocked by menu, settings, language, or save/delete behavior.

## Follow-Up

After each session:

- Save the completed observation file as `playtests/first_run/YYYY-MM-DD_player_##.md`.
- List the top 3 fixes before adding new features.
- If the same friction tag appears in 2 or more sessions, treat it as a release blocker.
