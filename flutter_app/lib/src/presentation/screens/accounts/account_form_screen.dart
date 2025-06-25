// File: lib/src/presentation/screens/accounts/account_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/account_model.dart';
import '../../providers/account_providers.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final AccountModel? accountToEdit;
  const AccountFormScreen({super.key, this.accountToEdit});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _limitController;
  late TextEditingController _statementDayController;
  late TextEditingController _dueDateDayController;

  String _accountType = 'bank';
  String _currency = 'TRY';
  String _investmentCategory = 'Borsa İstanbul';

  bool get _isEditMode => widget.accountToEdit != null;

  @override
  void initState() {
    super.initState();
    final acc = widget.accountToEdit;

    _nameController = TextEditingController(text: acc?.accountName ?? '');
    _balanceController =
        TextEditingController(text: acc?.initialBalance.toString() ?? '0');
    _limitController =
        TextEditingController(text: acc?.creditLimit?.toString() ?? '');
    _statementDayController =
        TextEditingController(text: acc?.statementDay?.toString() ?? '');
    _dueDateDayController =
        TextEditingController(text: acc?.dueDateDay?.toString() ?? '');

    if (_isEditMode) {
      _accountType = acc!.accountType;
      _currency = acc.currency;
      _investmentCategory = acc.category ?? 'Borsa İstanbul';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _limitController.dispose();
    _statementDayController.dispose();
    _dueDateDayController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, dynamic> accountData = {
      'accountName': _nameController.text.trim(),
      'accountType': _accountType,
      'currency': _currency,
    };

    if (_accountType == 'investment') {
      accountData['category'] = _investmentCategory;
    } else if (_accountType == 'credit_card') {
      accountData['creditLimit'] =
          double.tryParse(_limitController.text) ?? 0.0;
      accountData['statementDay'] =
          int.tryParse(_statementDayController.text) ?? 1;
      accountData['dueDateDay'] =
          int.tryParse(_dueDateDayController.text) ?? 10;
      accountData['initialBalance'] =
          double.tryParse(_balanceController.text) ?? 0.0;
    } else {
      accountData['initialBalance'] =
          double.tryParse(_balanceController.text) ?? 0.0;
    }

    try {
      final notifier = ref.read(accountsProvider.notifier);
      if (_isEditMode) {
        await notifier.updateAccount(widget.accountToEdit!.id, accountData);
      } else {
        await notifier.createAccount(accountData);
      }
      if (mounted) {
        final message =
            'Hesap başarıyla ${_isEditMode ? 'güncellendi' : 'oluşturuldu'}!';
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(accountsProvider).isLoading;
    final primaryColor = Colors.teal.shade700;
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2)),
    );

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditMode ? 'Hesabı Düzenle' : 'Yeni Hesap Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: inputDecoration.copyWith(labelText: 'Hesap Adı'),
                validator: (val) =>
                    val!.isEmpty ? 'Lütfen bir isim girin' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: inputDecoration.copyWith(labelText: 'Para Birimi'),
                items: const [
                  DropdownMenuItem(
                      value: 'TRY', child: Text('Türk Lirası (TRY)')),
                  DropdownMenuItem(
                      value: 'USD', child: Text('ABD Doları (USD)')),
                ],
                onChanged: _isEditMode
                    ? null
                    : (val) => setState(() => _currency = val!),
                disabledHint: _isEditMode ? Text(_currency) : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _accountType,
                decoration: inputDecoration.copyWith(labelText: 'Hesap Tipi'),
                items: const [
                  DropdownMenuItem(value: 'bank', child: Text('Banka Hesabı')),
                  DropdownMenuItem(value: 'cash', child: Text('Nakit')),
                  DropdownMenuItem(
                      value: 'credit_card', child: Text('Kredi Kartı')),
                  DropdownMenuItem(value: 'e_wallet', child: Text('E-Cüzdan')),
                  DropdownMenuItem(
                      value: 'investment', child: Text('Yatırım Hesabı')),
                ],
                onChanged: _isEditMode
                    ? null
                    : (val) => setState(() => _accountType = val!),
                disabledHint: _isEditMode ? Text(_accountType) : null,
              ),
              const SizedBox(height: 16),
              if (_accountType == 'investment')
                DropdownButtonFormField<String>(
                  value: _investmentCategory,
                  decoration:
                      inputDecoration.copyWith(labelText: 'Yatırım Kategorisi'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Borsa İstanbul', child: Text('Borsa İstanbul')),
                    DropdownMenuItem(
                        value: 'ABD Borsaları', child: Text('ABD Borsaları')),
                    DropdownMenuItem(
                        value: 'Kripto Para', child: Text('Kripto Para')),
                    DropdownMenuItem(
                        value: 'Diğer Yatırımlar',
                        child: Text('Diğer Yatırımlar')),
                  ],
                  onChanged: (val) =>
                      setState(() => _investmentCategory = val!),
                )
              else if (_accountType == 'credit_card')
                Column(
                  children: [
                    TextFormField(
                      controller: _balanceController,
                      decoration: inputDecoration.copyWith(
                          labelText: 'Mevcut Borç Tutarı',
                          prefixText: _currency == 'USD' ? '\$ ' : '₺ '),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _limitController,
                      decoration: inputDecoration.copyWith(
                          labelText: 'Toplam Kart Limiti',
                          prefixText: _currency == 'USD' ? '\$ ' : '₺ '),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                          ? 'Lütfen geçerli bir limit girin'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                                controller: _statementDayController,
                                decoration: inputDecoration.copyWith(
                                    labelText: 'Kesim Günü'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2)
                            ])),
                        const SizedBox(width: 16),
                        Expanded(
                            child: TextFormField(
                                controller: _dueDateDayController,
                                decoration: inputDecoration.copyWith(
                                    labelText: 'Son Ödeme'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2)
                            ])),
                      ],
                    )
                  ],
                )
              else
                TextFormField(
                  controller: _balanceController,
                  decoration: inputDecoration.copyWith(
                      labelText: _isEditMode
                          ? 'Başlangıç Bakiyesi (Değiştirilemez)'
                          : 'Başlangıç Bakiyesi',
                      prefixText: _currency == 'USD' ? '\$ ' : '₺ '),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  readOnly: _isEditMode,
                  enabled: !_isEditMode,
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white))
                    : Text(_isEditMode
                        ? 'Değişiklikleri Kaydet'
                        : 'Hesabı Oluştur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
