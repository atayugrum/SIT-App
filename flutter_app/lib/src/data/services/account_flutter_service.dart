// File: lib/src/data/services/account_flutter_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_model.dart';
import '../../presentation/providers/auth_providers.dart';

class AccountFlutterService {
  static const String _baseUrl = 'http://10.0.2.2:5000';
  final Ref _ref;

  AccountFlutterService(this._ref);

  Future<List<AccountModel>> listAccounts() async {
    final userId = _ref.read(userIdProvider);
    if (userId == null) {
      print("ACCOUNT_SERVICE: User not logged in. Returning empty list.");
      return [];
    }

    final url = Uri.parse('$_baseUrl/api/accounts').replace(queryParameters: {'userId': userId});
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> accountList = data['accounts'];
      return accountList.map((item) => AccountModel.fromMap(item)).toList();
    } else {
      throw Exception('Failed to load accounts');
    }
  }

  Future<AccountModel> createAccount(Map<String, dynamic> accountData) async {
    final userId = _ref.read(userIdProvider);
    if (userId == null) throw Exception("User not logged in.");

    accountData['userId'] = userId;
    
    final url = Uri.parse('$_baseUrl/api/accounts');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(accountData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return AccountModel.fromMap(data['account']);
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception('Failed to create account: $error');
    }
  }
}