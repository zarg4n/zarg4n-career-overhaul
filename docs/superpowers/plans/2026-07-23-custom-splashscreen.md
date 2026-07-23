# Custom Splashscreen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the supplied Galatasaray wallpaper into the existing zarg4n Career Overhaul FIFAMOD as FC 26's splashscreen.

**Architecture:** Prepare one lossless 3840×2160 source image, import it into the verified FC 26 splash texture asset, and export the existing project as a single updated FIFAMOD. The runtime and gameplay assets remain unchanged.

**Tech Stack:** PNG, FIFA Editing Toolsuite 2.0.4, FC 26 TU1.6.4 FIFAMOD, PowerShell verification.

## Global Constraints

- Use `C:\Users\Aynur\Desktop\eafc26 MODS\ChatGPT Image 23 Tem 2026 19_05_32.png`.
- Output exactly 3840×2160 without generative alteration.
- Modify `Fifa/FESplash/SplashScreen/SplashScreen`.
- Keep one `zarg4n Career Overhaul.fifamod`; do not create a separate addon.
- Do not modify gameplay or attribulator assets.
- Preserve all 18 Live Editor Lua files unchanged.

---

### Task 1: Prepare the splash source

**Files:**
- Create: `assets/splashscreen/zarg4n_splash_3840x2160.png`
- Create: `tests/splashscreen_asset.ps1`

**Interfaces:**
- Consumes: the supplied 1672×941 PNG.
- Produces: a lossless 3840×2160 PNG for texture import.

- [ ] **Step 1:** Add a test that requires a valid 3840×2160 PNG and verifies the source artwork path.
- [ ] **Step 2:** Run `powershell.exe -NoProfile -File tests\splashscreen_asset.ps1`; expect failure because the prepared asset is absent.
- [ ] **Step 3:** Center-crop the source to exact 16:9 and resize with high-quality Lanczos resampling.
- [ ] **Step 4:** Run the test again; expect `PASS: splashscreen source is 3840x2160`.
- [ ] **Step 5:** Commit the prepared source and test.

### Task 2: Import the FC 26 splash asset

**Files:**
- Modify: `zarg4n Career Overhaul.fifaproject`
- Modify: `release/zarg4n Career Overhaul 0.2.0.fifamod`
- Modify: `tests/release_artifacts.ps1`

**Interfaces:**
- Consumes: `assets/splashscreen/zarg4n_splash_3840x2160.png`.
- Produces: one FIFAMOD containing both `youth_scout.ini` and `Fifa/FESplash/SplashScreen/SplashScreen`.

- [ ] **Step 1:** Extend the release contract to require the splash asset string and reject gameplay/attribulator assets.
- [ ] **Step 2:** Run the release contract; expect failure against the old FIFAMOD.
- [ ] **Step 3:** Import the PNG into the splash texture while preserving `FE_SplashScreen_texgrp`, then export the existing project.
- [ ] **Step 4:** Run package, source-layout and release tests; expect all to pass.
- [ ] **Step 5:** Commit the project and FIFAMOD update.

### Task 3: Rebuild, apply and verify

**Files:**
- Modify: `release/zarg4n Career Overhaul 0.2.0 - Complete.zip`
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: the updated FIFAMOD and unchanged runtime ZIP.
- Produces: the final downloadable package and applied Mod Manager asset.

- [ ] **Step 1:** Document the integrated splash and the bottom/highest-priority load-order requirement.
- [ ] **Step 2:** Rebuild the complete ZIP and verify archive hashes.
- [ ] **Step 3:** Apply the updated FIFAMOD after the gameplay package in FIFA Mod Manager.
- [ ] **Step 4:** Verify the mod list resolves the zarg4n package last and that all Lua hashes remain unchanged.
- [ ] **Step 5:** Commit, push and update the v0.2.0 GitHub release assets.
