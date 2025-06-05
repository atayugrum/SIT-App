// File: flutter_app/lib/src/data/models/account_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountModel {
  final String? id; // Firestore document ID
  final String userId;
  final String accountName;
  final String accountType; // e.g., "Bank", "Cash", "Credit Card"
  final double initialBalance;
  final double currentBalance; 
  final String currency; // e.g., "TRY", "USD"
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  AccountModel({
    this.id,
    required this.userId,
    required this.accountName,
    required this.accountType,
    this.initialBalance = 0.0,
    required this.currentBalance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  static DateTime _parseDate(dynamic dateInput) {
    if (dateInput == null) return DateTime.now();
    if (dateInput is Timestamp) return dateInput.toDate();
    if (dateInput is String) return DateTime.tryParse(dateInput) ?? DateTime.now();
    return DateTime.now();
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      accountName: map['accountName'] as String? ?? 'Unknown Account',
      accountType: map['accountType'] as String? ?? 'Other',
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'TRY',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    // Used when sending data to the backend (e.g., for creation)
    return {
      // 'id': id, // ID is not sent when creating if backend generates it
      'userId': userId, // Usually set by backend based on authenticated user
      'accountName': accountName,
      'accountType': accountType,
      'initialBalance': initialBalance,
      'currentBalance': currentBalance, // For creation, this might be same as initialBalance
      'currency': currency,
      // 'createdAt': createdAt.toIso8601String(), // Backend should handle timestamps
      // 'updatedAt': updatedAt.toIso8601String(), // Backend should handle timestamps
      // 'isArchived': isArchived, // Backend might default this
    };
  }
}