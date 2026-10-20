#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "flutter/standard_method_codec.h"

namespace {

// System-wide unique window message used by a second instance to ask the
// running instance to show its main panel.
UINT GetShowMainWindowMessage() {
  static const UINT msg =
      RegisterWindowMessage(L"BiliAudio.ShowMainWindow");
  return msg;
}

// Property name matching the one used by the single-instance guard in
// main.cpp. It marks this top-level window as the app's main instance.
constexpr const wchar_t kInstanceProp[] = L"BiliAudioInstance";

}  // namespace

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
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Tag this window so a second instance can find it, and create the method
  // channel used to forward "show main panel" requests to the Dart side.
  ::SetProp(GetHandle(), kInstanceProp, reinterpret_cast<HANDLE>(1));
  method_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "bili_audio/single_instance",
          &flutter::StandardMethodCodec::GetInstance());

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

  // Single-instance activation: a second instance asked us to show the main
  // panel. Forward the request to the Dart side via the method channel.
  if (message == GetShowMainWindowMessage()) {
    if (method_channel_) {
      method_channel_->InvokeMethod(
          "showMainWindow",
          std::make_unique<flutter::EncodableValue>());
    }
    return 0;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
