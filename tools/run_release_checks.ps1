param(
  [switch]$Package,
  [switch]$Build,
  [switch]$RequireStoreSigning,
  [string]$ReleaseId
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$flutter = "C:\Users\shrud\.gemini\antigravity\scratch\flutter\bin\flutter.bat"

function Invoke-Checked {
  param(
    [string]$Label,
    [scriptblock]$Command
  )

  Write-Host "==> $Label"
  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$Label failed with exit code $LASTEXITCODE"
  }
}

Invoke-Checked "Flutter analyze" { & $flutter analyze }
Invoke-Checked "Flutter test" { & $flutter test }
Invoke-Checked "Firebase Functions lint" { & npm.cmd --prefix functions run lint }

if ($Package -or $Build) {
  $packageScript = Join-Path $PSScriptRoot "package_release.ps1"
  $packageArgs = @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    $packageScript
  )

  if (-not [string]::IsNullOrWhiteSpace($ReleaseId)) {
    $packageArgs += @("-ReleaseId", $ReleaseId)
  }

  if ($Build) {
    $packageArgs += "-Build"
  }

  if ($RequireStoreSigning) {
    $packageArgs += "-RequireStoreSigning"
  }

  Invoke-Checked "Package release" { & powershell @packageArgs }
} else {
  $verifyScript = Join-Path $PSScriptRoot "verify_release.ps1"
  $verifyArgs = @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    $verifyScript
  )

  if ($RequireStoreSigning) {
    $verifyArgs += "-RequireStoreSigning"
  }

  Invoke-Checked "Verify latest release" { & powershell @verifyArgs }
}

Write-Host "Release checks passed."
