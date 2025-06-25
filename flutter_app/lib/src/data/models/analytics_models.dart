// File: lib/src/data/models/analytics_models.dart

class AIProjectionsModel {
  final SpendingForecastModel spendingForecast;
  final SavingsPotentialModel savingsPotential;
  final List<ActionableTaskModel> actionableTasks;

  AIProjectionsModel({
    required this.spendingForecast,
    required this.savingsPotential,
    required this.actionableTasks,
  });

  factory AIProjectionsModel.fromMap(Map<String, dynamic> map) {
    return AIProjectionsModel(
      spendingForecast:
          SpendingForecastModel.fromMap(map['spendingForecast'] ?? {}),
      savingsPotential:
          SavingsPotentialModel.fromMap(map['savingsPotential'] ?? {}),
      actionableTasks: (map['actionableTasks'] as List<dynamic>? ?? [])
          .map((item) => ActionableTaskModel.fromMap(item))
          .toList(),
    );
  }
}

class SpendingForecastModel {
  final double next30Days;
  final String analysis;
  SpendingForecastModel({required this.next30Days, required this.analysis});
  factory SpendingForecastModel.fromMap(Map<String, dynamic> map) {
    return SpendingForecastModel(
      next30Days: (map['next30Days'] as num?)?.toDouble() ?? 0.0,
      analysis: map['analysis'] as String? ?? '...',
    );
  }
}

class SavingsPotentialModel {
  final double monthlyPotential;
  final String analysis;
  SavingsPotentialModel(
      {required this.monthlyPotential, required this.analysis});
  factory SavingsPotentialModel.fromMap(Map<String, dynamic> map) {
    return SavingsPotentialModel(
      monthlyPotential: (map['monthlyPotential'] as num?)?.toDouble() ?? 0.0,
      analysis: map['analysis'] as String? ?? '...',
    );
  }
}

class ActionableTaskModel {
  final String task;
  bool isCompleted;
  ActionableTaskModel({required this.task, this.isCompleted = false});
  factory ActionableTaskModel.fromMap(Map<String, dynamic> map) {
    return ActionableTaskModel(
      task: map['task'] as String? ?? '...',
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}

class DashboardInsightsModel {
  final IncomeExpenseSummary incomeExpenseSummary;
  final NeedsVsWantsModel needsVsWantsSummary;
  final List<EmotionSpendingItem> emotionSummary;
  final List<CategorySpendingItem> categorySummary;
  final List<DailyExpensePoint> expenseTrend7Days;
  final int dataSpanDays;
  final double totalFinancialBalance; // EKSİK OLan ALAN
  final double savingsBalance; // EKSİK OLan ALAN

  DashboardInsightsModel({
    required this.incomeExpenseSummary,
    required this.needsVsWantsSummary,
    required this.emotionSummary,
    required this.categorySummary,
    required this.expenseTrend7Days,
    required this.dataSpanDays,
    required this.totalFinancialBalance, // EKSİK OLan ALAN
    required this.savingsBalance, // EKSİK OLan ALAN
  });

  factory DashboardInsightsModel.fromMap(Map<String, dynamic> map) {
    return DashboardInsightsModel(
      incomeExpenseSummary:
          IncomeExpenseSummary.fromMap(map['incomeExpenseSummary'] ?? {}),
      needsVsWantsSummary:
          NeedsVsWantsModel.fromMap(map['needsVsWantsSummary'] ?? {}),
      emotionSummary: (map['emotionSummary'] as List<dynamic>? ?? [])
          .map((item) => EmotionSpendingItem.fromMap(item))
          .toList(),
      categorySummary: (map['categorySummary'] as List<dynamic>? ?? [])
          .map((item) => CategorySpendingItem.fromMap(item))
          .toList(),
      expenseTrend7Days: (map['expenseTrend7Days'] as List<dynamic>? ?? [])
          .map((item) => DailyExpensePoint.fromMap(item))
          .toList(),
      dataSpanDays: map['dataSpanDays'] as int? ?? 0,
      totalFinancialBalance:
          (map['totalFinancialBalance'] as num?)?.toDouble() ?? 0.0, // EKLENDİ
      savingsBalance:
          (map['savingsBalance'] as num?)?.toDouble() ?? 0.0, // EKLENDİ
    );
  }
}

class CategoryComparisonModel {
  final String category;
  final PeriodComparisonData currentPeriod;
  final PeriodComparisonData previousPeriod;

  CategoryComparisonModel({
    required this.category,
    required this.currentPeriod,
    required this.previousPeriod,
  });

  factory CategoryComparisonModel.fromMap(Map<String, dynamic> map) {
    return CategoryComparisonModel(
      category: map['category'] as String? ?? 'N/A',
      currentPeriod: PeriodComparisonData.fromMap(map['currentPeriod'] ?? {}),
      previousPeriod: PeriodComparisonData.fromMap(map['previousPeriod'] ?? {}),
    );
  }
}

class PeriodComparisonData {
  final String label;
  final double total;
  final List<DailyPoint> dailyPoints;

  PeriodComparisonData({
    required this.label,
    required this.total,
    required this.dailyPoints,
  });

  factory PeriodComparisonData.fromMap(Map<String, dynamic> map) {
    return PeriodComparisonData(
      label: map['label'] as String? ?? '',
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      dailyPoints: (map['dailyPoints'] as List<dynamic>? ?? [])
          .map((item) => DailyPoint.fromMap(item))
          .toList(),
    );
  }
}

class DailyPoint {
  final int day;
  final double amount;

  DailyPoint({required this.day, required this.amount});

  factory DailyPoint.fromMap(Map<String, dynamic> map) {
    return DailyPoint(
      day: map['day'] as int? ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class IncomeExpenseSummary {
  final double incomeTotal;
  final double expenseTotal;
  final double net;
  final double? incomeChangePercent;
  final double? expenseChangePercent;

  IncomeExpenseSummary({
    required this.incomeTotal,
    required this.expenseTotal,
    required this.net,
    this.incomeChangePercent,
    this.expenseChangePercent,
  });

  factory IncomeExpenseSummary.fromMap(Map<String, dynamic> map) {
    return IncomeExpenseSummary(
      incomeTotal: (map['incomeTotal'] as num?)?.toDouble() ?? 0.0,
      expenseTotal: (map['expenseTotal'] as num?)?.toDouble() ?? 0.0,
      net: (map['net'] as num?)?.toDouble() ?? 0.0,
      incomeChangePercent: (map['incomeChangePercent'] as num?)?.toDouble(),
      expenseChangePercent: (map['expenseChangePercent'] as num?)?.toDouble(),
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
  final double? budgetLimit;
  final double? budgetUsage;

  CategorySpendingItem({
    required this.category,
    required this.totalAmount,
    this.budgetLimit,
    this.budgetUsage,
  });

  factory CategorySpendingItem.fromMap(Map<String, dynamic> map) {
    return CategorySpendingItem(
      category: map['category'] as String? ?? 'Diğer',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      budgetLimit: (map['budgetLimit'] as num?)?.toDouble(),
      budgetUsage: (map['budgetUsage'] as num?)?.toDouble(),
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
