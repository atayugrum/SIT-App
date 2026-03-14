// File: lib/src/presentation/screens/auth/login_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import 'registration_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showAlert('Geçersiz E-posta', 'Lütfen geçerli bir e-posta adresi girin.');
      return false;
    }
    if (password.length < 6) {
      _showAlert('Geçersiz Şifre', 'Şifre en az 6 karakter olmalıdır.');
      return false;
    }
    return true;
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Tamam'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _loginUser() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on FirebaseAuthException catch (e) {
      String msg = 'Giriş başarısız. Lütfen tekrar deneyin.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        msg = 'Geçersiz e-posta veya şifre.';
      } else if (e.code == 'wrong-password') {
        msg = 'Yanlış şifre girdiniz.';
      } else if (e.code == 'invalid-email') {
        msg = 'E-posta adresi geçerli değil.';
      }
      if (mounted) _showAlert('Giriş Hatası', msg);
    } catch (e) {
      if (mounted) _showAlert('Hata', 'Beklenmedik bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Logo
              const Icon(
                CupertinoIcons.chart_bar_alt_fill,
                size: 72,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 16),
              const Text(
                'SIT App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.37,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Finansal özgürlüğünüze hoş geldiniz',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // E-posta alanı
              const _FieldLabel(label: 'E-posta'),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                placeholder: 'ornek@eposta.com',
                placeholderStyle: const TextStyle(color: AppColors.textTertiary),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(CupertinoIcons.mail, color: AppColors.textSecondary, size: 18),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),

              // Şifre alanı
              const _FieldLabel(label: 'Şifre'),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _passwordController,
                obscureText: true,
                placeholder: 'Güvenli şifreniz',
                placeholderStyle: const TextStyle(color: AppColors.textTertiary),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(CupertinoIcons.lock, color: AppColors.textSecondary, size: 18),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _loginUser(),
              ),
              const SizedBox(height: 32),

              // Giriş butonu
              CupertinoButton.filled(
                onPressed: _isLoading ? null : _loginUser,
                borderRadius: BorderRadius.circular(14),
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text(
                        'Giriş Yap',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),

              // Kayıt ol linki
              CupertinoButton(
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => const RegistrationScreen()),
                ),
                child: const Text(
                  'Hesabınız yok mu? Kaydolun',
                  style: TextStyle(color: AppColors.primaryBlue, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final BoxDecoration _inputDecoration = BoxDecoration(
    color: AppColors.surfaceGlass,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.glassBorder, width: 0.5),
  );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}
