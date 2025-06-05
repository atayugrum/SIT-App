// File: flutter_app/lib/src/presentation/screens/accounts/account_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/account_model.dart';
import '../../providers/account_providers.dart';
import '../../providers/auth_providers.dart'; // To get userId

class AccountFormScreen extends ConsumerStatefulWidget {
  final AccountModel? accountToEdit; // For editing later
  const AccountFormScreen({super.key, this.accountToEdit});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _accountNameController;
  late TextEditingController _initialBalanceController;
  late TextEditingController _currencyController;

  String _selectedAccountType = 'Bank'; // Default type
  final List<String> _accountTypes = ['Bank', 'Cash', 'Credit Card', 'E-Wallet', 'Savings', 'Investment', 'Other'];
  // Removed _commonCurrencies as it was unused. User will type currency.

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing an existing account
    _accountNameController = TextEditingController(text: widget.accountToEdit?.accountName ?? '');
    // For editing, initialBalance is usually not changed, but currentBalance is.
    // For simplicity, we'll keep it as initialBalance for now for adding.
    _initialBalanceController = TextEditingController(text: widget.accountToEdit?.initialBalance.toStringAsFixed(2) ?? '0.00');
    _selectedAccountType = widget.accountToEdit?.accountType ?? 'Bank';
    _currencyController = TextEditingController(text: widget.accountToEdit?.currency ?? 'TRY');
    // TODO: Implement proper edit logic vs create logic based on widget.accountToEdit
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _initialBalanceController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in! Cannot save account.'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    // For new accounts, currentBalance is same as initialBalance.
    // For editing, this logic would be different.
    final balance = double.tryParse(_initialBalanceController.text.trim()) ?? 0.0;

    final accountData = AccountModel(
      id: widget.accountToEdit?.id, // Pass ID if editing
      userId: currentUser.uid, // This will be overridden by service if needed, but good to have
      accountName: _accountNameController.text.trim(),
      accountType: _selectedAccountType,
      initialBalance: balance,
      currentBalance: widget.accountToEdit?.currentBalance ?? balance, // Use existing current if editing, else initial
      currency: _currencyController.text.trim().toUpperCase(),
      createdAt: widget.accountToEdit?.createdAt ?? DateTime.now(), // Keep original if editing
      updatedAt: DateTime.now(), // Will be set by backend
    );

    try {
      if (widget.accountToEdit != null) {
        // TODO: Implement updateAccount method in AccountFlutterService and AccountListNotifier
        print("ACCOUNT_FORM_SCREEN: Update logic to be implemented.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update functionality coming soon!'), backgroundColor: Colors.orangeAccent),
        );
        // For now, we'll just pop. Replace with actual update call.
        // await ref.read(accountsProvider.notifier).updateAccount(accountData); 
      } else {
        await ref.read(accountsProvider.notifier).addAccount(accountData);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account ${widget.accountToEdit != null ? "updated" : "saved"} successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true); // Pop and indicate success to refresh previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save account: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent),
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
      appBar: AppBar(
        title: Text(widget.accountToEdit == null ? 'Add New Account' : 'Edit Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _accountNameController,
                decoration: const InputDecoration(labelText: 'Account Name (e.g., Salary Account, Cash Wallet)', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)))),
                validator: (value) => value == null || value.isEmpty ? 'Please enter an account name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAccountType,
                decoration: const InputDecoration(labelText: 'Account Type', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)))),
                items: _accountTypes.map((String type) {
                  return DropdownMenuItem<String>(value: type, child: Text(type));
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedAccountType = newValue);
                  }
                },
                validator: (value) => value == null ? 'Please select an account type' : null,
              ),
              const SizedBox(height: 16),
               TextFormField(
                controller: _currencyController,
                decoration: const InputDecoration(labelText: 'Currency (e.g., TRY, USD)', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)))),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z]')),
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a currency code';
                  if (value.length < 3) return 'Currency code must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialBalanceController,
                decoration: InputDecoration(labelText: 'Initial Balance (${_currencyController.text.toUpperCase()})', border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)))),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty && (double.tryParse(value) == null)) { // Allow zero balance
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAccount,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: _isLoading
                    ? const SizedBox(height:20, width:20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}