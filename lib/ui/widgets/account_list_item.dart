import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/x_account.dart';
import '../../core/constants.dart';
import '../widgets/account_avatar.dart';

/// Một dòng trong danh sách tài khoản.
///
/// Mỗi dòng hiển thị: avatar chữ cái đầu, @username, tên folder, huy hiệu "Không còn follow",
/// nút yêu thích (sao), nút xóa. Bấm vào dòng mở link bằng trình duyệt ngoài ứng dụng.
class AccountListItem extends StatelessWidget {
  final XAccount account;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;
  final ValueChanged<String?> onMoveToFolder;
  final VoidCallback onLongPress;
  final bool desktopMode;

  const AccountListItem({
    super.key,
    required this.account,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onDelete,
    required this.onMoveToFolder,
    required this.onLongPress,
    this.desktopMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOpened = account.lastOpened != null;
    final isUnfollowed = account.status == AppConstants.statusUnfollowed;
    final folderLabel = (account.folder == null || account.folder!.isEmpty)
        ? AppConstants.folderUncategorized
        : account.folder!;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: desktopMode ? 8 : 0,
        vertical: 4,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Avatar chữ cái đầu
              AccountAvatar(letter: account.avatarLetter),

              const SizedBox(width: 12),

              // Thông tin chính
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          account.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isOpened
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                                : Theme.of(context).colorScheme.onSurface,
                            decoration: isOpened ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Huy hiệu không còn follow
                        if (isUnfollowed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Không còn follow',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        // Dấu đã xem
                        if (isOpened)
                          const Icon(Icons.done, size: 14, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Tên folder
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            folderLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Trạng thái
                        Text(
                          isUnfollowed ? 'unfollowed' : 'active',
                          style: TextStyle(
                            fontSize: 11,
                            color: isUnfollowed
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Nút yêu thích (sao)
              IconButton(
                icon: Icon(
                  account.favorite ? Icons.star : Icons.star_border,
                  color: account.favorite
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                tooltip: account.favorite ? 'Bỏ yêu thích' : 'Yêu thích',
                onPressed: onFavoriteToggle,
              ),

              // Nút menu (xóa, di chuyển folder)
              PopupMenuButton<String>(
                tooltip: 'Tùy chọn',
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'open',
                    child: Row(
                      children: [
                        const Icon(Icons.open_in_new, size: 16),
                        const SizedBox(width: 8),
                        const Text('Mở trang cá nhân'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'favorite',
                    child: Row(
                      children: [
                        Icon(account.favorite ? Icons.star : Icons.star_border),
                        const SizedBox(width: 8),
                        Text(account.favorite ? 'Bỏ yêu thích' : 'Yêu thích'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'move',
                    child: Row(
                      children: [
                        const Icon(Icons.folder_open, size: 16),
                        const SizedBox(width: 8),
                        const Text('Di chuyển folder'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Xóa', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  switch (value) {
                    case 'open':
                      onTap();
                      break;
                    case 'favorite':
                      onFavoriteToggle();
                      break;
                    case 'move':
                      onMoveToFolder(null); // di chuyển về Chưa phân loại
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
