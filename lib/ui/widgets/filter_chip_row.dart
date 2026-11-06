import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import 'neu_card.dart';

/// Hàng chip lọc cuộn ngang: Tất cả / Yêu thích / Chưa phân loại / từng folder.
class FilterChipRow extends StatelessWidget {
  final List<String> folders;
  final String? selectedFolder;
  final bool favoritesOnly;
  final ValueChanged<String?> onFolderSelected;
  final VoidCallback? onFavoritesSelected;
  final Map<String, int>? counts;

  const FilterChipRow({
    super.key,
    required this.folders,
    required this.selectedFolder,
    required this.onFolderSelected,
    this.favoritesOnly = false,
    this.onFavoritesSelected,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    // Thứ tự: Tất cả, Yêu thích, Chưa phân loại, sau đó là các folder.
    final itemCount = 3 + folders.length;

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _chip(
              label: AppConstants.filterAll,
              selected: selectedFolder == null && !favoritesOnly,
              onSelected: () => onFolderSelected(null),
            );
          }
          if (index == 1) {
            return _chip(
              label: AppConstants.filterFavorites,
              selected: favoritesOnly,
              onSelected: () => onFavoritesSelected?.call(),
            );
          }
          if (index == 2) {
            return _chip(
              label: AppConstants.filterUncategorized,
              selected: !favoritesOnly &&
                  selectedFolder == AppConstants.folderUncategorized,
              onSelected: () => onFolderSelected(AppConstants.folderUncategorized),
            );
          }

          final folder = folders[index - 3];
          return _chip(
            label: folder,
            selected: !favoritesOnly && selectedFolder == folder,
            onSelected: () => onFolderSelected(folder),
          );
        },
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: NeuCard(
        onTap: onSelected,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        radius: 999,
        compactShadow: !selected,
        color: selected ? AppColors.accent : AppColors.surface,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_rounded,
                size: 15,
                color: AppColors.onBright,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.onBright : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
