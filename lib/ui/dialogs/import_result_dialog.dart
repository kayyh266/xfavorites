import 'package:flutter/material.dart';
import '../../models/csv_import_result.dart';

/// Hiển thị thông báo kết quả nhập CSV dưới dạng dialog.
class ImportResultDialog extends StatelessWidget {
  final CsvImportResult result;

  const ImportResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kết quả nhập CSV'),
      content: Text(result.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
