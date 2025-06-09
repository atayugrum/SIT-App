// File: lib/src/presentation/providers/auth_providers.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart'; // Bu import yolunu projenize göre düzenleyin.

// 1. Firebase Authentication servisini sağlayan temel provider.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// 2. Kendi yazdığımız AuthService sınıfını sağlayan provider.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

// 3. Kimlik doğrulama durumundaki değişiklikleri (giriş/çıkış) dinleyen StreamProvider.
// Uygulamanın oturum yönetiminin kalbidir.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// 4. Mevcut kullanıcıyı SENKRON olarak almak için kullanılan provider. (GÜNCELLENDİ)
// Diğer provider'ı dinleyerek her zaman en güncel User nesnesini sağlar.
// Bu, projenizin diğer bölümlerinin bozulmasını engeller.
final currentUserProvider = Provider<User?>((ref) {
  // authStateChangesProvider'dan gelen en son değeri (.value) döndürür.
  return ref.watch(authStateChangesProvider).value;
});

// 5. Yalnızca mevcut kullanıcının KİMLİĞİNİ (UID - String) sağlayan provider.
// Yatırım modülü ve diğer modüllerin kullanımı için idealdir.
final userIdProvider = Provider<String?>((ref) {
  // authStateChangesProvider'dan gelen en son değerin 'uid' özelliğini döndürür.
  return ref.watch(authStateChangesProvider).value?.uid;
});