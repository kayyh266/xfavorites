import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import 'neu_card.dart';

/// Menu chọn chế độ sắp xếp tài khoản.
class SortMenu extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelected;

  const SortMenu({
    super.key,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Sắp xếp',
      offset: const Offset(0, 44),
      color: AppColors.surfaceRaised,
      initialValue: current,
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: AppConstants.sortAz,
          child: Text('A-Z'),
        ),
        PopupMenuItem<String>(
          value: AppConstants.sortNewest,
          child: Text('Mới thêm'),
        ),
        PopupMenuItem<String>(
          value: AppConstants.sortFavoritesFirst,
          child: Text('Yêu thích trước'),
        ),
      ],
      child: NeuCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        radius: 13,
        compactShadow: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swap_vert_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              current,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
