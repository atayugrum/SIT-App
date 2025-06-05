// File: flutter_app/lib/src/data/services/account_flutter_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/account_model.dart';
import '../../presentation/providers/auth_providers.dart'; // To get current user
import 'package:flutter_riverpod/flutter_riverpod.dart'; // For Ref

class AccountFlutterService {
  static const String _flaskApiBaseUrl = 'http://10.0.2.2:5000'; // Android Emulator
  // For iOS Simulator: static const String _flaskApiBaseUrl = 'http://localhost:5000';
  // For Web/Physical Device: static const String _flaskApiBaseUrl = 'http://YOUR_COMPUTER_IP:5000';
  final Ref _ref;

  AccountFlutterService(this._ref);

  Future<AccountModel> createAccount(AccountModel account) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception("User not logged in. Cannot create account.");
    }
    
    // Ensure userId is included in the map sent to backend
    final Map<String, dynamic> accountDataForApi = account.toMap()
        ..['userId'] = currentUser.uid;

    final url = Uri.parse('$_flaskApiBaseUrl/api/accounts');
    print("ACCOUNT_FLUTTER_SERVICE: Creating account at $url with data: ${jsonEncode(accountDataForApi)}");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(accountDataForApi),
      ).timeout(const Duration(seconds: 10));

      print("ACCOUNT_FLUTTER_SERVICE: Create response status: ${response.statusCode}");

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('account')) {
          print("ACCOUNT_FLUTTER_SERVICE: Account created: ${responseData['account']}");
          return AccountModel.fromMap(responseData['account'] as Map<String, dynamic>);
        } else {
          throw Exception(responseData['error'] ?? 'Failed to create account: Unexpected API response format.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print("ACCOUNT_FLUTTER_SERVICE: Error creating account - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to create account: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("ACCOUNT_FLUTTER_SERVICE: Exception during createAccount: $e");
      print("ACCOUNT_FLUTTER_SERVICE: StackTrace: $s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is your Flask API server running and accessible?');
      }
      throw Exception('Failed to create account: $e');
    }
  }

  Future<List<AccountModel>> listAccounts() async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      print("ACCOUNT_FLUTTER_SERVICE: User not logged in. Cannot list accounts.");
      return [];
    }

    final url = Uri.parse('$_flaskApiBaseUrl/api/accounts').replace(queryParameters: {'userId': currentUser.uid});
    print("ACCOUNT_FLUTTER_SERVICE: Listing accounts from $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print("ACCOUNT_FLUTTER_SERVICE: List response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('accounts')) {
          final List<dynamic> accountsData = responseData['accounts'];
          final accounts = accountsData
              .map((data) => AccountModel.fromMap(data as Map<String, dynamic>))
              .toList();
          print("ACCOUNT_FLUTTER_SERVICE: Fetched ${accounts.length} accounts.");
          return accounts;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to list accounts: Unexpected API response format.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print("ACCOUNT_FLUTTER_SERVICE: Error listing accounts - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to list accounts: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("ACCOUNT_FLUTTER_SERVICE: Exception during listAccounts: $e");
      print("ACCOUNT_FLUTTER_SERVICE: StackTrace: $s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is your Flask API server running and accessible?');
      }
      throw Exception('Failed to list accounts: $e');
    }
  }
}