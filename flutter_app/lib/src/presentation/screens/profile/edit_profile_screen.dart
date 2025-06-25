// File: lib/src/presentation/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user_profile_model.dart';
import '../../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile initialProfile;
  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _birthDateController;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.initialProfile.fullName);
    _usernameController =
        TextEditingController(text: widget.initialProfile.username);
    _birthDateController =
        TextEditingController(text: widget.initialProfile.birthDate);
    if (widget.initialProfile.birthDate.isNotEmpty) {
      try {
        _selectedBirthDate =
            DateFormat('yyyy-MM-dd').parse(widget.initialProfile.birthDate);
      } catch (e) {
        print(
            "Doğum tarihi ayrıştırılırken hata: ${widget.initialProfile.birthDate} - $e");
      }
    }
  }

  @override
  void dispose() {
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
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final updates = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'birthDate': _birthDateController.text.trim(),
    };

    try {
      await ref
          .read(profileServiceProvider)
          .updateUserProfile(widget.initialProfile.uid, updates);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profil başarıyla güncellendi!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Profil güncellenemedi: ${e.toString().replaceFirst("Exception: ", "")}'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                    labelText: 'Tam Ad',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)))),
                validator: (value) => value == null || value.isEmpty
                    ? 'Tam ad boş bırakılamaz'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)))),
                validator: (value) => value == null || value.isEmpty
                    ? 'Kullanıcı adı boş bırakılamaz'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthDateController,
                readOnly: true,
                decoration: InputDecoration(
                    labelText: 'Doğum Tarihi',
                    hintText: 'Doğum tarihinizi seçin',
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0))),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: () => _selectBirthDate(context),
                    )),
                validator: (value) => value == null || value.isEmpty
                    ? 'Lütfen doğum tarihinizi seçin'
                    : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
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
                    : const Text('Değişiklikleri Kaydet',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
