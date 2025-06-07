// File: lib/src/data/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionModel {
  final String? id;
  final String userId;
  final String type;
  final String category;
  final String? subCategory;
  final double amount;
  final DateTime date;
  final String account;
  final String? description;
  final bool isRecurring;
  final String? recurrenceRule;
  final bool? isNeed;
  final String? emotion;
  final int? incomeAllocationPct;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    this.id,
    required this.userId,
    required this.type,
    required this.category,
    this.subCategory,
    required this.amount,
    required this.date,
    required this.account,
    this.description,
    this.isRecurring = false,
    this.recurrenceRule,
    this.isNeed,
    this.emotion,
    this.incomeAllocationPct,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic dateInput) {
    if (dateInput is Timestamp) return dateInput.toDate();
    if (dateInput is String) return DateTime.tryParse(dateInput) ?? DateTime.now();
    return DateTime.now();
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'expense',
      category: map['category'] as String? ?? 'Uncategorized',
      subCategory: map['subCategory'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: _parseDate(map['date']),
      account: map['account'] as String? ?? '',
      description: map['description'] as String?,
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrenceRule: map['recurrenceRule'] as String?,
      isNeed: map['isNeed'] as bool?,
      emotion: map['emotion'] as String?,
      incomeAllocationPct: map['incomeAllocationPct'] as int?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'type': type,
      'category': category,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'account': account,
      'isRecurring': isRecurring,
      // Null olmayan alanları ekle
      if (id != null) 'id': id,
      if (subCategory != null) 'subCategory': subCategory,
      if (description != null) 'description': description,
      if (recurrenceRule != null) 'recurrenceRule': recurrenceRule,
      if (isNeed != null) 'isNeed': isNeed,
      if (emotion != null) 'emotion': emotion,
      if (type == 'income' && incomeAllocationPct != null)
        'incomeAllocationPct': incomeAllocationPct,
    };
    return map;
  }
  
  // YENİ METOD: Sadece güncellenebilir alanları içeren bir map döndürür.
  Map<String, dynamic> toMapForUpdate() {
    return {
      'type': type,
      'category': category,
      'subCategory': subCategory,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'account': account,
      'description': description,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule,
      'isNeed': isNeed,
      'emotion': emotion,
      'incomeAllocationPct': incomeAllocationPct,
      // userId, createdAt gibi alanlar güncellemede gönderilmez.
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? category,
    String? subCategory,
    double? amount,
    DateTime? date,
    String? account,
    String? description,
    bool? isRecurring,
    String? recurrenceRule,
    bool? isNeed,
    String? emotion,
    int? incomeAllocationPct,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      account: account ?? this.account,
      description: description ?? this.description,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      isNeed: isNeed ?? this.isNeed,
      emotion: emotion ?? this.emotion,
      incomeAllocationPct: incomeAllocationPct ?? this.incomeAllocationPct,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}