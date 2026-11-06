import 'dart:convert';
import 'dart:typed_data';

/// Phân tích file CSV theo định dạng yêu cầu:
/// username,link,favorite,folder,status,added_at,last_seen_following
///
/// Hỗ trợ:
/// - BOM UTF-8 (EF BB BF) ở đầu file.
/// - Thiếu cột (chỉ có username,link hoặc thiếu cột nào) -> để trống/mặc định.
/// - Dòng trống được bỏ qua.
/// - Username có @ được chấp nhận (sau khi lưu sẽ chuẩn hóa).
class CsvParser {
  CsvParser._();

  /// Các tên cột tiêu chuẩn (thứ tự theo định dạng yêu cầu).
  static const List<String> standardColumns = [
    'username',
    'link',
    'favorite',
    'folder',
    'status',
    'added_at',
    'last_seen_following',
  ];

  /// Phân tích nội dung CSV (chuỗi đã đọc từ file). Trả về danh sách các hàng (Map).
  static List<Map<String, String>> parse(String content) {
    if (content.isEmpty) return [];

    // Loại bỏ BOM UTF-8 nếu có (U+FEFF hoặc các byte EF BB BF).
    String data = content;
    if (data.startsWith('\uFEFF')) {
      data = data.substring(1);
    }

    // Chia dòng. Hỗ trợ cả \r\n (Windows), \n (Unix), \r (Mac cũ).
    final lines = data.split(RegExp(r'\r\n|\r|\n'));

    if (lines.isEmpty) return [];

    // Dòng đầu tiên là tiêu đề.
    final headerLine = lines.first.trim();
    if (headerLine.isEmpty) return [];

    final headers = _splitCsvLine(headerLine);
    // Chuẩn hóa header: xóa khoảng trắng, viết thường.
    final normalizedHeaders = headers.map((h) => h.trim().toLowerCase()).toList();

    // Xác định chỉ số của từng cột tiêu chuẩn. Nếu thiếu cột thì chỉ số = -1.
    final Map<String, int> columnIndex = {};
    for (int i = 0; i < standardColumns.length; i++) {
      columnIndex[standardColumns[i]] = normalizedHeaders.indexOf(standardColumns[i]);
    }

    final List<Map<String, String>> rows = [];

    // Bắt đầu từ dòng thứ 2 (dòng dữ liệu).
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      // Bỏ qua dòng trống.
      if (line.trim().isEmpty) continue;

      final values = _splitCsvLine(line);
      final Map<String, String> row = {};

      for (final col in standardColumns) {
        final idx = columnIndex[col];
        if (idx != null && idx != -1 && idx < values.length) {
          row[col] = values[idx].trim();
        } else {
          row[col] = ''; // thiếu cột -> để trống
        }
      }

      rows.add(row);
    }

    return rows;
  }

  /// Phân tích một dòng CSV đơn lẻ, xử lý nháy kép (") để bao trị trường chứa dấu phẩy.
  static List<String> _splitCsvLine(String line) {
    final List<String> fields = [];
    StringBuffer current = StringBuffer();
    bool inQuotes = false;
    int i = 0;

    while (i < line.length) {
      final ch = line[i];

      if (inQuotes) {
        if (ch == '"') {
          // Kiểm tra dấu nháy kép kép ("") -> là một dấu nháy kép thực tế trong trường.
          if (i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i += 2;
            continue;
          }
          inQuotes = false;
          i++;
          continue;
        }
        current.write(ch);
        i++;
      } else {
        if (ch == '"') {
          inQuotes = true;
          i++;
        } else if (ch == ',') {
          fields.add(current.toString());
          current.clear();
          i++;
        } else {
          current.write(ch);
          i++;
        }
      }
    }

    fields.add(current.toString());
    return fields;
  }

  /// Đọc file CSV từ danh sách byte (ví dụ từ file_picker) và phân tích.
  /// Tự động giải mã UTF-8 (có BOM sẽ được xử lý trong [parse]).
  static List<Map<String, String>> parseBytes(Uint8List bytes) {
    final content = utf8.decode(bytes);
    return parse(content);
  }
}
