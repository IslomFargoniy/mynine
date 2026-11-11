// Mynine kiosk / lockdown support for the exam PCs (Windows 10/11).
//
// Exposes MethodChannel "mynine/lockdown" (StandardMethodCodec):
//
//   enable({keyboardHook, captureProtection, kiosk,
//           systemPolicies, minimizeOthers})          -> null
//   disable()                                         -> null
//   monitorCount()                                    -> int
//   scanProcesses({names: [String]})                  -> [String] (lower-case exe names found
//                                                        in this user's session)
//   terminateProcesses({names: [String]})             -> [{process, terminated}] (this session
//                                                        only, protected system processes skipped;
//                                                        runs on a worker thread, the result is
//                                                        posted back to the platform thread)
//   clearClipboard()                                  -> null
//   machineId()                                       -> String? (HKLM MachineGuid)
//   isVirtualMachine()                                -> bool
//
// Events are pushed to Dart with invokeMethod("onEvent", {type: ...}):
//   focus_lost {process?} | focus_gained | display_changed | capture_blocked
//
// System policies (HKCU, only while locked): Task Manager, Lock and Change
// password disabled (Ctrl+Alt+Del screen), precision-touchpad 3/4-finger
// gestures off, toast notifications off; accessibility shortcut keys
// (StickyKeys: Shift x5, FilterKeys: right Shift 8 s, ToggleKeys: NumLock
// 5 s) off. The original values (registry values with their type and raw
// data; accessibility flags) are written to
// %LOCALAPPDATA%\Mynine\lockdown_applied.ini BEFORE anything is changed and
// restored on disable(), on WM_ENDSESSION, and at the next start if the app
// crashed (the constructor restores a leftover marker file).
//
// The low-level keyboard hook is re-installed every 30 s and when the window
// regains the focus: Windows silently removes a hook whose thread was too
// slow (LowLevelHooksTimeout), so slow work (closing programs) never runs on
// the hook's (platform) thread.
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

  void Enable(bool keyboard_hook, bool capture_protection, bool kiosk,
              bool system_policies, bool minimize_others);
  void Disable();
  void EnterKiosk();
  void ExitKiosk();
  void FitToMonitor();
  void InstallKeyboardHook();
  void ReinstallKeyboardHook();
  void RemoveKeyboardHook();
  void SendEvent(const std::string& type);
  void SendEvent(const std::string& type, const flutter::EncodableMap& extra);
  void MinimizeOtherWindows();
  void ApplySystemPolicies();
  void RestoreSystemPolicies();

  static int CountMonitors();
  static std::vector<std::string> ScanProcesses(
      const std::vector<std::string>& banned);
  static flutter::EncodableList TerminateProcesses(
      const std::vector<std::string>& names);
  static std::string ProcessNameFromPid(DWORD pid);
  static std::wstring PolicyMarkerPath();
  static void ReleaseHeldWinKeys();
  static void BroadcastPolicyChange();
  static std::optional<std::string> ReadMachineGuid();
  static bool LooksLikeVirtualMachine();
  static LRESULT CALLBACK KeyboardProc(int code, WPARAM wparam, LPARAM lparam);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  HWND window_;
  HHOOK keyboard_hook_ = nullptr;
  bool hook_wanted_ = false;
  bool kiosk_ = false;
  bool capture_protected_ = false;
  bool policies_applied_ = false;
  bool minimize_others_ = false;
  LONG_PTR saved_style_ = 0;
  LONG_PTR saved_ex_style_ = 0;
  RECT saved_rect_{};

  // The low-level hook callback is static; it reaches the instance here.
  static LockdownChannel* instance_;
};

#endif  // RUNNER_LOCKDOWN_CHANNEL_H_
