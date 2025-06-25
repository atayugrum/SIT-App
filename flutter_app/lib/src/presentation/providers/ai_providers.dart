// File: lib/src/presentation/providers/ai_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/parsed_transaction_model.dart';
import '../../data/services/ai_flutter_service.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../data/models/transaction_model.dart';
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

  BatchTransactionNotifier(this._aiService, this._ref)
      : super(BatchTransactionState());

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

  void updateItem(int index,
      {String? accountId,
      bool? isNeed,
      String? emotion,
      DateTime? date,
      int? incomeAllocationPct}) {
    if (index < 0 || index >= state.parsedItems.length) return;

    final updatedItems = List<ParsedTransactionModel>.from(state.parsedItems);
    updatedItems[index] = updatedItems[index].copyWith(
      account: accountId,
      isNeed: isNeed,
      emotion: emotion,
      date: date,
      incomeAllocationPct: incomeAllocationPct,
    );
    state = state.copyWith(parsedItems: updatedItems);
  }

  void setGlobalAccount(String accountId) {
    final updatedItems = [
      for (final item in state.parsedItems) item.copyWith(account: accountId)
    ];
    state = state.copyWith(parsedItems: updatedItems);
  }

  Future<void> saveAllTransactions() async {
    final userId = _ref.read(userIdProvider);
    if (userId == null) throw Exception("Kullanıcı bulunamadı.");

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final transactionNotifier = _ref.read(transactionsProvider.notifier);

      for (final item in state.parsedItems) {
        if (item.account == null || item.account!.isEmpty) {
          throw Exception("Bir işlem için hesap seçilmemiş: ${item.description}");
        }

        final transactionToSave = TransactionModel(
          userId: userId,
          type: item.type,
          category: item.category,
          subCategory: item.subCategory,
          amount: item.amount,
          date: item.date,
          accountId: item.account!,
          description: item.description,
          isRecurring: false,
          isNeed: item.isNeed,
          emotion: item.emotion,
          incomeAllocationPct:
              item.type == 'income' ? (item.incomeAllocationPct ?? 0) : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await transactionNotifier.addTransaction(transactionToSave);
      }

      state = state.copyWith(isLoading: false, parsedItems: []);
    } catch (e) {
      state =
          state.copyWith(isLoading: false, error: "İşlemler kaydedilemedi: $e");
      rethrow;
    }
  }

  void clear() {
    state = BatchTransactionState();
  }
}

final batchTransactionProvider = StateNotifierProvider.autoDispose<
    BatchTransactionNotifier, BatchTransactionState>((ref) {
  final aiService = ref.watch(aiFlutterServiceProvider);
  return BatchTransactionNotifier(aiService, ref);
});