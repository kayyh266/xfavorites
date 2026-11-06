import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../models/x_account.dart';

/// Dialog thêm tài khoản thủ công. Trả về [XAccount] khi lưu.
class AddAccountDialog extends StatefulWidget {
  final List<String> folders;
  final String? initialFolder;

  const AddAccountDialog({
    super.key,
    required this.folders,
    this.initialFolder,
  });

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  late String _folderValue;
  bool _favorite = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFolder;
    _folderValue = (initial == null ||
            initial.isEmpty ||
            initial == AppConstants.folderUncategorized)
        ? ''
        : initial;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _usernameController.text
        .trim()
        .replaceFirst(RegExp(r'^@+'), '')
        .trim();
    if (username.isEmpty) {
      setState(() => _error = 'Vui lòng nhập username');
      return;
    }
    if (username.contains(RegExp(r'\s'))) {
      setState(() => _error = 'Username không được chứa khoảng trắng');
      return;
    }

    final rawLink = _linkController.text.trim();
    final link = rawLink.isEmpty ? 'https://x.com/$username' : rawLink;

    Navigator.pop(
      context,
      XAccount(
        username: username,
        link: link,
        favorite: _favorite,
        folder: _folderValue.isEmpty ? null : _folderValue,
        status: AppConstants.statusActive,
        addedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm tài khoản'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _usernameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'vi_du',
                  prefixText: '@',
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link (không bắt buộc)',
                  hintText: 'https://x.com/username',
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Folder'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _folderValue,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: AppColors.surfaceRaised,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text(AppConstants.folderUncategorized),
                      ),
                      for (final folder in widget.folders)
                        DropdownMenuItem<String>(
                          value: folder,
                          child: Text(
                            folder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _folderValue = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                value: _favorite,
                onChanged: (value) => setState(() => _favorite = value),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.accent,
                title: const Text(
                  'Đánh dấu yêu thích',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
