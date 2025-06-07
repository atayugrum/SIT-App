// File: lib/src/presentation/providers/savings_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/savings_allocation_model.dart';
import '../../data/models/savings_balance_model.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/services/savings_flutter_service.dart';
import 'account_providers.dart';

// Servis provider'ı
final savingsFlutterServiceProvider = Provider<SavingsFlutterService>((ref) {
  return SavingsFlutterService(ref);
});

// Toplam kumbara bakiyesini getiren provider
final savingsBalanceProvider = FutureProvider.autoDispose<SavingsBalanceModel>((ref) async {
  final service = ref.watch(savingsFlutterServiceProvider);
  return service.getSavingsBalance();
});

// Kumbara hareketlerini (allocations) yöneten notifier ve state'i
class SavingsAllocationsState {
  final List<SavingsAllocationModel> allocations;
  final bool isLoading;
  final String? error;
  final DateTime startDate;
  final DateTime endDate;
  final String? filterSource; 

  SavingsAllocationsState({
    this.allocations = const [],
    this.isLoading = false,
    this.error,
    required this.startDate,
    required this.endDate,
    this.filterSource,
  });

  SavingsAllocationsState copyWith({
    List<SavingsAllocationModel>? allocations,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    String? filterSource,
    bool clearError = false,
  }) {
    return SavingsAllocationsState(
      allocations: allocations ?? this.allocations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      filterSource: filterSource ?? this.filterSource,
    );
  }
}

class SavingsAllocationsNotifier extends StateNotifier<SavingsAllocationsState> {
  final SavingsFlutterService _service;
  final Ref _ref;

  SavingsAllocationsNotifier(this._service, this._ref) : super(SavingsAllocationsState(
    startDate: DateTime.now().subtract(const Duration(days: 29)),
    endDate: DateTime.now(),
  )) {
    fetchAllocations(); 
  }

  Future<void> fetchAllocations() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final allocations = await _service.listSavingsAllocations(
        startDate: formatter.format(state.startDate),
        endDate: formatter.format(state.endDate),
        source: state.filterSource,
      );
      state = state.copyWith(allocations: allocations, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addManualSaving({required double amount, required DateTime date}) async {
    try {
      await _service.addManualSaving(amount: amount, date: date);
      await fetchAllocations(); 
      final _ = _ref.refresh(savingsBalanceProvider);
      final __ = _ref.refresh(accountsProvider); 
    } catch (e) {
      rethrow; 
    }
  }
  
  void setDateRange(DateTime newStart, DateTime newEnd) {
    state = state.copyWith(startDate: newStart, endDate: newEnd, allocations: [], isLoading: true);
    fetchAllocations();
  }

  void setFilterSource(String? source) {
    state = state.copyWith(filterSource: source, allocations: [], isLoading: true);
    fetchAllocations();
  }
}

final savingsAllocationsProvider = StateNotifierProvider<SavingsAllocationsNotifier, SavingsAllocationsState>((ref) {
  return SavingsAllocationsNotifier(ref.watch(savingsFlutterServiceProvider), ref);
});

// === TASARRUF HEDEFLERİ İÇİN PROVIDER'LAR ===

final savingsGoalsProvider = FutureProvider.autoDispose<List<SavingsGoalModel>>((ref) async {
  final service = ref.watch(savingsFlutterServiceProvider);
  return service.listGoals();
});

class SavingsGoalNotifier extends StateNotifier<AsyncValue<void>> {
  final SavingsFlutterService _service;
  final Ref _ref;

  SavingsGoalNotifier(this._service, this._ref) : super(const AsyncData(null));

  Future<void> createGoal({required String title, required double targetAmount, required DateTime targetDate}) async {
    try {
      await _service.createGoal(title: title, targetAmount: targetAmount, targetDate: targetDate);
      // DÜZELTME: Uyarıyı gidermek için sonucu değişkene atıyoruz.
      final _ = _ref.refresh(savingsGoalsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _service.deleteGoal(goalId);
      // DÜZELTME: Uyarıları gidermek için sonuçları değişkenlere atıyoruz.
      final _ = _ref.refresh(savingsGoalsProvider);
      final __ = _ref.refresh(savingsBalanceProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> allocateToGoal({required String goalId, required double amount}) async {
    try {
      await _service.allocateToGoal(goalId: goalId, amount: amount);
      // DÜZELTME: Uyarıları gidermek için sonuçları değişkenlere atıyoruz.
      final _ = _ref.refresh(savingsGoalsProvider);
      final __ = _ref.refresh(savingsBalanceProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final savingsGoalNotifierProvider = StateNotifierProvider.autoDispose<SavingsGoalNotifier, AsyncValue<void>>((ref) {
  return SavingsGoalNotifier(ref.watch(savingsFlutterServiceProvider), ref);
});