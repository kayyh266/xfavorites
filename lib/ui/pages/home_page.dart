import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/csv_import_result.dart';
import '../../models/x_account.dart';
import '../../repositories/account_repository.dart';
import '../../providers/repository_provider.dart';
import '../../core/constants.dart';
import '../dialogs/import_result_dialog.dart';
import '../widgets/account_list_item.dart';
import '../widgets/desktop_drop_viewer.dart';
import '../widgets/filter_chip_row.dart';
import '../dialogs/folder_dialog.dart';

/// Trang chính của ứng dụng. Hỗ trợ cả điện thoại (một cột) và máy tính (2-3 cột).
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  /// Chỉ bật kéo thả file trên desktop (Windows/Linux/macOS).
  bool get _supportsDragAndDrop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Hành động
  // -------------------------------------------------------------------------

  /// Mở hộp chọn file CSV rồi nhập dữ liệu.
  Future<void> _handleImportCsv() async {
    await _runCsvImport(() {
      final repo = ref.read(accountRepositoryProvider.notifier);
      return repo.importCsvFromPicker();
    });
  }

  /// Xử lý file CSV được kéo thả trên desktop.
  Future<void> _handleDroppedFile(Uint8List bytes, String fileName) async {
    final lowerName = fileName.toLowerCase();
    if (!lowerName.endsWith('.csv') && !lowerName.endsWith('.txt')) {
      _showMessage('Vui lòng chọn file .csv');
      return;
    }

    await _runCsvImport(() {
      final repo = ref.read(accountRepositoryProvider.notifier);
      return repo.importCsvFromBytes(bytes);
    });
  }

  /// Chạy một tác vụ nhập CSV, hiện tiến trình và hiện kết quả / lỗi.
  ///
  /// Dùng chung cho nút Nhập CSV (FAB, menu, toolbar desktop) và kéo thả file.
  Future<void> _runCsvImport(Future<CsvImportResult?> Function() task) async {
    var dialogOpen = true;

    // Hiện tiến trình trong lúc đọc file / ghi CSDL.
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

      // Người dùng hủy chọn file -> không thông báo.
      if (result == null) return;

      await showDialog<void>(
        context: context,
        builder: (_) => ImportResultDialog(result: result),
      );
    } catch (e) {
      if (!mounted) return;

      if (dialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }

      _showMessage('Nhập CSV thất bại: ${_describeError(e)}');
    }
  }

  /// Bỏ tiền tố "Exception: " cho thông báo lỗi dễ đọc.
  String _describeError(Object error) {
    final text = error.toString();
    const prefix = 'Exception: ';
    return text.startsWith(prefix) ? text.substring(prefix.length) : text;
  }

  Future<void> _handleExportCsv() async {
    final repo = ref.read(accountRepositoryProvider.notifier);
    try {
      final path = await repo.exportCsvToFile();
      _showMessage('Đã xuất CSV: $path');
    } catch (e) {
      _showMessage('Xuất CSV thất bại: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openAccountUrl(String link) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _createFolder() async {
    final repo = ref.read(accountRepositoryProvider.notifier);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const FolderDialog(title: 'Tạo folder mới'),
    );
    if (name == null || name.trim().isEmpty) return;

    final error = await repo.addFolder(name.trim());
    if (error != null) _showMessage(error);
  }

  Future<void> _renameFolder(String oldName) async {
    final repo = ref.read(accountRepositoryProvider.notifier);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => FolderDialog(
        title: 'Đổi tên folder',
        initialValue: oldName,
      ),
    );
    if (newName == null ||
        newName.trim().isEmpty ||
        newName.trim() == oldName) {
      return;
    }

    final error = await repo.renameFolder(oldName, newName.trim());
    if (error != null) _showMessage(error);
  }

  Future<void> _deleteFolder(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa folder'),
        content: Text('Xóa folder "$name"? Các tài khoản trong folder sẽ về "Chưa phân loại".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(accountRepositoryProvider.notifier).deleteFolder(name);
    }
  }

  void _deleteSelectedAccounts() async {
    final repo = ref.read(accountRepositoryProvider.notifier);
    final ids = repo.selectedIds.toList();
    if (ids.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Text('Xóa ${ids.length} tài khoản đã chọn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await repo.deleteAccounts(ids);
    }
  }

  void _moveSelectedToFolder(String? folder) async {
    final repo = ref.read(accountRepositoryProvider.notifier);
    await repo.setFolderForAccounts(repo.selectedIds.toList(), folder);
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(accountRepositoryProvider);
    final accounts = ref.watch(filteredAccountsProvider);
    final folders = ref.watch(foldersProvider);
    final isDesktop = MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;

    Widget body = isDesktop
        ? _buildDesktopLayout(repo, accounts, folders)
        : _buildMobileLayout(repo, accounts, folders);

    // Hiện lỗi tải dữ liệu thay vì im lặng.
    if (repo.loadError != null) {
      body = Column(
        children: [
          MaterialBanner(
            leading: const Icon(Icons.error_outline),
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
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('X Favorites'),
        actions: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.import_export),
              tooltip: 'Nhập / Xuất CSV',
              onPressed: _showImportExportMenu,
            ),
          if (repo.selectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa đã chọn',
              onPressed: _deleteSelectedAccounts,
            ),
        ],
      ),
      body: body,
      floatingActionButton: !isDesktop && !repo.selectionMode
          ? FloatingActionButton.extended(
              onPressed: _handleImportCsv,
              icon: const Icon(Icons.import_export),
              label: const Text('Nhập CSV'),
            )
          : null,
      bottomNavigationBar: !isDesktop ? _buildBottomNav(repo) : null,
    );

    // Trên desktop, bọc toàn bộ trang để nhận file kéo thả.
    if (_supportsDragAndDrop) {
      return DropViewer(
        onDropFile: _handleDroppedFile,
        onError: _showMessage,
        child: scaffold,
      );
    }

    return scaffold;
  }

  // =========================================================================
  // Bố cục điện thoại
  // =========================================================================

  Widget _buildMobileLayout(AccountRepository repo, List<XAccount> accounts, List<String> folders) {
    return Column(
      children: [
        // Thanh tìm kiếm
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm theo username...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(accountRepositoryProvider.notifier).setSearchQuery('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) =>
                ref.read(accountRepositoryProvider.notifier).setSearchQuery(value),
          ),
        ),

        // Hàng chip lọc cuộn ngang
        FilterChipRow(
          folders: folders,
          selectedFolder: repo.selectedFolder,
          favoritesOnly: repo.favoritesOnly,
          onFolderSelected: (folder) =>
              ref.read(accountRepositoryProvider.notifier).setFolderFilter(folder),
          onFavoritesSelected: () =>
              ref.read(accountRepositoryProvider.notifier).setFavoritesOnly(true),
        ),

        // Thanh chọn nhiều (hiện khi đang chọn)
        if (repo.selectionMode) _buildSelectionBar(repo),

        // Danh sách tài khoản
        Expanded(
          child: accounts.isEmpty
              ? const Center(child: Text('Chưa có tài khoản. Nhập CSV để bắt đầu.'))
              : ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final acc = accounts[index];
                    return AccountListItem(
                      account: acc,
                      onTap: () => _onAccountTap(acc),
                      onFavoriteToggle: () =>
                          ref.read(accountRepositoryProvider.notifier).toggleFavorite(acc.id!),
                      onDelete: () => _confirmDeleteAccount(acc),
                      onMoveToFolder: (folder) =>
                          ref.read(accountRepositoryProvider.notifier).setFolderForAccount(
                              acc.id!, folder),
                      onLongPress: () =>
                          ref.read(accountRepositoryProvider.notifier).toggleSelection(acc.id!),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // =========================================================================
  // Bố cục máy tính (Windows)
  // =========================================================================

  Widget _buildDesktopLayout(AccountRepository repo, List<XAccount> accounts, List<String> folders) {
    return Row(
      children: [
        // Cột trái: sidebar folder
        SizedBox(
          width: 260,
          child: _buildDesktopSidebar(repo, folders),
        ),
        const VerticalDivider(width: 1),
        // Cột giữa: thanh công cụ + danh sách
        Expanded(
          child: Column(
            children: [
              // Thanh công cụ (tìm kiếm, sắp xếp, nhập/xuất)
              _buildDesktopToolbar(repo),

              // Thanh chọn nhiều
              if (repo.selectionMode) _buildSelectionBar(repo),

              // Danh sách
              Expanded(
                child: accounts.isEmpty
                    ? const Center(child: Text('Chưa có tài khoản. Dùng nút Nhập CSV hoặc kéo thả file CSV vào cửa sổ.'))
                    : ListView.builder(
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final acc = accounts[index];
                          return AccountListItem(
                            account: acc,
                            onTap: () => _onAccountTap(acc),
                            onFavoriteToggle: () =>
                                ref.read(accountRepositoryProvider.notifier).toggleFavorite(acc.id!),
                            onDelete: () => _confirmDeleteAccount(acc),
                            onMoveToFolder: (folder) =>
                                ref.read(accountRepositoryProvider.notifier).setFolderForAccount(
                                    acc.id!, folder),
                            onLongPress: () =>
                                ref.read(accountRepositoryProvider.notifier).toggleSelection(acc.id!),
                            desktopMode: true,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar(AccountRepository repo, List<String> folders) {
    final notifier = ref.read(accountRepositoryProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.folder, size: 24),
              SizedBox(width: 8),
              Text('Folders', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              _sidebarTile(
                icon: Icons.people,
                label: AppConstants.filterAll,
                count: repo.countAll,
                selected: !repo.favoritesOnly && repo.selectedFolder == null,
                onTap: notifier.selectAll,
              ),
              _sidebarTile(
                icon: Icons.star,
                label: AppConstants.filterFavorites,
                count: repo.favoriteCount,
                selected: repo.favoritesOnly,
                onTap: () => notifier.setFavoritesOnly(true),
              ),
              _sidebarTile(
                icon: !repo.favoritesOnly &&
                        repo.selectedFolder == AppConstants.folderUncategorized
                    ? Icons.folder
                    : Icons.folder_outlined,
                label: AppConstants.folderUncategorized,
                count: repo.uncategorizedCount,
                selected: !repo.favoritesOnly &&
                    repo.selectedFolder == AppConstants.folderUncategorized,
                onTap: () =>
                    notifier.setFolderFilter(AppConstants.folderUncategorized),
              ),
              for (final folder in folders)
                _sidebarTile(
                  icon: !repo.favoritesOnly && repo.selectedFolder == folder
                      ? Icons.folder
                      : Icons.folder_outlined,
                  label: folder,
                  count: repo.countFolder(folder),
                  selected: !repo.favoritesOnly && repo.selectedFolder == folder,
                  onTap: () => notifier.setFolderFilter(folder),
                  trailing: PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
                      const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                    onSelected: (value) {
                      if (value == 'rename') {
                        _renameFolder(folder);
                      } else if (value == 'delete') {
                        _deleteFolder(folder);
                      }
                    },
                  ),
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Tạo folder mới'),
                onTap: _createFolder,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sidebarTile({
    required IconData icon,
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text('$label ($count)'),
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      onTap: onTap,
      trailing: trailing,
    );
  }

  Widget _buildDesktopToolbar(AccountRepository repo) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(accountRepositoryProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) =>
                  ref.read(accountRepositoryProvider.notifier).setSearchQuery(value),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: repo.sortMode,
            items: const [
              DropdownMenuItem<String>(value: AppConstants.sortAz, child: Text('Sắp xếp: A-Z')),
              DropdownMenuItem<String>(value: AppConstants.sortNewest, child: Text('Sắp xếp: Mới thêm')),
              DropdownMenuItem<String>(value: AppConstants.sortFavoritesFirst, child: Text('Sắp xếp: Yêu thích trước')),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(accountRepositoryProvider.notifier).setSortMode(value);
              }
            },
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _handleImportCsv,
            icon: const Icon(Icons.import_export),
            label: const Text('Nhập CSV'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _handleExportCsv,
            icon: const Icon(Icons.save_as),
            label: const Text('Xuất CSV'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Thanh chọn nhiều (dùng chung mobile & desktop)
  // =========================================================================

  Widget _buildSelectionBar(AccountRepository repo) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('${repo.selectedIds.length} đã chọn'),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Di chuyển sang folder',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: AppConstants.folderUncategorized,
                child: Text(AppConstants.folderUncategorized),
              ),
              for (final folder in ref.watch(foldersProvider))
                PopupMenuItem(
                  value: folder,
                  child: Text(folder),
                ),
            ],
            onSelected: (folder) {
              final isUncategorized = folder == AppConstants.folderUncategorized;
              _moveSelectedToFolder(isUncategorized ? null : folder);
            },
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.clear),
            label: const Text('Bỏ chọn'),
            onPressed: () => ref.read(accountRepositoryProvider.notifier).exitSelectionMode(),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Xóa'),
            onPressed: _deleteSelectedAccounts,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Bottom nav (chỉ điện thoại)
  // =========================================================================

  Widget _buildBottomNav(AccountRepository repo) {
    final notifier = ref.read(accountRepositoryProvider.notifier);

    return BottomNavigationBar(
      currentIndex: repo.favoritesOnly ? 1 : 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.people), label: AppConstants.filterAll),
        BottomNavigationBarItem(icon: Icon(Icons.star), label: AppConstants.filterFavorites),
      ],
      onTap: (index) {
        if (index == 1) {
          notifier.setFavoritesOnly(true);
        } else {
          notifier.selectAll();
        }
      },
    );
  }

  // =========================================================================
  // Xử lý sự kiện tài khoản
  // =========================================================================

  void _onAccountTap(XAccount acc) {
    // Nếu đang chọn nhiều, bấm vào dòng thì chọn/bỏ chọn thay vì mở link.
    if (ref.read(accountRepositoryProvider).selectionMode) {
      ref.read(accountRepositoryProvider.notifier).toggleSelection(acc.id!);
      return;
    }

    // Đánh dấu đã mở rồi mở link bằng trình duyệt ngoài.
    ref.read(accountRepositoryProvider.notifier).markOpened(acc.id!);
    _openAccountUrl(acc.link);
  }

  void _showImportExportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.import_export),
            title: const Text('Nhập CSV'),
            onTap: () {
              Navigator.pop(context);
              _handleImportCsv();
            },
          ),
          ListTile(
            leading: const Icon(Icons.save_as),
            title: const Text('Xuất CSV'),
            onTap: () {
              Navigator.pop(context);
              _handleExportCsv();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(XAccount acc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Text('Xóa "${acc.displayName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(accountRepositoryProvider.notifier).deleteAccount(acc.id!);
    }
  }
}

/// Dialog hiện tiến trình khi đang đọc file / ghi CSDL.
class _ImportProgressDialog extends StatelessWidget {
  const _ImportProgressDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      title: Text('Đang nhập CSV'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang đọc file và cập nhật dữ liệu...'),
        ],
      ),
    );
  }
}
