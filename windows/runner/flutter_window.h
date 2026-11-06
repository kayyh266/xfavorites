#ifndef FLUTTER_WINDOW_H_
#define FLUTTER_WINDOW_H_

#include <flutter_dart_project.h>
#include <flutter_windows.h>

#include <memory>

#include "win32_window.h"

// Một cửa sổ Win32 đang chạy một Flutter view kèm theo dự án Flutter.
class FlutterWindow : public Win32Window {
 public:
  FlutterWindow(HINSTANCE instance, int show_command,
                FlutterDesktopResettableRef controller);

  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  void OnSize() override;
  LRESULT MessageHandler(HWND hWnd, UINT const message,
                         WPARAM const wParam,
                         LPARAM const lParam) noexcept override;

 private:
  FlutterDesktopResettableRef controller_;
};

#endif  // FLUTTER_WINDOW_H_
