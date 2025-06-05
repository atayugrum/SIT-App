// File: lib/src/data/services/analytics_flutter_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 

import '../../presentation/providers/auth_providers.dart'; 
import '../models/analytics_models.dart'; 

const String _flaskApiBaseUrl = 'http://10.0.2.2:5000'; 


final analyticsServiceProvider = Provider<AnalyticsFlutterService>((ref) {
  final userId = ref.watch(currentUserProvider.select((user) => user?.uid));
  return AnalyticsFlutterService(userId);
});

class AnalyticsFlutterService {
  final String? _userId;
  AnalyticsFlutterService(this._userId);

  Future<T> _handleResponse<T>(http.Response response, String dataKey, T Function(Map<String, dynamic> data) parser, {String? alternativeDataKey1, String? alternativeDataKey2}) async {
    print("AnalyticsFlutterService: Response Status ${response.statusCode} for ${response.request?.url}");
    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      if (responseData['success'] == true) {
        if (responseData.containsKey(dataKey) && responseData[dataKey] != null) {
          if (responseData[dataKey] is Map<String, dynamic>) { return parser(responseData[dataKey] as Map<String, dynamic>); }
          else { return parser(responseData); }
        } else if (alternativeDataKey1 != null && responseData.containsKey(alternativeDataKey1) && responseData[alternativeDataKey1] != null && alternativeDataKey2 != null && responseData.containsKey(alternativeDataKey2) && responseData[alternativeDataKey2] != null) {
           return parser(responseData); 
        } else {
          print("AnalyticsFlutterService: API success true, but data key '$dataKey' (or alternatives) missing or null. Response: $responseData");
          throw Exception('Failed to parse data from API: Data key missing or null.');
        }
      } else {
        print("AnalyticsFlutterService: API success false. Error: ${responseData['error']}");
        throw Exception('Failed to load data from API: ${responseData['error'] ?? 'Unexpected API response format.'}');
      }
    } else {
      print("AnalyticsFlutterService: API Error - Status: ${response.statusCode}, Body: ${response.body}");
      throw Exception('Failed to load data from API: ${responseData['error'] ?? response.reasonPhrase}');
    }
  }

  Future<MonthlyExpenseSummaryModel> getMonthlyExpenseSummary(int year, int month) async {
    if (_userId == null) throw Exception("User not logged in.");
    final uri = Uri.parse('$_flaskApiBaseUrl/api/insights/monthly-expense-summary').replace(queryParameters: { 'userId': _userId, 'year': year.toString(), 'month': month.toString(),});
    try { final response = await http.get(uri).timeout(const Duration(seconds: 15)); return _handleResponse(response, 'summary', MonthlyExpenseSummaryModel.fromMap);
    } catch (e,s) { print("AnalyticsFlutterService Exception in getMonthlyExpenseSummary: $e\n$s"); rethrow; }
  }
  Future<IncomeExpenseAnalysisModel> getIncomeExpenseAnalysis(int year, int month) async {
    if (_userId == null) throw Exception("User not logged in.");
    final uri = Uri.parse('$_flaskApiBaseUrl/api/insights/income-expense-analysis').replace(queryParameters: { 'userId': _userId, 'year': year.toString(), 'month': month.toString(),});
    try { final response = await http.get(uri).timeout(const Duration(seconds: 15)); return _handleResponse(response, 'analysis', IncomeExpenseAnalysisModel.fromMap);
    } catch (e,s) { print("AnalyticsFlutterService Exception in getIncomeExpenseAnalysis: $e\n$s"); rethrow;}
  }
  Future<SpendingTrendModel> getSpendingTrend({String period = "6m"}) async {
    if (_userId == null) throw Exception("User not logged in.");
    final uri = Uri.parse('$_flaskApiBaseUrl/api/insights/trend').replace(queryParameters: { 'userId': _userId, 'period': period,});
    try { final response = await http.get(uri).timeout(const Duration(seconds: 15)); return _handleResponse(response, 'trend', SpendingTrendModel.fromMap);
    } catch (e,s) { print("AnalyticsFlutterService Exception in getSpendingTrend: $e\n$s"); rethrow;}
  }
  Future<CategoryTrendDataModel> getCategoryTrendData({required DateTime startDate, required DateTime endDate}) async {
    if (_userId == null) throw Exception("User not logged in.");
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final uri = Uri.parse('$_flaskApiBaseUrl/api/insights/category-trend').replace(queryParameters: { 'userId': _userId, 'startDate': formatter.format(startDate), 'endDate': formatter.format(endDate),});
    try { final response = await http.get(uri).timeout(const Duration(seconds: 20)); return _handleResponse(response, 'data', CategoryTrendDataModel.fromMap, alternativeDataKey1: 'labels', alternativeDataKey2: 'data'); 
    } catch (e,s) { print("AnalyticsFlutterService Exception in getCategoryTrendData: $e\n$s"); rethrow;}
  }
  Future<DashboardInsightsModel> getDashboardInsights() async {
    if (_userId == null) throw Exception("User not logged in.");
    final uri = Uri.parse('$_flaskApiBaseUrl/api/insights/dashboard').replace(queryParameters: {'userId': _userId,});
    try { final response = await http.get(uri).timeout(const Duration(seconds: 25)); return _handleResponse(response, 'dashboard', DashboardInsightsModel.fromMap);
    } catch (e,s) { print("AnalyticsFlutterService Exception in getDashboardInsights: $e\n$s"); rethrow;}
  }
}