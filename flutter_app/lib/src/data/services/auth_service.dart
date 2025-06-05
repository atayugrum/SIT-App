// File: flutter_app/lib/src/data/services/auth_service.dart
// (Make sure imports for firebase_auth, http, and dart:convert are at the top)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  static const String _flaskApiBaseUrl = 'http://10.0.2.2:5000'; // For Android Emulator

  AuthService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print("AUTH_SERVICE: Attempting Firebase SignIn for $email");
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("AUTH_SERVICE: Firebase SignIn Successful for $email");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('AUTH_SERVICE: Firebase SignIn AuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, s) {
      print('AUTH_SERVICE: Generic SignIn Exception: $e');
      print('AUTH_SERVICE: StackTrace: $s');
      throw Exception('An unexpected error occurred during sign in.');
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
      print("AUTH_SERVICE: Attempting Firebase SignUp for $email");
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("AUTH_SERVICE: Firebase SignUp Successful for $email. UID: ${userCredential.user?.uid}");

      firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        print("AUTH_SERVICE: Firebase user is null after creation. This shouldn't happen.");
        throw Exception('Firebase user creation returned null user.');
      }

      // Optionally send email verification
      // print("AUTH_SERVICE: Attempting to send email verification to ${firebaseUser.email}");
      // await firebaseUser.sendEmailVerification();
      // print("AUTH_SERVICE: Email verification sent (or attempted).");

      final String birthDateString = "${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}";
      
      final profileData = {
        'uid': firebaseUser.uid,
        'email': email,
        'fullName': fullName,
        'username': username,
        'birthDate': birthDateString,
        'profileIconId': profileIconId,
      };

      final apiUrl = '$_flaskApiBaseUrl/api/users/create_profile';
      print("AUTH_SERVICE: Attempting to call Flask API at: $apiUrl");
      print("AUTH_SERVICE: Profile data being sent: ${jsonEncode(profileData)}");

      http.Response response;
      try {
        response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(profileData),
        ).timeout(const Duration(seconds: 10)); // Added a timeout
         print("AUTH_SERVICE: Flask API response status: ${response.statusCode}");
         print("AUTH_SERVICE: Flask API response body: ${response.body}");
      } catch (e, s) {
        print("AUTH_SERVICE: HTTP Post Exception to Flask: $e");
        print("AUTH_SERVICE: HTTP Post StackTrace: $s");
        // If HTTP call fails, delete the Firebase Auth user to keep things consistent
        print("AUTH_SERVICE: Deleting orphaned Firebase Auth user ${firebaseUser.uid} due to API call failure.");
        await firebaseUser.delete();
        print("AUTH_SERVICE: Orphaned Firebase Auth user deleted.");
        throw Exception('Network error or API not reachable: $e');
      }
      

      if (response.statusCode == 201) {
        print('AUTH_SERVICE: User profile created via Flask API successfully.');
        return userCredential;
      } else {
        print('AUTH_SERVICE: Flask API Error - Status ${response.statusCode}: ${response.body}');
        print("AUTH_SERVICE: Deleting orphaned Firebase Auth user ${firebaseUser.uid} due to API error response.");
        await firebaseUser.delete();
        print("AUTH_SERVICE: Orphaned Firebase Auth user deleted.");
        throw Exception('Failed to create user profile on backend: ${response.reasonPhrase} - ${response.body}');
      }
    } on FirebaseAuthException catch (e) {
      print('AUTH_SERVICE: Firebase SignUp AuthException: ${e.code} - ${e.message}');
      rethrow; // Rethrow to be caught by RegistrationScreen
    } catch (e, s) { // Catch any other exceptions, including those rethrown or from API call
      print('AUTH_SERVICE: Generic SignUp/Profile Creation Exception: $e');
      print('AUTH_SERVICE: StackTrace: $s');
      // If firebaseUser was created but API call failed later and an error was thrown
      // it might have already been deleted. This is a fallback.
      if (firebaseUser != null && _firebaseAuth.currentUser?.uid == firebaseUser.uid) {
          try {
            print("AUTH_SERVICE: Attempting to delete Firebase user ${firebaseUser.uid} in generic catch block.");
            await firebaseUser.delete();
            print("AUTH_SERVICE: Firebase user ${firebaseUser.uid} deleted in generic catch block.");
          } catch (deleteError) {
            print("AUTH_SERVICE: Error deleting Firebase user in generic catch block: $deleteError");
          }
      }
      // Rethrow a more generic message or the original if it's informative
      throw Exception('An unexpected error occurred during registration. Please check logs.');
    }
  }

  Future<void> signOut() async {
    print("AUTH_SERVICE: Attempting signOut.");
    await _firebaseAuth.signOut();
    print("AUTH_SERVICE: signOut successful.");
  }
}