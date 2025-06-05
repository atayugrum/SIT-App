// File: flutter_app/lib/src/presentation/screens/auth/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
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
  final _birthDateController = TextEditingController(); // To display selected date
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
      initialDate: _selectedBirthDate ?? DateTime(2000, 1, 1), 
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18 + 4)), 
      helpText: 'Select your birth date',
      confirmText: 'Select',
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _registerUser() async {
    print("REGISTER_SCREEN: _registerUser called.");
    if (!_formKey.currentState!.validate()) {
      print("REGISTER_SCREEN: Form is not valid.");
      return; 
    }
    if (_selectedBirthDate == null) {
      print("REGISTER_SCREEN: Birth date not selected.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select your birth date.'),
              backgroundColor: Colors.orangeAccent),
        );
      }
      return;
    }

    setState(() {
      print("REGISTER_SCREEN: Setting _isLoading = true");
      _isLoading = true;
    });

    try {
      print("REGISTER_SCREEN: Attempting signUpAndCreateProfile...");
      final authService = ref.read(authServiceProvider);

      await authService.signUpAndCreateProfile(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        birthDate: _selectedBirthDate!,
      );
      print("REGISTER_SCREEN: signUpAndCreateProfile call COMPLETED (may or may not have been successful internally).");

      // If the above call didn't throw an exception, it means it was successful
      // (including API call and no orphaned user deletion)
      print("REGISTER_SCREEN: Now proceeding with signOut in RegistrationScreen success path...");
      await authService.signOut();
      print("REGISTER_SCREEN: signOut in RegistrationScreen SUCCESSFUL.");
      
      if (mounted) {
        print("REGISTER_SCREEN: Showing success SnackBar...");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration successful! Please log in.'),
              backgroundColor: Colors.green),
        );
        print("REGISTER_SCREEN: Attempting to pop screen...");
        if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            print("REGISTER_SCREEN: Screen popped.");
        } else {
            print("REGISTER_SCREEN: Screen CANNOT be popped.");
        }
      } else {
          print("REGISTER_SCREEN: Success path, but widget not mounted before SnackBar/Pop.");
      }
    } on FirebaseAuthException catch (e) {
      print("REGISTER_SCREEN: FirebaseAuthException caught in RegistrationScreen: ${e.code} - ${e.message}");
      String errorMessage = 'Registration failed. Please try again.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.redAccent),
        );
      }
    } catch (e, s) { 
      print("REGISTER_SCREEN: Generic Exception caught in RegistrationScreen: $e");
      print("REGISTER_SCREEN: StackTrace for Generic Exception in RegistrationScreen: $s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              // Display the specific error message from the AuthService if available
              content: Text(e.toString().replaceFirst("Exception: ", "")), // Basic formatting
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      print("REGISTER_SCREEN: FINALLY block reached in RegistrationScreen.");
      if (mounted) {
        setState(() {
          print("REGISTER_SCREEN: FINALLY - Setting _isLoading = false in RegistrationScreen");
          _isLoading = false; 
        });
        print("REGISTER_SCREEN: FINALLY - setState for _isLoading called in RegistrationScreen.");
      } else {
          print("REGISTER_SCREEN: FINALLY block in RegistrationScreen, but widget not mounted.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... THE REST OF YOUR BUILD METHOD (UNCHANGED from the previous complete RegistrationScreen code) ...
    // (Includes all TextFormFields, ElevatedButton, TextButton)
    // For brevity, I'm not repeating the entire build method here.
    // Just make sure the _registerUser method above is correctly placed within the _RegistrationScreenState class.
    // The build method from the "can you write the entire block?" response is correct.
     return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
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
                  decoration: const InputDecoration(
                    labelText: 'Full Name', 
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username', 
                    prefixIcon: Icon(Icons.account_circle_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a username' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email', 
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!value.contains('@') || !value.contains('.')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password', 
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password', 
                    prefixIcon: Icon(Icons.lock_person_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Birth Date',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    hintText: _selectedBirthDate == null ? 'Select your birth date' : null,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  ),
                  onTap: () => _selectBirthDate(context),
                  validator: (value) => _selectedBirthDate == null ? 'Please select your birth date' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Register', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : () {
                     if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                     }
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}