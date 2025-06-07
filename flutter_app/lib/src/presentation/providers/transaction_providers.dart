// File: lib/src/presentation/providers/transaction_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction_model.dart';
import '../../data/services/transaction_flutter_service.dart';

// Hızlı tarih aralıklarını yönetmek için bir enum tanımlıyoruz.
enum QuickDateRange { thisMonth, lastMonth, last3Months, last6Months, allTime }

class TransactionsState {
  final bool isLoading;
  final String? error;
  final List<TransactionModel> transactions;
  final DateTime startDate;
  final DateTime endDate;
  final String? filterType;
  
  // YENİ: Toplam gelir ve gider için alanlar
  final double totalIncome;
  final double totalExpense;

  TransactionsState({
    this.isLoading = false,
    this.error,
    this.transactions = const [],
    required this.startDate,
    required this.endDate,
    this.filterType,
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
    double? totalIncome,
    double? totalExpense,
    bool clearError = false,
  }) {
    return TransactionsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      transactions: transactions ?? this.transactions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      filterType: filterType ?? this.filterType,
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
      );
      
      // YENİ: Toplamları hesaplama
      double income = 0.0;
      double expense = 0.0;
      for (var tx in transactions) {
        if (tx.type == 'income') {
          income += tx.amount;
        } else if (tx.type == 'expense') {
          expense += tx.amount;
        }
      }
      
      state = state.copyWith(
        transactions: transactions, 
        isLoading: false,
        totalIncome: income,
        totalExpense: expense,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
  
  void setQuickDateRange(QuickDateRange range) {
    final now = DateTime.now();
    DateTime newStartDate;
    DateTime newEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (range) {
      case QuickDateRange.thisMonth:
        newStartDate = DateTime(now.year, now.month, 1);
        break;
      case QuickDateRange.lastMonth:
        final lastMonthEnd = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
        newStartDate = DateTime(lastMonthEnd.year, lastMonthEnd.month, 1);
        newEndDate = lastMonthEnd;
        break;
      case QuickDateRange.last3Months:
        newStartDate = DateTime(now.year, now.month - 2, 1);
        break;
      case QuickDateRange.last6Months:
         newStartDate = DateTime(now.year, now.month - 5, 1);
        break;
      case QuickDateRange.allTime:
         newStartDate = DateTime(2000); // Çok eski bir tarih
         break;
    }
    state = state.copyWith(startDate: newStartDate, endDate: newEndDate);
    fetchTransactions();
  }

  Future<void> addTransaction(TransactionModel transaction) async { try { await _service.createTransaction(transaction); fetchTransactions(); } catch (e) { rethrow; } }
  Future<void> updateTransactionInList(String id, TransactionModel transaction) async { try { await _service.updateTransaction(id, transaction); fetchTransactions(); } catch (e) { rethrow; } }
  Future<void> deleteTransactionFromList(String id) async { try { await _service.deleteTransaction(id); fetchTransactions(); } catch (e) { rethrow; } }
  void setDateRange(DateTime newStart, DateTime newEnd) { state = state.copyWith(startDate: newStart, endDate: newEnd); fetchTransactions(); }
  void setFilterType(String? type) { state = state.copyWith(filterType: type); fetchTransactions(); }
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier(ref.watch(transactionServiceProvider));
});

final accountTransactionsProvider = FutureProvider.autoDispose.family<List<TransactionModel>, String>((ref, accountName) async {
  final service = ref.watch(transactionServiceProvider);
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month - 3, 1);
  final endDate = now;
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  return await service.listTransactions(
    startDate: formatter.format(startDate),
    endDate: formatter.format(endDate),
    account: accountName,
  );
});