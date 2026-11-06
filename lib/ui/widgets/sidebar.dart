import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import 'app_logo.dart';
import 'neu_avatar.dart';
import 'neu_card.dart';

/// Sidebar máy tính (240px): logo, điều hướng, danh sách folder, cài đặt.
class SideBar extends StatelessWidget {
  final String? selectedFolder;
  final bool favoritesOnly;
  final int totalCount;
  final int favoriteCount;
  final int uncategorizedCount;
  final List<String> folders;
  final Map<String, int> folderCounts;
  final VoidCallback onHome;
  final VoidCallback onFavorites;
  final ValueChanged<String?> onFolderSelected;
  final VoidCallback onAddFolder;
  final ValueChanged<String> onRenameFolder;
  final ValueChanged<String> onDeleteFolder;
  final VoidCallback onSettings;

  const SideBar({
    super.key,
    required this.selectedFolder,
    required this.favoritesOnly,
    required this.totalCount,
    required this.favoriteCount,
    required this.uncategorizedCount,
    required this.folders,
    required this.folderCounts,
    required this.onHome,
    required this.onFavorites,
    required this.onFolderSelected,
    required this.onAddFolder,
    required this.onRenameFolder,
    required this.onDeleteFolder,
    required this.onSettings,
  });

  bool get _homeSelected => !favoritesOnly && selectedFolder == null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          right: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 2, 4, 18),
                child: AppLogo(size: 40),
              ),
              _SidebarNavItem(
                icon: Icons.home_rounded,
                label: 'Trang chủ',
                count: totalCount,
                selected: _homeSelected,
                onTap: onHome,
              ),
              const SizedBox(height: 6),
              _SidebarNavItem(
                icon: Icons.star_rounded,
                label: AppConstants.filterFavorites,
                count: favoriteCount,
                selected: favoritesOnly,
                onTap: onFavorites,
              ),
              const SizedBox(height: 6),
              _SidebarNavItem(
                icon: Icons.folder_off_outlined,
                label: AppConstants.filterUncategorized,
                count: uncategorizedCount,
                selected: !favoritesOnly &&
                    selectedFolder == AppConstants.folderUncategorized,
                onTap: () =>
                    onFolderSelected(AppConstants.folderUncategorized),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'THƯ MỤC',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  _AddFolderButton(onTap: onAddFolder),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: folders.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          'Chưa có folder. Nhấn + để tạo folder đầu tiên.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          final folder = folders[index];
                          final selected = !favoritesOnly &&
                              selectedFolder == folder;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: GestureDetector(
                              onSecondaryTapUp: (details) => _showFolderMenu(
                                context,
                                details.globalPosition,
                                folder,
                              ),
                              child: NeuCard(
                                onTap: () => onFolderSelected(folder),
                                selected: selected,
                                compactShadow: true,
                                radius: 12,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 7,
                                ),
                                child: Row(
                                  children: [
                                    NeuAvatar(
                                      label: folder,
                                      size: 30,
                                      outlined: selected,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            folder,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            '${folderCounts[folder] ?? 0} tài khoản',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Tùy chọn folder',
                                      color: AppColors.surfaceRaised,
                                      padding: EdgeInsets.zero,
                                      offset: const Offset(0, 30),
                                      onSelected: (value) {
                                        if (value == 'rename') {
                                          onRenameFolder(folder);
                                        } else if (value == 'delete') {
                                          onDeleteFolder(folder);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem<String>(
                                          value: 'rename',
                                          child: Text('Đổi tên'),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text(
                                            'Xóa',
                                            style: TextStyle(
                                              color: AppColors.danger,
                                            ),
                                          ),
                                        ),
                                      ],
                                      child: const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Icon(
                                          Icons.more_horiz_rounded,
                                          size: 16,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 18),
              _SidebarNavItem(
                icon: Icons.settings_outlined,
                label: 'Cài đặt',
                selected: false,
                onTap: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFolderMenu(
    BuildContext context,
    Offset position,
    String folder,
  ) async {
    final result = await showMenu<String>(
      context: context,
      color: AppColors.surfaceRaised,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: const [
        PopupMenuItem<String>(
          value: 'rename',
          child: Text('Đổi tên folder'),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Text(
            'Xóa folder',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    );
    if (result == 'rename') {
      onRenameFolder(folder);
    } else if (result == 'delete') {
      onDeleteFolder(folder);
    }
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      onTap: onTap,
      selected: selected,
      compactShadow: !selected,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: selected ? AppColors.accent : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.18)
                    : AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddFolderButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddFolderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tạo folder mới',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outline),
          ),
          child: const Icon(
            Icons.add_rounded,
            size: 17,
            color: AppColors.orange,
          ),
        ),
      ),
    );
  }
}
