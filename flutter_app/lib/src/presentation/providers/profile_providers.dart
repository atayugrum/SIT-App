// File: lib/src/presentation/providers/profile_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/services/profile_service.dart';
import 'auth_providers.dart';

// ProfileService'i sağlayan provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

// Kullanıcının profil verisini çeken ana provider
final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final firebaseUser = ref.watch(currentUserProvider);
  
  if (firebaseUser != null) {
    final profileService = ref.watch(profileServiceProvider);
    try {
      final profile = await profileService.getUserProfile(firebaseUser.uid);
      return profile;
    } catch (e) {
      print("PROFILE_PROVIDER: Error fetching profile: $e");
      throw Exception("Could not load profile data: $e");
    }
  } else {
    return null; // Kullanıcı giriş yapmamış
  }
});