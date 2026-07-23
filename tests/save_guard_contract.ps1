$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$allowedFiles = @(
    'src/lua/zarg4n_state_store.lua',
    'src/lua/zarg4n_save_guard.lua',
    'src/lua/zarg4n_migrations.lua'
)

foreach ($relativePath in $allowedFiles) {
    $path = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing save-safety module: $relativePath"
    }
}

$source = ($allowedFiles | ForEach-Object {
    Get-Content -Raw -LiteralPath (Join-Path $root $_)
}) -join "`n"

$forbidden = @(
    'TransferPlayer',
    'LoanPlayer',
    'DeleteDBTableRow',
    'SaveCareer',
    'SetRecordFieldValue',
    'EditDBTableField',
    'MEMORY\s*:\s*Write',
    'os\s*\.\s*execute',
    'io\s*\.\s*popen',
    '\.sav(?:\W|$)',
    'settings\d+',
    'career_save',
    'Documents[\\/]+EA SPORTS FC',
    'FC 26[\\/]+settings',
    'AppData[\\/]+Local[\\/]+EA SPORTS FC'
)

foreach ($pattern in $forbidden) {
    if ($source -match $pattern) {
        throw "Save-safety layer contains forbidden EA save mutation pattern: $pattern"
    }
}

if ($source -notmatch 'schema_version\s*=\s*2') {
    throw 'Schema v2 is not declared.'
}
if ($source -notmatch 'database_writes') {
    throw 'Fail-closed database write feature flag is missing.'
}
if ($source -notmatch 'migration_journal') {
    throw 'Migration journal is missing.'
}
if ($source -notmatch 'rollback_metadata') {
    throw 'Rollback metadata is missing.'
}
if ($source -notmatch 'IsValidSaveUid') {
    throw 'Conservative save UID validation is missing.'
}

Write-Output 'PASS: save guard source contract.'
