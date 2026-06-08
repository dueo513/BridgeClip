# BridgeClip Apple Platform Build Notes

BridgeClip has iOS and macOS targets prepared in the Flutter project. Final Apple builds must be created on macOS with Xcode installed.

## What Is Ready

- Platform values are preserved as `ios` and `macos`.
- iOS uses manual clipboard sending from Settings because iOS does not allow continuous background clipboard monitoring.
- macOS uses the desktop sync path and can watch the clipboard like Windows.
- iOS/macOS app display name is `BridgeClip`.
- URL schemes are registered for `bridgeclip://`, `appclip://`, and `copysync://`.
- macOS sandbox network client entitlement is enabled for Firebase/Firestore access.
- Firebase Functions send APNs notification payloads for iOS FCM tokens while keeping Android data-only behavior.

## Required Apple Setup

1. Open the project on a Mac.
2. Run `flutter pub get`.
3. Open `ios/Runner.xcworkspace` in Xcode.
4. Set the Apple development team for the iOS Runner target.
5. Confirm the iOS bundle id:
   - `com.antigravity.clipboardsync.clipboardSync`
6. Enable push notification capability if iOS push is required.
7. Upload or configure the APNs key/certificate in Firebase Cloud Messaging.
8. Open `macos/Runner.xcworkspace` in Xcode.
9. Set the Apple development team for the macOS Runner target.

## Build Commands On Mac

```bash
flutter clean
flutter pub get
flutter build ios --release
flutter build macos --release
```

For an installable iOS archive, use Xcode Archive from `ios/Runner.xcworkspace`.

## Manual QA

- iOS: join a room, receive a Windows/macOS clipboard notification, tap it, and confirm the decrypted clip is copied or visible in the app.
- iOS: copy text in another app, open BridgeClip, use Settings > Send current clipboard, and confirm it appears on Windows/macOS.
- iOS: reboot the phone and confirm room/device identity remains saved.
- macOS: join the same room, copy text, and confirm it appears on Windows/Android/iOS.
- macOS: copy text from another device and confirm it lands in the local clipboard without echo-upload loops.

## Known Apple Constraints

- iOS cannot continuously monitor clipboard changes in the background.
- iOS sync is designed around notifications, opening the app, and manual clipboard sending.
- macOS auto-start is intentionally not exposed yet; it should be implemented with a macOS-specific login item flow later.
