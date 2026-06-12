# Fate Coins Release Readiness Report

- Generated: 2026-06-11 23:04:22
- Godot: 4.6.2-stable (official)
- Project: Fate Coins 0.1.0
- Main scene: res://scenes/main.tscn

## Gate Summary

- [PASS] Project metadata and main scene are configured.
- [PASS] Required branding assets exist at expected sizes.
- [PASS] Five English live UI screenshots exist at 1600x1000.
- [PASS] Latest store visual quality report has no failed screenshots or branding assets.
- [PASS] Bilingual Steam store materials have no failed checks.
- [PASS] Release-facing license notes and in-game credits/legal copy are present.
- [PASS] Accessibility/comfort settings include persisted reduced-motion support.
- [PASS] Latest responsive layout smoke report has no failed checks.
- [PASS] First-run human observation protocol and template have no failed checks.
- [PASS] Latest audio quality report has no failed assets.
- [PASS] Windows, macOS, and Linux export presets target expected artifact paths.
- [BLOCKED] Export template availability for all required platforms.
- [BLOCKED] macOS signing/notarization final-release policy.

## Branding Assets

- [PASS] App icon: `res://textures/branding/app_icon.png` expected 1024x1024
- [PASS] Boot splash: `res://textures/branding/boot_splash.png` expected 1600x1000
- [PASS] Steam capsule: `res://textures/branding/steam_capsule_616x353.png` expected 616x353
- [PASS] Steam header: `res://textures/branding/steam_header_920x430.png` expected 920x430
- [PASS] Steam library: `res://textures/branding/steam_library_600x900.png` expected 600x900

## Store Screenshots

- [PASS] Screenshot manifest: `res://screenshots/steam/README.md`
- [PASS] `res://screenshots/steam/01_main_menu.png` expected 1600x1000
- [PASS] `res://screenshots/steam/02_preparation_board.png` expected 1600x1000
- [PASS] `res://screenshots/steam/03_opening_layout.png` expected 1600x1000
- [PASS] `res://screenshots/steam/04_combat_chain.png` expected 1600x1000
- [PASS] `res://screenshots/steam/05_boss_pressure.png` expected 1600x1000

## Store Visual Quality

- [PASS] Latest report: `res://build/store_visual_quality_report.md`
- Passing visual asset checks in latest report: 11

## Store Page Materials

- [PASS] Latest report: `res://build/store_page_materials_report.md`
- Passing store material checks in latest report: 10

## Legal And Credits

- [PASS] `res://LICENSES.md` includes `Godot Engine`
- [PASS] `res://LICENSES.md` includes `MIT License`
- [PASS] `res://LICENSES.md` includes `Project Code And Game Content`
- [PASS] `res://LICENSES.md` includes `Final Release Checklist`
- [PASS] `res://scripts/main.gd` includes `menu_credits_button`
- [PASS] `res://scripts/main.gd` includes `credits_dialog`
- [PASS] `res://scripts/main.gd` includes `credits_body`
- [PASS] `res://scripts/main.gd` includes `Credits / Licenses`

## Accessibility And Comfort

- [PASS] Reduced motion state: `reduced_motion_enabled`
- [PASS] Settings toggle: `reduced_motion_toggle`
- [PASS] Toggle callback: `_on_reduced_motion_toggled`
- [PASS] Persisted settings field: `reduced_motion_enabled": reduced_motion_enabled`
- [PASS] Reduced impact banner motion: `create_timer(0.95)`

## Responsive Layout

- [PASS] Latest report: `res://build/responsive_layout_report.md`
- Passing responsive layout checks in latest report: 7

## First-Run Playtest Materials

- [PASS] Latest report: `res://build/first_run_playtest_materials_report.md`
- Passing first-run playtest material checks in latest report: 2

## Export Presets

- [PASS] Windows Desktop -> `build/windows/FateCoins.exe` runnable=true filter=all_resources
- [PASS] macOS -> `build/macos/FateCoins.zip` runnable=true filter=all_resources
  - macOS signing identity: ``; notarization: `0`
- [PASS] Linux/X11 -> `build/linux/FateCoins.x86_64` runnable=true filter=all_resources

## Audio Quality

- [PASS] Latest report: `res://build/audio_quality_report.md`
- Passing audio assets in latest report: 15

## Export Templates

- Template version: `4.6.2.stable`
- Checked directories: `/Users/admin/Library/Application Support/export_templates/4.6.2.stable`, `/Users/admin/Library/Application Support/Godot/export_templates/4.6.2.stable`
- [BLOCKED] Windows Desktop requires `windows_debug_x86_64.exe`
- [BLOCKED] Windows Desktop requires `windows_release_x86_64.exe`
- [BLOCKED] macOS requires `macos.zip`
- [BLOCKED] Linux/X11 requires `linux_debug.x86_64`
- [BLOCKED] Linux/X11 requires `linux_release.x86_64`

## Expected Artifacts

- Windows Desktop: `build/windows/FateCoins.exe`
- macOS: `build/macos/FateCoins.zip`
- Linux/X11: `build/linux/FateCoins.x86_64`

## Platform Follow-Up

- Run `tools/export_release_smoke.sh` after installing Godot export templates.
- Run `tools/audio_quality_check.gd` after regenerating or replacing any audio.
- Run `tools/store_visual_quality_check.gd` after regenerating screenshots or branding art.
- Run `tools/store_page_materials_check.gd` after changing screenshots, capsules, or store copy.
- Run `tools/first_run_playtest_materials_check.gd` after changing first-run tutorial, rules, or menu flow.
- Launch each exported build and rerun save/settings/user-data checks on Windows, macOS, and Linux.
- macOS preset currently uses Godot codesign settings with no Developer ID identity and notarization disabled; final Steam release still needs signing/notarization policy confirmation.
- Final storefront still needs human-selected screenshots, final capsule polish, and English Steam backend formatting.
