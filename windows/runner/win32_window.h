#ifndef WIN32_WINDOW_H_
#define WIN32_WINDOW_H_

#include <windows.h>

#include <dwmapi.h>
#include <string>

// Một cửa sổ Win32 cơ bản có thể dùng để chạy Flutter view.
class Win32Window {
 public:
  Win32Window(HINSTANCE instance, int show_command);
  virtual ~Win32Window();

  bool CreateAndShow(const std::wstring& title, int width, int height);

  void Destroy();

  HINSTANCE GetInstance() const { return instance_; }
  HWND GetHWND() const { return hwnd_; }
  int client_width() const { return client_width_; }
  int client_height() const { return client_height_; }

 protected:
  virtual bool OnCreate();
  virtual void OnDestroy();
  virtual void OnSize();
  virtual LRESULT MessageHandler(HWND hWnd, UINT const message,
                                 WPARAM const wParam,
                                 LPARAM const lParam) noexcept;

 private:
  static LRESULT CALLBACK WndProc(HWND hWnd, UINT message,
                                  WPARAM wParam, LPARAM lParam);

  HINSTANCE instance_;
  HWND hwnd_;
  int show_command_;
  int client_width_;
  int client_height_;
  bool running_;
};

#endif  // WIN32_WINDOW_H_
