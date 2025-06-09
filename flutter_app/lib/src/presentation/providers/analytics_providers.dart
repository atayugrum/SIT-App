// File: lib/src/presentation/providers/analytics_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/analytics_models.dart';
import '../../data/services/analytics_flutter_service.dart';

// Ana Servis
final analyticsServiceProvider = Provider<AnalyticsFlutterService>((ref) {
  return AnalyticsFlutterService(ref);
});

// Tüm dashboard verisini tek seferde çeken ana FutureProvider
final dashboardInsightsProvider = FutureProvider.autoDispose<DashboardInsightsModel>((ref) {
  return ref.watch(analyticsServiceProvider).getDashboardInsights();
});

// === Diğer Provider'lar Ana Provider'dan Veri Alır ===

// Gelir/Gider özetini ana veriden seçerek sunar
final incomeExpenseSummaryProvider = Provider.autoDispose<AsyncValue<IncomeExpenseSummary>>((ref) {
  return ref.watch(dashboardInsightsProvider).whenData((insights) => insights.incomeExpenseSummary);
});

// İstek/İhtiyaç özetini ana veriden seçerek sunar
final needsVsWantsProvider = Provider.autoDispose<AsyncValue<NeedsVsWantsModel>>((ref) {
  return ref.watch(dashboardInsightsProvider).whenData((insights) => insights.needsVsWantsSummary);
});

// Duygu özetini ana veriden seçerek sunar
final emotionSummaryProvider = Provider.autoDispose<AsyncValue<List<EmotionSpendingItem>>>((ref) {
  return ref.watch(dashboardInsightsProvider).whenData((insights) => insights.emotionSummary);
});