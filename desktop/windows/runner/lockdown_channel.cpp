#include "lockdown_channel.h"

#include <flutter/standard_method_codec.h>
#include <tlhelp32.h>

#include <algorithm>
#include <cctype>
#include <set>

// Windows 10 2004+ (SDK 10.0.19041). Older SDKs do not define it.
#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x00000011
#endif

namespace {

constexpr UINT_PTR kRefocusTimerId = 0x4D59;  // 'MY'
constexpr UINT kRefocusDelayMs = 400;

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
           GetBoolArg(args, "kiosk", true));
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
                             bool kiosk) {
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
// Keyboard hook (blocks Win, Alt+Tab, Alt+F4, Alt+Esc, Ctrl+Esc, Alt+Space,
// PrintScreen). Ctrl+Alt+Del cannot be intercepted by design (secure attention
// sequence) — use Group Policy to hide Task Manager on the exam PCs.

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
        block = alt;  // Alt+Tab
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
        SendEvent("focus_lost");
        if (kiosk_) ::SetTimer(hwnd, kRefocusTimerId, kRefocusDelayMs, nullptr);
      } else {
        SendEvent("focus_gained");
      }
      break;  // let Flutter see it too
    case WM_DISPLAYCHANGE:
      if (kiosk_) FitToMonitor();
      SendEvent("display_changed");
      break;
    case WM_TIMER:
      if (wparam == kRefocusTimerId) {
        ::KillTimer(hwnd, kRefocusTimerId);
        if (kiosk_) {
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
  if (!channel_) return;
  flutter::EncodableMap payload{
      {flutter::EncodableValue("type"), flutter::EncodableValue(type)}};
  channel_->InvokeMethod(
      "onEvent", std::make_unique<flutter::EncodableValue>(payload));
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
  HANDLE snapshot = ::CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) return found;
  PROCESSENTRY32W entry{};
  entry.dwSize = sizeof(entry);
  if (::Process32FirstW(snapshot, &entry)) {
    do {
      const std::string name = ToLowerAscii(WideToUtf8(entry.szExeFile));
      if (wanted.count(name) && seen.insert(name).second) {
        found.push_back(name);
      }
    } while (::Process32NextW(snapshot, &entry));
  }
  ::CloseHandle(snapshot);
  return found;
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
