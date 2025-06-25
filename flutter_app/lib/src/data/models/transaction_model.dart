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
  // DÜZELTME: Alan adı 'account' yerine 'accountId' olarak değiştirildi.
  final String accountId; 
  final String? description;
  final bool isRecurring;
  final String? recurrenceRule;
  final int? incomeAllocationPct;
  final bool? isNeed;
  final String? emotion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TransactionModel({
    this.id,
    required this.userId,
    required this.type,
    required this.category,
    this.subCategory,
    required this.amount,
    required this.date,
    required this.accountId, // DÜZELTME
    this.description,
    this.isRecurring = false,
    this.recurrenceRule,
    this.incomeAllocationPct,
    this.isNeed,
    this.emotion,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'category': category,
      'subCategory': subCategory,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(date),
      // DÜZELTME: Backend'e 'account' yerine 'accountId' anahtarını gönder.
      'accountId': accountId, 
      'description': description,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule,
      'incomeAllocationPct': incomeAllocationPct,
      'isNeed': isNeed,
      'emotion': emotion,
    };
  }

  Map<String, dynamic> toMapForUpdate() {
     return {
      'type': type,
      'category': category,
      'subCategory': subCategory,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'accountId': accountId, // DÜZELTME
      'description': description,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule,
      'incomeAllocationPct': incomeAllocationPct,
      'isNeed': isNeed,
      'emotion': emotion,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'expense',
      category: map['category'] as String? ?? 'Diğer',
      subCategory: map['subCategory'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] is Timestamp 
          ? (map['date'] as Timestamp).toDate() 
          : DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      // DÜZELTME: API'den gelen 'accountId' veya eski 'account' alanını oku.
      accountId: map['accountId'] as String? ?? map['account'] as String? ?? '', 
      description: map['description'] as String?,
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrenceRule: map['recurrenceRule'] as String?,
      incomeAllocationPct: map['incomeAllocationPct'] as int?,
      isNeed: map['isNeed'] as bool?,
      emotion: map['emotion'] as String?,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : DateTime.tryParse(map['updatedAt'] as String? ?? ''),
    );
  }
}