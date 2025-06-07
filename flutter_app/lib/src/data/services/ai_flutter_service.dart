// lib/src/data/services/ai_flutter_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/budget_suggestion_model.dart';

class AIFlutterService {
  final String _baseUrl = 'http://10.0.2.2:5000'; // TODO: Burayı kendi backend adresinizle değiştirin

  Future<BudgetSuggestion> getBudgetRecommendation(String userId, String category) async {
    final uri = Uri.parse('$_baseUrl/api/ai/recommendations/budget')
        .replace(queryParameters: {'userId': userId, 'category': category});

    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BudgetSuggestion.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Bütçe önerisi alınamadı.');
      }
    } catch (e) {
      // Network hatası veya diğer hatalar
      throw Exception('Bir hata oluştu: $e');
    }
  }
}