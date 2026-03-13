// File: lib/src/data/services/ai_flutter_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/budget_suggestion_model.dart';
import '../models/parsed_transaction_model.dart';

class AIFlutterService {
  static const String _baseUrl = 'https://sit-app-backend.onrender.com';
  final _logger = Logger();

  Future<BudgetSuggestion> getBudgetRecommendation(String userId, String category) async {
    final uri = Uri.parse('$_baseUrl/api/ai/recommendations/budget')
        .replace(queryParameters: {'userId': userId, 'category': category});
    _logger.i("Getting budget recommendation for category: $category");

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        return BudgetSuggestion.fromJson(json.decode(response.body));
      } else {
        Map<String, dynamic> errorData = {};
        try { errorData = json.decode(response.body); } catch (_) { errorData = {"error": response.body}; }
        _logger.e("Error getting budget recommendation - ${response.statusCode}", error: errorData);
        throw Exception(errorData['error'] ?? 'Bütçe önerisi alınamadı.');
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on getBudgetRecommendation', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on getBudgetRecommendation', error: e, stackTrace: s);
      throw Exception('AI servisinden yanıt alınamadı, lütfen tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on getBudgetRecommendation', error: e, stackTrace: s);
      throw Exception('Bütçe önerisi alınırken beklenmedik bir hata oluştu.');
    }
  }

  Future<List<ParsedTransactionModel>> parseTransactionText(String text) async {
    final url = Uri.parse('$_baseUrl/api/ai/parse-text');
    final payload = jsonEncode({'text': text});
    _logger.i("Parsing transaction text...");

    try {
      final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('parsedTransactions')) {
          final List<dynamic> txData = data['parsedTransactions'];
          _logger.i("Parsed ${txData.length} transactions from text.");
          return txData.map((d) => ParsedTransactionModel.fromMap(d)).toList();
        } else {
          _logger.w("Failed to parse text, API returned success=false", error: data['error']);
          throw Exception(data['error'] ?? 'Metin ayrıştırılamadı.');
        }
      } else {
        Map<String, dynamic> errorData = {};
        try { errorData = jsonDecode(response.body); } catch (_) { errorData = {"error": response.body}; }
        _logger.e("Error parsing text - ${response.statusCode}", error: errorData);
        throw Exception('Metin ayrıştırma hatası: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on parseTransactionText', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on parseTransactionText', error: e, stackTrace: s);
      throw Exception('AI servisinden yanıt alınamadı, lütfen tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on parseTransactionText', error: e, stackTrace: s);
      throw Exception('Metin ayrıştırılırken beklenmedik bir hata oluştu.');
    }
  }
}