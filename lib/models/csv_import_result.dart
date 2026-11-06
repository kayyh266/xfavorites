/// Kết quả nhập CSV: số lượng mới thêm, cập nhật và bỏ qua (trùng).
class CsvImportResult {
  final int added;
  final int updated;
  final int skipped;

  const CsvImportResult({
    required this.added,
    required this.updated,
    required this.skipped,
  });

  int get total => added + updated + skipped;

  /// Thông báo hiển thị người dùng sau khi nhập.
  String get message => 'Thêm $added mới, cập nhật $updated, bỏ qua $skipped trùng';
}
