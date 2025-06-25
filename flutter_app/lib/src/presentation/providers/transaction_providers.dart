// File: lib/src/presentation/providers/transaction_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/transaction_flutter_service.dart';
import 'auth_providers.dart';
import 'account_providers.dart';
import 'analytics_v2_providers.dart';

enum QuickDateRange { thisMonth, lastMonth, last3Months, last6Months, allTime }

class TransactionsState {
  final bool isLoading;
  final String? error;
  final List<TransactionModel> transactions;
  final DateTime startDate;
  final DateTime endDate;
  final String? filterType;
  final String? filterAccount;
  final double totalIncome;
  final double totalExpense;

  TransactionsState({
    this.isLoading = false,
    this.error,
    this.transactions = const [],
    required this.startDate,
    required this.endDate,
    this.filterType,
    this.filterAccount,
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
  });

  TransactionsState copyWith({
    bool? isLoading,
    String? error,
    List<TransactionModel>? transactions,
    DateTime? startDate,
    DateTime? endDate,
    String? filterType,
    String? filterAccount,
    double? totalIncome,
    double? totalExpense,
    bool clearError = false,
    bool clearAccountFilter = false,
  }) {
    return TransactionsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      transactions: transactions ?? this.transactions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      filterType: filterType ?? this.filterType,
      filterAccount: clearAccountFilter ? null : filterAccount ?? this.filterAccount,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
    );
  }
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionFlutterService _service;
  
  TransactionsNotifier(this._service) : super(TransactionsState(
    startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    endDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59),
  )) {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final transactions = await _service.listTransactions(
        startDate: formatter.format(state.startDate),
        endDate: formatter.format(state.endDate),
        type: state.filterType,
        account: state.filterAccount,
      );
      double income = 0.0;
      double expense = 0.0;
      for (var tx in transactions) {
        if (tx.type == 'income') {
          income += tx.amount;
        } else if (tx.type == 'expense') {
          expense += tx.amount;
        }
      }
      state = state.copyWith(transactions: transactions, isLoading: false, totalIncome: income, totalExpense: expense);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
  
  // DOLDURULMUŞ FONKSİYON
  void setQuickDateRange(QuickDateRange range) {
    final now = DateTime.now();
    DateTime newStart;
    DateTime newEnd;

    switch (range) {
      case QuickDateRange.thisMonth:
        newStart = DateTime(now.year, now.month, 1);
        newEnd = now;
        break;
      case QuickDateRange.lastMonth:
        final firstDayOfThisMonth = DateTime(now.year, now.month, 1);
        newEnd = firstDayOfThisMonth.subtract(const Duration(days: 1));
        newStart = DateTime(newEnd.year, newEnd.month, 1);
        break;
      case QuickDateRange.last3Months:
        newStart = DateTime(now.year, now.month - 2, 1);
        newEnd = now;
        break;
      case QuickDateRange.last6Months:
        newStart = DateTime(now.year, now.month - 5, 1);
        newEnd = now;
        break;
      case QuickDateRange.allTime:
        newStart = DateTime(2000);
        newEnd = now;
        break;
    }
    setDateRange(newStart, newEnd);
  }

  void setDateRange(DateTime newStart, DateTime newEnd) {
    state = state.copyWith(startDate: newStart, endDate: newEnd);
    fetchTransactions();
  }

  void setFilterType(String? type) {
    state = state.copyWith(filterType: type);
    fetchTransactions();
  }

  void setAccountFilter(String? accountName) {
    state = state.copyWith(filterAccount: accountName, clearAccountFilter: accountName == null);
    fetchTransactions();
  }
  
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _service.createTransaction(transaction);
      fetchTransactions();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTransactionInList(String id, TransactionModel transaction) async {
    try {
      await _service.updateTransaction(id, transaction);
      fetchTransactions();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransactionFromList(String id) async {
    try {
      await _service.deleteTransaction(id);
      fetchTransactions();
    } catch (e) {
      rethrow;
    }
  }
}

final transactionServiceProvider = Provider<TransactionFlutterService>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  return TransactionFlutterService(userId);
});

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier(ref.watch(transactionServiceProvider));
});

final accountTransactionsProvider = FutureProvider.autoDispose.family<List<TransactionModel>, String>((ref, accountName) async {
  final service = ref.watch(transactionServiceProvider);
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month - 3, 1);
  final formatter = DateFormat('yyyy-MM-dd');
  return await service.listTransactions(startDate: formatter.format(startDate), endDate: formatter.format(now), account: accountName);
});

class TransactionActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  TransactionActionNotifier(this._ref) : super(const AsyncData(null));

  Future<void> _runAction(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
      // İlgili provider'ları geçersiz kılarak yeniden yüklenmelerini sağla
      _ref.invalidate(transactionsProvider);
      _ref.invalidate(accountsProvider);
      _ref.invalidate(analyticsV2Provider); // Analizleri de güncelle
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  Future<void> createTransfer(Map<String, dynamic> transferData) async {
    final service = _ref.read(transactionServiceProvider);
    await _runAction(() => service.createTransfer(transferData));
  }
}

final transactionActionProvider = StateNotifierProvider.autoDispose<TransactionActionNotifier, AsyncValue<void>>((ref) {
  return TransactionActionNotifier(ref);
});