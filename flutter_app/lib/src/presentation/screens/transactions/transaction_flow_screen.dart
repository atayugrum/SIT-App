// File: lib/src/presentation/screens/transactions/transaction_flow_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_form_provider.dart';
import '../../../core/categories.dart';
import '../../providers/transaction_providers.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/account_providers.dart';
import '../../providers/auth_providers.dart';
import '../../../data/models/user_category_model.dart';
import '../../providers/category_providers.dart';

class TransactionFlowScreen extends ConsumerStatefulWidget {
  final TransactionModel? transactionToEdit;

  const TransactionFlowScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<TransactionFlowScreen> createState() =>
      _TransactionFlowScreenState();
}

class _TransactionFlowScreenState extends ConsumerState<TransactionFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final GlobalKey<FormState> _detailsFormKey = GlobalKey<FormState>();
  bool _isSaving = false;

  bool get _isEditMode => widget.transactionToEdit != null;

  List<Widget> _buildSteps(
      TransactionFormData formData, VoidCallback goToNextPage) {
    // sabit key, artık date bazlı rebuild yapmıyor
    const detailsStepKey = ValueKey('detailsStep_flow');

    return <Widget>[
      _TransactionTypeSelectionStep(
        key: const ValueKey('typeStep_flow'),
        selectedType: formData.type,
        onTypeSelected: (type) {
          ref.read(transactionFormNotifierProvider.notifier).updateType(type);
          goToNextPage();
        },
      ),
      _CategorySelectionStep(
        key: ValueKey('categoryStep_flow_${formData.type}'),
        transactionType: formData.type,
        selectedCategory: formData.category,
        onCategorySelected: (category) {
          ref
              .read(transactionFormNotifierProvider.notifier)
              .updateCategory(category);
          goToNextPage();
        },
      ),
      _SubCategorySelectionStep(
        key: ValueKey('subCategoryStep_flow_${formData.category ?? "none"}'),
        transactionType: formData.type,
        mainCategoryName: formData.category,
        selectedSubCategory: formData.subCategory,
        onSubCategorySelected: (subCategory) {
          ref
              .read(transactionFormNotifierProvider.notifier)
              .updateSubCategory(subCategory);
          goToNextPage();
        },
        onProceedWithoutSubcategory: () {
          ref
              .read(transactionFormNotifierProvider.notifier)
              .updateSubCategory(null);
          goToNextPage();
        },
      ),
      _DetailsEntryStep(
        key: detailsStepKey,
        formKey: _detailsFormKey,
        initialFormData: formData,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(transactionFormNotifierProvider.notifier);
      if (_isEditMode) {
        notifier.loadTransactionForEdit(widget.transactionToEdit!);
      } else {
        notifier.reset();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    if (!mounted) return;
    setState(() {
      _currentPage = page;
    });
  }

  void _goToNextPage() {
    final formData = ref.read(transactionFormNotifierProvider);
    final steps = _buildSteps(formData, _goToNextPage);

    bool canProceed = true;
    String validationMessage = '';

    if (_currentPage == 0 && formData.type.isEmpty) {
      canProceed = false;
      validationMessage = 'Please select a transaction type.';
    } else if (_currentPage == 1 && formData.category == null) {
      canProceed = false;
      validationMessage = 'Please select a category.';
    }

    if (!canProceed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationMessage),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    if (_pageController.hasClients && _currentPage < steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _goToPreviousPage() async {
    if (_pageController.hasClients && _currentPage > 0) {
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleSave({bool addAnother = false}) async {
    final steps =
        _buildSteps(ref.read(transactionFormNotifierProvider), _goToNextPage);
    if (_currentPage != steps.length - 1) return;

    if (!_detailsFormKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please correct errors in the form.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    _detailsFormKey.currentState!.save();

    if (mounted) setState(() => _isSaving = true);

    // debug: kaydetmeden önce formData.amount
    final formData = ref.read(transactionFormNotifierProvider);
    debugPrint('[FORM DATA] amount = ${formData.amount}');

    final notifier = ref.read(transactionFormNotifierProvider.notifier);
    final modelToSave = notifier.toTransactionModel();
    if (modelToSave == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form data is incomplete. Cannot save.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    try {
      if (_isEditMode) {
        await ref
            .read(transactionsProvider.notifier)
            .updateTransactionInList(modelToSave.id!, modelToSave);
      } else {
        await ref.read(transactionsProvider.notifier).addTransaction(modelToSave);
      }

      if (mounted) {
        // unused_result uyarısını çözmek için atama yapıyoruz
        ref.invalidate(accountsProvider);


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transaction ${_isEditMode ? "updated" : "saved"}!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        if (addAnother && modelToSave.type == 'expense' && !_isEditMode) {
          notifier.partialResetForNewEntry(
            originalType: modelToSave.type,
            originalDate: modelToSave.date,
            originalAccount: modelToSave.account,
            originalCategory: modelToSave.category,
            originalSubCategory: modelToSave.subCategory,
          );
        } else {
          notifier.reset();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formData = ref.watch(transactionFormNotifierProvider);
    final steps = _buildSteps(formData, _goToNextPage);
    final theme = Theme.of(context);
    final bool isLastStep = _currentPage == steps.length - 1;
    String appBarTitle = _isEditMode ? 'Edit Transaction' : 'Add Transaction';
    appBarTitle += ' (Step ${_currentPage + 1}/${steps.length})';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: _isSaving ? null : _goToPreviousPage,
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: steps,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0)
            .copyWith(bottom: MediaQuery.of(context).padding.bottom + 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // step indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(steps.length, (index) {
                return Container(
                  width: _currentPage == index ? 12 : 8,
                  height: _currentPage == index ? 12 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? theme.primaryColor
                        : Colors.grey.shade400,
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            if (isLastStep)
              Row(
                children: <Widget>[
                  if (formData.type == 'expense' && !_isEditMode)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_circle_outline),
                        label: const Text('Save & Add Another'),
                        onPressed:
                            _isSaving ? null : () => _handleSave(addAnother: true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: theme.colorScheme.primary),
                        ),
                      ),
                    ),
                  if (formData.type == 'expense' && !_isEditMode)
                    const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_isEditMode ? 'Update & Close' : 'Save & Close'),
                      onPressed: _isSaving ? null : () => _handleSave(addAnother: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment:
                    _currentPage > 0 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                children: <Widget>[
                  if (_currentPage > 0)
                    TextButton.icon(
                      icon: const Icon(Icons.navigate_before),
                      label: const Text('Previous'),
                      onPressed: _isSaving ? null : _goToPreviousPage,
                    )
                  else
                    const Spacer(),
                  const Spacer(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Step 1: Transaction Type Selection
class _TransactionTypeSelectionStep extends StatelessWidget {
  final String selectedType;
  final void Function(String) onTypeSelected;

  const _TransactionTypeSelectionStep({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'What kind of transaction?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          _TypeButton(
            key: const ValueKey('incomeButton'),
            label: 'Income',
            icon: Icons.arrow_downward_rounded,
            isSelected: selectedType == 'income',
            onPressed: () => onTypeSelected('income'),
            color: Colors.green.shade600,
          ),
          const SizedBox(height: 20),
          _TypeButton(
            key: const ValueKey('expenseButton'),
            label: 'Expense',
            icon: Icons.arrow_upward_rounded,
            isSelected: selectedType == 'expense',
            onPressed: () => onTypeSelected('expense'),
            color: Colors.red.shade600,
          ),
        ],
      ),
    );
  }
}

// Step 2: Category Selection
class _CategorySelectionStep extends ConsumerWidget {
  final String transactionType;
  final String? selectedCategory;
  final void Function(String) onCategorySelected;

  const _CategorySelectionStep({
    super.key,
    required this.transactionType,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  Future<void> _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    String currentTransactionType,
  ) async {
    final formKey = GlobalKey<FormState>();
    final categoryController = TextEditingController();
    final subcategoriesController = TextEditingController();
    bool isLoading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: Text(
              'Add New ${currentTransactionType == 'income' ? 'Income' : 'Expense'} Category',
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Category Name *'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a category name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: subcategoriesController,
                    decoration: const InputDecoration(
                      labelText: 'Subcategories (Optional)',
                      hintText: 'e.g., Sub1, Sub2',
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => isLoading = true);
                        final user = ref.read(currentUserProvider);
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User not logged in.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setState(() => isLoading = false);
                          return;
                        }
                        final subs = subcategoriesController.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                        final newCat = UserCategoryModel(
                          userId: user.uid,
                          categoryName: categoryController.text.trim(),
                          categoryType: currentTransactionType,
                          subcategories: subs,
                          iconId: 'custom_default_icon',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        try {
                          final provider = currentTransactionType == 'income'
                              ? incomeCustomCategoriesProvider
                              : expenseCustomCategoriesProvider;
                          await ref.read(provider.notifier).addCategory(newCat);
                          ref.invalidate(allCustomCategoriesProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${newCat.categoryName} added!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          onCategorySelected(newCat.categoryName);
                          Navigator.of(ctx).pop();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed: ${e.toString().replaceFirst("Exception: ", "")}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          setState(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Category'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predefined = transactionType == 'income' ? incomeCategories : expenseCategories;
    final asyncCats = transactionType == 'income'
        ? ref.watch(incomeCustomCategoriesProvider)
        : ref.watch(expenseCustomCategoriesProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Select a Category for your ${transactionType == 'income' ? 'Income' : 'Expense'}',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add New Custom Category'),
            onPressed: () => _showAddCategoryDialog(context, ref, transactionType),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: theme.textTheme.labelLarge,
              side: BorderSide(color: theme.primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Or choose from below:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncCats.when(
              data: (customs) {
                final keys = <String>[...predefined.keys, ...customs.map((c) => c.categoryName)];
                final icons = <String, IconData>{}
                  ..addAll(predefined)
                  ..addEntries(customs.map((c) => MapEntry(c.categoryName, Icons.label_outline)));
                final unique = keys.toSet().toList()..sort();
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: unique.length,
                  itemBuilder: (ctx, i) {
                    final name = unique[i];
                    final isSel = name == selectedCategory;
                    return GestureDetector(
                      onTap: () => onCategorySelected(name),
                      child: Card(
                        elevation: isSel ? 6 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSel ? theme.primaryColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        color: isSel
                            ? theme.primaryColor.withOpacity(0.1)
                            : theme.cardColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              icons[name] ?? Icons.help_outline,
                              size: 36,
                              color: isSel
                                  ? theme.primaryColor
                                  : theme.iconTheme.color!.withOpacity(0.7),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? theme.primaryColor : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

// Step 3: Subcategory Selection
class _SubCategorySelectionStep extends ConsumerWidget {
  final String transactionType;
  final String? mainCategoryName;
  final String? selectedSubCategory;
  final void Function(String?) onSubCategorySelected;
  final VoidCallback onProceedWithoutSubcategory;

  const _SubCategorySelectionStep({
    super.key,
    required this.transactionType,
    required this.mainCategoryName,
    this.selectedSubCategory,
    required this.onSubCategorySelected,
    required this.onProceedWithoutSubcategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mainCategoryName == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onProceedWithoutSubcategory();
      });
      return const Center(
        child: Text('No main category selected. Proceeding…'),
      );
    }

    final predefinedSubs = transactionType == 'income' ? incomeSubcategories : expenseSubcategories;
    final subs = <String>[];
    if (predefinedSubs.containsKey(mainCategoryName)) {
      subs.addAll(predefinedSubs[mainCategoryName]!);
    }

    final asyncCats = transactionType == 'income'
        ? ref.watch(incomeCustomCategoriesProvider)
        : ref.watch(expenseCustomCategoriesProvider);

    bool isLoading = true;
    UserCategoryModel? customMain;

    asyncCats.when(
      data: (cats) {
        isLoading = false;
        final found = cats.where((c) => c.categoryName == mainCategoryName && !c.isArchived);
        if (found.isNotEmpty) {
          customMain = found.first;
          for (var s in customMain!.subcategories) {
            if (!subs.contains(s)) subs.add(s);
          }
        }
        subs.sort();
      },
      loading: () => isLoading = true,
      error: (_, __) => isLoading = false,
    );

    if (isLoading && subs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final canAdd = customMain?.id != null;

    if (subs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'No Subcategories for "$mainCategoryName".',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            if (canAdd)
              ElevatedButton.icon(
                onPressed: () => _showAddSubDialog(context, ref, mainCategoryName!),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add First Subcategory'),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onProceedWithoutSubcategory,
              child: const Text('Continue without Subcategory'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Select Subcategory for "$mainCategoryName"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 12),
          if (canAdd)
            OutlinedButton.icon(
              onPressed: () => _showAddSubDialog(context, ref, mainCategoryName!),
              icon: const Icon(Icons.add_circle_outline),
              label: Text("Add New Subcategory"),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: subs.length,
              itemBuilder: (ctx, i) {
                final name = subs[i];
                final sel = name == selectedSubCategory;
                return Card(
                  elevation: sel ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: sel ? Theme.of(context).primaryColor : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      name,
                      style: TextStyle(fontWeight: sel ? FontWeight.bold : FontWeight.normal),
                    ),
                    selected: sel,
                    selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    onTap: () => onSubCategorySelected(name),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onProceedWithoutSubcategory,
            child: const Text('Skip Subcategory'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSubDialog(
      BuildContext context, WidgetRef ref, String mainCatName) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();
    bool loading = false;

    final cats = transactionType == 'income'
        ? ref.read(incomeCustomCategoriesProvider)
        : ref.read(expenseCustomCategoriesProvider);

    UserCategoryModel? target;
    if (cats.hasValue) {
      try {
        target = cats.value!.firstWhere((c) => c.categoryName == mainCatName && !c.isArchived);
      } catch (_) {}
    }
    final can = target?.id != null;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: Text('Add Subcategory to "$mainCatName"'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (!can)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        cats is AsyncLoading
                            ? 'Loading…'
                            : 'Subcategories only for custom categories.',
                        style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                      ),
                    ),
                  TextFormField(
                    controller: ctrl,
                    enabled: can,
                    decoration: const InputDecoration(labelText: 'Name *'),
                    validator: (v) {
                      if (!can) return null;
                      if (v == null || v.trim().isEmpty) return 'Enter name';
                      if (target!.subcategories
                          .map((s) => s.toLowerCase())
                          .contains(v.trim().toLowerCase())) {
                        return '"${v.trim()}" exists.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: loading ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: loading || !can
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => loading = true);
                        final newName = ctrl.text.trim();
                        final updated = [
                          ...target!.subcategories,
                          if (!target.subcategories.map((s) => s.toLowerCase()).contains(newName.toLowerCase()))
                            newName
                        ];
                        final updatedModel = UserCategoryModel(
                          id: target.id!,
                          userId: target.userId,
                          categoryName: target.categoryName,
                          categoryType: target.categoryType,
                          subcategories: updated,
                          iconId: target.iconId,
                          createdAt: target.createdAt,
                          updatedAt: DateTime.now(),
                          isArchived: target.isArchived,
                        );
                        try {
                          final provider = transactionType == 'income'
                              ? incomeCustomCategoriesProvider
                              : expenseCustomCategoriesProvider;
                          await ref.read(provider.notifier).updateCustomCategory(updatedModel);
                          ref.invalidate(allCustomCategoriesProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Subcategory "$newName" added!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          onSubCategorySelected(newName);
                          Navigator.of(ctx).pop();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          setState(() => loading = false);
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }
}

// Step 4: Details Entry
class _DetailsEntryStep extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;
  final TransactionFormData initialFormData;

  const _DetailsEntryStep({
    super.key,
    required this.formKey,
    required this.initialFormData,
  });

  @override
  ConsumerState<_DetailsEntryStep> createState() => _DetailsEntryStepState();
}

class _DetailsEntryStepState extends ConsumerState<_DetailsEntryStep> {
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _recurrenceController;
  late final TextEditingController _incomePctController;

  bool _isRecurring = false;
  bool? _isNeed;
  String? _selectedEmotion;
  String? _selectedAccount;

  final List<String> _emotionList = <String>[
    'Happy',
    'Neutral',
    'Stressed',
    'Guilty',
    'Excited',
    'Sad',
  ];

  @override
  void initState() {
    super.initState();
    final fd = widget.initialFormData;
    _amountController =
        TextEditingController(text: fd.amount?.toStringAsFixed(2) ?? '');
    _dateController =
        TextEditingController(text: DateFormat('yyyy-MM-dd').format(fd.date));
    _descriptionController = TextEditingController(text: fd.description ?? '');
    _recurrenceController =
        TextEditingController(text: fd.recurrenceRule ?? '');
    _incomePctController =
        TextEditingController(text: fd.incomeAllocationPct?.toString() ?? '');

    _isRecurring = fd.isRecurring;
    _isNeed = fd.isNeed;
    _selectedEmotion = fd.emotion;
    _selectedAccount = fd.account;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    _recurrenceController.dispose();
    _incomePctController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final notifier = ref.read(transactionFormNotifierProvider.notifier);
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(transactionFormNotifierProvider).date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      notifier.updateDate(picked);
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txType = ref.watch(transactionFormNotifierProvider.select((d) => d.type));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: widget.formKey,
        child: ListView(
          children: <Widget>[
            Text(
              'Enter Transaction Details',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 24),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                final a = double.tryParse(v.replaceAll(',', '.').trim());
                if (a == null || a <= 0) return 'Valid positive amount';
                return null;
              },
              onChanged: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.').trim());
                debugPrint('[AMOUNT] onChanged → $parsed');
                ref.read(transactionFormNotifierProvider.notifier).updateAmount(parsed);
              },
              onSaved: (v) {
                final parsed = double.tryParse(v?.replaceAll(',', '.').trim() ?? '');
                debugPrint('[AMOUNT] onSaved → $parsed');
                ref.read(transactionFormNotifierProvider.notifier).updateAmount(parsed);
              },
            ),
            const SizedBox(height: 16),

            // Date
            TextFormField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Date',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
              readOnly: true,
              onTap: _pickDate,
              validator: (v) => (v == null || v.isEmpty) ? 'Select date' : null,
            ),
            const SizedBox(height: 16),

            // Account
            Consumer(builder: (ctx, ref, _) {
              final accountsVal = ref.watch(accountsProvider);
              return accountsVal.when(
                data: (accounts) {
                  if (_selectedAccount != null &&
                      !accounts.any((a) => a.accountName == _selectedAccount)) {
                    _selectedAccount = null;
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedAccount,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select an account'),
                    isExpanded: true,
                    items: accounts.map((a) {
                      return DropdownMenuItem<String>(
                        value: a.accountName,
                        child: Text('${a.accountName} (${a.currency})'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedAccount = v),
                    onSaved: (v) => ref.read(transactionFormNotifierProvider.notifier).updateAccount(v),
                    validator: (v) => (v == null) ? 'Please select an account' : null,
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => TextFormField(
                  initialValue: widget.initialFormData.account,
                  decoration: const InputDecoration(
                    labelText: 'Account (Error Loading)',
                    border: OutlineInputBorder(),
                    errorText: 'Could not load accounts',
                  ),
                  onSaved: (v) => ref.read(transactionFormNotifierProvider.notifier).updateAccount(v),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter an account' : null,
                ),
              );
            }),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onSaved: (v) => ref.read(transactionFormNotifierProvider.notifier).updateDescription(v?.trim()),
            ),
            const SizedBox(height: 16),

            // Recurring
            SwitchListTile(
              title: const Text('Repeated Entry?'),
              value: _isRecurring,
              onChanged: (v) {
                setState(() => _isRecurring = v);
                ref.read(transactionFormNotifierProvider.notifier).updateIsRecurring(v);
                if (!v) {
                  _recurrenceController.clear();
                  ref.read(transactionFormNotifierProvider.notifier).updateRecurrenceRule(null);
                }
              },
            ),
            if (_isRecurring) ...<Widget>[
              const SizedBox(height: 8),
              TextFormField(
                controller: _recurrenceController,
                decoration: const InputDecoration(
                  labelText: 'Recurrence Rule (Optional)',
                  hintText: 'e.g., FREQ=MONTHLY',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => ref.read(transactionFormNotifierProvider.notifier).updateRecurrenceRule(v?.trim()),
              ),
              const SizedBox(height: 16),
            ],

            // Income specifics
            if (txType == 'income') ...<Widget>[
              Text('Income Specifics', style: theme.textTheme.titleMedium),
              const Divider(),
              const SizedBox(height: 8),
              TextFormField(
                controller: _incomePctController,
                decoration: const InputDecoration(
                  labelText: 'Allocate to Savings (%)',
                  hintText: '0-100',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final val = int.tryParse(v);
                    if (val == null || val < 0 || val > 100) return 'Must be 0-100';
                  }
                  return null;
                },
                onSaved: (v) => ref.read(transactionFormNotifierProvider.notifier).updateIncomeAllocationPct(
                      v != null && v.isNotEmpty ? int.parse(v) : 0,
                    ),
              ),
              const SizedBox(height: 16),
            ],

            // Expense specifics
            if (txType == 'expense') ...<Widget>[
              Text('Expense Specifics', style: theme.textTheme.titleMedium),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Is this a "Want" or a "Need"?'),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  FilterChip(
                    label: const Text('Want'),
                    selected: _isNeed == false,
                    onSelected: (sel) {
                      setState(() => _isNeed = sel ? false : null);
                      ref.read(transactionFormNotifierProvider.notifier).updateIsNeed(sel ? false : null);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Need'),
                    selected: _isNeed == true,
                    onSelected: (sel) {
                      setState(() => _isNeed = sel ? true : null);
                      ref.read(transactionFormNotifierProvider.notifier).updateIsNeed(sel ? true : null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedEmotion,
                decoration: const InputDecoration(
                  labelText: 'How did you feel after this expense?',
                  border: OutlineInputBorder(),
                ),
                items: _emotionList
                    .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedEmotion = v),
                onSaved: (v) => ref.read(transactionFormNotifierProvider.notifier).updateEmotion(v),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// Bottom helper
class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color color;

  const _TypeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 20)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: isSelected ? color : color.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isSelected ? 4 : 2,
      ),
    );
  }
}
