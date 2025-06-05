// File: flutter_app/lib/src/presentation/providers/account_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account_model.dart';
import '../../data/services/account_flutter_service.dart';

// Provider for AccountFlutterService
final accountFlutterServiceProvider = Provider<AccountFlutterService>((ref) {
  return AccountFlutterService(ref); // Pass ref
});

// StateNotifier for managing the list of accounts
class AccountsListNotifier extends StateNotifier<AsyncValue<List<AccountModel>>> {
  final AccountFlutterService _service;
  // Store ref to be able to refresh other providers if needed, though not used directly for that here.
  // final Ref _ref; 

  AccountsListNotifier(this._service /*, this._ref*/) : super(const AsyncValue.loading()) {
    fetchAccounts(); // Fetch initially
  }

  Future<void> fetchAccounts() async {
    print("ACCOUNTS_PROVIDER: Fetching accounts...");
    state = const AsyncValue.loading();
    try {
      final accounts = await _service.listAccounts();
      state = AsyncValue.data(accounts);
      print("ACCOUNTS_PROVIDER: Accounts fetched successfully, count: ${accounts.length}");
    } catch (e, s) {
      print("ACCOUNTS_PROVIDER: Error fetching accounts: $e \n$s");
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addAccount(AccountModel account) async {
    // Current state before attempting to add
    // Optimistically show loading, but keep old data if available
    state = AsyncValue.loading(); 
    // If previous state had data, we can use it to avoid blank screen during add
    // state = previousState.copyWithPrevious(previousState, isloading: true); // requires AsyncValueX or similar

    try {
      await _service.createAccount(account);
      await fetchAccounts(); // Refresh the list to get the latest, including the new one
    } catch (e) {
      print("ACCOUNTS_PROVIDER: Error adding account in Notifier: $e");
      // If add failed, revert to previous state or set an error
      // For simplicity, fetchAccounts will set the error state if it also fails
      // or a more specific error can be set here.
      // If fetchAccounts() is called in finally, it will handle error state too.
      state = AsyncValue.error(e, StackTrace.current); // Set error state directly
      rethrow; 
    }
  }
}

final accountsProvider = StateNotifierProvider<AccountsListNotifier, AsyncValue<List<AccountModel>>>((ref) {
  return AccountsListNotifier(ref.watch(accountFlutterServiceProvider) /*, ref*/);
});