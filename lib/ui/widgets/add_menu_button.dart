import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'neu_card.dart';

/// Các hành động trong menu "Thêm".
enum AddMenuAction { importCsv, exportCsv, addManual }

/// Nút "Thêm" màu cam, mở menu Nhập CSV / Xuất CSV / Thêm tài khoản.
class AddMenuButton extends StatelessWidget {
  final VoidCallback onImportCsv;
  final VoidCallback onExportCsv;
  final VoidCallback onAddManual;
  final bool compact;

  const AddMenuButton({
    super.key,
    required this.onImportCsv,
    required this.onExportCsv,
    required this.onAddManual,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AddMenuAction>(
      tooltip: 'Thêm / Nhập / Xuất',
      offset: const Offset(0, 46),
      color: AppColors.surfaceRaised,
      onSelected: (action) {
        switch (action) {
          case AddMenuAction.importCsv:
            onImportCsv();
            break;
          case AddMenuAction.exportCsv:
            onExportCsv();
            break;
          case AddMenuAction.addManual:
            onAddManual();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<AddMenuAction>(
          value: AddMenuAction.importCsv,
          child: _MenuItem(
            icon: Icons.file_upload_outlined,
            label: 'Nhập CSV',
          ),
        ),
        PopupMenuItem<AddMenuAction>(
          value: AddMenuAction.exportCsv,
          child: _MenuItem(
            icon: Icons.file_download_outlined,
            label: 'Xuất CSV',
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<AddMenuAction>(
          value: AddMenuAction.addManual,
          child: _MenuItem(
            icon: Icons.person_add_alt_1_outlined,
            label: 'Thêm tài khoản thủ công',
          ),
        ),
      ],
      child: NeuCard(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 9 : 11,
        ),
        radius: 14,
        compactShadow: true,
        borderColor: AppColors.outline,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 19, color: AppColors.orange),
            const SizedBox(width: 6),
            Text(
              'Thêm',
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
