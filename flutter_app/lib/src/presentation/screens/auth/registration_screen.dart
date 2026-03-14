// File: lib/src/presentation/screens/auth/registration_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_providers.dart';
import '../../../core/theme/app_theme.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _emailController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController        = TextEditingController();
  final _usernameController        = TextEditingController();
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  bool _validate() {
    if (_fullNameController.text.trim().isEmpty) {
      _showAlert('Eksik Alan', 'Lütfen tam adınızı girin.'); return false;
    }
    if (_usernameController.text.trim().isEmpty) {
      _showAlert('Eksik Alan', 'Lütfen bir kullanıcı adı girin.'); return false;
    }
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showAlert('Geçersiz E-posta', 'Lütfen geçerli bir e-posta adresi girin.'); return false;
    }
    if (_passwordController.text.length < 6) {
      _showAlert('Zayıf Şifre', 'Şifre en az 6 karakter olmalıdır.'); return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showAlert('Şifre Uyuşmuyor', 'Girdiğiniz şifreler eşleşmiyor.'); return false;
    }
    if (_selectedBirthDate == null) {
      _showAlert('Eksik Alan', 'Lütfen doğum tarihinizi seçin.'); return false;
    }
    return true;
  }

  void _pickBirthDate() {
    DateTime tempDate = _selectedBirthDate ?? DateTime(2000, 1, 1);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: const Color(0xFF1C1C1E),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: const Text('Seç', style: TextStyle(color: AppColors.primaryBlue)),
                  onPressed: () {
                    setState(() => _selectedBirthDate = tempDate);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: tempDate,
                maximumDate: DateTime.now().subtract(const Duration(days: 365 * 18 + 4)),
                minimumDate: DateTime(1900),
                onDateTimeChanged: (d) => tempDate = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerUser() async {
    if (!_validate()) return;
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
        _showAlert('Kayıt Başarılı', 'Hesabınız oluşturuldu. Lütfen giriş yapın.');
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Kayıt başarısız. Lütfen tekrar deneyin.';
      if (e.code == 'weak-password') {
        msg = 'Belirlediğiniz şifre çok zayıf.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'Bu e-posta ile zaten bir hesap mevcut.';
      } else if (e.code == 'invalid-email') {
        msg = 'E-posta adresi geçerli değil.';
      }
      if (mounted) _showAlert('Kayıt Hatası', msg);
    } catch (e) {
      if (mounted) _showAlert('Hata', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthDateText = _selectedBirthDate != null
        ? DateFormat('dd.MM.yyyy').format(_selectedBirthDate!)
        : 'Doğum tarihinizi seçin';

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Hesap Oluştur'),
        backgroundColor: Color(0xCC000000),
        border: Border(bottom: BorderSide(color: Color(0xFF2C2C2E), width: 0.5)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _FieldLabel(label: 'TAM AD'),
              const SizedBox(height: 8),
              _buildField(_fullNameController, 'Adınız ve soyadınız', CupertinoIcons.person),
              const SizedBox(height: 20),

              const _FieldLabel(label: 'KULLANICI ADI'),
              const SizedBox(height: 8),
              _buildField(_usernameController, 'kullanici_adi', CupertinoIcons.at),
              const SizedBox(height: 20),

              const _FieldLabel(label: 'E-POSTA'),
              const SizedBox(height: 8),
              _buildField(
                _emailController, 'ornek@eposta.com', CupertinoIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              const _FieldLabel(label: 'ŞİFRE'),
              const SizedBox(height: 8),
              _buildField(_passwordController, '••••••••', CupertinoIcons.lock, obscure: true),
              const SizedBox(height: 20),

              const _FieldLabel(label: 'ŞİFRE ONAYI'),
              const SizedBox(height: 8),
              _buildField(
                _confirmPasswordController, '••••••••', CupertinoIcons.lock_shield,
                obscure: true,
              ),
              const SizedBox(height: 20),

              const _FieldLabel(label: 'DOĞUM TARİHİ'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickBirthDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: _inputDecoration,
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.calendar, color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        birthDateText,
                        style: TextStyle(
                          color: _selectedBirthDate != null
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              CupertinoButton.filled(
                onPressed: _isLoading ? null : _registerUser,
                borderRadius: BorderRadius.circular(14),
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text(
                        'Kaydol',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: _isLoading
                    ? null
                    : () { if (Navigator.of(context).canPop()) Navigator.of(context).pop(); },
                child: const Text(
                  'Zaten bir hesabınız var mı? Giriş yapın',
                  style: TextStyle(color: AppColors.primaryBlue, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String placeholder,
    IconData icon, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return CupertinoTextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      placeholder: placeholder,
      placeholderStyle: const TextStyle(color: AppColors.textTertiary),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}
