import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// Điểm vào ứng dụng. Bọc toàn bộ ứng dụng trong [ProviderScope] để Riverpod hoạt động.
void main() {
  runApp(const ProviderScope(child: XFavoritesApp()));
}
