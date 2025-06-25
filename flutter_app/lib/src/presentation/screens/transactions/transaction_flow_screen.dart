// File: lib/src/presentation/screens/transactions/transaction_flow_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
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
      validationMessage = 'Lütfen bir işlem türü seçin.';
    } else if (_currentPage == 1 && formData.category == null) {
      canProceed = false;
      validationMessage = 'Lütfen bir kategori seçin.';
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
            content: Text('Lütfen formdaki hataları düzeltin.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    _detailsFormKey.currentState!.save();

    if (mounted) setState(() => _isSaving = true);

    // HATA DÜZELTMESİ: Kullanılmayan 'formData' değişkeni bu satırda kaldırıldı.
    final notifier = ref.read(transactionFormNotifierProvider.notifier);
    final modelToSave = notifier.toTransactionModel();

    if (modelToSave == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form verileri eksik. Kaydedilemiyor.'),
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
        await ref
            .read(transactionsProvider.notifier)
            .addTransaction(modelToSave);
      }

      if (mounted) {
        ref.invalidate(accountsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isEditMode ? 'İşlem güncellendi!' : 'İşlem kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Hata: ${e.toString().replaceFirst("Exception: ", "")}'),
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
    final bool isLastStep = _currentPage == steps.length - 1;
    String appBarTitle = _isEditMode ? 'İşlemi Düzenle' : 'İşlem Ekle';
    appBarTitle += ' (Adım ${_currentPage + 1}/${steps.length})';
    const primaryColor = Color(0xFF00796B); // Colors.teal.shade700

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
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
                        ? primaryColor
                        : Colors.grey.shade400,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_circle_outline),
                        label: const Text('Kaydet & Yeni Ekle'),
                        onPressed: _isSaving
                            ? null
                            : () => _handleSave(addAnother: true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0)),
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
                      label: Text(_isEditMode
                          ? 'Güncelle ve Kapat'
                          : 'Kaydet ve Kapat'),
                      onPressed: _isSaving
                          ? null
                          : () => _handleSave(addAnother: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                      ),
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
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
            'Ne tür bir işlem?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          _TypeButton(
            key: const ValueKey('incomeButton'),
            label: 'Gelir',
            icon: Icons.arrow_downward_rounded,
            isSelected: selectedType == 'income',
            onPressed: () => onTypeSelected('income'),
            color: Colors.green.shade600,
          ),
          const SizedBox(height: 20),
          _TypeButton(
            key: const ValueKey('expenseButton'),
            label: 'Gider',
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
    const primaryColor = Color(0xFF00796B);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            title: Text(
              currentTransactionType == 'income'
                  ? 'Yeni Gelir Kategorisi Ekle'
                  : 'Yeni Gider Kategorisi Ekle',
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: 'Kategori Adı *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: primaryColor, width: 2)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Lütfen bir kategori adı girin'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: subcategoriesController,
                    decoration: InputDecoration(
                      labelText: 'Alt Kategoriler (İsteğe Bağlı)',
                      hintText: 'Örn: Alt1, Alt2',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: primaryColor, width: 2)),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => isLoading = true);
                        final user = ref.read(currentUserProvider);
                        if (user == null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kullanıcı girişi yapılmamış.'),
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

                          // DÜZELTME: `await` sonrası context kullanımı öncesi kontrol
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text("'${newCat.categoryName}' eklendi!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          onCategorySelected(newCat.categoryName);

                          // DÜZELTME: `await` sonrası context kullanımı öncesi kontrol
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                        } catch (e) {
                          // DÜZELTME: `await` sonrası context kullanımı öncesi kontrol
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Başarısız: ${e.toString().replaceFirst("Exception: ", "")}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          // EK İYİLEŞTİRME: Diyalogun hala ekranda olduğundan emin ol
                          if (ctx.mounted) {
                            setState(() => isLoading = false);
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kategoriyi Kaydet'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFF00796B);
    const tintedBackgroundColor = Color(0xFFE0F2F1);
    final predefined =
        transactionType == 'income' ? incomeCategories : expenseCategories;
    final asyncCats = transactionType == 'income'
        ? ref.watch(incomeCustomCategoriesProvider)
        : ref.watch(expenseCustomCategoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '${transactionType == 'income' ? 'Geliriniz' : 'Gideriniz'} için bir Kategori Seçin',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Yeni Özel Kategori Ekle'),
            onPressed: () =>
                _showAddCategoryDialog(context, ref, transactionType),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Veya aşağıdakilerden birini seçin:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncCats.when(
              data: (customs) {
                final keys = <String>[
                  ...predefined.keys,
                  ...customs.map((c) => c.categoryName)
                ];
                final icons = <String, IconData>{}
                  ..addAll(predefined)
                  ..addEntries(customs.map(
                      (c) => MapEntry(c.categoryName, Icons.label_outline)));
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
                              color: isSel ? primaryColor : Colors.transparent,
                              width: 2.5),
                        ),
                        color: isSel ? tintedBackgroundColor : Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              icons[name] ?? Icons.help_outline,
                              size: 36,
                              // DÜZELTME: withOpacity yerine withAlpha kullanıldı
                              color: isSel
                                  ? primaryColor
                                  : Theme.of(context)
                                      .iconTheme
                                      .color!
                                      .withAlpha(179), // 0.7 opacity
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSel ? primaryColor : null,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Hata: $err')),
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
    const primaryColor = Color(0xFF00796B);
    const tintedBackgroundColor = Color(0xFFE0F2F1);

    if (mainCategoryName == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onProceedWithoutSubcategory();
      });
      return const Center(
        child: Text('Ana kategori seçilmedi. Devam ediliyor...'),
      );
    }

    final predefinedSubs = transactionType == 'income'
        ? incomeSubcategories
        : expenseSubcategories;
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
        final found = cats
            .where((c) => c.categoryName == mainCategoryName && !c.isArchived);
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
              '"$mainCategoryName" için Alt Kategori Yok.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            if (canAdd)
              ElevatedButton.icon(
                onPressed: () =>
                    _showAddSubDialog(context, ref, mainCategoryName!),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('İlk Alt Kategoriyi Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                ),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onProceedWithoutSubcategory,
              child: const Text('Alt Kategori Olmadan Devam Et'),
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
            '"$mainCategoryName" için Alt Kategori Seçin',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 12),
          if (canAdd)
            OutlinedButton.icon(
              onPressed: () =>
                  _showAddSubDialog(context, ref, mainCategoryName!),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Yeni Alt Kategori Ekle"),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0))),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: subs.length,
              itemBuilder: (ctx, i) {
                final name = subs[i];
                final sel = name == selectedSubCategory;
                return Card(
                  elevation: sel ? 3 : 1,
                  color: sel ? tintedBackgroundColor : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: sel ? primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      name,
                      style: TextStyle(
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          color: sel ? primaryColor : null),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: () => onSubCategorySelected(name),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onProceedWithoutSubcategory,
            child: const Text('Alt Kategoriyi Atla'),
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
    const primaryColor = Color(0xFF00796B);

    final cats = transactionType == 'income'
        ? ref.read(incomeCustomCategoriesProvider)
        : ref.read(expenseCustomCategoriesProvider);

    UserCategoryModel? target;
    if (cats.hasValue) {
      try {
        target = cats.value!
            .firstWhere((c) => c.categoryName == mainCatName && !c.isArchived);
      } catch (_) {}
    }
    final can = target?.id != null;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            title: Text('"$mainCatName" Kategorisine Alt Kategori Ekle'),
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
                            ? 'Yükleniyor...'
                            : 'Alt kategoriler yalnızca özel kategoriler için eklenebilir.',
                        style:
                            TextStyle(color: Theme.of(ctx).colorScheme.error),
                      ),
                    ),
                  TextFormField(
                    controller: ctrl,
                    enabled: can,
                    decoration: InputDecoration(
                        labelText: 'İsim *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: primaryColor, width: 2))),
                    validator: (v) {
                      if (!can) return null;
                      if (v == null || v.trim().isEmpty) return 'İsim girin';
                      if (target!.subcategories
                          .map((s) => s.toLowerCase())
                          .contains(v.trim().toLowerCase())) {
                        return '"${v.trim()}" zaten mevcut.';
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
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                ),
                onPressed: loading || !can
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => loading = true);
                        final newName = ctrl.text.trim();
                        final updated = [
                          ...target!.subcategories,
                          if (!target.subcategories
                              .map((s) => s.toLowerCase())
                              .contains(newName.toLowerCase()))
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
                          await ref
                              .read(provider.notifier)
                              .updateCustomCategory(updatedModel);
                          ref.invalidate(allCustomCategoriesProvider);

                          // DÜZELTME: `await` sonrası context kullanımı öncesi kontrol
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Alt kategori "$newName" eklendi!'),
                                backgroundColor: Colors.green),
                          );
                          onSubCategorySelected(newName);

                          // DÜZELTME: `await` sonrası context kullanımı öncesi kontrol
                          if (!dCtx.mounted) return;
                          Navigator.of(dCtx).pop();
                        } catch (e) {
                          // DÜZELTME: `await` sonrası context kullanımı öncesi kontrol
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Başarısız: ${e.toString()}'),
                                backgroundColor: Colors.red),
                          );
                        } finally {
                          if (dCtx.mounted) {
                            setState(() => loading = false);
                          }
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Ekle'),
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
    const primaryColor = Color(0xFF00796B);
    final inputDecoration = InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2)));

    final txType =
        ref.watch(transactionFormNotifierProvider.select((d) => d.type));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: widget.formKey,
        child: ListView(
          children: <Widget>[
            Text(
              'İşlem Detaylarını Girin',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 24),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: inputDecoration.copyWith(labelText: 'Tutar'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Tutar girin';
                final a = double.tryParse(v.replaceAll(',', '.').trim());
                if (a == null || a <= 0)
                  return 'Geçerli pozitif bir tutar girin';
                return null;
              },
              onChanged: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.').trim());
                ref
                    .read(transactionFormNotifierProvider.notifier)
                    .updateAmount(parsed);
              },
              onSaved: (v) {
                final parsed =
                    double.tryParse(v?.replaceAll(',', '.').trim() ?? '');
                ref
                    .read(transactionFormNotifierProvider.notifier)
                    .updateAmount(parsed);
              },
            ),
            const SizedBox(height: 16),

            // Date
            TextFormField(
              controller: _dateController,
              decoration: inputDecoration.copyWith(
                labelText: 'Tarih',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
              readOnly: true,
              onTap: _pickDate,
              validator: (v) => (v == null || v.isEmpty) ? 'Tarih seçin' : null,
            ),
            const SizedBox(height: 16),

            // Account
            Consumer(builder: (ctx, ref, _) {
              final accountsVal = ref.watch(accountsProvider);
              return accountsVal.when(
                data: (accounts) {
                  if (_selectedAccount != null &&
                      !accounts.any((a) => a.id == _selectedAccount)) {
                    _selectedAccount = null;
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedAccount,
                    decoration: inputDecoration.copyWith(labelText: 'Hesap'),
                    hint: const Text('Bir hesap seçin'),
                    isExpanded: true,
                    items: accounts.map((a) {
                      return DropdownMenuItem<String>(
                        value: a.id,
                        child: Text('${a.accountName} (${a.currency})'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedAccount = v),
                    onSaved: (v) => ref
                        .read(transactionFormNotifierProvider.notifier)
                        .updateAccount(v),
                    validator: (v) =>
                        (v == null) ? 'Lütfen bir hesap seçin' : null,
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => TextFormField(
                  initialValue: widget.initialFormData.account,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Hesap (Yükleme Hatası)',
                    errorText: 'Hesaplar yüklenemedi',
                  ),
                  onSaved: (v) => ref
                      .read(transactionFormNotifierProvider.notifier)
                      .updateAccount(v),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Lütfen bir hesap girin'
                      : null,
                ),
              );
            }),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: inputDecoration.copyWith(
                  labelText: 'Açıklama (İsteğe Bağlı)'),
              maxLines: 2,
              onSaved: (v) => ref
                  .read(transactionFormNotifierProvider.notifier)
                  .updateDescription(v?.trim()),
            ),
            const SizedBox(height: 16),

            // Recurring
            SwitchListTile(
              title: const Text('Tekrarlanan Girdi mi?'),
              value: _isRecurring,
              activeColor: primaryColor,
              onChanged: (v) {
                setState(() => _isRecurring = v);
                ref
                    .read(transactionFormNotifierProvider.notifier)
                    .updateIsRecurring(v);
                if (!v) {
                  _recurrenceController.clear();
                  ref
                      .read(transactionFormNotifierProvider.notifier)
                      .updateRecurrenceRule(null);
                }
              },
            ),
            if (_isRecurring) ...<Widget>[
              const SizedBox(height: 8),
              TextFormField(
                controller: _recurrenceController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Tekrarlama Kuralı (İsteğe Bağlı)',
                  hintText: 'Örn: FREQ=MONTHLY',
                ),
                onSaved: (v) => ref
                    .read(transactionFormNotifierProvider.notifier)
                    .updateRecurrenceRule(v?.trim()),
              ),
              const SizedBox(height: 16),
            ],

            // Income specifics
            if (txType == 'income') ...<Widget>[
              Text('Gelire Özgü Detaylar',
                  style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              const SizedBox(height: 8),
              TextFormField(
                controller: _incomePctController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Birikime Ayrılacak (%)',
                  hintText: '0-100',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final val = int.tryParse(v);
                    // DÜZELTME: Tek satırlık if, süslü parantez içine alındı
                    if (val == null || val < 0 || val > 100) {
                      return '0-100 arasında olmalı';
                    }
                  }
                  return null;
                },
                onSaved: (v) => ref
                    .read(transactionFormNotifierProvider.notifier)
                    .updateIncomeAllocationPct(
                      v != null && v.isNotEmpty ? int.parse(v) : 0,
                    ),
              ),
              const SizedBox(height: 16),
            ],

            // Expense specifics
            if (txType == 'expense') ...<Widget>[
              Text('Gidere Özgü Detaylar',
                  style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Bu bir "İstek" mi, "İhtiyaç" mı?'),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  FilterChip(
                      label: const Text('İstek'),
                      selectedColor: const Color(0xFFE0F2F1), // tinted
                      selected: _isNeed == false,
                      onSelected: (sel) {
                        setState(() => _isNeed = sel ? false : null);
                        ref
                            .read(transactionFormNotifierProvider.notifier)
                            .updateIsNeed(sel ? false : null);
                      }),
                  const SizedBox(width: 8),
                  FilterChip(
                      label: const Text('İhtiyaç'),
                      selectedColor: const Color(0xFFE0F2F1), // tinted
                      selected: _isNeed == true,
                      onSelected: (sel) {
                        setState(() => _isNeed = sel ? true : null);
                        ref
                            .read(transactionFormNotifierProvider.notifier)
                            .updateIsNeed(sel ? true : null);
                      }),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedEmotion,
                decoration: inputDecoration.copyWith(
                  labelText: 'Bu harcamadan sonra nasıl hissettiniz?',
                ),
                items: kEmotionList
                    .map((e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedEmotion = v),
                onSaved: (v) => ref
                    .read(transactionFormNotifierProvider.notifier)
                    .updateEmotion(v),
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
        backgroundColor: isSelected ? color : Colors.grey.shade500,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isSelected ? 4 : 2,
      ),
    );
  }
}
