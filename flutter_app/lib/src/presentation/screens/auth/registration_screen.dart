// File: lib/src/presentation/screens/auth/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('tr', 'TR'),
      initialDate: _selectedBirthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18 + 4)),
      helpText: 'Doğum Tarihinizi Seçin',
      confirmText: 'Seç',
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lütfen doğum tarihinizi seçin.'),
              backgroundColor: Colors.orangeAccent),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpAndCreateProfile(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        birthDate: _selectedBirthDate!,
      );

      await authService.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kayıt başarılı! Lütfen giriş yapın.'),
              backgroundColor: Colors.green),
        );
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Kayıt başarısız. Lütfen tekrar deneyin.';
      if (e.code == 'weak-password')
        errorMessage = 'Belirlediğiniz şifre çok zayıf.';
      else if (e.code == 'email-already-in-use')
        errorMessage = 'Bu e-posta adresi ile zaten bir hesap mevcut.';
      else if (e.code == 'invalid-email')
        errorMessage = 'E-posta adresi geçerli değil.';
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage), backgroundColor: Colors.redAccent));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.teal.shade700;
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Hesap Oluştur')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: inputDecoration.copyWith(
                      labelText: 'Tam Adınız',
                      prefixIcon: const Icon(Icons.person_outline)),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Lütfen tam adınızı girin'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: inputDecoration.copyWith(
                      labelText: 'Kullanıcı Adı',
                      prefixIcon: const Icon(Icons.account_circle_outlined)),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Lütfen bir kullanıcı adı girin'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: inputDecoration.copyWith(
                      labelText: 'E-posta',
                      prefixIcon: const Icon(Icons.email_outlined)),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Lütfen e-posta adresinizi girin';
                    if (!value.contains('@') || !value.contains('.'))
                      return 'Geçerli bir e-posta adresi girin';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: inputDecoration.copyWith(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline)),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Lütfen bir şifre belirleyin';
                    if (value.length < 6)
                      return 'Şifre en az 6 karakter olmalıdır';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: inputDecoration.copyWith(
                      labelText: 'Şifreyi Onayla',
                      prefixIcon: const Icon(Icons.lock_person_outlined)),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Lütfen şifrenizi tekrar girin';
                    if (value != _passwordController.text)
                      return 'Şifreler uyuşmuyor';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  decoration: inputDecoration.copyWith(
                      labelText: 'Doğum Tarihi',
                      hintText: 'Doğum tarihinizi seçin',
                      suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => _selectBirthDate(context))),
                  onTap: () => _selectBirthDate(context),
                  validator: (value) => _selectedBirthDate == null
                      ? 'Lütfen doğum tarihinizi seçin'
                      : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Kaydol', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (Navigator.of(context).canPop())
                            Navigator.of(context).pop();
                        },
                  child: const Text('Zaten bir hesabınız var mı? Giriş yapın'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
