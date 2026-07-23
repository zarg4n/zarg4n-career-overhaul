$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$luaRoot = Join-Path $root "src\lua"
$required = @(
    "zarg4n_config.lua",
    "zarg4n_logger.lua",
    "zarg4n_state_store.lua",
    "zarg4n_player_profile.lua",
    "zarg4n_stats.lua",
    "zarg4n_development.lua",
    "zarg4n_physical_growth.lua",
    "zarg4n_playstyles.lua",
    "zarg4n_events.lua",
    "zarg4n_career_overhaul.lua"
)

foreach ($file in $required) {
    $path = Join-Path $luaRoot $file
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing source file: $file" }
}

$source = Get-ChildItem -LiteralPath $luaRoot -Filter "*.lua" -File | Get-Content -Raw
foreach ($token in @("KIARIKA", "Anth James", "gameplay", "attribulator")) {
    if ($source -match [regex]::Escape($token)) { throw "Forbidden dependency token found: $token" }
}

Write-Output "PASS: zarg4n runtime source layout is isolated."
