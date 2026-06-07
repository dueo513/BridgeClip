param(
  [string]$Alias = "upload",
  [string]$KeystorePath = "android\app\upload-keystore.jks",
  [int]$ValidityDays = 10000,
  [string]$DName = "CN=BridgeClip, OU=BridgeClip, O=BridgeClip, L=Seoul, S=Seoul, C=KR",
  [switch]$Force,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

function Find-Keytool {
  $pathKeytool = Get-Command "keytool.exe" -ErrorAction SilentlyContinue
  if ($null -ne $pathKeytool) {
    return $pathKeytool.Source
  }

  if ($env:JAVA_HOME) {
    $javaHomeKeytool = Join-Path $env:JAVA_HOME "bin\keytool.exe"
    if (Test-Path $javaHomeKeytool) {
      return $javaHomeKeytool
    }
  }

  $javaCommand = Get-Command "java.exe" -ErrorAction SilentlyContinue
  if ($null -ne $javaCommand) {
    $javaSiblingKeytool = Join-Path (Split-Path $javaCommand.Source) "keytool.exe"
    if (Test-Path $javaSiblingKeytool) {
      return $javaSiblingKeytool
    }
  }

  $knownKeytools = @(
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
    "C:\Program Files\Java\jdk-17\bin\keytool.exe",
    "C:\Program Files\Java\jdk-21\bin\keytool.exe"
  )

  foreach ($candidate in $knownKeytools) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  throw "keytool.exe was not found. Install a JDK or set JAVA_HOME."
}

function ConvertTo-PlainText {
  param([securestring]$SecureValue)

  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
  try {
    [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
  }
}

$keytool = Find-Keytool
$keystoreFullPath = Join-Path $repoRoot $KeystorePath
$keyPropertiesPath = Join-Path $repoRoot "android\key.properties"

if ($DryRun) {
  Write-Host "keytool: $keytool"
  Write-Host "keystore: $keystoreFullPath"
  Write-Host "key.properties: $keyPropertiesPath"
  Write-Host "alias: $Alias"
  Write-Host "validity days: $ValidityDays"
  exit 0
}

if ((Test-Path $keystoreFullPath) -and -not $Force) {
  throw "Keystore already exists: $keystoreFullPath. Use -Force to overwrite."
}

if ((Test-Path $keyPropertiesPath) -and -not $Force) {
  throw "android\key.properties already exists. Use -Force to overwrite."
}

New-Item -ItemType Directory -Force -Path (Split-Path $keystoreFullPath) | Out-Null

$storePasswordSecure = Read-Host "Keystore password" -AsSecureString
$keyPasswordSecure = Read-Host "Key password (press Enter to reuse keystore password)" -AsSecureString

$storePassword = ConvertTo-PlainText $storePasswordSecure
$keyPassword = ConvertTo-PlainText $keyPasswordSecure
if ([string]::IsNullOrWhiteSpace($keyPassword)) {
  $keyPassword = $storePassword
}

try {
  & $keytool `
    -genkeypair `
    -v `
    -keystore $keystoreFullPath `
    -storetype JKS `
    -keyalg RSA `
    -keysize 2048 `
    -validity $ValidityDays `
    -alias $Alias `
    -storepass $storePassword `
    -keypass $keyPassword `
    -dname $DName

  if ($LASTEXITCODE -ne 0) {
    throw "keytool failed with exit code $LASTEXITCODE"
  }

  $relativeStoreFile = $KeystorePath -replace '^android\\', ''
  $properties = @(
    "storePassword=$storePassword",
    "keyPassword=$keyPassword",
    "keyAlias=$Alias",
    "storeFile=$relativeStoreFile"
  )
  Set-Content -Encoding UTF8 -Path $keyPropertiesPath -Value $properties

  Write-Host "Created keystore: $keystoreFullPath"
  Write-Host "Created signing config: $keyPropertiesPath"
  Write-Host "Both files are ignored by git. Keep a secure backup of the keystore and passwords."
} finally {
  $storePassword = $null
  $keyPassword = $null
}
