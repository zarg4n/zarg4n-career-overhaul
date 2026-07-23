$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root "src\legacy\zarg4n\youth_scout.ini"

if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing isolated youth scout configuration."
}

$content = Get-Content -Raw -LiteralPath $path
$expected = @{
    YOUTH_INITIAL_USER_COUNTRY_PERCENTAGE = 72
    YOUTH_PLAYER_PLATINUM_CHANCE_0 = 2
    YOUTH_PLAYER_PLATINUM_CHANCE_1 = 4
    YOUTH_PLAYER_PLATINUM_CHANCE_2 = 7
    YOUTH_PLAYER_PLATINUM_CHANCE_3 = 10
    YOUTH_PLAYER_PLATINUM_CHANCE_4 = 12
    LOCAL_LAD_CHANCE_0 = 4
    LOCAL_LAD_CHANCE_1 = 7
    LOCAL_LAD_CHANCE_2 = 11
    LOCAL_LAD_CHANCE_3 = 16
    LOCAL_LAD_CHANCE_4 = 24
}

foreach ($entry in $expected.GetEnumerator()) {
    if ($content -notmatch "(?m)^$([regex]::Escape($entry.Key))\s*=\s*$($entry.Value)\s*$") {
        throw "Unexpected value for $($entry.Key)."
    }
}

Write-Output "PASS: youth scout configuration is conservative and isolated."
