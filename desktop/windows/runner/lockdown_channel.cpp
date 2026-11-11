#include "lockdown_channel.h"

#include <dwmapi.h>
#include <flutter/standard_method_codec.h>
#include <io.h>
#include <tlhelp32.h>

#include <algorithm>
#include <atomic>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cwchar>
#include <map>
#include <set>
#include <thread>
#include <utility>
#include <vector>

// Windows 10 2004+ (SDK 10.0.19041). Older SDKs do not define it.
#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x00000011
#endif

namespace {

// Windows 11 keeps its taskbar above a topmost full-screen window whenever that
// window is not the foreground one, so kiosk mode hides the taskbars outright
// (primary and every secondary monitor) and shows them again on exit. Startup
// also shows them, in case a previous run crashed while they were hidden.
void SetTaskbarsVisible(bool visible) {
  ::EnumWindows(
      [](HWND hwnd, LPARAM lparam) -> BOOL {
        wchar_t cls[64] = {};
        ::GetClassNameW(hwnd, cls, 64);
        if (wcscmp(cls, L"Shell_TrayWnd") == 0 ||
            wcscmp(cls, L"Shell_SecondaryTrayWnd") == 0) {
          ::ShowWindowAsync(hwnd, lparam != 0 ? SW_SHOWNA : SW_HIDE);
        }
        return TRUE;
      },
      visible ? 1 : 0);
}

constexpr UINT_PTR kRefocusTimerId = 0x4D59;  // 'MY'
constexpr UINT kRefocusDelayMs = 400;

// Re-installs the low-level keyboard hook (Windows drops a hook that timed
// out once too often, without telling the app).
constexpr UINT_PTR kHookTimerId = 0x4D5A;
constexpr UINT kHookRefreshMs = 30000;

// Posted by the terminate worker thread back to the platform thread.
constexpr UINT kTerminateDoneMessage = WM_APP + 0x4D;

// Unassigned virtual key, sent before a synthesized Win key-up so the
// Start menu does not open (a lone Win tap opens it).
constexpr WORD kMaskKey = 0xE8;

// A terminateProcesses call in flight on the worker thread.
struct TerminateJob {
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result;
  flutter::EncodableList list;
};

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

std::string ToHex(const std::vector<BYTE>& data) {
  static const char kDigits[] = "0123456789abcdef";
  std::string out;
  out.reserve(data.size() * 2);
  for (const BYTE b : data) {
    out.push_back(kDigits[(b >> 4) & 0x0F]);
    out.push_back(kDigits[b & 0x0F]);
  }
  return out;
}

int HexDigit(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return -1;
}

bool FromHex(const std::string& hex, std::vector<BYTE>* out) {
  out->clear();
  if (hex.size() % 2 != 0) return false;
  for (size_t i = 0; i < hex.size(); i += 2) {
    const int hi = HexDigit(hex[i]);
    const int lo = HexDigit(hex[i + 1]);
    if (hi < 0 || lo < 0) return false;
    out->push_back(static_cast<BYTE>((hi << 4) | lo));
  }
  return true;
}

std::vector<std::string> SplitFields(const std::string& line) {
  std::vector<std::string> fields;
  size_t start = 0;
  size_t bar = line.find('|');
  for (; bar != std::string::npos; bar = line.find('|', start)) {
    fields.push_back(line.substr(start, bar - start));
    start = bar + 1;
  }
  fields.push_back(line.substr(start));
  return fields;
}

// Accessibility shortcut keys. Only the flags are saved / changed; the other
// fields keep their current values. Changes are not written to the user
// profile (fWinIni = 0): they last until sign-out at most.
const char* const kAccessFeatures[] = {"STICKY", "FILTER", "TOGGLE"};

bool GetAccessFlags(const std::string& name, DWORD* flags) {
  if (name == "STICKY") {
    STICKYKEYS v{};
    v.cbSize = static_cast<UINT>(sizeof(v));
    if (!::SystemParametersInfoW(SPI_GETSTICKYKEYS, v.cbSize, &v, 0)) return false;
    *flags = v.dwFlags;
    return true;
  }
  if (name == "FILTER") {
    FILTERKEYS v{};
    v.cbSize = static_cast<UINT>(sizeof(v));
    if (!::SystemParametersInfoW(SPI_GETFILTERKEYS, v.cbSize, &v, 0)) return false;
    *flags = v.dwFlags;
    return true;
  }
  if (name == "TOGGLE") {
    TOGGLEKEYS v{};
    v.cbSize = static_cast<UINT>(sizeof(v));
    if (!::SystemParametersInfoW(SPI_GETTOGGLEKEYS, v.cbSize, &v, 0)) return false;
    *flags = v.dwFlags;
    return true;
  }
  return false;
}

bool SetAccessFlags(const std::string& name, DWORD flags) {
  if (name == "STICKY") {
    STICKYKEYS v{};
    v.cbSize = static_cast<UINT>(sizeof(v));
    if (!::SystemParametersInfoW(SPI_GETSTICKYKEYS, v.cbSize, &v, 0)) return false;
    v.dwFlags = flags;
    return ::SystemParametersInfoW(SPI_SETSTICKYKEYS, v.cbSize, &v, 0) != FALSE;
  }
  if (name == "FILTER") {
    FILTERKEYS v{};
    v.cbSize = static_cast<UINT>(sizeof(v));
    if (!::SystemParametersInfoW(SPI_GETFILTERKEYS, v.cbSize, &v, 0)) return false;
    v.dwFlags = flags;
    return ::SystemParametersInfoW(SPI_SETFILTERKEYS, v.cbSize, &v, 0) != FALSE;
  }
  if (name == "TOGGLE") {
    TOGGLEKEYS v{};
    v.cbSize = static_cast<UINT>(sizeof(v));
    if (!::SystemParametersInfoW(SPI_GETTOGGLEKEYS, v.cbSize, &v, 0)) return false;
    v.dwFlags = flags;
    return ::SystemParametersInfoW(SPI_SETTOGGLEKEYS, v.cbSize, &v, 0) != FALSE;
  }
  return false;
}

// The flags with the shortcut key (and its confirmation dialog) switched off.
DWORD WithoutHotkey(const std::string& name, DWORD flags) {
  if (name == "STICKY") return flags & ~static_cast<DWORD>(SKF_HOTKEYACTIVE | SKF_CONFIRMHOTKEY);
  if (name == "FILTER") return flags & ~static_cast<DWORD>(FKF_HOTKEYACTIVE | FKF_CONFIRMHOTKEY);
  if (name == "TOGGLE") return flags & ~static_cast<DWORD>(TKF_HOTKEYACTIVE | TKF_CONFIRMHOTKEY);
  return flags;
}

std::string AccessibilityMarkerLines() {
  std::string lines;
  for (const char* name : kAccessFeatures) {
    DWORD flags = 0;
    if (GetAccessFlags(name, &flags)) {
      lines += std::string("A|") + name + "|" + std::to_string(flags) + "\n";
    }
  }
  return lines;
}

void DisableAccessibilityHotkeys() {
  for (const char* name : kAccessFeatures) {
    DWORD flags = 0;
    if (GetAccessFlags(name, &flags)) {
      const DWORD locked = WithoutHotkey(name, flags);
      if (locked != flags) SetAccessFlags(name, locked);
    }
  }
}

bool ReadWholeFile(const std::wstring& path, std::string* content) {
  FILE* file = nullptr;
  if (_wfopen_s(&file, path.c_str(), L"rb") != 0 || file == nullptr) return false;
  char buffer[1024];
  size_t n = 0;
  while ((n = fread(buffer, 1, sizeof(buffer), file)) > 0) {
    content->append(buffer, n);
  }
  fclose(file);
  return true;
}

// Written through to the disk (_commit = FlushFileBuffers) before returning:
// the marker must survive a power loss that happens after the registry was
// changed.
bool WriteWholeFile(const std::wstring& path, const std::string& content,
                    const wchar_t* mode) {
  FILE* file = nullptr;
  if (_wfopen_s(&file, path.c_str(), mode) != 0 || file == nullptr) return false;
  const size_t written = fwrite(content.data(), 1, content.size(), file);
  const bool ok = written == content.size() && fflush(file) == 0 &&
                  _commit(_fileno(file)) == 0;
  fclose(file);
  return ok;
}

// True when the marker holds at least one saved registry value (an "R|" line
// or a desktop 1.0.2 line). An empty / truncated marker saved nothing.
bool MarkerHasRegistryLines(const std::string& content) {
  size_t start = 0;
  while (start < content.size()) {
    size_t end = content.find('\n', start);
    if (end == std::string::npos) end = content.size();
    std::string line = content.substr(start, end - start);
    start = end + 1;
    if (!line.empty() && line.back() == '\r') line.pop_back();
    if (line.empty()) continue;
    const std::vector<std::string> f = SplitFields(line);
    if (f[0] == "R" && f.size() >= 6) return true;
    if (f[0] != "R" && f[0] != "A" && f.size() >= 4) return true;
  }
  return false;
}

// The value currently holds exactly what lockdown writes (REG_DWORD).
bool HasLockedValue(const PolicyValue& p) {
  DWORD value = 0;
  DWORD size = static_cast<DWORD>(sizeof(value));
  return ::RegGetValueW(HKEY_CURRENT_USER, p.subkey, p.name, RRF_RT_REG_DWORD,
                        nullptr, &value, &size) == ERROR_SUCCESS &&
         value == p.locked_value;
}

// No usable marker: the values are only deleted when they hold the locked
// value (they were most likely left by a run whose marker was lost).
void DeleteLockedValues() {
  for (const auto& p : kPolicies) {
    if (HasLockedValue(p)) {
      ::RegDeleteKeyValueW(HKEY_CURRENT_USER, p.subkey, p.name);
    }
  }
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
  SetTaskbarsVisible(true);
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
    // Closing programs waits for each of them: never on this (platform)
    // thread, which also runs the low-level keyboard hook. The result is
    // posted back and delivered in HandleMessage.
    auto* job = new TerminateJob{std::move(result), {}};
    const HWND target = window_;
    std::thread([job, names, target]() {
      job->list = TerminateProcesses(names);
      if (!::PostMessageW(target, kTerminateDoneMessage, 0,
                          reinterpret_cast<LPARAM>(job))) {
        // The window is gone (app exiting): the result must not be touched
        // from this thread, so it is deliberately leaked.
        static_cast<void>(job->result.release());
        delete job;
      }
    }).detach();
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
    SetTaskbarsVisible(false);
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
  SetTaskbarsVisible(false);
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
  SetTaskbarsVisible(true);
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
  hook_wanted_ = true;
  ::SetTimer(window_, kHookTimerId, kHookRefreshMs, nullptr);
  if (keyboard_hook_) return;
  // A Win key held right now would stay "down" for Windows once the hook
  // swallows its key-up (every later key would then act as Win+key).
  ReleaseHeldWinKeys();
  keyboard_hook_ = ::SetWindowsHookExW(WH_KEYBOARD_LL, KeyboardProc,
                                       ::GetModuleHandleW(nullptr), 0);
}

void LockdownChannel::ReinstallKeyboardHook() {
  if (!hook_wanted_) return;
  // New hook first, then the old one: no moment without a hook. A hook that
  // Windows already removed makes UnhookWindowsHookEx fail harmlessly.
  HHOOK fresh = ::SetWindowsHookExW(WH_KEYBOARD_LL, KeyboardProc,
                                    ::GetModuleHandleW(nullptr), 0);
  if (!fresh) return;  // keep the current one
  HHOOK old = keyboard_hook_;
  keyboard_hook_ = fresh;
  if (old) ::UnhookWindowsHookEx(old);
}

void LockdownChannel::RemoveKeyboardHook() {
  hook_wanted_ = false;
  ::KillTimer(window_, kHookTimerId);
  if (keyboard_hook_) {
    ::UnhookWindowsHookEx(keyboard_hook_);
    keyboard_hook_ = nullptr;
  }
}

void LockdownChannel::ReleaseHeldWinKeys() {
  const bool lwin = (::GetAsyncKeyState(VK_LWIN) & 0x8000) != 0;
  const bool rwin = (::GetAsyncKeyState(VK_RWIN) & 0x8000) != 0;
  if (!lwin && !rwin) return;
  INPUT inputs[4] = {};
  UINT count = 0;
  // An unassigned key first, so the Win key-up is not a "Win tap" that
  // opens the Start menu.
  inputs[count].type = INPUT_KEYBOARD;
  inputs[count].ki.wVk = kMaskKey;
  ++count;
  inputs[count].type = INPUT_KEYBOARD;
  inputs[count].ki.wVk = kMaskKey;
  inputs[count].ki.dwFlags = KEYEVENTF_KEYUP;
  ++count;
  if (lwin) {
    inputs[count].type = INPUT_KEYBOARD;
    inputs[count].ki.wVk = VK_LWIN;
    inputs[count].ki.dwFlags = KEYEVENTF_KEYUP | KEYEVENTF_EXTENDEDKEY;
    ++count;
  }
  if (rwin) {
    inputs[count].type = INPUT_KEYBOARD;
    inputs[count].ki.wVk = VK_RWIN;
    inputs[count].ki.dwFlags = KEYEVENTF_KEYUP | KEYEVENTF_EXTENDEDKEY;
    ++count;
  }
  ::SendInput(count, inputs, static_cast<int>(sizeof(INPUT)));
}

LRESULT CALLBACK LockdownChannel::KeyboardProc(int code, WPARAM wparam,
                                               LPARAM lparam) {
  if (code == HC_ACTION) {
    const auto* key = reinterpret_cast<const KBDLLHOOKSTRUCT*>(lparam);
    const DWORD vk = key->vkCode;
    const bool alt = (key->flags & LLKHF_ALTDOWN) != 0;
    const bool ctrl = (::GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
    bool block = false;
    const bool key_up = wparam == WM_KEYUP || wparam == WM_SYSKEYUP;
    const bool injected = (key->flags & LLKHF_INJECTED) != 0;
    switch (vk) {
      case VK_LWIN:
      case VK_RWIN:
        // Start menu, Win+D, Win+Tab, Win+Shift+S, ... A synthesized key-up
        // (ReleaseHeldWinKeys: Win was held when the hook was installed)
        // must reach Windows, or it keeps the key "down".
        block = !(key_up && injected);
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
        ReinstallKeyboardHook();
      }
      break;  // let Flutter see it too
    case kTerminateDoneMessage: {
      std::unique_ptr<TerminateJob> job(reinterpret_cast<TerminateJob*>(lparam));
      if (job && job->result) {
        job->result->Success(flutter::EncodableValue(std::move(job->list)));
      }
      return 0;
    }
    case WM_ENDSESSION:
      // Sign-out / shutdown while locked: leave the account as it was.
      if (wparam) RestoreSystemPolicies();
      break;
    case WM_WINDOWPOSCHANGING:
      // Kiosk: the window always covers its whole monitor. Without this the
      // startup options of window_manager (size 1366x820, centre) or the shell
      // can move it after EnterKiosk — the exam header slid off the top edge
      // and the desktop showed through a strip at the bottom.
      if (kiosk_ && !::IsIconic(hwnd)) {
        auto* pos = reinterpret_cast<WINDOWPOS*>(lparam);
        HMONITOR monitor = ::MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY);
        MONITORINFO info{};
        info.cbSize = sizeof(info);
        if (pos && ::GetMonitorInfo(monitor, &info)) {
          const RECT& r = info.rcMonitor;
          pos->x = r.left;
          pos->y = r.top;
          pos->cx = r.right - r.left;
          pos->cy = r.bottom - r.top;
          pos->flags &= ~(SWP_NOMOVE | SWP_NOSIZE);
        }
      }
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
          // Explorer restarted (new taskbar window) or something showed it.
          SetTaskbarsVisible(false);
          // Take the foreground back (works because our process owned it last;
          // Windows may only flash the taskbar otherwise).
          ::ShowWindow(hwnd, SW_RESTORE);
          ::SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
                         SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
          ::SetForegroundWindow(hwnd);
        }
        return 0;
      }
      if (wparam == kHookTimerId) {
        ReinstallKeyboardHook();
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
// Marker file format, one line per saved item (UTF-8):
//   R|<subkey>|<value name>|<1 = existed, 0 = absent>|<REG_* type>|<hex data>
//   A|<STICKY|FILTER|TOGGLE>|<original dwFlags>
// Desktop 1.0.2 wrote "<subkey>|<value name>|<existed>|<DWORD>" lines; they
// are still restored (as REG_DWORD).

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
  // An empty / truncated one saved nothing and is replaced.
  bool have_marker = false;
  std::string existing;
  if (::GetFileAttributesW(path.c_str()) != INVALID_FILE_ATTRIBUTES) {
    have_marker =
        !ReadWholeFile(path, &existing) || MarkerHasRegistryLines(existing);
  }
  if (!have_marker) {
    std::string content;
    for (const auto& p : kPolicies) {
      // Any type: a pre-existing value of another type is restored as it was
      // (never deleted, never turned into a DWORD).
      DWORD type = REG_NONE;
      DWORD size = 0;
      const DWORD flags = RRF_RT_ANY | RRF_NOEXPAND;
      LSTATUS status = ::RegGetValueW(HKEY_CURRENT_USER, p.subkey, p.name,
                                      flags, &type, nullptr, &size);
      bool existed = status == ERROR_SUCCESS;
      std::vector<BYTE> data;
      if (existed && size > 0) {
        data.resize(size);
        status = ::RegGetValueW(HKEY_CURRENT_USER, p.subkey, p.name, flags,
                                &type, data.data(), &size);
        if (status != ERROR_SUCCESS) return;  // cannot save it: change nothing
        data.resize(size);
      }
      // Already the locked value without a marker: most likely left by a run
      // whose marker was lost. Recorded as originally absent, so the restore
      // deletes it instead of keeping the PC locked down.
      if (existed && type == REG_DWORD && data.size() == sizeof(DWORD)) {
        DWORD current = 0;
        std::memcpy(&current, data.data(), sizeof(current));
        if (current == p.locked_value) {
          existed = false;
          data.clear();
        }
      }
      content += "R|" + WideToUtf8(p.subkey) + "|" + WideToUtf8(p.name) + "|" +
                 (existed ? "1" : "0") + "|" +
                 std::to_string(existed ? type : 0) + "|" + ToHex(data) + "\n";
    }
    content += AccessibilityMarkerLines();
    if (!WriteWholeFile(path, content, L"wb")) {
      ::DeleteFileW(path.c_str());
      return;
    }
  } else if (!existing.empty() &&
             existing.find("A|STICKY|") == std::string::npos) {
    // Marker of desktop 1.0.2 (no accessibility lines): add the current
    // flags, which that version never changed.
    WriteWholeFile(path, AccessibilityMarkerLines(), L"ab");
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
                     reinterpret_cast<const BYTE*>(&value),
                     static_cast<DWORD>(sizeof(value)));
    ::RegCloseKey(key);
  }
  DisableAccessibilityHotkeys();
  policies_applied_ = true;
  BroadcastPolicyChange();
}

void LockdownChannel::RestoreSystemPolicies() {
  RestorePoliciesFromMarker();
  policies_applied_ = false;
  BroadcastPolicyChange();
}

void LockdownChannel::RestoreSystemState(bool notify_shell) {
  RestorePoliciesFromMarker();
  SetTaskbarsVisible(true);
  if (notify_shell) {
    DWORD_PTR ignored = 0;
    ::SendMessageTimeoutW(HWND_BROADCAST, WM_SETTINGCHANGE, 0,
                          reinterpret_cast<LPARAM>(L"Policy"),
                          SMTO_ABORTIFHUNG, 1000, &ignored);
  }
}

void LockdownChannel::RestoreAfterCrash() {
  static std::atomic<bool> done{false};
  if (done.exchange(true)) return;
  SetTaskbarsVisible(true);  // first: needs no allocation
  RestorePoliciesFromMarker();
}

void LockdownChannel::RestorePoliciesFromMarker() {
  const std::wstring path = PolicyMarkerPath();
  if (path.empty()) return;
  std::string content;
  if (!ReadWholeFile(path, &content)) return;  // nothing saved = nothing changed

  if (!MarkerHasRegistryLines(content)) {
    // Empty / truncated marker (the write never completed): the originals
    // are unknown, so only values that hold the locked value are removed.
    DeleteLockedValues();
  }

  bool all_ok = true;
  size_t start = 0;
  while (start < content.size()) {
    size_t end = content.find('\n', start);
    if (end == std::string::npos) end = content.size();
    std::string line = content.substr(start, end - start);
    start = end + 1;
    if (!line.empty() && line.back() == '\r') line.pop_back();
    if (line.empty()) continue;
    const std::vector<std::string> f = SplitFields(line);

    if (f[0] == "A") {
      // A|<feature>|<flags>
      if (f.size() < 3) continue;
      const DWORD flags =
          static_cast<DWORD>(std::strtoul(f[2].c_str(), nullptr, 10));
      DWORD current = 0;
      if (GetAccessFlags(f[1], &current) && current != flags &&
          !SetAccessFlags(f[1], flags)) {
        all_ok = false;
      }
      continue;
    }

    std::wstring subkey;
    std::wstring name;
    bool existed = false;
    DWORD type = REG_DWORD;
    std::vector<BYTE> data;
    if (f[0] == "R") {
      // R|subkey|name|existed|type|hex
      if (f.size() < 6) continue;
      subkey = Utf8ToWide(f[1]);
      name = Utf8ToWide(f[2]);
      existed = f[3] == "1";
      type = static_cast<DWORD>(std::strtoul(f[4].c_str(), nullptr, 10));
      if (existed && !FromHex(f[5], &data)) {
        all_ok = false;  // unreadable: keep the marker, touch nothing
        continue;
      }
    } else {
      // Desktop 1.0.2: subkey|name|existed|DWORD
      if (f.size() < 4) continue;
      subkey = Utf8ToWide(f[0]);
      name = Utf8ToWide(f[1]);
      existed = f[2] == "1";
      const DWORD value =
          static_cast<DWORD>(std::strtoul(f[3].c_str(), nullptr, 10));
      const BYTE* bytes = reinterpret_cast<const BYTE*>(&value);
      data.assign(bytes, bytes + sizeof(value));
    }
    if (subkey.empty() || name.empty()) continue;

    LSTATUS status;
    if (existed) {
      HKEY key = nullptr;
      status = ::RegCreateKeyExW(HKEY_CURRENT_USER, subkey.c_str(), 0, nullptr,
                                 0, KEY_SET_VALUE, nullptr, &key, nullptr);
      if (status == ERROR_SUCCESS) {
        status = ::RegSetValueExW(key, name.c_str(), 0, type,
                                  data.empty() ? nullptr : data.data(),
                                  static_cast<DWORD>(data.size()));
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
