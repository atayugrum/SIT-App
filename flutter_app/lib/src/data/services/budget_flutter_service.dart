// File: lib/src/data/services/budget_flutter_service.dart
import 'dart:convert';
import '../../core/network/api_constants.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/budget_model.dart';
import '../../presentation/providers/auth_providers.dart';

class BudgetFlutterService {
  final Ref _ref;
  final _logger = Logger();

  BudgetFlutterService(this._ref);

  String? get _userId => _ref.read(userIdProvider);

  Future<List<BudgetModel>> listBudgets(int year, int month) async {
    if (_userId == null) {
       _logger.w("Cannot list budgets: User not logged in.");
       return [];
    }
    
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/budgets?userId=$_userId&year=$year&month=$month');
    _logger.i("Listing budgets from: $uri");

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['budgets'] != null) {
          final List<dynamic> budgetsJson = data['budgets'];
          return budgetsJson.map((json) => BudgetModel.fromMap(json, json['id'])).toList();
        } else {
          _logger.w("Failed to fetch budgets, success=false", error: data['error']);
          throw Exception(data['error'] ?? 'Bütçeler alınamadı.');
        }
      } else {
        _logger.e("Error listing budgets - ${response.statusCode}", error: response.body);
        throw Exception('Bütçeler alınamadı: Hata ${response.statusCode}');
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on listBudgets', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on listBudgets', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on listBudgets', error: e, stackTrace: s);
      throw Exception('Bütçeler listelenirken beklenmedik bir hata oluştu.');
    }
  }

  Future<BudgetModel> createOrUpdateBudget(BudgetModel budget) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/budgets');
    // --- HATA DÜZELTMESİ BURADA ---
    // 'budget.categoryName' yerine modeldeki doğru alan adı olan 'budget.category' kullanıldı.
    _logger.i("Creating/updating budget for category: ${budget.category}");
    
    try {
      final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(budget.toMap()),
          ).timeout(const Duration(seconds: 60));

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true && responseData['budget'] != null) {
          _logger.i("Budget saved successfully.");
          return BudgetModel.fromMap(responseData['budget'], responseData['budget']['id']);
        } else {
          _logger.w("Failed to save budget, success=false", error: responseData['error']);
          throw Exception(responseData['error'] ?? 'Bütçe kaydedilemedi.');
        }
      } else {
        _logger.e("Error saving budget - ${response.statusCode}", error: responseData);
        throw Exception(responseData['error'] ?? 'Bütçe kaydedilirken sunucu hatası oluştu.');
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on createOrUpdateBudget', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on createOrUpdateBudget', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on createOrUpdateBudget', error: e, stackTrace: s);
      throw Exception('Bütçe kaydedilirken beklenmedik bir hata oluştu.');
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    if (_userId == null) throw Exception("User not authenticated.");
    
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/budgets/$budgetId?userId=$_userId');
    _logger.i("Deleting budget: $budgetId");

    try {
      final response = await http.delete(uri).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        String error = "HTTP ${response.statusCode}";
        try { error = json.decode(response.body)["error"] ?? error; } catch (_) {}
        _logger.e("Error deleting budget - ${response.statusCode}", error: error);
        throw Exception('Bütçe silinemedi: $error');
      }
       _logger.i("Budget $budgetId deleted successfully.");
    } on SocketException catch (e, s) {
      _logger.e('Network Error on deleteBudget', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on deleteBudget', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on deleteBudget', error: e, stackTrace: s);
      throw Exception('Bütçe silinirken beklenmedik bir hata oluştu.');
    }
  }
}