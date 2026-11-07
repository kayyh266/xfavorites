import 'dart:io';
import 'package:collection/collection.dart';
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
  bool _favoritesOnly = false;
  String _searchQuery = '';
  String _sortMode = AppConstants.sortAz;

  /// Lỗi khi tải dữ liệu ban đầu (null nếu không có lỗi).
  String? _loadError;

  // Chế độ chọn nhiều.
  final Set<int> _selectedIds = {};
  bool _selectionMode = false;

  AccountRepository() {
    // Không await: lỗi được bắt bên trong _load và lưu vào _loadError.
    _load();
  }

  // =========================================================================
  // Getter
  // =========================================================================

  List<XAccount> get allAccounts => List.unmodifiable(_allAccounts);

  List<String> get folders => List.unmodifiable(_folders);

  String? get selectedFolder => _selectedFolder;

  /// Chỉ hiển thị tài khoản yêu thích hay không.
  bool get favoritesOnly => _favoritesOnly;

  String get searchQuery => _searchQuery;

  String get sortMode => _sortMode;

  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);

  bool get selectionMode => _selectionMode;

  /// Lỗi tải dữ liệu (dùng để hiển thị trên giao diện).
  String? get loadError => _loadError;

  /// Tổng số tài khoản.
  int get countAll => _allAccounts.length;

  /// Danh sách tài khoản đã được lọc theo folder, yêu thích, tìm kiếm và sắp xếp.
  List<XAccount> get filteredAccounts {
    var result = _allAccounts.where((acc) {
      // Lọc yêu thích
      if (_favoritesOnly && !acc.favorite) return false;

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

  /// Tài khoản mở gần đây, sắp theo last_opened giảm dần, tối đa [AppConstants.recentLimit].
  List<XAccount> get recentAccounts {
    final opened = _allAccounts.where((a) => a.lastOpened != null).toList()
      ..sort((a, b) => b.lastOpened!.compareTo(a.lastOpened!));
    if (opened.length > AppConstants.recentLimit) {
      return List.unmodifiable(opened.take(AppConstants.recentLimit));
    }
    return List.unmodifiable(opened);
  }

  /// Tài khoản vừa mở gần nhất (null nếu chưa mở tài khoản nào).
  XAccount? get latestOpened {
    XAccount? latest;
    for (final account in _allAccounts) {
      final openedAt = account.lastOpened;
      if (openedAt == null) continue;
      if (latest == null || openedAt.isAfter(latest.lastOpened!)) {
        latest = account;
      }
    }
    return latest;
  }

  /// Số tài khoản của từng folder thật (không gồm mục cố định).
  Map<String, int> get folderCounts {
    final counts = <String, int>{};
    for (final folder in _folders) {
      counts[folder] = 0;
    }
    for (final account in _allAccounts) {
      final folder = account.folder;
      if (folder != null && folder.isNotEmpty) {
        counts[folder] = (counts[folder] ?? 0) + 1;
      }
    }
    return counts;
  }

  // =========================================================================
  // Tải dữ liệu ban đầu
  // =========================================================================

  Future<void> _load() async {
    try {
      _allAccounts = await _db.getAccounts();
      _folders = await _db.getFolders();
      _loadError = null;
    } catch (e) {
      _loadError = 'Không thể tải dữ liệu: $e';
    }
    notifyListeners();
  }

  /// Tải lại dữ liệu từ CSDL (sau khi có thay đổi lớn).
  Future<void> reload() async {
    await _load();
  }

  // =========================================================================
  // Lọc / tìm kiếm / sắp xếp
  // =========================================================================

  /// Lọc theo folder. Đồng thời tắt lọc "chỉ yêu thích".
  void setFolderFilter(String? folder) {
    _selectedFolder = folder;
    _favoritesOnly = false;
    _clearSelection();
    notifyListeners();
  }

  /// Bật/tắt lọc "chỉ yêu thích".
  ///
  /// Khi bật, bỏ lọc folder để hiển thị toàn bộ tài khoản yêu thích.
  void setFavoritesOnly(bool value) {
    _favoritesOnly = value;
    if (value) _selectedFolder = null;
    _clearSelection();
    notifyListeners();
  }

  /// Bỏ mọi bộ lọc (Tất cả).
  void selectAll() {
    _selectedFolder = null;
    _favoritesOnly = false;
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
    final index = _allAccounts.indexWhere((a) => a.id == id);
    if (index < 0) {
      await _db.setFavorite(id, favorite);
      return;
    }

    final previous = _allAccounts[index];
    if (previous.favorite == favorite) return;

    // Cập nhật lạc quan để không phải tải lại toàn bộ danh sách.
    _allAccounts = List<XAccount>.from(_allAccounts);
    _allAccounts[index] = previous.copyWith(favorite: favorite);
    notifyListeners();

    try {
      await _db.setFavorite(id, favorite);
    } catch (_) {
      _allAccounts[index] = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleFavorite(int id) async {
    final acc = _allAccounts.firstWhereOrNull((a) => a.id == id);
    if (acc == null) return;
    await setFavorite(id, !acc.favorite);
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
    final index = _allAccounts.indexWhere((a) => a.id == id);
    if (index < 0) {
      await _db.markOpened(id);
      await reload();
      return;
    }

    final previous = _allAccounts[index];
    _allAccounts = List<XAccount>.from(_allAccounts);
    _allAccounts[index] = previous.copyWith(
      lastOpened: DateTime.now(),
      openCount: previous.openCount + 1,
    );
    notifyListeners();

    try {
      await _db.markOpened(id);
    } catch (_) {
      _allAccounts[index] = previous;
      notifyListeners();
      rethrow;
    }
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

  /// Thêm folder mới. Trả về null nếu thành công, hoặc thông báo lỗi.
  Future<String?> addFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Tên folder không được để trống';
    }
    if (trimmed.toLowerCase() == AppConstants.folderUncategorized.toLowerCase()) {
      return 'Không thể dùng tên "${AppConstants.folderUncategorized}" cho folder mới';
    }
    if (_folders.any((f) => f.toLowerCase() == trimmed.toLowerCase())) {
      return 'Folder "$trimmed" đã tồn tại';
    }

    final success = await _db.addFolder(trimmed);
    if (!success) {
      return 'Folder "$trimmed" đã tồn tại';
    }
    await reload();
    return null;
  }

  /// Đổi tên folder. Trả về null nếu thành công, hoặc thông báo lỗi.
  Future<String?> renameFolder(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      return 'Tên folder không được để trống';
    }
    if (trimmed.toLowerCase() == AppConstants.folderUncategorized.toLowerCase()) {
      return 'Không thể dùng tên "${AppConstants.folderUncategorized}" cho folder';
    }
    if (trimmed.toLowerCase() != oldName.toLowerCase() &&
        _folders.any((f) => f.toLowerCase() == trimmed.toLowerCase())) {
      return 'Folder "$trimmed" đã tồn tại';
    }

    final success = await _db.renameFolder(oldName, trimmed);
    if (!success) {
      return 'Không thể đổi tên folder "$oldName"';
    }
    await reload();
    return null;
  }

  Future<void> deleteFolder(String name) async {
    await _db.deleteFolder(name);
    await reload();
  }

  /// Số lượng tài khoản trong folder (đồng bộ, không cần await).
  int countFolder(String? folder) {
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
  ///
  /// Trả về `null` khi người dùng hủy chọn file (không hiện thông báo).
  /// Ném exception với thông điệp tiếng Việt khi có lỗi thật.
  Future<CsvImportResult?> importCsvFromPicker() async {
    final picked = await FilePicker.pickFile(
      type: FileType.any,
      dialogTitle: 'Chọn file CSV',
    );

    // Người dùng hủy chọn file.
    if (picked == null) return null;

    final fileName = picked.name.toLowerCase();
    if (!fileName.endsWith('.csv') && !fileName.endsWith('.txt')) {
      throw Exception('Vui lòng chọn file .csv');
    }

    final Uint8List bytes;
    try {
      bytes = await picked.readAsBytes();
    } catch (_) {
      throw Exception(
        'Không đọc được nội dung file "${picked.name}". Vui lòng thử lại với file .csv khác.',
      );
    }

    return importCsvFromBytes(bytes);
  }

  /// Nhập CSV từ dữ liệu bytes (dùng cho kéo thả trên desktop).
  Future<CsvImportResult> importCsvFromBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw Exception('File CSV rỗng.');
    }

    final rows = CsvParser.parseBytes(bytes);
    if (rows.isEmpty) {
      throw Exception('Không tìm thấy dữ liệu hợp lệ trong file CSV.');
    }

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
  List<int> exportCsvBytes() {
    final csvString = CsvExport.toCsvString(_allAccounts);
    return CsvExport.toUtf8WithBom(csvString);
  }
}
