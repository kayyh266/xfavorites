# HƯỚNG DẪN BUILD X FAVORITES TRÊN GITHUB ACTIONS
# (Không cần cài Android Studio hay Visual Studio trên máy)

Tài liệu này hướng dẫn bạn từ A-Z: tạo repo GitHub, đẩy code, cấu hình Secrets (nếu muốn ký APK), chạy build và tải file về.

---

## MỤC LỤC

1. [Yêu cầu ban đầu](#1-yêu-cầu-ban-đầu)
2. [Tạo repo GitHub私人 (private)](#2-tao-repo-github-private)
3. [Cài Git và đẩy code lên GitHub](#3-cai-git-va-day-code-len-github)
4. [Cấu hình Secrets cho ký APK (tùy chọn)](#4-cau-hinh-secrets-cho-ky-apk-tuy-chon)
5. [Chạy build thủ công trên GitHub Actions](#5-chay-build-thu-cong-tren-github-actions)
6. [Phát hành bằng tag (tự động tạo Release)](#6-phat-hanh-bang-tag-tu-dong-tao-release)
7. [Tải artifact và file Release về máy](#7-tai-artifact-va-file-release-ve-may)
8. [Cài APK lên điện thoại Android](#8-cai-apk-len-dien-thoai-android)
9. [Chạy file .exe trên Windows](#9-chay-file-exe-tren-windows)
10. [Phương án ký APK (A và B)](#10-phuong-an-ky-apk-a-va-b)
11. [Xử lý lỗi thường gặp](#11-xu-ly-loi-thuong-gap)
12. [Lưu ý chi phí GitHub Actions](#12-luu-y-chi-phi-github-actions)

---

## 1. YÊU CẦU BAN ĐẦU

Trên máy của bạn chỉ cần cài:
- **Git**: https://git-scm.com/
- Một tài khoản GitHub: https://github.com/

Không cần cài Flutter, Android Studio hay Visual Studio — tất cả sẽ chạy trên máy chủ của GitHub.

---

## 2. TẠO REPO GITHUB PRIVATE

1. Đăng nhập GitHub.
2. Nhấn vào ảnh đại diện (góc trên phải) → **Your repositories** → **New**.
3. **Repository name**: `xfavorites` (hoặc tên bạn thích).
4. Chọn **Private** (để mã nguồn không công khai).
5. Bỏ chọn "Add a README file" (vì bạn đã có code sẵn).
6. Nhấn **Create repository**.
7. Copy đường dẫn repo, ví dụ: `https://github.com/ten-ban/xfavorites.git`.

---

## 3. CÀI GIT VÀ ĐẨY CODE LÊN GITHUB

Mở **Git Bash** (hoặc CMD/PowerShell), chạy lần lượt các lệnh sau:

```bash
# 1. Di chuyển vào thư mục dự án (thư mục chứa pubspec.yaml)
cd /d D:\custo\xfavorites

# 2. Khởi tạo git repo cục bộ
git init

# 3. Đặt nhánh mặc định là main
git branch -M main

# 4. Thêm tất cả file vào staging
git add .

# 5. Commit lần đầu
git commit -m "Initial commit: X Favorites app with CI config"

# 6. Thêm remote (thay ten-ban bằng username GitHub của bạn)
git remote add origin https://github.com/ten-ban/xfavorites.git

# 7. Đẩy code lên GitHub
git push -u origin main
```

Sau khi push xong, hãy vào trang repo trên GitHub để kiểm tra xem các file `.github/workflows/build.yml`, `.gitignore`, `android/app/build.gradle` đã có chưa.

---

## 4. CẤU HÌNH SECRETS CHO KÝ APK (TÙY CHỌN)

Nếu bạn chỉ dùng **phương án A** (khóa debug mặc định), hãy bỏ qua bước này.

Nếu muốn dùng **phương án B** (ký APK bằng keystore riêng của bạn):

### 4.1 Tạo keystore trên máy của bạn

Mở terminal, chạy:

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Lưu ý:
- Mật khẩu keystore: nhớ kỹ, sẽ nhập vào GitHub Secrets.
- Mật khẩu alias (key): có thể giống hoặc khác mật khẩu keystore.
- File `upload-keystore.jks` sẽ được tạo tại thư mục hiện tại. **Đừng commit file này lên GitHub**.

### 4.2 Mã hóa keystore thành base64

Trên Windows PowerShell:

```powershell
$content = Get-Content -Path "upload-keystore.jks" -Encoding Byte
[Convert]::ToBase64String($content) | clip
```

Chuỗi base64 đã được copy vào clipboard.

### 4.3 Thêm Secrets vào GitHub

Vào repo GitHub → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**. Thêm 4 secret sau:

| Tên Secret | Giá trị |
|------------|---------|
| `KEYSTORE_BASE64` | Chuỗi base64 vừa copy từ bước 4.2 |
| `KEYSTORE_PASSWORD` | Mật khẩu keystore (bạn nhập khi chạy keytool) |
| `KEY_ALIAS` | `upload` (hoặc alias bạn chọn) |
| `KEY_PASSWORD` | Mật khẩu alias (key) |

### 4.4 Cách workflow xử lý

Trong file `android/app/build.gradle`, phần `signingConfigs.release` chỉ được bật nếu file `android/key.properties` tồn tại. Trên GitHub Actions, workflow (nếu bạn thêm bước giải mã) sẽ tạo file `key.properties` từ Secrets, sau đó Gradle sẽ ký APK release.

> Lưu ý: File `build.yml` hiện tại trong repo bạn nhận được đã bao gồm sẵn phần ghi chú cho phương án B, nhưng **không** tự động tạo `key.properties` từ Secrets để giữ workflow đơn giản. Nếu muốn bật phương án B, hãy thêm bước giải mã vào job `android` trước lệnh `flutter build apk` (xem ví dụ ở phần 10).

---

## 5. CHẠY BUILD THỦ CÔNG TRÊN GITHUB ACTIONS

1. Vào trang repo trên GitHub.
2. Chọn tab **Actions** (giao diện बीच may hiện "I understand my workflows, go ahead and enable them" — nhấn xác nhận nếu được hỏi).
3. Ở sidebar trái, chọn workflow **Build X Favorites**.
4. Nhấn nút **"Run workflow"** (màu xanh) ở bên phải.
5. Chọn nhánh `main`, rồi nhấn **Run workflow**.
6. Chờ các job `android` và `windows` chạy xong (có thể mất 5–15 phút tùy mạng và dung lượng cache).

Khi xong, bạn sẽ thấy các job có dấu xanh (✓) nếu thành công.

---

## 6. PHÁT HÀNH BẰNG TAG (TỰ ĐỘNG TẠO RELEASE)

Nếu bạn muốn GitHub tự tạo trang Release và đính kèm APK + zip Windows:

```bash
# Trên máy của bạn, trong thư mục dự án
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions sẽ phát hiện tag `v*` và chạy job `release`, tự động:
- Tạo GitHub Release có tên "Release v1.0.0"
- Đính kèm tất cả file `.apk` và `.zip`
- Bạn có thể vào trang **Releases** của repo để tải trực tiếp.

---

## 7. TẢI ARTIFACT VÀ FILE RELEASE VỀ MÁY

### Cách A: Tải từ trang Kết quả Actions (không cần tag)

1. Sau khi workflow chạy xong, vào tab **Actions**.
2. Nhấn vào chạy workflow vừa rồi (ví dụBuild #1).
3. Ở bên phải hoặc dưới cùng, tìm mục **Artifacts**:
   - `xfavorites-android-apk`: chứa các file `.apk`
   - `xfavorites-windows`: chứa file `XFavorites_Windows.zip`
4. Nhấn vào tên artifact để tải về.

### Cách B: Tải từ trang Releases (khi đã push tag)

1. Vào repo GitHub → mục **Releases** (góc phải bên dưới Code).
2. Nhấn vào bản release tương ứng (ví dụ v1.0.0).
3. Trong phần **Assets**, bạn sẽ thấy các file `.apk` và `.zip`. Nhấn để tải.

---

## 8. CÀI APK LÊN ĐIỆN THOẠI ANDROID

### 8.1 Chọn file APK thích hợp

Trong artifact `xfavorites-android-apk`, bạn sẽ thấy các file:
- `app-arm64-v8a-release.apk` — dành cho điện thoại hiện đại (64-bit, phổ biến nhất từ năm 2018 đến nay).
- `app-armeabi-v7a-release.apk` — dành cho điện thoại cũ hơn (32-bit).
- `app-x86_64-release.apk` — dành cho máy giả lập Android trên PC.
- `app-release.apk` — fat APK (tất cả kiến trúc, kích thước lớn hơn).

**Nên cài:** `app-arm64-v8a-release.apk` cho điện thoại Android phổ thông hiện nay.

### 8.2 Cài đặt

1. Chuyển file `.apk` qua điện thoại (cáp USB, Google Drive, Zalo, email...).
2. Trên điện thoại: **Cài đặt** → **Bảo mật** (hoặc **Ứng dụng**) → Bật **Cài đặt từ nguồn không xác định** (hoặc Cho phép cài từ trình duyệt/Trình quản lý file).
3. Mở file `.apk` → nhấn **Cài đặt**.
4. Mở app "X Favorites" và sử dụng.

> Lưu ý: Vì APK dùng khóa debug (phương án A), nếu bạn cài đè lên một bản đã cài trước đó mà ký bởi khóa khác, Android sẽ báo lỗi và bạn phải gỡ cài bản cũ trước khi cài bản mới.

---

## 9. CHẠY FILE .EXE TRÊN WINDOWS

1. Tải artifact `xfavorites-windows` (file `XFavorites_Windows.zip`).
2. Giải nén zip vào một thư mục trên máy, ví dụ `C:\XFavorites\`.
3. Thư mục giải nén phải chứa đầy đủ:
   - `xfavorites.exe`
   - `flutter_windows.dll`
   - `dart_plugin_launcher.dll`
   - Các file `.dll` khác
   - Thư mục `data` (chứa Flutter assets)
4. Nhấn đúp vào `xfavorites.exe` để chạy.

> **Quan trọng:** Không chỉ copy file `xfavorites.exe` đơn lẻ sang máy khác. Phải copy **toàn bộ** nội dung thư mục `Release/` (đã được nén sẵn trong zip) mới chạy được.

---

## 10. PHƯƠNG ÁN KÝ APK (A VÀ B)

### Phương án A (Mặc định, đơn giản)

- **Cách hoạt động:** Không cần keystore. Flutter build APK release dùng khóa debug mặc định.
- **Ưu điểm:** Không cần cấu hình gì, chạy ngay trên GitHub Actions.
- **Hạn chế:**
  - **Không thể đẩy lên Google Play Console** (yêu cầu keystore release riêng).
  - Cập nhật app bằng cách cài đè chỉ ổn nếu bản cũ và bản mới **dùng cùng một khóa ký** (khóa debug của Flutter thường giống nhau trên cùng một máy phát triển, nhưng nếu bạn build trên máy khác thì khóa debug có thể khác → không cài đè được, phải gỡ cài trước).
- **Dùng cho:** Sử dụng cá nhân, chia sẻ cho bạn bè, lưu trữ bản sao lưu.

### Phương án B (Tùy chọn, khóa riêng)

- **Cách hoạt động:** Bạn tạo `upload-keystore.jks`, mã hóa base64, lưu vào GitHub Secrets. Workflow giải mã ra file tạm, tạo `android/key.properties`, rồi Gradle ký APK release.
- **Ưu điểm:** APK có thể đẩy lên Google Play, có thể cập nhật cài đè qua các phiên bản sau này (vì dùng cùng keystore).
- **Hạn chế:** Phải bảo mật keystore và mật khẩu, không commit vào repo.

#### Nếu muốn bật phương án B, hãy thêm bước sau vào job `android` trong `.github/workflows/build.yml` (trước lệnh `flutter build apk`):

```yaml
      - name: Decode keystore and create key.properties
        if: env.KEYSTORE_BASE64 != ''
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > upload-keystore.jks
          cat > android/key.properties <<EOF
          storePassword=${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=../upload-keystore.jks
          EOF
```

Và đảm bảo file `android/app/build.gradle` đã được chỉnh như file tôi cung cấp ở trên (phần `if (keystorePropertiesFile.exists())`).

> **TUYỆT ĐỐI KHÔNG commit file `upload-keystore.jks`, `android/key.properties` đã điền mật khẩu, hoặc bất kỳ file keystore nào vào repo GitHub.**

---

## 11. XỬ LÝ LỖI THƯỜNG GẶP

| Lỗi | Nguyên nhân phổ biến | Cách khắc phục |
|-----|---------------------|----------------|
| `flutter: command not found` (trên máy local) | Bạn đang cố chạy flutter trên máy local mà chưa cài | CI không cần flutter trên máy local. Chỉ cần Git. Nếu muốn chạy local, cài Flutter SDK theo hướng dẫn ufficiali. |
| Lỗi `minSdkVersion` | `minSdkVersion` quá thấp, không khớp với một số plugin | Trong `android/app/build.gradle`, đảm bảo `minSdkVersion 21` (đã có trong file tôi cung cấp). |
| Lỗi giấy phép Android SDK | CI chưa chấp nhận giấy phép Android | `subosito/flutter-action` thường tự xử lý. Nếu lỗi, thêm bước `flutter doctor --android-licenses` vào workflow. |
| Workflow không thấy artifact | Job chưa chạy xong hoặc tên artifact sai | Đảm bảo tên artifact trong `upload-artifact` khớp với tên bạn tìm. Thời gian lưu mặc định 90 ngày, tôi đã đặt 30 ngày. |
| Chạy `.exe` báo thiếu `.dll` | Chỉ copy file `xfavorites.exe` đơn lẻ | Giải nén toàn bộ zip `XFavorites_Windows.zip`, chứa mọi file cần thiết. |
| Lỗi pubspec version không khớp tag | `pubspec.yaml` có `version: 1.0.0+1` nhưng bạn push tag `v2.0.0` | Đây không làm sinh lỗi build, nhưng để gọn gàng hãy cập nhật `pubspec.yaml` cho khớp với tag trước khi push. |
| `Permission denied` khi tạo Release | Job `release` không có quyền `contents: write` | Đã được cấu hình trong file `build.yml` (permissions của job release). |

---

## 12. LƯU Ý CHI PHÍ GITHUB ACTIONS

- **Repo private:** GitHub cung cấp một số phút miễn phí mỗi tháng cho Actions (thường là 2.000 phút cho tài khoản free, nhưng có thể thay đổi theo chính sách GitHub).
- **Runner Windows:** Tốn nhiều phút hơn runner Linux (Windows thường tính phí cao gấp khoảng 2 lần Ubuntu).
- **Mẹo tiết kiệm:**
  - Chỉ chạy build khi thực sự cần (dùng `workflow_dispatch` hoặc push tag).
  - Đã bật `cache: true` trong `subosito/flutter-action` để lưu Flutter SDK và dependencies, làm nhanh các lần build sau.
  - Không cần build cả Windows và Android mỗi lần nếu bạn chỉ cần một trong hai (có thể tắt job không cần bằng cách xóa job đó khỏi `build.yml`).
  - Artifacts được lưu 30 ngày (đã cấu hình), sau đó sẽ tự xóa để giải phóng lưu trữ.

---

## TÓM TẢT FILE ĐÃ TẠO

| File | Chức năng |
|------|-----------|
| `.github/workflows/build.yml` | Cấu hình GitHub Actions (build Android, Windows, tạo Release) |
| `.gitignore` | Bỏ qua build artifacts, keystore, key.properties, zip, exe |
| `android/app/build.gradle` | Cấu hình Gradle Android (minSdk, package, signing tùy chọn) |
| `android/key.properties` | Mẫu file cấu hình keystore (bị gitignore, không commit thực tế) |
| `GUIDE_CI.md` | Hướng dẫn này |

Chúc bạn build thành công! Nếu cần hỗ trợ thêm, hãy phản hồi.
