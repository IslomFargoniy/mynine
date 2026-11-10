// Mynine kiosk / lockdown support for the exam PCs (Windows 10/11).
//
// Exposes MethodChannel "mynine/lockdown" (StandardMethodCodec):
//
//   enable({keyboardHook, captureProtection, kiosk})  -> null
//   disable()                                         -> null
//   monitorCount()                                    -> int
//   scanProcesses({names: [String]})                  -> [String] (lower-case exe names found)
//   clearClipboard()                                  -> null
//   machineId()                                       -> String? (HKLM MachineGuid)
//   isVirtualMachine()                                -> bool
//
// Events are pushed to Dart with invokeMethod("onEvent", {type: ...}):
//   focus_lost | focus_gained | display_changed | capture_blocked
//
// Self-contained: only Win32 + the Flutter C++ client wrapper.
#ifndef RUNNER_LOCKDOWN_CHANNEL_H_
#define RUNNER_LOCKDOWN_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <optional>
#include <string>
#include <vector>

class LockdownChannel {
 public:
  LockdownChannel(flutter::BinaryMessenger* messenger, HWND window);
  ~LockdownChannel();

  LockdownChannel(const LockdownChannel&) = delete;
  LockdownChannel& operator=(const LockdownChannel&) = delete;

  // Called from FlutterWindow::MessageHandler for every top-level message.
  // Returns a value only for messages it fully handles (its own timer).
  std::optional<LRESULT> HandleMessage(HWND hwnd, UINT message, WPARAM wparam,
                                       LPARAM lparam);

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void Enable(bool keyboard_hook, bool capture_protection, bool kiosk);
  void Disable();
  void EnterKiosk();
  void ExitKiosk();
  void FitToMonitor();
  void InstallKeyboardHook();
  void RemoveKeyboardHook();
  void SendEvent(const std::string& type);

  static int CountMonitors();
  static std::vector<std::string> ScanProcesses(
      const std::vector<std::string>& banned);
  static std::optional<std::string> ReadMachineGuid();
  static bool LooksLikeVirtualMachine();
  static LRESULT CALLBACK KeyboardProc(int code, WPARAM wparam, LPARAM lparam);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  HWND window_;
  HHOOK keyboard_hook_ = nullptr;
  bool kiosk_ = false;
  bool capture_protected_ = false;
  LONG_PTR saved_style_ = 0;
  LONG_PTR saved_ex_style_ = 0;
  RECT saved_rect_{};

  // The low-level hook callback is static; it reaches the instance here.
  static LockdownChannel* instance_;
};

#endif  // RUNNER_LOCKDOWN_CHANNEL_H_
