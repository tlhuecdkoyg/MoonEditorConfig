$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$moonCommand = Get-Command moon -ErrorAction SilentlyContinue
$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
$moon = if ($moonCommand) { $moonCommand.Source } else { "D:\conda\environments\moonbit\moonbit-toolchain\bin\moon.exe" }
$node = if ($nodeCommand) { $nodeCommand.Source } else { "D:\conda\environments\moonbit\node.exe" }

if (-not (Test-Path -LiteralPath $moon)) { throw "找不到 MoonBit：$moon" }
if (-not (Test-Path -LiteralPath $node)) { throw "找不到 Node.js：$node" }

Push-Location $root
try {
  & $moon build --target js --release web/app
  if ($LASTEXITCODE -ne 0) { throw "Studio 构建失败" }
  & $node tools/studio_server.mjs
} finally {
  Pop-Location
}
