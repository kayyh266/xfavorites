#include "flutter_window.h"

#include <flutter_plugin_registrar.h>

#include "utils.h"

FlutterWindow::FlutterWindow(HINSTANCE instance, int show_command,
                             FlutterDesktopResettableRef controller)
    : Win32Window::Win32Window(instance, show_command),
      controller_(std::move(controller)) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
}

  RECT margin = {-1, -1, -1, -1};
  DwmExtendFrameIntoClientArea(GetHWND(), &margin);

  controller_->RegisterTopLevelWindow(GetHWND());

  return true;
}

void FlutterWindow::OnDestroy() {
  controller_.reset();
  Win32Window::OnDestroy();
}

void FlutterWindow::OnSize() {
  if (controller_) {
    controller_->GetView()->Resize(client_width(), client_height());
  }
}

LRESULT FlutterWindow::MessageHandler(HWND hWnd, UINT const message,
                                      WPARAM const wParam,
                                      LPARAM const lParam) noexcept {
  switch (message) {
    // Xác định việc xử lý WM_DROPFILES ở đây nếu muốn xử lý native.
    case WM_DROPFILES:
      return 0;
    default:
      return Win32Window::MessageHandler(hWnd, message, wParam, lParam);
  }
}
