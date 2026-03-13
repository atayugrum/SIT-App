// File: lib/src/data/services/savings_flutter_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../../presentation/providers/auth_providers.dart';
import '../models/savings_allocation_model.dart';
import '../models/savings_balance_model.dart';
import '../models/savings_goal_model.dart';

class SavingsFlutterService {
  static const String _flaskApiBaseUrl = 'https://sit-app-production.up.railway.app';
  final Ref _ref;
  final _logger = Logger();

  SavingsFlutterService(this._ref);

  String? get _userId => _ref.read(currentUserProvider)?.uid;

  void _handleErrorResponse(http.Response response, String context) {
    try {
      Map<String, dynamic> errorData = {};
        try { errorData = jsonDecode(response.body); } catch (_) { errorData = {"error": response.body}; }
      _logger.e("Error in $context - ${response.statusCode}", error: response.body);
      throw Exception('Failed to $context: ${errorData['error'] ?? response.reasonPhrase}');
    } catch(e) {
       _logger.e("Error in $context, could not parse error body - ${response.statusCode}", error: response.body);
       throw Exception('Failed to $context: Server error.');
    }
  }

  Future<SavingsBalanceModel> getSavingsBalance() async {
    if (_userId == null) {
      _logger.w("User not logged in. Cannot fetch savings balance.");
      throw Exception("User not logged in.");
    }
    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/balance').replace(queryParameters: {'userId': _userId});
    _logger.i("Fetching savings balance from $url");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          _logger.i("Savings balance fetched successfully.");
          return SavingsBalanceModel.fromMap(responseData);
        } else {
          _logger.e("API success but format error in getSavingsBalance", error: responseData['error']);
          throw Exception(responseData['error'] ?? 'Failed to fetch savings balance.');
        }
      } else {
        _handleErrorResponse(response, 'fetch savings balance');
        throw Exception("Server error while fetching balance."); // Fallback
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on getSavingsBalance', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on getSavingsBalance', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e("Exception during getSavingsBalance", error: e, stackTrace: s);
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
    _logger.i("Listing savings allocations from: $url");
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('allocations')) {
          final List<dynamic> allocationsData = responseData['allocations'];
          return allocationsData.map((data) => SavingsAllocationModel.fromMap(data as Map<String, dynamic>)).toList();
        } else {
           _logger.w("Failed to list allocations, success=false", error: responseData['error']);
          throw Exception(responseData['error'] ?? 'Failed to list allocations.');
        }
      } else {
        _handleErrorResponse(response, 'list allocations');
        return []; // Should not be reached
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on listSavingsAllocations', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on listSavingsAllocations', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addManualSaving({required double amount, required DateTime date}) async {
    if (_userId == null) throw Exception("User not logged in.");

    final payload = {
      'userId': _userId, 'amount': amount, 'date': DateFormat('yyyy-MM-dd').format(date),
    };

    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/allocations');
    _logger.i("Adding manual saving...");

    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload)).timeout(const Duration(seconds: 60));
      if (response.statusCode != 201) {
        _handleErrorResponse(response, 'add manual saving');
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on addManualSaving', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on addManualSaving', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SavingsGoalModel>> listGoals() async {
    if (_userId == null) throw Exception("User not logged in.");
    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/goals').replace(queryParameters: {'userId': _userId});
    _logger.i("Listing savings goals from $url");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> goalsData = data['goals'];
          return goalsData.map((d) => SavingsGoalModel.fromMap(d)).toList();
        } else {
          _logger.w("Failed to list goals, success=false", error: data['error']);
          throw Exception(data['error'] ?? 'Failed to list goals.');
        }
      } else {
        _handleErrorResponse(response, 'list goals');
        return [];
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on listGoals', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on listGoals', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch(e) { rethrow; }
  }

  Future<SavingsGoalModel> createGoal({required String title, required double targetAmount, required DateTime targetDate}) async {
    if (_userId == null) throw Exception("User not logged in.");
    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/goals');
    final payload = jsonEncode({
      'userId': _userId, 'title': title, 'targetAmount': targetAmount,
      'targetDate': DateFormat('yyyy-MM-dd').format(targetDate),
    });
    
    _logger.i("Creating new savings goal...");
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: payload).timeout(const Duration(seconds: 60));
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SavingsGoalModel.fromMap(data['goal']);
      } else {
        _handleErrorResponse(response, 'create goal');
        throw Exception('Failed to create goal.'); // Fallback
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on createGoal', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on createGoal', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch(e) { rethrow; }
  }

  Future<void> deleteGoal(String goalId) async {
    if (_userId == null) throw Exception("User not logged in.");
    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/goals/$goalId').replace(queryParameters: {'userId': _userId});
    _logger.i("Deleting savings goal $goalId");
    
    try {
      final response = await http.delete(url).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        _handleErrorResponse(response, 'delete goal');
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on deleteGoal', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on deleteGoal', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch(e) { rethrow; }
  }

  Future<void> allocateToGoal({required String goalId, required double amount}) async {
    if (_userId == null) throw Exception("User not logged in.");
    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/goals/$goalId/allocate');
    final payload = jsonEncode({'userId': _userId, 'amount': amount});
    _logger.i("Allocating $amount to goal $goalId");

    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: payload).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        _handleErrorResponse(response, 'allocate funds to goal');
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on allocateToGoal', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on allocateToGoal', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch(e) { rethrow; }
  }
}