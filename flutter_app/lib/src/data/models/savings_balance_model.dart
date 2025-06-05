// File: flutter_app/lib/src/data/models/savings_balance_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsBalanceModel {
  final double balance;
  final DateTime? updatedAt;

  SavingsBalanceModel({
    required this.balance,
    this.updatedAt,
  });

  static DateTime? _parseDate(dynamic dateInput) {
    if (dateInput == null) return null;
    if (dateInput is Timestamp) return dateInput.toDate();
    if (dateInput is String) return DateTime.tryParse(dateInput);
    return null;
  }

  factory SavingsBalanceModel.fromMap(Map<String, dynamic> map) {
    return SavingsBalanceModel(
      // API returns "balance" directly, not nested under "savingsBalance" map
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      updatedAt: _parseDate(map['updatedAt']),
    );
  }
}