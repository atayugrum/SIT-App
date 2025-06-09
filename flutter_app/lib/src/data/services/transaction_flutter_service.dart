// File: lib/src/data/services/transaction_flutter_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../models/transaction_model.dart';

const String _flaskApiBaseUrl = 'http://10.0.2.2:5000'; 

// DÜZELTME: Provider tanımı buradan kaldırıldı. Artık transaction_providers.dart dosyasında.

class TransactionFlutterService {
  final String? _userId;
  TransactionFlutterService(this._userId);

  Future<List<TransactionModel>> listTransactions({
    required String startDate,
    required String endDate,
    String? type,
    String? account,
  }) async {
    if (_userId == null) {
      return [];
    }

    final Map<String, String> queryParams = {
      'userId': _userId,
      'startDate': startDate,
      'endDate': endDate,
    };
    if (type != null) queryParams['type'] = type;
    if (account != null) queryParams['account'] = account;

    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true && responseData['transactions'] != null) {
          final List<dynamic> transactionsJson = responseData['transactions'];
          return transactionsJson
              .map((json) => TransactionModel.fromMap(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Failed to list transactions: ${responseData['error'] ?? 'Unknown API error'}');
        }
      } else {
        throw Exception('Failed to list transactions: ${responseData['error'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Network error or server issue while listing transactions.');
    }
  }

  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transaction.toMap()),
      );
      final responseData = json.decode(response.body);
      if (response.statusCode == 201) {
        if (responseData['success'] == true && responseData['transaction'] != null) {
          return TransactionModel.fromMap(responseData['transaction'] as Map<String, dynamic>);
        } else {
          throw Exception(responseData['error'] ?? 'Failed to create transaction: Unexpected API response format.');
        }
      } else {
        throw Exception('Failed to create transaction: ${responseData['error'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<TransactionModel> updateTransaction(String id, TransactionModel transaction) async {
    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions/$id');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transaction.toMapForUpdate()),
      );
       final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseData['success'] == true && responseData['transaction'] != null) {
          return TransactionModel.fromMap(responseData['transaction'] as Map<String, dynamic>);
        } else {
          throw Exception(responseData['error'] ?? 'Failed to update transaction: Unexpected API response format.');
        }
      } else {
        throw Exception('Failed to update transaction: ${responseData['error'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (_userId == null) throw Exception("User not logged in.");
    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions/$id?userId=$_userId');
    try {
      final response = await http.delete(url);
      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          return;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to delete transaction.');
        }
      } else {
        throw Exception('Failed to delete transaction: ${responseData['error'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }
}