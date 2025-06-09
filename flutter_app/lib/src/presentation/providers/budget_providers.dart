// File: lib/src/presentation/providers/budget_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_model.dart';
import '../../data/services/budget_flutter_service.dart';
import 'auth_providers.dart';

final budgetServiceProvider = Provider<BudgetFlutterService>((ref) {
  return BudgetFlutterService(ref);
});

final budgetPeriodProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final budgetsProvider = FutureProvider.autoDispose<List<BudgetModel>>((ref) async {
  final budgetService = ref.watch(budgetServiceProvider);
  final period = ref.watch(budgetPeriodProvider);
  return budgetService.listBudgets(period.year, period.month);
});

// DÜZELTME: Notifier'ın adı standart hale getirildi.
final budgetActionNotifierProvider = StateNotifierProvider.autoDispose<BudgetActionNotifier, AsyncValue<void>>((ref) {
  return BudgetActionNotifier(ref);
});

class BudgetActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  BudgetActionNotifier(this._ref) : super(const AsyncData(null));

  // DÜZELTME: Metod artık doğrudan BudgetModel alıyor.
  Future<void> createOrUpdateBudget(BudgetModel budget) async {
    state = const AsyncLoading();
    try {
      final budgetService = _ref.read(budgetServiceProvider);
      // userId'nin modele eklendiğinden emin ol
      final userId = _ref.read(userIdProvider);
      if (userId == null) throw Exception("User not logged in.");

      await budgetService.createOrUpdateBudget(budget);
      
      _ref.invalidate(budgetsProvider);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    state = const AsyncLoading();
    try {
      final budgetService = _ref.read(budgetServiceProvider);
      await budgetService.deleteBudget(budgetId);
      _ref.invalidate(budgetsProvider);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}