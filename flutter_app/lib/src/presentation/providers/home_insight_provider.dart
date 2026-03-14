// File: lib/src/presentation/providers/home_insight_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ai_flutter_service.dart';
import 'auth_providers.dart';

class HomeInsightModel {
  final String headline;
  final List<String> insights;
  final List<String> actions;

  const HomeInsightModel({
    required this.headline,
    required this.insights,
    required this.actions,
  });

  factory HomeInsightModel.fromMap(Map<String, dynamic> map) {
    return HomeInsightModel(
      headline: map['headline'] as String? ?? '',
      insights: List<String>.from(map['insights'] as List? ?? []),
      actions: List<String>.from(map['actions'] as List? ?? []),
    );
  }
}

final _aiServiceProvider = Provider<AIFlutterService>((_) => AIFlutterService());

final homeInsightProvider =
    FutureProvider.autoDispose<HomeInsightModel>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) throw Exception('Oturum bulunamadı.');
  final service = ref.watch(_aiServiceProvider);
  final raw = await service.getHomeInsights(userId);
  return HomeInsightModel.fromMap(raw);
});
