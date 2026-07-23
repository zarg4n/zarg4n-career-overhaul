# Changelog

## 0.2.0 — 23 July 2026

- A fresh Manager Career is now required.
- Each career keeps its own player development data when switching saves.
- Season-end development is protected from being applied twice.
- Interrupted development updates can continue safely.
- Controlled development now covers the 27–28 prime window.
- Expanded the selection of PlayStyles players can earn.
- Added player personality foundations and Turkish/English support.
- Added the custom zarg4n 4K splashscreen.
- Moved the first player scan to the safe career-ready stage to prevent a crash while creating a new career.
- Reduced player-table work to one scan and removed unnecessary state writes from unrelated career events.
- Kept gameplay physics and CPU behaviour unchanged.

## 0.1.0-alpha — 23 July 2026

- Built a clean TU1.6.4 FIFA Editing Toolsuite project with one isolated career asset.
- Added conservative platinum/local-lad youth generation.
- Added save-specific deterministic prospect profiles.
- Added season-stat development with small-sample protection and `-2..+3` potential limits.
- Added gradual body, strength and jumping development through the early twenties.
- Kept performance development active through the prime years while preserving veteran potential values.
- Added regular PlayStyle and PlayStyle+ database writes with 80/85 OVR gates.
- Added Live Editor development-manager persistence and duplicate-event protection.
- Added automatic `lua/autorun` startup, save-switch reloads and per-player recovery checkpoints.
- Added post-load EA save reconciliation for interrupted season-end writes.
- Added complete FC 26 PlayStyle flag preservation and side-position normalization.
- Added Lua 5.3 parsing, runtime contract, behaviour and package tests.
- Confirmed that no gameplay or attribulator asset is included.
