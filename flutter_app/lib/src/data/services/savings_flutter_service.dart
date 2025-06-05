// File: flutter_app/lib/src/data/services/savings_flutter_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For DateFormat in addManualSaving

import '../../presentation/providers/auth_providers.dart'; // To get current user's UID
import '../models/savings_allocation_model.dart'; 
import '../models/savings_balance_model.dart'; 

class SavingsFlutterService {
  static const String _flaskApiBaseUrl = 'http://10.0.2.2:5000'; // Android Emulator default
  // For iOS Simulator: static const String _flaskApiBaseUrl = 'http://localhost:5000';
  // For Web or physical device on same network: static const String _flaskApiBaseUrl = 'http://YOUR_COMPUTER_IP:5000';
  final Ref _ref;

  SavingsFlutterService(this._ref);

  Future<SavingsBalanceModel> getSavingsBalance() async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception("User not logged in. Cannot fetch savings balance.");
    }
    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/balance').replace(queryParameters: {'userId': currentUser.uid});
    print("SAVINGS_FLUTTER_SERVICE: Fetching savings balance from $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print("SAVINGS_FLUTTER_SERVICE: Balance response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          return SavingsBalanceModel.fromMap(responseData);
        } else {
          throw Exception(responseData['error'] ?? 'Failed to fetch savings balance: Unexpected API response.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print("SAVINGS_FLUTTER_SERVICE: Error fetching balance - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to fetch savings balance: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("SAVINGS_FLUTTER_SERVICE: Exception during getSavingsBalance: $e\n$s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is API server running and accessible?');
      }
      rethrow;
    }
  }

  Future<List<SavingsAllocationModel>> listSavingsAllocations({String? startDate, String? endDate, String? source}) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      print("SAVINGS_FLUTTER_SERVICE: User not logged in for listSavingsAllocations.");
      return [];
    }

    final Map<String, String> queryParams = {'userId': currentUser.uid};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (source != null) queryParams['source'] = source;

    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/allocations').replace(queryParameters: queryParams);
    print("SAVINGS_FLUTTER_SERVICE: Listing savings allocations from $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print("SAVINGS_FLUTTER_SERVICE: Allocations list response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('allocations')) {
          final List<dynamic> allocationsData = responseData['allocations'];
          return allocationsData
              .map((data) => SavingsAllocationModel.fromMap(data as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(responseData['error'] ?? 'Failed to list savings allocations: Unexpected API response.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print("SAVINGS_FLUTTER_SERVICE: Error listing allocations - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to list savings allocations: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("SAVINGS_FLUTTER_SERVICE: Exception during listSavingsAllocations: $e\n$s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is API server running and accessible?');
      }
      rethrow;
    }
  }

  Future<void> addManualSaving({required double amount, required DateTime date}) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception("User not logged in. Cannot add manual saving.");
    }

    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formattedDate = formatter.format(date);

    final Map<String, dynamic> payload = {
      'userId': currentUser.uid, 
      'amount': amount,
      'date': formattedDate,
    };

    final url = Uri.parse('$_flaskApiBaseUrl/api/savings/allocations');
    print("SAVINGS_FLUTTER_SERVICE: Adding manual saving at $url with data: ${jsonEncode(payload)}");
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      print("SAVINGS_FLUTTER_SERVICE: Add manual saving response status: ${response.statusCode}");

      if (response.statusCode == 201) { 
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          print("SAVINGS_FLUTTER_SERVICE: Manual saving added successfully.");
          return;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to add manual saving: Unexpected API response.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print("SAVINGS_FLUTTER_SERVICE: Error adding manual saving - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to add manual saving: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("SAVINGS_FLUTTER_SERVICE: Exception during addManualSaving: $e\n$s");
        if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is API server running?');
      }
      rethrow;
    }
  }
}