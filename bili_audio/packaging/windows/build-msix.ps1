param(
  [switch]$SkipIfUnconfigured
)

$ErrorActionPreference = 'Stop'
$appRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $appRoot

$identity = $env:MSSTORE_IDENTITY_NAME
$publisher = $env:MSSTORE_PUBLISHER
$publisherName = $env:MSSTORE_PUBLISHER_DISPLAY_NAME
$values = @($identity, $publisher, $publisherName)
$missingCount = @($values | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count
$configured = $values.Count - $missingCount

if ($missingCount -gt 0) {
  $message = @'
Microsoft Store package identity is not set.
In Partner Center open the app, then Product management, then Product identity.
Set MSSTORE_IDENTITY_NAME, MSSTORE_PUBLISHER, and MSSTORE_PUBLISHER_DISPLAY_NAME.
'@
  if ($SkipIfUnconfigured -and $configured -eq 0) {
    Write-Host $message
    exit 0
  }
  Write-Error $message
}

New-Item -ItemType Directory -Force -Path dist | Out-Null
dart run msix:create --store `
  --build-windows true `
  --windows-build-args "--dart-define=MICROSOFT_STORE=true" `
  --identity-name $identity `
  --publisher $publisher `
  --publisher-display-name $publisherName `
  --output-path dist `
  --output-name bili_audio-windows-x64-store
