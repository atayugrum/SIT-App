// File: lib/src/presentation/screens/savings/manual_save_form_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/savings_providers.dart';

class ManualSaveFormScreen extends ConsumerStatefulWidget {
  const ManualSaveFormScreen({super.key});

  @override
  ConsumerState<ManualSaveFormScreen> createState() =>
      _ManualSaveFormScreenState();
}

class _ManualSaveFormScreenState
    extends ConsumerState<ManualSaveFormScreen> {
  final _amountCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
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

  void _pickDate() {
    DateTime temp = _selectedDate;
    showCupertinoModalPopup(
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
                      style:
                          TextStyle(color: AppColors.textSecondary)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text('Tarih Seç',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                CupertinoButton(
                  child: const Text('Uygula',
                      style:
                          TextStyle(color: AppColors.primaryBlue)),
                  onPressed: () {
                    setState(() => _selectedDate = temp);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(2000),
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(
        _amountCtrl.text.replaceAll(',', '.').trim());
    if (amount == null || amount <= 0) {
      _showAlert('Lütfen geçerli bir tutar girin.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref
          .read(savingsAllocationsProvider.notifier)
          .addManualSaving(amount: amount, date: _selectedDate);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _showAlert(
            'Hata: ${e.toString().replaceFirst("Exception: ", "")}');
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
    final dateLabel =
        DateFormat('dd MMM yyyy', 'tr').format(_selectedDate);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Kumbaraya Manuel Ekle'),
        backgroundColor: Color(0xCC000000),
        border: Border(
            bottom:
                BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Kaydedilecek Tutar',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[\d,.]')),
              ],
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text('₺ ',
                    style: TextStyle(color: AppColors.textPrimary)),
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
            const Text('Tasarruf Tarihi',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
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
                        style: const TextStyle(
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                  : const Text('Kumbaraya Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
