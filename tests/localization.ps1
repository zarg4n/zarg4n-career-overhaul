$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$trPath = Join-Path $root 'data/localization/tr_tr.json'
$enPath = Join-Path $root 'data/localization/en_us.json'
$sourceFiles = @(
    'src/lua/zarg4n_personality.lua',
    'src/lua/zarg4n_memory.lua',
    'src/lua/zarg4n_dialogue.lua',
    'src/lua/zarg4n_transfer_observer.lua'
)

if (-not (Test-Path -LiteralPath $trPath) -or -not (Test-Path -LiteralPath $enPath)) {
    throw 'Both localization catalogs must exist.'
}

$tr = Get-Content -LiteralPath $trPath -Raw | ConvertFrom-Json
$en = Get-Content -LiteralPath $enPath -Raw | ConvertFrom-Json
$trProperties = @($tr.PSObject.Properties)
$enProperties = @($en.PSObject.Properties)
$trKeys = @($trProperties.Name | Sort-Object)
$enKeys = @($enProperties.Name | Sort-Object)

if (Compare-Object $trKeys $enKeys) {
    throw 'Turkish and English localization keys do not match.'
}

foreach ($family in @('post_match', 'promise', 'press', 'transfer_observer')) {
    $keys = @($trKeys | Where-Object { $_ -match "^$family\.\d{2}$" })
    if ($keys.Count -lt 10) {
        throw "$family must contain at least 10 matched variants."
    }
}

foreach ($key in $trKeys) {
    if (
        [string]::IsNullOrWhiteSpace([string]$tr.PSObject.Properties[$key].Value) -or
        [string]::IsNullOrWhiteSpace([string]$en.PSObject.Properties[$key].Value)
    ) {
        throw "Blank localization value: $key"
    }
}

$authoredText = (($trProperties.Value + $enProperties.Value) -join "`n")
if ($authoredText -match '(?i)kiarika|anth\s+james') {
    throw 'Authored content contains a forbidden third-party name.'
}

$awkwardPhrases = @(
    'kapıyı kapattı, fakat kilidi değiştirmedi',
    'ayrıntılar, anlaşmanın kendisinden daha tehlikeli',
    'anlatı rakamlardan sahaya',
    'stepping through is yours',
    'minutes carrying pressure',
    'details are now more dangerous than the agreement itself'
)
foreach ($phrase in $awkwardPhrases) {
    if ($authoredText -match [regex]::Escape($phrase)) {
        throw "Artificial or awkward dialogue remains: $phrase"
    }
}

$forbiddenApis = '(?i)' + (
    @(
        'MEMORY\s*:',
        'SetRecordFieldValue',
        'EditDBTableField',
        'GetDBTableRows',
        'GetSaveUID',
        'MessageBox',
        'GameLocalizationManager',
        'TransferPlayer',
        'LoanPlayer'
    ) -join '|'
)
foreach ($relativePath in $sourceFiles) {
    $path = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing source file: $relativePath"
    }
    $source = Get-Content -LiteralPath $path -Raw
    if ($source -match $forbiddenApis) {
        throw "Forbidden game-writing API in $relativePath"
    }
}

Write-Output 'PASS: localization and forbidden API contract'
