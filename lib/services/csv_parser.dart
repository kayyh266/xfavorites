import 'dart:convert';
import 'dart:typed_data';

/// Phân tích file CSV theo định dạng yêu cầu:
/// username,link,favorite,folder,status,added_at,last_seen_following
///
/// Hỗ trợ:
/// - BOM UTF-8 (EF BB BF) ở đầu file, cả dạng byte lẫn ký tự U+FEFF.
/// - Tự nhận dấu phân cách `,` hoặc `;` hoặc tab dựa trên dòng tiêu đề.
/// - Trường có xuống dòng bên trong cặp nháy kép.
/// - Thiếu cột (chỉ có username,link hoặc thiếu cột nào) -> để trống/mặc định.
/// - Dòng trống được bỏ qua.
/// - Username có @ được chấp nhận và tự bỏ @.
/// - Nếu thiếu link thì tự sinh https://x.com/<username>.
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

    // Loại bỏ BOM UTF-8 nếu có (U+FEFF).
    String data = content;
    if (data.startsWith('\uFEFF')) {
      data = data.substring(1);
    }
    if (data.isEmpty) return [];

    // Tự nhận dấu phân cách dựa trên dòng tiêu đề.
    final delimiter = _detectDelimiter(data);

    // Phân tích toàn bộ nội dung (có thể có xuống dòng bên trong nháy kép).
    final allRows = _parseRows(data, delimiter);
    if (allRows.isEmpty) return [];

    // Bỏ các dòng trống ở đầu file.
    int headerRowIndex = 0;
    while (headerRowIndex < allRows.length && _isBlankRow(allRows[headerRowIndex])) {
      headerRowIndex++;
    }
    if (headerRowIndex >= allRows.length) return [];

    final headerRow = allRows[headerRowIndex];
    final normalizedHeaders =
        headerRow.map((h) => h.replaceAll('\uFEFF', '').trim().toLowerCase()).toList();
    if (normalizedHeaders.isEmpty) return [];

    // Cột username là bắt buộc. Nếu tiêu đề không ghi rõ, coi cột đầu tiên là username.
    final usernameIndex = normalizedHeaders.indexOf('username');
    final usernameColumn = usernameIndex >= 0 ? usernameIndex : 0;

    // Xác định chỉ số của từng cột tiêu chuẩn. Nếu thiếu cột thì chỉ số = -1.
    final Map<String, int> columnIndex = {};
    for (final col in standardColumns) {
      columnIndex[col] = normalizedHeaders.indexOf(col);
    }

    final List<Map<String, String>> rows = [];

    for (int i = headerRowIndex + 1; i < allRows.length; i++) {
      final values = allRows[i];
      if (_isBlankRow(values)) continue;

      String valueAt(String column) {
        final idx = columnIndex[column];
        if (idx == null || idx < 0 || idx >= values.length) return '';
        return values[idx].trim();
      }

      // Username: bỏ mọi ký tự @ ở đầu.
      final rawUsername = values[usernameColumn].trim().replaceFirst(RegExp(r'^@+'), '');
      final username = rawUsername.replaceAll('\uFEFF', '').trim();

      final linkFromCsv = valueAt('link');
      final link = linkFromCsv.isNotEmpty
          ? linkFromCsv
          : (username.isEmpty ? '' : 'https://x.com/$username');

      final row = <String, String>{
        'username': username,
        'link': link,
        'favorite': valueAt('favorite'),
        'folder': valueAt('folder'),
        'status': valueAt('status'),
        'added_at': valueAt('added_at'),
        'last_seen_following': valueAt('last_seen_following'),
      };

      rows.add(row);
    }

    return rows;
  }

  /// Đọc file CSV từ danh sách byte (ví dụ từ file_picker) và phân tích.
  /// Tự động bỏ BOM byte (EF BB BF) và giải mã UTF-8 kể cả khi có byte lỗi.
  static List<Map<String, String>> parseBytes(Uint8List bytes) {
    if (bytes.isEmpty) return [];

    final hasUtf8Bom =
        bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF;
    final data = hasUtf8Bom ? bytes.sublist(3) : bytes;
    if (data.isEmpty) return [];

    final content = utf8.decode(data, allowMalformed: true);
    return parse(content);
  }

  /// Nhận dấu phân cách dựa trên dòng tiêu đề đầu tiên.
  static String _detectDelimiter(String data) {
    final firstLineEnd = data.indexOf(RegExp(r'[\r\n]'));
    final headerLine = firstLineEnd >= 0 ? data.substring(0, firstLineEnd) : data;

    int countChar(String ch) => ch.allMatches(headerLine).length;

    final counts = <String, int>{
      ',': countChar(','),
      ';': countChar(';'),
      '\t': countChar('\t'),
    };

    String best = ',';
    int bestCount = 0;
    counts.forEach((delimiter, count) {
      if (count > bestCount) {
        best = delimiter;
        bestCount = count;
      }
    });
    return best;
  }

  /// Phân tích toàn bộ nội dung CSV thành danh sách các hàng.
  /// Xử lý đúng trường có xuống dòng bên trong cặp nháy kép.
  static List<List<String>> _parseRows(String data, String delimiter) {
    final List<List<String>> rows = [];
    List<String> row = <String>[];
    final StringBuffer field = StringBuffer();
    bool inQuotes = false;
    int i = 0;

    while (i < data.length) {
      final ch = data[i];

      if (inQuotes) {
        if (ch == '"') {
          // Hai nháy kép liên tiếp ("") = một dấu nháy kép thực tế trong trường.
          if (i + 1 < data.length && data[i + 1] == '"') {
            field.write('"');
            i += 2;
            continue;
          }
          inQuotes = false;
          i++;
          continue;
        }
        field.write(ch);
        i++;
        continue;
      }

      if (ch == '"') {
        inQuotes = true;
        i++;
      } else if (ch == delimiter) {
        row.add(field.toString());
        field.clear();
        i++;
      } else if (ch == '\r' || ch == '\n') {
        // Gộp \r\n thành một lần xuống dòng.
        if (ch == '\r' && i + 1 < data.length && data[i + 1] == '\n') {
          i++;
        }
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
        i++;
      } else {
        field.write(ch);
        i++;
      }
    }

    // Dòng cuối cùng (file không kết thúc bằng ký tự xuống dòng).
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }

    return rows;
  }

  static bool _isBlankRow(List<String> row) {
    for (final value in row) {
      if (value.trim().isNotEmpty) return false;
    }
    return true;
  }
}
