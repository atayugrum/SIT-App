// File: flutter_app/lib/src/data/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // DateFormat için

class TransactionModel {
  final String? id;
  final String userId;
  final String type; // 'income' or 'expense'
  final String category;
  final String? subCategory;
  final double amount;
  final DateTime date;
  final String account;
  final String? description;
  final bool isRecurring;
  final String? recurrenceRule;
  final int? incomeAllocationPct; // Nullable int
  final bool? isNeed;
  final String? emotion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted; // Soft delete için

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
    this.incomeAllocationPct, // Null olabilir
    this.isNeed,
    this.emotion,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  static DateTime _parseDate(dynamic dateInput) {
    if (dateInput == null) return DateTime.now();
    if (dateInput is Timestamp) return dateInput.toDate();
    if (dateInput is String) {
      // Hem ISO hem de "yyyy-MM-dd" formatını handle etmeye çalışalım
      try {
        return DateTime.parse(dateInput);
      } catch (e) {
        try {
          return DateFormat('yyyy-MM-dd').parseStrict(dateInput);
        } catch (e2) {
          print("Error parsing date from string '$dateInput': $e2");
          return DateTime.now();
        }
      }
    }
    return DateTime.now();
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'expense',
      category: map['category'] as String? ?? 'Unknown',
      subCategory: map['subCategory'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: _parseDate(map['date']),
      account: map['account'] as String? ?? 'N/A',
      description: map['description'] as String?,
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrenceRule: map['recurrenceRule'] as String?,
      incomeAllocationPct: map['incomeAllocationPct'] as int?,
      isNeed: map['isNeed'] as bool?,
      emotion: map['emotion'] as String?,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() { // API'ye gönderilecek map
    final Map<String, dynamic> data = {
      // 'id': id, // ID backend'den geliyor veya update için gönderiliyor
      'userId': userId, // Backend'de auth token'dan alınmalı, ama modelde bulunsun
      'type': type,
      'category': category,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(date), // Backend string bekliyor
      'account': account,
      'isRecurring': isRecurring,
      // Null olmayan alanları ekle
      if (subCategory != null && subCategory!.isNotEmpty) 'subCategory': subCategory,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (recurrenceRule != null && recurrenceRule!.isNotEmpty) 'recurrenceRule': recurrenceRule,
      if (isNeed != null) 'isNeed': isNeed,
      if (emotion != null && emotion!.isNotEmpty) 'emotion': emotion,
    };

    // incomeAllocationPct SADECE gelir tipindeyse ve null değilse eklenmeli
    // Eğer 0 ise yine de gönderilmeli (kullanıcı özellikle 0 seçmiş olabilir)
    if (type == 'income') {
      data['incomeAllocationPct'] = incomeAllocationPct; // Null olabilir, backend int? bekliyor
    }
    
    // id alanı sadece PUT (update) isteğinde gönderilmeli, POST (create) için değil.
    // Bu ayrımı serviste yapmak daha iyi olabilir. Şimdilik hep gönderelim, backend create'te ignore edebilir.
    // if (id != null) data['id'] = id; 

    return data;
  }
}