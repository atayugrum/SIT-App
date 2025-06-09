// File: lib/src/presentation/screens/budgets/budget_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/budget_model.dart';
import '../../../data/models/budget_suggestion_model.dart';
import '../../../presentation/providers/budget_providers.dart';
import '../../../presentation/providers/ai_providers.dart';
import '../../../core/categories.dart';
import '../../../presentation/providers/auth_providers.dart';


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
    _limitAmountController = TextEditingController(text: budget?.limitAmount.toStringAsFixed(0) ?? '');
    _selectedCategory = budget?.category;
    _selectedPeriod = _isEditMode ? DateTime(budget!.year, budget.month) : ref.read(budgetPeriodProvider);
  }

  @override
  void dispose() {
    _limitAmountController.dispose();
    super.dispose();
  }

  Future<void> _getAISuggestion() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen önce bir kategori seçin.'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isFetchingSuggestion = true);
    try {
      // DÜZELTME: Provider doğru şekilde çağrılıyor.
      final suggestion = await ref.read(budgetSuggestionProvider(_selectedCategory!).future);
      if (mounted) _showSuggestionDialog(suggestion);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isFetchingSuggestion = false);
    }
  }

  void _showSuggestionDialog(BudgetSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yapay Zeka Önerisi'),
        content: Text(suggestion.rationale),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              _limitAmountController.text = suggestion.suggestedBudget.toStringAsFixed(0);
              Navigator.of(context).pop();
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    final limitAmount = double.tryParse(_limitAmountController.text.trim());
    if (limitAmount == null || limitAmount <= 0) return;

    final userId = ref.read(userIdProvider);
    if (userId == null) return;

    final budgetToSave = BudgetModel(
      id: widget.budgetToEdit?.id,
      userId: userId,
      category: _selectedCategory!,
      limitAmount: limitAmount,
      year: _selectedPeriod.year,
      month: _selectedPeriod.month,
      period: 'monthly',
      isAuto: false, // Manuel işlem her zaman isAuto=false
      createdAt: widget.budgetToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    try {
      await ref.read(budgetActionNotifierProvider.notifier).createOrUpdateBudget(budgetToSave);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bütçe kaydedildi!'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = expenseCategories.keys.toList()..sort();
    final actionState = ref.watch(budgetActionNotifierProvider);
    final isSaving = actionState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Bütçeyi Düzenle' : 'Yeni Bütçe Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ... (Dropdown ve TextFormField'lar aynı, bir önceki yanıttaki gibi)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                items: availableCategories.map((String cat) => DropdownMenuItem<String>(value: cat, child: Text(cat))).toList(),
                onChanged: _isEditMode ? null : (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Lütfen kategori seçin' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _limitAmountController,
                decoration: const InputDecoration(labelText: 'Aylık Limit', border: OutlineInputBorder(), prefixText: '₺ '),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Lütfen bir limit girin' : null,
              ),
              const SizedBox(height: 16),
              if (!_isEditMode)
                _isFetchingSuggestion
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                  : OutlinedButton.icon(
                      onPressed: _getAISuggestion,
                      icon: const Icon(Icons.lightbulb_outline, color: Colors.orangeAccent),
                      label: const Text('AI Önerisi Al'),
                    ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                label: Text(_isEditMode ? 'Güncelle' : 'Kaydet'),
                onPressed: isSaving ? null : _saveBudget,
              ),
            ],
          ),
        ),
      ),
    );
  }
}