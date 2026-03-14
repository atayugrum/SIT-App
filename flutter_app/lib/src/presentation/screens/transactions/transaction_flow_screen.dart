// File: lib/src/presentation/screens/transactions/transaction_flow_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/categories.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_category_model.dart';
import '../../providers/account_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/category_providers.dart';
import '../../providers/transaction_form_provider.dart';
import '../../providers/transaction_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class TransactionFlowScreen extends ConsumerStatefulWidget {
  final TransactionModel? transactionToEdit;
  const TransactionFlowScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<TransactionFlowScreen> createState() =>
      _TransactionFlowScreenState();
}

class _TransactionFlowScreenState
    extends ConsumerState<TransactionFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  bool get _isEditMode => widget.transactionToEdit != null;

  List<Widget> _buildSteps(TransactionFormData formData) {
    return <Widget>[
      _TransactionTypeSelectionStep(
        key: const ValueKey('typeStep_flow'),
        selectedType: formData.type,
        onTypeSelected: (type) {
          ref.read(transactionFormNotifierProvider.notifier).updateType(type);
          _goToNextPage();
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
          _goToNextPage();
        },
      ),
      _SubCategorySelectionStep(
        key: ValueKey(
            'subCategoryStep_flow_${formData.category ?? "none"}'),
        transactionType: formData.type,
        mainCategoryName: formData.category,
        selectedSubCategory: formData.subCategory,
        onSubCategorySelected: (sub) {
          ref
              .read(transactionFormNotifierProvider.notifier)
              .updateSubCategory(sub);
          _goToNextPage();
        },
        onProceedWithoutSubcategory: () {
          ref
              .read(transactionFormNotifierProvider.notifier)
              .updateSubCategory(null);
          _goToNextPage();
        },
      ),
      const _DetailsEntryStep(key: ValueKey('detailsStep_flow')),
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
    setState(() => _currentPage = page);
  }

  void _goToNextPage() {
    final formData = ref.read(transactionFormNotifierProvider);
    final steps = _buildSteps(formData);
    if (_currentPage == 0 && formData.type.isEmpty) {
      _showAlert(context, 'Lütfen bir işlem türü seçin.');
      return;
    }
    if (_currentPage == 1 && formData.category == null) {
      _showAlert(context, 'Lütfen bir kategori seçin.');
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
    final formData = ref.read(transactionFormNotifierProvider);
    final steps = _buildSteps(formData);
    if (_currentPage != steps.length - 1) return;

    if (formData.amount == null || formData.amount! <= 0) {
      _showAlert(context, 'Lütfen geçerli bir tutar girin.');
      return;
    }
    if (formData.account == null) {
      _showAlert(context, 'Lütfen bir hesap seçin.');
      return;
    }

    if (mounted) setState(() => _isSaving = true);

    final notifier = ref.read(transactionFormNotifierProvider.notifier);
    final modelToSave = notifier.toTransactionModel();

    if (modelToSave == null) {
      _showAlert(context, 'Form verileri eksik. Kaydedilemiyor.');
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    try {
      if (_isEditMode) {
        await ref
            .read(transactionsProvider.notifier)
            .updateTransactionInList(modelToSave.id!, modelToSave);
      } else {
        await ref
            .read(transactionsProvider.notifier)
            .addTransaction(modelToSave);
      }

      if (mounted) {
        ref.invalidate(accountsProvider);
        if (addAnother && modelToSave.type == 'expense' && !_isEditMode) {
          notifier.partialResetForNewEntry(
            originalType: modelToSave.type,
            originalDate: modelToSave.date,
            originalAccount: modelToSave.accountId,
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
        _showAlert(context,
            'Hata: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAlert(BuildContext ctx, String message) {
    showCupertinoDialog(
      context: ctx,
      builder: (_) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formData = ref.watch(transactionFormNotifierProvider);
    final steps = _buildSteps(formData);
    final bool isLastStep = _currentPage == steps.length - 1;
    final String navTitle =
        '${_isEditMode ? 'İşlemi Düzenle' : 'İşlem Ekle'} (${_currentPage + 1}/${steps.length})';

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: Text(navTitle),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving
              ? null
              : (_currentPage > 0
                  ? _goToPreviousPage
                  : () => Navigator.of(context).pop()),
          child: Icon(
            _currentPage > 0 ? CupertinoIcons.back : CupertinoIcons.xmark,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: steps,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(steps.length, (i) {
                      return Container(
                        width: _currentPage == i ? 12 : 8,
                        height: _currentPage == i ? 12 : 8,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == i
                              ? AppColors.primaryBlue
                              : const Color(0xFF636366),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (isLastStep)
                    Row(
                      children: [
                        if (formData.type == 'expense' &&
                            !_isEditMode) ...[
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              onPressed: _isSaving
                                  ? null
                                  : () =>
                                      _handleSave(addAnother: true),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  if (_isSaving)
                                    const CupertinoActivityIndicator()
                                  else
                                    const Icon(
                                        CupertinoIcons
                                            .add_circled_solid,
                                        size: 18),
                                  const SizedBox(width: 6),
                                  const Text('Kaydet & Yeni'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: CupertinoButton.filled(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: _isSaving
                                ? null
                                : () =>
                                    _handleSave(addAnother: false),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                if (_isSaving)
                                  const CupertinoActivityIndicator(
                                      color: CupertinoColors.white)
                                else
                                  const Icon(
                                      CupertinoIcons
                                          .checkmark_circle_fill,
                                      size: 18),
                                const SizedBox(width: 6),
                                Text(_isEditMode
                                    ? 'Güncelle ve Kapat'
                                    : 'Kaydet ve Kapat'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1: Transaction Type Selection
// ─────────────────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ne tür bir işlem?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          _TypeButton(
            label: 'Gelir',
            icon: CupertinoIcons.arrow_down_circle_fill,
            isSelected: selectedType == 'income',
            onPressed: () => onTypeSelected('income'),
            color: AppColors.incomeGreen,
          ),
          const SizedBox(height: 20),
          _TypeButton(
            label: 'Gider',
            icon: CupertinoIcons.arrow_up_circle_fill,
            isSelected: selectedType == 'expense',
            onPressed: () => onTypeSelected('expense'),
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color color;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppColors.surfaceGlass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.glassBorder,
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2: Category Selection
// ─────────────────────────────────────────────────────────────────────────────

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
      BuildContext context, WidgetRef ref) async {
    final categoryCtrl = TextEditingController();
    final subsCtrl = TextEditingController();
    String? errorText;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          height: 400,
          color: const Color(0xFF1C1C1E),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('İptal',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                  ),
                  Text(
                    transactionType == 'income'
                        ? 'Yeni Gelir Kategorisi'
                        : 'Yeni Gider Kategorisi',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final name = categoryCtrl.text.trim();
                      if (name.isEmpty) {
                        setState(
                            () => errorText = 'Kategori adı girin');
                        return;
                      }
                      final user = ref.read(currentUserProvider);
                      if (user == null) {
                        setState(() => errorText = 'Giriş yapılmamış.');
                        return;
                      }
                      final subs = subsCtrl.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      final newCat = UserCategoryModel(
                        userId: user.uid,
                        categoryName: name,
                        categoryType: transactionType,
                        subcategories: subs,
                        iconId: 'custom_default_icon',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      try {
                        final provider = transactionType == 'income'
                            ? incomeCustomCategoriesProvider
                            : expenseCustomCategoriesProvider;
                        await ref
                            .read(provider.notifier)
                            .addCategory(newCat);
                        ref.invalidate(allCustomCategoriesProvider);
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        onCategorySelected(name);
                      } catch (e) {
                        if (!ctx.mounted) return;
                        setState(() => errorText = 'Hata: $e');
                      }
                    },
                    child: const Text('Kaydet',
                        style:
                            TextStyle(color: AppColors.primaryBlue)),
                  ),
                ],
              ),
              if (errorText != null) ...[
                const SizedBox(height: 4),
                Text(errorText!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: categoryCtrl,
                placeholder: 'Kategori Adı *',
                placeholderStyle:
                    const TextStyle(color: AppColors.textSecondary),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: subsCtrl,
                placeholder: 'Alt Kategoriler (virgülle ayır)',
                placeholderStyle:
                    const TextStyle(color: AppColors.textSecondary),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predefined = transactionType == 'income'
        ? incomeCategories
        : expenseCategories;
    final asyncCats = transactionType == 'income'
        ? ref.watch(incomeCustomCategoriesProvider)
        : ref.watch(expenseCustomCategoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${transactionType == 'income' ? 'Geliriniz' : 'Gideriniz'} için Kategori Seçin',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showAddCategoryDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceGlass,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primaryBlue, width: 0.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add_circled_solid,
                      color: AppColors.primaryBlue, size: 18),
                  SizedBox(width: 8),
                  Text('Yeni Özel Kategori Ekle',
                      style: TextStyle(
                          color: AppColors.primaryBlue, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Veya aşağıdakilerden birini seçin:',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncCats.when(
              data: (customs) {
                final allKeys = <String>[
                  ...predefined.keys,
                  ...customs.map((c) => c.categoryName),
                ];
                final allIcons = <String, IconData>{...predefined}
                  ..addEntries(customs.map(
                      (c) => MapEntry(c.categoryName, CupertinoIcons.tag)));
                final unique = allKeys.toSet().toList()..sort();
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: unique.length,
                  itemBuilder: (ctx, i) {
                    final name = unique[i];
                    final isSel = name == selectedCategory;
                    return GestureDetector(
                      onTap: () => onCategorySelected(name),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primaryBlue
                                  .withValues(alpha: 0.2)
                              : AppColors.surfaceGlass,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? AppColors.primaryBlue
                                : AppColors.glassBorder,
                            width: isSel ? 2 : 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              allIcons[name] ??
                                  CupertinoIcons.question,
                              size: 28,
                              color: isSel
                                  ? AppColors.primaryBlue
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4),
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSel
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: isSel
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CupertinoActivityIndicator()),
              error: (err, _) => Center(
                  child: Text('Hata: $err',
                      style:
                          const TextStyle(color: AppColors.danger))),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3: Subcategory Selection
// ─────────────────────────────────────────────────────────────────────────────

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

  Future<void> _showAddSubDialog(
    BuildContext context,
    WidgetRef ref,
    UserCategoryModel target,
  ) async {
    final ctrl = TextEditingController();
    String? errorText;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          height: 260,
          color: const Color(0xFF1C1C1E),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('İptal',
                        style: TextStyle(
                            color: AppColors.textSecondary)),
                  ),
                  const Text('Alt Kategori Ekle',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final name = ctrl.text.trim();
                      if (name.isEmpty) {
                        setState(() => errorText = 'İsim girin');
                        return;
                      }
                      if (target.subcategories
                          .map((s) => s.toLowerCase())
                          .contains(name.toLowerCase())) {
                        setState(
                            () => errorText = '"$name" zaten mevcut.');
                        return;
                      }
                      final updated = [...target.subcategories, name];
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
                        await ref
                            .read(provider.notifier)
                            .updateCustomCategory(updatedModel);
                        ref.invalidate(allCustomCategoriesProvider);
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        onSubCategorySelected(name);
                      } catch (e) {
                        if (!ctx.mounted) return;
                        setState(() => errorText = 'Hata: $e');
                      }
                    },
                    child: const Text('Ekle',
                        style:
                            TextStyle(color: AppColors.primaryBlue)),
                  ),
                ],
              ),
              if (errorText != null) ...[
                const SizedBox(height: 4),
                Text(errorText!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: ctrl,
                placeholder: 'Alt Kategori İsmi',
                placeholderStyle:
                    const TextStyle(color: AppColors.textSecondary),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                autofocus: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mainCategoryName == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => onProceedWithoutSubcategory());
      return const Center(
        child: Text('Ana kategori seçilmedi. Devam ediliyor...',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final predefinedSubs = transactionType == 'income'
        ? incomeSubcategories
        : expenseSubcategories;
    final asyncCats = transactionType == 'income'
        ? ref.watch(incomeCustomCategoriesProvider)
        : ref.watch(expenseCustomCategoriesProvider);

    return asyncCats.when(
      loading: () =>
          const Center(child: CupertinoActivityIndicator()),
      error: (_, __) => _buildList(
          context, ref, predefinedSubs[mainCategoryName] ?? [], null),
      data: (cats) {
        final subs = <String>[
          ...?predefinedSubs[mainCategoryName]
        ];
        UserCategoryModel? customMain;
        try {
          customMain = cats.firstWhere(
              (c) => c.categoryName == mainCategoryName && !c.isArchived);
          for (final s in customMain.subcategories) {
            if (!subs.contains(s)) subs.add(s);
          }
        } catch (_) {}
        subs.sort();
        return _buildList(context, ref, subs, customMain);
      },
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref,
      List<String> subs, UserCategoryModel? customMain) {
    final canAdd = customMain?.id != null;

    if (subs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '"$mainCategoryName" için Alt Kategori Yok.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            if (canAdd)
              CupertinoButton(
                onPressed: () =>
                    _showAddSubDialog(context, ref, customMain!),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.add_circled_solid, size: 18),
                    SizedBox(width: 8),
                    Text('İlk Alt Kategoriyi Ekle'),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            CupertinoButton(
              onPressed: onProceedWithoutSubcategory,
              child: const Text('Alt Kategori Olmadan Devam Et',
                  style:
                      TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '"$mainCategoryName" için Alt Kategori Seçin',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (canAdd)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () =>
                  _showAddSubDialog(context, ref, customMain!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryBlue, width: 0.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.add_circled_solid,
                        color: AppColors.primaryBlue, size: 18),
                    SizedBox(width: 8),
                    Text('Yeni Alt Kategori Ekle',
                        style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: subs.length + 1,
              separatorBuilder: (_, __) =>
                  Container(height: 0.5, color: AppColors.separator),
              itemBuilder: (ctx, i) {
                if (i == subs.length) {
                  return CupertinoButton(
                    onPressed: onProceedWithoutSubcategory,
                    child: const Text('Alt Kategoriyi Atla',
                        style: TextStyle(
                            color: AppColors.textSecondary)),
                  );
                }
                final name = subs[i];
                final sel = name == selectedSubCategory;
                return GestureDetector(
                  onTap: () => onSubCategorySelected(name),
                  child: Container(
                    color: sel
                        ? AppColors.primaryBlue.withValues(alpha: 0.1)
                        : AppColors.backgroundDark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: sel
                                  ? AppColors.primaryBlue
                                  : AppColors.textPrimary,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (sel)
                          const Icon(CupertinoIcons.checkmark,
                              color: AppColors.primaryBlue, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4: Details Entry
// ─────────────────────────────────────────────────────────────────────────────

class _DetailsEntryStep extends ConsumerStatefulWidget {
  const _DetailsEntryStep({super.key});

  @override
  ConsumerState<_DetailsEntryStep> createState() =>
      _DetailsEntryStepState();
}

class _DetailsEntryStepState
    extends ConsumerState<_DetailsEntryStep> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _recurrenceCtrl;
  late final TextEditingController _incomePctCtrl;

  bool _isRecurring = false;
  bool? _isNeed;
  String? _selectedEmotion;
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final fd = ref.read(transactionFormNotifierProvider);
    _amountCtrl =
        TextEditingController(text: fd.amount?.toStringAsFixed(2) ?? '');
    _descCtrl =
        TextEditingController(text: fd.description ?? '');
    _recurrenceCtrl =
        TextEditingController(text: fd.recurrenceRule ?? '');
    _incomePctCtrl = TextEditingController(
        text: fd.incomeAllocationPct?.toString() ?? '');
    _selectedDate = fd.date;
    _isRecurring = fd.isRecurring;
    _isNeed = fd.isNeed;
    _selectedEmotion = fd.emotion;
    _selectedAccountId = fd.account;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _recurrenceCtrl.dispose();
    _incomePctCtrl.dispose();
    super.dispose();
  }

  BoxDecoration get _fieldDecor => BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      );

  void _pickDate() {
    DateTime tempDate = _selectedDate;
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
                const Text('Tarih Seç',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                CupertinoButton(
                  child: const Text('Uygula',
                      style:
                          TextStyle(color: AppColors.primaryBlue)),
                  onPressed: () {
                    ref
                        .read(transactionFormNotifierProvider.notifier)
                        .updateDate(tempDate);
                    setState(() => _selectedDate = tempDate);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(2000),
                onDateTimeChanged: (d) => tempDate = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickAccount(List<dynamic> accounts) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Hesap Seç'),
        actions: accounts
            .map((a) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _selectedAccountId = a.id);
                    ref
                        .read(transactionFormNotifierProvider.notifier)
                        .updateAccount(a.id);
                    Navigator.of(context).pop();
                  },
                  child: Text('${a.accountName} (${a.currency})'),
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

  void _pickEmotion() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Bu harcamadan nasıl hissettiniz?'),
        actions: kEmotionList
            .map((e) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _selectedEmotion = e);
                    ref
                        .read(transactionFormNotifierProvider.notifier)
                        .updateEmotion(e);
                    Navigator.of(context).pop();
                  },
                  child: Text(e),
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

  @override
  Widget build(BuildContext context) {
    final txType =
        ref.watch(transactionFormNotifierProvider.select((d) => d.type));
    final dateLabel =
        DateFormat('dd MMM yyyy', 'tr').format(_selectedDate);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'İşlem Detaylarını Girin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // ── Amount ──────────────────────────────────────────────────────────
          const Text('Tutar',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            placeholder: '0.00',
            placeholderStyle:
                const TextStyle(color: AppColors.textSecondary),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _fieldDecor,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            onChanged: (v) {
              final parsed =
                  double.tryParse(v.replaceAll(',', '.').trim());
              ref
                  .read(transactionFormNotifierProvider.notifier)
                  .updateAmount(parsed);
            },
          ),
          const SizedBox(height: 16),

          // ── Date ────────────────────────────────────────────────────────────
          const Text('Tarih',
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
                      style: const TextStyle(
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Account ─────────────────────────────────────────────────────────
          const Text('Hesap',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Consumer(builder: (ctx, ref, _) {
            final val = ref.watch(accountsProvider);
            return val.when(
              data: (accounts) {
                // auto-select first if nothing chosen yet
                if (_selectedAccountId == null &&
                    accounts.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(
                        () => _selectedAccountId = accounts.first.id);
                    ref
                        .read(transactionFormNotifierProvider.notifier)
                        .updateAccount(accounts.first.id);
                  });
                }
                final found = accounts
                    .where((a) => a.id == _selectedAccountId)
                    .toList();
                final selected =
                    found.isNotEmpty ? found.first : null;
                return GestureDetector(
                  onTap: accounts.isNotEmpty
                      ? () => _pickAccount(accounts)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: _fieldDecor,
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.creditcard,
                            color: AppColors.primaryBlue, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selected != null
                                ? '${selected.accountName} (${selected.currency})'
                                : 'Hesap seçin',
                            style: TextStyle(
                              color: selected != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Icon(CupertinoIcons.chevron_down,
                            color: AppColors.textSecondary,
                            size: 14),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                  child: CupertinoActivityIndicator()),
              error: (_, __) => const Text('Hesaplar yüklenemedi.',
                  style: TextStyle(color: AppColors.danger)),
            );
          }),
          const SizedBox(height: 16),

          // ── Description ─────────────────────────────────────────────────────
          const Text('Açıklama (İsteğe Bağlı)',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: _descCtrl,
            placeholder: 'Kısa açıklama...',
            placeholderStyle:
                const TextStyle(color: AppColors.textSecondary),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _fieldDecor,
            maxLines: 2,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            onChanged: (v) => ref
                .read(transactionFormNotifierProvider.notifier)
                .updateDescription(
                    v.trim().isEmpty ? null : v.trim()),
          ),
          const SizedBox(height: 16),

          // ── Recurring ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: _fieldDecor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tekrarlanan Girdi mi?',
                    style:
                        TextStyle(color: AppColors.textPrimary)),
                CupertinoSwitch(
                  value: _isRecurring,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (v) {
                    setState(() => _isRecurring = v);
                    ref
                        .read(transactionFormNotifierProvider.notifier)
                        .updateIsRecurring(v);
                    if (!v) {
                      _recurrenceCtrl.clear();
                      ref
                          .read(
                              transactionFormNotifierProvider.notifier)
                          .updateRecurrenceRule(null);
                    }
                  },
                ),
              ],
            ),
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: _recurrenceCtrl,
              placeholder: 'Tekrarlama Kuralı (Örn: FREQ=MONTHLY)',
              placeholderStyle:
                  const TextStyle(color: AppColors.textSecondary),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecor,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              onChanged: (v) => ref
                  .read(transactionFormNotifierProvider.notifier)
                  .updateRecurrenceRule(
                      v.trim().isEmpty ? null : v.trim()),
            ),
          ],
          const SizedBox(height: 16),

          // ── Income-specific ─────────────────────────────────────────────────
          if (txType == 'income') ...[
            const Text('Gelire Özgü Detaylar',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            Container(
                height: 0.5,
                color: AppColors.separator,
                margin:
                    const EdgeInsets.symmetric(vertical: 8)),
            const Text('Birikime Ayrılacak (%)',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _incomePctCtrl,
              placeholder: '0–100',
              placeholderStyle:
                  const TextStyle(color: AppColors.textSecondary),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecor,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              onChanged: (v) {
                final val = int.tryParse(v);
                ref
                    .read(transactionFormNotifierProvider.notifier)
                    .updateIncomeAllocationPct(val ?? 0);
              },
            ),
            const SizedBox(height: 16),
          ],

          // ── Expense-specific ────────────────────────────────────────────────
          if (txType == 'expense') ...[
            const Text('Gidere Özgü Detaylar',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            Container(
                height: 0.5,
                color: AppColors.separator,
                margin:
                    const EdgeInsets.symmetric(vertical: 8)),
            const Text('Bu bir "İstek" mi, "İhtiyaç" mı?',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final nv = _isNeed == false ? null : false;
                      setState(() => _isNeed = nv);
                      ref
                          .read(
                              transactionFormNotifierProvider.notifier)
                          .updateIsNeed(nv);
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isNeed == false
                            ? AppColors.primaryBlue
                                .withValues(alpha: 0.2)
                            : AppColors.surfaceGlass,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isNeed == false
                              ? AppColors.primaryBlue
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Text('İstek',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isNeed == false
                                ? AppColors.primaryBlue
                                : AppColors.textSecondary,
                            fontWeight: _isNeed == false
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final nv = _isNeed == true ? null : true;
                      setState(() => _isNeed = nv);
                      ref
                          .read(
                              transactionFormNotifierProvider.notifier)
                          .updateIsNeed(nv);
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isNeed == true
                            ? AppColors.incomeGreen
                                .withValues(alpha: 0.2)
                            : AppColors.surfaceGlass,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isNeed == true
                              ? AppColors.incomeGreen
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Text('İhtiyaç',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isNeed == true
                                ? AppColors.incomeGreen
                                : AppColors.textSecondary,
                            fontWeight: _isNeed == true
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Bu harcamadan nasıl hissettiniz?',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickEmotion,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: _fieldDecor,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedEmotion ??
                            'Duygu seçin (isteğe bağlı)',
                        style: TextStyle(
                          color: _selectedEmotion != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Icon(CupertinoIcons.chevron_down,
                        color: AppColors.textSecondary, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
