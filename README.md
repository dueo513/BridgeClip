# BridgeClip 🌉 (Beta)

**BridgeClip** is a highly secure, cross-platform clipboard synchronization tool between Windows and Android devices. It bypasses conventional OS limitations to deliver instant, seamless background synchronization.

> ⚠️ **Notice**: This project is currently in the **Beta version**. Features and stability may evolve over time.

## 🚀 Key Features

* **Military-Grade Security (AES-256 E2EE):** All clipboard text is encrypted locally before being transmitted via Firebase. Not even the database administrator can decipher the content.
* **Instant Background Sync:**
  * **Android:** Intelligent background polling overcoming Android 10+ clipboard restrictions.
  * **Windows:** Seamlessly integrates into the Windows System Tray with auto-start on boot via the Windows Registry.
* **Smart UI & Localization:** 
  * Real-time Multi-language engine supporting **Korean** and **English** on the fly.
  * Separate UI management for instant 'Clipboard' data vs 'Archive' (Permanent Vault).
* **Auto-Destruction Timer:** Set timers (1m, 10m, 1h, 1d) to automatically purge clipboard history from the cloud.

## 🛠️ Tech Stack
* **Framework:** Flutter (Dart)
* **Backend Backend:** Firebase Firestore & Cloud Messaging (FCM)
* **Security:** encrypt (AES-256-CBC)
* **Native Integration:** `window_manager`, `tray_manager`, `launch_at_startup`, `flutter_local_notifications`

## ⚙️ Disclaimer / How to Use
Since this utilizes Firebase for backend syncing, the `lib/secrets.dart` containing API configurations has been deliberately excluded from this repository (`.gitignore`) to prevent credential leakage. 

If you fork or clone this repository, you must connect your own Firebase environment and supply your own API keys.
