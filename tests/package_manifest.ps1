$ErrorActionPreference = "Stop"
$manifestPath = Join-Path (Split-Path -Parent $PSScriptRoot) "src\package_manifest.json"
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.author -ne "zarg4n") { throw "Invalid author" }
if ($manifest.titleUpdate -ne "TU1.6.4") { throw "Invalid title update" }
if ($manifest.requiresNewCareer -ne $true) { throw "New-career requirement missing" }
if ($manifest.gameplayWrites -ne $false) { throw "Gameplay writes must remain disabled" }
Write-Output "PASS: package manifest is valid."
