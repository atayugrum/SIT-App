// File: lib/src/data/services/profile_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  static const String _flaskApiBaseUrl = 'http://10.0.2.2:5000';
  final _logger = Logger();

  Future<UserProfile> getUserProfile(String uid) async {
    if (uid.isEmpty) {
      _logger.w("Attempted to get profile with empty UID.");
      throw ArgumentError('Kullanıcı ID (uid) boş olamaz.');
    }

    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    final url =
        Uri.parse('$_flaskApiBaseUrl/api/users/$uid/profile?_=$cacheBuster');

    _logger.i("Fetching profile from: $url");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      _logger.d("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _logger.i("Profile data fetched successfully for UID $uid.");
        _logger.d("Profile data: $data");
        return UserProfile.fromMap(data);
      } else if (response.statusCode == 404) {
        _logger.w("Profile not found (404) for UID $uid", error: response.body);
        throw Exception('Kullanıcı profili bulunamadı.');
      } else {
        _logger.e(
            "Error fetching profile for UID $uid - ${response.statusCode}",
            error: response.body);
        throw Exception(
            'Kullanıcı profili yüklenemedi: Durum ${response.statusCode}');
      }
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout during getUserProfile for UID $uid',
          error: e, stackTrace: s);
      throw Exception('Ağ bağlantısı zaman aşımına uğradı.');
    } on http.ClientException catch (e, s) {
      _logger.e('ClientException during getUserProfile for UID $uid',
          error: e, stackTrace: s);
      throw Exception('Ağ hatası veya API erişilemez durumda.');
    } catch (e, s) {
      _logger.e('Generic exception during getUserProfile for UID $uid',
          error: e, stackTrace: s);
      throw Exception('Beklenmedik bir hata oluştu: $e');
    }
  }

  Future<UserProfile> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    if (uid.isEmpty) {
      _logger.w("Attempted to update profile with empty UID.");
      throw ArgumentError('Kullanıcı ID (uid) boş olamaz.');
    }
    final url = Uri.parse('$_flaskApiBaseUrl/api/users/$uid/profile');
    _logger.i("Updating profile for UID $uid at: $url");
    _logger.d("Update data: $updates");

    try {
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updates),
          )
          .timeout(const Duration(seconds: 10));

      _logger.d("Update response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true &&
            responseData.containsKey('profile')) {
          _logger.i("Profile updated successfully for UID $uid.");
          return UserProfile.fromMap(
              responseData['profile'] as Map<String, dynamic>);
        } else {
          _logger.e("API success but response format error during update",
              error: response.body);
          throw Exception(responseData['error'] ??
              'Profil güncellenemedi, sunucu yanıtı hatalı.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        _logger.e(
            "Error updating profile for UID $uid - ${response.statusCode}",
            error: response.body);
        throw Exception(
            'Profil güncellenemedi: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout during updateUserProfile for UID $uid',
          error: e, stackTrace: s);
      throw Exception(
          'Güncelleme sırasında ağ bağlantısı zaman aşımına uğradı.');
    } on http.ClientException catch (e, s) {
      _logger.e('ClientException during updateUserProfile for UID $uid',
          error: e, stackTrace: s);
      throw Exception(
          'Güncelleme sırasında ağ hatası veya API erişilemez durumda.');
    } catch (e, s) {
      _logger.e('Generic exception during updateUserProfile for UID $uid',
          error: e, stackTrace: s);
      throw Exception('Beklenmedik bir güncelleme hatası: $e');
    }
  }
  Future<void> deleteUserAccount(String uid) async {
    if (uid.isEmpty) {
      _logger.w("Attempted to delete account with empty UID.");
      throw ArgumentError('Kullanıcı ID (uid) boş olamaz.');
    }
    final url = Uri.parse('$_flaskApiBaseUrl/api/users/$uid');
    _logger.i("Sending DELETE request for user UID $uid to: $url");

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          // NOT: Eğer API'niz token bazlı koruma gerektiriyorsa,
          // 'Authorization': 'Bearer <token>' header'ını burada eklemelisiniz.
        },
      ).timeout(const Duration(seconds: 20));

      _logger.d("Delete response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          _logger.i("User account for UID $uid deleted successfully from backend.");
          return; // Başarılı, geriye bir şey döndürmeye gerek yok.
        } else {
          _logger.e("API success=false during account deletion", error: response.body);
          throw Exception(responseData['error'] ?? 'Hesap silinemedi, sunucu hatası.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        _logger.e(
            "Error deleting account for UID $uid - ${response.statusCode}",
            error: response.body);
        throw Exception(
            'Hesap silinemedi: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } on TimeoutException catch (e, s) {
      _logger.e('Timeout during deleteUserAccount for UID $uid', error: e, stackTrace: s);
      throw Exception('Hesap silinirken ağ bağlantısı zaman aşımına uğradı.');
    } on http.ClientException catch (e, s) {
      _logger.e('ClientException during deleteUserAccount for UID $uid', error: e, stackTrace: s);
      throw Exception('Hesap silinirken ağ hatası veya API erişilemez durumda.');
    } catch (e, s) {
      _logger.e('Generic exception during deleteUserAccount for UID $uid', error: e, stackTrace: s);
      throw Exception('Hesap silinirken beklenmedik bir hata oluştu: $e');
    }
  }
}
