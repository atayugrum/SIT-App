// File: lib/src/presentation/providers/transaction_form_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import 'auth_providers.dart';

/// Form'da tutulacak tüm alanları temsil eden model.
class TransactionFormData {
  final String? id;
  final String type;
  final String? category;
  final String? subCategory;
  final double? amount;
  final DateTime date;
  final String? account;
  final String? description;
  final int? incomeAllocationPct;
  final bool isRecurring;
  final String? recurrenceRule;
  final bool? isNeed;
  final String? emotion;
  final DateTime? originalCreatedAt;

  TransactionFormData({
    this.id,
    this.type = 'expense',
    this.category,
    this.subCategory,
    this.amount,
    required this.date,
    this.account,
    this.description,
    this.incomeAllocationPct,
    this.isRecurring = false,
    this.recurrenceRule,
    this.isNeed,
    this.emotion,
    this.originalCreatedAt,
  });

  TransactionFormData copyWith({
    String? id,
    String? type,
    String? category,
    String? subCategory,
    double? amount,
    DateTime? date,
    String? account,
    String? description,
    int? incomeAllocationPct,
    bool? isRecurring,
    String? recurrenceRule,
    bool? isNeed,
    String? emotion,
    DateTime? originalCreatedAt,
    bool clearSubCategory = false,
    bool clearIncomeAllocationPct = false,
    bool clearNeed = false,
    bool clearEmotion = false,
  }) {
    final String effectiveType = type ?? this.type;

    return TransactionFormData(
      id: id ?? this.id, // DÜZELTME: id'nin null olmaması için
      type: effectiveType,
      category: category ?? this.category,
      subCategory: clearSubCategory ? null : subCategory ?? this.subCategory,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      account: account ?? this.account,
      description: description ?? this.description,
      incomeAllocationPct: clearIncomeAllocationPct ? null : (effectiveType == 'income' ? (incomeAllocationPct ?? this.incomeAllocationPct) : null),
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      isNeed: clearNeed ? null : (effectiveType == 'expense' ? (isNeed ?? this.isNeed) : null),
      emotion: clearEmotion ? null : (effectiveType == 'expense' ? (emotion ?? this.emotion) : null),
      originalCreatedAt: originalCreatedAt ?? this.originalCreatedAt,
    );
  }
}

/// Form verisini tutan ve işleyen StateNotifier.
class TransactionFormNotifier extends StateNotifier<TransactionFormData> {
  // DÜZELTME: _userId saklamak yerine Ref objesini saklıyoruz.
  final Ref _ref;

  TransactionFormNotifier(this._ref) : super(TransactionFormData(date: DateTime.now(), incomeAllocationPct: 0));

  void updateType(String type) {
    state = state.copyWith(
      type: type,
      category: null,
      subCategory: null,
      clearSubCategory: true,
      incomeAllocationPct: type == 'income' ? (state.incomeAllocationPct ?? 0) : null,
      clearNeed: type != 'expense',
      clearEmotion: type != 'expense',
    );
  }

  void updateCategory(String? category) {
    state = state.copyWith(category: category, subCategory: null, clearSubCategory: true);
  }

  void updateSubCategory(String? subCategory) {
    state = state.copyWith(subCategory: subCategory);
  }

  void updateAmount(double? amount) {
    state = state.copyWith(amount: amount);
  }

  void updateDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void updateDescription(String? description) {
    state = state.copyWith(description: description);
  }

  void updateIsRecurring(bool isRecurring) {
    state = state.copyWith(isRecurring: isRecurring, recurrenceRule: isRecurring ? state.recurrenceRule : null);
  }

  void updateRecurrenceRule(String? rule) {
    state = state.copyWith(recurrenceRule: rule);
  }

  void updateAccount(String? account) {
    state = state.copyWith(account: account);
  }

  void updateIncomeAllocationPct(int? pct) {
    if (state.type == 'income') {
      state = state.copyWith(incomeAllocationPct: pct);
    }
  }

  void updateIsNeed(bool? isNeed) {
    if (state.type == 'expense') {
      state = state.copyWith(isNeed: isNeed);
    }
  }

  void updateEmotion(String? emotion) {
    if (state.type == 'expense') {
      state = state.copyWith(emotion: emotion);
    }
  }

  void loadTransactionForEdit(TransactionModel transaction) {
    state = TransactionFormData(
      id: transaction.id,
      type: transaction.type,
      category: transaction.category,
      subCategory: transaction.subCategory,
      amount: transaction.amount,
      date: transaction.date,
      account: transaction.accountId,
      description: transaction.description,
      isRecurring: transaction.isRecurring,
      recurrenceRule: transaction.recurrenceRule,
      incomeAllocationPct: transaction.type == 'income' ? (transaction.incomeAllocationPct ?? 0) : null,
      isNeed: transaction.type == 'expense' ? transaction.isNeed : null,
      emotion: transaction.type == 'expense' ? transaction.emotion : null,
      originalCreatedAt: transaction.createdAt,
    );
  }

  /// Kaydetme aşamasında formdaki alanları kontrol edip TransactionModel üretiyoruz.
  TransactionModel? toTransactionModel() {
    // DÜZELTME: userId'yi ihtiyaç anında ref'ten oku
    final userId = _ref.read(userIdProvider);

    if (userId == null || state.category == null || state.amount == null || state.account == null) {
      return null;
    }

    return TransactionModel(
      id: state.id,
      userId: userId, // Artık '!' operatörüne gerek yok ve her zaman dolu
      type: state.type,
      category: state.category!,
      subCategory: state.subCategory,
      amount: state.amount!,
      date: state.date,
      accountId: state.account!,
      description: state.description,
      isRecurring: state.isRecurring,
      recurrenceRule: state.recurrenceRule,
      incomeAllocationPct: state.type == 'income' ? (state.incomeAllocationPct ?? 0) : null,
      isNeed: state.type == 'expense' ? state.isNeed : null,
      emotion: state.type == 'expense' ? state.emotion : null,
      createdAt: state.id != null ? (state.originalCreatedAt ?? DateTime.now()) : DateTime.now(), 
      updatedAt: DateTime.now(),
    );
  }

  void reset() {
    state = TransactionFormData(date: DateTime.now(), incomeAllocationPct: 0);
  }

  void partialResetForNewEntry({
    required String originalType,
    DateTime? originalDate,
    String? originalAccount,
    String? originalCategory,
    String? originalSubCategory,
  }) {
    state = TransactionFormData(
      type: originalType,
      date: originalDate ?? DateTime.now(),
      account: originalAccount,
      category: originalCategory,
      subCategory: originalSubCategory,
      id: null,
      amount: null,
      description: null,
      incomeAllocationPct: originalType == 'income' ? 0 : null,
      isRecurring: false,
      recurrenceRule: null,
      isNeed: null,
      emotion: null,
    );
  }
}

final transactionFormNotifierProvider = StateNotifierProvider.autoDispose<TransactionFormNotifier, TransactionFormData>((ref) {
  // DÜZELTME: Notifier'a artık userId yerine doğrudan 'ref'i veriyoruz.
  return TransactionFormNotifier(ref);
});