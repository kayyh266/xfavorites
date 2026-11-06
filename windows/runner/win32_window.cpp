#include "win32_window.h"

#include <dwmapi.h>

#pragma comment(lib, "dwmapi.lib")

Win32Window::Win32Window(HINSTANCE instance, int show_command)
    : instance_(instance),
      hwnd_(nullptr),
      show_command_(show_command),
      client_width_(0),
      client_height_(0),
      running_(false) {}

Win32Window::~Win32Window() {
  Destroy();
}

bool Win32Window::CreateAndShow(const std::wstring& title, int width, int height) {
  WNDCLASSW wc = {};
  wc.lpfnWndProc = WndProc;
  wc.hInstance = instance_;
  wc.lpszClassName = L"XFavoritesWindowClass";
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wc.hbrBackground = CreateSolidBrush(RGB(30, 30, 30));

  if (!RegisterClassW(&wc)) {
    return false;
  }

  hwnd_ = CreateWindowW(
      wc.lpszClassName, title.c_str(), WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
      CW_USEDEFAULT, CW_USEDEFAULT, width, height, nullptr, nullptr, instance_,
      this);

  if (!hwnd_) {
    return false;
  }

  running_ = true;
  ShowWindow(hwnd_, show_command_);
  UpdateWindow(hwnd_);

  return true;
}

void Win32Window::Destroy() {
  if (hwnd_) {
    DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }
}

LRESULT CALLBACK Win32Window::WndProc(HWND hWnd, UINT message,
                                       WPARAM wParam, LPARAM lParam) {
  if (message == WM_NCCREATE) {
    auto create_struct = reinterpret_cast<CREATESTRUCTW*>(lParam);
    auto window = static_cast<Win32Window*>(create_struct->lpCreateParams);
    SetWindowLongPtrW(hWnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(window));
    window->hwnd_ = hWnd;
    return DefWindowProcW(hWnd, message, wParam, lParam);
  }

  auto window = reinterpret_cast<Win32Window*>(GetWindowLongPtrW(hWnd, GWLP_USERDATA));
  if (!window) {
    return DefWindowProcW(hWnd, message, wParam, lParam);
  }

  switch (message) {
    case WM_DESTROY:
      window->running_ = false;
      PostQuitMessage(0);
      window->OnDestroy();
      return 0;
    case WM_SIZE:
      window->client_width_ = LOWORD(lParam);
      window->client_height_ = HIWORD(lParam);
      window->OnSize();
      return 0;
    default:
      return window->MessageHandler(hWnd, message, wParam, lParam);
  }
}

LRESULT Win32Window::MessageHandler(HWND hWnd, UINT const message,
                                     WPARAM const wParam,
                                     LPARAM const lParam) noexcept {
  return DefWindowProcW(hWnd, message, wParam, lParam);
}

bool Win32Window::OnCreate() {
  return true;
}

void Win32Window::OnDestroy() {}

void Win32Window::OnSize() {}
