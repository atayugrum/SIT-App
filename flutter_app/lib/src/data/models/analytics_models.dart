// File: lib/src/data/models/analytics_models.dart

class CategorySpending {
  final String category;
  final double amount;
  final double? percentage;
  CategorySpending({ required this.category, required this.amount, this.percentage });
  factory CategorySpending.fromMap(Map<String, dynamic> map) {
    return CategorySpending(
      category: map['category'] as String? ?? 'Uncategorized',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (map['percentage'] as num?)?.toDouble(),
    );
  }
}
class MonthlyExpenseSummaryModel { // This might be part of DashboardInsightsModel now
  final int year; final int month; final double totalExpense; final double? prevMonthTotalExpense; final double? momChangePct; final List<CategorySpending> byCategory; final List<Map<String, dynamic>> topSubCategories;
  MonthlyExpenseSummaryModel({ required this.year, required this.month, required this.totalExpense, this.prevMonthTotalExpense, this.momChangePct, required this.byCategory, required this.topSubCategories });
  factory MonthlyExpenseSummaryModel.fromMap(Map<String, dynamic> map) {
    var byCategoryList = <CategorySpending>[]; if (map['byCategory'] != null && map['byCategory'] is List) { byCategoryList = (map['byCategory'] as List).map((item) => CategorySpending.fromMap(item as Map<String, dynamic>)).toList(); }
    var topSubCategoriesList = <Map<String, dynamic>>[]; if (map['topSubCategories'] != null && map['topSubCategories'] is List) { topSubCategoriesList = List<Map<String, dynamic>>.from(map['topSubCategories']); }
    return MonthlyExpenseSummaryModel( year: map['year'] as int? ?? DateTime.now().year, month: map['month'] as int? ?? DateTime.now().month, totalExpense: (map['totalExpense'] as num?)?.toDouble() ?? 0.0, prevMonthTotalExpense: (map['prevMonthTotalExpense'] as num?)?.toDouble(), momChangePct: (map['momChangePct'] as num?)?.toDouble(), byCategory: byCategoryList, topSubCategories: topSubCategoriesList );
  }
}
class TopCategoryInfo {
  final String category; final double amount;
  TopCategoryInfo({required this.category, required this.amount});
  factory TopCategoryInfo.fromMap(Map<String, dynamic> map) { return TopCategoryInfo( category: map['category'] as String? ?? 'N/A', amount: (map['amount'] as num?)?.toDouble() ?? 0.0 ); }
}
class IncomeExpenseAnalysisModel { // This might be part of DashboardInsightsModel now
  final int year; final int month; final double totalIncome; final double totalExpense; final double net; final double? coverageRatio; final TopCategoryInfo? topIncomeCategory; final TopCategoryInfo? topExpenseCategory;
  IncomeExpenseAnalysisModel({ required this.year, required this.month, required this.totalIncome, required this.totalExpense, required this.net, this.coverageRatio, this.topIncomeCategory, this.topExpenseCategory });
  factory IncomeExpenseAnalysisModel.fromMap(Map<String, dynamic> map) {
    return IncomeExpenseAnalysisModel( year: map['year'] as int? ?? DateTime.now().year, month: map['month'] as int? ?? DateTime.now().month, totalIncome: (map['totalIncome'] as num?)?.toDouble() ?? 0.0, totalExpense: (map['totalExpense'] as num?)?.toDouble() ?? 0.0, net: (map['net'] as num?)?.toDouble() ?? 0.0, coverageRatio: (map['coverageRatio'] as num?)?.toDouble(), topIncomeCategory: map['topIncomeCategory'] != null ? TopCategoryInfo.fromMap(map['topIncomeCategory'] as Map<String, dynamic>) : null, topExpenseCategory: map['topExpenseCategory'] != null ? TopCategoryInfo.fromMap(map['topExpenseCategory'] as Map<String, dynamic>) : null );
  }
}
class SpendingTrendModel {
  final String period; final double lastTotal; final double prevTotal; final double? trendPercent;
  SpendingTrendModel({ required this.period, required this.lastTotal, required this.prevTotal, this.trendPercent });
  factory SpendingTrendModel.fromMap(Map<String, dynamic> map) { return SpendingTrendModel( period: map['period'] as String? ?? 'N/A', lastTotal: (map['lastTotal'] as num?)?.toDouble() ?? 0.0, prevTotal: (map['prevTotal'] as num?)?.toDouble() ?? 0.0, trendPercent: (map['trendPercent'] as num?)?.toDouble() ); }
}
class CategoryTrendDataModel {
  final List<String> labels; final Map<String, List<double>> data;
  CategoryTrendDataModel({ required this.labels, required this.data });
  factory CategoryTrendDataModel.fromMap(Map<String, dynamic> map) { Map<String, List<double>> parsedData = {}; if (map['data'] != null && map['data'] is Map) { (map['data'] as Map<String, dynamic>).forEach((category, amounts) { if (amounts is List) { parsedData[category] = amounts.map((amount) => (amount as num).toDouble()).toList(); }}); } return CategoryTrendDataModel( labels: map['labels'] != null ? List<String>.from(map['labels']) : [], data: parsedData ); }
}
class DailyExpense {
  final DateTime date; final double dailyExpense;
  DailyExpense({required this.date, required this.dailyExpense});
  factory DailyExpense.fromMap(Map<String, dynamic> map) { return DailyExpense( date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(), dailyExpense: (map['dailyExpense'] as num?)?.toDouble() ?? 0.0 ); }
}
class BudgetFeedbackItemModel {
  final String category; final double spent; final double? limit; final String status; final double? excessAmount; final double? excessPct; final double? remainingAmount; final double? usedPct;
  BudgetFeedbackItemModel({ required this.category, required this.spent, this.limit, required this.status, this.excessAmount, this.excessPct, this.remainingAmount, this.usedPct });
  factory BudgetFeedbackItemModel.fromMap(Map<String, dynamic> map) {
    return BudgetFeedbackItemModel( category: map['category'] as String? ?? 'Uncategorized', spent: (map['spent'] as num?)?.toDouble() ?? 0.0, limit: (map['limit'] as num?)?.toDouble(), status: map['status'] as String? ?? 'unknown', excessAmount: (map['excessAmount'] as num?)?.toDouble(), excessPct: (map['excessPct'] as num?)?.toDouble(), remainingAmount: (map['remainingAmount'] as num?)?.toDouble(), usedPct: (map['usedPct'] as num?)?.toDouble() );
  }
}
class DashboardInsightsModel {
  final IncomeExpenseAnalysisModel? currentMonthIncomeExpense;
  final List<CategorySpending>? currentMonthExpenseByCategory;
  final double savingsBalance;
  final List<DailyExpense> expenseTrend7Days;
  final List<BudgetFeedbackItemModel>? budgetFeedback;
  final SpendingTrendModel? spendingTrend6m; // Added for 6m trend

  DashboardInsightsModel({
    this.currentMonthIncomeExpense,
    this.currentMonthExpenseByCategory,
    required this.savingsBalance,
    required this.expenseTrend7Days,
    this.budgetFeedback,
    this.spendingTrend6m, // Added
  });

  factory DashboardInsightsModel.fromMap(Map<String, dynamic> map) {
    return DashboardInsightsModel(
      currentMonthIncomeExpense: map['currentMonthIncomeExpense'] != null ? IncomeExpenseAnalysisModel.fromMap(map['currentMonthIncomeExpense'] as Map<String, dynamic>) : null,
      currentMonthExpenseByCategory: map['currentMonthExpenseByCategory'] != null && map['currentMonthExpenseByCategory'] is List ? (map['currentMonthExpenseByCategory'] as List).map((item) => CategorySpending.fromMap(item as Map<String, dynamic>)).toList() : [],
      savingsBalance: (map['savingsBalance'] as num?)?.toDouble() ?? 0.0,
      expenseTrend7Days: map['expenseTrend7Days'] != null && map['expenseTrend7Days'] is List ? (map['expenseTrend7Days'] as List).map((item) => DailyExpense.fromMap(item as Map<String, dynamic>)).toList() : [],
      budgetFeedback: map['budgetFeedback'] != null && map['budgetFeedback'] is List ? (map['budgetFeedback'] as List).map((item) => BudgetFeedbackItemModel.fromMap(item as Map<String, dynamic>)).toList() : [],
      spendingTrend6m: map['spendingTrend6m'] != null ? SpendingTrendModel.fromMap(map['spendingTrend6m'] as Map<String, dynamic>) : null, // Added
    );
  }
}