// File: lib/src/presentation/screens/accounts/account_form_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/account_model.dart';
import '../../providers/account_providers.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final AccountModel? accountToEdit;
  const AccountFormScreen({super.key, this.accountToEdit});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _limitCtrl;
  late final TextEditingController _statementDayCtrl;
  late final TextEditingController _dueDateDayCtrl;

  String _accountType = 'bank';
  String _currency = 'TRY';
  String _investmentCategory = 'Borsa İstanbul';

  bool get _isEditMode => widget.accountToEdit != null;

  @override
  void initState() {
    super.initState();
    final acc = widget.accountToEdit;
    _nameCtrl = TextEditingController(text: acc?.accountName ?? '');
    _balanceCtrl = TextEditingController(
        text: acc != null ? acc.initialBalance.toString() : '0');
    _limitCtrl =
        TextEditingController(text: acc?.creditLimit?.toString() ?? '');
    _statementDayCtrl =
        TextEditingController(text: acc?.statementDay?.toString() ?? '');
    _dueDateDayCtrl =
        TextEditingController(text: acc?.dueDateDay?.toString() ?? '');
    if (_isEditMode) {
      _accountType = acc!.accountType;
      _currency = acc.currency;
      _investmentCategory = acc.category ?? 'Borsa İstanbul';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _limitCtrl.dispose();
    _statementDayCtrl.dispose();
    _dueDateDayCtrl.dispose();
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

  void _pickCurrency() {
    if (_isEditMode) return;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Para Birimi'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _currency = 'TRY');
              Navigator.of(context).pop();
            },
            child: const Text('Türk Lirası (TRY)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _currency = 'USD');
              Navigator.of(context).pop();
            },
            child: const Text('ABD Doları (USD)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
      ),
    );
  }

  void _pickAccountType() {
    if (_isEditMode) return;
    final options = [
      ('bank', 'Banka Hesabı'),
      ('cash', 'Nakit'),
      ('credit_card', 'Kredi Kartı'),
      ('e_wallet', 'E-Cüzdan'),
      ('investment', 'Yatırım Hesabı'),
    ];
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Hesap Tipi'),
        actions: options
            .map((opt) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _accountType = opt.$1);
                    Navigator.of(context).pop();
                  },
                  child: Text(opt.$2),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
      ),
    );
  }

  void _pickInvestmentCategory() {
    final options = [
      'Borsa İstanbul',
      'ABD Borsaları',
      'Kripto Para',
      'Diğer Yatırımlar',
    ];
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Yatırım Kategorisi'),
        actions: options
            .map((cat) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _investmentCategory = cat);
                    Navigator.of(context).pop();
                  },
                  child: Text(cat),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showAlert('Lütfen bir hesap adı girin.');
      return;
    }

    final Map<String, dynamic> data = {
      'accountName': name,
      'accountType': _accountType,
      'currency': _currency,
    };

    if (_accountType == 'investment') {
      data['category'] = _investmentCategory;
    } else if (_accountType == 'credit_card') {
      data['initialBalance'] =
          double.tryParse(_balanceCtrl.text) ?? 0.0;
      final limit = double.tryParse(_limitCtrl.text) ?? 0.0;
      if (limit <= 0) {
        _showAlert('Lütfen geçerli bir kart limiti girin.');
        return;
      }
      data['creditLimit'] = limit;
      data['statementDay'] =
          int.tryParse(_statementDayCtrl.text) ?? 1;
      data['dueDateDay'] =
          int.tryParse(_dueDateDayCtrl.text) ?? 10;
    } else {
      data['initialBalance'] =
          double.tryParse(_balanceCtrl.text) ?? 0.0;
    }

    try {
      final notifier = ref.read(accountsProvider.notifier);
      if (_isEditMode) {
        await notifier.updateAccount(widget.accountToEdit!.id, data);
      } else {
        await notifier.createAccount(data);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showAlert('Hata: $e');
    }
  }

  BoxDecoration get _fieldDecor => BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      );

  Widget _pickerRow(
      String label, String value, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: _fieldDecor,
        child: Row(
          children: [
            Expanded(
              child: Text(value,
                  style: TextStyle(
                    color: onTap != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  )),
            ),
            if (onTap != null)
              const Icon(CupertinoIcons.chevron_right,
                  color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  String _accountTypeLabel(String type) {
    switch (type) {
      case 'bank':
        return 'Banka Hesabı';
      case 'cash':
        return 'Nakit';
      case 'credit_card':
        return 'Kredi Kartı';
      case 'e_wallet':
        return 'E-Cüzdan';
      case 'investment':
        return 'Yatırım Hesabı';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(accountsProvider).isLoading;
    final currencySymbol = _currency == 'USD' ? '\$ ' : '₺ ';

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditMode ? 'Hesabı Düzenle' : 'Yeni Hesap'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom:
                BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Hesap Adı',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _nameCtrl,
              placeholder: 'Örn: Ziraat Bankası',
              placeholderStyle:
                  const TextStyle(color: AppColors.textSecondary),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecor,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            const SizedBox(height: 16),
            const Text('Para Birimi',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            _pickerRow(
              'Para Birimi',
              _currency == 'TRY'
                  ? 'Türk Lirası (TRY)'
                  : 'ABD Doları (USD)',
              _isEditMode ? null : _pickCurrency,
            ),
            const SizedBox(height: 16),
            const Text('Hesap Tipi',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            _pickerRow(
              'Hesap Tipi',
              _accountTypeLabel(_accountType),
              _isEditMode ? null : _pickAccountType,
            ),
            const SizedBox(height: 16),
            if (_accountType == 'investment') ...[
              const Text('Yatırım Kategorisi',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              _pickerRow(
                'Yatırım Kategorisi',
                _investmentCategory,
                _pickInvestmentCategory,
              ),
            ] else if (_accountType == 'credit_card') ...[
              const Text('Mevcut Borç Tutarı',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(currencySymbol,
                      style: const TextStyle(
                          color: AppColors.textPrimary)),
                ),
                placeholder: '0.00',
                placeholderStyle:
                    const TextStyle(color: AppColors.textSecondary),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _fieldDecor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
              const SizedBox(height: 16),
              const Text('Toplam Kart Limiti',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _limitCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(currencySymbol,
                      style: const TextStyle(
                          color: AppColors.textPrimary)),
                ),
                placeholder: '0.00',
                placeholderStyle:
                    const TextStyle(color: AppColors.textSecondary),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _fieldDecor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kesim Günü',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _statementDayCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          placeholder: '1',
                          placeholderStyle: const TextStyle(
                              color: AppColors.textSecondary),
                          style: const TextStyle(
                              color: AppColors.textPrimary),
                          decoration: _fieldDecor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Son Ödeme',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _dueDateDayCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          placeholder: '10',
                          placeholderStyle: const TextStyle(
                              color: AppColors.textSecondary),
                          style: const TextStyle(
                              color: AppColors.textPrimary),
                          decoration: _fieldDecor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                _isEditMode
                    ? 'Başlangıç Bakiyesi (Değiştirilemez)'
                    : 'Başlangıç Bakiyesi',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _balanceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                readOnly: _isEditMode,
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(currencySymbol,
                      style: const TextStyle(
                          color: AppColors.textPrimary)),
                ),
                placeholder: '0.00',
                placeholderStyle:
                    const TextStyle(color: AppColors.textSecondary),
                style: TextStyle(
                    color: _isEditMode
                        ? AppColors.textSecondary
                        : AppColors.textPrimary),
                decoration: _fieldDecor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ],
            const SizedBox(height: 32),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                  : Text(_isEditMode
                      ? 'Değişiklikleri Kaydet'
                      : 'Hesabı Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
