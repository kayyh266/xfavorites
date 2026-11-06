import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';

/// Điểm vào ứng dụng.
///
/// Trên Windows/Linux, sqflite thông thường không hỗ trợ, nên ta khởi tạo
/// databaseFactoryFfi từ sqflite_common_ffi trước khi chạy app.
/// Trên Android, giữ nguyên sqflite mặc định, không cần init thêm.
void main() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ProviderScope(child: XFavoritesApp()));
}
