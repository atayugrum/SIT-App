// File: lib/src/data/services/analytics_flutter_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/analytics_models.dart';
import '../../presentation/providers/auth_providers.dart';

class AnalyticsFlutterService {
  final Ref _ref;
  static const String _baseUrl = 'http://10.0.2.2:5000';
  final _logger = Logger();

  AnalyticsFlutterService(this._ref);

  String? get _userId => _ref.read(userIdProvider);

  Future<DashboardInsightsModel> getDashboardInsights() async {
    if (_userId == null) throw Exception("User not logged in");

    final url = Uri.parse('$_baseUrl/api/analytics/dashboard?userId=$_userId');
    _logger.i("Getting dashboard insights...");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['dashboard'] != null) {
          _logger.d("Dashboard data received: ${data['dashboard']}");
          return DashboardInsightsModel.fromMap(data['dashboard']);
        } else {
          _logger.w("Failed to get dashboard insights, success=false", error: data['error']);
          throw Exception(data['error'] ?? 'Failed to load dashboard insights');
        }
      } else {
        _logger.e("Error getting dashboard - ${response.statusCode}", error: jsonDecode(response.body));
        throw Exception('Failed to load dashboard insights with status code: ${response.statusCode}');
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on getDashboardInsights', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on getDashboardInsights', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on getDashboardInsights', error: e, stackTrace: s);
      throw Exception('Genel bakış verileri alınırken bir hata oluştu.');
    }
  }

  Future<AIProjectionsModel> getAIProjections() async {
    if (_userId == null) throw Exception("User not logged in");
    
    final url = Uri.parse('$_baseUrl/api/analytics/projections?userId=$_userId');
    _logger.i("Getting AI projections...");
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['projections'] != null) {
          return AIProjectionsModel.fromMap(data['projections']);
        } else {
          _logger.w("Failed to get AI projections, success=false", error: data['error']);
          throw Exception(data['error'] ?? 'AI analizi alınamadı.');
        }
      } else {
        _logger.e("Error getting AI projections - ${response.statusCode}", error: jsonDecode(response.body));
        throw Exception('AI analizi alınamadı: Hata Kodu ${response.statusCode}');
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on getAIProjections', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on getAIProjections', error: e, stackTrace: s);
      throw Exception('AI analiz servisine bağlanılamadı, lütfen tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on getAIProjections', error: e, stackTrace: s);
      throw Exception('AI analizi alınırken bir hata oluştu.');
    }
  }
}