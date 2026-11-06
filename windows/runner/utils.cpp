#include "utils.h"

#include <windows.h>
#include <shellapi.h>
#include <string>
#include <vector>

std::vector<std::string> GetCommandLineArguments() {
  int argc;
  wchar_t** argv = CommandLineToArgvW(GetCommandLineW(), &argc);
  std::vector<std::string> arguments;
  if (argv != nullptr) {
    for (int i = 0; i < argc; ++i) {
      int size_needed = WideCharToMultiByte(CP_UTF8, 0, argv[i], -1, nullptr, 0,
                                            nullptr, nullptr);
      std::string str(size_needed, 0);
      WideCharToMultiByte(CP_UTF8, 0, argv[i], -1, &str[0], size_needed,
                          nullptr, nullptr);
      str.pop_back();  // Xóa ký tự null kết thúc.
      arguments.push_back(str);
    }
    LocalFree(argv);
  }
  return arguments;
}
