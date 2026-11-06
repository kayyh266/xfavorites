import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xfavorites/database/database_helper.dart';

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
