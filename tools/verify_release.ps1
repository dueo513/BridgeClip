param(
  [Parameter(Mandatory = $true)]
  [string]$ReleasePath,
  [switch]$RequireStoreSigning
)

$ErrorActionPreference = "Stop"

$releaseRoot = Resolve-Path $ReleasePath
$requiredFiles = @(
  "BridgeClip-Android-release.apk",
  "BridgeClip-Android-release.aab",
  "BridgeClip-Windows-release.zip",
  "BridgeClip-Windows-release\clipboard_sync.exe",
  "RELEASE_NOTES.md",
  "RELEASE_AUDIT.md",
  "SHA256SUMS.txt"
)

$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

foreach ($file in $requiredFiles) {
  $path = Join-Path $releaseRoot $file
  if (-not (Test-Path $path)) {
    $failures.Add("Missing required file: $file")
  }
}

if ($failures.Count -eq 0) {
  foreach ($line in Get-Content -Encoding UTF8 (Join-Path $releaseRoot "SHA256SUMS.txt")) {
    if (-not $line.Trim()) { continue }
    $parts = $line -split "\s+", 3
    if ($parts.Count -ne 3) {
      $failures.Add("Invalid SHA256SUMS line: $line")
      continue
    }

    $path = Join-Path $releaseRoot $parts[2]
    if (-not (Test-Path $path)) {
      $failures.Add("SHA256SUMS references missing file: $($parts[2])")
      continue
    }

    $actualHash = (Get-FileHash $path -Algorithm SHA256).Hash
    $actualLength = (Get-Item $path).Length
    if ($actualHash -ne $parts[0] -or $actualLength -ne [int64]$parts[1]) {
      $failures.Add("Hash or size mismatch: $($parts[2])")
    }
  }
}

if ($failures.Count -eq 0) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [System.IO.Compression.ZipFile]::OpenRead((Join-Path $releaseRoot "BridgeClip-Windows-release.zip"))
  try {
    $zipNames = $zip.Entries | ForEach-Object { $_.FullName }
    foreach ($entry in @("clipboard_sync.exe", "flutter_windows.dll")) {
      if ($zipNames -notcontains $entry) {
        $failures.Add("Windows zip missing entry: $entry")
      }
    }
  } finally {
    $zip.Dispose()
  }
}

if ($failures.Count -eq 0) {
  $androidSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
  $apksigner = Get-ChildItem $androidSdk -Recurse -Filter "apksigner.bat" -ErrorAction SilentlyContinue |
    Sort-Object FullName |
    Select-Object -Last 1

  if ($null -eq $apksigner) {
    $message = "apksigner.bat not found; APK signer certificate was not checked."
    if ($RequireStoreSigning) {
      $failures.Add($message)
    } else {
      $warnings.Add($message)
    }
  } else {
    $apkPath = Join-Path $releaseRoot "BridgeClip-Android-release.apk"
    $apkSignOutput = & $apksigner.FullName verify --verbose --print-certs $apkPath 2>&1
    if ($LASTEXITCODE -ne 0) {
      $failures.Add("APK signature verification failed.")
    } else {
      $signerLine = $apkSignOutput | Where-Object { $_ -like "*certificate DN:*" } | Select-Object -First 1
      if ($signerLine -like "*Android Debug*") {
        $message = "APK is signed with Android Debug certificate. Use android/key.properties for store submission."
        if ($RequireStoreSigning) {
          $failures.Add($message)
        } else {
          $warnings.Add($message)
        }
      }
    }
  }
}

if ($failures.Count -gt 0) {
  Write-Host "Release verification failed:"
  foreach ($failure in $failures) {
    Write-Host "- $failure"
  }
  exit 1
}

Write-Host "Release verification passed: $releaseRoot"
if ($warnings.Count -gt 0) {
  Write-Host "Warnings:"
  foreach ($warning in $warnings) {
    Write-Host "- $warning"
  }
}
