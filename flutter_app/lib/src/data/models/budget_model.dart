// File: lib/src/data/models/budget_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String? id;
  final String userId;
  final String category;
  final double limitAmount;
  final String period; // e.g., 'monthly'
  final int year;
  final int month;
  final bool isAuto;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetModel({
    this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
    required this.period,
    required this.year,
    required this.month,
    this.isAuto = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map, String? documentId) {
    return BudgetModel(
      id: documentId,
      userId: map['userId'] as String,
      category: map['category'] as String,
      limitAmount: (map['limitAmount'] as num).toDouble(),
      period: map['period'] as String? ?? 'monthly',
      year: map['year'] as int,
      month: map['month'] as int,
      isAuto: map['isAuto'] as bool? ?? false,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'limitAmount': limitAmount,
      'period': period,
      'year': year,
      'month': month,
      'isAuto': isAuto,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? category,
    double? limitAmount,
    String? period,
    int? year,
    int? month,
    bool? isAuto,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      period: period ?? this.period,
      year: year ?? this.year,
      month: month ?? this.month,
      isAuto: isAuto ?? this.isAuto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}