$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Split-Path -Parent $PSScriptRoot
$release = Join-Path $root "release"
$project = Join-Path $root "zarg4n Career Overhaul.fifaproject"
$mod = Join-Path $release "zarg4n Career Overhaul 0.2.0.fifamod"
$runtimeZip = Join-Path $release "zarg4n Career Overhaul 0.2.0 - Live Editor Runtime.zip"
$completeZip = Join-Path $release "zarg4n Career Overhaul 0.2.0 - Complete.zip"

foreach ($path in @($project, $mod, $runtimeZip, $completeZip)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing release artifact: $path" }
    if ((Get-Item -LiteralPath $path).Length -le 0) { throw "Empty release artifact: $path" }
}

$projectHeader = [System.IO.File]::ReadAllBytes($project)[0..3]
if ([System.Text.Encoding]::ASCII.GetString($projectHeader) -ne "FETP") {
    throw "Invalid FIFA Editing Toolsuite project header."
}

$modBytes = [System.IO.File]::ReadAllBytes($mod)
$modText = [System.Text.Encoding]::ASCII.GetString($modBytes)
$requiredModStrings = @(
    "dlc/dlc_FootballCompEng/dlc/FootballCompEng/data/youth_scout.ini",
    "fifa/fesplash/splashscreen/splashscreen"
)
foreach ($requiredString in $requiredModStrings) {
    if (-not $modText.Contains($requiredString)) {
        throw "FIFAMOD is missing required asset: $requiredString"
    }
}
foreach ($forbiddenString in @("fcgameplay/", "attribulator/")) {
    if ($modText.Contains($forbiddenString)) {
        throw "FIFAMOD contains forbidden gameplay asset: $forbiddenString"
    }
}

$zip = [System.IO.Compression.ZipFile]::OpenRead($runtimeZip)
try {
    $luaEntries = @($zip.Entries | Where-Object {
        $_.FullName.Replace("\", "/") -like "lua/*/zarg4n_*.lua"
    })
    $runtimeLuaFiles = @(Get-ChildItem -Recurse -File -LiteralPath (Join-Path $root "runtime\lua") |
        Where-Object { $_.Name -like "zarg4n_*.lua" })
    if ($luaEntries.Count -ne $runtimeLuaFiles.Count) {
        throw "Runtime archive Lua count differs from the runtime source tree."
    }
    if (-not ($luaEntries.FullName.Replace("\", "/") -contains "lua/autorun/zarg4n_career_overhaul.lua")) {
        throw "Runtime entrypoint must be packaged under lua/autorun."
    }
    foreach ($entry in $luaEntries) {
        $stream = $entry.Open()
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $archiveHash = -join ($sha.ComputeHash($stream) | ForEach-Object { $_.ToString("X2") })
        }
        finally {
            $sha.Dispose()
            $stream.Dispose()
        }
        $relativePath = $entry.FullName.Replace("/", "\")
        $sourcePath = Join-Path (Join-Path $root "runtime") $relativePath
        $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
        if ($archiveHash -ne $sourceHash) { throw "Stale runtime archive entry: $($entry.FullName)" }
    }
}
finally {
    $zip.Dispose()
}

$complete = [System.IO.Compression.ZipFile]::OpenRead($completeZip)
try {
    $requiredEntries = @{
        "zarg4n Career Overhaul 0.2.0.fifamod" = $mod
        "zarg4n Career Overhaul 0.2.0 - Live Editor Runtime.zip" = $runtimeZip
        "README.md" = (Join-Path $root "README.md")
        "INSTALLATION.md" = (Join-Path $root "docs\INSTALLATION.md")
        "RELEASE_NOTES_0.2.0.md" = (Join-Path $release "RELEASE_NOTES_0.2.0.md")
    }
    foreach ($entryName in $requiredEntries.Keys) {
        $entry = $complete.GetEntry($entryName)
        if ($null -eq $entry) {
            throw "Complete archive is missing: $entryName"
        }
        $stream = $entry.Open()
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $archiveHash = -join ($sha.ComputeHash($stream) | ForEach-Object { $_.ToString("X2") })
        }
        finally {
            $sha.Dispose()
            $stream.Dispose()
        }
        $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $requiredEntries[$entryName]).Hash
        if ($archiveHash -ne $sourceHash) { throw "Stale complete archive entry: $entryName" }
    }
}
finally {
    $complete.Dispose()
}

Write-Output "PASS: release artifacts are present and structurally valid."
