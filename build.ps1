#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

$Version = '3.14'
$TargetTriple = 'x86_64-pc-windows-msvc'
$Variant = 'noopt'  # Windows version doesn't offer "lto"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir = Join-Path $RepoRoot 'python-build-standalone'
$DistDir = Join-Path $BuildDir 'dist'
$UnpackDir = Join-Path $DistDir $Variant

Get-ChildItem -Path $DistDir -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

Push-Location $BuildDir
try {
    & uv run --no-dev build.py `
        --python "cpython-$Version" `
        --options $Variant `
        --vs 2022 `
        --sh "C:\cygwin\bin\sh.exe"
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}

Write-Host "Contents of dist:"
Get-ChildItem -Path $DistDir -Recurse | ForEach-Object { Write-Host $_.FullName }

# New-Item -ItemType Directory -Path $UnpackDir -Force | Out-Null

# $tarball = Get-ChildItem -Path $DistDir -File |
#     Where-Object { $_.Name -like "cpython-$Version*$TargetTriple-$Variant*.tar.zst" } |
#     Select-Object -First 1

# if (-not $tarball) {
#     throw "No matching tarball under $DistDir (cpython-$Version*-$TargetTriple-$Variant*.tar.zst)."
# }

# & tar -C $UnpackDir -xf $tarball.FullName
# if ($LASTEXITCODE -ne 0) {
#     throw "tar failed (exit $LASTEXITCODE). Ensure Windows tar supports zstd or install a recent tar/zstd."
# }

# # Remove unnecessary files and directories (same intent as build.sh; layout differs on Windows).

# $installRoot = Join-Path $UnpackDir 'python\install'
# if (-not (Test-Path -LiteralPath $installRoot)) {
#     throw "Expected layout not found: $installRoot"
# }

# # Linux: rm -rf bin/ include/ share/
# foreach ($extra in @('Include', 'Scripts', 'Doc')) {
#     $p = Join-Path $installRoot $extra
#     if (Test-Path -LiteralPath $p) {
#         Remove-Item -LiteralPath $p -Recurse -Force
#     }
# }

# # Linux drops share/ (tcl/tk trees live there on Unix); trim obvious counterparts when present.
# foreach ($pattern in @('tcl*', 'tk*', 'share')) {
#     Get-ChildItem -Path $installRoot -Directory -ErrorAction SilentlyContinue |
#         Where-Object { $_.Name -like $pattern } |
#         ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }
# }

# # Stdlib trim under Lib\ (Unix uses lib/python$Version\).
# $libPy = Join-Path $installRoot 'Lib'
# if (-not (Test-Path -LiteralPath $libPy)) {
#     throw "Expected stdlib directory not found: $libPy"
# }

# $configPattern = "config-$Version-*"
# Get-ChildItem -Path $libPy -Directory -ErrorAction SilentlyContinue |
#     Where-Object {
#         $_.Name -like $configPattern -or
#         $_.Name -eq 'test' -or
#         $_.Name -eq 'idlelib' -or
#         $_.Name -eq 'ensurepip'
#     } |
#     ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }

# # Linux build.sh removes lib-dynload where extensions are folded into libpython; keep Lib\lib-dynload on Windows.

# $sitePackages = Join-Path $libPy 'site-packages'
# if (Test-Path -LiteralPath $sitePackages) {
#     Remove-Item -LiteralPath (Join-Path $sitePackages 'pip') -Recurse -Force -ErrorAction SilentlyContinue
#     Get-ChildItem -Path $sitePackages -Directory -Filter 'pip-*.dist-info' -ErrorAction SilentlyContinue |
#         ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }
# }

# # Zip: Linux packs lib/ only; Windows embedding typically needs Lib\, DLLs\, and core *.dll next to python.exe.
# $zipName = 'python-windows.zip'
# $zipPath = Join-Path $RepoRoot $zipName
# if (Test-Path -LiteralPath $zipPath) {
#     Remove-Item -LiteralPath $zipPath -Force
# }

# Push-Location $installRoot
# try {
#     $payload = @(Join-Path $installRoot 'Lib')
#     $dllsDir = Join-Path $installRoot 'DLLs'
#     if (Test-Path -LiteralPath $dllsDir) {
#         $payload += $dllsDir
#     }
#     $payload += @(Get-ChildItem -Path . -File -Filter '*.dll' | ForEach-Object { $_.FullName })
#     Compress-Archive -Path $payload -DestinationPath $zipPath -CompressionLevel Fastest -Force
# }
# finally {
#     Pop-Location
# }

# Write-Host "Wrote $(Join-Path $RepoRoot $zipName)"
