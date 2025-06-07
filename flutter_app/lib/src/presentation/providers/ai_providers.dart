// File: lib/src/presentation/providers/ai_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_suggestion_model.dart';
import '../../data/services/ai_flutter_service.dart';
import 'auth_providers.dart'; // YENİ: Auth provider'ları import edildi

// AI Servisi için provider
final aiFlutterServiceProvider = Provider<AIFlutterService>((ref) {
  return AIFlutterService();
});

// Bütçe önerisi için FutureProvider.family
// 'family' kullanarak kategoriye özel anlık istekler yapabiliriz.
final budgetSuggestionProvider = FutureProvider.autoDispose
    .family<BudgetSuggestion, String>((ref, category) async {
  
  // YENİ: KULLANICI ID'SİNİ DİNAMİK OLARAK ALMA
  // authStateChangesProvider'ı izleyerek o anki kullanıcıyı alıyoruz.
  final user = ref.watch(authStateChangesProvider).value;

  // Kullanıcı oturum açmamışsa veya oturum bilgisi henüz gelmediyse hata fırlat.
  if (user == null) {
    throw Exception('Bütçe önerisi almak için kullanıcı oturumu gereklidir.');
  }

  // Firebase'den gelen gerçek kullanıcı ID'si (uid)
  final userId = user.uid;
  
  // AI servisini çağır
  final aiService = ref.watch(aiFlutterServiceProvider);
  
  return aiService.getBudgetRecommendation(userId, category);
});