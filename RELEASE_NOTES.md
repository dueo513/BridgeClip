# BridgeClip Release Notes

## 2026-06-08 Optimization + Release Candidate

Artifacts:

- Windows: `release\BridgeClip-20260608-0240\BridgeClip-Windows-release.zip`
- Android APK: `release\BridgeClip-20260608-0240\BridgeClip-Android-release.apk`
- Android App Bundle: `release\BridgeClip-20260608-0240\BridgeClip-Android-release.aab`

### Included

- Windows and Android clipboard sync with Room ID and password pairing.
- AES-256-GCM/PBKDF2 end-to-end encrypted clipboard payloads.
- Firebase Auth, Firestore, and Functions based sync/push structure.
- Device registry with stable device ID, device rename, notification toggle, and device removal.
- Android Quick Sync, notification copy/select-copy actions, and Quick Settings support.
- Windows tray behavior, startup toggle, clipboard monitoring, and echo upload guard.
- Archive, pinning, search, automatic delete policy, app lock, and light/dark themes.
- Korean and English localization with Korean UI using `방` / `방 ID`.
- Final launcher icon assets applied for Android, iOS, macOS, and Windows, with platform theme variants prepared.
- Remote device removal now disconnects the removed device after its registry entry disappears.
- Windows app window appears in the taskbar; closing the window still hides/minimizes it to tray.
- Cleaner password hint copy.
- Clipboard row spacing improved between content and metadata.
- Search input keeps a stable focus node while filtering.

### Optimization Pass

- Shared login/onboarding language selector.
- Shared language choice sheet for login, onboarding, and settings.
- Shared room ID compaction helper.
- Extracted app drawer, select-copy dialog, rename-device dialog, and confirm-action dialog.
- Extracted Firestore REST field codec from `DatabaseService`.
- Reduced `lib/main.dart` from 1342 lines to 1101 lines in the latest pass.
- Reduced `lib/services/database_service.dart` from 663 lines to 630 lines.

### Verified

- `flutter analyze`: passed.
- `flutter test`: passed, 12 tests.
- `npm.cmd --prefix functions run lint`: passed.
- `flutter build apk --release`: passed.
- `flutter build appbundle --release`: passed.
- `flutter build windows`: passed.
- `firebase.cmd deploy --only firestore:rules,functions --project shrud-clip-2026-78fee`: passed.
- Android APK install on emulator: passed.
- Android app launch smoke test on emulator: passed.
- Android release APK launch smoke test on emulator: passed.
- Android launcher icon visual check on emulator: passed.
- Windows release executable smoke test: passed.
- Release artifact SHA-256 verification: passed.
- `tools\package_release.ps1` release packaging smoke test: passed.
- Login screen logo/password hint visual check on emulator: passed.
- Search field one-character input check on emulator: passed.
- Android release signing config supports `android/key.properties`; current local package uses debug-key fallback because no private release key is present.
- Firebase CLI available: `15.15.0`.
- Firebase project selected: `shrud-clip-2026-78fee`.

### Deploy Command

```powershell
firebase.cmd deploy --only firestore:rules,functions --project shrud-clip-2026-78fee
```

### Still Needs Real Phone QA

- Windows-to-physical-Android notification delivery.
- Android notification copy action on a physical phone.
- Android notification select-copy action on a physical phone.
- Android Quick Settings tile on a physical phone.
- Phone reboot and app relaunch persistence.
- Play submission signing with a private upload/release keystore.

### Known Constraints

- Android emulator clipboard sharing can mirror clipboard text into the Windows host clipboard. Use a real phone for final cross-device clipboard QA.
- Account recovery is not available because this build uses Room ID and password pairing instead of email login.
- macOS and iOS are planned for a later phase.
