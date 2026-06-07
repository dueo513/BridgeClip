# BridgeClip

BridgeClip is a Windows and Android clipboard sync app. It uses a shared Room ID
and password, keeps clipboard text end-to-end encrypted on each client, and
stores only encrypted payloads in Firebase.

The current release target is a Windows zip and an Android release APK. macOS
and iOS are planned as a later Apple platform phase.

## Current Status

- Primary platforms: Windows, Android
- Backend: Firebase Auth, Firestore, Cloud Functions, FCM
- Encryption: AES-256-GCM with a PBKDF2-derived key
- Latest validated artifacts:
  - `release\BridgeClip-20260608-0240\BridgeClip-Windows-release.zip`
  - `release\BridgeClip-20260608-0240\BridgeClip-Android-release.apk`
  - `release\BridgeClip-20260608-0240\BridgeClip-Android-release.aab`

## Features

- Windows to Android clipboard sync
- Android to Windows Quick Sync
- Room ID and password based pairing
- Generated Room ID format and QR invite flow
- End-to-end encrypted clipboard contents
- Firebase Functions based FCM push fan-out
- Device management screen
- Stable per-device `deviceId`
- Device rename
- Per-device notification on/off
- Device removal from the room registry
- Windows tray integration
- Windows launch-at-startup registration
- Android notification actions: copy and select copy
- Android Quick Settings tile
- Archive and pinned clipboard items
- Auto-delete for non-archived clipboard history
- PIN app lock
- Light and dark themes
- Korean and English localization
- Echo upload protection on Windows using the native clipboard sequence number

## Install

### Windows

1. Extract the Windows zip.
2. Run `clipboard_sync.exe`.
3. Allow the app to stay in the tray.
4. Use the same Room ID and password as the Android app.

### Android

1. Install the release APK.
2. Open BridgeClip.
3. Join the same Room ID with the same password.
4. Add the Quick Settings tile if you want one-tap mobile-to-PC sync.

Android may ask for notification permission. Enable it if you want clipboard
receive notifications and notification actions.

## Pairing

BridgeClip does not use account login. A Room ID identifies the shared clipboard
space, and the room password derives the encryption key.

- Keep the Room ID if you want to reconnect later.
- Keep the password private. The password is never uploaded to Firebase.
- QR invite links fill the Room ID, but users still need the password.

## Usage

### Windows to Android

1. Keep BridgeClip running on Windows.
2. Copy text on Windows.
3. The encrypted item is uploaded to Firestore.
4. Android receives an FCM notification.
5. Use the notification copy action, select-copy action, or open the app.

### Android to Windows

1. Copy text on Android.
2. Tap the BridgeClip Quick Settings tile.
3. Windows receives the new clipboard item.
4. BridgeClip writes it to the local Windows clipboard.

## Security Model

The room password is used locally to derive the encryption key with PBKDF2. The
clipboard text is encrypted with AES-256-GCM before upload. Firestore stores the
encrypted `content` field, timestamps, device metadata, archive state, and a
key-scoped content hash used only for idempotency.

Firebase Functions read metadata and FCM tokens, but do not decrypt clipboard
content. Do not ship `service-account.json` or server credentials in any client
build.

## Firebase Layout

- Room registry: `rooms/{roomId}`
- Clipboard items: `users/{roomId}/clipboards/{clipId}`
- Device registry and FCM tokens: `users/{roomId}/tokens/{deviceId}`
- Function trigger: `onClipboardCreated`

Clipboard item fields:

- `content`
- `timestamp`
- `createdAtClient`
- `deviceName`
- `platform`
- `deviceId`
- `contentHash`
- `isPinned`

Device fields:

- `deviceName`
- `platform`
- `token`
- `notificationsEnabled`
- `updatedAt`
- `lastSeenAt`

## Known Constraints

- Android emulator clipboard sharing can mirror Android clipboard changes into
  the host Windows clipboard. That is a VM/emulator behavior, not the same as a
  real phone.
- Windows currently uses Firestore/Auth REST calls because the native Windows
  Firebase plugin path was unstable in this project.
- Room ID and password are user-managed. There is no email account recovery yet.
- macOS and iOS are not release targets for this phase.

## Build

Use the Flutter SDK used for this workspace:

```powershell
C:\Users\shrud\.gemini\antigravity\scratch\flutter\bin\flutter.bat pub get
C:\Users\shrud\.gemini\antigravity\scratch\flutter\bin\flutter.bat analyze
C:\Users\shrud\.gemini\antigravity\scratch\flutter\bin\flutter.bat test
C:\Users\shrud\.gemini\antigravity\scratch\flutter\bin\flutter.bat build windows
C:\Users\shrud\.gemini\antigravity\scratch\flutter\bin\flutter.bat build apk --release
C:\Users\shrud\.gemini\antigravity\scratch\flutter\bin\flutter.bat build appbundle --release
```

Deploy Firebase support separately:

```powershell
firebase deploy --only firestore:rules,functions
```

## Android Release Signing

Local release builds fall back to the Android debug certificate when
`android\key.properties` is missing. That is useful for QA, but not for Play
submission.

Check that the local machine can create an upload keystore:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\create_android_upload_keystore.ps1 -DryRun
```

Create the ignored upload keystore and signing config:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\create_android_upload_keystore.ps1
```

The command creates `android\app\upload-keystore.jks` and
`android\key.properties`. Both are ignored by git. Back up the keystore and
passwords securely; losing them can block future app updates.

After creating the keystore, rebuild and verify the release package:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\package_release.ps1 -Build
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_release.ps1
```

## Release Checklist

Before sharing a build:

- Run `flutter analyze`.
- Run `flutter test`.
- Run `npm --prefix functions run lint`.
- For store submission, create `android\key.properties` with
  `tools\create_android_upload_keystore.ps1`.
- Build Windows release.
- Build Android release APK.
- Build Android release App Bundle.
- Package artifacts with `tools\package_release.ps1`.
- Verify packaged artifacts with `tools\verify_release.ps1`.
- Install and launch the APK.
- Launch the Windows app.
- Verify host Windows clipboard upload.
- Verify isolated Android emulator Quick Sync upload.
- Verify no echo upload duplicate is created.
- Verify notification actions on a real Android phone.
- Verify the Quick Settings tile on a real Android phone.

## Apple Platform Notes

The data model, encryption service, localization, and Firebase backend keep
platform values open for `windows`, `android`, `macos`, and `ios`.

macOS should use the desktop sync model with macOS-specific tray and auto-start
implementation. iOS should prefer foreground, notification, app-open, share
sheet, and manual sync flows because background clipboard access is restricted.
