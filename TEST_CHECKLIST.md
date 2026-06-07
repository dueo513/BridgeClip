# BridgeClip Test Checklist

Use this checklist before sharing a build.

## Automated Checks

- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `npm --prefix functions run lint`
- [ ] `flutter build windows`
- [ ] `flutter build apk --release`
- [ ] `firebase deploy --only firestore:rules,functions`

## Windows Smoke Test

- [ ] App launches without crash.
- [ ] Stored Room ID and password restore correctly.
- [ ] Tray menu opens the app.
- [ ] Tray exit closes the app.
- [ ] Launch-at-startup setting can be read.
- [ ] Clipboard copy uploads to Firestore.
- [ ] Remote clipboard item writes to local Windows clipboard.
- [ ] Remote item does not echo-upload back as a Windows duplicate.
- [ ] Archive view opens.
- [ ] Device management view opens.
- [ ] App lock can be enabled and unlocked.

## Android Emulator Smoke Test

- [ ] APK installs.
- [ ] App launches without crash.
- [ ] Stored Room ID and password restore correctly.
- [ ] Quick Sync activity starts.
- [ ] Quick Sync uploads the current Android clipboard.
- [ ] No fatal `AndroidRuntime` crash appears in logcat.

Emulator note: clipboard sharing can mirror Android clipboard text into the
Windows host clipboard. Treat emulator sync results as a smoke test only.

## Real Android Phone QA

- [ ] APK installs on physical phone.
- [ ] Phone joins the same Room ID with the same password.
- [ ] Windows copy creates a phone notification.
- [ ] Notification `Copy` action copies the decrypted text.
- [ ] Notification `Select copy` action opens the selection flow.
- [ ] Quick Settings tile is available.
- [ ] Quick Settings tile uploads phone clipboard to Windows.
- [ ] Phone reboot preserves Room ID, password, and device ID.
- [ ] App relaunch re-registers the same device.
- [ ] Notification off disables pushes to that phone.
- [ ] Notification on re-enables pushes.
- [ ] Device rename is reflected in new clipboard items.
- [ ] Device removal deletes the registry document.
- [ ] Removed device re-registers when the app opens again.

## Cross-Device QA

- [ ] Windows and Android have different `deviceId` values.
- [ ] Same password decrypts the same room on both devices.
- [ ] Wrong password shows unreadable/decryption-failed content.
- [ ] Isolated Android emulator upload records `platform=android`.
- [ ] Host Windows upload records `platform=windows`.
- [ ] Android to Windows sync does not create a Windows duplicate.
- [ ] Windows to Android sync does not create an Android duplicate.
- [ ] Auto-delete removes non-pinned items after the configured delay.
- [ ] Pinned/archive items remain available.

## Release Package QA

- [ ] Windows zip extracts cleanly.
- [ ] Windows executable runs from the extracted folder.
- [ ] Android APK filename matches the release note.
- [ ] README artifact paths match the produced files.
- [ ] Release notes include current validation results.
