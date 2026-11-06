import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// Hàng chip lọc cuộn ngang: Tất cả / Yêu thích / Chưa phân loại / từng folder.
class FilterChipRow extends StatelessWidget {
  final List<String> folders;
  final String? selectedFolder;
  final bool favoritesOnly;
  final ValueChanged<String?> onFolderSelected;
  final VoidCallback? onFavoritesSelected;

  const FilterChipRow({
    super.key,
    required this.folders,
    required this.selectedFolder,
    required this.onFolderSelected,
    this.favoritesOnly = false,
    this.onFavoritesSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Thứ tự: Tất cả, Yêu thích, Chưa phân loại, sau đó là các folder.
    final itemCount = 3 + folders.length;

    return SizedBox(
      height: AppConstants.minTouchSize,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
      ),
    );
  }
}
