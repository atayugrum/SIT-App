// File: lib/src/presentation/screens/settings/add_edit_category_form_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_category_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/category_providers.dart';

class AddEditCategoryFormScreen extends ConsumerStatefulWidget {
  final UserCategoryModel? categoryToEdit;
  const AddEditCategoryFormScreen({super.key, this.categoryToEdit});

  @override
  ConsumerState<AddEditCategoryFormScreen> createState() =>
      _AddEditCategoryFormScreenState();
}

class _AddEditCategoryFormScreenState
    extends ConsumerState<AddEditCategoryFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _subcatsCtrl;
  late String _categoryType;
  bool _isLoading = false;

  bool get _isEditMode => widget.categoryToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.categoryToEdit?.categoryName ?? '');
    _categoryType = widget.categoryToEdit?.categoryType ?? 'expense';
    _subcatsCtrl = TextEditingController(
        text: widget.categoryToEdit?.subcategories.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subcatsCtrl.dispose();
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

  void _pickType() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Kategori Tipi'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _categoryType = 'expense');
              Navigator.of(context).pop();
            },
            child: const Text('Gider'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _categoryType = 'income');
              Navigator.of(context).pop();
            },
            child: const Text('Gelir'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showAlert('Lütfen bir kategori adı girin.');
      return;
    }
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showAlert('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
      return;
    }

    setState(() => _isLoading = true);

    final subcats = _subcatsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final categoryData = UserCategoryModel(
      id: widget.categoryToEdit?.id,
      userId: currentUser.uid,
      categoryName: name,
      categoryType: _categoryType,
      subcategories: subcats,
      iconId:
          widget.categoryToEdit?.iconId ?? 'default_category_icon',
      createdAt: widget.categoryToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isArchived: widget.categoryToEdit?.isArchived ?? false,
    );

    try {
      final notifier = _categoryType == 'income'
          ? ref.read(incomeCustomCategoriesProvider.notifier)
          : ref.read(expenseCustomCategoriesProvider.notifier);
      if (_isEditMode) {
        await notifier.updateCustomCategory(categoryData);
      } else {
        await notifier.addCategory(categoryData);
      }
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
    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
            _isEditMode ? 'Kategoriyi Düzenle' : 'Yeni Kategori'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom:
                BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Kategori Adı',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _nameCtrl,
              placeholder: 'Örn: Eğlence',
              placeholderStyle:
                  const TextStyle(color: AppColors.textSecondary),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecor,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            const SizedBox(height: 16),
            const Text('Kategori Tipi',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickType,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: _fieldDecor,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _categoryType == 'income' ? 'Gelir' : 'Gider',
                        style: const TextStyle(
                            color: AppColors.textPrimary),
                      ),
                    ),
                    const Icon(CupertinoIcons.chevron_right,
                        color: AppColors.textSecondary, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Alt Kategoriler (virgülle ayırın)',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _subcatsCtrl,
              placeholder: 'Örn: Kahve, Öğle Yemeği, Atıştırmalık',
              placeholderStyle:
                  const TextStyle(color: AppColors.textSecondary),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecor,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                  : Text(_isEditMode
                      ? 'Kategoriyi Güncelle'
                      : 'Kategoriyi Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
