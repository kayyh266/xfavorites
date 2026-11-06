import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'neu_avatar.dart';
import 'neu_card.dart';

/// Thẻ folder lớn trên trang chủ (avatar tròn nổi, tên đậm, số tài khoản).
///
/// [icon] dùng cho các thẻ đặc biệt: Tất cả, Yêu thích, Chưa phân loại.
class FolderCard extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onTap;
  final IconData? icon;
  final bool selected;

  /// Có menu đổi tên / xóa khi một trong hai callback được truyền vào.
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const FolderCard({
    super.key,
    required this.title,
    required this.count,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasMenu = onRename != null || onDelete != null;

    return NeuCard(
      onTap: onTap,
      selected: selected,
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              icon == null
                  ? NeuAvatar(label: title, size: 46)
                  : _IconAvatar(icon: icon!, label: title),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count tài khoản',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (hasMenu)
            Positioned(
              top: -6,
              right: -8,
              child: PopupMenuButton<String>(
                tooltip: 'Tùy chọn folder',
                color: AppColors.surfaceRaised,
                padding: EdgeInsets.zero,
                offset: const Offset(0, 34),
                onSelected: (value) {
                  if (value == 'rename') {
                    onRename?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Đổi tên'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Xóa folder',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceRaised,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    size: 17,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconAvatar extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IconAvatar({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = NeuAvatar.colorFor(label);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.16) ?? color,
            color,
            Color.lerp(color, Colors.black, 0.18) ?? color,
          ],
        ),
        boxShadow: AppShadows.neuSoft,
      ),
      child: Icon(icon, size: 23, color: AppColors.onBright),
    );
  }
}
