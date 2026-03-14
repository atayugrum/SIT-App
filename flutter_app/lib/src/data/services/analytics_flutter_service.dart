// File: lib/src/data/services/analytics_flutter_service.dart
import 'dart:convert';
import '../../core/network/api_constants.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/analytics_models.dart';
import '../../presentation/providers/auth_providers.dart';

class AnalyticsFlutterService {
  final Ref _ref;
  final _logger = Logger();

  AnalyticsFlutterService(this._ref);

  String? get _userId => _ref.read(userIdProvider);

  /// Fetches both historical analytics and AI projections in a single request.
  Future<({DashboardInsightsModel historical, AIProjectionsModel aiProjections})>
      getV2Analytics() async {
    if (_userId == null) throw Exception("User not logged in");

    final url = Uri.parse('${ApiConstants.baseUrl}/api/analytics/v2/dashboard?userId=$_userId');
    _logger.i("Getting v2 analytics...");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final historical = DashboardInsightsModel.fromMap(
              data['data']['historical'] as Map<String, dynamic>? ?? {});
          final aiProjections = AIProjectionsModel.fromMap(
              data['data']['aiProjections'] as Map<String, dynamic>? ?? {});
          return (historical: historical, aiProjections: aiProjections);
        } else {
          throw Exception(data['error'] ?? 'Analitik veriler alınamadı');
        }
      } else {
        _logger.e("Error getting v2 analytics - ${response.statusCode}", error: response.body);
        throw Exception('Analitik veriler alınamadı: Hata Kodu ${response.statusCode}');
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on getV2Analytics', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on getV2Analytics', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on getV2Analytics', error: e, stackTrace: s);
      throw Exception('Analitik veriler alınırken bir hata oluştu.');
    }
  }

  Future<CategoryComparisonModel> getCategoryComparison(String category) async {
    if (_userId == null) throw Exception("User not logged in");

    final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/analytics/category-comparison?userId=$_userId&category=${Uri.encodeComponent(category)}');
    _logger.i("Getting category comparison for $category...");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return CategoryComparisonModel.fromMap(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Kategori karşılaştırması alınamadı');
        }
      } else {
        _logger.e("Error getting category comparison - ${response.statusCode}", error: response.body);
        throw Exception('Kategori karşılaştırması alınamadı: Hata Kodu ${response.statusCode}');
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on getCategoryComparison', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on getCategoryComparison', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı.');
    } catch (e, s) {
      _logger.e('Generic Error on getCategoryComparison', error: e, stackTrace: s);
      throw Exception('Kategori karşılaştırması alınırken bir hata oluştu.');
    }
  }
}
