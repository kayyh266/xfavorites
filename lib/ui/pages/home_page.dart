import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../models/csv_import_result.dart';
import '../../models/x_account.dart';
import '../../providers/repository_provider.dart';
import '../../repositories/account_repository.dart';
import '../dialogs/add_account_dialog.dart';
import '../dialogs/folder_dialog.dart';
import '../dialogs/import_result_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../widgets/account_card.dart';
import '../widgets/add_menu_button.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_search_field.dart';
import '../widgets/desktop_drop_viewer.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/folder_card.dart';
import '../widgets/mobile_nav_bar.dart';
import '../widgets/neu_card.dart';
import '../widgets/now_opened_bar.dart';
import '../widgets/recent_card.dart';
import '../widgets/section_header.dart';
import '../widgets/sidebar.dart';
import '../widgets/sort_menu.dart';
import '../widgets/toast_host.dart';

/// Trang chính: dashboard + danh sách tài khoản, hỗ trợ desktop và điện thoại.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode(debugLabel: 'account-search');

  Timer? _toastTimer;
  ToastData? _toast;

  /// Trạng thái riêng của desktop: ép hiển thị danh sách dù không có filter.
  bool _desktopShowList = false;

  /// Tab đang chọn trên điện thoại (0: Trang chủ, 1: Yêu thích, 2: Thư mục).
  int _mobileTab = 0;
  bool _mobileFolderView = false;

  bool get _supportsDragAndDrop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // =========================================================================
  // Toast
  // =========================================================================

  void _showToast(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _toastTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _toast = ToastData(
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    });
    _toastTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _hideToast() {
    _toastTimer?.cancel();
    if (mounted) setState(() => _toast = null);
  }

  // =========================================================================
  // Điều hướng
  // =========================================================================

  void _clearSearch() {
    _searchController.clear();
    ref.read(accountRepositoryProvider.notifier).setSearchQuery('');
  }

  void _goHome({bool mobile = false}) {
    final notifier = ref.read(accountRepositoryProvider.notifier);
    notifier.selectAll();
    _clearSearch();
    if (mobile) {
      setState(() {
        _mobileTab = 0;
        _mobileFolderView = false;
      });
    } else {
      setState(() => _desktopShowList = false);
    }
  }

  void _goFavorites({bool mobile = false}) {
    final notifier = ref.read(accountRepositoryProvider.notifier);
    notifier.setFavoritesOnly(true);
    _clearSearch();
    if (mobile) {
      setState(() {
        _mobileTab = 1;
        _mobileFolderView = false;
      });
    } else {
      setState(() => _desktopShowList = true);
    }
  }

  void _openFolder(String? folder, {bool mobile = false}) {
    final notifier = ref.read(accountRepositoryProvider.notifier);
    if (folder == null) {
      notifier.selectAll();
    } else {
      notifier.setFolderFilter(folder);
    }
    _clearSearch();
    if (mobile) {
      setState(() {
        _mobileTab = 2;
        _mobileFolderView = true;
      });
    } else {
      setState(() => _desktopShowList = true);
    }
  }

  void _selectMobileTab(int index) {
    final notifier = ref.read(accountRepositoryProvider.notifier);
    switch (index) {
      case 0:
        notifier.selectAll();
        _clearSearch();
        setState(() {
          _mobileTab = 0;
          _mobileFolderView = false;
        });
        break;
      case 1:
        notifier.setFavoritesOnly(true);
        _clearSearch();
        setState(() {
          _mobileTab = 1;
          _mobileFolderView = false;
        });
        break;
      case 2:
        notifier.selectAll();
        _clearSearch();
        setState(() {
          _mobileTab = 2;
          _mobileFolderView = false;
        });
        break;
    }
  }

  // =========================================================================
  // Tài khoản
  // =========================================================================

  Future<void> _handleAccountTap(XAccount account) async {
    final repo = ref.read(accountRepositoryProvider);
    if (repo.selectionMode) {
      ref.read(accountRepositoryProvider.notifier).toggleSelection(account.id!);
      return;
    }

    if (account.id != null) {
      unawaited(ref.read(accountRepositoryProvider.notifier).markOpened(account.id!));
    }
    await _openUrl(account.link);
  }

  Future<void> _openUrl(String link) async {
    var raw = link.trim();
    if (raw.isEmpty) {
      _showToast('Tài khoản này chưa có link.');
      return;
    }
    // Bổ sung scheme nếu dữ liệu CSV chỉ lưu dạng "x.com/username".
    if (!raw.contains('://')) {
      raw = 'https://$raw';
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      _showToast('Link không hợp lệ: $link');
      return;
    }

    // Không dùng canLaunchUrl(): trên Android 11+ nó trả về false nếu
    // AndroidManifest thiếu thẻ <queries> cho scheme https, dù trình duyệt
    // vẫn mở được bằng launchUrl(). Gọi thẳng launchUrl() và xử lý kết quả.
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        _showToast('Không mở được link: $link');
      }
    } on PlatformException catch (e) {
      _showToast('Không mở được link: ${e.message ?? e.code}');
    } catch (e) {
      _showToast('Không mở được link: ${_describeError(e)}');
    }
  }

  void _toggleFavorite(XAccount account) {
    if (account.id == null) return;
    ref.read(accountRepositoryProvider.notifier).toggleFavorite(account.id!);
  }

  void _toggleSelection(XAccount account) {
    if (account.id == null) return;
    ref.read(accountRepositoryProvider.notifier).toggleSelection(account.id!);
  }

  Future<void> _moveAccountToFolder(XAccount account) async {
    if (account.id == null) return;
    final choice = await _pickFolder(title: 'Chuyển ${account.displayName} vào folder');
    if (choice == null) return;
    final folder = choice == AppConstants.menuUncategorized ? null : choice;
    await ref
        .read(accountRepositoryProvider.notifier)
        .setFolderForAccount(account.id!, folder);
    _showToast('Đã chuyển ${account.displayName} vào ${folder ?? AppConstants.folderUncategorized}');
  }

  Future<void> _moveSelectedToFolder() async {
    final repo = ref.read(accountRepositoryProvider);
    final ids = repo.selectedIds.toList();
    if (ids.isEmpty) return;

    final choice = await _pickFolder(title: 'Chuyển ${ids.length} tài khoản vào folder');
    if (choice == null) return;
    final folder = choice == AppConstants.menuUncategorized ? null : choice;
    await ref.read(accountRepositoryProvider.notifier).setFolderForAccounts(ids, folder);
    _showToast('Đã chuyển ${ids.length} tài khoản vào ${folder ?? AppConstants.folderUncategorized}');
  }

  Future<String?> _pickFolder({required String title}) async {
    final folders = ref.read(foldersProvider);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
        content: SizedBox(
          width: 360,
          height: 320,
          child: ListView.builder(
            itemCount: 1 + folders.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.folder_off_outlined, size: 19),
                  title: const Text(AppConstants.folderUncategorized),
                  onTap: () => Navigator.pop(
                    dialogContext,
                    AppConstants.menuUncategorized,
                  ),
                );
              }
              final folder = folders[index - 1];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.folder_outlined, size: 19),
                title: Text(
                  folder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(dialogContext, folder),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(XAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Text('Xóa "${account.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || account.id == null || !mounted) return;
    await ref.read(accountRepositoryProvider.notifier).deleteAccount(account.id!);
    _showToast('Đã xóa ${account.displayName}');
  }

  Future<void> _confirmDeleteSelected() async {
    final repo = ref.read(accountRepositoryProvider);
    final ids = repo.selectedIds.toList();
    if (ids.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Text('Xóa ${ids.length} tài khoản đã chọn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(accountRepositoryProvider.notifier).deleteAccounts(ids);
    _showToast('Đã xóa ${ids.length} tài khoản');
  }

  // =========================================================================
  // Folder
  // =========================================================================

  Future<void> _createFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const FolderDialog(title: 'Tạo folder mới'),
    );
    if (name == null || name.trim().isEmpty) return;

    final error = await ref
        .read(accountRepositoryProvider.notifier)
        .addFolder(name.trim());
    if (error != null) {
      _showToast(error);
    } else {
      _showToast('Đã tạo folder "${name.trim()}"');
    }
  }

  Future<void> _renameFolder(String oldName) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => FolderDialog(
        title: 'Đổi tên folder',
        initialValue: oldName,
      ),
    );
    if (newName == null ||
        newName.trim().isEmpty ||
        newName.trim() == oldName) {
      return;
    }

    final error = await ref
        .read(accountRepositoryProvider.notifier)
        .renameFolder(oldName, newName.trim());
    if (error != null) {
      _showToast(error);
    } else {
      _showToast('Đã đổi tên folder thành "${newName.trim()}"');
    }
  }

  Future<void> _deleteFolder(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa folder'),
        content: Text(
          'Xóa folder "$name"? Các tài khoản trong folder sẽ về "Chưa phân loại".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(accountRepositoryProvider.notifier).deleteFolder(name);
    _showToast('Đã xóa folder "$name"');
  }

  // =========================================================================
  // Nhập / xuất / thêm thủ công
  // =========================================================================

  Future<void> _handleImportCsv() async {
    await _runCsvImport(() {
      return ref.read(accountRepositoryProvider.notifier).importCsvFromPicker();
    });
  }

  Future<void> _handleDroppedFile(Uint8List bytes, String fileName) async {
    final lowerName = fileName.toLowerCase();
    if (!lowerName.endsWith('.csv') && !lowerName.endsWith('.txt')) {
      _showToast('Vui lòng chọn file .csv');
      return;
    }
    await _runCsvImport(() {
      return ref.read(accountRepositoryProvider.notifier).importCsvFromBytes(bytes);
    });
  }

  Future<void> _runCsvImport(
    Future<CsvImportResult?> Function() task,
  ) async {
    var dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ImportProgressDialog(),
    );

    try {
      final result = await task();
      if (!mounted) return;

      if (dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      if (result == null) return;

      _showToast(
        'Nhập hoàn tất: ${result.added} tài khoản mới, '
        '${result.updated} cập nhật, ${result.skipped} lỗi',
        actionLabel: 'Chi tiết',
        onAction: () {
          _hideToast();
          showDialog<void>(
            context: context,
            builder: (_) => ImportResultDialog(result: result),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      if (dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showToast('Nhập CSV thất bại: ${_describeError(e)}');
    }
  }

  Future<void> _handleExportCsv() async {
    try {
      final path = await ref.read(accountRepositoryProvider.notifier).exportCsvToFile();
      _showToast('Đã xuất CSV: $path');
    } catch (e) {
      _showToast('Xuất CSV thất bại: ${_describeError(e)}');
    }
  }

  Future<void> _handleAddManual() async {
    final repo = ref.read(accountRepositoryProvider);
    final account = await showDialog<XAccount>(
      context: context,
      builder: (_) => AddAccountDialog(
        folders: repo.folders,
        initialFolder: repo.selectedFolder,
      ),
    );
    if (account == null || !mounted) return;

    final normalized = XAccount.normalizeUsername(account.username);
    final existed = repo.allAccounts.any(
      (item) => XAccount.normalizeUsername(item.username) == normalized,
    );
    if (existed) {
      _showToast('Username ${account.displayName} đã tồn tại');
      return;
    }

    await ref.read(accountRepositoryProvider.notifier).addAccount(account);
    _showToast('Đã thêm ${account.displayName}');
  }

  Future<void> _openSettings() async {
    final repo = ref.read(accountRepositoryProvider);
    final action = await showDialog<SettingsAction>(
      context: context,
      builder: (_) => SettingsDialog(
        totalCount: repo.countAll,
        favoriteCount: repo.favoriteCount,
        folderCount: repo.folders.length,
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case SettingsAction.importCsv:
        await _handleImportCsv();
        break;
      case SettingsAction.exportCsv:
        await _handleExportCsv();
        break;
    }
  }

  String _describeError(Object error) {
    final text = error.toString();
    const prefix = 'Exception: ';
    return text.startsWith(prefix) ? text.substring(prefix.length) : text;
  }

  // =========================================================================
  // Phím tắt
  // =========================================================================

  Map<ShortcutActivator, VoidCallback> _buildShortcuts() {
    return {
      const SingleActivator(LogicalKeyboardKey.keyA, control: true): () {
        if (_searchFocus.hasFocus) return;
        final repo = ref.read(accountRepositoryProvider);
        final isDesktop =
            MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;
        final listVisible = !isDesktop ||
            _desktopShowList ||
            repo.selectedFolder != null ||
            repo.favoritesOnly ||
            _mobileTab == 1 ||
            _mobileFolderView;
        if (!listVisible) return;
        repo.selectAllVisible();
      },
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
        _searchFocus.requestFocus();
      },
      const SingleActivator(LogicalKeyboardKey.delete): () {
        if (_searchFocus.hasFocus) return;
        final repo = ref.read(accountRepositoryProvider);
        if (repo.selectionMode) {
          _confirmDeleteSelected();
        }
      },
      const SingleActivator(LogicalKeyboardKey.escape): () {
        final repo = ref.read(accountRepositoryProvider);
        if (repo.selectionMode) {
          repo.clearSelection();
        }
      },
    };
  }

  // =========================================================================
  // Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(accountRepositoryProvider);
    final accounts = ref.watch(filteredAccountsProvider);
    final folders = ref.watch(foldersProvider);
    final recents = ref.watch(recentAccountsProvider);
    final latest = ref.watch(latestOpenedProvider);
    final folderCounts = ref.watch(folderCountsProvider);
    final isDesktop =
        MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;

    Widget body = isDesktop
        ? _buildDesktop(repo, accounts, folders, recents, latest, folderCounts)
        : _buildMobile(repo, accounts, folders, recents, latest, folderCounts);

    if (repo.loadError != null) {
      body = Column(
        children: [
          MaterialBanner(
            backgroundColor: AppColors.surfaceRaised,
            leading: const Icon(Icons.error_outline, color: AppColors.danger),
            content: Text(repo.loadError!),
            actions: [
              TextButton(
                onPressed: () =>
                    ref.read(accountRepositoryProvider.notifier).reload(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
          Expanded(child: body),
        ],
      );
    }

    final scaffold = Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: body),
    );

    if (_supportsDragAndDrop) {
      return DropViewer(
        onDropFile: _handleDroppedFile,
        onError: _showToast,
        child: scaffold,
      );
    }
    return scaffold;
  }

  // =========================================================================
  // Desktop
  // =========================================================================

  Widget _buildDesktop(
    AccountRepository repo,
    List<XAccount> accounts,
    List<String> folders,
    List<XAccount> recents,
    XAccount? latest,
    Map<String, int> folderCounts,
  ) {
    final showList = _desktopShowList ||
        repo.selectedFolder != null ||
        repo.favoritesOnly;

    final main = Focus(
      autofocus: true,
      child: CallbackShortcuts(
        bindings: _buildShortcuts(),
        child: Stack(
          children: [
            Positioned.fill(
              child: showList
                  ? _buildDesktopList(repo, accounts, folders)
                  : _buildDashboard(repo, folders, recents, folderCounts),
            ),
            Positioned(
              top: 18,
              right: 24,
              child: ToastHost(
                toast: _toast,
                onClose: _hideToast,
                width: 360,
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: repo.selectionMode
                      ? SelectionActionBar(
                          count: repo.selectedIds.length,
                          onMoveFolder: _moveSelectedToFolder,
                          onDelete: _confirmDeleteSelected,
                          onClear: () => ref
                              .read(accountRepositoryProvider.notifier)
                              .clearSelection(),
                        )
                      : latest == null
                          ? const SizedBox.shrink()
                          : NowOpenedBar(
                              account: latest,
                              onOpen: () => _handleAccountTap(latest),
                              onFavorite: () => _toggleFavorite(latest),
                              onFolder: () => _moveAccountToFolder(latest),
                              onDelete: () => _confirmDeleteAccount(latest),
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        SizedBox(
          width: 240,
          child: SideBar(
            selectedFolder: repo.selectedFolder,
            favoritesOnly: repo.favoritesOnly,
            totalCount: repo.countAll,
            favoriteCount: repo.favoriteCount,
            uncategorizedCount: repo.uncategorizedCount,
            folders: folders,
            folderCounts: folderCounts,
            onHome: _goHome,
            onFavorites: _goFavorites,
            onFolderSelected: (folder) => _openFolder(folder),
            onAddFolder: _createFolder,
            onRenameFolder: _renameFolder,
            onDeleteFolder: _deleteFolder,
            onSettings: _openSettings,
          ),
        ),
        Expanded(child: main),
      ],
    );
  }

  Widget _buildDashboard(
    AccountRepository repo,
    List<String> folders,
    List<XAccount> recents,
    Map<String, int> folderCounts,
  ) {
    final maxOpen = recents.fold<int>(
      1,
      (max, account) => account.openCount > max ? account.openCount : max,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 120),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MỞ GẦN ĐÂY',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'App chỉ lưu danh sách trên máy bạn — không gửi dữ liệu ra ngoài. '
                    '${repo.countAll} tài khoản · ${repo.favoriteCount} yêu thích.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            AddMenuButton(
              onImportCsv: _handleImportCsv,
              onExportCsv: _handleExportCsv,
              onAddManual: _handleAddManual,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                recents.isEmpty
                    ? 'Các tài khoản bạn mở sẽ xuất hiện tại đây.'
                    : 'Tối đa ${AppConstants.recentLimit} tài khoản, mới nhất trước.',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${recents.length}/${AppConstants.recentLimit}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (recents.isEmpty)
          _emptyState(
            icon: Icons.history_rounded,
            title: 'Chưa mở tài khoản nào',
            subtitle:
                'Bấm vào một tài khoản để mở trang cá nhân bằng trình duyệt ngoài.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recents.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 122,
                ),
                itemBuilder: (context, index) {
                  final account = recents[index];
                  final progress = account.openCount == 0
                      ? 0.12
                      : (account.openCount / maxOpen).clamp(0.0, 1.0);
                  return RecentCard(
                    account: account,
                    progress: progress,
                    onTap: () => _handleAccountTap(account),
                  );
                },
              );
            },
          ),
        const SizedBox(height: 28),
        SectionHeader(
          title: 'Thư mục',
          subtitle:
              '${folders.length} folder · ${repo.uncategorizedCount} chưa phân loại',
          trailing: _addFolderChip(),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1400
                ? 5
                : constraints.maxWidth >= 1050
                    ? 4
                    : 3;
            final itemCount = 3 + folders.length;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 136,
              ),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FolderCard(
                    title: AppConstants.filterAll,
                    count: repo.countAll,
                    icon: Icons.grid_view_rounded,
                    onTap: () => _openFolder(null),
                  );
                }
                if (index == 1) {
                  return FolderCard(
                    title: AppConstants.filterFavorites,
                    count: repo.favoriteCount,
                    icon: Icons.star_rounded,
                    onTap: _goFavorites,
                  );
                }
                if (index == 2) {
                  return FolderCard(
                    title: AppConstants.folderUncategorized,
                    count: repo.uncategorizedCount,
                    icon: Icons.folder_off_outlined,
                    onTap: () => _openFolder(
                      AppConstants.folderUncategorized,
                    ),
                  );
                }

                final folder = folders[index - 3];
                return FolderCard(
                  title: folder,
                  count: folderCounts[folder] ?? 0,
                  onTap: () => _openFolder(folder),
                  onRename: () => _renameFolder(folder),
                  onDelete: () => _deleteFolder(folder),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDesktopList(
    AccountRepository repo,
    List<XAccount> accounts,
    List<String> folders,
  ) {
    final title = repo.favoritesOnly
        ? AppConstants.filterFavorites
        : repo.selectedFolder == null
            ? 'Tất cả tài khoản'
            : repo.selectedFolder == AppConstants.folderUncategorized
                ? AppConstants.folderUncategorized
                : repo.selectedFolder!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 8),
          child: Column(
            children: [
              Row(
                children: [
                  _backButton(onTap: _goHome),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${accounts.length} tài khoản · Chọn nhiều bằng Ctrl+A',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  AddMenuButton(
                    onImportCsv: _handleImportCsv,
                    onExportCsv: _handleExportCsv,
                    onAddManual: _handleAddManual,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: (value) => ref
                          .read(accountRepositoryProvider.notifier)
                          .setSearchQuery(value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SortMenu(
                    current: repo.sortMode,
                    onSelected: (mode) => ref
                        .read(accountRepositoryProvider.notifier)
                        .setSortMode(mode),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _accountList(
            repo,
            accounts,
            folders,
            desktopMode: true,
            bottomPadding: 110,
          ),
        ),
      ],
    );
  }

  Widget _accountList(
    AccountRepository repo,
    List<XAccount> accounts,
    List<String> folders, {
    required bool desktopMode,
    double bottomPadding = 100,
  }) {
    if (accounts.isEmpty) {
      return _emptyState(
        icon: Icons.person_search_outlined,
        title: 'Không có tài khoản',
        subtitle: repo.searchQuery.isNotEmpty
            ? 'Không tìm thấy username chứa "${repo.searchQuery}".'
            : 'Nhập CSV hoặc thêm tài khoản thủ công để bắt đầu.',
        padding: EdgeInsets.fromLTRB(
          desktopMode ? 28 : 16,
          desktopMode ? 40 : 24,
          desktopMode ? 28 : 16,
          bottomPadding,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        desktopMode ? 28 : 0,
        4,
        desktopMode ? 28 : 0,
        bottomPadding,
      ),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return AccountCard(
          key: ValueKey(account.id),
          account: account,
          folders: folders,
          selected:
              account.id != null && repo.selectedIds.contains(account.id),
          selectionMode: repo.selectionMode,
          desktopMode: desktopMode,
          onTap: () => _handleAccountTap(account),
          onLongPress: () => _toggleSelection(account),
          onFavoriteToggle: () => _toggleFavorite(account),
          onDelete: () => _confirmDeleteAccount(account),
          onMoveToFolder: (folder) => _setAccountFolder(account, folder),
        );
      },
    );
  }

  Future<void> _setAccountFolder(XAccount account, String? folder) async {
    if (account.id == null) return;
    await ref
        .read(accountRepositoryProvider.notifier)
        .setFolderForAccount(account.id!, folder);
    _showToast(
      'Đã chuyển ${account.displayName} vào '
      '${folder ?? AppConstants.folderUncategorized}',
    );
  }

  Widget _backButton({required VoidCallback onTap}) {
    return NeuCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      radius: 12,
      compactShadow: true,
      child: const Icon(
        Icons.arrow_back_rounded,
        size: 20,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _addFolderChip() {
    return InkWell(
      onTap: _createFolder,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outline),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 15, color: AppColors.orange),
            SizedBox(width: 4),
            Text(
              'Folder',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 8,
    ),
  }) {
    return Padding(
      padding: padding,
      child: NeuCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        compactShadow: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 26, color: AppColors.accent),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Mobile
  // =========================================================================

  Widget _buildMobile(
    AccountRepository repo,
    List<XAccount> accounts,
    List<String> folders,
    List<XAccount> recents,
    XAccount? latest,
    Map<String, int> folderCounts,
  ) {
    final hasBottomBar = repo.selectionMode || latest != null;
    final bottomPadding = hasBottomBar ? 92.0 : 20.0;

    Widget content;
    if (_mobileTab == 2 && _mobileFolderView) {
      content = _buildMobileFolderList(repo, accounts, folders, bottomPadding);
    } else if (_mobileTab == 2) {
      content = _buildMobileFolderTab(repo, folders, folderCounts, bottomPadding);
    } else if (_mobileTab == 1) {
      content = Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SectionHeader(
              title: 'Yêu thích',
              subtitle: 'Tài khoản đã đánh dấu yêu thích',
              bottomSpacing: 8,
            ),
          ),
          Expanded(
            child: _accountList(
              repo,
              accounts,
              folders,
              desktopMode: false,
              bottomPadding: bottomPadding,
            ),
          ),
        ],
      );
    } else {
      content = _buildMobileHome(
        repo,
        accounts,
        folders,
        recents,
        folderCounts,
        bottomPadding,
      );
    }

    return Column(
      children: [
        _buildMobileHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: AppSearchField(
            controller: _searchController,
            focusNode: _searchFocus,
            compact: true,
            onChanged: (value) => ref
                .read(accountRepositoryProvider.notifier)
                .setSearchQuery(value),
          ),
        ),
        if (_mobileTab == 0 && !_mobileFolderView)
          FilterChipRow(
            folders: folders,
            selectedFolder: repo.selectedFolder,
            favoritesOnly: repo.favoritesOnly,
            onFolderSelected: (folder) {
              final notifier = ref.read(accountRepositoryProvider.notifier);
              if (folder == null) {
                notifier.selectAll();
              } else {
                notifier.setFolderFilter(folder);
              }
            },
            onFavoritesSelected: () => _goFavorites(mobile: true),
          ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: content),
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Align(
                  alignment: Alignment.topRight,
                  child: ToastHost(
                    toast: _toast,
                    onClose: _hideToast,
                    width: MediaQuery.of(context).size.width > 384
                        ? 360
                        : MediaQuery.of(context).size.width - 24,
                  ),
                ),
              ),
              if (hasBottomBar)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: repo.selectionMode
                      ? SelectionActionBar(
                          count: repo.selectedIds.length,
                          onMoveFolder: _moveSelectedToFolder,
                          onDelete: _confirmDeleteSelected,
                          onClear: () => ref
                              .read(accountRepositoryProvider.notifier)
                              .clearSelection(),
                        )
                      : NowOpenedBar(
                          account: latest!,
                          compact: true,
                          onOpen: () => _handleAccountTap(latest),
                          onFavorite: () => _toggleFavorite(latest),
                          onFolder: () => _moveAccountToFolder(latest),
                          onDelete: () => _confirmDeleteAccount(latest),
                        ),
                ),
            ],
          ),
        ),
        MobileNavBar(
          currentIndex: _mobileTab,
          onChanged: _selectMobileTab,
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          const Expanded(
            child: AppLogo(size: 32, compact: true),
          ),
          NeuCard(
            onTap: _openSettings,
            padding: const EdgeInsets.all(14),
            radius: 12,
            compactShadow: true,
            child: const Icon(
              Icons.settings_outlined,
              size: 19,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          AddMenuButton(
            compact: true,
            onImportCsv: _handleImportCsv,
            onExportCsv: _handleExportCsv,
            onAddManual: _handleAddManual,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHome(
    AccountRepository repo,
    List<XAccount> accounts,
    List<String> folders,
    List<XAccount> recents,
    Map<String, int> folderCounts,
    double bottomPadding,
  ) {
    final maxOpen = recents.fold<int>(
      1,
      (max, account) => account.openCount > max ? account.openCount : max,
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SectionHeader(
                title: 'Mở gần đây',
                subtitle: recents.isEmpty
                    ? 'Các tài khoản bạn mở sẽ xuất hiện tại đây.'
                    : 'Vuốt ngang để xem thêm.',
                trailing: Text(
                  '${recents.length}/${AppConstants.recentLimit}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              if (recents.isEmpty)
                _emptyState(
                  icon: Icons.history_rounded,
                  title: 'Chưa mở tài khoản nào',
                  subtitle: 'Chạm vào tài khoản để mở bằng trình duyệt ngoài.',
                )
              else
                SizedBox(
                  height: 128,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: recents.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final account = recents[index];
                      final progress = account.openCount == 0
                          ? 0.12
                          : (account.openCount / maxOpen).clamp(0.0, 1.0);
                      return SizedBox(
                        width: 238,
                        child: RecentCard(
                          account: account,
                          progress: progress,
                          onTap: () => _handleAccountTap(account),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Thư mục',
                subtitle:
                    '${folders.length} folder · ${repo.uncategorizedCount} chưa phân loại',
                trailing: _addFolderChip(),
              ),
              _mobileFolderGrid(repo, folders, folderCounts),
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Tài khoản',
                subtitle: '${accounts.length} tài khoản trong bộ lọc hiện tại',
                bottomSpacing: 4,
              ),
            ]),
          ),
        ),
        if (accounts.isEmpty)
          SliverToBoxAdapter(
            child: _emptyState(
              icon: Icons.person_search_outlined,
              title: 'Không có tài khoản',
              subtitle: repo.searchQuery.isNotEmpty
                  ? 'Không tìm thấy username chứa "${repo.searchQuery}".'
                  : 'Nhập CSV hoặc thêm tài khoản thủ công để bắt đầu.',
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            ),
          )
        else
          SliverList.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return AccountCard(
                key: ValueKey(account.id),
                account: account,
                folders: folders,
                selected: account.id != null &&
                    repo.selectedIds.contains(account.id),
                selectionMode: repo.selectionMode,
                onTap: () => _handleAccountTap(account),
                onLongPress: () => _toggleSelection(account),
                onFavoriteToggle: () => _toggleFavorite(account),
                onDelete: () => _confirmDeleteAccount(account),
                onMoveToFolder: (folder) => _setAccountFolder(account, folder),
              );
            },
          ),
        SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
      ],
    );
  }

  Widget _buildMobileFolderTab(
    AccountRepository repo,
    List<String> folders,
    Map<String, int> folderCounts,
    double bottomPadding,
  ) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding),
      children: [
        SectionHeader(
          title: 'Thư mục',
          subtitle:
              '${folders.length} folder · ${repo.uncategorizedCount} chưa phân loại',
          trailing: _addFolderChip(),
        ),
        _mobileFolderGrid(repo, folders, folderCounts),
      ],
    );
  }

  Widget _mobileFolderGrid(
    AccountRepository repo,
    List<String> folders,
    Map<String, int> folderCounts,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3 + folders.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 132,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return FolderCard(
            title: AppConstants.filterAll,
            count: repo.countAll,
            icon: Icons.grid_view_rounded,
            onTap: () => _selectMobileTab(0),
          );
        }
        if (index == 1) {
          return FolderCard(
            title: AppConstants.filterFavorites,
            count: repo.favoriteCount,
            icon: Icons.star_rounded,
            onTap: () => _selectMobileTab(1),
          );
        }
        if (index == 2) {
          return FolderCard(
            title: AppConstants.folderUncategorized,
            count: repo.uncategorizedCount,
            icon: Icons.folder_off_outlined,
            onTap: () => _openFolder(
              AppConstants.folderUncategorized,
              mobile: true,
            ),
          );
        }

        final folder = folders[index - 3];
        return FolderCard(
          title: folder,
          count: folderCounts[folder] ?? 0,
          onTap: () => _openFolder(folder, mobile: true),
          onRename: () => _renameFolder(folder),
          onDelete: () => _deleteFolder(folder),
        );
      },
    );
  }

  Widget _buildMobileFolderList(
    AccountRepository repo,
    List<XAccount> accounts,
    List<String> folders,
    double bottomPadding,
  ) {
    final title = repo.selectedFolder == null
        ? 'Tất cả tài khoản'
        : repo.selectedFolder == AppConstants.folderUncategorized
            ? AppConstants.folderUncategorized
            : repo.selectedFolder!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 16, 4),
          child: Row(
            children: [
              _backButton(
                onTap: () {
                  ref.read(accountRepositoryProvider.notifier).selectAll();
                  _clearSearch();
                  setState(() {
                    _mobileFolderView = false;
                    _mobileTab = 2;
                  });
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${accounts.length} tài khoản',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SortMenu(
                current: repo.sortMode,
                onSelected: (mode) => ref
                    .read(accountRepositoryProvider.notifier)
                    .setSortMode(mode),
              ),
            ],
          ),
        ),
        Expanded(
          child: _accountList(
            repo,
            accounts,
            folders,
            desktopMode: false,
            bottomPadding: bottomPadding,
          ),
        ),
      ],
    );
  }
}

class _ImportProgressDialog extends StatelessWidget {
  const _ImportProgressDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      title: Text('Đang nhập CSV'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              child: LinearProgressIndicator(minHeight: 6),
            ),
            SizedBox(height: 16),
            Text('Đang đọc file và cập nhật dữ liệu...'),
          ],
        ),
      ),
    );
  }
}
