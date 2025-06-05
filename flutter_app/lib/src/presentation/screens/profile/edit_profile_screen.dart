// File: flutter_app/lib/src/presentation/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user_profile_model.dart';
import '../../providers/profile_providers.dart'; // For profileServiceProvider and userProfileProvider

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile initialProfile; // Pass the current profile to pre-fill

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
    _fullNameController = TextEditingController(text: widget.initialProfile.fullName);
    _usernameController = TextEditingController(text: widget.initialProfile.username);
    _birthDateController = TextEditingController(text: widget.initialProfile.birthDate);
    // Try to parse the initial birthDate string to DateTime
    if (widget.initialProfile.birthDate.isNotEmpty) {
        try {
             _selectedBirthDate = DateFormat('yyyy-MM-dd').parse(widget.initialProfile.birthDate);
        } catch(e) {
            print("Error parsing initial birthDate: ${widget.initialProfile.birthDate} - $e");
            _selectedBirthDate = null; // or some default
            _birthDateController.text = ''; // Clear if parsing failed
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
     if (_selectedBirthDate == null && _birthDateController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your birth date.'), backgroundColor: Colors.orangeAccent),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final updates = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'birthDate': _birthDateController.text.trim(), // Send as YYYY-MM-DD string
    };

    try {
      await ref.read(profileServiceProvider).updateUserProfile(widget.initialProfile.uid, updates);

      // Refresh the profile data so ProfileScreen shows updated info
      final _ = ref.refresh(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Go back to ProfileScreen
      }
    } catch (e) {
      print("EDIT_PROFILE_SCREEN: Error saving profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent),
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
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)))),
                validator: (value) => value == null || value.isEmpty ? 'Full name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)))),
                validator: (value) => value == null || value.isEmpty ? 'Username cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Birth Date',
                  hintText: 'Select your birth date',
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () => _selectBirthDate(context),
                  )
                ),
                 validator: (value) => value == null || value.isEmpty ? 'Please select your birth date' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Text('Save Changes', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}