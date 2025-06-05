// File: flutter_app/lib/src/data/services/transaction_flutter_service.dart
import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart'; // Not directly used here, but TransactionModel might use it
import '../models/transaction_model.dart';
import '../../presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionFlutterService {
  static const String _flaskApiBaseUrl = 'http://10.0.2.2:5000'; // Android Emulator default
  // For iOS Simulator: static const String _flaskApiBaseUrl = 'http://localhost:5000';
  // For Web or physical device on same network: static const String _flaskApiBaseUrl = 'http://YOUR_COMPUTER_IP:5000';
  final Ref _ref;

  TransactionFlutterService(this._ref);

  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception("User not logged in. Cannot create transaction.");
    }
    final Map<String, dynamic> transactionData = transaction.toMap()..['userId'] = currentUser.uid;
    
    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions');
    print("TRANSACTION_FLUTTER_SERVICE: Creating transaction at $url with data: ${jsonEncode(transactionData)}");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transactionData),
      ).timeout(const Duration(seconds: 10));

      print("TRANSACTION_FLUTTER_SERVICE: Create response status: ${response.statusCode}");

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('transaction')) {
          print("TRANSACTION_FLUTTER_SERVICE: Transaction created: ${responseData['transaction']}");
          return TransactionModel.fromMap(responseData['transaction'] as Map<String, dynamic>);
        } else {
          throw Exception(responseData['error'] ?? 'Failed to create transaction: Unexpected API response format.');
        }
      } else {
         final errorData = jsonDecode(response.body);
        print("TRANSACTION_FLUTTER_SERVICE: Error creating - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to create transaction: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("TRANSACTION_FLUTTER_SERVICE: Exception during createTransaction: $e\n$s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is your Flask API server running and accessible?');
      }
      rethrow; 
    }
  }

  Future<List<TransactionModel>> listTransactions({
    String? startDate, 
    String? endDate,   
    String? type,
    String? accountName, // <-- accountName parametresi burada
  }) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      print("TRANSACTION_FLUTTER_SERVICE: User not logged in for listTransactions.");
      return [];
    }

    final Map<String, String> queryParams = {'userId': currentUser.uid};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (type != null) queryParams['type'] = type;
    if (accountName != null) queryParams['account'] = accountName; // <-- query'ye ekle

    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions').replace(queryParameters: queryParams);
    print("TRANSACTION_FLUTTER_SERVICE: Listing transactions from $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print("TRANSACTION_FLUTTER_SERVICE: List response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('transactions')) {
          final List<dynamic> transactionsData = responseData['transactions'];
          final transactions = transactionsData
              .map((data) => TransactionModel.fromMap(data as Map<String, dynamic>))
              .toList();
          print("TRANSACTION_FLUTTER_SERVICE: Fetched ${transactions.length} transactions.");
          return transactions;
        } else {
           throw Exception(responseData['error'] ?? 'Failed to list transactions: Unexpected API response format.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print("TRANSACTION_FLUTTER_SERVICE: Error listing - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to list transactions: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("TRANSACTION_FLUTTER_SERVICE: Exception during listTransactions: $e\n$s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is your Flask API server running and accessible?');
      }
      rethrow;
    }
  }

  Future<TransactionModel> updateTransaction(String transactionId, TransactionModel transaction) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception("User not logged in. Cannot update transaction.");
    }
    final Map<String, dynamic> transactionData = transaction.toMap()..['userId'] = currentUser.uid;
    
    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions/$transactionId');
    print("TRANSACTION_FLUTTER_SERVICE: Updating transaction $transactionId at $url with data: ${jsonEncode(transactionData)}");

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transactionData),
      ).timeout(const Duration(seconds: 10));

      print("TRANSACTION_FLUTTER_SERVICE: Update response status: ${response.statusCode}");

      if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('transaction')) {
          print("TRANSACTION_FLUTTER_SERVICE: Transaction updated: ${responseData['transaction']}");
          return TransactionModel.fromMap(responseData['transaction'] as Map<String, dynamic>);
        } else {
          throw Exception(responseData['error'] ?? 'Failed to update transaction: Unexpected API response.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print("TRANSACTION_FLUTTER_SERVICE: Error updating - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to update transaction: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("TRANSACTION_FLUTTER_SERVICE: Exception during updateTransaction: $e\n$s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is API server running?');
      }
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception("User not logged in. Cannot delete transaction.");
    }
    
    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions/$transactionId').replace(queryParameters: {'userId': currentUser.uid});
    print("TRANSACTION_FLUTTER_SERVICE: Deleting transaction $transactionId at $url");

    try {
      final response = await http.delete(url).timeout(const Duration(seconds: 10));
      print("TRANSACTION_FLUTTER_SERVICE: Delete response status: ${response.statusCode}");

      if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          print("TRANSACTION_FLUTTER_SERVICE: Transaction $transactionId deleted successfully.");
          return; 
        } else {
          throw Exception(responseData['error'] ?? 'Failed to delete transaction: Unexpected API response.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print("TRANSACTION_FLUTTER_SERVICE: Error deleting - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to delete transaction: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("TRANSACTION_FLUTTER_SERVICE: Exception during deleteTransaction: $e\n$s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is API server running?');
      }
      rethrow;
    }
  }
}