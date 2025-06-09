// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_widget.dart'; // Projenizin ana widget'ını içeren dosya
import 'firebase_options.dart'; // Firebase CLI tarafından oluşturulan konfigürasyon dosyası

// main fonksiyonunu asenkron olarak tanımlıyoruz.
// Bu, uygulama başlamadan önce bazı başlatma işlemlerinin tamamlanmasını beklememizi sağlar.
Future<void> main() async {
  // Flutter framework'ünün native kod ile haberleşmek için hazır olduğundan emin oluyoruz.
  // Firebase gibi eklentileri başlatmadan önce bu satır zorunludur.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase servislerini, platforma özel konfigürasyonlarla başlatıyoruz.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Türkçe tarih ve sayı formatlaması için 'intl' paketini başlatıyoruz.
  // Bu satır, İşlem Geçmişi sayfasındaki DateFormat ve NumberFormat hatalarını çözer.
  await initializeDateFormatting('tr_TR', null);
  
  // Riverpod state yönetimi için ProviderScope ile sarmalayarak uygulamayı çalıştırıyoruz.
  runApp(
    const ProviderScope(
      child: AppWidget(),
    ),
  );
}