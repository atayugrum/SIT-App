// File: flutter_app/lib/app_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'src/presentation/screens/auth/login_screen.dart'; // No longer directly used here
import 'src/presentation/screens/auth/auth_wrapper.dart'; // Import AuthWrapper

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
        home: const AuthWrapper(), // Start with AuthWrapper
      ),
    );
  }
}