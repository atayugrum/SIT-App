// File: lib/src/presentation/providers/budget_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_model.dart';
import '../../data/services/budget_flutter_service.dart'; // Bu import zaten doğru olmalı

// Provider for the currently selected year and month for budget view
final budgetPeriodProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1); // Ayın ilk gününü saklayalım
});

// Provider to fetch budgets for the selected period
final budgetsProvider = FutureProvider<List<BudgetModel>>((ref) async {
  final budgetService = ref.watch(budgetServiceProvider);
  final period = ref.watch(budgetPeriodProvider);
  // BudgetFlutterService'in constructor'ı artık userId'yi alıyor ve kendi içinde saklıyor.
  // Bu yüzden burada budgetService._userId şeklinde erişmeye gerek yok.
  return budgetService.listBudgets(period.year, period.month);
});

// Notifier for managing budget operations (create, update, delete)
class BudgetNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  BudgetNotifier(this._ref) : super(const AsyncData(null));

  Future<void> createOrUpdateBudget({
    String? budgetId,
    required String category,
    required double limitAmount,
    required int year,
    required int month,
    String period = 'monthly', // Default to monthly
    bool isAuto = false, // Default to manual
  }) async {
    state = const AsyncLoading();
    try {
      final budgetService = _ref.read(budgetServiceProvider);
      await budgetService.createOrUpdateBudget(
        budgetId: budgetId,
        category: category,
        limitAmount: limitAmount,
        year: year,
        month: month,
        period: period,
        isAuto: isAuto,
      );
      _ref.invalidate(budgetsProvider); // Bütçe listesini yenile
      state = const AsyncData(null);
      print("BudgetNotifier: Budget created/updated, list invalidated.");
    } catch (e, stack) {
      print("BudgetNotifier: Error create/update budget: $e \n$stack");
      state = AsyncError(e, stack);
      rethrow; // Hatayı UI'ın yakalaması için tekrar fırlat
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    state = const AsyncLoading();
    try {
      final budgetService = _ref.read(budgetServiceProvider);
      await budgetService.deleteBudget(budgetId);
      _ref.invalidate(budgetsProvider); // Bütçe listesini yenile
      state = const AsyncData(null);
      print("BudgetNotifier: Budget deleted, list invalidated.");
    } catch (e, stack) {
      print("BudgetNotifier: Error deleting budget: $e \n$stack");
      state = AsyncError(e, stack);
      rethrow; // Hatayı UI'ın yakalaması için tekrar fırlat
    }
  }
}

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<void>>((ref) {
  return BudgetNotifier(ref);
});
