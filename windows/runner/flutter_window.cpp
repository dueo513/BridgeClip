#include "flutter_window.h"

#include <optional>
#include <windows.h>

#include <app_links/app_links_plugin_c_api.h>
#include <clipboard_watcher/clipboard_watcher_plugin.h>
#include <flutter/standard_method_codec.h>
#include <firebase_core/firebase_core_plugin_c_api.h>
#include <screen_retriever_windows/screen_retriever_windows_plugin_c_api.h>
#include <tray_manager/tray_manager_plugin.h>
#include <window_manager/window_manager_plugin.h>

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  // cloud_firestore/firebase_auth currently crash during Windows native plugin
  // startup in this app; Windows uses Firestore/Auth REST calls instead.
  AppLinksPluginCApiRegisterWithRegistrar(
      flutter_controller_->engine()->GetRegistrarForPlugin("AppLinksPluginCApi"));
  ClipboardWatcherPluginRegisterWithRegistrar(
      flutter_controller_->engine()->GetRegistrarForPlugin("ClipboardWatcherPlugin"));
  FirebaseCorePluginCApiRegisterWithRegistrar(
      flutter_controller_->engine()->GetRegistrarForPlugin("FirebaseCorePluginCApi"));
  ScreenRetrieverWindowsPluginCApiRegisterWithRegistrar(
      flutter_controller_->engine()->GetRegistrarForPlugin("ScreenRetrieverWindowsPluginCApi"));
  TrayManagerPluginRegisterWithRegistrar(
      flutter_controller_->engine()->GetRegistrarForPlugin("TrayManagerPlugin"));
  WindowManagerPluginRegisterWithRegistrar(
      flutter_controller_->engine()->GetRegistrarForPlugin("WindowManagerPlugin"));
  clipboard_guard_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.antigravity/clipboard_guard",
          &flutter::StandardMethodCodec::GetInstance());
  clipboard_guard_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "getClipboardSequenceNumber") {
          result->Success(flutter::EncodableValue(
              static_cast<int64_t>(::GetClipboardSequenceNumber())));
          return;
        }
        result->NotImplemented();
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    clipboard_guard_channel_ = nullptr;
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
