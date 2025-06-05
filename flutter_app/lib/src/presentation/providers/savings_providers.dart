// File: flutter_app/lib/src/presentation/providers/savings_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Used by SavingsAllocationsNotifier
import '../../data/models/savings_allocation_model.dart';
import '../../data/models/savings_balance_model.dart';
import '../../data/services/savings_flutter_service.dart'; // Corrected import path
import 'account_providers.dart'; // For refreshing accountsProvider

// Provider for SavingsFlutterService
final savingsFlutterServiceProvider = Provider<SavingsFlutterService>((ref) {
  return SavingsFlutterService(ref);
});

// Provider for fetching the total savings balance
final savingsBalanceProvider = FutureProvider<SavingsBalanceModel>((ref) async {
  print("SAVINGS_BALANCE_PROVIDER: Fetching total savings balance...");
  final service = ref.watch(savingsFlutterServiceProvider);
  final balance = await service.getSavingsBalance();
  print("SAVINGS_BALANCE_PROVIDER: Balance fetched: ${balance.balance}");
  return balance;
});

// State class for SavingsAllocations
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
    startDate: DateTime.now().subtract(const Duration(days: 29)), // Default to last 30 days
    endDate: DateTime.now(),
  )) {
    fetchAllocations(); 
  }

  Future<void> fetchAllocations() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      print("SAVINGS_ALLOC_NOTIFIER: Fetching allocations for ${formatter.format(state.startDate)} to ${formatter.format(state.endDate)}, source: ${state.filterSource}");
      final allocations = await _service.listSavingsAllocations(
        startDate: formatter.format(state.startDate),
        endDate: formatter.format(state.endDate),
        source: state.filterSource,
      );
      state = state.copyWith(allocations: allocations, isLoading: false);
      print("SAVINGS_ALLOC_NOTIFIER: Allocations fetched successfully, count: ${allocations.length}");
    } catch (e, s) {
      print("SAVINGS_ALLOC_NOTIFIER: Error fetching allocations: $e\n$s");
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addManualSaving({required double amount, required DateTime date}) async {
    // For more immediate UI feedback, you could set loading state here
    // state = state.copyWith(isLoading: true);
    try {
      await _service.addManualSaving(amount: amount, date: date);
      await fetchAllocations(); // Refresh the list of allocations
      // ignore: unused_result
      _ref.refresh(savingsBalanceProvider); // Refresh the total balance
      // ignore: unused_result
      _ref.refresh(accountsProvider); 
    } catch (e) {
      print("SAVINGS_ALLOC_NOTIFIER: Error adding manual saving: $e");
      // state = state.copyWith(error: e.toString(), isLoading: false); // Set error if not rethrowing
      rethrow; 
    }
    // finally {
    //   if (mounted) state = state.copyWith(isLoading: false); // Ensure loading is off
    // }
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
