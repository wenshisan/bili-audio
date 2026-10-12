# Build the Windows Release version and copy the artifacts to the publish dir.
#
# Usage (run from project root):
#   powershell -ExecutionPolicy Bypass -File build_release.ps1
#
# Notes:
#   - "flutter build windows" builds in Release mode by default.
#   - Release output lives in build\windows\x64\runner\Release\
#   - The destination directory is created automatically if missing.

$ErrorActionPreference = 'Stop'

# Project root = directory containing this script
$ProjectRoot = $PSScriptRoot
# Flutter Release output directory
$ReleaseDir  = Join-Path $ProjectRoot 'build\windows\x64\runner\Release'
# Publish destination directory
$DestDir     = 'C:\Users\LSM\OneDrive - Lenovo\Documents\PGB\win\release'

Write-Host '==> Building Windows Release...' -ForegroundColor Cyan
Push-Location $ProjectRoot
try {
    flutter build windows
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build windows failed (exit code $LASTEXITCODE)"
    }
}
finally {
    Pop-Location
}
Write-Host '==> Build finished.' -ForegroundColor Green

# Verify the artifacts directory exists
if (-not (Test-Path $ReleaseDir)) {
    throw "Release artifacts not found: $ReleaseDir"
}

# Ensure destination directory exists
if (-not (Test-Path $DestDir)) {
    Write-Host "==> Creating destination: $DestDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
}

Write-Host "==> Copying Release files to $DestDir ..." -ForegroundColor Cyan
# Copy everything (including subdirectories and hidden files), overwrite if exists
Copy-Item -Path (Join-Path $ReleaseDir '*') -Destination $DestDir -Recurse -Force

Write-Host "==> Published to: $DestDir" -ForegroundColor Green
