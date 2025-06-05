// File: lib/src/presentation/providers/analytics_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/analytics_models.dart';
import '../../data/services/analytics_flutter_service.dart';

final analyticsPeriodProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1); 
});
final analyticsDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  final threeMonthsAgo = DateTime(now.year, now.month - 2, 1); 
  return DateTimeRange(start: threeMonthsAgo, end: now); 
});
final monthlyExpenseSummaryProvider = FutureProvider.autoDispose<MonthlyExpenseSummaryModel>((ref) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  final period = ref.watch(analyticsPeriodProvider);
  try { return await analyticsService.getMonthlyExpenseSummary(period.year, period.month);
  } catch (e) { throw Exception("Error fetching monthly expense summary: ${e.toString().replaceFirst("Exception: ", "")}");}
});
final incomeExpenseAnalysisProvider = FutureProvider.autoDispose<IncomeExpenseAnalysisModel>((ref) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  final period = ref.watch(analyticsPeriodProvider);
  try { return await analyticsService.getIncomeExpenseAnalysis(period.year, period.month);
  } catch (e) { throw Exception("Error fetching income/expense analysis: ${e.toString().replaceFirst("Exception: ", "")}");}
});
final spendingTrendProvider = FutureProvider.autoDispose.family<SpendingTrendModel, String>((ref, periodParam) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  try { return await analyticsService.getSpendingTrend(period: periodParam);
  } catch (e) { throw Exception("Error fetching spending trend for $periodParam: ${e.toString().replaceFirst("Exception: ", "")}");}
});
final categoryTrendDataProvider = FutureProvider.autoDispose<CategoryTrendDataModel>((ref) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  final dateRange = ref.watch(analyticsDateRangeProvider);
  try { return await analyticsService.getCategoryTrendData(startDate: dateRange.start, endDate: dateRange.end);
  } catch (e) { throw Exception("Error fetching category trend data: ${e.toString().replaceFirst("Exception: ", "")}");}
});
final dashboardInsightsProvider = FutureProvider.autoDispose<DashboardInsightsModel>((ref) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  try { return await analyticsService.getDashboardInsights();
  } catch (e) { throw Exception("Error fetching dashboard insights: ${e.toString().replaceFirst("Exception: ", "")}");}
});