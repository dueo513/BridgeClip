# BridgeClip Physical Phone QA Checklist

Use this checklist before treating a build as a final public release. Emulator and Windows smoke tests are already covered by the release scripts; this file is for the parts that need a real Android phone.

## Build Under Test

- Release folder: `release/BridgeClip-20260608-0426`
- Android APK: `release/BridgeClip-20260608-0426/BridgeClip-Android-release.apk`
- Windows ZIP: `release/BridgeClip-20260608-0426/BridgeClip-Windows-release.zip`

## Android Install

- Install the APK on a physical Android phone.
- Open the app and confirm the new BridgeClip icon appears on the phone launcher.
- Confirm the app opens without a Firebase Auth error.
- Confirm Korean and English language switching works from settings.

## Room Connection

- Create or join the same room on Windows and Android.
- Confirm the room id stays saved after closing and reopening the app.
- Confirm the room id stays saved after rebooting the phone.
- Confirm the room password is required only for local encryption/decryption and is not shown in Firestore.

## Clipboard Sync

- Copy text on Windows and confirm it appears on Android.
- Use the Android Quick Settings tile/manual sync path and confirm copied phone text appears on Windows.
- Copy received text on Android and confirm it does not upload back as an echo duplicate.
- Copy received text on Windows and confirm it does not upload back as an echo duplicate.
- Confirm archive and pinned items are preserved as expected.

## Android Notifications

- Copy text on Windows and confirm exactly one Android notification appears.
- Tap the notification copy action and confirm the received text is copied.
- Tap the select-copy action and confirm the app opens to the expected copy flow.
- Turn Android notifications off for this device in settings and confirm Windows copies no longer trigger push notifications.
- Turn Android notifications back on and confirm push notifications resume.

## Device Management

- Open settings and confirm both Windows and Android are listed as connected devices.
- Rename the Android device and confirm new clipboard items show the new device name.
- Remove another device and confirm it disappears from the list.
- Remove the current Android device and confirm local room/device state is cleared.

## App Lock And Persistence

- Enable app lock and confirm unlocking works.
- Confirm background sync/manual sync behavior remains usable with app lock enabled.
- Reboot the phone and confirm saved room, device identity, and app lock state remain consistent.

## Release Sign-Off

- Run `tools/run_release_checks.ps1` after any code or asset change.
- Run `tools/smoke_release_apps.ps1 -RequireAndroidDevice` with an emulator or connected device.
- For Play Store submission, create an upload keystore and repackage with store signing before using the AAB.
