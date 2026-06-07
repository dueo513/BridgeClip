# BridgeClip Release Audit

## Scope

Goal: optimize code without removing or changing intended app features, then produce release app artifacts.

Release folder:

- `release\BridgeClip-20260608-0240`

## Release Artifacts

- Windows zip: `BridgeClip-Windows-release.zip`
- Windows unpacked app: `BridgeClip-Windows-release\clipboard_sync.exe`
- Android APK: `BridgeClip-Android-release.apk`
- Android App Bundle: `BridgeClip-Android-release.aab`
- Release notes: `RELEASE_NOTES.md`

## Verified Evidence

- Working tree is clean after release packaging.
- `flutter analyze` passed.
- `flutter test` passed with 12 tests.
- `npm.cmd --prefix functions run lint` passed.
- `flutter build apk --release` passed.
- `flutter build appbundle --release` passed.
- `flutter build windows` passed.
- Firebase deploy passed for `firestore:rules,functions` on project `shrud-clip-2026-78fee`.
- Android release APK installed on emulator.
- Android release APK launched on emulator and showed the main BridgeClip screen.
- Android launcher icon was visually checked on emulator.
- Windows release zip contains `clipboard_sync.exe` and `flutter_windows.dll`.
- Windows release `clipboard_sync.exe` started successfully from the release folder and was stopped after the smoke check.
- `SHA256SUMS.txt` entries match the current release artifact hashes and file sizes.
- Service account files and `googleapis_auth` are not present in client dependencies or source; only README guidance mentions not shipping service-account credentials.
- Android release signing is configurable through `android/key.properties`; without that local file, Gradle falls back to the debug signing key for testable local release builds.

## Feature Preservation Evidence

- Clipboard sync, encryption, Firebase Auth/Firestore/Functions, device registry, notification toggles, room pairing, archive, pinning, search, automatic delete, app lock, Windows tray/startup, and Android quick actions remain documented in `RELEASE_NOTES.md`.
- Device ID and notification filtering remain present in `lib`, `functions`, and `firestore.rules`.
- Platform icon assets are prepared for Android, iOS, macOS, and Windows.

## Remaining Physical Device QA

These are not fully provable on the emulator/host setup and should be checked on a real Android phone before calling this a store-ready final release:

- Windows-to-physical-Android notification delivery.
- Android notification `copy` action.
- Android notification `select copy` action.
- Android Quick Settings tile.
- Phone reboot and app relaunch persistence.
- Android Play submission signing with a private upload/release keystore.

## Status

The current package is a release-ready candidate for local distribution and final physical phone QA. Store submission still needs physical-device validation and normal store metadata/signing review.
