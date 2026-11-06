import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';

/// Hành động người dùng chọn trong dialog Cài đặt.
enum SettingsAction { importCsv, exportCsv }

/// Dialog Cài đặt: nhập/xuất CSV và thông tin ứng dụng.
class SettingsDialog extends StatelessWidget {
  final int totalCount;
  final int favoriteCount;
  final int folderCount;

  const SettingsDialog({
    super.key,
    required this.totalCount,
    required this.favoriteCount,
    required this.folderCount,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cài đặt'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _Stat(
                    label: 'Tài khoản',
                    value: '$totalCount',
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  _Stat(
                    label: 'Yêu thích',
                    value: '$favoriteCount',
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 8),
                  _Stat(
                    label: 'Folder',
                    value: '$folderCount',
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ActionRow(
                icon: Icons.file_upload_outlined,
                title: 'Nhập CSV',
                subtitle: 'Thêm / cập nhật danh sách từ file CSV',
                onTap: () => Navigator.pop(context, SettingsAction.importCsv),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.file_download_outlined,
                title: 'Xuất CSV',
                subtitle: 'Lưu toàn bộ tài khoản ra file 7 cột',
                onTap: () => Navigator.pop(context, SettingsAction.exportCsv),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outline),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppConstants.appName} · Phiên bản 1.0.0',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'App chỉ lưu danh sách trên máy bạn — không gửi dữ liệu ra ngoài.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
