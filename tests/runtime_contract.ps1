$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$luaRoot = Join-Path $root "src\lua"

$events = Get-Content -Raw (Join-Path $luaRoot "zarg4n_events.lua")
$stats = Get-Content -Raw (Join-Path $luaRoot "zarg4n_stats.lua")
$stateStore = Get-Content -Raw (Join-Path $luaRoot "zarg4n_state_store.lua")
$entrypoint = Get-Content -Raw (Join-Path $luaRoot "zarg4n_career_overhaul.lua")

if ($events -match 'local Enums\s*=\s*require') {
    throw "Career enums module exports globals; assigning require result is unsupported."
}

if ($events -match 'Enums\.ENUM_CM_EVENT') {
    throw "Career event constants must use the Live Editor global enum names."
}

if ($stats -match 'row\.avg.*appearances') {
    throw "Live Editor avg is already a competition total and must not be weighted twice."
}

if ($events -notmatch 'PlayerWriter\.Apply') {
    throw "Calculated potential, physical growth and PlayStyles are not written to the career database."
}

$candidateFields = @(
    "strength", "jumping", "shotpower", "longshots", "stamina", "acceleration",
    "sprintspeed", "interceptions", "finishing", "positioning", "reactions",
    "ballcontrol", "dribbling", "vision", "shortpassing", "longpassing",
    "standingtackle", "defensiveawareness"
)
foreach ($field in $candidateFields) {
    $escapedField = [regex]::Escape($field)
    if ($events -notmatch "GetRecordFieldValue\(record,\s*`"$escapedField`"\)") {
        throw "Events row does not read required FC 26 player field: $field"
    }
}

if ($events -match 'GetRecordFieldValue\(record,\s*"marking"\)') {
    throw "FC 26 defensive awareness must use defensiveawareness, not marking."
}

if ($events -notmatch 'evolution\s*=\s*evolution' -or $events -notmatch 'PlayStyles\.ApplyEvolution') {
    throw "Archetype evolution must be prepared as transaction data and committed explicitly."
}

if ($events -notmatch 'last_processed_date') {
    throw "Season-end processing must be idempotent."
}

if ($events -notmatch 'profile\.last_processed_date\s*~=\s*current_date') {
    throw "Season processing must be idempotent per player after a partial failure."
}

if ($events -notmatch 'pending_transaction') {
    throw "Player updates must persist a recoverable pending transaction before database writes."
}

if ($events -notmatch 'committed_transaction' -or $events -notmatch 'PlayerWriter\.Matches') {
    throw "Completed targets must be reconciled against the EA career save after reload."
}

$rollbackFields = @(
    "last_development",
    "playstyle_candidates",
    "last_playstyle_award",
    "last_stats",
    "physical_projection",
    "last_processed_date",
    "archetype_phase",
    "role_archetype",
    "candidate_affinities",
    "archetype_history",
    "strength_growth_total",
    "jumping_growth_total",
    "pending_transaction",
    "committed_transaction",
    "seasons_observed",
    "identity_revealed"
)

$hasRollbackHelpers = (
    $events -match 'local function snapshot_profile\s*\(' -and
    $events -match 'local function restore_profile\s*\(' -and
    $events -match 'local function deep_copy\s*\('
)
if (-not $hasRollbackHelpers) {
    throw "Player transaction rollback must use explicit deep snapshot and restore helpers."
}

foreach ($field in $rollbackFields) {
    $escapedField = [regex]::Escape($field)
    if ($events -notmatch "$escapedField\s*=\s*deep_copy\(profile\.$escapedField\)") {
        throw "Player transaction snapshot does not deep-copy profile field: $field"
    }
    if ($events -notmatch "profile\.$escapedField\s*=\s*deep_copy\(snapshot\.$escapedField\)") {
        throw "Player transaction rollback does not restore profile field: $field"
    }
}

if ($events -notmatch 'local profile_snapshot\s*=\s*snapshot_profile\(profile\)') {
    throw "Player transaction must capture its complete profile snapshot before commit mutations."
}

if ($events -notmatch 'restore_profile\(profile,\s*profile_snapshot\)') {
    throw "State commit failure must restore the complete pre-transaction profile snapshot."
}

if ($events -notmatch 'Config\.max_profile_age') {
    throw "Runtime must use an explicit supported career-development age range."
}

if ($stateStore -match '\\Desktop\\') {
    throw "Runtime state must remain inside the Live Editor data directory."
}

if ($entrypoint -notmatch 'player_development_manager:Load') {
    throw "Live Editor development overrides must be loaded for the active save."
}

if ($entrypoint -notmatch 'package\.path') {
    throw "Runtime entrypoint must make modules in lua/scripts resolvable from lua/autorun."
}

if ($entrypoint -notmatch 'GetSaveUID' -or $entrypoint -notmatch 'runtime\.state\.save_uid\s*~=\s*save_uid') {
    throw "Runtime must reload state when the active career save changes."
}

if ($entrypoint -notmatch 'ZARG4N_CAREER_RUNTIME_LOADED') {
    throw "Runtime must prevent duplicate event registration."
}

if ($events -notmatch 'player_development_manager:Save') {
    throw "Live Editor development overrides must be persisted after season processing."
}

if ($stateStore -notmatch '\.tmp') {
    throw "State writes must use a temporary file before replacement."
}

if ($stateStore -notmatch 'state file is corrupted') {
    throw "Corrupted state must stop processing instead of silently starting clean."
}

Write-Output "PASS: Live Editor runtime contract checks passed."
