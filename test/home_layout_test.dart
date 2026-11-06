import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xfavorites/core/app_theme.dart';
import 'package:xfavorites/database/database_helper.dart';
import 'package:xfavorites/models/x_account.dart';
import 'package:xfavorites/ui/pages/home_page.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    DatabaseHelper.configureForTesting(path: inMemoryDatabasePath);
    final db = DatabaseHelper.instance;
    await db.addFolder('Art');
    await db.addFolder('Music');

    for (var i = 0; i < 6; i++) {
      final id = await db.insertAccount(
        XAccount(
          username: 'artist_$i',
          link: 'https://x.com/artist_$i',
          favorite: i.isEven,
          folder: i.isEven ? 'Art' : null,
          addedAt: DateTime(2026, 1, i + 1),
        ),
      );
      if (i < 3) {
        await db.markOpened(id);
      }
    }
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
    DatabaseHelper.configureForTesting(path: null);
  });

  Future<void> pumpHome(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('không overflow ở kích thước điện thoại 400x915', (tester) async {
    await pumpHome(tester, const Size(400, 915));
    expect(tester.takeException(), isNull);
    expect(find.text('MỞ GẦN ĐÂY'), findsWidgets);
  });

  testWidgets('không overflow ở kích thước desktop 1920x1080', (tester) async {
    await pumpHome(tester, const Size(1920, 1080));
    expect(tester.takeException(), isNull);
    expect(find.text('MỞ GẦN ĐÂY'), findsWidgets);
    expect(find.text('X Favorites'), findsWidgets);
  });
}
