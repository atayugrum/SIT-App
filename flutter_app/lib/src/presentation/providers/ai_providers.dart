// File: lib/src/presentation/providers/ai_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/parsed_transaction_model.dart';
import '../../data/services/ai_flutter_service.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../data/models/transaction_model.dart';
import '../../presentation/providers/account_providers.dart';
import '../../presentation/providers/transaction_providers.dart';
import '../../data/models/budget_suggestion_model.dart';

final aiFlutterServiceProvider = Provider<AIFlutterService>((ref) {
  return AIFlutterService();
});

final budgetSuggestionProvider = FutureProvider.autoDispose
    .family<BudgetSuggestion, String>((ref, category) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) {
    throw Exception('Bütçe önerisi almak için kullanıcı oturumu gereklidir.');
  }
  final aiService = ref.watch(aiFlutterServiceProvider);
  return aiService.getBudgetRecommendation(userId, category);
});

class BatchTransactionState {
  final bool isLoading;
  final String? error;
  final List<ParsedTransactionModel> parsedItems;

  BatchTransactionState({
    this.isLoading = false,
    this.error,
    this.parsedItems = const [],
  });

  BatchTransactionState copyWith({
    bool? isLoading,
    String? error,
    List<ParsedTransactionModel>? parsedItems,
    bool clearError = false,
  }) {
    return BatchTransactionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      parsedItems: parsedItems ?? this.parsedItems,
    );
  }
}

class BatchTransactionNotifier extends StateNotifier<BatchTransactionState> {
  final AIFlutterService _aiService;
  final Ref _ref;

  BatchTransactionNotifier(this._aiService, this._ref) : super(BatchTransactionState());

  Future<void> parseText(String text) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _aiService.parseTransactionText(text);
      state = state.copyWith(isLoading: false, parsedItems: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateItem(int index, {String? account, bool? isNeed, String? emotion}) {
    if (index < 0 || index >= state.parsedItems.length) return;
    
    final updatedItems = List<ParsedTransactionModel>.from(state.parsedItems);
    updatedItems[index] = updatedItems[index].copyWith(
      account: account,
      isNeed: isNeed,
      emotion: emotion,
    );
    state = state.copyWith(parsedItems: updatedItems);
  }

  Future<void> saveAllTransactions() async {
    final userId = _ref.read(userIdProvider);
    if (userId == null) throw Exception("Kullanıcı bulunamadı.");

    final transactionService = _ref.read(transactionServiceProvider);
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      for (final item in state.parsedItems) {
        final transactionToSave = TransactionModel(
          userId: userId,
          type: item.type,
          category: item.category,
          subCategory: null, // AI şimdilik subcategory tahminlemiyor
          amount: item.amount,
          date: item.date,
          account: item.account!, // Bu aşamada null olmamalı
          description: item.description,
          isRecurring: false,
          isNeed: item.isNeed,
          emotion: item.emotion,
          // incomeAllocationPct AI tarafından belirlenmiyor, varsayılan 0
          incomeAllocationPct: item.type == 'income' ? 0 : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await transactionService.createTransaction(transactionToSave);
      }
      
      // Başarıyla kaydedildikten sonra state'i temizle
      state = state.copyWith(isLoading: false, parsedItems: []);
      
      // Ana listeleri yenile
      _ref.invalidate(transactionsProvider);
      _ref.invalidate(accountsProvider);

    } catch (e) {
      state = state.copyWith(isLoading: false, error: "İşlemler kaydedilemedi: $e");
      rethrow;
    }
  }

  void clear() {
    state = BatchTransactionState();
  }
}


final batchTransactionProvider = StateNotifierProvider.autoDispose<BatchTransactionNotifier, BatchTransactionState>((ref) {
  final aiService = ref.watch(aiFlutterServiceProvider);
  return BatchTransactionNotifier(aiService, ref);
});