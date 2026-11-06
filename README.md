# X Favorites

Ứng dụng quản lý danh sách tài khoản X (Twitter) yêu thích, chạy trên **Windows (.exe)** và **Android (.apk)** từ cùng một codebase Flutter (Dart). Giao diện tiếng Việt, Material 3, lưu cục bộ SQLite.

## Cấu trúc thư mục

```
xfavorites/
├── android/app/src/main/AndroidManifest.xml      # Quyền Android, package com.example.xfavorites
├── lib/
│   ├── main.dart                                  # Điểm vào
│   ├── app.dart                                   # MaterialApp, theme, i18n
│   ├── core/
│   │   ├── constants.dart                         # Hằng số (packageId, folder, status...)
│   │   └── app_theme.dart                         # Theme sáng/tối Material 3
│   ├── models/
│   │   ├── x_account.dart                         # Mô hình tài khoản X
│   │   └── csv_import_result.dart                 # Kết quả nhập CSV
│   ├── database/
│   │   └── database_helper.dart                   # SQLite helper (tạo bảng, CRUD, nhập/xuất)
│   ├── repositories/
│   │   └── account_repository.dart                # Lớp nghiệp vụ (lọc, tìm, sắp xếp, folder, chọn nhiều...)
│   ├── services/
│   │   ├── csv_parser.dart                        # Phân tích CSV (BOM, thiếu cột, @, dòng trống)
│   │   └── csv_export.dart                        # Xuất CSV UTF-8 có BOM
│   ├── providers/
│   │   └── repository_provider.dart               # Riverpod providers
│   └── ui/
│       ├── pages/home_page.dart                   # Trang chính (mobile + desktop)
│       ├── widgets/
│       │   ├── account_avatar.dart                # Avatar chữ cái đầu
│       │   ├── account_list_item.dart             # Dòng tài khoản
│       │   ├── desktop_drop_viewer.dart           # Kéo thả file CSV (desktop)
│       │   └── filter_chip_row.dart               # Chip lọc folder cuộn ngang
│       └── dialogs/
│           ├── folder_dialog.dart                 # Tạo/đổi tên folder
│           └── import_result_dialog.dart          # Thông báo kết quả nhập
├── test/
│   └── csv_parser_test.dart                       # Unit test phân tích CSV
├── windows/runner/                                # Cửa sổ Windows (.exe)
│   ├── main.cpp
│   ├── flutter_window.cpp / .h
│   ├── win32_window.cpp / .h
│   ├── utils.cpp / .h
│   ├── resource.h
│   └── xfavorites.rc
├── pubspec.yaml                                   # Dependencies
└── README.md                                      # Hướng dẫn này
```

## Yêu cầu trước khi build

- Flutter SDK 3.0+ đã cài và `flutter doctor` không báo lỗi nghiêm trọng.
- Windows: C++ build tools (Visual Studio 2022 community với workload "Desktop development with C++").
- Android: Android SDK, JDK 17, một thiết bị Android hoặc emulator.
- Kéo thả file CSV trên Windows yêu cầu package `desktop_drop` (đã có trong `pubspec.yaml`).

## Bước 1: Tạo dự án Flutter (nếu chưa có)

```bash
flutter create --platforms=windows,android xfavorites
# Sau đó copy tất cả file trong lib/, test/, android/app/src/main/AndroidManifest.xml,
# windows/runner/ và pubspec.yaml vào thư mục dự án vừa tạo.
```

Hoặc nếu đã có thư mục `xfavorites/` chứa code ở trên, chỉ cần:

```bash
cd xfavorites
flutter pub get
```

## Bước 2: Cài icon app (tùy chọn)

Tạo file `app.ico` (Windows) và các icon Android, rồi chạy:

```bash
flutter pub add dev:flutter_launcher_icons
```

Thêm vào cuối `pubspec.yaml`:

```yaml
flutter_icons:
  android: "launcher_icon"
  ios: true
  windows:
    path: "app.ico"
  image_path: "assets/icon.png"
```

Chạy:

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

## Bước 3: Build Windows (.exe)

### Build release

```bash
cd xfavorites
flutter build windows --release
```

File `.exe` sẽ nằm ở:

```
build/windows/x64/runner/Release/
```

Các file chính:
- `xfavorites.exe` — ứng dụng chính
- `flutter_windows.dll`, `dart_plugin_launcher.dll`, v.v. — thư viện đi kèm

### Đóng gói thành file zip

```bash
# Trên Windows (PowerShell)
Compress-Archive -Path "build/windows/x64/runner/Release/*" -DestinationPath "XFavorites_Windows.zip"

# Hoặc chọn toàn bộ thư mục Release và nhấn chuột phải → Send to → Compressed (zipped) folder
```

### Tạo installer (tùy chọn)

Bạn có thể dùng **Inno Setup** (miễn phí) để tạo file `.exe` cài đặt:
1. Tải Inno Setup tại: https://jrsoftware.org/isinfo.php
2. Tạo script mới, chỉ đến thư mục `build/windows/x64/runner/Release/`
3. Biên dịch ra file `setup.exe`

### Phím tắt trên Windows

| Phím | Chức năng |
|------|-----------|
| Ctrl + F | Focus vào ô tìm kiếm |
| Delete | Xóa tài khoản đang chọn (hoặc đã chọn nhiều) |
| Kéo thả file `.csv` vào cửa sổ | Nhập CSV ngay lập tức |

## Bước 4: Build Android (.apk)

### Tạo keystore ký APK (nếu chưa có)

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Tạo file `key.properties`

Tạo file `android/key.properties`:

```properties
storePassword=<MẬT_KHẨ_KEYSTORE>
keyPassword=<MẬT_KHẨ_ALIAS>
keyAlias=upload
storeFile=../upload-keystore.jks
```

### Cấu hình signing trong `android/app/build.gradle`

Thêm vào cuối file `android/app/build.gradle` (trong khối `android`):

```groovy
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}

def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
```

### Build APK release

```bash
cd xfavorites
flutter build apk --release
```

File APK sẽ nằm ở:

```
build/app/outputs/flutter-apk/app-release.apk
```

### Cài lên điện thoại

1. Bật "Cài đặt từ nguồn không biết" trên điện thoại Android.
2. Chuyển file `app-release.apk` qua điện thoại (USB, email, Google Drive...).
3. Mở file APK → Cài đặt.
4. Mở app "X Favorites".

### Quyền Android đã cấu hình

- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` — chọn/lưu file CSV.
- `INTERNET` — cần để mở link trang X bằng trình duyệt ngoài.

## Cách sử dụng ứng dụng

1. **Nhập CSV**: Bấm nút "+" Nhập CSV (diện thoại) hoặc nút "Nhập CSV" trên thanh công cụ (Windows), hoặc kéo thả file `.csv` vào cửa sổ (Windows).
2. **Xem danh sách**: Mỗi dòng hiển thị avatar chữ cái đầu, @username, tên folder, huy hiệu "Không còn follow" (nếu status = unfollowed), nút sao yêu thích, nút xóa.
3. **Mở trang cá nhân**: Bấm vào dòng → mở bằng TRÌNH DUYỆT NGOÀI (không phải WebView). Dòng đã mở sẽ bị mờ nhẹ có dấu "đã xem".
4. **Yêu thích**: Bấm sao để bật/tắt. Dùng bộ lọc "Yêu thích" để chỉ xem các tài khoản yêu thích.
5. **Xóa**: Bấm nút xóa trên dòng, hoặc nhấn giữ vào dòng để vào chế độ chọn nhiều, rồi xóa hàng loạt.
6. **Folder**: Tạo/đổi tên/xóa folder từ sidebar (Windows) hoặc menu. Xóa folder không xóa tài khoản bên trong (chúng về "Chưa phân loại").
7. **Tìm kiếm**: Gõ vào ô tìm kiếm ở trên.
8. **Sắp xếp**: A-Z, mới thêm, yêu thích trước.
9. **Xuất CSV**: Bấm "Xuất CSV" để lưu file UTF-8 có BOM (Excel mở không lỗi font), dùng cho extension Chrome hoặc sao lưu.

## Lưu ý kỹ thuật

- Dữ liệu lưu cục bộ trong SQLite (thuộc thư mục tài liệu của ứng dụng), không gửi ra ngoài, không cần đăng nhập.
- CSV phải có dòng tiêu đề: `username,link,favorite,folder,status,added_at,last_seen_following`.
- Khi nhập thiếu cột, các cột còn lại sẽ được để trống/mặc định.
- File xuất ra luôn mã hóa UTF-8 có BOM (EF BB BF) để Excel nhận diện font đúng.
- Gộp nhập nhiều lần: trùng username (không phân biệt hoa thường) sẽ cập nhật status, giữ nguyên favorite/folder đã có trong app.
