// File: flutter_app/lib/app_widget.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/theme/app_theme.dart';
import 'src/presentation/screens/auth/auth_wrapper.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: const CupertinoApp(
        title: 'SIT App',
        theme: AppTheme.cupertinoTheme,
        debugShowCheckedModeBanner: false,

        // Türkçe yerelleştirme
        locale: Locale('tr', 'TR'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate, // fl_chart için gereklidir
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],

        home: AuthWrapper(),
      ),
    );
  }
}
