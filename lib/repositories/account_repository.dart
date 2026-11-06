import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';
import '../models/x_account.dart';
import '../models/csv_import_result.dart';
import '../services/csv_parser.dart';
import '../services/csv_export.dart';
import '../core/constants.dart';

/// Repository trung gian giữa DatabaseHelper và các Provider/UI.
///
/// Tách logic nghiệp vụ (nhập/xuất CSV, tìm kiếm, lọc, sắp xếp, folder, v.v.)
/// ra khỏi giao diện. Đây là lớp duy nhất gọi trực tiếp DatabaseHelper.
class AccountRepository extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<XAccount> _allAccounts = [];
  List<String> _folders = [];

  // Trạng thái lọc / tìm kiếm / sắp xếp.
  String? _selectedFolder;
  String _searchQuery = '';
  String _sortMode = AppConstants.sortAz;

  // Chế độ chọn nhiều.
  final Set<int> _selectedIds = {};
  bool _selectionMode = false;

  AccountRepository() {
    _load();
  }

  // =========================================================================
  // Getter
  // =========================================================================

  List<XAccount> get allAccounts => List.unmodifiable(_allAccounts);

  List<String> get folders => List.unmodifiable(_folders);

  String? get selectedFolder => _selectedFolder;

  String get searchQuery => _searchQuery;

  String get sortMode => _sortMode;

  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);

  bool get selectionMode => _selectionMode;

  /// Danh sách tài khoản đã được lọc theo folder, tìm kiếm và sắp xếp.
  List<XAccount> get filteredAccounts {
    var result = _allAccounts.where((acc) {
      // Lọc folder
      if (_selectedFolder != null) {
        if (_selectedFolder == AppConstants.folderUncategorized) {
          if (acc.folder != null && acc.folder!.isNotEmpty) return false;
        } else {
          if (acc.folder != _selectedFolder) return false;
        }
      }

      // Lọc tìm kiếm (theo username)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!acc.username.toLowerCase().contains(q)) return false;
      }

      return true;
    }).toList();

    // Sắp xếp
    switch (_sortMode) {
      case AppConstants.sortAz:
        result.sort((a, b) => XAccount.normalizeUsername(a.username)
            .compareTo(XAccount.normalizeUsername(b.username)));
        break;
      case AppConstants.sortNewest:
        result.sort((a, b) {
          final da = a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da); // mới nhất trước
        });
        break;
      case AppConstants.sortFavoritesFirst:
        result.sort((a, b) {
          if (a.favorite == b.favorite) {
            return XAccount.normalizeUsername(a.username)
                .compareTo(XAccount.normalizeUsername(b.username));
          }
          return a.favorite ? -1 : 1; // yêu thích trước
        });
        break;
    }

    return result;
  }

  /// Số lượng yêu thích.
  int get favoriteCount => _allAccounts.where((a) => a.favorite).length;

  /// Số lượng chưa phân loại.
  int get uncategorizedCount {
    return _allAccounts.where((a) => a.folder == null || a.folder!.isEmpty).length;
  }

  // =========================================================================
  // Tải dữ liệu ban đầu
  // =========================================================================

  Future<void> _load() async {
    _allAccounts = await _db.getAccounts();
    _folders = await _db.getFolders();
    notifyListeners();
  }

  /// Tải lại dữ liệu từ CSDL (sau khi có thay đổi lớn).
  Future<void> reload() async {
    await _load();
  }

  // =========================================================================
  // Lọc / tìm kiếm / sắp xếp
  // =========================================================================

  void setFolderFilter(String? folder) {
    _selectedFolder = folder;
    _clearSelection();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _clearSelection();
    notifyListeners();
  }

  void setSortMode(String mode) {
    _sortMode = mode;
    notifyListeners();
  }

  // =========================================================================
  // Tài khoản: thêm, sửa, xóa
  // =========================================================================

  Future<void> addAccount(XAccount account) async {
    await _db.insertAccount(account);
    await reload();
  }

  Future<void> updateAccount(XAccount account) async {
    await _db.updateAccount(account);
    await reload();
  }

  Future<void> deleteAccount(int id) async {
    await _db.deleteAccount(id);
    _selectedIds.remove(id);
    if (_selectedIds.isEmpty) _selectionMode = false;
    await reload();
  }

  Future<void> deleteAccounts(List<int> ids) async {
    await _db.deleteAccounts(ids);
    _selectedIds.removeWhere(ids.contains);
    if (_selectedIds.isEmpty) _selectionMode = false;
    await reload();
  }

  Future<void> setFavorite(int id, bool favorite) async {
    await _db.setFavorite(id, favorite);
    await reload();
  }

  Future<void> toggleFavorite(int id) async {
    final acc = _allAccounts.firstWhereOrNull((a) => a.id == id);
    if (acc == null) return;
    await _db.setFavorite(id, !acc.favorite);
    await reload();
  }

  Future<void> setFolderForAccount(int id, String? folder) async {
    await _db.setFolder(id, folder);
    await reload();
  }

  Future<void> setFolderForAccounts(List<int> ids, String? folder) async {
    await _db.setFolderForAccounts(ids, folder);
    _clearSelection();
    await reload();
  }

  // =========================================================================
  // Đánh dấu đã mở / chưa mở
  // =========================================================================

  Future<void> markOpened(int id) async {
    await _db.markOpened(id);
    await reload();
  }

  Future<void> unmarkOpened(int id) async {
    await _db.unmarkOpened(id);
    await reload();
  }

  bool isOpened(int id) {
    final acc = _allAccounts.firstWhereOrNull((a) => a.id == id);
    return acc?.lastOpened != null;
  }

  // =========================================================================
  // Folder
  // =========================================================================

  Future<bool> addFolder(String name) async {
    final success = await _db.addFolder(name);
    if (success) {
      await reload();
    }
    return success;
  }

  Future<void> renameFolder(String oldName, String newName) async {
    await _db.renameFolder(oldName, newName);
    await reload();
  }

  Future<void> deleteFolder(String name) async {
    await _db.deleteFolder(name);
    await reload();
  }

  Future<int> countFolder(String? folder) async {
    if (folder == null || folder == AppConstants.folderUncategorized) {
      return uncategorizedCount;
    }
    return _allAccounts.where((a) => a.folder == folder).length;
  }

  // =========================================================================
  // Chọn nhiều
  // =========================================================================

  void toggleSelection(int id) {
    if (!_selectionMode) {
      _selectionMode = true;
    }
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    if (_selectedIds.isEmpty) _selectionMode = false;
    notifyListeners();
  }

  void selectAllVisible() {
    _selectionMode = true;
    for (final acc in filteredAccounts) {
      _selectedIds.add(acc.id!);
    }
    notifyListeners();
  }

  void clearSelection() {
    _clearSelection();
    notifyListeners();
  }

  void _clearSelection() {
    _selectedIds.clear();
    _selectionMode = false;
  }

  void exitSelectionMode() {
    if (_selectionMode) {
      _selectionMode = false;
      _selectedIds.clear();
      notifyListeners();
    }
  }

  // =========================================================================
  // Nhập CSV
  // =========================================================================

  /// Chọn file CSV bằng file_picker, phân tích và nhập vào CSDL.
  /// Trả về kết quả nhập để hiển thị thông báo.
  Future<CsvImportResult> importCsvFromPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.bytes == null) {
      return const CsvImportResult(added: 0, updated: 0, skipped: 0);
    }

    final bytes = result.files.single.bytes! as Uint8List;
    final rows = CsvParser.parseBytes(bytes);
    final importResult = await _db.importFromCsv(rows);
    await reload();
    return importResult;
  }

  /// Nhập CSV từ dữ liệu bytes (dùng cho kéo thả trên desktop).
  Future<CsvImportResult> importCsvFromBytes(Uint8List bytes) async {
    final rows = CsvParser.parseBytes(bytes);
    final importResult = await _db.importFromCsv(rows);
    await reload();
    return importResult;
  }

  // =========================================================================
  // Xuất CSV
  // =========================================================================

  /// Xuất tất cả tài khoản ra file CSV (UTF-8 có BOM).
  /// Trả về đường dẫn file đã lưu.
  Future<String> exportCsvToFile() async {
    final accounts = _allAccounts;
    final csvString = CsvExport.toCsvString(accounts);
    final bytes = CsvExport.toUtf8WithBom(csvString);

    // Lưu vào thư mục tài liệu của ứng dụng.
    Directory dir = await getApplicationDocumentsDirectory();
    final fileName = 'xfavorites_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Trả về byte CSV UTF-8 BOM (dùng nếu muốn chia sẻ / lưu khác).
  Uint8List exportCsvBytes() {
    final csvString = CsvExport.toCsvString(_allAccounts);
    return CsvExport.toUtf8WithBom(csvString);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
