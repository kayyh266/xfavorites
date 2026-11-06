import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/x_account.dart';
import '../../models/csv_import_result.dart';
import '../../repositories/account_repository.dart';
import '../../providers/repository_provider.dart';
import '../../core/constants.dart';
import '../widgets/account_avatar.dart';
import '../widgets/account_list_item.dart';
import '../widgets/filter_chip_row.dart';
import '../dialogs/folder_dialog.dart';
import '../dialogs/import_result_dialog.dart';

/// Trang chính của ứng dụng. Hỗ trợ cả điện thoại (một cột) và máy tính (2-3 cột).
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Lắng nghe sự kiện kéo thả file (chỉ có ý nghĩa trên desktop).
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Được xử lý bởi DropViewer bên ngoài build (xem dưới).
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Hành động
  // -------------------------------------------------------------------------

  Future<void> _handleImportCsv() async {
    final repo = ref.read(accountRepositoryProvider.notifier);
    final result = await repo.importCsvFromPicker();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _handleImportFromBytes(List<Uint8List> bytesList) async {
    final repo = ref.read(accountRepositoryProvider.notifier);
    int totalAdded = 0, totalUpdated = 0, totalSkipped = 0;
    for (final bytes in bytesList) {
      final result = await repo.importCsvFromBytes(bytes);
      totalAdded += result.added;
      totalUpdated += result.updated;
      totalSkipped += result.skipped;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thêm $totalAdded mới, cập nhật $totalUpdated, bỏ qua $totalSkipped trùng',
          ),
        ),
      );
    }
  }

  Future<void> _handleExportCsv() async {
    final repo = ref.read(accountRepositoryProvider.notifier);
    try {
      final path = await repo.exportCsvToFile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xuất CSV: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xuất CSV thất bại: $e')),
        );
      }
    }
  }

  Future<void> _openAccountUrl(String link) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _createFolder() async {
    final repo = ref.read(accountRepositoryProvider.notifier);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const FolderDialog(title: 'Tạo folder mới'),
    );
    if (name != null && name.trim().isNotEmpty) {
      final success = await repo.addFolder(name.trim());
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder đã tồn tại')),
        );
      }
    }
  }

  void _renameFolder(String oldName) async {
    final repo = ref.read(accountRepositoryProvider.notifier);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => FolderDialog(
        title: 'Đổi tên folder',
        initialValue: oldName,
      ),
    );
    if (newName != null && newName.trim().isNotEmpty && newName.trim() != oldName) {
      await repo.renameFolder(oldName, newName.trim());
    }
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

    return Scaffold(
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
      body: DropViewer(
        onDrop: _handleImportFromBytes,
        child: isDesktop ? _buildDesktopLayout(repo, accounts, folders) : _buildMobileLayout(repo, accounts, folders),
      ),
      floatingActionButton: !isDesktop && !repo.selectionMode
          ? FloatingActionButton.extended(
              onPressed: _handleImportCsv,
              icon: const Icon(Icons.import_export),
              label: const Text('Nhập CSV'),
            )
          : null,
      bottomNavigationBar: !isDesktop ? _buildBottomNav(repo) : null,
    );
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
          onFolderSelected: (folder) =>
              ref.read(accountRepositoryProvider.notifier).setFolderFilter(folder),
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
                    ? const Center(child: Text('Chưa có tài khoản. Kéo thả file CSV hoặc dùng nút Nhập CSV.'))
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.folder, size: 24),
              const SizedBox(width: 8),
              const Text('Folders', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              _sidebarFolderItem(repo, null, 'Tất cả', repo.countAll()),
              _sidebarFolderItem(
                  repo, AppConstants.folderUncategorized, AppConstants.folderUncategorized,
                  repo.uncategorizedCount),
              for (final folder in folders)
                _sidebarFolderItem(repo, folder, folder, repo.countFolder(folder)),
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

  Widget _sidebarFolderItem(AccountRepository repo, String? folder, String label, int count) {
    final isSelected = repo.selectedFolder == folder;
    return ListTile(
      leading: Icon(isSelected ? Icons.folder : Icons.folder_outlined),
      title: Text('$label ($count)'),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      onTap: () {
        ref.read(accountRepositoryProvider.notifier).setFolderFilter(folder);
      },
      trailing: folder != null && folder != AppConstants.folderUncategorized
          ? PopupMenuButton<String>(
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
            )
          : null,
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
            items: [
              DropdownMenuItem(value: AppConstants.sortAz, child: const Text('Sắp xếp: A-Z')),
              DropdownMenuItem(value: AppConstants.sortNewest, child: const Text('Sắp xếp: Mới thêm')),
              DropdownMenuItem(value: AppConstants.sortFavoritesFirst, child: const Text('Sắp xếp: Yêu thích trước')),
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('${repo.selectedIds.length} đã chọn'),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Di chuyển sang folder',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'uncategorized',
                child: Text('Chưa phân loại'),
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
    return BottomNavigationBar(
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Tất cả'),
        BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Yêu thích'),
      ],
      onTap: (index) {
        if (index == 1) {
          // Chuyển sang filter yêu thích (tạm thời dùng selectedFolder=null nhưng sort=favoritesFirst)
          ref.read(accountRepositoryProvider.notifier).setSortMode(AppConstants.sortFavoritesFirst);
          ref.read(accountRepositoryProvider.notifier).setFolderFilter(null);
        } else {
          ref.read(accountRepositoryProvider.notifier).setSortMode(AppConstants.sortAz);
          ref.read(accountRepositoryProvider.notifier).setFolderFilter(null);
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
