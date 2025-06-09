// File: lib/src/data/models/analytics_models.dart

// Ana Dashboard verisini tutan model
class DashboardInsightsModel {
  final IncomeExpenseSummary incomeExpenseSummary;
  final NeedsVsWantsModel needsVsWantsSummary;
  final List<EmotionSpendingItem> emotionSummary;
  final List<CategorySpendingItem> categorySummary;
  final List<DailyExpensePoint> expenseTrend7Days;
  final double savingsBalance;

  DashboardInsightsModel({
    required this.incomeExpenseSummary,
    required this.needsVsWantsSummary,
    required this.emotionSummary,
    required this.categorySummary,
    required this.expenseTrend7Days,
    required this.savingsBalance, // YENİ
  });

  factory DashboardInsightsModel.fromMap(Map<String, dynamic> map) {
    return DashboardInsightsModel(
      incomeExpenseSummary: IncomeExpenseSummary.fromMap(map['incomeExpenseSummary'] ?? {}),
      needsVsWantsSummary: NeedsVsWantsModel.fromMap(map['needsVsWantsSummary'] ?? {}),
      emotionSummary: (map['emotionSummary'] as List<dynamic>? ?? [])
          .map((item) => EmotionSpendingItem.fromMap(item))
          .toList(),
      categorySummary: (map['categorySummary'] as List<dynamic>? ?? [])
          .map((item) => CategorySpendingItem.fromMap(item))
          .toList(),
      expenseTrend7Days: (map['expenseTrend7Days'] as List<dynamic>? ?? [])
          .map((item) => DailyExpensePoint.fromMap(item))
          .toList(),
      savingsBalance: (map['savingsBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// Alt Modeller
class IncomeExpenseSummary {
  final double incomeTotal;
  final double expenseTotal;
  final double net;
  IncomeExpenseSummary({required this.incomeTotal, required this.expenseTotal, required this.net});
  factory IncomeExpenseSummary.fromMap(Map<String, dynamic> map) {
    return IncomeExpenseSummary(
      incomeTotal: (map['incomeTotal'] as num?)?.toDouble() ?? 0.0,
      expenseTotal: (map['expenseTotal'] as num?)?.toDouble() ?? 0.0,
      net: (map['net'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class NeedsVsWantsModel {
  final double needsTotal;
  final double wantsTotal;
  NeedsVsWantsModel({required this.needsTotal, required this.wantsTotal});
  factory NeedsVsWantsModel.fromMap(Map<String, dynamic> map) {
    return NeedsVsWantsModel(
      needsTotal: (map['needsTotal'] as num?)?.toDouble() ?? 0.0,
      wantsTotal: (map['wantsTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
  double get grandTotal => needsTotal + wantsTotal;
}

class EmotionSpendingItem {
  final String emotion;
  final double totalAmount;
  EmotionSpendingItem({required this.emotion, required this.totalAmount});
  factory EmotionSpendingItem.fromMap(Map<String, dynamic> map) {
    return EmotionSpendingItem(
      emotion: map['emotion'] as String? ?? 'N/A',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategorySpendingItem {
  final String category;
  final double totalAmount;
  CategorySpendingItem({required this.category, required this.totalAmount});
  factory CategorySpendingItem.fromMap(Map<String, dynamic> map) {
    return CategorySpendingItem(
      category: map['category'] as String? ?? 'Diğer',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailyExpensePoint {
  final DateTime date;
  final double amount;
  DailyExpensePoint({required this.date, required this.amount});
  factory DailyExpensePoint.fromMap(Map<String, dynamic> map) {
    return DailyExpensePoint(
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}