#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// A class abstraction for a high DPI-aware Win32 Window.
class Win32Window {
 public:
  // Point and size for the window.
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates a win32 window with |title|, |origin|, and |size|.
  bool Create(const std::wstring& title, const Point& origin, const Size& size);

  // Show the current window.
  void Show();

  // Destroy the window.
  void Destroy();

  // Sets whether the window should be closed when the user closes it.
  void SetQuitOnClose(bool quit_on_close);

  // Returns the handle of the window.
  HWND GetHandle() const;

 protected:
  // Called when the window is created.
  virtual bool OnCreate();

  // Called when the window is being destroyed.
  virtual void OnDestroy();

  // Message handler for the window.
  virtual LRESULT MessageHandler(HWND hwnd, UINT message, WPARAM wparam,
                                 LPARAM lparam) noexcept;

 private:
  // Registers a window class.
  static LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wparam,
                                  LPARAM lparam) noexcept;

  // Retrieves the instance associated with this window.
  static Win32Window* GetThisFromHandle(HWND hwnd) noexcept;

  // Updates the theme of the window.
  void UpdateTheme(HWND hwnd);

  // Enables dark mode for the window.
  void EnableDarkMode(HWND hwnd, bool use_dark_mode = true);

  // Sets the child content window.
  void SetChildContent(HWND child_content);

  // Retrieves the client area rectangle.
  RECT GetClientArea() const;

  HWND hwnd_ = nullptr;
  HWND child_content_ = nullptr;
  bool quit_on_close_ = false;
};

#endif  // RUNNER_WIN32_WINDOW_H_
