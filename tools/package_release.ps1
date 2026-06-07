param(
  [string]$ReleaseId = (Get-Date -Format "yyyyMMdd-HHmm"),
  [switch]$Build,
  [switch]$RequireStoreSigning,
  [switch]$SkipVerify,
  [switch]$KeepFailedPackage
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$flutter = "C:\Users\shrud\.gemini\antigravity\scratch\flutter\bin\flutter.bat"
$releaseRoot = Join-Path $repoRoot "release\BridgeClip-$ReleaseId"
$windowsStage = Join-Path $releaseRoot "BridgeClip-Windows-release"
$windowsZip = Join-Path $releaseRoot "BridgeClip-Windows-release.zip"
$releaseExistedBefore = Test-Path $releaseRoot

function Update-PackagedReleasePaths {
  param(
    [string]$Path,
    [string]$ReleaseId
  )

  $content = Get-Content -Encoding UTF8 $Path
  $content = $content `
    -replace 'release\\BridgeClip-[^\\`]+\\BridgeClip-Windows-release\.zip',
      "release\BridgeClip-$ReleaseId\BridgeClip-Windows-release.zip" `
    -replace 'release\\BridgeClip-[^\\`]+\\BridgeClip-Android-release\.apk',
      "release\BridgeClip-$ReleaseId\BridgeClip-Android-release.apk" `
    -replace 'release\\BridgeClip-[^\\`]+\\BridgeClip-Android-release\.aab',
      "release\BridgeClip-$ReleaseId\BridgeClip-Android-release.aab" `
    -replace 'release\\BridgeClip-[^\\`]+',
      "release\BridgeClip-$ReleaseId"
  Set-Content -Encoding UTF8 -Path $Path -Value $content
}

if ($Build) {
  & $flutter build apk --release
  & $flutter build appbundle --release
  & $flutter build windows
}

$requiredFiles = @(
  "build\app\outputs\flutter-apk\app-release.apk",
  "build\app\outputs\bundle\release\app-release.aab",
  "build\windows\x64\runner\Release\clipboard_sync.exe",
  "RELEASE_NOTES.md",
  "RELEASE_AUDIT.md"
)

foreach ($file in $requiredFiles) {
  if (-not (Test-Path $file)) {
    throw "Missing required release input: $file"
  }
}

New-Item -ItemType Directory -Force -Path $releaseRoot | Out-Null

Copy-Item -Force "build\app\outputs\flutter-apk\app-release.apk" `
  (Join-Path $releaseRoot "BridgeClip-Android-release.apk")
Copy-Item -Force "build\app\outputs\bundle\release\app-release.aab" `
  (Join-Path $releaseRoot "BridgeClip-Android-release.aab")

if (Test-Path $windowsStage) {
  Remove-Item -Recurse -Force $windowsStage
}
Copy-Item -Recurse -Force "build\windows\x64\runner\Release" $windowsStage

if (Test-Path $windowsZip) {
  Remove-Item -Force $windowsZip
}
Compress-Archive -Path (Join-Path $windowsStage "*") -DestinationPath $windowsZip -Force

Copy-Item -Force "RELEASE_NOTES.md" (Join-Path $releaseRoot "RELEASE_NOTES.md")
Copy-Item -Force "RELEASE_AUDIT.md" (Join-Path $releaseRoot "RELEASE_AUDIT.md")

Update-PackagedReleasePaths -Path (Join-Path $releaseRoot "RELEASE_NOTES.md") -ReleaseId $ReleaseId
Update-PackagedReleasePaths -Path (Join-Path $releaseRoot "RELEASE_AUDIT.md") -ReleaseId $ReleaseId

$hashFiles = @(
  "BridgeClip-Android-release.apk",
  "BridgeClip-Android-release.aab",
  "BridgeClip-Windows-release.zip",
  "RELEASE_NOTES.md",
  "RELEASE_AUDIT.md"
)

$hashLines = foreach ($file in $hashFiles) {
  $path = Join-Path $releaseRoot $file
  $hash = (Get-FileHash $path -Algorithm SHA256).Hash
  $length = (Get-Item $path).Length
  "$hash  $length  $file"
}

Set-Content -Encoding UTF8 -Path (Join-Path $releaseRoot "SHA256SUMS.txt") -Value $hashLines

$hashOk = $true
foreach ($line in Get-Content -Encoding UTF8 (Join-Path $releaseRoot "SHA256SUMS.txt")) {
  $parts = $line -split "\s+", 3
  $path = Join-Path $releaseRoot $parts[2]
  $actualHash = (Get-FileHash $path -Algorithm SHA256).Hash
  $actualLength = (Get-Item $path).Length
  if ($actualHash -ne $parts[0] -or $actualLength -ne [int64]$parts[1]) {
    $hashOk = $false
    Write-Error "Hash or size mismatch for $($parts[2])"
  }
}

if (-not (Test-Path (Join-Path $windowsStage "clipboard_sync.exe"))) {
  throw "Windows release is missing clipboard_sync.exe"
}

Write-Host "Release packaged: $releaseRoot"
Write-Host "SHA-256 verification: $hashOk"

if (-not $SkipVerify) {
  $verifyScript = Join-Path $PSScriptRoot "verify_release.ps1"
  $verifyArgs = @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    $verifyScript,
    "-ReleasePath",
    $releaseRoot
  )

  if ($RequireStoreSigning) {
    $verifyArgs += "-RequireStoreSigning"
  }

  & powershell @verifyArgs
  if ($LASTEXITCODE -ne 0) {
    if ((-not $releaseExistedBefore) -and (-not $KeepFailedPackage) -and (Test-Path $releaseRoot)) {
      $resolvedReleaseRoot = (Resolve-Path $releaseRoot).Path
      $resolvedReleaseParent = (Resolve-Path (Join-Path $repoRoot "release")).Path
      $releaseParentPrefix = $resolvedReleaseParent + [System.IO.Path]::DirectorySeparatorChar

      if ($resolvedReleaseRoot.StartsWith($releaseParentPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -Recurse -Force -LiteralPath $resolvedReleaseRoot
        Write-Host "Removed failed release package: $resolvedReleaseRoot"
      } else {
        Write-Warning "Skipped failed release cleanup because the path is outside the release folder: $resolvedReleaseRoot"
      }
    }

    throw "Release verification failed after packaging."
  }
}
