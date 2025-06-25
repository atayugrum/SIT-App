// File: lib/src/presentation/providers/account_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account_model.dart';
import '../../data/services/account_flutter_service.dart';

final accountServiceProvider = Provider<AccountFlutterService>((ref) {
  return AccountFlutterService(ref);
});

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, AsyncValue<List<AccountModel>>>(
        (ref) {
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
    await _handleAction(() => _service.createAccount(accountData));
  }

  // YENİ: Hesap güncelleme aksiyonu
  Future<void> updateAccount(
      String accountId, Map<String, dynamic> accountData) async {
    await _handleAction(() => _service.updateAccount(accountId, accountData));
  }

  // YENİ: Hesap arşivleme aksiyonu
  Future<void> archiveAccount(String accountId) async {
    await _handleAction(() => _service.archiveAccount(accountId));
  }

  // YENİ: Tekrarlanan kodu azaltmak için yardımcı metot
  Future<void> _handleAction(Future<void> Function() action) async {
    // Optimistic UI: Kullanıcıya anında yükleme göstermek için
    state = const AsyncLoading<List<AccountModel>>().copyWithPrevious(state);
    try {
      await action();
    } catch (e) {
      // Hata durumunda state'i eski haline döndürmeye gerek yok,
      // çünkü fetchAccounts yeniden her şeyi düzeltecek.
      // Sadece hatayı yukarı fırlatıyoruz ki UI katmanı yakalasın.
      rethrow;
    } finally {
      // Her işlemden sonra listeyi kesin olarak yenile
      await fetchAccounts();
    }
  }
}
