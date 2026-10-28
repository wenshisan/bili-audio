$ErrorActionPreference = 'Stop'
$appRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $appRoot

# 默认身份来自 pubspec.yaml 的 msix_config，与 Partner Center 的 Product identity 一致。
# 设置同名环境变量时改用环境变量。
# 商店要求版本最后一位是 0。pubspec 的 +构建号放进第三位：0.1.0+1 → 0.1.1.0。
$pubspec = Get-Content -Raw (Join-Path $appRoot 'pubspec.yaml')
if ($pubspec -notmatch '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?\s*$') {
  throw 'pubspec.yaml 里没有可用的 version'
}
$storeBuild = if ($Matches[4]) { $Matches[4] } else { $Matches[3] }
$storeVersion = "$($Matches[1]).$($Matches[2]).$storeBuild.0"
$createArgs = @(
  'run', 'msix:create', '--store',
  '--build-windows', 'true',
  '--windows-build-args', '--dart-define=MICROSOFT_STORE=true',
  '--version', $storeVersion,
  '--output-path', 'dist',
  '--output-name', 'bili_audio-windows-x64-store'
)
if (-not [string]::IsNullOrWhiteSpace($env:MSSTORE_IDENTITY_NAME)) {
  $createArgs += @('--identity-name', $env:MSSTORE_IDENTITY_NAME)
}
if (-not [string]::IsNullOrWhiteSpace($env:MSSTORE_PUBLISHER)) {
  $createArgs += @('--publisher', $env:MSSTORE_PUBLISHER)
}
if (-not [string]::IsNullOrWhiteSpace($env:MSSTORE_PUBLISHER_DISPLAY_NAME)) {
  $createArgs += @('--publisher-display-name', $env:MSSTORE_PUBLISHER_DISPLAY_NAME)
}

New-Item -ItemType Directory -Force -Path dist | Out-Null
dart @createArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
