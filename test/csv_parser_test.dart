import 'package:flutter_test/flutter_test.dart';
import 'package:xfavorites/services/csv_parser.dart';

void main() {
  group('CsvParser', () {
    test('phân tích đúng CSV đầy đủ 7 cột', () {
      const csv = '''username,link,favorite,folder,status,added_at,last_seen_following
artist1,https://x.com/artist1,true,Art,active,2026-01-01T00:00:00Z,2026-01-02T00:00:00Z
artist2,https://x.com/artist2,false,,unfollowed,2026-01-03T00:00:00Z,''';

      final rows = CsvParser.parse(csv);

      expect(rows.length, 2);
      expect(rows[0]['username'], 'artist1');
      expect(rows[0]['link'], 'https://x.com/artist1');
      expect(rows[0]['favorite'], 'true');
      expect(rows[0]['folder'], 'Art');
      expect(rows[0]['status'], 'active');
      expect(rows[1]['username'], 'artist2');
      expect(rows[1]['folder'], '');
      expect(rows[1]['status'], 'unfollowed');
    });

    test('loại bỏ BOM UTF-8 ở đầu file', () {
      const csv = '\uFEFFusername,link\nartist1,https://x.com/artist1\n';

      final rows = CsvParser.parse(csv);

      expect(rows.length, 1);
      expect(rows[0]['username'], 'artist1');
      expect(rows[0]['link'], 'https://x.com/artist1');
    });

    test('chỉ có hai cột username,link (thiếu cột khác) vẫn nhập được', () {
      const csv = 'username,link\nartist1,https://x.com/artist1\nartist2,https://x.com/artist2\n';

      final rows = CsvParser.parse(csv);

      expect(rows.length, 2);
      expect(rows[0]['username'], 'artist1');
      expect(rows[0]['link'], 'https://x.com/artist1');
      expect(rows[0]['favorite'], '');
      expect(rows[0]['folder'], '');
      expect(rows[0]['status'], '');
      expect(rows[0]['added_at'], '');
      expect(rows[0]['last_seen_following'], '');
    });

    test('bỏ qua dòng trống', () {
      const csv = 'username,link\nartist1,https://x.com/artist1\n\n\nartist2,https://x.com/artist2\n';

      final rows = CsvParser.parse(csv);

      expect(rows.length, 2);
    });

    test('chấp nhận username có ký tự @ đằng trước', () {
      const csv = 'username,link\n@artist1,https://x.com/artist1\n';

      final rows = CsvParser.parse(csv);

      expect(rows.length, 1);
      expect(rows[0]['username'], '@artist1');
    });

    test('trả về danh sách rỗng khi nội dung trống', () {
      final rows = CsvParser.parse('');

      expect(rows.isEmpty, true);
    });

    test('trả về danh sách rỗng khi chỉ có tiêu đề', () {
      final rows = CsvParser.parse('username,link,favorite,folder,status,added_at,last_seen_following');

      expect(rows.isEmpty, true);
    });

    test('xử lý trường chứa dấu phẩy được bọc bởi nháy kép', () {
      const csv = 'username,link\nartist1,"https://x.com/artist1, extra"\n';

      final rows = CsvParser.parse(csv);

      expect(rows.length, 1);
      expect(rows[0]['link'], 'https://x.com/artist1, extra');
    });

    test('xử lý nháy kép đôi trong trường ("")', () {
      const csv = 'username,link\nartist1,"https://x.com/artist1""test"\n';

      final rows = CsvParser.parse(csv);

      expect(rows.length, 1);
      expect(rows[0]['link'], 'https://x.com/artist1"test');
    });
  });
}
