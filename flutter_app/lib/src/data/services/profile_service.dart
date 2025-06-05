// File: flutter_app/lib/src/data/services/profile_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/user_profile_model.dart';

class ProfileService {
  static const String _flaskApiBaseUrl = 'http://10.0.2.2:5000';

  Future<UserProfile> getUserProfile(String uid) async {
    if (uid.isEmpty) {
      print("PROFILE_SERVICE: Error - User ID (uid) cannot be empty.");
      throw ArgumentError('User ID (uid) cannot be empty.');
    }
    final url = Uri.parse('$_flaskApiBaseUrl/api/users/$uid/profile');
    print("PROFILE_SERVICE: Fetching profile from $url");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print("PROFILE_SERVICE: Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print("PROFILE_SERVICE: Profile data received: $data");
        return UserProfile.fromMap(data);
      } else if (response.statusCode == 404) {
        print("PROFILE_SERVICE: Profile not found (404) for UID $uid - ${response.body}");
        throw Exception('User profile not found.');
      } else {
        print("PROFILE_SERVICE: Error fetching profile - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to load user profile: Status ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e, s) {
      print("PROFILE_SERVICE: Exception during getUserProfile for UID $uid: $e");
      print("PROFILE_SERVICE: StackTrace: $s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error or API not reachable. Please check your connection and API server.');
      }
      throw Exception('Failed to connect or parse profile data: $e');
    }
  }

  // NEW METHOD TO UPDATE USER PROFILE
  Future<UserProfile> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    if (uid.isEmpty) {
      throw ArgumentError('User ID (uid) cannot be empty.');
    }
    final url = Uri.parse('$_flaskApiBaseUrl/api/users/$uid/profile');
    print("PROFILE_SERVICE: Updating profile at $url with data: $updates");

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      ).timeout(const Duration(seconds: 10));

      print("PROFILE_SERVICE: Update response status: ${response.statusCode}");
      // print("PROFILE_SERVICE: Update response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('profile')) {
            print("PROFILE_SERVICE: Profile update successful. Updated data: ${responseData['profile']}");
            return UserProfile.fromMap(responseData['profile'] as Map<String, dynamic>);
        } else {
            print("PROFILE_SERVICE: Profile update API call successful but response indicates failure or missing profile: ${response.body}");
            throw Exception(responseData['error'] ?? 'Failed to update profile, server error.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print("PROFILE_SERVICE: Error updating profile - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to update profile: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("PROFILE_SERVICE: Exception during updateUserProfile for UID $uid: $e");
      print("PROFILE_SERVICE: StackTrace: $s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error or API not reachable during update. Please check your connection and API server.');
      }
      throw Exception('Failed to connect or parse update response: $e');
    }
  }
}