// File: lib/src/presentation/screens/savings/savings_goal_form_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/savings_goal_model.dart';
import '../../providers/savings_providers.dart';

class SavingsGoalFormScreen extends ConsumerStatefulWidget {
  final SavingsGoalModel? goalToEdit;
  const SavingsGoalFormScreen({super.key, this.goalToEdit});

  @override
  ConsumerState<SavingsGoalFormScreen> createState() =>
      _SavingsGoalFormScreenState();
}

class _SavingsGoalFormScreenState
    extends ConsumerState<SavingsGoalFormScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  DateTime? _targetDate;

  bool get _isEditMode => widget.goalToEdit != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goalToEdit;
    _titleCtrl = TextEditingController(text: g?.title ?? '');
    _amountCtrl = TextEditingController(
        text: g != null ? g.targetAmount.toStringAsFixed(0) : '');
    _targetDate = g?.targetDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
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
    final initial = _targetDate ??
        DateTime.now().add(const Duration(days: 30));
    DateTime temp = initial;
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
                const Text('Hedef Tarihi',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                CupertinoButton(
                  child: const Text('Uygula',
                      style:
                          TextStyle(color: AppColors.primaryBlue)),
                  onPressed: () {
                    setState(() => _targetDate = temp);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                minimumDate: DateTime.now(),
                maximumDate:
                    DateTime.now().add(const Duration(days: 365 * 10)),
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _showAlert('Lütfen bir başlık girin.');
      return;
    }
    final amount = double.tryParse(
        _amountCtrl.text.replaceAll(',', '.').trim());
    if (amount == null || amount <= 0) {
      _showAlert('Lütfen geçerli bir hedef tutar girin.');
      return;
    }
    if (_targetDate == null) {
      _showAlert('Lütfen bir hedef tarihi seçin.');
      return;
    }
    try {
      if (_isEditMode) {
        // Update not yet implemented in service
      } else {
        await ref
            .read(savingsGoalNotifierProvider.notifier)
            .createGoal(
              title: title,
              targetAmount: amount,
              targetDate: _targetDate!,
            );
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

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(savingsGoalNotifierProvider).isLoading;
    final dateLabel = _targetDate == null
        ? 'Tarih Seçilmedi'
        : DateFormat.yMMMd('tr_TR').format(_targetDate!);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditMode
            ? 'Hedefi Düzenle'
            : 'Yeni Tasarruf Hedefi'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom:
                BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Hedef Adı',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _titleCtrl,
              placeholder: 'Örn: Tatil Fonu',
              placeholderStyle:
                  const TextStyle(color: AppColors.textSecondary),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecor,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            const SizedBox(height: 16),
            const Text('Hedef Tutar',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text('₺ ',
                    style: TextStyle(color: AppColors.textPrimary)),
              ),
              placeholder: '0',
              placeholderStyle:
                  const TextStyle(color: AppColors.textSecondary),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecor,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            const SizedBox(height: 16),
            const Text('Hedef Tarihi',
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
                        style: TextStyle(
                          color: _targetDate != null
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
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
