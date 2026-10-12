#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Unique property placed on the running instance's top-level window so that a
// second instance can locate it. The window title may be changed at runtime by
// window_manager, so a property is more reliable than FindWindow by title.
constexpr const wchar_t kInstanceProp[] = L"TalixCompanionInstance";

// Single-instance named mutex. The "Global\\" prefix makes it visible across
// all sessions on the machine.
constexpr const wchar_t kSingleInstanceMutex[] =
    L"Global\\TalixCompanionSingleInstanceMutex";

// EnumWindows callback: stops at the first top-level window tagged with
// kInstanceProp and stores it in |lParam|.
BOOL CALLBACK FindTalixInstanceWindow(HWND hwnd, LPARAM lParam) {
  if (::GetProp(hwnd, kInstanceProp) != nullptr) {
    *reinterpret_cast<HWND*>(lParam) = hwnd;
    return FALSE;
  }
  return TRUE;
}

// Bring |hwnd| to the foreground even when the current process is not the
// foreground process, by temporarily sharing input state with the foreground
// thread. This bypasses Windows' foreground-lock timeout so the running
// instance reliably receives focus when a second instance is launched.
void BringToForeground(HWND hwnd) {
  ::ShowWindowAsync(hwnd, SW_RESTORE);
  DWORD foreground_thread =
      ::GetWindowThreadProcessId(::GetForegroundWindow(), nullptr);
  DWORD current_thread = ::GetCurrentThreadId();
  if (foreground_thread != 0 && foreground_thread != current_thread) {
    ::AttachThreadInput(current_thread, foreground_thread, TRUE);
  }
  ::SetForegroundWindow(hwnd);
  if (foreground_thread != 0 && foreground_thread != current_thread) {
    ::AttachThreadInput(current_thread, foreground_thread, FALSE);
  }
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // --- Single instance guard -------------------------------------------------
  // Create a named mutex. If it already exists, another instance owns it and
  // we must not start a second copy; instead bring the running instance's main
  // window to the foreground and ask it (via a window message) to show its main
  // panel, then exit.
  HANDLE single_instance_mutex =
      ::CreateMutex(nullptr, FALSE, kSingleInstanceMutex);
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing = nullptr;
    ::EnumWindows(FindTalixInstanceWindow,
                  reinterpret_cast<LPARAM>(&existing));
    if (existing != nullptr) {
      // Restore if minimized and bring to the foreground reliably.
      BringToForeground(existing);
      // Notify the running instance to show its main panel (handled on the
      // Dart side through a MethodChannel).
      const UINT show_msg =
          ::RegisterWindowMessage(L"TalixCompanion.ShowMainWindow");
      if (show_msg != 0) {
        ::PostMessage(existing, show_msg, 0, 0);
      }
    }
    if (single_instance_mutex != nullptr) {
      ::CloseHandle(single_instance_mutex);
    }
    ::CoUninitialize();
    return EXIT_SUCCESS;
  }
  // ---------------------------------------------------------------------------

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"talix_companion", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (single_instance_mutex != nullptr) {
    ::CloseHandle(single_instance_mutex);
  }
  return EXIT_SUCCESS;
}
