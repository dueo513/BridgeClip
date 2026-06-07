param(
  [string]$ReleaseId = (Get-Date -Format "yyyyMMdd-HHmm"),
  [switch]$Build
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$flutter = "C:\Users\shrud\.gemini\antigravity\scratch\flutter\bin\flutter.bat"
$releaseRoot = Join-Path $repoRoot "release\BridgeClip-$ReleaseId"
$windowsStage = Join-Path $releaseRoot "BridgeClip-Windows-release"
$windowsZip = Join-Path $releaseRoot "BridgeClip-Windows-release.zip"

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

$packagedNotesPath = Join-Path $releaseRoot "RELEASE_NOTES.md"
$packagedNotes = Get-Content -Encoding UTF8 $packagedNotesPath
$packagedNotes = $packagedNotes `
  -replace 'release\\BridgeClip-[^\\`]+\\BridgeClip-Windows-release\.zip',
    "release\BridgeClip-$ReleaseId\BridgeClip-Windows-release.zip" `
  -replace 'release\\BridgeClip-[^\\`]+\\BridgeClip-Android-release\.apk',
    "release\BridgeClip-$ReleaseId\BridgeClip-Android-release.apk" `
  -replace 'release\\BridgeClip-[^\\`]+\\BridgeClip-Android-release\.aab',
    "release\BridgeClip-$ReleaseId\BridgeClip-Android-release.aab"
Set-Content -Encoding UTF8 -Path $packagedNotesPath -Value $packagedNotes

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
