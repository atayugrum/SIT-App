// File: flutter_app/lib/src/presentation/screens/settings/add_edit_category_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_category_model.dart';
import '../../providers/category_providers.dart';
import '../../providers/auth_providers.dart'; // To get userId

class AddEditCategoryFormScreen extends ConsumerStatefulWidget {
  final UserCategoryModel? categoryToEdit;

  const AddEditCategoryFormScreen({super.key, this.categoryToEdit});

  @override
  ConsumerState<AddEditCategoryFormScreen> createState() => _AddEditCategoryFormScreenState();
}

class _AddEditCategoryFormScreenState extends ConsumerState<AddEditCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _categoryNameController;
  late TextEditingController _subcategoriesController;
  late String _selectedCategoryType;
  // String? _selectedIconId; // For later when icon selection is implemented

  bool _isLoading = false;
  bool get _isEditMode => widget.categoryToEdit != null;

  @override
  void initState() {
    super.initState();
    _categoryNameController = TextEditingController(text: widget.categoryToEdit?.categoryName ?? '');
    _selectedCategoryType = widget.categoryToEdit?.categoryType ?? 'expense'; // Default to 'expense' for new
    _subcategoriesController = TextEditingController(text: widget.categoryToEdit?.subcategories.join(', ') ?? '');
    // _selectedIconId = widget.categoryToEdit?.iconId;
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _subcategoriesController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in. Please restart the app."), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    List<String> subcategoriesList = _subcategoriesController.text.split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Use current (or default) iconId for now
    String iconIdToSave = widget.categoryToEdit?.iconId ?? 'default_category_icon'; 
    // if (_selectedIconId != null) {
    //   iconIdToSave = _selectedIconId!;
    // }


    final categoryData = UserCategoryModel(
      id: widget.categoryToEdit?.id, 
      userId: currentUser.uid, 
      categoryName: _categoryNameController.text.trim(),
      categoryType: _selectedCategoryType,
      subcategories: subcategoriesList,
      iconId: iconIdToSave, 
      createdAt: widget.categoryToEdit?.createdAt ?? DateTime.now(), 
      updatedAt: DateTime.now(), 
      isArchived: widget.categoryToEdit?.isArchived ?? false,
    );

    try {
      if (_isEditMode) {
        // Use the specific typed provider for update if you want targeted refresh,
        // or a general provider that calls the service then refreshes all.
        final notifier = _selectedCategoryType == 'income' 
            ? ref.read(incomeCustomCategoriesProvider.notifier)
            : ref.read(expenseCustomCategoriesProvider.notifier);
        await notifier.updateCustomCategory(categoryData);
         print("CATEGORY_FORM: Category updated: ${categoryData.categoryName}");
      } else {
        // Use the specific typed provider for add
        final notifier = _selectedCategoryType == 'income' 
            ? ref.read(incomeCustomCategoriesProvider.notifier)
            : ref.read(expenseCustomCategoriesProvider.notifier);
        await notifier.addCategory(categoryData);
        print("CATEGORY_FORM: Category added: ${categoryData.categoryName}");
      }

      // Optionally refresh the 'allCustomCategoriesProvider' if it's used elsewhere for combined lists
      // ignore: unused_result
      // ref.refresh(allCustomCategoriesProvider); // This would refetch all if needed

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Custom category ${_isEditMode ? "updated" : "added"} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Pop and indicate success (true)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save category: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Custom Category' : 'Add Custom Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _categoryNameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name *', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a category name' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategoryType,
                decoration: const InputDecoration(
                  labelText: 'Category Type *', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  prefixIcon: Icon(Icons.filter_list),
                ),
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text('Expense')),
                  DropdownMenuItem(value: 'income', child: Text('Income')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedCategoryType = newValue);
                  }
                },
                validator: (value) => value == null ? 'Please select a type' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _subcategoriesController,
                decoration: const InputDecoration(
                  labelText: 'Subcategories (comma-separated)',
                  hintText: 'e.g., Food, Shopping, Bills',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
                  prefixIcon: Icon(Icons.format_list_bulleted_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Enter subcategory names separated by commas. Example: Coffee, Lunch, Snacks",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              // TODO: Add Icon Picker later
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditMode ? 'Update Category' : 'Save Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}