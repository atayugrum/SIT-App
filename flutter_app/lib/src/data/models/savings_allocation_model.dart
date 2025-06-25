// File: flutter_app/lib/src/data/models/savings_allocation_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// --- YENİ EKLENEN IMPORT ---
import 'package:logger/logger.dart';

class SavingsAllocationModel {
  final String? id;
  final String userId;
  final String? transactionId;
  final double amount;
  final DateTime date;
  final String source; // 'auto' or 'manual'
  final DateTime createdAt;

  SavingsAllocationModel({
    this.id,
    required this.userId,
    this.transactionId,
    required this.amount,
    required this.date,
    required this.source,
    required this.createdAt,
  });

  // Bu fonksiyon static olduğu için kendi logger'ını oluşturması daha temiz bir çözüm.
  static DateTime _parseDate(dynamic dateInput,
      {bool isDateOnlyString = false}) {
    if (dateInput == null) return DateTime.now();
    if (dateInput is Timestamp) return dateInput.toDate();
    if (dateInput is String) {
      if (isDateOnlyString) {
        // For "YYYY-MM-DD" strings
        try {
          return DateFormat('yyyy-MM-dd').parseStrict(dateInput);
        } catch (e) {
          // --- DÜZELTME: 'print' yerine 'logger.e' kullanıldı ---
          final logger = Logger();
          logger.e("Error parsing date-only string '$dateInput'", error: e);
          return DateTime.tryParse(dateInput) ??
              DateTime.now(); // Fallback to general parse
        }
      }
      return DateTime.tryParse(dateInput) ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory SavingsAllocationModel.fromMap(Map<String, dynamic> map) {
    return SavingsAllocationModel(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      transactionId: map['transactionId'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: _parseDate(map['date'], isDateOnlyString: true),
      source: map['source'] as String? ?? 'unknown',
      createdAt: _parseDate(map['createdAt']),
    );
  }
}
