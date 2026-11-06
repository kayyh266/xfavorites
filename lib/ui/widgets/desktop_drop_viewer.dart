import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import 'neu_card.dart';

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
                  color: AppColors.background.withValues(alpha: 0.94),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: NeuCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 32,
                      ),
                      radius: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent.withValues(alpha: 0.14),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.45),
                              ),
                            ),
                            child: const Icon(
                              Icons.file_download_outlined,
                              size: 34,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'THẢ FILE CSV VÀO ĐÂY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Dữ liệu được nhập và lưu ngay trên máy bạn.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
