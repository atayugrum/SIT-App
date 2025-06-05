// File: flutter_app/lib/src/presentation/screens/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the authStateChangesProvider
    // This will rebuild the widget when the auth state changes
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is logged in, show HomeScreen
          return const HomeScreen();
        } else {
          // User is logged out, show LoginScreen
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold( // Show a loading indicator while checking auth state
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold( // Show an error screen if something goes wrong
        body: Center(child: Text('Something went wrong: $error')),
      ),
    );
  }
}