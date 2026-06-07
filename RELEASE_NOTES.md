# BridgeClip Release Notes

## 2026-06-07 Host + Emulator Final Build

Artifacts:

- Windows: `C:\Users\shrud\.gemini\antigravity\scratch\bridgeclip_release_2026-06-05\BridgeClip-Windows-2026-06-07-host-emulator-final.zip`
- Android: `C:\Users\shrud\.gemini\antigravity\scratch\bridgeclip_release_2026-06-05\BridgeClip-Android-2026-06-07-host-emulator-final.apk`

### Added

- Device management screen.
- Stable device ID registration.
- Device rename.
- Per-device notification toggle.
- Device removal from the registry.
- Generated Room ID and QR invite flow.
- Light and dark theme support.
- PIN app lock.
- Windows native clipboard sequence guard for echo upload prevention.
- Content hash based idempotency fallback for short network races.

### Changed

- Android Quick Sync waits for pending Firestore writes before closing the app.
- Firebase token documents now use `tokens/{deviceId}` as the primary registry.
- Clipboard items include optional `deviceId` and `contentHash`.
- Windows uses Firestore/Auth REST calls for stability.
- Client-side service account usage is removed.
- Firebase Functions send FCM pushes without decrypting clipboard content.
- Korean and English copy has been cleaned up.

### Verified

- `flutter analyze`: passed.
- `flutter test`: passed, 9 tests.
- `npm --prefix functions run lint`: passed.
- `flutter build windows`: passed.
- `flutter build apk --release`: passed.
- `firebase deploy --only firestore:rules,functions`: passed.
- Android APK install on emulator: passed.
- Android app launch smoke test: passed.
- Windows app launch smoke test: passed.
- Isolated Android emulator Quick Sync to Firestore: passed.
- Host Windows clipboard upload to Firestore: passed.
- Encrypted Firestore payloads decrypted with the room password and matched the tested text.
- Echo duplicate check: passed in prior guard validation, one Firestore document for the tested text.

### Still Needs Real Phone QA

- Windows-to-physical-Android notification delivery.
- Android notification delivery on a physical phone.
- Android notification copy action.
- Android notification select-copy action.
- Android Quick Settings tile on a physical phone.
- Phone reboot and app relaunch persistence.

### Known Constraints

- Android emulator clipboard sharing can mirror clipboard text into the Windows
  host clipboard. Use a real phone for final cross-device clipboard QA.
- Account recovery is not available because this build uses Room ID and
  password pairing instead of email login.
- macOS and iOS are planned for a later phase.
