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
