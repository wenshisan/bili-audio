# Point .cursor/skills at .claude/skills so both tools share one skill tree.
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$cursorDir = Join-Path $root ".cursor"
$link = Join-Path $cursorDir "skills"
$target = Join-Path $root ".claude\skills"

if (-not (Test-Path $target)) {
  throw "Missing skill source: $target"
}

New-Item -ItemType Directory -Force -Path $cursorDir | Out-Null

if (Test-Path $link) {
  $item = Get-Item $link -Force
  $isLink = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
  if (-not $isLink) {
    throw ".cursor\skills is a real directory. Remove it before recreating the junction."
  }
  cmd /c rmdir "$link" | Out-Null
}

cmd /c mklink /J "$link" "$target" | Out-Null
Write-Output "Linked $link -> $target"
