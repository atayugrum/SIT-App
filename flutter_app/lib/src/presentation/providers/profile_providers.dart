// File: lib/src/presentation/providers/profile_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/services/profile_service.dart'; // Düzeltilmiş servisi import ediyoruz
import 'auth_providers.dart';

// 1. Düzeltilmiş ProfileService'i sağlayan provider.
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

// 2. Kullanıcının profil verisini çeken ana provider.
// Bu provider artık düzeltilmiş servisi kullandığı için doğru çalışacaktır.
// .autoDispose, profil sayfasından ayrılınca hafızayı boşaltır ve geri dönüldüğünde
// en güncel veriyi tetikler. Artık sunucudan okuma garantisi olduğu için bu güvenlidir.
final userProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  final firebaseUser = ref.watch(currentUserProvider);

  if (firebaseUser != null) {
    // profileServiceProvider'ı dinleyerek ProfileService'in bir örneğini al.
    final profileService = ref.read(profileServiceProvider);

    // Servis üzerinden kullanıcı profilini getir.
    // Bu çağrı artık her zaman sunucudaki en güncel veriyi getirecektir.
    final profile = await profileService.getUserProfile(firebaseUser.uid);
    return profile;
  } else {
    // Kullanıcı giriş yapmamışsa null döndür.
    return null;
  }
});
