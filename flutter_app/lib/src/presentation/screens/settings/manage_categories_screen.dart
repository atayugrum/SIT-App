// File: flutter_app/lib/src/presentation/screens/settings/manage_categories_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_category_model.dart';
import '../../providers/category_providers.dart';
import '../../widgets/glass_card.dart';
import 'add_edit_category_form_screen.dart';

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState
    extends ConsumerState<ManageCategoriesScreen> {
  int _selectedSegment = 0; // 0=Gider, 1=Gelir

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Özel Kategoriler'),
        backgroundColor: const Color(0xCC000000),
        border: const Border(
            bottom:
                BorderSide(color: AppColors.separator, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            ref.invalidate(incomeCustomCategoriesProvider);
            ref.invalidate(expenseCustomCategoriesProvider);
          },
          child: const Icon(CupertinoIcons.refresh,
              color: AppColors.primaryBlue, size: 20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedSegment,
                backgroundColor: AppColors.surfaceGlass,
                thumbColor: AppColors.primaryBlue,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Gider Kategorileri',
                        style: TextStyle(fontSize: 13)),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Gelir Kategorileri',
                        style: TextStyle(fontSize: 13)),
                  ),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _selectedSegment = v);
                },
              ),
            ),
            Expanded(
              child: _selectedSegment == 0
                  ? _CategoryList(
                      type: 'expense',
                      provider: expenseCustomCategoriesProvider)
                  : _CategoryList(
                      type: 'income',
                      provider: incomeCustomCategoriesProvider),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton.filled(
                borderRadius: BorderRadius.circular(12),
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute(
                      builder: (_) =>
                          const AddEditCategoryFormScreen()),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.add, size: 18),
                    SizedBox(width: 8),
                    Text('Yeni Kategori'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final String type;
  final StateNotifierProvider<CustomCategoriesNotifier,
      AsyncValue<List<UserCategoryModel>>> provider;

  const _CategoryList({required this.type, required this.provider});

  void _showActions(BuildContext context, WidgetRef ref,
      UserCategoryModel category) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) => AddEditCategoryFormScreen(
                      categoryToEdit: category)));
            },
            child: const Text('Düzenle'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelete(context, ref, category);
            },
            child: const Text('Sil'),
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

  void _confirmDelete(BuildContext context, WidgetRef ref,
      UserCategoryModel category) {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text(
            '"${category.categoryName}" kategorisini silmek istediğinizden emin misiniz?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                if (category.id == null) {
                  throw Exception('Kategori ID bulunamadı.');
                }
                await ref
                    .read(provider.notifier)
                    .deleteCustomCategory(category.id!);
              } catch (_) {}
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCategories = ref.watch(provider);
    final typeLabel = type == 'income' ? 'gelir' : 'gider';
    final iconColor =
        type == 'income' ? AppColors.incomeGreen : AppColors.danger;

    return asyncCategories.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Henüz özel $typeLabel kategorisi eklemediniz.\nYeni bir tane eklemek için aşağıdaki butona dokunun!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          );
        }
        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                ref.invalidate(incomeCustomCategoriesProvider);
                ref.invalidate(expenseCustomCategoriesProvider);
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final cat = categories[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Icon(CupertinoIcons.tag_fill,
                                  color: iconColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(cat.categoryName,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w600)),
                                  if (cat.subcategories.isNotEmpty)
                                    Text(
                                      cat.subcategories.join(', '),
                                      style: const TextStyle(
                                          color:
                                              AppColors.textSecondary,
                                          fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    )
                                  else
                                    const Text('Alt kategori yok',
                                        style: TextStyle(
                                            color:
                                                AppColors.textSecondary,
                                            fontSize: 12,
                                            fontStyle:
                                                FontStyle.italic)),
                                ],
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () =>
                                  _showActions(context, ref, cat),
                              child: const Icon(CupertinoIcons.ellipsis,
                                  color: AppColors.textSecondary,
                                  size: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: categories.length,
                ),
              ),
            ),
          ],
        );
      },
      loading: () =>
          const Center(child: CupertinoActivityIndicator()),
      error: (err, _) => Center(
        child: Text('Kategoriler yüklenemedi: $err',
            style: const TextStyle(color: AppColors.danger),
            textAlign: TextAlign.center),
      ),
    );
  }
}
