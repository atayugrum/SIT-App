// File: lib/src/presentation/screens/budgets/budget_form_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/categories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/budget_suggestion_model.dart';
import '../../providers/ai_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/budget_providers.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  final BudgetModel? budgetToEdit;
  const BudgetFormScreen({super.key, this.budgetToEdit});

  @override
  ConsumerState<BudgetFormScreen> createState() =>
      _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  late final TextEditingController _limitCtrl;
  String? _selectedCategory;
  late DateTime _selectedPeriod;
  bool _isFetchingSuggestion = false;

  bool get _isEditMode => widget.budgetToEdit != null;

  @override
  void initState() {
    super.initState();
    final b = widget.budgetToEdit;
    _limitCtrl = TextEditingController(
        text: b?.limitAmount.toStringAsFixed(0) ?? '');
    _selectedCategory = b?.category;
    _selectedPeriod = _isEditMode
        ? DateTime(b!.year, b.month)
        : ref.read(budgetPeriodProvider);
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
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

  void _showSuggestionDialog(BudgetSuggestion suggestion) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('AI Bütçe Önerisi'),
        content: SingleChildScrollView(
            child: Text(suggestion.rationale)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  Future<void> _getAISuggestion() async {
    if (_selectedCategory == null) {
      _showAlert('Lütfen önce bir kategori seçin.');
      return;
    }
    setState(() => _isFetchingSuggestion = true);
    try {
      final suggestion = await ref
          .read(budgetSuggestionProvider(_selectedCategory!).future);
      _limitCtrl.text =
          suggestion.suggestedBudget.toStringAsFixed(0);
      if (mounted) _showSuggestionDialog(suggestion);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('422')
            ? 'Size özel öneri için en az 90 günlük harcama verisi gereklidir.'
            : e.toString().replaceFirst('Exception: ', '');
        _showAlert('Hata: $msg');
      }
    } finally {
      if (mounted) setState(() => _isFetchingSuggestion = false);
    }
  }

  void _pickCategory() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Kategori Seç'),
        actions: expenseCategories.keys
            .map((cat) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _selectedCategory = cat);
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

  Future<void> _saveBudget() async {
    if (_selectedCategory == null) {
      _showAlert('Lütfen bir kategori seçin.');
      return;
    }
    final limit = double.tryParse(_limitCtrl.text.trim());
    if (limit == null || limit <= 0) {
      _showAlert('Lütfen geçerli bir limit girin.');
      return;
    }
    final userId = ref.read(userIdProvider);
    if (userId == null) {
      _showAlert('Kullanıcı oturumu bulunamadı.');
      return;
    }
    final newBudget = BudgetModel(
      id: widget.budgetToEdit?.id,
      userId: userId,
      category: _selectedCategory!,
      limitAmount: limit,
      spentAmount: widget.budgetToEdit?.spentAmount ?? 0.0,
      period: 'monthly',
      year: _selectedPeriod.year,
      month: _selectedPeriod.month,
      createdAt: widget.budgetToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      await ref
          .read(budgetActionNotifierProvider.notifier)
          .createOrUpdateBudget(newBudget);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {}
  }

  BoxDecoration get _fieldDecor => BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      );

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(budgetActionNotifierProvider);
    final isSaving = actionState is AsyncLoading;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
            _isEditMode ? 'Bütçeyi Düzenle' : 'Yeni Bütçe Oluştur'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom:
                BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Category
            const Text('Kategori',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _isEditMode ? null : _pickCategory,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: _fieldDecor,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCategory ??
                            'Bütçe için bir kategori seçin',
                        style: TextStyle(
                          color: _selectedCategory != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (!_isEditMode)
                      const Icon(CupertinoIcons.chevron_down,
                          color: AppColors.textSecondary, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Limit amount
            const Text('Aylık Limit',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _limitCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
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

            // AI suggestion
            if (!_isEditMode)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed:
                    _isFetchingSuggestion ? null : _getAISuggestion,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryBlue, width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isFetchingSuggestion)
                        const CupertinoActivityIndicator()
                      else
                        const Icon(CupertinoIcons.sparkles,
                            color: AppColors.primaryBlue, size: 18),
                      const SizedBox(width: 8),
                      const Text('AI ile Öneri Al',
                          style: TextStyle(
                              color: AppColors.primaryBlue)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Save
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: isSaving ? null : _saveBudget,
              child: isSaving
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                  : Text(_isEditMode
                      ? 'Güncellemeyi Kaydet'
                      : 'Bütçeyi Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
