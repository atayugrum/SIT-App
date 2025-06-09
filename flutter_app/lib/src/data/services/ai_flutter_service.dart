// File: lib/src/data/services/ai_flutter_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/budget_suggestion_model.dart';
import '../models/parsed_transaction_model.dart';

class AIFlutterService {
  final String _baseUrl = 'http://10.0.2.2:5000';

  // Bütçe önerisi alma metodu
  Future<BudgetSuggestion> getBudgetRecommendation(String userId, String category) async {
    final uri = Uri.parse('$_baseUrl/api/ai/recommendations/budget')
        .replace(queryParameters: {'userId': userId, 'category': category});

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return BudgetSuggestion.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Bütçe önerisi alınamadı.');
      }
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }

  // Metinden işlem ayrıştırma metodu
  Future<List<ParsedTransactionModel>> parseTransactionText(String text) async {
    final url = Uri.parse('$_baseUrl/api/ai/parse-text');
    final payload = jsonEncode({'text': text});

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('parsedTransactions')) {
          final List<dynamic> txData = data['parsedTransactions'];
          return txData.map((d) => ParsedTransactionModel.fromMap(d)).toList();
        } else {
          throw Exception(data['error'] ?? 'Metin ayrıştırılamadı.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Metin ayrıştırma hatası: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }
}