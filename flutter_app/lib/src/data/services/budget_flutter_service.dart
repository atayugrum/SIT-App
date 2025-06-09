// File: lib/src/data/services/budget_flutter_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget_model.dart';
import '../../presentation/providers/auth_providers.dart';

class BudgetFlutterService {
  final Ref _ref;
  static const String _baseUrl = 'http://10.0.2.2:5000';

  BudgetFlutterService(this._ref);

  String? get _userId => _ref.read(userIdProvider);

  Future<List<BudgetModel>> listBudgets(int year, int month) async {
    if (_userId == null) return [];
    
    final uri = Uri.parse('$_baseUrl/api/budgets?userId=$_userId&year=$year&month=$month');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['budgets'] != null) {
        final List<dynamic> budgetsJson = data['budgets'];
        return budgetsJson.map((json) => BudgetModel.fromMap(json, json['id'])).toList();
      }
    }
    throw Exception('Failed to fetch budgets');
  }

  Future<BudgetModel> createOrUpdateBudget(BudgetModel budget) async {
    final uri = Uri.parse('$_baseUrl/api/budgets');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(budget.toMap()), // Modeli Map'e çevirip gönder
    ).timeout(const Duration(seconds: 10));

    final responseData = json.decode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (responseData['success'] == true && responseData['budget'] != null) {
        return BudgetModel.fromMap(responseData['budget'], responseData['budget']['id']);
      }
    }
    throw Exception(responseData['error'] ?? 'Failed to save budget');
  }

  Future<void> deleteBudget(String budgetId) async {
    if (_userId == null) throw Exception("User not authenticated.");
    final uri = Uri.parse('$_baseUrl/api/budgets/$budgetId?userId=$_userId');
    final response = await http.delete(uri);

    if (response.statusCode != 200) {
      final error = json.decode(response.body)['error'];
      throw Exception('Failed to delete budget: $error');
    }
  }
}