// File: lib/src/presentation/screens/profile/edit_profile_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_profile_model.dart';
import '../../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile initialProfile;
  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _usernameCtrl;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl =
        TextEditingController(text: widget.initialProfile.fullName);
    _usernameCtrl =
        TextEditingController(text: widget.initialProfile.username);
    if (widget.initialProfile.birthDate.isNotEmpty) {
      try {
        _selectedBirthDate = DateFormat('yyyy-MM-dd')
            .parse(widget.initialProfile.birthDate);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  void _showAlert(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        content: Text(msg),
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

  void _pickBirthDate() {
    final initial = _selectedBirthDate ?? DateTime(1990);
    DateTime temp = initial;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 320,
        color: const Color(0xFF1C1C1E),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('İptal',
                      style: TextStyle(color: AppColors.textSecondary)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text('Doğum Tarihi',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                CupertinoButton(
                  child: const Text('Uygula',
                      style: TextStyle(color: AppColors.primaryBlue)),
                  onPressed: () {
                    setState(() => _selectedBirthDate = temp);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                minimumDate: DateTime(1900),
                maximumDate: DateTime.now()
                    .subtract(const Duration(days: 365 * 18)),
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _fullNameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    if (name.isEmpty) {
      _showAlert('Tam ad boş bırakılamaz.');
      return;
    }
    if (username.isEmpty) {
      _showAlert('Kullanıcı adı boş bırakılamaz.');
      return;
    }
    if (_selectedBirthDate == null) {
      _showAlert('Lütfen doğum tarihinizi seçin.');
      return;
    }
    setState(() => _isLoading = true);
    final updates = <String, dynamic>{
      'fullName': name,
      'username': username,
      'birthDate': DateFormat('yyyy-MM-dd').format(_selectedBirthDate!),
    };
    try {
      await ref
          .read(profileServiceProvider)
          .updateUserProfile(widget.initialProfile.uid, updates);
      ref.invalidate(userProfileProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        _showAlert(
            'Profil güncellenemedi: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  BoxDecoration get _fieldDecor => BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      );

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedBirthDate == null
        ? 'Doğum tarihinizi seçin'
        : DateFormat('dd MMM yyyy', 'tr').format(_selectedBirthDate!);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Profili Düzenle'),
        backgroundColor: Color(0xCC000000),
        border: Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Tam Ad',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _fullNameCtrl,
              placeholder: 'Adınız Soyadınız',
              placeholderStyle:
                  const TextStyle(color: AppColors.textSecondary),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecor,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            const SizedBox(height: 16),
            const Text('Kullanıcı Adı',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _usernameCtrl,
              placeholder: 'kullanici_adi',
              placeholderStyle:
                  const TextStyle(color: AppColors.textSecondary),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecor,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            const SizedBox(height: 16),
            const Text('Doğum Tarihi',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickBirthDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: _fieldDecor,
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.calendar,
                        color: AppColors.primaryBlue, size: 18),
                    const SizedBox(width: 10),
                    Text(dateLabel,
                        style: TextStyle(
                          color: _selectedBirthDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                  : const Text('Değişiklikleri Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
