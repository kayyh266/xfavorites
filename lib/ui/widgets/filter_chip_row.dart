import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// Hàng chip lọc cuộn ngang: Tất cả / Yêu thích / Chưa phân loại / từng folder.
class FilterChipRow extends StatelessWidget {
  final List<String> folders;
  final String? selectedFolder;
  final ValueChanged<String?> onFolderSelected;

  const FilterChipRow({
    super.key,
    required this.folders,
    required this.selectedFolder,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = <String?>[
      null, // Tất cả (null = không lọc folder)
      AppConstants.folderUncategorized, // Chưa phân loại
      ...folders,
    ];

    return SizedBox(
      height: AppConstants.minTouchSize,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final folder = items[index];
          final isSelected = selectedFolder == folder;
          final label = folder == null
              ? AppConstants.filterAll
              : (folder == AppConstants.folderUncategorized
                  ? AppConstants.filterUncategorized
                  : folder);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) => onFolderSelected(selected ? folder : null),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}
