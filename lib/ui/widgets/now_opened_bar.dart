import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../models/x_account.dart';
import 'neu_avatar.dart';
import 'neu_card.dart';

/// Thanh nổi "vừa mở" ở cuối màn hình.
///
/// [compact] dùng cho điện thoại: chỉ avatar, @username và nút mở lại.
class NowOpenedBar extends StatelessWidget {
  final XAccount account;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final VoidCallback onFolder;
  final VoidCallback onDelete;
  final bool compact;

  const NowOpenedBar({
    super.key,
    required this.account,
    required this.onOpen,
    required this.onFavorite,
    required this.onFolder,
    required this.onDelete,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final folderName = (account.folder == null || account.folder!.isEmpty)
        ? AppConstants.folderUncategorized
        : account.folder!;

    return NeuCard(
      radius: 20,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 10,
      ),
      child: Row(
        children: [
          NeuAvatar(
            label: account.username,
            size: compact ? 32 : 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  account.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Vừa mở · $folderName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (compact) ...[
            _BarIcon(
              tooltip: 'Mở lại',
              icon: Icons.open_in_new_rounded,
              color: AppColors.accent,
              onTap: onOpen,
            ),
          ] else ...[
            _BarIcon(
              tooltip: 'Mở lại',
              icon: Icons.open_in_new_rounded,
              color: AppColors.accent,
              onTap: onOpen,
            ),
            _BarIcon(
              tooltip: account.favorite ? 'Bỏ yêu thích' : 'Yêu thích',
              icon: account.favorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: account.favorite ? AppColors.orange : AppColors.textSecondary,
              onTap: onFavorite,
            ),
            _BarIcon(
              tooltip: 'Chuyển folder',
              icon: Icons.drive_file_move_outline,
              color: AppColors.textSecondary,
              onTap: onFolder,
            ),
            _BarIcon(
              tooltip: 'Xóa tài khoản',
              icon: Icons.delete_outline_rounded,
              color: AppColors.textSecondary,
              onTap: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

/// Thanh thao tác thay thế thanh "vừa mở" khi đang chọn nhiều.
class SelectionActionBar extends StatelessWidget {
  final int count;
  final VoidCallback onMoveFolder;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const SelectionActionBar({
    super.key,
    required this.count,
    required this.onMoveFolder,
    required this.onDelete,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        return NeuCard(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  size: 17,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$count đã chọn',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (compact) ...[
                _BarIcon(
                  tooltip: 'Chuyển folder',
                  icon: Icons.drive_file_move_outline,
                  color: AppColors.textSecondary,
                  onTap: onMoveFolder,
                ),
                _BarIcon(
                  tooltip: 'Xóa tài khoản',
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  onTap: onDelete,
                ),
              ] else ...[
                _BarAction(
                  icon: Icons.drive_file_move_outline,
                  label: 'Folder',
                  color: AppColors.textSecondary,
                  onTap: onMoveFolder,
                ),
                _BarAction(
                  icon: Icons.delete_outline_rounded,
                  label: 'Xóa',
                  color: AppColors.danger,
                  onTap: onDelete,
                ),
              ],
              _BarIcon(
                tooltip: 'Bỏ chọn',
                icon: Icons.close_rounded,
                color: AppColors.textSecondary,
                onTap: onClear,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BarIcon({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 19, color: color),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _BarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BarAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17, color: color),
      label: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
