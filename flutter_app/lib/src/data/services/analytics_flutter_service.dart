// File: lib/src/data/services/analytics_flutter_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_models.dart';
import '../../presentation/providers/auth_providers.dart';

class AnalyticsFlutterService {
  final Ref _ref;
  static const String _baseUrl = 'http://10.0.2.2:5000';

  AnalyticsFlutterService(this._ref);

  Future<DashboardInsightsModel> getDashboardInsights() async {
    final userId = _ref.read(userIdProvider);
    if (userId == null) throw Exception("User not logged in");

    final url = Uri.parse('$_baseUrl/api/analytics/dashboard?userId=$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['dashboard'] != null) {
        return DashboardInsightsModel.fromMap(data['dashboard']);
      } else {
        throw Exception(data['error'] ?? 'Failed to load dashboard insights');
      }
    } else {
      throw Exception('Failed to load dashboard insights with status code: ${response.statusCode}');
    }
  }
}