import 'package:flutter/material.dart';
import 'dart:typed_data';

/// Widget pass-through (giữ nguyên cấu trúc để dễ sau này tích hợp lại desktop_drop nếu cần).
/// Hiện tại đơn giản trả về [child] vì gói desktop_drop đã được gỡ ra khỏi pubspec.yaml.
class DropViewer extends StatelessWidget {
  final Widget child;
  final ValueChanged<List<Uint8List>>? onDrop;

  const DropViewer({
    super.key,
    required this.child,
    this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
