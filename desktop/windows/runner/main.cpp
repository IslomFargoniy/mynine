#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <csignal>
#include <cstdlib>
#include <cwchar>
#include <exception>

#include "flutter_window.h"
#include "lockdown_channel.h"
#include "utils.h"

namespace {

// Crash handlers: put the taskbar and the user's settings back before the
// process dies (a forced kill is handled by the next start / uninstaller).
LONG WINAPI OnUnhandledException(EXCEPTION_POINTERS*) {
  LockdownChannel::RestoreAfterCrash();
  return EXCEPTION_CONTINUE_SEARCH;
}

void OnTerminate() {
  LockdownChannel::RestoreAfterCrash();
  std::abort();
}

void OnAbortSignal(int) {
  LockdownChannel::RestoreAfterCrash();
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // "--restore-lockdown" (run by the uninstaller): undo what a previous run
  // left behind (policies, hidden taskbar) and exit. Before the single
  // instance check and without a window or Flutter.
  if (command_line != nullptr &&
      std::wcsstr(command_line, L"--restore-lockdown") != nullptr) {
    LockdownChannel::RestoreSystemState(true);
    return EXIT_SUCCESS;
  }

  ::SetUnhandledExceptionFilter(OnUnhandledException);
  std::set_terminate(OnTerminate);
  std::signal(SIGABRT, OnAbortSignal);

  // Single instance: the Inno Setup script uses the same mutex name
  // (AppMutex) so installs/updates wait until the app has exited.
  HANDLE single_instance =
      ::CreateMutexW(nullptr, TRUE, L"MynineDesktopSingleInstance");
  if (single_instance && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Mynine Exam");
    if (existing) {
      ::ShowWindow(existing, SW_RESTORE);
      ::SetForegroundWindow(existing);
    }
    ::CloseHandle(single_instance);
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Mynine Exam", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (single_instance) {
    ::ReleaseMutex(single_instance);
    ::CloseHandle(single_instance);
  }
  return EXIT_SUCCESS;
}
