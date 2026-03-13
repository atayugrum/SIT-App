// File: lib/src/presentation/providers/analytics_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/analytics_models.dart';
import '../../data/services/analytics_flutter_service.dart';
import 'analytics_v2_providers.dart';

// Ana Servis
final analyticsServiceProvider = Provider<AnalyticsFlutterService>((ref) {
  return AnalyticsFlutterService(ref);
});

// Derived providers that delegate to the unified v2 provider

final dashboardInsightsProvider =
    Provider.autoDispose<AsyncValue<DashboardInsightsModel>>((ref) {
  return ref.watch(analyticsV2Provider).whenData((v) => v.historical);
});

final incomeExpenseSummaryProvider =
    Provider.autoDispose<AsyncValue<IncomeExpenseSummary>>((ref) {
  return ref
      .watch(analyticsV2Provider)
      .whenData((v) => v.historical.incomeExpenseSummary);
});

final needsVsWantsProvider =
    Provider.autoDispose<AsyncValue<NeedsVsWantsModel>>((ref) {
  return ref
      .watch(analyticsV2Provider)
      .whenData((v) => v.historical.needsVsWantsSummary);
});

final emotionSummaryProvider =
    Provider.autoDispose<AsyncValue<List<EmotionSpendingItem>>>((ref) {
  return ref
      .watch(analyticsV2Provider)
      .whenData((v) => v.historical.emotionSummary);
});

final aiProjectionsProvider =
    Provider.autoDispose<AsyncValue<AIProjectionsModel>>((ref) {
  return ref.watch(analyticsV2Provider).whenData((v) => v.aiProjections);
});
