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
$releaseIndexPath = Join-Path $repoRoot "release\LATEST.txt"
$windowsStage = Join-Path $releaseRoot "BridgeClip-Windows-release"
$windowsZip = Join-Path $releaseRoot "BridgeClip-Windows-release.zip"
$releaseExistedBefore = Test-Path $releaseRoot
$latestExistedBefore = Test-Path $releaseIndexPath
$previousLatestLines = @()
if ($latestExistedBefore) {
  $previousLatestLines = Get-Content -Encoding UTF8 $releaseIndexPath
}

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

function Find-Apksigner {
  $androidSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
  Get-ChildItem $androidSdk -Recurse -Filter "apksigner.bat" -ErrorAction SilentlyContinue |
    Sort-Object FullName |
    Select-Object -Last 1
}

function Find-Jarsigner {
  $pathJarsigner = Get-Command "jarsigner.exe" -ErrorAction SilentlyContinue
  if ($null -ne $pathJarsigner) {
    return $pathJarsigner.Source
  }

  if ($env:JAVA_HOME) {
    $javaHomeJarsigner = Join-Path $env:JAVA_HOME "bin\jarsigner.exe"
    if (Test-Path $javaHomeJarsigner) {
      return $javaHomeJarsigner
    }
  }

  $knownJarsigners = @(
    "C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe",
    "C:\Program Files\Java\jdk-17\bin\jarsigner.exe",
    "C:\Program Files\Java\jdk-21\bin\jarsigner.exe"
  )

  foreach ($candidate in $knownJarsigners) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  return $null
}

function Get-ApkSigningInfo {
  param([string]$ApkPath)

  $apksigner = Find-Apksigner
  if ($null -eq $apksigner) {
    return [ordered]@{
      checked = $false
      debugCertificate = $null
      certificate = $null
      error = "apksigner.bat not found"
    }
  }

  $output = & $apksigner.FullName verify --verbose --print-certs $ApkPath 2>&1
  if ($LASTEXITCODE -ne 0) {
    return [ordered]@{
      checked = $false
      debugCertificate = $null
      certificate = $null
      error = "APK signature verification failed"
    }
  }

  $signerLine = $output | Where-Object { $_ -like "*certificate DN:*" } | Select-Object -First 1
  return [ordered]@{
    checked = $true
    debugCertificate = ($signerLine -like "*Android Debug*")
    certificate = "$signerLine"
    error = $null
  }
}

function Get-AabSigningInfo {
  param([string]$AabPath)

  $jarsigner = Find-Jarsigner
  if ($null -eq $jarsigner) {
    return [ordered]@{
      checked = $false
      debugCertificate = $null
      certificate = $null
      error = "jarsigner.exe not found"
    }
  }

  $output = & $jarsigner -verify -verbose -certs $AabPath 2>&1
  $outputText = $output -join "`n"
  if ($outputText -notmatch "jar verified\.") {
    return [ordered]@{
      checked = $false
      debugCertificate = $null
      certificate = $null
      error = "Android App Bundle signature verification failed"
    }
  }

  $signerLine = $output | Where-Object { $_ -like "*Signed by*" } | Select-Object -Last 1
  return [ordered]@{
    checked = $true
    debugCertificate = ($outputText -like "*CN=Android Debug*")
    certificate = "$signerLine"
    error = $null
  }
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

$manifestArtifacts = foreach ($file in $hashFiles) {
  $path = Join-Path $releaseRoot $file
  [ordered]@{
    file = $file
    sha256 = (Get-FileHash $path -Algorithm SHA256).Hash
    size = (Get-Item $path).Length
  }
}

$gitCommit = $null
try {
  $gitCommit = (& git rev-parse HEAD 2>$null).Trim()
} catch {
  $gitCommit = $null
}

$apkSigning = Get-ApkSigningInfo -ApkPath (Join-Path $releaseRoot "BridgeClip-Android-release.apk")
$aabSigning = Get-AabSigningInfo -AabPath (Join-Path $releaseRoot "BridgeClip-Android-release.aab")
$storeReady = (
  $apkSigning.checked -eq $true -and
  $aabSigning.checked -eq $true -and
  $apkSigning.debugCertificate -eq $false -and
  $aabSigning.debugCertificate -eq $false
)

$manifest = [ordered]@{
  name = "BridgeClip"
  releaseId = $ReleaseId
  releasePath = "release\BridgeClip-$ReleaseId"
  generatedAtUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  gitCommit = $gitCommit
  androidSigning = [ordered]@{
    apk = $apkSigning
    appBundle = $aabSigning
    storeReady = $storeReady
  }
  artifacts = $manifestArtifacts
}

$manifestPath = Join-Path $releaseRoot "RELEASE_MANIFEST.json"
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -Path $manifestPath

$hashFiles += "RELEASE_MANIFEST.json"

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

$latestLines = @(
  "BridgeClip latest release",
  "ReleaseId: $ReleaseId",
  "Path: release\BridgeClip-$ReleaseId",
  "Windows: release\BridgeClip-$ReleaseId\BridgeClip-Windows-release.zip",
  "Android APK: release\BridgeClip-$ReleaseId\BridgeClip-Android-release.apk",
  "Android App Bundle: release\BridgeClip-$ReleaseId\BridgeClip-Android-release.aab",
  "SHA-256: release\BridgeClip-$ReleaseId\SHA256SUMS.txt"
)

Set-Content -Encoding UTF8 -Path $releaseIndexPath -Value $latestLines

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
    if ($latestExistedBefore) {
      Set-Content -Encoding UTF8 -Path $releaseIndexPath -Value $previousLatestLines
      Write-Host "Restored previous latest release index: $releaseIndexPath"
    } elseif (Test-Path $releaseIndexPath) {
      Remove-Item -Force -LiteralPath $releaseIndexPath
      Write-Host "Removed failed latest release index: $releaseIndexPath"
    }

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

Write-Host "Latest release index updated: $releaseIndexPath"
