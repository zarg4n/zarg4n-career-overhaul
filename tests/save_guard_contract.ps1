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
if ($source -notmatch 'IsValidSaveUid') {
    throw 'Conservative save UID validation is missing.'
}
if ($source -notmatch 'state_origin\s*=\s*FRESH_STATE_ORIGIN') {
    throw 'Fresh-career state origin is missing.'
}
if ($source -notmatch 'awaiting_initial_user_added\s*=\s*true') {
    throw 'Fresh-career one-shot activation lifecycle is missing.'
}
if ($source -notmatch 'function Migrations\.ValidateCurrent') {
    throw 'Current-schema validation is missing.'
}
if ($source -match 'function Migrations\.Upgrade') {
    throw 'Legacy state migration must not be supported.'
}
if ($source -match 'user_opt_in') {
    throw 'General user opt-in must not enable legacy careers.'
}
if ($source -notmatch 'event_marker\s*~=\s*INITIAL_USER_MARKER') {
    throw 'Activation must require the exact initial-user event marker.'
}

Write-Output 'PASS: save guard source contract.'
