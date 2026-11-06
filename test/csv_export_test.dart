import 'package:flutter_test/flutter_test.dart';
import 'package:xfavorites/models/x_account.dart';
import 'package:xfavorites/services/csv_export.dart';

void main() {
  group('CsvExport', () {
    test('giữ đúng 7 cột và không ghi open_count', () {
      const account = XAccount(
        username: 'artist1',
        link: 'https://x.com/artist1',
        favorite: true,
        folder: 'Art',
        openCount: 42,
        lastOpened: null,
      );

      final csv = CsvExport.toCsvString([account]);
      final lines = csv.trim().split('\n');

      expect(lines.length, 2);
      expect(lines.first, CsvExport.columns.join(','));
      expect(lines.first.split(',').length, 7);
      expect(csv.contains('open_count'), isFalse);
      expect(csv.contains('42'), isFalse);
    });

    test('last_opened không nằm trong CSV', () {
      final account = XAccount(
        username: 'artist1',
        link: 'https://x.com/artist1',
        lastOpened: DateTime.utc(2026, 1, 2),
        openCount: 5,
      );

      final csv = CsvExport.toCsvString([account]);
      expect(csv.contains('last_opened'), isFalse);
      expect(csv.contains('2026-01-02'), isFalse);
    });
  });
}
