import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/csv_import_result.dart';

/// Hiển thị chi tiết kết quả nhập CSV.
class ImportResultDialog extends StatelessWidget {
  final CsvImportResult result;

  const ImportResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kết quả nhập CSV'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(result.message),
            const SizedBox(height: 16),
            Row(
              children: [
                _ResultStat(
                  label: 'Mới',
                  value: result.added,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                _ResultStat(
                  label: 'Cập nhật',
                  value: result.updated,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 8),
                _ResultStat(
                  label: 'Bỏ qua',
                  value: result.skipped,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Cột open_count chỉ lưu cục bộ và không được ghi ra CSV.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ResultStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
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
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
