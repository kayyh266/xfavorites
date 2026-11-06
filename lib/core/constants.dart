/// Các hằng số dùng chung trong ứng dụng.
class AppConstants {
  AppConstants._();

  /// Tên gói ứng dụng (Android packageId).
  static const String packageId = 'com.example.xfavorites';

  /// Tên hiển thị của ứng dụng.
  static const String appName = 'X Favorites';

  /// Các giá trị status hợp lệ trong CSV / cơ sở dữ liệu.
  static const String statusActive = 'active';
  static const String statusUnfollowed = 'unfollowed';

  /// Tên folder mặc định khi tài khoản chưa được phân loại.
  static const String folderUncategorized = 'Chưa phân loại';

  /// Tên filter hiển thị.
  static const String filterAll = 'Tất cả';
  static const String filterFavorites = 'Yêu thích';
  static const String filterUncategorized = 'Chưa phân loại';

  /// Giá trị sentinel dùng trong menu chọn folder (đại diện cho null).
  static const String menuUncategorized = '__uncategorized__';

  /// Các chế độ sắp xếp.
  static const String sortAz = 'A-Z';
  static const String sortNewest = 'Mới thêm';
  static const String sortFavoritesFirst = 'Yêu thích trước';

  /// Số tài khoản mở gần đây hiển thị trên trang chủ.
  static const int recentLimit = 8;

  /// Khoảng cách tối thiểu cho vùng bấm (48dp).
  static const double minTouchSize = 48.0;

  /// Ngưỡng cửa sổ được coi là "rộng" (bố cục máy tính).
  static const double desktopBreakpoint = 900.0;
}
