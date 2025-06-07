// File: lib/src/data/services/savings_flutter_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 

import '../../presentation/providers/auth_providers.dart'; 
import '../models/savings_allocation_model.dart'; 
import '../models/savings_balance_model.dart'; 
import '../models/savings_goal_model.dart';

class SavingsFlutterService {
  // Geliştirme ortamınıza göre bu adresi değiştirmeyi unutmayın
  static const String _flaskApiBaseUrl = 'http://10.0.2.2:5000'; // Android Emulator
  final Ref _ref;

  SavingsFlutterService(this._ref);

  // Anlık olarak kullanıcı ID'sini alan yardımcı getter
  String? get _userId => _ref.read(currentUserProvider)?.uid;

  // Tekrarlanan hata yönetimini basitleştiren yardımcı fonksiyon
  void _handleErrorResponse(http.Response response, String context) {
    final errorData = jsonDecode(response.body);
    print("SAVINGS_FLUTTER_SERVICE: Error in $context - ${response.statusCode}: ${response.body}");
    throw Exception('Failed to $context: ${errorData['error'] ?? response.reasonPhrase}');
  }

  Future<SavingsBalanceModel> getSavingsBalance() async {
    if (_userId == null) throw Exception("User not logged in. Cannot fetch savings balance.");

    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/balance').replace(queryParameters: {'userId': _userId});
    print("SAVINGS_FLUTTER_SERVICE: Fetching savings balance from $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          return SavingsBalanceModel.fromMap(responseData);
        } else {
          throw Exception(responseData['error'] ?? 'Failed to fetch savings balance.');
        }
      } else {
        _handleErrorResponse(response, 'fetch savings balance');
        throw Exception("Server error while fetching balance."); // Fallback
      }
    } catch (e) {
      print("SAVINGS_FLUTTER_SERVICE: Exception during getSavingsBalance: $e");
      rethrow;
    }
  }

  Future<List<SavingsAllocationModel>> listSavingsAllocations({String? startDate, String? endDate, String? source}) async {
    if (_userId == null) return [];

    final Map<String, String> queryParams = {'userId': _userId!};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (source != null) queryParams['source'] = source;

    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/allocations').replace(queryParameters: queryParams);
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('allocations')) {
          final List<dynamic> allocationsData = responseData['allocations'];
          return allocationsData
              .map((data) => SavingsAllocationModel.fromMap(data as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(responseData['error'] ?? 'Failed to list allocations.');
        }
      } else {
        _handleErrorResponse(response, 'list allocations');
        return []; // Fallback
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addManualSaving({required double amount, required DateTime date}) async {
    if (_userId == null) throw Exception("User not logged in.");

    final payload = {
      'userId': _userId, 
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(date),
    };

    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/allocations');
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
      if (response.statusCode != 201) {
        _handleErrorResponse(response, 'add manual saving');
      }
    } catch (e) {
      rethrow;
    }
  }

  // === YENİ HEDEF METOTLARI ===

  Future<List<SavingsGoalModel>> listGoals() async {
    if (_userId == null) throw Exception("User not logged in.");
    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/goals').replace(queryParameters: {'userId': _userId});
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> goalsData = data['goals'];
          return goalsData.map((d) => SavingsGoalModel.fromMap(d)).toList();
        } else {
          throw Exception(data['error'] ?? 'Failed to list goals.');
        }
      } else {
        _handleErrorResponse(response, 'list goals');
        return [];
      }
    } catch(e) { rethrow; }
  }

  Future<SavingsGoalModel> createGoal({required String title, required double targetAmount, required DateTime targetDate}) async {
    if (_userId == null) throw Exception("User not logged in.");
    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/goals');
    final payload = jsonEncode({
      'userId': _userId,
      'title': title,
      'targetAmount': targetAmount,
      'targetDate': DateFormat('yyyy-MM-dd').format(targetDate),
    });
    
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: payload);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SavingsGoalModel.fromMap(data['goal']);
      } else {
        _handleErrorResponse(response, 'create goal');
        throw Exception('Failed to create goal.');
      }
    } catch(e) { rethrow; }
  }

  Future<void> deleteGoal(String goalId) async {
    if (_userId == null) throw Exception("User not logged in.");
    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/goals/$goalId').replace(queryParameters: {'userId': _userId});
    
    try {
      final response = await http.delete(url);
      if (response.statusCode != 200) {
        _handleErrorResponse(response, 'delete goal');
      }
    } catch(e) { rethrow; }
  }

  Future<void> allocateToGoal({required String goalId, required double amount}) async {
    if (_userId == null) throw Exception("User not logged in.");
    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/goals/$goalId/allocate');
    final payload = jsonEncode({'userId': _userId, 'amount': amount});

    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: payload);
      if (response.statusCode != 200) {
        _handleErrorResponse(response, 'allocate funds to goal');
      }
    } catch(e) { rethrow; }
  }
}