// File: lib/src/data/models/savings_goal_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final bool isActive;
  final DateTime createdAt;

  SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.isActive,
    required this.createdAt,
  });

  // İlerleme yüzdesini hesaplayan bir yardımcı getter
  double get progress => (targetAmount > 0) ? (currentAmount / targetAmount) : 0.0;

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num).toDouble(),
      targetDate: (map['targetDate'] is Timestamp) 
          ? (map['targetDate'] as Timestamp).toDate() 
          : DateTime.parse(map['targetDate'] as String),
      isActive: map['isActive'] as bool,
      createdAt: (map['createdAt'] is Timestamp) 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'targetDate': targetDate.toIso8601String(),
    };
  }
}