import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xfavorites/database/database_helper.dart';
import 'package:xfavorites/models/x_account.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    // Mỗi test dùng một CSDL trong bộ nhớ riêng.
    DatabaseHelper.configureForTesting(path: inMemoryDatabasePath);
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
    DatabaseHelper.configureForTesting(path: null);
  });

  test('getFolders không bao giờ chứa "Chưa phân loại"', () async {
    final db = DatabaseHelper.instance;

    expect(await db.getFolders(), isNot(contains('Chưa phân loại')));

    // Tên dành riêng cho mục cố định trên giao diện -> phải bị từ chối.
    expect(await db.addFolder('Chưa phân loại'), isFalse);
    expect(await db.getFolders(), isNot(contains('Chưa phân loại')));

    // Folder thật thì thêm được và được sắp xếp theo tên.
    expect(await db.addFolder('Music'), isTrue);
    expect(await db.addFolder('Art'), isTrue);
    expect(await db.addFolder('Art'), isFalse); // trùng

    final folders = await db.getFolders();
    expect(folders, <String>['Art', 'Music']);
  });

  test('importFromCsv tạo folder từ cột folder', () async {
    final db = DatabaseHelper.instance;

    final result = await db.importFromCsv([
      {'username': 'artist1', 'folder': 'Art'},
      {'username': 'artist2', 'folder': 'Music'},
      {'username': 'artist3', 'folder': ''},
    ]);

    expect(result.added, 3);
    expect(result.updated, 0);
    expect(result.skipped, 0);

    final folders = await db.getFolders();
    expect(folders, containsAll(<String>['Art', 'Music']));
    expect(folders, isNot(contains('Chưa phân loại')));

    final accounts = await db.getAccounts();
    expect(accounts.length, 3);
    expect(accounts.map((a) => a.folder), containsAll(<String?>['Art', 'Music', null]));
  });

  test('importFromCsv gộp username trùng ngay trong cùng file CSV', () async {
    final db = DatabaseHelper.instance;

    final result = await db.importFromCsv([
      {'username': '@Artist1', 'link': '', 'folder': 'Art'},
      {'username': 'artist1', 'link': 'https://x.com/artist1', 'folder': 'Art'},
      {'username': 'ARTIST1', 'link': '', 'folder': ''},
    ]);

    expect(result.added, 1);
    expect(result.updated, 2);

    final accounts = await db.getAccounts();
    expect(accounts.length, 1);
    expect(accounts.first.username, 'Artist1');
    expect(accounts.first.link, 'https://x.com/artist1');
    expect(accounts.first.folder, 'Art');
  });

  test('importFromCsv bỏ qua dòng không có username', () async {
    final db = DatabaseHelper.instance;

    final result = await db.importFromCsv([
      {'username': '', 'link': 'https://x.com/unknown'},
      {'username': 'artist1', 'link': ''},
    ]);

    expect(result.added, 1);
    expect(result.skipped, 1);
  });

  test('importFromCsv không tạo folder "Chưa phân loại" và dùng lại folder cùng tên', () async {
    final db = DatabaseHelper.instance;

    await db.importFromCsv([
      {'username': 'artist1', 'folder': 'Art'},
      {'username': 'artist2', 'folder': 'art'},
      {'username': 'artist3', 'folder': 'Chưa phân loại'},
    ]);

    final folders = await db.getFolders();
    expect(folders, <String>['Art']);

    final accounts = await db.getAccounts();
    final byName = {for (final acc in accounts) acc.username: acc};
    expect(byName['artist1']!.folder, 'Art');
    expect(byName['artist2']!.folder, 'Art');
    expect(byName['artist3']!.folder, isNull);
  });

  test('markOpened tăng open_count và cập nhật last_opened', () async {
    final db = DatabaseHelper.instance;

    final id = await db.insertAccount(
      const XAccount(username: 'artist1', link: 'https://x.com/artist1'),
    );

    var account = await db.getAccountById(id);
    expect(account, isNotNull);
    expect(account!.openCount, 0);
    expect(account.lastOpened, isNull);

    await db.markOpened(id);
    await db.markOpened(id);

    account = await db.getAccountById(id);
    expect(account, isNotNull);
    expect(account!.openCount, 2);
    expect(account.lastOpened, isNotNull);
  });

  test('nâng cấp CSDL v2 lên v3 thêm cột open_count mặc định 0', () async {
    final tempDir = await Directory.systemTemp.createTemp('xfavorites_v3_');
    final dbPath = p.join(tempDir.path, 'upgrade_v3.db');

    try {
      await DatabaseHelper.instance.close();
      DatabaseHelper.configureForTesting(path: dbPath);

      // Tạo CSDL kiểu phiên bản 2 (chưa có open_count).
      final rawDb = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
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
            await db.execute('CREATE TABLE folders (name TEXT PRIMARY KEY)');
          },
        ),
      );
      await rawDb.insert('accounts', {
        'username': 'legacy_user',
        'link': 'https://x.com/legacy_user',
      });
      await rawDb.close();

      // Mở lại bằng DatabaseHelper (version 3) -> onUpgrade phải ALTER TABLE.
      DatabaseHelper.configureForTesting(path: dbPath);
      final upgraded = DatabaseHelper.instance;
      final columns =
          await (await upgraded.database).rawQuery('PRAGMA table_info(accounts)');
      expect(columns.any((column) => column['name'] == 'open_count'), isTrue);

      final accounts = await upgraded.getAccounts();
      expect(accounts.length, 1);
      expect(accounts.first.openCount, 0);

      await upgraded.markOpened(accounts.first.id!);
      final opened = await upgraded.getAccountById(accounts.first.id!);
      expect(opened!.openCount, 1);
      expect(opened.lastOpened, isNotNull);
    } finally {
      await DatabaseHelper.instance.close();
      DatabaseHelper.configureForTesting(path: null);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });

  test('folder "Chưa phân loại" cũ trong CSDL được dọn khi mở lại', () async {
    final tempDir = await Directory.systemTemp.createTemp('xfavorites_test_');
    final dbPath = p.join(tempDir.path, 'migration.db');

    try {
      // Tạo CSDL rồi ghi dữ liệu kiểu phiên bản 1.
      DatabaseHelper.configureForTesting(path: dbPath);
      final first = DatabaseHelper.instance;
      final rawDb = await first.database;

      await rawDb.insert('folders', {'name': 'Chưa phân loại'});
      await rawDb.insert('folders', {'name': 'Art'});
      await rawDb.insert('accounts', {
        'username': 'artist1',
        'link': 'https://x.com/artist1',
        'folder': 'Chưa phân loại',
      });

      // Đóng rồi mở lại -> onOpen phải dọn folder cũ.
      await first.close();
      DatabaseHelper.configureForTesting(path: dbPath);

      final reopened = DatabaseHelper.instance;
      final folders = await reopened.getFolders();
      expect(folders, isNot(contains('Chưa phân loại')));
      expect(folders, contains('Art'));

      final accounts = await reopened.getAccounts();
      expect(accounts.length, 1);
      expect(accounts.first.folder, isNull);
    } finally {
      await DatabaseHelper.instance.close();
      DatabaseHelper.configureForTesting(path: null);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}
