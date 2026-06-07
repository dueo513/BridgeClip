# BridgeClip Release Notes

## 2026-06-08 Optimization + Release Candidate

Artifacts:

- Windows: `release\BridgeClip-20260608-0056\BridgeClip-Windows-release.zip`
- Android: `release\BridgeClip-20260608-0056\BridgeClip-Android-release.apk`

### Included

- Windows and Android clipboard sync with Room ID and password pairing.
- AES-256-GCM/PBKDF2 end-to-end encrypted clipboard payloads.
- Firebase Auth, Firestore, and Functions based sync/push structure.
- Device registry with stable device ID, device rename, notification toggle, and device removal.
- Android Quick Sync, notification copy/select-copy actions, and Quick Settings support.
- Windows tray behavior, startup toggle, clipboard monitoring, and echo upload guard.
- Archive, pinning, search, automatic delete policy, app lock, and light/dark themes.
- Korean and English localization with Korean UI using `방` / `방 ID`.
- Theme-aware app logo and Android launcher icon assets.

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
- `flutter build windows`: passed.
- Android APK install on emulator: passed.
- Android app launch smoke test on emulator: passed.
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

### Known Constraints

- Android emulator clipboard sharing can mirror clipboard text into the Windows host clipboard. Use a real phone for final cross-device clipboard QA.
- Account recovery is not available because this build uses Room ID and password pairing instead of email login.
- macOS and iOS are planned for a later phase.
