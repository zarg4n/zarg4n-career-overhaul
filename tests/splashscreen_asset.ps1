$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$source = "C:\Users\Aynur\Desktop\eafc26 MODS\ChatGPT Image 23 Tem 2026 19_05_32.png"
$prepared = Join-Path $root "assets\splashscreen\zarg4n_splash_3840x2160.png"
$expectedSourceHash = "036C5D64B7E7EE859F11D74D9A34B9BA17942F640A4822D14A44673B0B87958F"

if (-not (Test-Path -LiteralPath $source)) {
    throw "Missing supplied splashscreen source."
}
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash -ne $expectedSourceHash) {
    throw "Supplied splashscreen source has changed."
}
if (-not (Test-Path -LiteralPath $prepared)) {
    throw "Missing prepared splashscreen asset."
}

$image = [System.Drawing.Image]::FromFile($prepared)
try {
    if ($image.Width -ne 3840 -or $image.Height -ne 2160) {
        throw "Splashscreen must be exactly 3840x2160."
    }
    if ($image.RawFormat.Guid -ne [System.Drawing.Imaging.ImageFormat]::Png.Guid) {
        throw "Splashscreen must remain a lossless PNG."
    }
}
finally {
    $image.Dispose()
}

Write-Output "PASS: splashscreen source is 3840x2160."
