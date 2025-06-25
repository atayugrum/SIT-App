// File: flutter_app/lib/src/data/services/auth_service.dart
import 'package:logger/logger.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  static const String _flaskApiBaseUrl = 'http://10.0.2.2:5000';
  final _logger = Logger(
    printer: PrettyPrinter(methodCount: 1, errorMethodCount: 5),
  );

  AuthService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i("Attempting Firebase SignIn for $email");
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.i("Firebase SignIn Successful for $email");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase SignIn AuthException: ${e.code}', error: e);
      rethrow;
    } catch (e, s) {
      _logger.e('Generic SignIn Exception', error: e, stackTrace: s);
      throw Exception('Giriş yapılırken beklenmedik bir hata oluştu.');
    }
  }

  Future<UserCredential?> signUpAndCreateProfile({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required DateTime birthDate,
    String profileIconId = 'icon-1',
  }) async {
    UserCredential? userCredential;
    User? firebaseUser;

    try {
      _logger.i("Attempting Firebase SignUp for $email");
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = userCredential.user;
      _logger.i("Firebase SignUp Successful. UID: ${firebaseUser?.uid}");

      if (firebaseUser == null) {
        _logger.e("Firebase user is null after creation. This shouldn't happen.");
        throw Exception('Firebase user creation returned null user.');
      }
      
      final String birthDateString = "${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}";
      
      final profileData = {
        'uid': firebaseUser.uid, 'email': email, 'fullName': fullName,
        'username': username, 'birthDate': birthDateString, 'profileIconId': profileIconId,
      };

      final apiUrl = '$_flaskApiBaseUrl/api/users/create_profile';
      _logger.i("Calling Flask API at: $apiUrl with data: ${jsonEncode(profileData)}");
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profileData),
      ).timeout(const Duration(seconds: 15));
      
      _logger.i("Flask API response status: ${response.statusCode}");
      _logger.d("Flask API response body: ${response.body}");

      if (response.statusCode == 201) {
        _logger.i('User profile created via Flask API successfully.');
        return userCredential;
      } else {
        _logger.w('Flask API Error - Status ${response.statusCode}: ${response.body}');
        await firebaseUser.delete();
        _logger.w("Orphaned Firebase Auth user ${firebaseUser.uid} deleted due to API error response.");
        throw Exception('Backend üzerinde profil oluşturulamadı: ${response.reasonPhrase}');
      }
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase SignUp AuthException: ${e.code}', error: e);
      rethrow; 
    } on SocketException catch (e, s) {
        _logger.e('Network error during profile creation', error: e, stackTrace: s);
        if (firebaseUser != null) await firebaseUser.delete();
        throw Exception('Ağ hatası oluştu. Lütfen bağlantınızı kontrol edin.');
    } on TimeoutException catch(e, s) {
        _logger.e('API call timed out', error: e, stackTrace: s);
        if (firebaseUser != null) await firebaseUser.delete();
        throw Exception('Ağ bağlantısı zaman aşımına uğradı. Lütfen tekrar deneyin.');
    } catch (e, s) {
      _logger.e('Generic SignUp/Profile Creation Exception', error: e, stackTrace: s);
      if (firebaseUser != null && _firebaseAuth.currentUser?.uid == firebaseUser.uid) {
          try {
            _logger.w("Attempting to delete Firebase user ${firebaseUser.uid} in generic catch block.");
            await firebaseUser.delete();
            _logger.i("Firebase user ${firebaseUser.uid} deleted successfully in generic catch block.");
          } catch (deleteError, deleteStack) {
            _logger.f("CRITICAL: Error deleting Firebase user in generic catch block", error: deleteError, stackTrace: deleteStack);
          }
      }
      throw Exception('Kayıt sırasında beklenmedik bir hata oluştu.');
    }
  }

  Future<void> signOut() async {
    try {
      _logger.i("Attempting signOut.");
      await _firebaseAuth.signOut();
      _logger.i("SignOut successful.");
    } catch (e, s) {
      _logger.e('Error during signOut', error: e, stackTrace: s);
      throw Exception('Oturum kapatılamadı.');
    }
  }
}