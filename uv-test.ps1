#Requires -Version 5.1
<#
.SYNOPSIS
  Windows port of build.sh: build a trimmed CPython standalone tree and zip it.

.NOTES
  python-build-standalone on Windows uses cpython-windows/build.py, which differs
  from the Linux flow: there is no --target-triple (the target follows $env:Platform,
  usually x64 -> x86_64-pc-windows-msvc), and there is no "lto" option; use "pgo" or
  "noopt" instead. A path to sh.exe (--sh) is required (Git Bash or MSYS2).

  Run from an "x64 Native Tools Command Prompt" (or ensure $env:Platform is "x64") so
  MSVC and the SDK match what the upstream build expects.
#>

$ErrorActionPreference = 'Stop'

$Version = '3.14'  # Used in tarball patterns; build uses --python "cpython-$Version"
$targetTriple = 'x86_64-pc-windows-msvc'
$Variant = 'pgo'   # Linux build.sh uses "lto"; Windows only offers noopt/pgo (+ freethreaded)

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir = Join-Path $RepoRoot 'python-build-standalone'
$UnpackDir = Join-Path $BuildDir (Join-Path 'dist' $Variant)
$DistDir = Join-Path $BuildDir 'dist'

Write-Host "RepoRoot: $RepoRoot"
Write-Host "BuildDir: $BuildDir"
Write-Host "UnpackDir: $UnpackDir"
Write-Host "DistDir: $DistDir"

$candidates = @(
    "${env:ProgramFiles}\Git\usr\bin\sh.exe",
    "${env:ProgramFiles(x86)}\Git\usr\bin\sh.exe",
    "${env:ProgramFiles}\Git\bin\sh.exe",
    "${env:ProgramFiles(x86)}\Git\bin\sh.exe"
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
if ($candidates.Count -ge 1) {
    $ShExe = $candidates[0]
}

Write-Host "candidates: $candidates"

if (-not $ShExe -or -not (Test-Path -LiteralPath $ShExe)) {
    throw 'Could not find sh.exe. Install Git for Windows or MSYS2, or pass -ShExe / set PBUILD_SH.'
}

if (-not $env:Platform) {
    Write-Warning 'env:Platform is unset. For an x86_64 build, use an x64 MSVC tools environment (e.g. "x64 Native Tools") or set $env:Platform = "x64".'
}

Get-ChildItem -Path $DistDir -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

Push-Location $BuildDir
try {
    & uv run --no-dev build.py `
        --help `
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}
