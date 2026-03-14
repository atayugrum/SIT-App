// File: lib/src/presentation/screens/auth/auth_wrapper.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../navigation/main_tab_navigator.dart';
import 'login_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user != null) return const MainTabNavigator();
        return const LoginScreen();
      },
      loading: () => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator(radius: 16)),
      ),
      error: (error, stack) => CupertinoPageScaffold(
        child: Center(
          child: Text(
            'Bir hata oluştu: $error',
            style: const TextStyle(color: CupertinoColors.systemRed),
          ),
        ),
      ),
    );
  }
}
