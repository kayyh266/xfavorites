import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xfavorites/models/x_account.dart';
import 'package:xfavorites/repositories/account_repository.dart';

/// Provider cung cấp AccountRepository (single instance) cho toàn ứng dụng.
/// Sử dụng ChangeNotifierProvider vì AccountRepository kế thừa ChangeNotifier.
final accountRepositoryProvider =
    ChangeNotifierProvider<AccountRepository>((ref) {
  return AccountRepository();
});

/// Provider danh sách tài khoản đã lọc / tìm kiếm / sắp xếp.
final filteredAccountsProvider = Provider<List<XAccount>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.filteredAccounts;
});

/// Provider danh sách folder.
final foldersProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.folders;
});

/// Provider các tài khoản mở gần đây (tối đa 8, mới nhất trước).
final recentAccountsProvider = Provider<List<XAccount>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.recentAccounts;
});

/// Provider tài khoản vừa mở gần nhất.
final latestOpenedProvider = Provider<XAccount?>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.latestOpened;
});

/// Provider số tài khoản theo từng folder.
final folderCountsProvider = Provider<Map<String, int>>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.folderCounts;
});
