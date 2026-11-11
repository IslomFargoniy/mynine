#include "lockdown_channel.h"

#include <dwmapi.h>
#include <flutter/standard_method_codec.h>
#include <tlhelp32.h>

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cwchar>
#include <map>
#include <set>
#include <thread>

// Windows 10 2004+ (SDK 10.0.19041). Older SDKs do not define it.
#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x00000011
#endif

namespace {

constexpr UINT_PTR kRefocusTimerId = 0x4D59;  // 'MY'
constexpr UINT kRefocusDelayMs = 400;

// Per-user values changed while the PC is locked (HKEY_CURRENT_USER). Logoff
// is deliberately NOT disabled so a stuck PC can always be recovered.
struct PolicyValue {
  const wchar_t* subkey;
  const wchar_t* name;
  DWORD locked_value;
};

constexpr wchar_t kSystemPolicies[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System";
constexpr wchar_t kTouchPad[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\PrecisionTouchPad";
constexpr wchar_t kNotifications[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Notifications\\Settings";
constexpr wchar_t kPushNotifications[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\PushNotifications";

const PolicyValue kPolicies[] = {
    // Ctrl+Alt+Del screen: no Task Manager / Lock / Change password.
    {kSystemPolicies, L"DisableTaskMgr", 1},
    {kSystemPolicies, L"DisableLockWorkstation", 1},  // also Win+L
    {kSystemPolicies, L"DisableChangePassword", 1},
    // Precision touchpad gestures (Win10/11): 0 = do nothing. Some builds
    // only apply these after the next sign-in.
    {kTouchPad, L"ThreeFingerSlideEnabled", 0},
    {kTouchPad, L"FourFingerSlideEnabled", 0},
    {kTouchPad, L"ThreeFingerTapEnabled", 0},
    {kTouchPad, L"FourFingerTapEnabled", 0},
    // Toast notifications (banners) off.
    {kNotifications, L"NOC_GLOBAL_SETTING_TOASTS_ENABLED", 0},
    {kPushNotifications, L"ToastEnabled", 0},
};

// Never terminated, whatever the banned list says.
const char* const kProtectedProcesses[] = {
    "system", "registry", "idle", "smss.exe", "csrss.exe", "wininit.exe",
    "winlogon.exe", "services.exe", "lsass.exe", "lsaiso.exe", "svchost.exe",
    "explorer.exe", "dwm.exe", "fontdrvhost.exe", "sihost.exe", "ctfmon.exe",
    "taskhostw.exe", "runtimebroker.exe", "searchhost.exe", "searchapp.exe",
    "startmenuexperiencehost.exe", "shellexperiencehost.exe",
    "textinputhost.exe", "logonui.exe", "conhost.exe", "audiodg.exe",
    "spoolsv.exe", "msmpeng.exe", "securityhealthservice.exe",
    "securityhealthsystray.exe", "userinit.exe", "dllhost.exe", "wudfhost.exe",
    "mynine.exe", "mynine_desktop.exe"};

bool IsProtectedProcess(const std::string& lower_name) {
  for (const char* p : kProtectedProcesses) {
    if (lower_name == p) return true;
  }
  return false;
}

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  const int size = ::MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(),
                                         static_cast<int>(utf8.size()), nullptr,
                                         0);
  if (size <= 0) return std::wstring();
  std::wstring out(static_cast<size_t>(size), L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), static_cast<int>(utf8.size()),
                        out.data(), size);
  return out;
}

DWORD CurrentSessionId() {
  DWORD session = 0;
  ::ProcessIdToSessionId(::GetCurrentProcessId(), &session);
  return session;
}

bool InCurrentSession(DWORD pid, DWORD current_session) {
  DWORD session = 0;
  return ::ProcessIdToSessionId(pid, &session) && session == current_session;
}

std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty()) return std::string();
  const int size = ::WideCharToMultiByte(CP_UTF8, 0, wide.c_str(),
                                         static_cast<int>(wide.size()), nullptr,
                                         0, nullptr, nullptr);
  if (size <= 0) return std::string();
  std::string out(static_cast<size_t>(size), '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), static_cast<int>(wide.size()),
                        out.data(), size, nullptr, nullptr);
  return out;
}

std::string ToLowerAscii(std::string s) {
  std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) {
    return static_cast<char>(std::tolower(c));
  });
  return s;
}

std::optional<std::wstring> ReadRegString(HKEY root, const wchar_t* subkey,
                                          const wchar_t* value) {
  DWORD bytes = 0;
  const DWORD flags = RRF_RT_REG_SZ | RRF_SUBKEY_WOW6464KEY;
  if (::RegGetValueW(root, subkey, value, flags, nullptr, nullptr, &bytes) !=
          ERROR_SUCCESS ||
      bytes == 0) {
    return std::nullopt;
  }
  std::wstring buffer(bytes / sizeof(wchar_t) + 1, L'\0');
  if (::RegGetValueW(root, subkey, value, flags, nullptr, buffer.data(),
                     &bytes) != ERROR_SUCCESS) {
    return std::nullopt;
  }
  buffer.resize(wcsnlen(buffer.c_str(), buffer.size()));
  return buffer;
}

bool GetBoolArg(const flutter::EncodableMap* args, const char* key,
                bool fallback) {
  if (!args) return fallback;
  auto it = args->find(flutter::EncodableValue(key));
  if (it == args->end()) return fallback;
  if (const bool* b = std::get_if<bool>(&it->second)) return *b;
  return fallback;
}

}  // namespace

LockdownChannel* LockdownChannel::instance_ = nullptr;

LockdownChannel::LockdownChannel(flutter::BinaryMessenger* messenger,
                                 HWND window)
    : window_(window) {
  instance_ = this;
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "mynine/lockdown",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });
  // The app crashed (or was killed) while the PC was locked last time:
  // put the user's original settings back before anything else.
  RestoreSystemPolicies();
}

LockdownChannel::~LockdownChannel() {
  Disable();
  if (channel_) channel_->SetMethodCallHandler(nullptr);
  if (instance_ == this) instance_ = nullptr;
}

void LockdownChannel::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());

  if (method == "enable") {
    Enable(GetBoolArg(args, "keyboardHook", true),
           GetBoolArg(args, "captureProtection", true),
           GetBoolArg(args, "kiosk", true),
           GetBoolArg(args, "systemPolicies", false),
           GetBoolArg(args, "minimizeOthers", false));
    result->Success();
  } else if (method == "disable") {
    Disable();
    result->Success();
  } else if (method == "monitorCount") {
    result->Success(flutter::EncodableValue(CountMonitors()));
  } else if (method == "scanProcesses") {
    std::vector<std::string> banned;
    if (args) {
      auto it = args->find(flutter::EncodableValue("names"));
      if (it != args->end()) {
        if (const auto* list = std::get_if<flutter::EncodableList>(&it->second)) {
          for (const auto& v : *list) {
            if (const auto* s = std::get_if<std::string>(&v)) {
              banned.push_back(ToLowerAscii(*s));
            }
          }
        }
      }
    }
    flutter::EncodableList found;
    for (const auto& name : ScanProcesses(banned)) {
      found.emplace_back(name);
    }
    result->Success(flutter::EncodableValue(found));
  } else if (method == "terminateProcesses") {
    std::vector<std::string> names;
    if (args) {
      auto it = args->find(flutter::EncodableValue("names"));
      if (it != args->end()) {
        if (const auto* list = std::get_if<flutter::EncodableList>(&it->second)) {
          for (const auto& v : *list) {
            if (const auto* s = std::get_if<std::string>(&v)) {
              names.push_back(ToLowerAscii(*s));
            }
          }
        }
      }
    }
    result->Success(flutter::EncodableValue(TerminateProcesses(names)));
  } else if (method == "clearClipboard") {
    if (::OpenClipboard(window_)) {
      ::EmptyClipboard();
      ::CloseClipboard();
    }
    result->Success();
  } else if (method == "machineId") {
    auto id = ReadMachineGuid();
    if (id) {
      result->Success(flutter::EncodableValue(*id));
    } else {
      result->Success();
    }
  } else if (method == "isVirtualMachine") {
    result->Success(flutter::EncodableValue(LooksLikeVirtualMachine()));
  } else {
    result->NotImplemented();
  }
}

// ---------------------------------------------------------------------------
// Enable / disable

void LockdownChannel::Enable(bool keyboard_hook, bool capture_protection,
                             bool kiosk, bool system_policies,
                             bool minimize_others) {
  if (system_policies) ApplySystemPolicies();
  minimize_others_ = minimize_others;
  if (minimize_others) MinimizeOtherWindows();
  if (kiosk) EnterKiosk();
  if (keyboard_hook) InstallKeyboardHook();
  if (capture_protection && !capture_protected_) {
    // Excludes the window from screenshots / screen sharing / recording
    // (shows black). Falls back to WDA_MONITOR before Windows 10 2004.
    if (!::SetWindowDisplayAffinity(window_, WDA_EXCLUDEFROMCAPTURE)) {
      ::SetWindowDisplayAffinity(window_, WDA_MONITOR);
    }
    capture_protected_ = true;
  }
}

void LockdownChannel::Disable() {
  RemoveKeyboardHook();
  minimize_others_ = false;
  RestoreSystemPolicies();
  if (capture_protected_) {
    ::SetWindowDisplayAffinity(window_, WDA_NONE);
    capture_protected_ = false;
  }
  ExitKiosk();
}

void LockdownChannel::EnterKiosk() {
  if (kiosk_) {
    FitToMonitor();
    return;
  }
  saved_style_ = ::GetWindowLongPtr(window_, GWL_STYLE);
  saved_ex_style_ = ::GetWindowLongPtr(window_, GWL_EXSTYLE);
  ::GetWindowRect(window_, &saved_rect_);
  ::SetWindowLongPtr(window_, GWL_STYLE,
                     (saved_style_ & ~WS_OVERLAPPEDWINDOW) | WS_POPUP |
                         WS_VISIBLE);
  // Hide from the taskbar / Alt+Tab list.
  ::SetWindowLongPtr(window_, GWL_EXSTYLE,
                     (saved_ex_style_ & ~WS_EX_APPWINDOW) | WS_EX_TOPMOST);
  kiosk_ = true;
  FitToMonitor();
  ::SetForegroundWindow(window_);
}

void LockdownChannel::FitToMonitor() {
  HMONITOR monitor = ::MonitorFromWindow(window_, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO info{};
  info.cbSize = sizeof(info);
  if (!::GetMonitorInfo(monitor, &info)) return;
  const RECT& r = info.rcMonitor;
  ::SetWindowPos(window_, HWND_TOPMOST, r.left, r.top, r.right - r.left,
                 r.bottom - r.top, SWP_FRAMECHANGED | SWP_SHOWWINDOW);
}

void LockdownChannel::ExitKiosk() {
  if (!kiosk_) return;
  kiosk_ = false;
  ::KillTimer(window_, kRefocusTimerId);
  ::SetWindowLongPtr(window_, GWL_STYLE, saved_style_);
  ::SetWindowLongPtr(window_, GWL_EXSTYLE, saved_ex_style_);
  ::SetWindowPos(window_, HWND_NOTOPMOST, saved_rect_.left, saved_rect_.top,
                 saved_rect_.right - saved_rect_.left,
                 saved_rect_.bottom - saved_rect_.top,
                 SWP_FRAMECHANGED | SWP_SHOWWINDOW);
}

// ---------------------------------------------------------------------------
// Keyboard hook (blocks Win and every Win+key combination, Alt+Tab,
// Ctrl+Alt+Tab, Alt+F4, Alt+Esc, Ctrl+Esc, Ctrl+Shift+Esc, Alt+Space,
// PrintScreen, keyboard launch keys). Ctrl+Alt+Del and Win+L cannot be
// intercepted by an app (secure attention sequence / Winlogon): the system
// policies above remove Task Manager and Lock from that screen, and the
// README recommends Group Policy / Assigned Access as the OS-level layer.

void LockdownChannel::InstallKeyboardHook() {
  if (keyboard_hook_) return;
  keyboard_hook_ = ::SetWindowsHookExW(WH_KEYBOARD_LL, KeyboardProc,
                                       ::GetModuleHandleW(nullptr), 0);
}

void LockdownChannel::RemoveKeyboardHook() {
  if (keyboard_hook_) {
    ::UnhookWindowsHookEx(keyboard_hook_);
    keyboard_hook_ = nullptr;
  }
}

LRESULT CALLBACK LockdownChannel::KeyboardProc(int code, WPARAM wparam,
                                               LPARAM lparam) {
  if (code == HC_ACTION) {
    const auto* key = reinterpret_cast<const KBDLLHOOKSTRUCT*>(lparam);
    const DWORD vk = key->vkCode;
    const bool alt = (key->flags & LLKHF_ALTDOWN) != 0;
    const bool ctrl = (::GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
    bool block = false;
    switch (vk) {
      case VK_LWIN:
      case VK_RWIN:
        block = true;  // Start menu, Win+D, Win+Tab, Win+Shift+S, ...
        break;
      case VK_TAB:
        block = alt;  // Alt+Tab, Alt+Shift+Tab, Ctrl+Alt+Tab
        break;
      case VK_F4:
        block = alt;  // Alt+F4
        break;
      case VK_ESCAPE:
        block = alt || ctrl;  // Alt+Esc, Ctrl+Esc, Ctrl+Shift+Esc
        break;
      case VK_SPACE:
        block = alt;  // Alt+Space (system menu)
        break;
      case VK_BROWSER_BACK:
      case VK_BROWSER_FORWARD:
      case VK_BROWSER_REFRESH:
      case VK_BROWSER_STOP:
      case VK_BROWSER_SEARCH:
      case VK_BROWSER_FAVORITES:
      case VK_BROWSER_HOME:
      case VK_LAUNCH_MAIL:
      case VK_LAUNCH_MEDIA_SELECT:
      case VK_LAUNCH_APP1:
      case VK_LAUNCH_APP2:
        block = true;  // keyboard launch keys open other programs
        break;
      case VK_SNAPSHOT:
        block = true;  // PrintScreen
        if (instance_ && (wparam == WM_KEYDOWN || wparam == WM_SYSKEYDOWN)) {
          instance_->SendEvent("capture_blocked");
        }
        break;
      default:
        break;
    }
    if (block) return 1;
  }
  return ::CallNextHookEx(nullptr, code, wparam, lparam);
}

// ---------------------------------------------------------------------------
// Window messages: focus loss, display changes, re-focus in kiosk mode.

std::optional<LRESULT> LockdownChannel::HandleMessage(HWND hwnd, UINT message,
                                                      WPARAM wparam,
                                                      LPARAM lparam) {
  switch (message) {
    case WM_ACTIVATEAPP:
      if (wparam == FALSE) {
        // lparam = thread of the app being activated; fall back on the
        // foreground window.
        DWORD pid = 0;
        if (lparam != 0) {
          HANDLE thread = ::OpenThread(THREAD_QUERY_LIMITED_INFORMATION, FALSE,
                                       static_cast<DWORD>(lparam));
          if (thread) {
            pid = ::GetProcessIdOfThread(thread);
            ::CloseHandle(thread);
          }
        }
        if (pid == 0) {
          if (HWND fg = ::GetForegroundWindow()) {
            ::GetWindowThreadProcessId(fg, &pid);
          }
        }
        flutter::EncodableMap detail;
        if (pid != 0 && pid != ::GetCurrentProcessId()) {
          const std::string name = ProcessNameFromPid(pid);
          if (!name.empty()) {
            detail[flutter::EncodableValue("process")] =
                flutter::EncodableValue(name);
          }
        }
        SendEvent("focus_lost", detail);
        if (kiosk_) ::SetTimer(hwnd, kRefocusTimerId, kRefocusDelayMs, nullptr);
      } else {
        SendEvent("focus_gained");
      }
      break;  // let Flutter see it too
    case WM_ENDSESSION:
      // Sign-out / shutdown while locked: leave the account as it was.
      if (wparam) RestoreSystemPolicies();
      break;
    case WM_DISPLAYCHANGE:
      if (kiosk_) FitToMonitor();
      SendEvent("display_changed");
      break;
    case WM_TIMER:
      if (wparam == kRefocusTimerId) {
        ::KillTimer(hwnd, kRefocusTimerId);
        if (kiosk_) {
          if (minimize_others_) MinimizeOtherWindows();
          // Take the foreground back (works because our process owned it last;
          // Windows may only flash the taskbar otherwise).
          ::ShowWindow(hwnd, SW_RESTORE);
          ::SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
                         SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
          ::SetForegroundWindow(hwnd);
        }
        return 0;
      }
      break;
    default:
      break;
  }
  return std::nullopt;
}

void LockdownChannel::SendEvent(const std::string& type) {
  SendEvent(type, flutter::EncodableMap());
}

void LockdownChannel::SendEvent(const std::string& type,
                                const flutter::EncodableMap& extra) {
  if (!channel_) return;
  flutter::EncodableMap payload = extra;
  payload[flutter::EncodableValue("type")] = flutter::EncodableValue(type);
  channel_->InvokeMethod(
      "onEvent", std::make_unique<flutter::EncodableValue>(payload));
}

// ---------------------------------------------------------------------------
// Other windows: minimized when the PC is locked and whenever it re-takes
// the focus, so nothing else stays on screen.

void LockdownChannel::MinimizeOtherWindows() {
  ::EnumWindows(
      [](HWND hwnd, LPARAM data) -> BOOL {
        auto* self = reinterpret_cast<LockdownChannel*>(data);
        if (hwnd == self->window_ || !::IsWindowVisible(hwnd) ||
            ::IsIconic(hwnd)) {
          return TRUE;
        }
        DWORD pid = 0;
        ::GetWindowThreadProcessId(hwnd, &pid);
        if (pid == ::GetCurrentProcessId()) return TRUE;
        // Owned popups follow their owner; tool windows are not app windows.
        if (::GetWindow(hwnd, GW_OWNER) != nullptr) return TRUE;
        const LONG_PTR ex_style = ::GetWindowLongPtr(hwnd, GWL_EXSTYLE);
        if (ex_style & WS_EX_TOOLWINDOW) return TRUE;
        // Hidden UWP frames / other virtual desktops report as visible.
        DWORD cloaked = 0;
        if (SUCCEEDED(::DwmGetWindowAttribute(hwnd, DWMWA_CLOAKED, &cloaked,
                                              sizeof(cloaked))) &&
            cloaked != 0) {
          return TRUE;
        }
        wchar_t cls[64] = {};
        ::GetClassNameW(hwnd, cls, 64);
        for (const wchar_t* shell :
             {L"Progman", L"WorkerW", L"Shell_TrayWnd",
              L"Shell_SecondaryTrayWnd", L"NotifyIconOverflowWindow",
              L"Windows.UI.Core.CoreWindow"}) {
          if (wcscmp(cls, shell) == 0) return TRUE;
        }
        // Async: never blocks on a hung application.
        ::ShowWindowAsync(hwnd, SW_MINIMIZE);
        return TRUE;
      },
      reinterpret_cast<LPARAM>(this));
}

// ---------------------------------------------------------------------------
// System policies (HKCU) with crash-safe restore.
//
// Marker file format, one line per value (UTF-8):
//   <subkey>|<value name>|<1 = existed, 0 = absent>|<original DWORD>

std::wstring LockdownChannel::PolicyMarkerPath() {
  wchar_t base[MAX_PATH] = {};
  const DWORD len = ::GetEnvironmentVariableW(L"LOCALAPPDATA", base, MAX_PATH);
  if (len == 0 || len >= MAX_PATH) return std::wstring();
  std::wstring dir = std::wstring(base) + L"\\Mynine";
  ::CreateDirectoryW(dir.c_str(), nullptr);  // ERROR_ALREADY_EXISTS is fine
  return dir + L"\\lockdown_applied.ini";
}

void LockdownChannel::BroadcastPolicyChange() {
  // Explorer re-reads the policies on WM_SETTINGCHANGE("Policy"). Sent from a
  // worker thread so a hung top-level window never stalls the UI thread.
  std::thread([] {
    DWORD_PTR ignored = 0;
    ::SendMessageTimeoutW(HWND_BROADCAST, WM_SETTINGCHANGE, 0,
                          reinterpret_cast<LPARAM>(L"Policy"),
                          SMTO_ABORTIFHUNG, 1000, &ignored);
  }).detach();
}

void LockdownChannel::ApplySystemPolicies() {
  if (policies_applied_) return;
  const std::wstring path = PolicyMarkerPath();
  if (path.empty()) return;  // cannot remember the originals: change nothing

  // A leftover marker means the originals are already saved (restore failed
  // earlier): keep it instead of saving our own locked values as "originals".
  if (::GetFileAttributesW(path.c_str()) == INVALID_FILE_ATTRIBUTES) {
    std::string content;
    for (const auto& p : kPolicies) {
      DWORD value = 0;
      DWORD size = sizeof(value);
      const bool existed =
          ::RegGetValueW(HKEY_CURRENT_USER, p.subkey, p.name, RRF_RT_REG_DWORD,
                         nullptr, &value, &size) == ERROR_SUCCESS;
      content += WideToUtf8(p.subkey) + "|" + WideToUtf8(p.name) + "|" +
                 (existed ? "1" : "0") + "|" +
                 std::to_string(existed ? value : 0) + "\n";
    }
    FILE* file = nullptr;
    if (_wfopen_s(&file, path.c_str(), L"wb") != 0 || file == nullptr) return;
    const size_t written = fwrite(content.data(), 1, content.size(), file);
    const bool ok = written == content.size() && fflush(file) == 0;
    fclose(file);
    if (!ok) {
      ::DeleteFileW(path.c_str());
      return;
    }
  }

  for (const auto& p : kPolicies) {
    HKEY key = nullptr;
    if (::RegCreateKeyExW(HKEY_CURRENT_USER, p.subkey, 0, nullptr, 0,
                          KEY_SET_VALUE, nullptr, &key,
                          nullptr) != ERROR_SUCCESS) {
      continue;
    }
    const DWORD value = p.locked_value;
    ::RegSetValueExW(key, p.name, 0, REG_DWORD,
                     reinterpret_cast<const BYTE*>(&value), sizeof(value));
    ::RegCloseKey(key);
  }
  policies_applied_ = true;
  BroadcastPolicyChange();
}

void LockdownChannel::RestoreSystemPolicies() {
  const std::wstring path = PolicyMarkerPath();
  if (path.empty()) {
    policies_applied_ = false;
    return;
  }
  FILE* file = nullptr;
  if (_wfopen_s(&file, path.c_str(), L"rb") != 0 || file == nullptr) {
    policies_applied_ = false;  // nothing saved = nothing changed
    return;
  }
  std::string content;
  char buffer[1024];
  size_t n = 0;
  while ((n = fread(buffer, 1, sizeof(buffer), file)) > 0) {
    content.append(buffer, n);
  }
  fclose(file);

  bool all_ok = true;
  size_t start = 0;
  while (start < content.size()) {
    size_t end = content.find('\n', start);
    if (end == std::string::npos) end = content.size();
    const std::string line = content.substr(start, end - start);
    start = end + 1;

    // subkey|name|existed|value
    const size_t a = line.find('|');
    const size_t b = a == std::string::npos ? a : line.find('|', a + 1);
    const size_t c = b == std::string::npos ? b : line.find('|', b + 1);
    if (c == std::string::npos) continue;
    const std::wstring subkey = Utf8ToWide(line.substr(0, a));
    const std::wstring name = Utf8ToWide(line.substr(a + 1, b - a - 1));
    const bool existed = line.substr(b + 1, c - b - 1) == "1";
    const DWORD value =
        static_cast<DWORD>(std::strtoul(line.substr(c + 1).c_str(), nullptr, 10));
    if (subkey.empty() || name.empty()) continue;

    LSTATUS status;
    if (existed) {
      HKEY key = nullptr;
      status = ::RegCreateKeyExW(HKEY_CURRENT_USER, subkey.c_str(), 0, nullptr,
                                 0, KEY_SET_VALUE, nullptr, &key, nullptr);
      if (status == ERROR_SUCCESS) {
        status = ::RegSetValueExW(key, name.c_str(), 0, REG_DWORD,
                                  reinterpret_cast<const BYTE*>(&value),
                                  sizeof(value));
        ::RegCloseKey(key);
      }
    } else {
      status = ::RegDeleteKeyValueW(HKEY_CURRENT_USER, subkey.c_str(),
                                    name.c_str());
      if (status == ERROR_FILE_NOT_FOUND) status = ERROR_SUCCESS;
    }
    if (status != ERROR_SUCCESS) all_ok = false;
  }

  // Keep the marker if something could not be restored (retried next start).
  if (all_ok) ::DeleteFileW(path.c_str());
  policies_applied_ = false;
  BroadcastPolicyChange();
}

// ---------------------------------------------------------------------------
// Static helpers

int LockdownChannel::CountMonitors() {
  int count = 0;
  ::EnumDisplayMonitors(
      nullptr, nullptr,
      [](HMONITOR, HDC, LPRECT, LPARAM data) -> BOOL {
        ++*reinterpret_cast<int*>(data);
        return TRUE;
      },
      reinterpret_cast<LPARAM>(&count));
  return count;
}

std::vector<std::string> LockdownChannel::ScanProcesses(
    const std::vector<std::string>& banned) {
  std::vector<std::string> found;
  if (banned.empty()) return found;
  const std::set<std::string> wanted(banned.begin(), banned.end());
  std::set<std::string> seen;
  const DWORD session = CurrentSessionId();
  HANDLE snapshot = ::CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) return found;
  PROCESSENTRY32W entry{};
  entry.dwSize = sizeof(entry);
  if (::Process32FirstW(snapshot, &entry)) {
    do {
      const std::string name = ToLowerAscii(WideToUtf8(entry.szExeFile));
      // Only this user's session: another signed-in user's programs are not
      // on this screen (and could not be closed anyway).
      if (wanted.count(name) && !IsProtectedProcess(name) &&
          InCurrentSession(entry.th32ProcessID, session) &&
          seen.insert(name).second) {
        found.push_back(name);
      }
    } while (::Process32NextW(snapshot, &entry));
  }
  ::CloseHandle(snapshot);
  return found;
}

flutter::EncodableList LockdownChannel::TerminateProcesses(
    const std::vector<std::string>& names) {
  flutter::EncodableList out;
  std::set<std::string> wanted;
  for (const auto& n : names) {
    if (!n.empty() && !IsProtectedProcess(n)) wanted.insert(n);
  }
  if (wanted.empty()) return out;

  const DWORD own_pid = ::GetCurrentProcessId();
  const DWORD session = CurrentSessionId();
  // name -> every instance terminated?
  std::map<std::string, bool> results;
  HANDLE snapshot = ::CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) return out;
  PROCESSENTRY32W entry{};
  entry.dwSize = sizeof(entry);
  if (::Process32FirstW(snapshot, &entry)) {
    do {
      const DWORD pid = entry.th32ProcessID;
      if (pid == own_pid || pid == 0) continue;
      const std::string name = ToLowerAscii(WideToUtf8(entry.szExeFile));
      if (!wanted.count(name) || !InCurrentSession(pid, session)) continue;
      bool ok = false;
      HANDLE process =
          ::OpenProcess(PROCESS_TERMINATE | SYNCHRONIZE, FALSE, pid);
      if (process) {
        ok = ::TerminateProcess(process, 1) != FALSE;
        // Termination is asynchronous; give it a moment so the next scan
        // does not see it any more.
        if (ok) ::WaitForSingleObject(process, 200);
        ::CloseHandle(process);
      }
      auto it = results.find(name);
      if (it == results.end()) {
        results[name] = ok;
      } else {
        it->second = it->second && ok;
      }
    } while (::Process32NextW(snapshot, &entry));
  }
  ::CloseHandle(snapshot);

  for (const auto& [name, ok] : results) {
    flutter::EncodableMap item{
        {flutter::EncodableValue("process"), flutter::EncodableValue(name)},
        {flutter::EncodableValue("terminated"), flutter::EncodableValue(ok)}};
    out.emplace_back(item);
  }
  return out;
}

std::string LockdownChannel::ProcessNameFromPid(DWORD pid) {
  HANDLE process =
      ::OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
  if (process) {
    wchar_t path[MAX_PATH] = {};
    DWORD size = MAX_PATH;
    const BOOL ok = ::QueryFullProcessImageNameW(process, 0, path, &size);
    ::CloseHandle(process);
    if (ok && size > 0) {
      std::wstring full(path, size);
      const size_t slash = full.find_last_of(L"\\/");
      return ToLowerAscii(WideToUtf8(
          slash == std::wstring::npos ? full : full.substr(slash + 1)));
    }
  }
  // Elevated / protected process: the snapshot still has its exe name.
  std::string name;
  HANDLE snapshot = ::CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) return name;
  PROCESSENTRY32W entry{};
  entry.dwSize = sizeof(entry);
  if (::Process32FirstW(snapshot, &entry)) {
    do {
      if (entry.th32ProcessID == pid) {
        name = ToLowerAscii(WideToUtf8(entry.szExeFile));
        break;
      }
    } while (::Process32NextW(snapshot, &entry));
  }
  ::CloseHandle(snapshot);
  return name;
}

std::optional<std::string> LockdownChannel::ReadMachineGuid() {
  auto guid = ReadRegString(HKEY_LOCAL_MACHINE,
                            L"SOFTWARE\\Microsoft\\Cryptography",
                            L"MachineGuid");
  if (!guid || guid->empty()) return std::nullopt;
  return WideToUtf8(*guid);
}

bool LockdownChannel::LooksLikeVirtualMachine() {
  const wchar_t* bios = L"HARDWARE\\DESCRIPTION\\System\\BIOS";
  std::string text;
  for (const wchar_t* value :
       {L"SystemManufacturer", L"SystemProductName", L"BIOSVendor"}) {
    if (auto v = ReadRegString(HKEY_LOCAL_MACHINE, bios, value)) {
      text += ToLowerAscii(WideToUtf8(*v)) + " ";
    }
  }
  for (const char* marker : {"vmware", "virtualbox", "vbox", "qemu", "kvm",
                             "xen", "parallels", "virtual machine", "bochs"}) {
    if (text.find(marker) != std::string::npos) return true;
  }
  return false;
}
