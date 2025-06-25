// File: lib/src/presentation/screens/budgets/budget_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/budget_model.dart';
import '../../../data/models/budget_suggestion_model.dart';
import '../../../presentation/providers/budget_providers.dart';
import '../../../presentation/providers/ai_providers.dart';
import '../../../core/categories.dart';
import '../../providers/auth_providers.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  final BudgetModel? budgetToEdit;

  const BudgetFormScreen({super.key, this.budgetToEdit});

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _limitAmountController;
  String? _selectedCategory;
  late DateTime _selectedPeriod;

  bool _isFetchingSuggestion = false;
  bool get _isEditMode => widget.budgetToEdit != null;

  @override
  void initState() {
    super.initState();
    final budget = widget.budgetToEdit;
    _limitAmountController = TextEditingController(
        text: budget?.limitAmount.toStringAsFixed(0) ?? '');
    _selectedCategory = budget?.category;
    _selectedPeriod = _isEditMode
        ? DateTime(budget!.year, budget.month)
        : ref.read(budgetPeriodProvider);
  }

  @override
  void dispose() {
    _limitAmountController.dispose();
    super.dispose();
  }

  Future<void> _getAISuggestion() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce bir kategori seçin.')),
      );
      return;
    }
    setState(() => _isFetchingSuggestion = true);
    try {
      final suggestion =
          await ref.read(budgetSuggestionProvider(_selectedCategory!).future);
      _limitAmountController.text =
          suggestion.suggestedBudget.toStringAsFixed(0);
      if (mounted) _showSuggestionDialog(suggestion);
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().contains("422")
            ? "Size özel bir bütçe önerebilmemiz için en az 90 günlük harcama verisi gereklidir."
            : e.toString().replaceFirst("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hata: $errorMessage'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingSuggestion = false);
    }
  }

  void _showSuggestionDialog(BudgetSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI Bütçe Önerisi'),
        content: SingleChildScrollView(child: Text(suggestion.rationale)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Anladım'))
        ],
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(userIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kullanıcı oturumu bulunamadı.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final newBudget = BudgetModel(
      id: widget.budgetToEdit?.id,
      userId: userId,
      category: _selectedCategory!,
      limitAmount: double.parse(_limitAmountController.text),
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
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Hata yönetimi overview ekranındaki listener tarafından yapılıyor.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionState = ref.watch(budgetActionNotifierProvider);
    final isSaving = actionState is AsyncLoading;
    final primaryColor = Colors.teal.shade700;

    // DÜZELTME: Ortak stil burada tanımlanıyor ve aşağıda doğru şekilde kullanılıyor.
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Bütçeyi Düzenle' : 'Yeni Bütçe Oluştur'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Kategori', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: expenseCategories.keys
                    .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: _isEditMode
                    ? null
                    : (v) => setState(() => _selectedCategory = v),
                decoration: inputDecoration.copyWith(
                  hintText: 'Bütçe için bir kategori seçin',
                  filled: _isEditMode,
                  fillColor: Colors.grey.shade200,
                ),
                validator: (v) =>
                    v == null ? 'Lütfen bir kategori seçin' : null,
              ),
              const SizedBox(height: 24),
              Text('Aylık Limit', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _limitAmountController,
                decoration: inputDecoration.copyWith(prefixText: '₺ '),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Lütfen bir limit girin'
                    : null,
              ),
              const SizedBox(height: 20),
              if (!_isEditMode)
                _isFetchingSuggestion
                    ? const Center(
                        child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator()))
                    : FilledButton.tonalIcon(
                        onPressed: _getAISuggestion,
                        icon: const Icon(Icons.lightbulb_outline,
                            color: Colors.orangeAccent),
                        label: const Text('AI ile Öneri Al'),
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor:
                                Colors.teal.shade50.withOpacity(0.5)),
                      ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isSaving ? null : _saveBudget,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.white))
                    : Text(_isEditMode
                        ? 'Güncellemeyi Kaydet'
                        : 'Bütçeyi Oluştur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
