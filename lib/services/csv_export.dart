import 'dart:convert';
import 'dart:typed_data';
import '../models/x_account.dart';

/// Chuẩn bị dữ liệu xuất CSV và mã hóa UTF-8 có BOM (để Excel mở không lỗi font).
class CsvExport {
  CsvExport._();

  /// Các tên cột tiêu chuẩn (thứ tự theo định dạng yêu cầu).
  static const List<String> columns = [
    'username',
    'link',
    'favorite',
    'folder',
    'status',
    'added_at',
    'last_seen_following',
  ];

  /// Chuyển một giá trị sang chuỗi CSV (bọc bởi nháy kép nếu chứa dấu phẩy, nháy kép, hoặc xuống dòng).
  static String _csvValue(String value) {
    final needsQuotes = value.contains(RegExp(r'[,"\n\r]'));
    if (!needsQuotes) return value;
    // Thoát nháy kép bằng cách đôi nó ("")
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// Chuyển danh sách tài khoản thành chuỗi CSV (không bao gồm BOM).
  static String toCsvString(List<XAccount> accounts) {
    final StringBuffer sb = StringBuffer();

    // Ghi dòng tiêu đề.
    sb.writeln(columns.join(','));

    for (final acc in accounts) {
      final List<String> row = [
        _csvValue(acc.username),
        _csvValue(acc.link),
        _csvValue(acc.favorite ? 'true' : 'false'),
        _csvValue(acc.folder ?? ''),
        _csvValue(acc.status),
        _csvValue(acc.addedAt?.toIso8601String() ?? ''),
        _csvValue(acc.lastSeenFollowing?.toIso8601String() ?? ''),
      ];
      sb.writeln(row.join(','));
    }

    return sb.toString();
  }

  /// Mã hóa chuỗi CSV thành byte UTF-8 có BOM (EF BB BF).
  static Uint8List toUtf8WithBom(String csvString) {
    final bom = const [0xEF, 0xBB, 0xBF];
    final body = utf8.encode(csvString);
    final result = Uint8List(bom.length + body.length);
    result.setRange(0, bom.length, bom);
    result.setRange(bom.length, bom.length + body.length, body);
    return result;
  }
}
