// File: lib/src/presentation/screens/accounts/account_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/account_providers.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  
  String _accountType = 'bank';
  String _currency = 'TRY';
  String _investmentCategory = 'Borsa İstanbul'; // Yatırım için kategori

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    final Map<String, dynamic> accountData = {
      'accountName': _nameController.text.trim(),
      'accountType': _accountType,
      'currency': _currency,
      'initialBalance': double.tryParse(_balanceController.text) ?? 0.0,
      if (_accountType == 'investment') 'category': _investmentCategory,
    };

    try {
      await ref.read(accountsProvider.notifier).createAccount(accountData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hesap başarıyla oluşturuldu!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(accountsProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Hesap Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Hesap Adı', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Lütfen bir isim girin' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: 'Para Birimi', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'TRY', child: Text('Türk Lirası (TRY)')),
                  DropdownMenuItem(value: 'USD', child: Text('ABD Doları (USD)')),
                ],
                onChanged: (val) => setState(() => _currency = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _accountType,
                decoration: const InputDecoration(labelText: 'Hesap Tipi', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'bank', child: Text('Banka Hesabı')),
                  DropdownMenuItem(value: 'cash', child: Text('Nakit')),
                  DropdownMenuItem(value: 'investment', child: Text('Yatırım Hesabı')),
                ],
                onChanged: (val) => setState(() => _accountType = val!),
              ),
              const SizedBox(height: 16),
              if (_accountType == 'investment')
                DropdownButtonFormField<String>(
                  value: _investmentCategory,
                  decoration: const InputDecoration(labelText: 'Yatırım Kategorisi', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Borsa İstanbul', child: Text('Borsa İstanbul')),
                    DropdownMenuItem(value: 'ABD Borsaları', child: Text('ABD Borsaları')),
                    DropdownMenuItem(value: 'Kripto Para', child: Text('Kripto Para')),
                    DropdownMenuItem(value: 'Diğer Yatırımlar', child: Text('Diğer Yatırımlar')),
                  ],
                  onChanged: (val) => setState(() => _investmentCategory = val!),
                )
              else
                TextFormField(
                  controller: _balanceController,
                  decoration: InputDecoration(labelText: 'Başlangıç Bakiyesi', border: OutlineInputBorder(), prefixText: _currency == 'USD' ? '\$ ' : '₺ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: isLoading ? const CircularProgressIndicator() : const Text('Oluştur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}