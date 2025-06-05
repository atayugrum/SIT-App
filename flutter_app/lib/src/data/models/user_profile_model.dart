// File: flutter_app/lib/src/data/models/user_profile_model.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp, if Firestore returns it directly

class UserProfile {
  final String uid;
  final String fullName;
  final String username;
  final String email;
  final String birthDate; // Expecting YYYY-MM-DD string from Flask
  final String? profileIconId;
  final String? riskProfile;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.username,
    required this.email,
    required this.birthDate,
    this.profileIconId,
    this.riskProfile,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // Helper function to parse dates safely from String (ISO 8601) or Timestamp
    DateTime _parseDate(dynamic dateInput) {
      if (dateInput == null) return DateTime.now(); // Fallback for safety
      if (dateInput is Timestamp) return dateInput.toDate();
      if (dateInput is String) return DateTime.tryParse(dateInput) ?? DateTime.now();
      return DateTime.now(); // Default fallback
    }

    return UserProfile(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? 'N/A',
      username: map['username'] as String? ?? 'N/A',
      email: map['email'] as String? ?? 'N/A',
      birthDate: map['birthDate'] as String? ?? 'N/A',
      profileIconId: map['profileIconId'] as String?,
      riskProfile: map['riskProfile'] as String?,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }
  
  Map<String, dynamic> toMap() { // For updates later
    return {
      'uid': uid,
      'fullName': fullName,
      'username': username,
      'email': email,
      'birthDate': birthDate,
      'profileIconId': profileIconId,
      'riskProfile': riskProfile,
      'createdAt': createdAt.toIso8601String(), // Send as ISO string
      'updatedAt': updatedAt.toIso8601String(), // Send as ISO string
    };
  }
}