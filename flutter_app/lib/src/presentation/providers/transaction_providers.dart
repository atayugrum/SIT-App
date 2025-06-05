// File: flutter_app/lib/src/presentation/providers/transaction_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/transaction_flutter_service.dart';
import 'account_providers.dart'; // For refreshing accounts provider

final transactionFlutterServiceProvider = Provider<TransactionFlutterService>((ref) {
  return TransactionFlutterService(ref);
});

class TransactionsState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;
  final DateTime startDate;
  final DateTime endDate;
  final String? filterType; 

  TransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    required this.startDate,
    required this.endDate,
    this.filterType,
  });

  TransactionsState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    String? filterType,
    bool clearError = false,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      filterType: filterType ?? this.filterType,
    );
  }
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionFlutterService _service;
  final Ref _ref; 

  TransactionsNotifier(this._service, this._ref) : super(TransactionsState(
    startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    endDate: DateTime.now(),
  ));

  Future<void> fetchTransactions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final transactions = await _service.listTransactions(
        startDate: formatter.format(state.startDate),
        endDate: formatter.format(state.endDate),
        type: state.filterType,
      );
      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e,s) {
      print("TRANSACTIONS_NOTIFIER: Error fetching transactions: $e\n$s");
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
  
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _service.createTransaction(transaction);
      await fetchTransactions(); 
      // Refresh accounts on the UI side after transaction is added successfully
      // The screen that calls addTransaction should ideally trigger this if needed.
      // _ref.refresh(accountsProvider); // Moved to TransactionFlowScreen's save method
    } catch (e) {
      print("TRANSACTIONS_NOTIFIER: Error adding transaction: $e");
      rethrow; 
    }
  }

  Future<void> updateTransactionInList(String transactionId, TransactionModel transaction) async {
    try {
      await _service.updateTransaction(transactionId, transaction);
      await fetchTransactions(); 
      // ignore: unused_result
      _ref.refresh(accountsProvider); 
      print("TRANSACTIONS_NOTIFIER: Transaction updated, accounts refreshed.");
    } catch (e) {
      print("TRANSACTIONS_NOTIFIER: Error updating transaction: $e");
      rethrow;
    }
  }

  Future<void> deleteTransactionFromList(String transactionId) async {
    try {
      await _service.deleteTransaction(transactionId);
      await fetchTransactions(); 
      // ignore: unused_result
      _ref.refresh(accountsProvider); 
      print("TRANSACTIONS_NOTIFIER: Transaction deleted, accounts refreshed.");
    } catch (e) {
       print("TRANSACTIONS_NOTIFIER: Error deleting transaction: $e");
       rethrow;
    }
  }

  void setDateRange(DateTime newStart, DateTime newEnd) {
    state = state.copyWith(startDate: newStart, endDate: newEnd, transactions: [], isLoading: true);
    fetchTransactions();
  }

  void setFilterType(String? type) {
    state = state.copyWith(filterType: type, transactions: [], isLoading: true);
    fetchTransactions();
  }
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier(ref.watch(transactionFlutterServiceProvider), ref);
});

// NEW: Provider for fetching transactions for a specific account
// The 'String' in family is the accountName
final accountTransactionsProvider = FutureProvider.family<List<TransactionModel>, String>((ref, accountName) async {
  final service = ref.watch(transactionFlutterServiceProvider);
  // For AccountDetailScreen, let's fetch transactions for a wider default range, e.g., last year
  final endDate = DateTime.now();
  final startDate = DateTime(endDate.year - 1, endDate.month, endDate.day); // Last 1 year
  final formatter = DateFormat('yyyy-MM-dd');
  
  print("ACCOUNT_TRANSACTIONS_PROVIDER: Fetching for account '$accountName'");
  return service.listTransactions(
    accountName: accountName,
    startDate: formatter.format(startDate), // You can make these dates configurable later
    endDate: formatter.format(endDate),
  );
});