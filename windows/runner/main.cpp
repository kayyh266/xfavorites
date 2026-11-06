#include <flutter_dart_project.h>
#include <flutter_windows.h>
#include <windows.h>

#include <shlobj.h>  // DragAcceptFiles / WM_DROPFILES cho desktop_drop

#include <iostream>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Cho phép kéo thả file vào cửa sổ (dùng cho desktop_drop trên Windows).
  DragAcceptFiles(nullptr, TRUE);

  // Attach to console when present (whe created from console).
  if (::AttachConsole(ATTACH_PARENT_PROCESS)) {
    freopen("CONOUT$", "w", stdout);
    freopen("CONOUT$", "w", stderr);
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  FlutterDesktopResettableRef controller =
      FlutterDesktopCreateViewWithInitialRoute(
          "flutter_view", command_line_arguments.size(),
          command_line_arguments.data());

  FlutterWindow window(instance, show_command, std::move(controller));
  if (!window.CreateAndShow(L"X Favorites", 900, 700)) {
    return 0;
  }

  MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    // Xử lý WM_DROPFILES (kéo thả file) nếu cần
    TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return static_cast<int>(msg.wParam);
}
