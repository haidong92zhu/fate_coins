# Fate Coins License Notes

This file tracks release-facing license status for the current Steam-readiness pass.

## Project Code And Game Content

- Game code, design text, procedural assets, screenshots, and generated audio in this repository are project-owned unless a later asset replacement states otherwise.
- Current procedural art and audio were generated locally by the repository tools under `tools/`.
- Store capsules and screenshots under `textures/branding/` and `screenshots/steam/` are placeholder release assets for internal Steam-page preparation and should be replaced or re-approved before a final commercial build.

## Engine

- Built with Godot Engine 4.6.
- Godot Engine is distributed under the MIT License.
- Final release packages should include Godot's license text and third-party notices from the exact engine build used for export.

## Final Release Checklist

- Recheck this file after any non-generated art, font, music, sound, middleware, or plugin is added.
- Add a specific entry for each external asset with title, author/source, license, URL or purchase record, and redistribution notes.
- Keep platform-specific signing, notarization, and Steam redistributable notes with release build records.
