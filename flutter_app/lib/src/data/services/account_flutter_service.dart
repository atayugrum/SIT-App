// File: lib/src/data/services/account_flutter_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/account_model.dart';
import '../../presentation/providers/auth_providers.dart';

class AccountFlutterService {
  static const String _baseUrl = 'https://sit-app-backend.onrender.com';
  final Ref _ref;
  final _logger = Logger();

  AccountFlutterService(this._ref);

  String? get _userId => _ref.read(userIdProvider);

  // Hata durumlarını merkezden yöneten yardımcı bir metod
  void _handleError(http.Response response, String context) {
    final error = jsonDecode(response.body)['error'];
    _logger.e('Error in $context - ${response.statusCode}', error: error);
    throw Exception('Failed to $context: $error');
  }

  Future<List<AccountModel>> listAccounts() async {
    if (_userId == null) {
      _logger.w("Cannot list accounts: User not logged in.");
      return [];
    }

    final url = Uri.parse('$_baseUrl/api/accounts').replace(queryParameters: {'userId': _userId});
    _logger.i("Listing accounts from: $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> accountList = data['accounts'];
        return accountList.map((item) => AccountModel.fromMap(item)).toList();
      } else {
        _handleError(response, 'list accounts');
        return []; // Hata durumunda boş liste döner (throw sonrası çalışmaz ama syntax için gerekli)
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on listAccounts', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on listAccounts', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on listAccounts', error: e, stackTrace: s);
      throw Exception('Hesaplar listelenirken beklenmedik bir hata oluştu.');
    }
  }

  Future<AccountModel> createAccount(Map<String, dynamic> accountData) async {
    if (_userId == null) throw Exception("User not logged in.");
    accountData['userId'] = _userId;

    final url = Uri.parse('$_baseUrl/api/accounts');
    _logger.i("Creating account at: $url");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(accountData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _logger.i("Account created successfully: ${data['account']['id']}");
        return AccountModel.fromMap(data['account']);
      } else {
        _handleError(response, 'create account');
        throw Exception('This line should not be reached.');
      }
    } on SocketException catch (e, s) {
      _logger.e('Network Error on createAccount', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on createAccount', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on createAccount', error: e, stackTrace: s);
      throw Exception('Hesap oluşturulurken beklenmedik bir hata oluştu.');
    }
  }

  Future<void> updateAccount(String accountId, Map<String, dynamic> accountData) async {
    final url = Uri.parse('$_baseUrl/api/accounts/$accountId');
    _logger.i("Updating account at: $url");
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(accountData),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        _handleError(response, 'update account');
      }
      _logger.i("Account $accountId updated successfully.");
    } on SocketException catch (e, s) {
      _logger.e('Network Error on updateAccount', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on updateAccount', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on updateAccount', error: e, stackTrace: s);
      throw Exception('Hesap güncellenirken beklenmedik bir hata oluştu.');
    }
  }

  Future<void> archiveAccount(String accountId) async {
    final url = Uri.parse('$_baseUrl/api/accounts/$accountId');
    _logger.i("Archiving account at: $url");
    try {
      final response = await http.delete(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        _handleError(response, 'archive account');
      }
       _logger.i("Account $accountId archived successfully.");
    } on SocketException catch (e, s) {
      _logger.e('Network Error on archiveAccount', error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout on archiveAccount', error: e, stackTrace: s);
      throw Exception('Sunucuya bağlanılamadı. Lütfen daha sonra tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic Error on archiveAccount', error: e, stackTrace: s);
      throw Exception('Hesap arşivlenirken beklenmedik bir hata oluştu.');
    }
  }
}