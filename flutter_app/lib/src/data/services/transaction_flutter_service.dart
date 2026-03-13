// File: lib/src/data/services/transaction_flutter_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/transaction_model.dart';


const String _flaskApiBaseUrl = 'https://sit-app-production.up.railway.app';

class TransactionFlutterService {
  final String? _userId; // Bu userId'nin hala bir şekilde sağlanması gerekiyor.
  final _logger = Logger();
  
  TransactionFlutterService(this._userId);

  void _handleError(http.Response response, String context) {
    String errorMessage = 'HTTP ${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body);
      errorMessage = decoded['error'] ?? errorMessage;
    } catch (_) {
      // response body is not JSON (e.g. HTML error page)
    }
    _logger.e("Error in $context - ${response.statusCode}", error: errorMessage);
    throw Exception('$context başarısız: $errorMessage');
  }

  Future<void> createTransfer(Map<String, dynamic> transferData) async {
    if (_userId == null) throw Exception("User not logged in.");
    transferData['userId'] = _userId;

    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions/transfer');
    _logger.i("Creating transfer...");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transferData),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 201) {
        _handleError(response, "transfer işlemi");
      }
      _logger.i("Transfer created successfully.");
    } on SocketException catch (e, s) {
      _logger.e('Network Error on createTransfer', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on createTransfer', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on createTransfer', error: e, stackTrace: s);
      throw Exception('Transfer oluşturulurken beklenmedik bir hata oluştu.');
    }
  }

  Future<List<TransactionModel>> listTransactions({required String startDate, required String endDate, String? type, String? account}) async {
    if (_userId == null) return [];
    
    final Map<String, String> queryParams = {'userId': _userId, 'startDate': startDate, 'endDate': endDate};
    if (type != null) queryParams['type'] = type;
    if (account != null) queryParams['account'] = account;

    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions').replace(queryParameters: queryParams);
    _logger.i("Listing transactions from $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['transactions'] != null) {
          final List<dynamic> transactionsJson = responseData['transactions'];
          return transactionsJson.map((json) => TransactionModel.fromMap(json as Map<String, dynamic>)).toList();
        } else {
          _logger.w("Failed to list transactions, success=false", error: responseData['error']);
          throw Exception('İşlemler listelenemedi: ${responseData['error'] ?? 'Bilinmeyen API hatası'}');
        }
      } else {
        _handleError(response, "işlemleri listeleme");
        throw Exception("Bu satır çalışmamalı");
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on listTransactions', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on listTransactions', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on listTransactions', error: e, stackTrace: s);
      throw Exception('İşlemler listelenirken beklenmedik bir hata oluştu.');
    }
  }

  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    // Token alma kısmı kaldırıldı.
    if (_userId == null) throw Exception("Kullanıcı ID'si bulunamadı.");

    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions');
    _logger.i("Creating transaction for user: $_userId");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Authorization başlığı kaldırıldı.
        },
        body: json.encode(transaction.toMap()),
      ).timeout(const Duration(seconds: 60));

      // Sunucu yanıtını kontrol etme kısmı aynı kaldı, çünkü bu hala çok önemli.
      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        _logger.i("Transaction created successfully.");
        return TransactionModel.fromMap(responseData['transaction']);
      } else {
        // Hata durumunda, çökme yerine Exception fırlat.
        Map<String, dynamic> errorData = {};
        try { errorData = json.decode(response.body); } catch (_) { errorData = {"error": response.body}; }
        _logger.e("Failed to create transaction - ${response.statusCode}", error: errorData);
        throw Exception('İşlem oluşturulamadı: ${errorData['error'] ?? 'Bilinmeyen bir sunucu hatası.'}');
      }
    } on SocketException catch (e) {
      _logger.e("Network error on createTransaction: $e");
      throw Exception("Lütfen internet bağlantınızı kontrol edin.");
    } on TimeoutException catch (e) {
      _logger.e("Timeout on createTransaction: $e");
      throw Exception("Sunucuya ulaşılamadı, lütfen daha sonra tekrar deneyin.");
    } catch (e) {
      _logger.e("Generic error on createTransaction: $e");
      if (e is Exception) {
        rethrow;
      }
      throw Exception("İşlem oluşturulurken beklenmedik bir hata oluştu.");
    }
  }

  Future<TransactionModel> updateTransaction(String id, TransactionModel transaction) async {
    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions/$id');
    _logger.i("Updating transaction $id");

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transaction.toMapForUpdate())
      ).timeout(const Duration(seconds: 60));

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseData['success'] == true && responseData['transaction'] != null) {
          return TransactionModel.fromMap(responseData['transaction'] as Map<String, dynamic>);
        } else {
          _logger.w("Failed to update transaction, success=false", error: responseData['error']);
          throw Exception(responseData['error'] ?? 'İşlem güncellenemedi: Beklenmedik API yanıtı.');
        }
      } else {
        _handleError(response, "işlem güncelleme");
        throw Exception("Bu satır çalışmamalı");
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on updateTransaction', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on updateTransaction', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on updateTransaction', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (_userId == null) throw Exception("User not logged in.");

    final url = Uri.parse('$_flaskApiBaseUrl/api/transactions/$id?userId=$_userId');
    _logger.i("Deleting transaction $id");

    try {
      final response = await http.delete(url).timeout(const Duration(seconds: 60));
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] != true) {
          _logger.w("Failed to delete transaction, success=false", error: responseData['error']);
          throw Exception(responseData['error'] ?? 'İşlem silinemedi.');
        }
      } else {
        _handleError(response, "işlem silme");
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on deleteTransaction', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on deleteTransaction', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on deleteTransaction', error: e, stackTrace: s);
      rethrow;
    }
  }
}