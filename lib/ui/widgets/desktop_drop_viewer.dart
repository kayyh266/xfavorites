import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';

/// Bọc nội dung để cho phép kéo thả file .csv vào cửa sổ (chỉ có tác dụng trên desktop).
/// Khi thả file, gọi [onDrop] với danh sách byte của các file CSV.
class DropViewer extends StatelessWidget {
  final Widget child;
  final ValueChanged<List<Uint8List>> onDrop;

  const DropViewer({
    super.key,
    required this.child,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        final files = detail.files.where((f) =>
            f.name.toLowerCase().endsWith('.csv'));
        if (files.isEmpty) return;

        final bytesList = <Uint8List>[];
        for (final file in files) {
          try {
            final data = await file.readAsBytes();
            bytesList.add(data);
          } catch (_) {
            // Bỏ qua file không đọc được
          }
        }
        if (bytesList.isNotEmpty) {
          onDrop(bytesList);
        }
      },
      child: child,
    );
  }
}
