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

  /// Đường dẫn DB tùy chọn (dùng cho test, ví dụ inMemoryDatabasePath).
  /// Khi null, dùng file xfavorites.db trong thư mục Documents của ứng dụng.
  static String? databasePathOverride;

  static const String dbName = 'xfavorites.db';

  /// Phiên bản CSDL hiện tại.
  ///
  /// v2: bỏ folder mặc định "Chưa phân loại" khỏi bảng folders.
  /// v3: thêm cột open_count (số lần mở, chỉ lưu cục bộ, không ghi CSV).
  static const int dbVersion = 3;

  /// Cấu hình đường dẫn DB cho test.
  ///
  /// Gọi [close] trước nếu đang có kết nối mở. Truyền [path] = null để trở lại
  /// đường dẫn mặc định.
  static void configureForTesting({String? path}) {
    databasePathOverride = path;
    _database = null;
  }

  /// Lấy (hoặc tạo) đối tượng Database.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Khởi tạo cơ sở dữ liệu và tạo bảng nếu chưa tồn tại.
  Future<Database> _initDatabase() async {
    final String path;
    if (databasePathOverride != null) {
      path = databasePathOverride!;
    } else {
      final Directory documentsDir = await getApplicationDocumentsDirectory();
      path = join(documentsDir.path, dbName);
    }

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  /// Tạo bảng accounts và bảng folders khi cơ sở dữ liệu được tạo lần đầu.
  ///
  /// Không chèn sẵn "Chưa phân loại": đây là mục cố định trên giao diện,
  /// không phải một folder thật trong CSDL.
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
        last_opened TEXT,
        open_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE folders (
        name TEXT PRIMARY KEY
      )
    ''');
  }

  /// Nâng cấp CSDL từ phiên bản cũ.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _removeUncategorizedFolder(db);
    }
    if (oldVersion < 3) {
      // Kiểm tra trước khi ALTER để tránh lỗi "duplicate column".
      final columns = await db.rawQuery('PRAGMA table_info(accounts)');
      final hasOpenCount = columns.any((column) => column['name'] == 'open_count');
      if (!hasOpenCount) {
        await db.execute(
          'ALTER TABLE accounts ADD COLUMN open_count INTEGER NOT NULL DEFAULT 0',
        );
      }
    }
  }

  /// Dọn dẹp mỗi lần mở CSDL (phòng trường hợp dữ liệu cũ còn sót lại).
  Future<void> _onOpen(Database db) async {
    await _removeUncategorizedFolder(db);
  }

  /// Xóa folder "Chưa phân loại" khỏi bảng folders và đưa các tài khoản
  /// đang trỏ tới folder này về null.
  static Future<void> _removeUncategorizedFolder(Database db) async {
    final target = AppConstants.folderUncategorized.toLowerCase();

    final folderRows = await db.query('folders', columns: ['name']);
    for (final row in folderRows) {
      final name = (row['name'] ?? '').toString();
      if (name.trim().toLowerCase() == target) {
        await db.delete('folders', where: 'name = ?', whereArgs: [name]);
      }
    }

    await db.update(
      'accounts',
      {'folder': null},
      where: 'folder = ?',
      whereArgs: [AppConstants.folderUncategorized],
    );
  }

  /// Đóng cơ sở dữ liệu.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
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
      query += ' WHERE ${whereClauses.join(' AND ')}';
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

  /// Đánh dấu tài khoản đã mở trang cá nhân.
  ///
  /// Tăng open_count thêm 1 và cập nhật last_opened (chỉ lưu cục bộ).
  Future<int> markOpened(int id) async {
    Database db = await instance.database;
    return await db.rawUpdate(
      'UPDATE accounts SET last_opened = ?, open_count = open_count + 1 WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
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
    final List<Map<String, dynamic>> maps =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM accounts');
    return int.tryParse(maps.first['cnt']?.toString() ?? '0') ?? 0;
  }

  // -------------------------------------------------------------------------
  // Quản lý folder
  // -------------------------------------------------------------------------

  /// Lấy tất cả tên folder, đã loại bỏ "Chưa phân loại" và sắp xếp theo tên.
  Future<List<String>> getFolders() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    final target = AppConstants.folderUncategorized.toLowerCase();

    final names = maps
        .map((m) => (m['name'] ?? '').toString())
        .where((name) => name.trim().isNotEmpty)
        .where((name) => name.trim().toLowerCase() != target)
        .toList();

    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  /// Thêm một folder mới. Trả về true nếu thành công.
  ///
  /// Từ chối tên rỗng, tên "Chưa phân loại" và tên đã tồn tại
  /// (không phân biệt hoa thường).
  Future<bool> addFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.toLowerCase() == AppConstants.folderUncategorized.toLowerCase()) {
      return false;
    }

    Database db = await instance.database;
    final existing = await db.query(
      'folders',
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;

    try {
      await db.insert('folders', {'name': trimmed});
      return true;
    } catch (_) {
      return false; // đã tồn tại (PRIMARY KEY constraint)
    }
  }

  /// Đổi tên folder. Trả về true nếu thành công.
  ///
  /// Từ chối tên rỗng, tên "Chưa phân loại" và tên trùng với folder khác.
  Future<bool> renameFolder(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.toLowerCase() == AppConstants.folderUncategorized.toLowerCase()) {
      return false;
    }

    Database db = await instance.database;

    final existing = await db.query(
      'folders',
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (existing.isNotEmpty && existing.first['name'] != oldName) {
      return false;
    }

    await db.transaction((txn) async {
      await txn.update(
        'accounts',
        {'folder': trimmed},
        where: 'folder = ?',
        whereArgs: [oldName],
      );
      await txn.update(
        'folders',
        {'name': trimmed},
        where: 'name = ?',
        whereArgs: [oldName],
      );
    });

    return true;
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
  ///
  /// - Folder khác rỗng trong CSV được tự động thêm vào bảng folders.
  /// - Tài khoản trùng username ngay trong cùng file CSV cũng được gộp.
  /// - Toàn bộ thao tác chạy trong một transaction.
  Future<CsvImportResult> importFromCsv(List<Map<String, String>> rows) async {
    if (rows.isEmpty) {
      return const CsvImportResult(added: 0, updated: 0, skipped: 0);
    }

    Database db = await instance.database;

    return await db.transaction<CsvImportResult>((txn) async {
      // Lấy tất cả tài khoản hiện có để so sánh trùng lặp.
      final existingMaps = await txn.query('accounts');
      final Map<String, XAccount> existingByNormalized = {};
      for (final map in existingMaps) {
        final acc = XAccount.fromMap(map);
        existingByNormalized[XAccount.normalizeUsername(acc.username)] = acc;
      }

      // Tên folder hiện có: khóa chữ thường -> tên gốc, để tránh tạo trùng.
      final folderRows = await txn.query('folders', columns: ['name']);
      final Map<String, String> existingFolderNames = {};
      for (final row in folderRows) {
        final name = (row['name'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          existingFolderNames[name.toLowerCase()] = name;
        }
      }

      int added = 0;
      int updated = 0;
      int skipped = 0;

      for (final row in rows) {
        final rawUsername =
            (row['username'] ?? '').trim().replaceFirst(RegExp(r'^@+'), '').trim();
        if (rawUsername.isEmpty) {
          skipped++;
          continue;
        }

        final normalized = XAccount.normalizeUsername(rawUsername);

        final parsedLink = (row['link'] ?? '').trim();
        final link = parsedLink.isEmpty ? 'https://x.com/$rawUsername' : parsedLink;
        final favoriteStr = (row['favorite'] ?? '').trim().toLowerCase();
        final favorite = favoriteStr == 'true' || favoriteStr == '1';
        final folder = (row['folder'] ?? '').trim();
        final status = (row['status'] ?? '').trim();
        final addedAtStr = (row['added_at'] ?? '').trim();
        final lastSeenStr = (row['last_seen_following'] ?? '').trim();

        // Folder xuất hiện trong CSV phải có trong bảng folders.
        // Dùng lại đúng tên đã có (không phân biệt hoa thường) để tránh tạo trùng.
        var storedFolder = folder;
        if (folder.isNotEmpty &&
            folder.toLowerCase() != AppConstants.folderUncategorized.toLowerCase()) {
          final folderKey = folder.toLowerCase();
          final existingName = existingFolderNames[folderKey];
          if (existingName == null) {
            existingFolderNames[folderKey] = folder;
            await txn.insert(
              'folders',
              {'name': folder},
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          } else {
            storedFolder = existingName;
          }
        } else if (folder.toLowerCase() ==
            AppConstants.folderUncategorized.toLowerCase()) {
          storedFolder = '';
        }

        final existing = existingByNormalized[normalized];

        if (existing == null) {
          // Tên mới -> chèn vào CSDL.
          final newId = await txn.insert('accounts', {
            'username': rawUsername,
            'link': link,
            'favorite': favorite ? 1 : 0,
            'folder': storedFolder.isEmpty ? null : storedFolder,
            'status': status.isEmpty ? AppConstants.statusActive : status,
            'added_at': addedAtStr.isEmpty ? null : addedAtStr,
            'last_seen_following': lastSeenStr.isEmpty ? null : lastSeenStr,
            'last_opened': null,
          });

          // Ghi nhớ để các dòng trùng trong cùng file được gộp vào bản ghi này.
          existingByNormalized[normalized] = XAccount(
            id: newId,
            username: rawUsername,
            link: link,
            favorite: favorite,
            folder: storedFolder.isEmpty ? null : storedFolder,
            status: status.isEmpty ? AppConstants.statusActive : status,
            addedAt: addedAtStr.isEmpty ? null : DateTime.tryParse(addedAtStr),
            lastSeenFollowing:
                lastSeenStr.isEmpty ? null : DateTime.tryParse(lastSeenStr),
          );
          added++;
        } else {
          // Đã tồn tại -> giữ nguyên favorite/folder của app, chỉ cập nhật status
          // (và link nếu trống).
          final newLink = parsedLink.isEmpty ? existing.link : parsedLink;
          final newStatus = status.isEmpty ? existing.status : status;
          await txn.update(
            'accounts',
            {
              'link': newLink,
              'status': newStatus,
            },
            where: 'id = ?',
            whereArgs: [existing.id],
          );

          existingByNormalized[normalized] = existing.copyWith(
            link: newLink,
            status: newStatus,
          );
          updated++;
        }
      }

      return CsvImportResult(added: added, updated: updated, skipped: skipped);
    });
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
