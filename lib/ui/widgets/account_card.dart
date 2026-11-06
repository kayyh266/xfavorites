import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../models/x_account.dart';
import 'neu_avatar.dart';
import 'neu_card.dart';

/// Một dòng tài khoản trong danh sách.
///
/// Hiển thị avatar, @username, folder, huy hiệu "Không còn follow",
/// nút yêu thích, menu chuyển folder và nút xóa.
class AccountCard extends StatelessWidget {
  final XAccount account;
  final List<String> folders;
  final bool selected;
  final bool selectionMode;
  final bool desktopMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;
  final ValueChanged<String?> onMoveToFolder;

  const AccountCard({
    super.key,
    required this.account,
    required this.folders,
    required this.onTap,
    required this.onLongPress,
    required this.onFavoriteToggle,
    required this.onDelete,
    required this.onMoveToFolder,
    this.selected = false,
    this.selectionMode = false,
    this.desktopMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final folderName = (account.folder == null || account.folder!.isEmpty)
        ? AppConstants.folderUncategorized
        : account.folder!;
    final isUnfollowed = account.status == AppConstants.statusUnfollowed;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: desktopMode ? 0 : 12,
        vertical: 5,
      ),
      child: NeuCard(
        onTap: onTap,
        onLongPress: onLongPress,
        selected: selected,
        compactShadow: true,
        padding: EdgeInsets.symmetric(
          horizontal: desktopMode ? 14 : 10,
          vertical: 10,
        ),
        child: Row(
          children: [
            if (selectionMode) ...[
              _SelectBox(selected: selected),
              const SizedBox(width: 8),
            ],
            NeuAvatar(label: account.username, size: desktopMode ? 44 : 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: desktopMode ? 15 : 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isUnfollowed) ...[
                        const SizedBox(width: 6),
                        const _UnfollowedBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          folderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (account.openCount > 0)
                        Text(
                          '${account.openCount} lần mở',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            _IconAction(
              tooltip: account.favorite ? 'Bỏ yêu thích' : 'Yêu thích',
              icon: account.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: account.favorite ? AppColors.orange : AppColors.textSecondary,
              onPressed: onFavoriteToggle,
            ),
            PopupMenuButton<String>(
              tooltip: 'Chuyển folder',
              color: AppColors.surfaceRaised,
              offset: const Offset(0, 38),
              onSelected: (value) {
                if (value == '__delete__') {
                  onDelete();
                } else if (value == AppConstants.menuUncategorized) {
                  onMoveToFolder(null);
                } else {
                  onMoveToFolder(value);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  enabled: false,
                  height: 30,
                  child: Text(
                    'CHUYỂN VÀO FOLDER',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: AppConstants.menuUncategorized,
                  child: _FolderMenuRow(
                    label: AppConstants.folderUncategorized,
                    selected: account.folder == null || account.folder!.isEmpty,
                  ),
                ),
                for (final folder in folders)
                  PopupMenuItem<String>(
                    value: folder,
                    child: _FolderMenuRow(
                      label: folder,
                      selected: account.folder == folder,
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: '__delete__',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Xóa tài khoản',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ],
              child: const _IconSurface(
                icon: Icons.drive_file_move_outline,
                color: AppColors.textSecondary,
              ),
            ),
            if (desktopMode)
              _IconAction(
                tooltip: 'Xóa tài khoản',
                icon: Icons.delete_outline_rounded,
                color: AppColors.textSecondary,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  final bool selected;

  const _SelectBox({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.outline,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: AppColors.onBright)
          : null,
    );
  }
}

class _UnfollowedBadge extends StatelessWidget {
  const _UnfollowedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
      ),
      child: const Text(
        'Không còn follow',
        maxLines: 1,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: AppColors.orange,
        ),
      ),
    );
  }
}

class _FolderMenuRow extends StatelessWidget {
  final String label;
  final bool selected;

  const _FolderMenuRow({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          selected ? Icons.folder_rounded : Icons.folder_outlined,
          size: 18,
          color: selected ? AppColors.accent : AppColors.textSecondary,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AppColors.accent : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _IconAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 19, color: color),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _IconSurface extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconSurface({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceSunken,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }
}
