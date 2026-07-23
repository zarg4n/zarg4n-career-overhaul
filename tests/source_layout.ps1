$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$luaRoot = Join-Path $root "src\lua"
$runtimeRoot = Join-Path $root "runtime\lua\scripts"
$autorunRoot = Join-Path $root "runtime\lua\autorun"
$required = @(
    "zarg4n_config.lua",
    "zarg4n_logger.lua",
    "zarg4n_state_store.lua",
    "zarg4n_player_profile.lua",
    "zarg4n_stats.lua",
    "zarg4n_development.lua",
    "zarg4n_physical_growth.lua",
    "zarg4n_playstyles.lua",
    "zarg4n_player_writer.lua",
    "zarg4n_events.lua",
    "zarg4n_positions.lua",
    "zarg4n_migrations.lua",
    "zarg4n_save_guard.lua",
    "zarg4n_personality.lua",
    "zarg4n_memory.lua",
    "zarg4n_dialogue.lua",
    "zarg4n_transfer_observer.lua"
)

foreach ($file in $required) {
    $path = Join-Path $luaRoot $file
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing source file: $file" }
    $runtimePath = Join-Path $runtimeRoot $file
    if (-not (Test-Path -LiteralPath $runtimePath)) { throw "Missing runtime file: $file" }
    if ((Get-FileHash -LiteralPath $path).Hash -ne (Get-FileHash -LiteralPath $runtimePath).Hash) {
        throw "Runtime mirror differs from source: $file"
    }
}

$entrypoint = "zarg4n_career_overhaul.lua"
$entrypointSource = Join-Path $luaRoot $entrypoint
$entrypointRuntime = Join-Path $autorunRoot $entrypoint
if (-not (Test-Path -LiteralPath $entrypointRuntime)) { throw "Missing autorun entrypoint." }
if ((Get-FileHash -LiteralPath $entrypointSource).Hash -ne (Get-FileHash -LiteralPath $entrypointRuntime).Hash) {
    throw "Autorun entrypoint differs from source."
}

$source = Get-ChildItem -LiteralPath $luaRoot -Filter "*.lua" -File | Get-Content -Raw
foreach ($token in @("KIARIKA", "Anth James", "gameplay", "attribulator")) {
    if ($source -match [regex]::Escape($token)) { throw "Forbidden dependency token found: $token" }
}

Write-Output "PASS: zarg4n runtime source layout is isolated."
