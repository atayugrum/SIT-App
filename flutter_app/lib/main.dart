// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // YENİ: Tarih formatlama için gerekli import

import 'app_widget.dart'; // Sizin App widget'ınızın import yolu
import 'firebase_options.dart'; // Firebase konfigürasyonunuz

// main fonksiyonunu async yapıyoruz
Future<void> main() async {
  // Flutter binding'lerinin başlatıldığından emin oluyoruz
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlatıyoruz
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // YENİ: Uygulama başlamadan önce tarih formatlama yerel ayarlarını başlatıyoruz
  // Bu satır, LocaleDataException hatasını çözer.
  await initializeDateFormatting('tr_TR', null);

  // Uygulamayı çalıştırıyoruz
  runApp(
    const ProviderScope(
      child: AppWidget(), // Sizin ana widget'ınızın adı (örn: MyApp, SitApp)
    ),
  );
}