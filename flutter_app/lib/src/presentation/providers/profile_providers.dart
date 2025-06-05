// File: flutter_app/lib/src/presentation/providers/profile_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile_model.dart';    // Import UserProfile model
import '../../data/services/profile_service.dart';  // Import ProfileService
import 'auth_providers.dart';                      // To get current Firebase user's UID

// Provider for ProfileService instance
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(); // Correctly instantiate ProfileService
});

// FutureProvider to fetch the user profile.
// It depends on the current Firebase user's UID.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final firebaseUser = ref.watch(currentUserProvider); // From auth_providers.dart
  
  if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
    print("PROFILE_PROVIDER: Firebase user found with UID: ${firebaseUser.uid}. Attempting to fetch profile...");
    final profileService = ref.watch(profileServiceProvider);
    try {
      final profile = await profileService.getUserProfile(firebaseUser.uid);
      print("PROFILE_PROVIDER: Profile fetched successfully for ${firebaseUser.uid}: ${profile.fullName}");
      return profile;
    } catch (e, s) {
      print("PROFILE_PROVIDER: Error fetching profile for UID ${firebaseUser.uid}: $e");
      print("PROFILE_PROVIDER: StackTrace: $s");
      // Let the FutureProvider handle the error state, which AsyncValue.when can then use.
      // No need for a separate error notifier for this simple fetch.
      throw Exception("Could not load profile data: $e"); // Rethrow to be caught by AsyncValue.error
    }
  } else {
    print("PROFILE_PROVIDER: No Firebase user logged in or UID is empty. Cannot fetch profile.");
    return null; // No user logged in, or UID is empty
  }
});