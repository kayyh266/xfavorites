import 'package:collection/collection.dart';

/// Mô hình dữ liệu cho một tài khoản X (Twitter).
///
/// Các trường khớp đúng định dạng CSV yêu cầu:
/// username, link, favorite, folder, status, added_at, last_seen_following
class XAccount {
  final int? id; // khóa chính trong SQLite (tự sinh, có thể null khi mới tạo)
  final String username; // tên người dùng, không có @
  final String link; // https://x.com/<username>
  final bool favorite; // đã đánh dấu yêu thích hay chưa
  final String? folder; // tên folder, có thể null/trống
  final String status; // 'active' hoặc 'unfollowed'
  final DateTime? addedAt; // ngày thêm (ISO 8601)
  final DateTime? lastSeenFollowing; // lần cuối thấy follow (ISO 8601)
  final DateTime? lastOpened; // lần cuối mở trang cá nhân (lưu cục bộ, không ghi CSV)

  const XAccount({
    this.id,
    required this.username,
    required this.link,
    this.favorite = false,
    this.folder,
    this.status = AppConstants.statusActive,
    this.addedAt,
    this.lastSeenFollowing,
    this.lastOpened,
  });

  /// Tạo bản sao với một số trường được thay đổi.
  XAccount copyWith({
    int? id,
    String? username,
    String? link,
    bool? favorite,
    String? folder,
    String? status,
    DateTime? addedAt,
    DateTime? lastSeenFollowing,
    DateTime? lastOpened,
    bool clearLastOpened = false,
  }) {
    return XAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      link: link ?? this.link,
      favorite: favorite ?? this.favorite,
      folder: folder ?? this.folder,
      status: status ?? this.status,
      addedAt: addedAt ?? this.addedAt,
      lastSeenFollowing: lastSeenFollowing ?? this.lastSeenFollowing,
      lastOpened: clearLastOpened ? null : lastOpened ?? this.lastOpened,
    );
  }

  /// Chuyển sang Map để lưu vào SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'link': link,
      'favorite': favorite ? 1 : 0,
      'folder': folder,
      'status': status,
      'added_at': addedAt?.toIso8601String(),
      'last_seen_following': lastSeenFollowing?.toIso8601String(),
      'last_opened': lastOpened?.toIso8601String(),
    };
  }

  /// Tạo XAccount từ Map đọc từ SQLite.
  factory XAccount.fromMap(Map<String, dynamic> map) {
    return XAccount(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      username: map['username'] ?? '',
      link: map['link'] ?? '',
      favorite: (map['favorite'] ?? 0) == 1,
      folder: map['folder'],
      status: map['status'] ?? AppConstants.statusActive,
      addedAt: map['added_at'] != null ? DateTime.tryParse(map['added_at']) : null,
      lastSeenFollowing:
          map['last_seen_following'] != null ? DateTime.tryParse(map['last_seen_following']) : null,
      lastOpened: map['last_opened'] != null ? DateTime.tryParse(map['last_opened']) : null,
    );
  }

  /// Chuẩn hóa username: xóa '@' đầu nếu có, xóa khoảng trắng, viết thường để so sánh.
  static String normalizeUsername(String username) {
    return username.trim().replaceFirst(RegExp(r'^@+'), '').toLowerCase();
  }

  /// Tên hiển thị (có @ đằng trước).
  String get displayName => '@$username';

  /// avatar chữ cái đầu (không tải ảnh từ mạng).
  String get avatarLetter {
    if (username.isEmpty) return '?';
    return username[0].toUpperCase();
  }

  /// Hai tài khoản coi là trùng nếu username (chuẩn hóa) giống nhau.
  bool isSameUser(XAccount other) {
    return normalizeUsername(username) == normalizeUsername(other.username);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is XAccount &&
            id == other.id &&
            username == other.username &&
            link == other.link &&
            favorite == other.favorite &&
            folder == other.folder &&
            status == other.status;
  }

  @override
  int get hashCode => Object.hash(
        id,
        username,
        link,
        favorite,
        folder,
        status,
      );
}
