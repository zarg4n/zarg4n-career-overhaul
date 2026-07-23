# zarg4n Career Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an independent EA FC 26 TU1.6.4 career overhaul authored by zarg4n, distributed as one `.fifamod` plus one required Live Editor Lua runtime.

**Architecture:** Static database/UI changes are packaged into one `.fifamod`; dynamic career state is handled by a namespaced Lua runtime under `lua/scripts`. Runtime modules are pure decision logic around a small Live Editor adapter, so youth development can be tested without launching the game. Gameplay physics and Anth James gameplay files are outside the write set.

**Tech Stack:** EA FC 26 TU1.6.4, FIFA Editing Toolsuite 2.0.4, FIFA Mod Manager 2.0.4, FC 26 Live Editor v26.3.5 Lua API, JSON state files, UTF-8 localization data.

## Global Constraints

- Author: `zarg4n`.
- Target: EA SPORTS FC 26 TU1.6.4.
- New career required.
- One distributable `.fifamod` plus one required Lua runtime file tree.
- Do not copy KIARIKA code/assets; reimplement public behavior independently.
- Do not modify gameplay physics, AI gameplay tuning, or Anth James gameplay tables.
- Runtime writes must be guarded by career-mode and save-state checks.
- All user-facing text must have Turkish and English keys.

---

### Task 1: Create the source layout and runtime bootstrap

**Files:**
- Create: `src/lua/zarg4n_career_overhaul.lua`
- Create: `src/lua/zarg4n_config.lua`
- Create: `src/lua/zarg4n_logger.lua`
- Create: `tests/source_layout.ps1`

**Interfaces:**
- Produces a namespaced runtime entrypoint that registers `post__CareerModeEvent`.
- Configuration exposes exact target version, state directory name, and development caps.

- [ ] Add a version guard and safe no-op path outside career mode.
- [ ] Add structured logging with the save UID when available.
- [ ] Add a PowerShell source-layout test that checks the required files and forbidden gameplay paths.
- [ ] Run the source-layout test and confirm it passes.

### Task 2: Implement profile and state persistence

**Files:**
- Create: `src/lua/zarg4n_state_store.lua`
- Create: `src/lua/zarg4n_player_profile.lua`
- Create: `tests/profile_rules.ps1`

**Interfaces:**
- `StateStore:Load(save_uid): table`
- `StateStore:Save(save_uid, state): boolean`
- `PlayerProfile:Create(player_row, seed): table`
- `PlayerProfile:Validate(profile): boolean`

- [ ] Define profile fields for physical, speed, technical, mental, aerial, body growth, memory, and PlayStyle affinity.
- [ ] Use deterministic seed derivation from save UID and player ID so reloads do not reroll players.
- [ ] Clamp all profile values to `[0, 100]`.
- [ ] Save only namespaced zarg4n state and never overwrite game database rows for custom memory data.
- [ ] Test deterministic profiles and invalid-state recovery.

### Task 3: Implement performance aggregation and development scoring

**Files:**
- Create: `src/lua/zarg4n_stats.lua`
- Create: `src/lua/zarg4n_development.lua`
- Modify: `src/lua/zarg4n_career_overhaul.lua`
- Create: `tests/development_rules.ps1`

**Interfaces:**
- `Stats:Aggregate(player_id, raw_stats): table`
- `Development:Calculate(profile, aggregate, context): table`
- `Development:Apply(runtime_adapter, player_id, result): boolean`

- [ ] Aggregate goals, assists, appearances, average rating, clean sheets, saves, cards, and position-specific proxy stats when the API exposes them.
- [ ] Preserve cameo contributions while applying a minutes-confidence factor.
- [ ] Keep normal development separate from potential adjustment.
- [ ] Limit season potential adjustment to `-2..+3` and clamp to the player’s existing development ceiling.
- [ ] Apply only whitelisted development-plan fields and never gameplay fields.
- [ ] Test a 15-minute goal-plus-assist cameo, a regular starter, and a poor high-minute season.

### Task 4: Implement physical growth and PlayStyle affinity

**Files:**
- Create: `src/lua/zarg4n_physical_growth.lua`
- Create: `src/lua/zarg4n_playstyles.lua`
- Create: `tests/playstyle_rules.ps1`

**Interfaces:**
- `PhysicalGrowth:Calculate(profile, player_row, context): table`
- `PlayStyles:BuildCandidates(profile, player_row, aggregate): table`
- `PlayStyles:ChoosePlus(candidates, selection): table`

- [ ] Keep body growth separate from numeric physical attributes.
- [ ] Make Bruiser increase strength/body-growth affinity without making every defender large.
- [ ] Add age-gated, low-probability height/weight deltas with hard caps.
- [ ] Map the existing Live Editor PlayStyle enum values without copying external assets.
- [ ] Build 2–3 PlayStyle+ candidates from profile, position, quality, and multi-match behavior.
- [ ] Test fast/lean CB, strong/slow CB, technical CAM, and Bruiser growth cases.

### Task 5: Add save/new-career validation and event wiring

**Files:**
- Modify: `src/lua/zarg4n_career_overhaul.lua`
- Create: `src/lua/zarg4n_events.lua`
- Create: `tests/event_rules.ps1`

**Interfaces:**
- `Events:OnCareerEvent(event_id, event): void`
- `Events:IsNewCareer(state, current_date): boolean`

- [ ] Handle career initialization, save-load preparation, day/week passage, post-match, and season-end events.
- [ ] Reject legacy saves with a clear log/message and do not mutate them.
- [ ] Recompute development only once per relevant event using idempotent state markers.
- [ ] Test duplicate event delivery and save reload behavior.

### Task 6: Implement localization and dialogue data contracts

**Files:**
- Create: `data/localization/tr_tr.json`
- Create: `data/localization/en_us.json`
- Create: `src/lua/zarg4n_dialogue.lua`
- Create: `tests/localization.ps1`

**Interfaces:**
- `Dialogue:Select(event_context, personality, locale): table`
- `Dialogue:ApplyChoice(state, choice_id): table`

- [ ] Define event tags for match events, player requests, press questions, promises, and transfer conversations.
- [ ] Add at least ten authored variants per initial event family before UI integration.
- [ ] Validate that every Turkish key has an English counterpart and vice versa.
- [ ] Keep choices grounded in football language and attach explicit morale/sharpness/trust effects.

### Task 7: Build the HUD and single-package export

**Files:**
- Create: `src/ui/README.md`
- Create: `src/package_manifest.json`
- Create: `tests/package_manifest.ps1`
- Generated: `dist/zarg4n Career Overhaul.fifamod`

**Interfaces:**
- HUD consumes the profile/development/PlayStyle state contract from runtime.
- Package manifest records author, target TU, and excluded gameplay paths.

- [ ] Add HUD panels to player details and development plan surfaces without replacing the full Career Hub.
- [ ] Add safe fallback text when runtime state is unavailable.
- [ ] Build one `.fifamod` with zarg4n-owned database/UI/localization assets.
- [ ] Verify the package contains no KIARIKA filenames, Anth James filenames, or gameplay-tuning paths.
- [ ] Launch the game through FIFA Mod Manager and validate a new career end-to-end.
