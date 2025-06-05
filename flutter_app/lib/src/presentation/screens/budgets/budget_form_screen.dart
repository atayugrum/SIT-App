// File: lib/src/presentation/screens/budgets/budget_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/budget_model.dart';
import '../../providers/budget_providers.dart';
// import '../../providers/category_providers.dart'; // Artık doğrudan izlemiyoruz, kategorileri expenseCategories'den alacağız
// import '../../../data/models/user_category_model.dart'; // Kaldırıldı
import '../../../core/categories.dart'; // Önceden tanımlanmış kategoriler için

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
  // _selectedPeriod, bütçenin hangi yıl ve ay için olduğunu tutar.
  late DateTime _selectedPeriod; 

  bool get _isEditMode => widget.budgetToEdit != null;

  // Bütçe için kullanılabilir kategorileri (şimdilik sadece harcama) birleştir
  List<String> _getAvailableExpenseCategories(WidgetRef ref) {
    final predefined = List<String>.from(expenseCategories.keys);
    // final customAsync = ref.watch(expenseCustomCategoriesProvider); // Dinamik yükleme için izle
    // customAsync.whenData((customList) {
    //   for (var catModel in customList) {
    //     if (!predefined.contains(catModel.categoryName) && !catModel.isArchived) {
    //       predefined.add(catModel.categoryName);
    //     }
    //   }
    // });
    // Şimdilik sadece predefined kullanalım, asyncCustomCategories senkronizasyonu zorlaştırıyor.
    // TODO: Custom kategorileri de senkron ve düzgün bir şekilde buraya dahil et.
    predefined.sort();
    return predefined;
  }


  @override
  void initState() {
    super.initState();
    _limitAmountController = TextEditingController();

    if (_isEditMode && widget.budgetToEdit != null) {
      final budget = widget.budgetToEdit!;
      _selectedCategory = budget.category;
      _limitAmountController.text = budget.limitAmount.toStringAsFixed(0);
      _selectedPeriod = DateTime(budget.year, budget.month);
    } else {
      // Yeni bütçe için, BudgetOverviewScreen'deki seçili periyodu veya varsayılanı al
      _selectedPeriod = ref.read(budgetPeriodProvider); 
    }
  }

  @override
  void dispose() {
    _limitAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickPeriod(BuildContext context) async {
    final DateTime initialDateForYearPicker = _selectedPeriod;
    
    final DateTime? pickedYear = await showDatePicker(
      context: context,
      initialDate: initialDateForYearPicker,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT BUDGET YEAR',
    );

    if (pickedYear != null && mounted) {
      final DateTime initialDateForMonthPicker = DateTime(pickedYear.year, _selectedPeriod.month);
      
      final DateTime? pickedMonth = await showDatePicker(
          context: context,
          initialDate: initialDateForMonthPicker,
          firstDate: DateTime(pickedYear.year, 1),
          lastDate: DateTime(pickedYear.year, 12),
          initialEntryMode: DatePickerEntryMode.input,
          fieldLabelText: 'Month (1-12)',
          fieldHintText: 'MM',
          helpText: 'SELECT BUDGET MONTH',
      );
        
      if (pickedMonth != null && mounted) {
          setState(() {
              _selectedPeriod = DateTime(pickedYear.year, pickedMonth.month);
          });
      }
    }
  }


  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final limitAmount = double.tryParse(_limitAmountController.text.trim());
    if (limitAmount == null || limitAmount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid positive limit amount.'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (_selectedCategory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a category.'), backgroundColor: Colors.red),
          );
        }
        return;
    }

    final budgetNotifier = ref.read(budgetNotifierProvider.notifier);
    
    // Check if a budget for this category and period already exists (only for create mode)
    if (!_isEditMode) {
        final existingBudgetsAsync = ref.read(budgetsProvider);
        if (existingBudgetsAsync.hasValue) {
            final existingBudgets = existingBudgetsAsync.value!;
            bool alreadyExists = existingBudgets.any((b) => 
                b.category == _selectedCategory && 
                b.year == _selectedPeriod.year && 
                b.month == _selectedPeriod.month);
            if (alreadyExists) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('A budget for "${_selectedCategory}" already exists for ${DateFormat.yMMMM().format(_selectedPeriod)}. Please edit the existing one.'), backgroundColor: Colors.orange),
                  );
                }
                return;
            }
        }
    }


    try {
      await budgetNotifier.createOrUpdateBudget(
        budgetId: _isEditMode ? widget.budgetToEdit!.id : null,
        category: _selectedCategory!,
        limitAmount: limitAmount,
        year: _selectedPeriod.year,
        month: _selectedPeriod.month,
        // isAuto: _isEditMode ? widget.budgetToEdit!.isAuto : false, // Backend upsert'ü isAuto'yu false yapar
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Budget ${_isEditMode ? "updated" : "saved"} successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true); // Başarı durumunu bir önceki ekrana bildir
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving budget: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Get available categories (predefined expense + custom expense)
    // Note: This approach for custom categories list might not be perfectly reactive if custom categories are added while this form is open.
    // A better approach would be to watch a combined provider. For now, it fetches once.
    final List<String> availableCategories = _getAvailableExpenseCategories(ref);


    final budgetOperationState = ref.watch(budgetNotifierProvider);
    final isLoading = budgetOperationState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Budget' : 'Add Budget'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Budget For:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(DateFormat.yMMMM().format(_selectedPeriod)),
                onPressed: () => _pickPeriod(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: theme.textTheme.titleMedium,
                  side: BorderSide(color: theme.dividerColor),
                ),
              ),
              const SizedBox(height: 20),

              Text('Category (Expense):', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  hintText: 'Choose an expense category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                isExpanded: true,
                items: availableCategories.map((String categoryName) {
                  return DropdownMenuItem<String>(
                    value: categoryName,
                    child: Text(categoryName),
                  );
                }).toList(),
                onChanged: _isEditMode ? null : (String? newValue) { 
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 20),

              Text('Limit Amount:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _limitAmountController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Limit',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  prefixText: '₺ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a limit amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: isLoading 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.save_alt_outlined),
                label: Text(_isEditMode ? 'Update Budget' : 'Save Budget'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
                ),
                onPressed: isLoading ? null : _saveBudget,
              ),
            ],
          ),
        ),
      ),
    );
  }
}