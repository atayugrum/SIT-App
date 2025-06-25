// File: flutter_app/lib/app_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // YENİ IMPORT
import 'src/presentation/screens/auth/auth_wrapper.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'SIT App',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        debugShowCheckedModeBanner: false,

        // --- BU SATIRLARI EKLEYİN ---
        locale: const Locale(
            'tr', 'TR'), // Uygulamanın varsayılan dilini Türkçe yapar
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'), // Türkçe desteği
          Locale('en', 'US'), // İngilizce (opsiyonel ama iyi bir pratiktir)
        ],
        // --------------------------

        home: const AuthWrapper(),
      ),
    );
  }
}
