// File: flutter_app/lib/src/presentation/screens/transactions/transaction_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_form_provider.dart';
import '../../../core/categories.dart';
import '../../providers/transaction_providers.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/account_providers.dart';
import '../../../data/models/account_model.dart';
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
    final detailsStepKey = ValueKey(
        'detailsStep_${formData.type}_${_isEditMode ? formData.id : "new"}_${formData.date.millisecondsSinceEpoch}');

    return [
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
          final notifier = ref.read(transactionFormNotifierProvider.notifier);
          notifier.updateCategory(category);
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
        currentFormDataFromProvider: formData,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notifier = ref.read(transactionFormNotifierProvider.notifier);
        if (_isEditMode) {
          print(
              "FLOW_SCREEN: Edit mode, loading transaction: ${widget.transactionToEdit!.id}");
          notifier.loadTransactionForEdit(widget.transactionToEdit!);
        } else {
          print("FLOW_SCREEN: Create mode, resetting form.");
          notifier.reset();
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    if (mounted) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _goToNextPage() {
    final formData = ref.read(transactionFormNotifierProvider);
    final steps = _buildSteps(formData, _goToNextPage);
    bool canProceed = true;
    String validationMessage = "";
    if (_currentPage == 0 && formData.type.isEmpty) {
      canProceed = false;
      validationMessage = "Please select a transaction type.";
    } else if (_currentPage == 1 && formData.category == null) {
      canProceed = false;
      validationMessage = "Please select a category.";
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
          curve: Curves.easeInOut);
    }
  }

  void _goToPreviousPage() {
    if (_pageController.hasClients && _currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }
  }

  Future<void> _handleSave({bool addAnother = false}) async {
    final currentSteps =
        _buildSteps(ref.read(transactionFormNotifierProvider), _goToNextPage);
    if (_currentPage != currentSteps.length - 1) {
      return;
    }
    if (!_detailsFormKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please correct errors in the form.'),
          backgroundColor: Colors.redAccent,
        ));
      }
      return;
    }
    if (mounted) setState(() => _isSaving = true);
    final formNotifier = ref.read(transactionFormNotifierProvider.notifier);
    final modelToSave = formNotifier.toTransactionModel();
    if (modelToSave == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Form data is incomplete. Cannot save.'),
          backgroundColor: Colors.redAccent,
        ));
      }
      if (mounted) setState(() => _isSaving = false);
      return;
    }
    print("TransactionFlowScreen: Saving transaction (Edit mode: $_isEditMode)");
    try {
      if (_isEditMode) {
        await ref
            .read(transactionsProvider.notifier)
            .updateTransactionInList(modelToSave.id!, modelToSave);
      } else {
        await ref.read(transactionsProvider.notifier).addTransaction(modelToSave);
      }
      if (mounted) {
        final _ = ref.refresh(accountsProvider);
        print("TransactionFlowScreen: accountsProvider refreshed.");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Transaction ${_isEditMode ? "updated" : "saved"}!'),
          backgroundColor: Colors.green,
        ));
        if (addAnother &&
            modelToSave.type == 'expense' &&
            !_isEditMode) {
          formNotifier.partialResetForNewEntry(
            originalType: modelToSave.type,
            originalDate: modelToSave.date,
            originalAccount: modelToSave.account,
            originalCategory: modelToSave.category,
          );
        } else {
          formNotifier.reset();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.redAccent,
        ));
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
    bool isLastStep = _currentPage == steps.length - 1;
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
                onPressed:
                    _isSaving ? null : () => Navigator.of(context).pop()),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(steps.length, (index) {
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
                children: [
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
                      label: Text(
                          _isEditMode ? 'Update & Close' : 'Save & Close'),
                      onPressed:
                          _isSaving ? null : () => _handleSave(addAnother: false),
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
                mainAxisAlignment: _currentPage > 0
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                children: [
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
              )
          ],
        ),
      ),
    );
  }
}

// Step 1: _TransactionTypeSelectionStep
class _TransactionTypeSelectionStep extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeSelected;

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

// Step 2: _CategorySelectionStep
class _CategorySelectionStep extends ConsumerWidget {
  final String transactionType;
  final String? selectedCategory;
  final Function(String) onCategorySelected;

  const _CategorySelectionStep({
    super.key,
    required this.transactionType,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  Future<void> _showAddCategoryDialog(
      BuildContext context, WidgetRef ref, String currentTransactionType) async {
    final formKey = GlobalKey<FormState>();
    final categoryNameController = TextEditingController();
    final subcategoriesController = TextEditingController();
    bool isLoadingInDialog = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setStateInDialog) {
          return AlertDialog( /* ... content as before, no changes needed here for this fix ... */ 
            title: Text('Add New ${currentTransactionType == 'income' ? 'Income' : 'Expense'} Category'),
            content: SingleChildScrollView(child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[ TextFormField(controller: categoryNameController,decoration: const InputDecoration(labelText: 'Category Name *'),validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a category name' : null), const SizedBox(height: 16), TextFormField(controller: subcategoriesController,decoration: const InputDecoration(labelText: 'Subcategories (Optional)', hintText: 'e.g., Sub1, Sub2')),]))),
            actions: <Widget>[ TextButton(child: const Text('Cancel'),onPressed: isLoadingInDialog ? null : () => Navigator.of(dialogContext).pop()), ElevatedButton(onPressed: isLoadingInDialog ? null : () async { if (formKey.currentState!.validate()) { setStateInDialog(() => isLoadingInDialog = true); final currentUser = ref.read(currentUserProvider); if (currentUser == null) { if(dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text("User not logged in."), backgroundColor: Colors.red)); if(dialogContext.mounted) setStateInDialog(() => isLoadingInDialog = false); return;} List<String> subcategoriesList = subcategoriesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(); final newCategory = UserCategoryModel(userId: currentUser.uid, categoryName: categoryNameController.text.trim(), categoryType: currentTransactionType, subcategories: subcategoriesList, iconId: 'custom_default_icon', createdAt: DateTime.now(), updatedAt: DateTime.now()); try { final categoryNotifierProviderType = currentTransactionType == 'income' ? incomeCustomCategoriesProvider : expenseCustomCategoriesProvider; await ref.read(categoryNotifierProviderType.notifier).addCategory(newCategory); final _ = ref.refresh(allCustomCategoriesProvider); if (dialogContext.mounted) { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('${newCategory.categoryName} added!'), backgroundColor: Colors.green)); onCategorySelected(newCategory.categoryName); Navigator.of(dialogContext).pop(); }} catch (e) { if (dialogContext.mounted) {ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Failed: ${e.toString().replaceFirst("Exception: ","")}'), backgroundColor: Colors.red));}} finally { if (dialogContext.mounted) {setStateInDialog(() => isLoadingInDialog = false);}}}} , child: isLoadingInDialog ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Category'))],);});},);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { /* ... content as before ... */ 
    final predefinedCategoriesMap = transactionType == 'income' ? incomeCategories : expenseCategories; final predefinedCategoryKeys = predefinedCategoriesMap.keys.toList();
    final asyncCustomCategories = transactionType == 'income' ? ref.watch(incomeCustomCategoriesProvider) : ref.watch(expenseCustomCategoriesProvider); 
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text( 'Select a Category for your ${transactionType == 'income' ? 'Income' : 'Expense'}', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20)), const SizedBox(height: 12), OutlinedButton.icon( icon: const Icon(Icons.add_circle_outline), label: const Text("Add New Custom Category"), onPressed: () { _showAddCategoryDialog(context, ref, transactionType); }, style: OutlinedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 10), textStyle: theme.textTheme.labelLarge, side: BorderSide(color: theme.primaryColor))), const SizedBox(height: 12), const Text("Or choose from below:", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)), const SizedBox(height: 12),
    Expanded( child: asyncCustomCategories.when( data: (customCategories) { List<String> allCategoryKeys = [...predefinedCategoryKeys]; Map<String, IconData> allCategoriesMap = {...predefinedCategoriesMap}; for (var customCat in customCategories) { if (!allCategoryKeys.contains(customCat.categoryName)) { allCategoryKeys.add(customCat.categoryName); allCategoriesMap[customCat.categoryName] = Icons.label_outline; }} allCategoryKeys.sort(); if (allCategoryKeys.isEmpty) { return const Center(child: Text("No categories available. Please add one!"));} return GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( crossAxisCount: 3, childAspectRatio: 1.0, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: allCategoryKeys.length, itemBuilder: (context, index) { final categoryName = allCategoryKeys[index]; final iconData = allCategoriesMap[categoryName] ?? Icons.help_outline; final bool isSelected = categoryName == selectedCategory; return GestureDetector(onTap: () => onCategorySelected(categoryName), child: Card(elevation: isSelected ? 6 : 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? theme.primaryColor : Colors.transparent, width: 2)), color: isSelected ? theme.primaryColor.withAlpha((255 * 0.1).round()) : theme.cardColor, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(iconData, size: 36, color: isSelected ? theme.primaryColor : theme.iconTheme.color?.withAlpha((255 * 0.7).round())), const SizedBox(height: 8), Text(categoryName, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? theme.primaryColor : theme.textTheme.bodySmall?.color), overflow: TextOverflow.ellipsis)])));});}, loading: () => const Center(child: CircularProgressIndicator()), error: (err, stack) => Center(child: Text("Error loading categories: $err"))))]));
  }
}

// Step 3: _SubCategorySelectionStep
class _SubCategorySelectionStep extends ConsumerWidget { /* ... content as before, ensure super.key ... */ 
  final String transactionType; final String? mainCategoryName; final String? selectedSubCategory; final Function(String?) onSubCategorySelected; final VoidCallback onProceedWithoutSubcategory;
  const _SubCategorySelectionStep({super.key, required this.transactionType, required this.mainCategoryName, this.selectedSubCategory, required this.onSubCategorySelected, required this.onProceedWithoutSubcategory});
  Future<void> _showAddSubCategoryDialog(BuildContext context, WidgetRef ref, String type, String currentMainCategoryName) async { /* ... as provided before ... */ 
    final formKey = GlobalKey<FormState>(); final subCategoryNameController = TextEditingController(); bool isLoadingInDialog = false;
    final asyncCustomCategories = type == 'income' ? ref.read(incomeCustomCategoriesProvider) : ref.read(expenseCustomCategoriesProvider); UserCategoryModel? targetMainCategoryModel; bool mainCategoryIsCustom = false;
    if (asyncCustomCategories.hasValue) { try { targetMainCategoryModel = asyncCustomCategories.value!.firstWhere((cat) => cat.categoryName == currentMainCategoryName && !cat.isArchived); mainCategoryIsCustom = targetMainCategoryModel.id != null; } catch(e) { print("AddSubDialog: Main category '$currentMainCategoryName' not found or error: $e"); }}
    bool canAddSubcategory = mainCategoryIsCustom && targetMainCategoryModel != null;
    return showDialog<void>(context: context, barrierDismissible: false, builder: (BuildContext dialogContext) { return StatefulBuilder(builder: (context, setStateInDialog) {
            return AlertDialog(title: Text('Add Subcategory to "$currentMainCategoryName"'),
            content: SingleChildScrollView(child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                if (!canAddSubcategory) Padding( padding: const EdgeInsets.only(bottom: 12.0), child: Text( asyncCustomCategories is AsyncLoading ? "Loading category data..." : "Subcategories can only be added to custom categories. '$currentMainCategoryName' might be predefined or not loaded.", style: TextStyle(color: Theme.of(dialogContext).colorScheme.error, fontSize: 12),),),
                TextFormField(controller: subCategoryNameController, decoration: const InputDecoration(labelText: 'New Subcategory Name *'), enabled: canAddSubcategory, validator: (value) { if (!canAddSubcategory) return null; if (value == null || value.trim().isEmpty) { return 'Please enter a subcategory name';} if (targetMainCategoryModel!.subcategories.map((s) => s.toLowerCase()).contains(value.trim().toLowerCase())) { return '"${value.trim()}" already exists.';} return null;},),
              ]))),
            actions: <Widget>[TextButton(child: const Text('Cancel'), onPressed: isLoadingInDialog ? null : () => Navigator.of(dialogContext).pop()),
                ElevatedButton(onPressed: (isLoadingInDialog || !canAddSubcategory) ? null : () async { 
                    if (formKey.currentState!.validate()) { setStateInDialog(() => isLoadingInDialog = true); final newSubName = subCategoryNameController.text.trim(); List<String> updatedSubcategories = List.from(targetMainCategoryModel!.subcategories); if (!updatedSubcategories.map((s)=>s.toLowerCase()).contains(newSubName.toLowerCase())) { updatedSubcategories.add(newSubName); }
                    final updatedCategoryModel = UserCategoryModel(id: targetMainCategoryModel.id!, userId: targetMainCategoryModel.userId, categoryName: targetMainCategoryModel.categoryName, categoryType: targetMainCategoryModel.categoryType, subcategories: updatedSubcategories, iconId: targetMainCategoryModel.iconId, createdAt: targetMainCategoryModel.createdAt, updatedAt: DateTime.now(), isArchived: targetMainCategoryModel.isArchived );
                    try { final categoryNotifierProviderType = type == 'income' ? incomeCustomCategoriesProvider : expenseCustomCategoriesProvider; await ref.read(categoryNotifierProviderType.notifier).updateCustomCategory(updatedCategoryModel); final _ = ref.refresh(allCustomCategoriesProvider); if (dialogContext.mounted) { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Subcategory "$newSubName" added!'), backgroundColor: Colors.green)); onSubCategorySelected(newSubName); Navigator.of(dialogContext).pop(); }}
                    catch (e) { if (dialogContext.mounted) { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Failed: ${e.toString().replaceFirst("Exception: ","")}'), backgroundColor: Colors.red));}}
                    finally { if (dialogContext.mounted) { setStateInDialog(() => isLoadingInDialog = false);}}}
                  }, child: isLoadingInDialog ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add Subcategory')),
            ]);});},);
  }
  @override Widget build(BuildContext context, WidgetRef ref) { /* ... same as before ... */ 
    final theme = Theme.of(context); List<String> subCategoriesToDisplay = []; bool isLoadingData = true; UserCategoryModel? currentCustomMainCategoryData;
    if (mainCategoryName == null) { WidgetsBinding.instance.addPostFrameCallback((_) {onProceedWithoutSubcategory();}); return const Center(child: Text("No main category selected. Proceeding...", textAlign: TextAlign.center));}
    final predefinedSubCategoriesMap = transactionType == 'income' ? incomeSubcategories : expenseSubcategories; if (predefinedSubCategoriesMap.containsKey(mainCategoryName)) { subCategoriesToDisplay.addAll(predefinedSubCategoriesMap[mainCategoryName]!);}
    final asyncCustomCategories = transactionType == 'income' ? ref.watch(incomeCustomCategoriesProvider) : ref.watch(expenseCustomCategoriesProvider);
    asyncCustomCategories.map( data: (data) { isLoadingData = false; try { currentCustomMainCategoryData = data.value.firstWhere((cat) => cat.categoryName == mainCategoryName && !cat.isArchived,); for (var subcat in currentCustomMainCategoryData!.subcategories) { if (!subCategoriesToDisplay.contains(subcat)) {subCategoriesToDisplay.add(subcat);}}} catch (e) { /* not found */ } if (subCategoriesToDisplay.isNotEmpty) {subCategoriesToDisplay = subCategoriesToDisplay.toSet().toList()..sort();}}, loading: (_) { isLoadingData = true; }, error: (error) { isLoadingData = false; print("SUB_CATEGORY_STEP (build): Error loading custom categories: ${error.error}");});
    if (isLoadingData && subCategoriesToDisplay.isEmpty) { return const Center(child: CircularProgressIndicator());}
    bool canAddSubCatToThisMain = currentCustomMainCategoryData != null && currentCustomMainCategoryData?.id != null;
    if (subCategoriesToDisplay.isEmpty) { return Padding( padding: const EdgeInsets.all(16.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [ Text( 'No Subcategories available for "$mainCategoryName".', textAlign: TextAlign.center, style: theme.textTheme.titleLarge,), const SizedBox(height: 20), if (canAddSubCatToThisMain) ElevatedButton.icon(icon: const Icon(Icons.add_circle_outline), label: const Text('Add First Subcategory'), onPressed: () => _showAddSubCategoryDialog(context, ref, transactionType, mainCategoryName!),), const SizedBox(height: 10), TextButton( onPressed: onProceedWithoutSubcategory, child: const Text('Continue without Subcategory'),), ],),);}
    return Padding( padding: const EdgeInsets.all(16.0), child: Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [ Text( 'Select Subcategory for "$mainCategoryName"', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),), const SizedBox(height: 12), if (canAddSubCatToThisMain) OutlinedButton.icon( icon: const Icon(Icons.add_circle_outline), label: Text("Add New Subcategory to '$mainCategoryName'"), onPressed: () => _showAddSubCategoryDialog(context, ref, transactionType, mainCategoryName!), style: OutlinedButton.styleFrom(side: BorderSide(color: theme.primaryColor)),) else Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text("(Subcategories can usually be added to your own custom main categories.)", textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),),), const SizedBox(height: 12), Expanded( child: ListView.builder( itemCount: subCategoriesToDisplay.length, itemBuilder: (context, index) { final subCategoryName = subCategoriesToDisplay[index]; final bool isSelected = subCategoryName == selectedSubCategory; return Card( elevation: isSelected ? 4 : 1, margin: const EdgeInsets.symmetric(vertical: 4.0), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8), side: BorderSide( color: isSelected ? theme.primaryColor : Colors.transparent, width: 1.5,),), child: ListTile( title: Text(subCategoryName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)), onTap: () => onSubCategorySelected(subCategoryName), selected: isSelected, selectedTileColor: theme.primaryColor.withAlpha((255 * 0.1).round()),),);},),), const SizedBox(height: 16), TextButton( onPressed: onProceedWithoutSubcategory, child: const Text('Skip Subcategory (Select "None")'),) ],),);
  }
}

// REFINED Step 4 - _DetailsEntryStep Widget and _DetailsEntryStepState
class _DetailsEntryStep extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;
  final TransactionFormData currentFormDataFromProvider;

  const _DetailsEntryStep({
    super.key,
    required this.formKey,
    required this.currentFormDataFromProvider,
  });

  @override
  ConsumerState<_DetailsEntryStep> createState() => _DetailsEntryStepState();
}

class _DetailsEntryStepState extends ConsumerState<_DetailsEntryStep> {
  // Controllers are initialized in initState
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _accountController;
  late final TextEditingController _recurrenceRuleController;
  late final TextEditingController _incomeAllocationPctController;
  
  late final FocusNode _incomeAllocationFocusNode;

  // Local state for UI elements, also initialized from currentFormDataFromProvider
  late bool _isRecurring; // CRITICAL: This was the source of LateInitializationError
  String? _selectedEmotion;
  bool? _isNeed;
  String? _selectedAccountNameFromDropdown;

  final List<String> _emotionSuggestions = ["Happy", "Neutral", "Stressed", "Guilty", "Excited", "Sad"];

  @override
  void initState() {
    super.initState();
    print("DETAILS_STEP initState: Initializing. FormData type: ${widget.currentFormDataFromProvider.type}");
    
    // Initialize controllers HERE
    _amountController = TextEditingController();
    _dateController = TextEditingController();
    _descriptionController = TextEditingController();
    _accountController = TextEditingController();
    _recurrenceRuleController = TextEditingController();
    _incomeAllocationPctController = TextEditingController();
    _incomeAllocationFocusNode = FocusNode();

    // Initialize local state variables AND controller texts from initial widget data
    _initializeLocalStateAndControllers(widget.currentFormDataFromProvider);
  }
  
  @override
  void didUpdateWidget(covariant _DetailsEntryStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentFormDataFromProvider != oldWidget.currentFormDataFromProvider) {
      print("DETAILS_STEP: didUpdateWidget. Syncing state. New AllocPct from prop: ${widget.currentFormDataFromProvider.incomeAllocationPct}");
      _syncLocalStateAndControllersOnDataChange(widget.currentFormDataFromProvider);
    }
  }

  void _initializeLocalStateAndControllers(TransactionFormData fd) {
    // This is called ONCE from initState to set initial values for controllers and local state.
    _amountController.text = fd.amount?.toStringAsFixed(2) ?? '';
    _dateController.text = DateFormat('yyyy-MM-dd').format(fd.date);
    _descriptionController.text = fd.description ?? '';
    _accountController.text = fd.account ?? '';
    _selectedAccountNameFromDropdown = fd.account;
    _isRecurring = fd.isRecurring; // Initialize late field
    _recurrenceRuleController.text = fd.recurrenceRule ?? '';
    _incomeAllocationPctController.text = fd.incomeAllocationPct?.toString() ?? (fd.type == 'income' ? '0' : '');
    _isNeed = fd.isNeed; // Initialize late field
    _selectedEmotion = fd.emotion; // Initialize late field
  }
  
  // This method is called from didUpdateWidget to sync UI with provider changes
  // without disrupting user input on the currently focused field.
  void _syncLocalStateAndControllersOnDataChange(TransactionFormData fd) {
    if (!mounted) return;

    // Sync TextEditingControllers only if text differs AND field is not focused
    _updateControllerTextIfNeeded(_amountController, fd.amount?.toStringAsFixed(2) ?? '', null);
    _updateControllerTextIfNeeded(_dateController, DateFormat('yyyy-MM-dd').format(fd.date), null);
    _updateControllerTextIfNeeded(_descriptionController, fd.description ?? '', null);
    _updateControllerTextIfNeeded(_accountController, fd.account ?? '', null);
    _updateControllerTextIfNeeded(_recurrenceRuleController, fd.recurrenceRule ?? '', null);
    _updateControllerTextIfNeeded(_incomeAllocationPctController, 
        fd.incomeAllocationPct?.toString() ?? (fd.type == 'income' ? '0' : ''), 
        _incomeAllocationFocusNode); // Pass focus node for specific check

    // Sync local state variables (like bools for switches, selected values for dropdowns)
    bool needsSetState = false;
    if (_selectedAccountNameFromDropdown != fd.account) {
      _selectedAccountNameFromDropdown = fd.account;
      needsSetState = true;
    }
    if (_isRecurring != fd.isRecurring) {
      _isRecurring = fd.isRecurring;
      needsSetState = true;
    }
    if (fd.type == 'expense') {
      if (_isNeed != fd.isNeed) { _isNeed = fd.isNeed; needsSetState = true; }
      if (_selectedEmotion != fd.emotion) { _selectedEmotion = fd.emotion; needsSetState = true; }
    } else { 
      if (_isNeed != null) { _isNeed = null; needsSetState = true;}
      if (_selectedEmotion != null) { _selectedEmotion = null; needsSetState = true;}
    }
    
    if (needsSetState) {
      setState(() {}); 
    }
  }

  // Helper to update controller text only if necessary and not focused
  void _updateControllerTextIfNeeded(TextEditingController controller, String newText, FocusNode? focusNode) {
    if (focusNode?.hasFocus == true) {
      // If the field has focus, don't override user typing unless the value is truly different from what they might be aiming for
      // This can be tricky. For now, if focused, we assume user input is king.
      // An alternative would be to compare and only update if the value from provider is drastically different.
      print("DETAILS_STEP: Field ${controller.hashCode} has focus. Current text: '${controller.text}', Provider newText: '$newText'. Skipping programmatic update.");
      return;
    }
    if (controller.text != newText) {
      print("DETAILS_STEP: Updating controller ${controller.hashCode} text from '${controller.text}' to '$newText'");
      controller.text = newText;
      // controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    _accountController.dispose();
    _recurrenceRuleController.dispose();
    _incomeAllocationPctController.dispose();
    _incomeAllocationFocusNode.dispose(); 
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async { 
    final formNotifier = ref.read(transactionFormNotifierProvider.notifier);
    final currentFormDate = ref.read(transactionFormNotifierProvider).date; 
    final DateTime? picked = await showDatePicker(context: context, initialDate: currentFormDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
    if (picked != null && picked != currentFormDate) { 
      formNotifier.updateDate(picked); 
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TransactionFormData displayFormData = widget.currentFormDataFromProvider; 
    
    return Padding( /* ... Form UI as before ... */ 
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: widget.formKey, 
        child: ListView( 
          children: [
            Text('Enter Transaction Details', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20)), const SizedBox(height: 24),
            TextFormField(controller: _amountController, decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), prefixText: '₺ '), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) { if (v == null || v.isEmpty) return 'Enter amount'; final a = double.tryParse(v); if (a == null || a <= 0) return 'Valid positive amount'; return null; }, onChanged: (v) => ref.read(transactionFormNotifierProvider.notifier).updateAmount(double.tryParse(v.trim()))), const SizedBox(height: 16),
            TextFormField(controller: _dateController, decoration: InputDecoration(labelText: 'Date', border: const OutlineInputBorder(), suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _selectDate(context))), readOnly: true, onTap: () => _selectDate(context), validator: (v) => (v == null || v.isEmpty) ? 'Select date' : null), const SizedBox(height: 16),
            Consumer(builder: (context, ref, child) { final accountsAsyncValue = ref.watch(accountsProvider); return accountsAsyncValue.when(data: (accountsList) { String? currentDropdownValue = _selectedAccountNameFromDropdown; if (currentDropdownValue != null && !accountsList.any((acc) => acc.accountName == currentDropdownValue)) { currentDropdownValue = null; WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && ref.read(transactionFormNotifierProvider).account != null) { ref.read(transactionFormNotifierProvider.notifier).updateAccount(null); }});} return DropdownButtonFormField<String>(value: currentDropdownValue, decoration: const InputDecoration(labelText: 'Account', border: OutlineInputBorder()), hint: const Text('Select an account'), isExpanded: true, items: accountsList.map((AccountModel account) => DropdownMenuItem<String>(value: account.accountName, child: Text("${account.accountName} (${account.currency})"))).toList(), onChanged: (String? newValue) { setState(() { _selectedAccountNameFromDropdown = newValue; }); ref.read(transactionFormNotifierProvider.notifier).updateAccount(newValue);}, validator: (value) => value == null ? 'Please select an account' : null);}, loading: () => const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2))), error: (err, stack) => TextFormField(controller: _accountController, decoration: InputDecoration(labelText: 'Account (Error Loading List)', border: const OutlineInputBorder(), errorText: 'Could not load accounts'), onChanged:(value) => ref.read(transactionFormNotifierProvider.notifier).updateAccount(value.trim()), validator: (value) => value == null || value.isEmpty ? 'Please enter an account' : null,));}), const SizedBox(height: 16),
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()), maxLines: 2, onChanged: (value) => ref.read(transactionFormNotifierProvider.notifier).updateDescription(value.trim())), const SizedBox(height: 16),
            SwitchListTile(title: const Text('Repeated Entry?'), value: _isRecurring, onChanged: (bool value) { setState(() => _isRecurring = value); ref.read(transactionFormNotifierProvider.notifier).updateIsRecurring(value); if (!value) { _recurrenceRuleController.clear(); ref.read(transactionFormNotifierProvider.notifier).updateRecurrenceRule(null);}}, tileColor: (theme.inputDecorationTheme.fillColor ?? theme.canvasColor).withAlpha((255 * 0.5).round()), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0)),
            if (_isRecurring) ...[ const SizedBox(height: 8), TextFormField(controller: _recurrenceRuleController, decoration: const InputDecoration(labelText: 'Recurrence Rule (Optional)', hintText: 'e.g., FREQ=MONTHLY', border: OutlineInputBorder()), onChanged: (value) => ref.read(transactionFormNotifierProvider.notifier).updateRecurrenceRule(value.trim()))], const SizedBox(height: 16),
            
            if (displayFormData.type == 'income') ...[ 
              Text('Income Specifics', style: theme.textTheme.titleMedium), const Divider(), const SizedBox(height: 8), 
              TextFormField(
                controller: _incomeAllocationPctController, 
                focusNode: _incomeAllocationFocusNode, 
                decoration: const InputDecoration(labelText: 'Allocate to Savings (%)', hintText: '0-100', border: OutlineInputBorder()), 
                keyboardType: TextInputType.number, 
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)], 
                validator: (value) { if (value != null && value.trim().isNotEmpty) { final val = int.tryParse(value.trim()); if (val == null || val < 0 || val > 100) return 'Must be 0-100'; } return null; }, 
                onChanged: (value) { 
                  final trimmedValue = value.trim();
                  ref.read(transactionFormNotifierProvider.notifier).updateIncomeAllocationPct(trimmedValue.isEmpty ? null : int.tryParse(trimmedValue));
                }
              ), const SizedBox(height: 16)],
            if (displayFormData.type == 'expense') ...[ 
              Text('Expense Specifics', style: theme.textTheme.titleMedium), const Divider(), const SizedBox(height: 8), const Text('Is this a "Want" or a "Need"?'), const SizedBox(height: 4), 
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [ FilterChip(label: const Text('Want'), selected: _isNeed == false, onSelected: (bool selected) { setState(() => _isNeed = selected ? false : (_isNeed == false ? null : _isNeed) ); ref.read(transactionFormNotifierProvider.notifier).updateIsNeed(_isNeed);}, checkmarkColor: theme.colorScheme.onPrimary, selectedColor: theme.colorScheme.primary, labelStyle: TextStyle(color: _isNeed == false ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color)), const SizedBox(width: 8), FilterChip(label: const Text('Need'), selected: _isNeed == true, onSelected: (bool selected) { setState(() => _isNeed = selected ? true : (_isNeed == true ? null : _isNeed)); ref.read(transactionFormNotifierProvider.notifier).updateIsNeed(_isNeed);}, checkmarkColor: theme.colorScheme.onPrimary, selectedColor: theme.colorScheme.primary, labelStyle: TextStyle(color: _isNeed == true ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color))]), 
              const SizedBox(height: 16), 
              DropdownButtonFormField<String>(value: _selectedEmotion, decoration: const InputDecoration(labelText: 'How did you feel after this expense?', border: OutlineInputBorder()), items: _emotionSuggestions.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(), onChanged: (String? newValue) { setState(() => _selectedEmotion = newValue); ref.read(transactionFormNotifierProvider.notifier).updateEmotion(newValue);}), 
              const SizedBox(height: 16)],
          ],
        ),
      ),
    );
  }
}

// Helper widget for Income/Expense buttons
class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color color;
  const _TypeButton({super.key, required this.label, required this.icon, required this.isSelected, required this.onPressed, required this.color});
  @override
  Widget build(BuildContext context) { /* ... same as before ... */ 
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 20)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: isSelected ? color : color.withAlpha((255 * 0.7).round()),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isSelected ? 4 : 2,
      ),
    );
  }
}