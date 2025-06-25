// File: lib/src/data/models/account_model.dart

class AccountModel {
  final String id;
  final String userId;
  final String accountName;
  final String accountType;
  final double initialBalance;
  final double currentBalance;
  final String currency;
  final String? category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isArchived;
  // YENİ: Kredi kartı için opsiyonel alanlar
  final double? creditLimit;
  final int? statementDay;
  final int? dueDateDay;

  AccountModel({
    required this.id,
    required this.userId,
    required this.accountName,
    required this.accountType,
    required this.initialBalance,
    required this.currentBalance,
    required this.currency,
    this.category,
    required this.createdAt,
    this.updatedAt,
    required this.isArchived,
    this.creditLimit,
    this.statementDay,
    this.dueDateDay,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      accountName: map['accountName'] as String? ?? 'N/A',
      accountType: map['accountType'] as String? ?? 'bank',
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'TRY',
      category: map['category'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isArchived: map['isArchived'] as bool? ?? false,
      // YENİ: Kredi kartı alanlarını map'ten oku
      creditLimit: (map['creditLimit'] as num?)?.toDouble(),
      statementDay: map['statementDay'] as int?,
      dueDateDay: map['dueDateDay'] as int?,
    );
  }
}
