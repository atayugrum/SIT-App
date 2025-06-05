// File: flutter_app/lib/src/data/models/user_category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

class UserCategoryModel {
  final String? id; // Firestore document ID
  final String userId;
  final String categoryName;
  final String categoryType; // 'income' or 'expense'
  final String? iconId; // Optional icon identifier
  final List<String> subcategories; // List of subcategory names
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserCategoryModel({
    this.id,
    required this.userId,
    required this.categoryName,
    required this.categoryType,
    this.iconId,
    this.subcategories = const [],
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic dateInput) {
    if (dateInput == null) return DateTime.now();
    if (dateInput is Timestamp) return dateInput.toDate();
    if (dateInput is String) return DateTime.tryParse(dateInput) ?? DateTime.now();
    return DateTime.now();
  }

  factory UserCategoryModel.fromMap(Map<String, dynamic> map) {
    return UserCategoryModel(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? 'Unknown Category',
      categoryType: map['categoryType'] as String? ?? 'expense',
      iconId: map['iconId'] as String?,
      subcategories: map['subcategories'] != null
          ? List<String>.from(map['subcategories'])
          : [],
      isArchived: map['isArchived'] as bool? ?? false,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMapForApi() {
    // Used when sending data to the backend (e.g., for creation/update)
    return {
      // 'id': id, // Not sent for creation, backend generates
      'userId': userId, // Usually set by backend from auth context, but good for client model
      'categoryName': categoryName,
      'categoryType': categoryType,
      if (iconId != null) 'iconId': iconId,
      'subcategories': subcategories,
      // 'isArchived': isArchived, // Backend handles default on create
      // 'createdAt': createdAt.toIso8601String(), // Backend handles
      // 'updatedAt': updatedAt.toIso8601String(), // Backend handles
    };
  }
}