import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'neu_card.dart';

/// Nội dung một thông báo toast.
class ToastData {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ToastData({
    required this.message,
    this.actionLabel,
    this.onAction,
  });
}

/// Thông báo nổi góc trên phải, tự ẩn do widget cha quản lý.
class ToastHost extends StatelessWidget {
  final ToastData? toast;
  final VoidCallback onClose;
  final double width;

  const ToastHost({
    super.key,
    required this.toast,
    required this.onClose,
    this.width = 360,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, -0.15),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: toast == null
          ? const SizedBox.shrink(key: ValueKey('empty-toast'))
          : SizedBox(
              key: ValueKey(toast!.message),
              width: width,
              child: NeuCard(
                radius: 16,
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                color: AppColors.surfaceRaised,
                borderColor: AppColors.accent.withValues(alpha: 0.35),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 17,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              toast!.message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (toast!.actionLabel != null) ...[
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: toast!.onAction,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    toast!.actionLabel!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
