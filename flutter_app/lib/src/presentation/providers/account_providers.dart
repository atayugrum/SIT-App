// File: lib/src/presentation/providers/account_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account_model.dart';
import '../../data/services/account_flutter_service.dart';

final accountServiceProvider = Provider<AccountFlutterService>((ref) {
  return AccountFlutterService(ref);
});

final accountsProvider = StateNotifierProvider<AccountsNotifier, AsyncValue<List<AccountModel>>>((ref) {
  return AccountsNotifier(ref);
});

class AccountsNotifier extends StateNotifier<AsyncValue<List<AccountModel>>> {
  final Ref _ref;
  late final AccountFlutterService _service;

  AccountsNotifier(this._ref) : super(const AsyncLoading()) {
    _service = _ref.read(accountServiceProvider);
    fetchAccounts();
  }

  Future<void> fetchAccounts() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.listAccounts());
  }

  Future<void> createAccount(Map<String, dynamic> accountData) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      await _service.createAccount(accountData);
      await fetchAccounts(); // Listeyi yenile
    } catch (e) {
      state = previousState; // Hata durumunda eski duruma dön
      rethrow;
    }
  }
}

