// File: lib/src/data/services/budget_flutter_service.dart
import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget_model.dart';
import '../../presentation/providers/auth_providers.dart'; // For currentUserProvider

// API_BASE_URL'i burada sabit olarak tanımlıyoruz, diğer servislerdeki gibi.
const String _flaskApiBaseUrl = 'http://10.0.2.2:5000'; // Android Emulator default
// For iOS Simulator: const String _flaskApiBaseUrl = 'http://localhost:5000';
// For Web or physical device on same network: const String _flaskApiBaseUrl = 'http://YOUR_COMPUTER_IP:5000';


final budgetServiceProvider = Provider<BudgetFlutterService>((ref) {
  // currentUserProvider'ı izleyerek _userId'yi constructor'a geçirelim
  final userId = ref.watch(currentUserProvider.select((user) => user?.uid));
  return BudgetFlutterService(userId);
});

class BudgetFlutterService {
  final String? _userId; // Servis içinde kullanılacak kullanıcı ID'si
  BudgetFlutterService(this._userId);

  Future<List<BudgetModel>> listBudgets(int year, int month) async {
    if (_userId == null) {
      print("BudgetFlutterService: User not logged in, cannot fetch budgets.");
      return []; // Veya bir Exception fırlatılabilir
    }
    final Uri uri = Uri.parse('$_flaskApiBaseUrl/api/budgets?userId=$_userId&year=$year&month=$month');
    print("BudgetFlutterService: Fetching budgets from $uri");

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['budgets'] != null) {
          final List<dynamic> budgetsJson = data['budgets'];
          final budgets = budgetsJson
              .map((jsonItem) => BudgetModel.fromMap(jsonItem as Map<String, dynamic>, jsonItem['id'] as String?))
              .toList();
          print("BudgetFlutterService: Fetched ${budgets.length} budgets.");
          return budgets;
        } else {
          print("BudgetFlutterService: Failed to fetch budgets - API success false or no budgets data: ${data['error']}");
          throw Exception('Failed to fetch budgets: ${data['error'] ?? 'Unknown API error'}');
        }
      } else {
        print("BudgetFlutterService: Failed to fetch budgets - Status Code: ${response.statusCode}, Body: ${response.body}");
        throw Exception('Failed to fetch budgets. Status: ${response.statusCode}');
      }
    } on TimeoutException catch (e, s) {
      print("BudgetFlutterService: Timeout fetching budgets: $e\n$s");
      throw Exception('Network timeout. Please check your connection.');
    } on http.ClientException catch (e, s) {
      print("BudgetFlutterService: ClientException fetching budgets: $e\n$s");
      throw Exception('Network error. Is the API server running and accessible?');
    } catch (e, s) {
      print("BudgetFlutterService: Error fetching budgets: $e\n$s");
      throw Exception('An unknown error occurred while fetching budgets.');
    }
  }

  Future<BudgetModel> createOrUpdateBudget({
    String? budgetId, 
    required String category,
    required double limitAmount,
    required int year,
    required int month,
    String period = 'monthly',
    bool isAuto = false,
  }) async {
    if (_userId == null) {
      throw Exception("User not logged in, cannot create/update budget.");
    }

    final Uri uri = Uri.parse('$_flaskApiBaseUrl/api/budgets'); 
    final Map<String, dynamic> payload = {
      'userId': _userId, // Backend bu userId'yi kullanacak
      'category': category,
      'limitAmount': limitAmount,
      'period': period,
      'year': year,
      'month': month,
      'isAuto': isAuto,
      // Eğer düzenleme ise ve Flask API'si ID'yi payload'da bekliyorsa:
      // if (budgetId != null) 'existingBudgetId': budgetId, // Ya da Flask'taki upsert mantığına göre
    };

    print("BudgetFlutterService: Creating/Updating budget. URL: $uri, Payload: $payload");

    try {
      // Backend'deki POST /api/budgets hem create hem de update (upsert) yapacak şekilde tasarlandı.
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true && responseData['budget'] != null) {
          print("BudgetFlutterService: Budget ${responseData['budget']['id']} created/updated successfully.");
          return BudgetModel.fromMap(responseData['budget'] as Map<String, dynamic>, responseData['budget']['id'] as String?);
        } else {
          print("BudgetFlutterService: Create/Update budget failed - API success false: ${responseData['error']}");
          throw Exception('Failed to create/update budget: ${responseData['error'] ?? 'Unknown API error'}');
        }
      } else {
        print("BudgetFlutterService: Create/Update budget failed - Status: ${response.statusCode}, Body: ${response.body}");
        throw Exception('Failed to create/update budget. Status: ${response.statusCode}');
      }
    } on TimeoutException catch (e, s) {
      print("BudgetFlutterService: Timeout creating/updating budget: $e\n$s");
      throw Exception('Network timeout. Please check your connection.');
    } on http.ClientException catch (e, s) {
      print("BudgetFlutterService: ClientException creating/updating budget: $e\n$s");
      throw Exception('Network error. Is the API server running and accessible?');
    } catch (e,s) {
      print("BudgetFlutterService: Error creating/updating budget: $e\n$s");
      throw Exception('An unknown error occurred while saving the budget.');
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    if (_userId == null) {
      throw Exception("User not logged in, cannot delete budget.");
    }
    final Uri uri = Uri.parse('$_flaskApiBaseUrl/api/budgets/$budgetId?userId=$_userId');
    print("BudgetFlutterService: Deleting budget $budgetId. URL: $uri");

    try {
      final response = await http.delete(uri).timeout(const Duration(seconds: 10));
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
         if (responseData['success'] == true) {
            print("BudgetFlutterService: Budget $budgetId deleted successfully.");
            return;
         } else {
            print("BudgetFlutterService: Delete budget failed - API success false: ${responseData['error']}");
            throw Exception('Failed to delete budget: ${responseData['error'] ?? 'Unknown API error'}');
         }
      } else {
        print("BudgetFlutterService: Delete budget failed - Status: ${response.statusCode}, Body: ${response.body}");
        throw Exception('Failed to delete budget. Status: ${response.statusCode}');
      }
    } on TimeoutException catch (e, s) {
      print("BudgetFlutterService: Timeout deleting budget: $e\n$s");
      throw Exception('Network timeout. Please check your connection.');
    } on http.ClientException catch (e, s) {
      print("BudgetFlutterService: ClientException deleting budget: $e\n$s");
      throw Exception('Network error. Is the API server running and accessible?');
    } catch (e,s) {
      print("BudgetFlutterService: Error deleting budget $budgetId: $e\n$s");
      throw Exception('An unknown error occurred while deleting the budget.');
    }
  }
}
