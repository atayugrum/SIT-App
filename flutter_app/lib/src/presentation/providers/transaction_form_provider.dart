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

  TransactionFormData({
    this.id,
    this.type = 'expense', // Varsayılan: expense
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
  });

  /// copyWith sayesinde belirli alanları güncelleyip yeni bir state oluşturabiliyoruz.
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
    // Aşağıdakiler true ise ilgili alan null'a çekilecek:
    bool clearSubCategory = false,
    bool clearIncomeAllocationPct = false,
    bool clearNeed = false,
    bool clearEmotion = false,
  }) {
    // Eğer yeni bir type gelmişse, önceki type'a bağlı olarak bazı alanları temizlemek gerekebilir.
    final String effectiveType = type ?? this.type;

    return TransactionFormData(
      id: id, // id'yi null yapmak için ?? this.id kullanmıyoruz
      type: effectiveType,
      category: category ?? this.category,
      subCategory: clearSubCategory
          ? null
          : subCategory ?? this.subCategory,
      amount: amount ?? this.amount, // amount'u null yapmak için ?? this.amount kullanmıyoruz
      date: date ?? this.date,
      account: account ?? this.account,
      description: description,
      incomeAllocationPct: clearIncomeAllocationPct
          ? null
          : (effectiveType == 'income'
              ? (incomeAllocationPct ?? this.incomeAllocationPct)
              : null),
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule,
      isNeed: clearNeed
          ? null
          : (effectiveType == 'expense'
              ? (isNeed ?? this.isNeed)
              : null),
      emotion: clearEmotion
          ? null
          : (effectiveType == 'expense'
              ? (emotion ?? this.emotion)
              : null),
    );
  }
}

/// Form verisini tutan ve işleyen StateNotifier.
class TransactionFormNotifier extends StateNotifier<TransactionFormData> {
  final String? _userId;

  TransactionFormNotifier(this._userId)
      : super(TransactionFormData(
          date: DateTime.now(),
          incomeAllocationPct: 0,
        ));

  /// Tür değiştiğinde (income/expense), ilgili alanları resetliyoruz.
  void updateType(String type) {
    print("FORM_NOTIFIER: Updating type to $type");
    state = state.copyWith(
      type: type,
      category: null,
      subCategory: null,
      clearSubCategory: true,
      incomeAllocationPct: type == 'income'
          ? (state.incomeAllocationPct ?? 0)
          : null,
      clearNeed: type != 'expense',
      clearEmotion: type != 'expense',
    );
  }

  void updateCategory(String? category) {
    state = state.copyWith(
      category: category,
      subCategory: null,
      clearSubCategory: true,
    );
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
    state = state.copyWith(
      isRecurring: isRecurring,
      recurrenceRule: isRecurring ? state.recurrenceRule : null,
    );
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

  /// Var olan bir transaction'ı düzenlemek için, notifier'a veri yüklüyoruz.
  void loadTransactionForEdit(TransactionModel transaction) {
    print(
        "FORM_NOTIFIER: Loading transaction for edit. ID: ${transaction.id}, AllocPct: ${transaction.incomeAllocationPct}");
    state = TransactionFormData(
      id: transaction.id,
      type: transaction.type,
      category: transaction.category,
      subCategory: transaction.subCategory,
      amount: transaction.amount,
      date: transaction.date,
      account: transaction.account,
      description: transaction.description,
      isRecurring: transaction.isRecurring,
      recurrenceRule: transaction.recurrenceRule,
      incomeAllocationPct:
          transaction.type == 'income' ? (transaction.incomeAllocationPct ?? 0) : null,
      isNeed: transaction.type == 'expense' ? transaction.isNeed : null,
      emotion: transaction.type == 'expense' ? transaction.emotion : null,
    );
  }

  /// Kaydetme aşamasında formdaki alanları kontrol edip TransactionModel üretiyoruz.
  TransactionModel? toTransactionModel() {
    if (_userId == null ||
        state.category == null ||
        state.amount == null ||
        state.account == null) {
          print("FORM_NOTIFIER: Missing required fields. UserId: $_userId, Category: ${state.category}, Amount: ${state.amount}, Account: ${state.account}");
          
      print("FORM_NOTIFIER: Validation failed for toTransactionModel.");
      return null;
    }

    print(
        "FORM_NOTIFIER: Creating TransactionModel. incomeAllocationPct: ${state.incomeAllocationPct}");
    return TransactionModel(
      id: state.id,
      userId: _userId,
      type: state.type,
      category: state.category!,
      subCategory: state.subCategory,
      amount: state.amount!,
      date: state.date,
      account: state.account!,
      description: state.description,
      isRecurring: state.isRecurring,
      recurrenceRule: state.recurrenceRule,
      incomeAllocationPct:
          state.type == 'income' ? (state.incomeAllocationPct ?? 0) : null,
      isNeed: state.type == 'expense' ? state.isNeed : null,
      emotion: state.type == 'expense' ? state.emotion : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Formu tamamen varsayılan save etmek istiyorsak reset ediyoruz.
  void reset() {
    print("TRANSACTION_FORM_NOTIFIER: Resetting form.");
    state = TransactionFormData(date: DateTime.now(), incomeAllocationPct: 0);
  }

  /// "Save & Add Another" işlemi sonrası, bazı alanları koruyup geri kalanları sıfırlıyoruz.
  void partialResetForNewEntry({
    required String originalType,
    DateTime? originalDate,
    String? originalAccount,
    String? originalCategory,
    String? originalSubCategory,
  }) {
    print(
        "TRANSACTION_FORM_NOTIFIER: Partial reset. Keeping Type: $originalType, Account: $originalAccount, Category: $originalCategory, SubCategory: $originalSubCategory");
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

/// Provider'ımız
final transactionFormNotifierProvider =
    StateNotifierProvider<TransactionFormNotifier, TransactionFormData>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  return TransactionFormNotifier(userId);
});
