param(
  [string]$ReleasePath,
  [switch]$SkipVerify,
  [switch]$SkipWindows,
  [switch]$SkipAndroid,
  [switch]$RequireAndroidDevice
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

function Resolve-ReleaseRoot {
  param([string]$Path)

  if (-not [string]::IsNullOrWhiteSpace($Path)) {
    return Resolve-Path $Path
  }

  $latestPath = Join-Path $repoRoot "release\LATEST.txt"
  if (Test-Path $latestPath) {
    $pathLine = Get-Content -Encoding UTF8 $latestPath |
      Where-Object { $_ -like "Path: release\BridgeClip-*" } |
      Select-Object -First 1
    if ($pathLine) {
      return Resolve-Path (Join-Path $repoRoot ($pathLine -replace "^Path: ", ""))
    }
  }

  $latestRelease = Get-ChildItem (Join-Path $repoRoot "release") -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^BridgeClip-\d{8}-\d{4}$' } |
    Sort-Object Name -Descending |
    Select-Object -First 1

  if ($null -eq $latestRelease) {
    throw "No release folder found. Pass -ReleasePath explicitly."
  }

  return $latestRelease.FullName
}

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

$releaseRoot = Resolve-ReleaseRoot -Path $ReleasePath

if (-not $SkipVerify) {
  $verifyScript = Join-Path $PSScriptRoot "verify_release.ps1"
  Invoke-Checked "Verify release package" {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $verifyScript -ReleasePath $releaseRoot
  }
}

if (-not $SkipWindows) {
  $windowsExe = Join-Path $releaseRoot "BridgeClip-Windows-release\clipboard_sync.exe"
  if (-not (Test-Path $windowsExe)) {
    throw "Windows release executable not found: $windowsExe"
  }

  Write-Host "==> Launch Windows release app"
  $process = Start-Process -FilePath $windowsExe `
    -WorkingDirectory (Split-Path $windowsExe) `
    -PassThru `
    -WindowStyle Hidden
  Start-Sleep -Seconds 4

  if ($process.HasExited) {
    throw "Windows release executable exited during smoke test."
  }

  $closed = $process.CloseMainWindow()
  Start-Sleep -Seconds 2
  if (-not $process.HasExited) {
    Stop-Process -Id $process.Id -Force
  }

  Write-Host "Windows release app launched successfully."
}

if (-not $SkipAndroid) {
  $adb = "C:\Users\shrud\AppData\Local\Android\Sdk\platform-tools\adb.exe"
  if (-not (Test-Path $adb)) {
    throw "adb.exe not found: $adb"
  }

  $devices = & $adb devices |
    Select-Object -Skip 1 |
    Where-Object { $_ -match "\sdevice$" }

  if ($devices.Count -eq 0) {
    if ($RequireAndroidDevice) {
      throw "No Android device or emulator is connected."
    }

    Write-Host "No Android device or emulator connected; skipping Android smoke test."
  } else {
    $apkPath = Join-Path $releaseRoot "BridgeClip-Android-release.apk"
    if (-not (Test-Path $apkPath)) {
      throw "Android release APK not found: $apkPath"
    }

    $packageId = "com.antigravity.clipboardsync.clipboard_sync"
    Invoke-Checked "Install Android release APK" {
      & $adb install -r $apkPath
    }

    Invoke-Checked "Launch Android release app" {
      & $adb shell monkey -p $packageId -c android.intent.category.LAUNCHER 1
    }

    Start-Sleep -Seconds 2
    $androidPid = & $adb shell pidof $packageId
    if ([string]::IsNullOrWhiteSpace($androidPid)) {
      throw "Android release app did not stay running after launch."
    }

    Write-Host "Android release app launched successfully."
  }
}

Write-Host "Release app smoke checks passed: $releaseRoot"
