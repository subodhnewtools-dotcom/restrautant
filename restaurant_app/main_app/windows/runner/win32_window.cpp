#include "win32_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>

#include "resource.h"

namespace {

/// Window attribute that enables dark mode window decorations.
///
/// Redefined in case the developer's machine has a Windows SDK with older
/// headers.
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20

// Shortcut to minimize boilerplate.
typedef HRESULT(WINAPI* DwmSetWindowAttributePtr)(HWND hwnd, DWORD attr,
                                                  const void* attrValue,
                                                  DWORD attrSize);

}  // namespace

Win32Window::Win32Window() = default;

Win32Window::~Win32Window() { Destroy(); }

bool Win32Window::Create(const std::wstring& title, const Point& origin,
                         const Size& size) {
  Destroy();

  WNDCLASS wnd_class = {};
  wnd_class.lpszClassName = L"Flutter_Window_Class";
  wnd_class.style = CS_HREDRAW | CS_VREDRAW;
  wnd_class.lpfnWndProc = WndProc;
  wnd_class.hInstance = GetModuleHandle(nullptr);
  wnd_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  RegisterClass(&wnd_class);

  RECT frame_rect = {origin.x, origin.y, origin.x + size.width,
                     origin.y + size.height};
  AdjustWindowRect(&frame_rect, WS_OVERLAPPEDWINDOW, FALSE);

  hwnd_ = CreateWindowExW(
      0, L"Flutter_Window_Class", title.c_str(),
      WS_OVERLAPPEDWINDOW | WS_VISIBLE, CW_USEDEFAULT, CW_USEDEFAULT,
      frame_rect.right - frame_rect.left, frame_rect.bottom - frame_rect.top,
      nullptr, nullptr, GetModuleHandle(nullptr), this);

  if (!hwnd_) {
    return false;
  }

  UpdateTheme(hwnd_);

  return OnCreate();
}

void Win32Window::Destroy() {
  OnDestroy();

  if (hwnd_) {
    DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }
  UnregisterClass(L"Flutter_Window_Class", nullptr);
}

LRESULT CALLBACK Win32Window::WndProc(HWND hwnd, UINT message, WPARAM wparam,
                                      LPARAM lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto cs = reinterpret_cast<LPCREATESTRUCT>(lparam);
    SetWindowLongPtr(hwnd, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(cs->lpCreateParams));

    auto that = static_cast<Win32Window*>(cs->lpCreateParams);
    EnableDarkMode(hwnd);
    that->hwnd_ = hwnd;
  } else if (Win32Window* that = GetThisFromHandle(hwnd)) {
    return that->MessageHandler(hwnd, message, wparam, lparam);
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd, UINT message, WPARAM wparam,
                            LPARAM lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      hwnd_ = nullptr;
      PostQuitMessage(0);
      return 0;

    case WM_DPICHANGED: {
      auto newRectSize = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;

      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                   newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

      return 0;
    }
    case WM_SIZE: {
      RECT rect = GetClientArea();
      if (child_content_ != nullptr) {
        MoveWindow(child_content_, rect.left, rect.top, rect.right - rect.left,
                   rect.bottom - rect.top, TRUE);
      }
      return 0;
    }

    case WM_ACTIVATE:
      if (child_content_ != nullptr) {
        SetFocus(child_content_);
      }
      return 0;

    case WM_DISPLAYCHANGE:
      UpdateTheme(hwnd);
      return 0;
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

Win32Window* Win32Window::GetThisFromHandle(HWND hwnd) noexcept {
  return reinterpret_cast<Win32Window*>(
      GetWindowLongPtr(hwnd, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND child_content) {
  child_content_ = child_content;
  SetParent(child_content, hwnd_);
  RECT frame_rect = GetClientArea();
  MoveWindow(child_content, frame_rect.left, frame_rect.top,
             frame_rect.right - frame_rect.left, frame_rect.bottom - frame_rect.top,
             TRUE);
}

RECT Win32Window::GetClientArea() const {
  RECT rect;
  GetClientRect(hwnd_, &rect);
  return rect;
}

HWND Win32Window::GetHandle() const { return hwnd_; }

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

bool Win32Window::OnCreate() { return true; }

void Win32Window::OnDestroy() {}

void Win32Window::UpdateTheme(HWND hwnd) {
  DWORD light_mode;
  DWORD light_mode_size = sizeof(light_mode);
  LSTATUS result = RegGetValue(HKEY_CURRENT_USER,
                               R"(\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize)",
                               R"(AppsUseLightTheme)", RRF_RT_REG_DWORD, nullptr,
                               &light_mode, &light_mode_size);

  if (result == ERROR_SUCCESS) {
    EnableDarkMode(hwnd, light_mode == 0);
  }
}

void Win32Window::EnableDarkMode(HWND hwnd, bool use_dark_mode) {
  HMODULE dwmapi = LoadLibrary("dwmapi.dll");
  if (dwmapi == nullptr) {
    return;
  }

  auto fn = reinterpret_cast<DwmSetWindowAttributePtr>(
      GetProcAddress(dwmapi, "DwmSetWindowAttribute"));
  if (fn == nullptr) {
    FreeLibrary(dwmapi);
    return;
  }

  BOOL value = use_dark_mode ? TRUE : FALSE;
  fn(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &value, sizeof(value));

  FreeLibrary(dwmapi);
}
