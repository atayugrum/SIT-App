// File: lib/src/presentation/screens/settings/add_edit_category_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_category_model.dart';
import '../../providers/category_providers.dart';
import '../../providers/auth_providers.dart';

class AddEditCategoryFormScreen extends ConsumerStatefulWidget {
  final UserCategoryModel? categoryToEdit;
  const AddEditCategoryFormScreen({super.key, this.categoryToEdit});

  @override
  ConsumerState<AddEditCategoryFormScreen> createState() =>
      _AddEditCategoryFormScreenState();
}

class _AddEditCategoryFormScreenState
    extends ConsumerState<AddEditCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _categoryNameController;
  late TextEditingController _subcategoriesController;
  late String _selectedCategoryType;
  bool _isLoading = false;
  bool get _isEditMode => widget.categoryToEdit != null;

  @override
  void initState() {
    super.initState();
    _categoryNameController =
        TextEditingController(text: widget.categoryToEdit?.categoryName ?? '');
    _selectedCategoryType = widget.categoryToEdit?.categoryType ?? 'expense';
    _subcategoriesController = TextEditingController(
        text: widget.categoryToEdit?.subcategories.join(', ') ?? '');
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _subcategoriesController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Oturum bulunamadı. Lütfen tekrar giriş yapın."),
            backgroundColor: Colors.red));
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    List<String> subcategoriesList = _subcategoriesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final categoryData = UserCategoryModel(
      id: widget.categoryToEdit?.id,
      userId: currentUser.uid,
      categoryName: _categoryNameController.text.trim(),
      categoryType: _selectedCategoryType,
      subcategories: subcategoriesList,
      iconId: widget.categoryToEdit?.iconId ?? 'default_category_icon',
      createdAt: widget.categoryToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isArchived: widget.categoryToEdit?.isArchived ?? false,
    );

    try {
      final notifier = _selectedCategoryType == 'income'
          ? ref.read(incomeCustomCategoriesProvider.notifier)
          : ref.read(expenseCustomCategoriesProvider.notifier);

      if (_isEditMode) {
        await notifier.updateCustomCategory(categoryData);
      } else {
        await notifier.addCategory(categoryData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Kategori başarıyla kaydedildi!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Hata: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.teal.shade700;
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Kategoriyi Düzenle' : 'Yeni Kategori Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _categoryNameController,
                decoration: inputDecoration.copyWith(
                    labelText: 'Kategori Adı *',
                    prefixIcon: const Icon(Icons.label_outline)),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Lütfen bir kategori adı girin'
                    : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategoryType,
                decoration: inputDecoration.copyWith(
                    labelText: 'Kategori Tipi *',
                    prefixIcon: const Icon(Icons.filter_list)),
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text('Gider')),
                  DropdownMenuItem(value: 'income', child: Text('Gelir')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null)
                    setState(() => _selectedCategoryType = newValue);
                },
                validator: (value) =>
                    value == null ? 'Lütfen bir tip seçin' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _subcategoriesController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Alt Kategoriler (virgülle ayırın)',
                  hintText: 'Örn: Kahve, Öğle Yemeği, Atıştırmalık',
                  prefixIcon: const Icon(Icons.format_list_bulleted_outlined),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isEditMode
                        ? 'Kategoriyi Güncelle'
                        : 'Kategoriyi Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
