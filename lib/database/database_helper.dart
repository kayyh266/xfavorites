import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/x_account.dart';
import '../models/csv_import_result.dart';
import '../core/constants.dart';

/// Helper quản lý cơ sở dữ liệu SQLite cục bộ.
///
/// - Android: dùng sqflite thông thường (databaseFactory mặc định).
/// - Windows/Linux: dùng sqflite_common_ffi qua databaseFactoryFfi
///   (đã được gán vào databaseFactory trong main.dart).
///
/// Đường dẫn database lấy từ path_provider (getApplicationDocumentsDirectory),
/// hoạt động đúng trên cả hai nền tảng. Dữ liệu chỉ lưu cục bộ, không gửi ra ngoài.
class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  static const String dbName = 'xfavorites.db';

  /// Lấy (hoặc tạo) đối tượng Database.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Khởi tạo cơ sở dữ liệu và tạo bảng nếu chưa tồn tại.
  Future<Database> _initDatabase() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Tạo bảng accounts và bảng folders khi cơ sở dữ liệu được tạo lần đầu.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        link TEXT NOT NULL,
        favorite INTEGER NOT NULL DEFAULT 0,
        folder TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        added_at TEXT,
        last_seen_following TEXT,
        last_opened TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE folders (
        name TEXT PRIMARY KEY
      )
    ''');

    // Chèn folder mặc định "Chưa phân loại" (dùng làm nhãn hiển thị)
    await db.insert('folders', {'name': AppConstants.folderUncategorized});
  }

  /// Đóng cơ sở dữ liệu.
  Future<void> close() async {
    Database db = await instance.database;
    await db.close();
    _database = null;
  }

  // -------------------------------------------------------------------------
  // Quản lý tài khoản
  // -------------------------------------------------------------------------

  /// Lấy tất cả tài khoản, có thể lọc theo folder và tìm kiếm.
  Future<List<XAccount>> getAccounts({
    String? folder,
    String? search,
  }) async {
    Database db = await instance.database;
    String query = 'SELECT * FROM accounts';
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (folder != null && folder == AppConstants.folderUncategorized) {
      whereClauses.add('(folder IS NULL OR folder = "")');
    } else if (folder != null) {
      whereClauses.add('folder = ?');
      whereArgs.add(folder);
    }

    if (search != null && search.isNotEmpty) {
      whereClauses.add('LOWER(username) LIKE ?');
      whereArgs.add('%${search.toLowerCase()}%');
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ' + whereClauses.join(' AND ');
    }

    query += ' ORDER BY username COLLATE NOCASE ASC';

    final List<Map<String, dynamic>> rawMaps = await db.rawQuery(query);
    return rawMaps.map((map) => XAccount.fromMap(map)).toList();
  }

  /// Lấy tài khoản theo id.
  Future<XAccount?> getAccountById(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return XAccount.fromMap(maps.first);
  }

  /// Chèn một tài khoản mới. Trả về id mới tạo.
  Future<int> insertAccount(XAccount account) async {
    Database db = await instance.database;
    return await db.insert('accounts', account.toMap());
  }

  /// Cập nhật một tài khoản theo id. Trả về số dòng bị ảnh hưởng.
  Future<int> updateAccount(XAccount account) async {
    Database db = await instance.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// Xóa một tài khoản theo id. Trả về số dòng bị ảnh hưởng.
  Future<int> deleteAccount(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Xóa nhiều tài khoản theo danh sách id. Trả về tổng số dòng bị ảnh hưởng.
  Future<int> deleteAccounts(List<int> ids) async {
    if (ids.isEmpty) return 0;
    Database db = await instance.database;
    int total = 0;
    for (final id in ids) {
      total += await deleteAccount(id);
    }
    return total;
  }

  /// Cập nhật trạng favorite của tài khoản.
  Future<int> setFavorite(int id, bool favorite) async {
    Database db = await instance.database;
    return await db.update(
      'accounts',
      {'favorite': favorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Đánh dấu tài khoản đã mở trang cá nhân (lưu last_opened).
  Future<int> markOpened(int id) async {
    Database db = await instance.database;
    return await db.update(
      'accounts',
      {'last_opened': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Bỏ đánh dấu đã mở.
  Future<int> unmarkOpened(int id) async {
    Database db = await instance.database;
    return await db.update(
      'accounts',
      {'last_opened': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Di chuyển tài khoản vào folder (folder có thể null).
  Future<int> setFolder(int id, String? folder) async {
    Database db = await instance.database;
    return await db.update(
      'accounts',
      {'folder': folder},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Di chuyển nhiều tài khoản vào folder.
  Future<int> setFolderForAccounts(List<int> ids, String? folder) async {
    if (ids.isEmpty) return 0;
    Database db = await instance.database;
    int total = 0;
    for (final id in ids) {
      total += await setFolder(id, folder);
    }
    return total;
  }

  /// Lấy số lượng tài khoản theo folder (dùng hiển thị số lượng bên cạnh tên folder).
  Future<int> countByFolder(String? folder) async {
    Database db = await instance.database;
    if (folder == null || folder == AppConstants.folderUncategorized) {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM accounts WHERE folder IS NULL OR folder = ""',
      );
      return int.tryParse(maps.first['cnt']?.toString() ?? '0') ?? 0;
    }
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'folder = ?',
      whereArgs: [folder],
    );
    return maps.length;
  }

  /// Lấy tổng số tài khoản.
  Future<int> countAll() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT COUNT(*) as cnt FROM accounts');
    return int.tryParse(maps.first['cnt']?.toString() ?? '0') ?? 0;
  }

  // -------------------------------------------------------------------------
  // Quản lý folder
  // -------------------------------------------------------------------------

  /// Lấy tất cả tên folder.
  Future<List<String>> getFolders() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    return maps.map((m) => m['name'] as String).toList();
  }

  /// Thêm một folder mới. Trả về true nếu thành công (folder chưa tồn tại).
  Future<bool> addFolder(String name) async {
    if (name.trim().isEmpty) return false;
    Database db = await instance.database;
    try {
      await db.insert('folders', {'name': name.trim()});
      return true;
    } catch (_) {
      return false; // đã tồn tại (PRIMARY KEY constraint)
    }
  }

  /// Đổi tên folder. Tài khoản trong folder giữ nguyên (tham chiếu theo tên, nên cần cập nhật).
  Future<int> renameFolder(String oldName, String newName) async {
    if (newName.trim().isEmpty) return 0;
    Database db = await instance.database;
    await db.update(
      'accounts',
      {'folder': newName.trim()},
      where: 'folder = ?',
      whereArgs: [oldName],
    );
    return await db.update(
      'folders',
      {'name': newName.trim()},
      where: 'name = ?',
      whereArgs: [oldName],
    );
  }

  /// Xóa folder. Tài khoản trong folder sẽ về null (Chưa phân loại), không bị xóa tài khoản.
  Future<int> deleteFolder(String name) async {
    Database db = await instance.database;
    await db.update(
      'accounts',
      {'folder': null},
      where: 'folder = ?',
      whereArgs: [name],
    );
    return await db.delete(
      'folders',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  // -------------------------------------------------------------------------
  // Nhập / xuất CSV
  // -------------------------------------------------------------------------

  /// Nhập danh sách tài khoản từ CSV. Gộp theo username (không phân biệt hoa thường).
  /// Giữ nguyên favorite/folder đã có trong app, chỉ thêm tên mới và cập nhật status.
  Future<CsvImportResult> importFromCsv(List<Map<String, String>> rows) async {
    if (rows.isEmpty) return const CsvImportResult(added: 0, updated: 0, skipped: 0);

    Database db = await instance.database;

    // Lấy tất cả tài khoản hiện có để so sánh trùng lặp.
    final existingMaps = await db.query('accounts');
    final existingAccounts = existingMaps.map((m) => XAccount.fromMap(m)).toList();
    final Map<String, XAccount> existingByNormalized = {};
    for (final acc in existingAccounts) {
      existingByNormalized[XAccount.normalizeUsername(acc.username)] = acc;
    }

    int added = 0;
    int updated = 0;
    int skipped = 0;

    // Dùng batch để tối đa hiệu năng khi nhập nhiều dòng.
    final batch = db.batch();

    for (final row in rows) {
      final rawUsername = (row['username'] ?? '').trim();
      if (rawUsername.isEmpty) {
        skipped++;
        continue;
      }

      final normalized = XAccount.normalizeUsername(rawUsername);
      final link = (row['link'] ?? '').trim();
      final favoriteStr = (row['favorite'] ?? '').trim().toLowerCase();
      final favorite = favoriteStr == 'true' || favoriteStr == '1';
      final folder = (row['folder'] ?? '').trim();
      final status = (row['status'] ?? '').trim();
      final addedAtStr = (row['added_at'] ?? '').trim();
      final lastSeenStr = (row['last_seen_following'] ?? '').trim();

      final existing = existingByNormalized[normalized];

      if (existing == null) {
        // Tên mới -> chèn vào CSDL (batch)
        batch.insert('accounts', {
          'username': rawUsername,
          'link': link,
          'favorite': favorite ? 1 : 0,
          'folder': folder.isEmpty ? null : folder,
          'status': status.isEmpty ? AppConstants.statusActive : status,
          'added_at': addedAtStr.isEmpty ? null : addedAtStr,
          'last_seen_following': lastSeenStr.isEmpty ? null : lastSeenStr,
          'last_opened': null,
        });
        added++;
      } else {
        // Đã tồn tại -> giữ nguyên favorite/folder của app, chỉ cập nhật status (và link nếu trống)
        final newLink = link.isEmpty ? existing.link : link;
        final newStatus = status.isEmpty ? existing.status : status;
        batch.update(
          'accounts',
          {
            'link': newLink,
            'status': newStatus,
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        updated++;
      }
    }

    await batch.commit(noResult: true);
    return CsvImportResult(added: added, updated: updated, skipped: skipped);
  }

  /// Xuất tất cả tài khoản ra danh sách Map (dùng để ghi file CSV).
  Future<List<Map<String, String>>> exportToCsv() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    return maps.map((m) {
      return {
        'username': (m['username'] ?? '').toString(),
        'link': (m['link'] ?? '').toString(),
        'favorite': ((m['favorite'] ?? 0) == 1) ? 'true' : 'false',
        'folder': (m['folder'] ?? '').toString(),
        'status': (m['status'] ?? AppConstants.statusActive).toString(),
        'added_at': (m['added_at'] ?? '').toString(),
        'last_seen_following': (m['last_seen_following'] ?? '').toString(),
      };
    }).toList();
  }
}
