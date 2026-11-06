import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

/// Callback xử lý một file được kéo thả vào cửa sổ.
typedef DropFileCallback = Future<void> Function(Uint8List bytes, String fileName);

/// Bọc toàn bộ giao diện để nhận file kéo thả trên desktop.
///
/// - Đọc nội dung file bằng [XFile.readAsBytes].
/// - Hiện lớp phủ "Thả file CSV vào đây" trong lúc đang kéo.
/// - Chỉ nên dùng trên Windows/Linux/macOS.
class DropViewer extends StatefulWidget {
  final Widget child;
  final DropFileCallback onDropFile;
  final void Function(String message)? onError;

  const DropViewer({
    super.key,
    required this.child,
    required this.onDropFile,
    this.onError,
  });

  @override
  State<DropViewer> createState() => _DropViewerState();
}

class _DropViewerState extends State<DropViewer> {
  bool _dragging = false;

  Future<void> _handleDrop(DropDetails details) async {
    if (_dragging) {
      setState(() => _dragging = false);
    }

    for (final item in details.items) {
      if (item is! DropFileItem) continue;
      try {
        final bytes = await item.file.readAsBytes();
        await widget.onDropFile(bytes, item.name);
      } catch (e) {
        widget.onError?.call('Không đọc được file đã thả: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropTarget(
      acceptedKinds: const {DropItemKind.file},
      onEnter: (_) => setState(() => _dragging = true),
      onLeave: () => setState(() => _dragging = false),
      onDrop: _handleDrop,
      child: Stack(
        children: [
          widget.child,
          if (_dragging)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: colorScheme.primary.withValues(alpha: 0.88),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.file_download_outlined,
                        size: 72,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Thả file CSV vào đây',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
