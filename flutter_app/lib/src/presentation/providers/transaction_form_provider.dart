// File: flutter_app/lib/src/presentation/providers/transaction_form_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import 'auth_providers.dart';

class TransactionFormData {
  final String? id;
  final String type;
  final String? category;
  final String? subCategory;
  final double? amount;
  final DateTime date;
  final String? account;
  final String? description;
  final int? incomeAllocationPct; // Null olabilir (örneğin giderse veya kullanıcı girmemişse)
  final bool isRecurring;
  final String? recurrenceRule;
  final bool? isNeed;
  final String? emotion;

  TransactionFormData({
    this.id,
    this.type = 'expense', // Varsayılan tip
    this.category,
    this.subCategory,
    this.amount,
    required this.date,
    this.account,
    this.description,
    this.incomeAllocationPct, // Gelir için varsayılanı notifier'da set et
    this.isRecurring = false,
    this.recurrenceRule,
    this.isNeed,
    this.emotion,
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
    int? incomeAllocationPct, // Gelen yeni değer
    bool? isRecurring,
    String? recurrenceRule,
    bool? isNeed,
    String? emotion,
    bool setIncomeAllocationPctToNull = false, // incomeAllocationPct'yi explicit null yapmak için flag
    bool setIsNeedToNull = false,
    bool setEmotionToNull = false,
  }) {
    final String effectiveType = type ?? this.type;

    return TransactionFormData(
      id: id ?? this.id,
      type: effectiveType,
      category: category ?? this.category,
      subCategory: subCategory == null && this.category != (category ?? this.category) ? null : (subCategory ?? this.subCategory), // Kategori değişirse alt kategoriyi sıfırla
      amount: amount ?? this.amount,
      date: date ?? this.date,
      account: account ?? this.account,
      description: description ?? this.description,
      incomeAllocationPct: setIncomeAllocationPctToNull 
          ? null 
          : (effectiveType == 'income' 
              // Eğer copyWith'e incomeAllocationPct için bir değer (null dahil) geldiyse onu kullan,
              // gelmediyse mevcut (this.incomeAllocationPct) değeri koru.
              ? (incomeAllocationPct != this.incomeAllocationPct && incomeAllocationPct == null ? null : (incomeAllocationPct ?? this.incomeAllocationPct)) 
              : null), // Giderse null yap
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: isRecurring == false ? null : (recurrenceRule ?? this.recurrenceRule),
      isNeed: setIsNeedToNull ? null : (effectiveType == 'expense' ? (isNeed ?? this.isNeed) : null),
      emotion: setEmotionToNull ? null : (effectiveType == 'expense' ? (emotion ?? this.emotion) : null),
    );
  }
}

class TransactionFormNotifier extends StateNotifier<TransactionFormData> {
  final String? _userId;

  TransactionFormNotifier(this._userId) 
      : super(TransactionFormData(date: DateTime.now(), type: 'expense', incomeAllocationPct: null)); // Başlangıçta incomeAlloc null, type expense

  void updateType(String type) {
    print("FORM_NOTIFIER: Updating type to $type");
    state = state.copyWith(
      type: type,
      category: null,
      subCategory: null,
      // Tip değiştiğinde, türe özel alanları sıfırla/ayarla
      incomeAllocationPct: type == 'income' ? (state.incomeAllocationPct ?? 0) : null, // Gelir ise 0 yap, değilse null
      setIncomeAllocationPctToNull: type == 'expense', // Eğer gidere geçiyorsa kesin null yap
      isNeed: type == 'expense' ? state.isNeed : null,
      setIsNeedToNull: type == 'income',
      emotion: type == 'expense' ? state.emotion : null,
      setEmotionToNull: type == 'income',
    );
  }

  void updateCategory(String? category) {
    print("FORM_NOTIFIER: Updating category to $category");
    state = state.copyWith(category: category, subCategory: null); // Kategori değişince alt kategori sıfırlanır
  }

  void updateSubCategory(String? subCategory) {
    print("FORM_NOTIFIER: Updating subCategory to $subCategory");
    state = state.copyWith(subCategory: subCategory);
  }

  void updateAmount(double? amount) {
    print("FORM_NOTIFIER: Updating amount to $amount");
    state = state.copyWith(amount: amount);
  }

  void updateDate(DateTime date) {
    print("FORM_NOTIFIER: Updating date to $date");
    state = state.copyWith(date: date);
  }

  void updateDescription(String? description) {
    print("FORM_NOTIFIER: Updating description to $description");
    state = state.copyWith(description: description);
  }
  
  void updateIsRecurring(bool isRecurring) {
    print("FORM_NOTIFIER: Updating isRecurring to $isRecurring");
    state = state.copyWith(isRecurring: isRecurring, recurrenceRule: isRecurring ? state.recurrenceRule : null);
  }

  void updateRecurrenceRule(String? rule) {
    print("FORM_NOTIFIER: Updating recurrenceRule to $rule");
    state = state.copyWith(recurrenceRule: rule);
  }

  void updateIncomeAllocationPct(int? pct) {
    // Bu metod sadece gelir tipindeyken çağrılmalı (UI kontrolü)
    if (state.type == 'income') {
      print("FORM_NOTIFIER: Updating incomeAllocationPct to $pct");
      state = state.copyWith(incomeAllocationPct: pct, setIncomeAllocationPctToNull: pct == null); // Eğer pct null ise, null olarak set et
      print("FORM_NOTIFIER: After update, state.incomeAllocationPct is ${state.incomeAllocationPct}");
    }
  }
  
  void updateAccount(String? account) {
    print("FORM_NOTIFIER: Updating account to $account");
    state = state.copyWith(account: account);
  }

  void updateIsNeed(bool? isNeed) {
    if (state.type == 'expense') {
      print("FORM_NOTIFIER: Updating isNeed to $isNeed");
      state = state.copyWith(isNeed: isNeed, setIsNeedToNull: isNeed == null);
    }
  }

  void updateEmotion(String? emotion) {
    if (state.type == 'expense') {
      print("FORM_NOTIFIER: Updating emotion to $emotion");
      state = state.copyWith(emotion: emotion, setEmotionToNull: emotion == null);
    }
  }

  void loadTransactionForEdit(TransactionModel transaction) {
    print("FORM_NOTIFIER: Loading transaction for edit. ID: ${transaction.id}, AllocPct: ${transaction.incomeAllocationPct}");
    state = TransactionFormData(
      id: transaction.id,
      type: transaction.type,
      category: transaction.category,
      subCategory: transaction.subCategory,
      amount: transaction.amount,
      date: transaction.date,
      account: transaction.account,
      description: transaction.description,
      incomeAllocationPct: transaction.type == 'income' ? (transaction.incomeAllocationPct) : null, // Keep null if model has null
      isRecurring: transaction.isRecurring,
      recurrenceRule: transaction.recurrenceRule,
      isNeed: transaction.type == 'expense' ? transaction.isNeed : null,
      emotion: transaction.type == 'expense' ? transaction.emotion : null,
    );
  }

  TransactionModel? toTransactionModel() {
    if (_userId == null || state.category == null || state.amount == null || state.account == null ) {
      print("FORM_NOTIFIER: toTransactionModel validation failed. UserID, Category, Amount, Account, or Date is null.");
      print("Details: UserID: $_userId, Category: ${state.category}, Amount: ${state.amount}, Account: ${state.account}, Date: ${state.date}");
      return null; 
    }
    // Eğer type income ve incomeAllocationPct null ise, backend'e 0 gönder.
    // Kullanıcı boş bırakırsa (onChanged'da null gelir), bu 0 olarak yorumlanmalı.
    int? finalIncomeAllocPct = state.incomeAllocationPct;
    if (state.type == 'income' && state.incomeAllocationPct == null) {
        finalIncomeAllocPct = 0;
    }

    print("FORM_NOTIFIER: Creating TransactionModel. incomeAllocationPct to be used in model: $finalIncomeAllocPct (Original state: ${state.incomeAllocationPct})");
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
      incomeAllocationPct: state.type == 'income' ? finalIncomeAllocPct : null, 
      isNeed: state.type == 'expense' ? state.isNeed : null,
      emotion: state.type == 'expense' ? state.emotion : null,
      createdAt: DateTime.now(), 
      updatedAt: DateTime.now(), 
    );
  }

  void reset() {
    print("FORM_NOTIFIER: Resetting form to initial state.");
    state = TransactionFormData(date: DateTime.now(), type: 'expense', incomeAllocationPct: null); 
  }

  void partialResetForNewEntry({
    required String originalType,
    DateTime? originalDate,
    String? originalAccount,
    String? originalCategory,
  }) {
    print("FORM_NOTIFIER: Partial reset. Original type: $originalType");
    state = TransactionFormData(
      type: originalType, 
      date: originalDate ?? DateTime.now(), 
      account: originalAccount, 
      category: originalCategory, 
      incomeAllocationPct: originalType == 'income' ? 0 : null,
      isRecurring: false, 
    );
  }
}

final transactionFormNotifierProvider = StateNotifierProvider<TransactionFormNotifier, TransactionFormData>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  return TransactionFormNotifier(userId);
});