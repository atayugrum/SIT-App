// File: flutter_app/lib/src/presentation/screens/settings/manage_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_category_model.dart';
import '../../providers/category_providers.dart';
import 'add_edit_category_form_screen.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Colors.teal.shade700;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Özel Kategorileri Yönet'),
          backgroundColor: Colors.grey.shade100,
          elevation: 0,
          foregroundColor: Colors.grey.shade800,
          bottom: TabBar(
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: 'Gelir Kategorileri'),
              Tab(text: 'Gider Kategorileri'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Kategorileri Yenile',
              onPressed: () {
                ref.invalidate(incomeCustomCategoriesProvider);
                ref.invalidate(expenseCustomCategoriesProvider);
              },
            )
          ],
        ),
        body: TabBarView(
          children: [
            _CategoryList(
                type: 'income', provider: incomeCustomCategoriesProvider),
            _CategoryList(
                type: 'expense', provider: expenseCustomCategoriesProvider),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const AddEditCategoryFormScreen())),
          label: const Text('Yeni Kategori'),
          icon: const Icon(Icons.add),
          backgroundColor: primaryColor,
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

  void _navigateToEditCategory(
      BuildContext context, WidgetRef ref, UserCategoryModel category) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            AddEditCategoryFormScreen(categoryToEdit: category)));
  }

  void _confirmAndDeleteCategory(
      BuildContext context, WidgetRef ref, UserCategoryModel category) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text(
            '"${category.categoryName}" kategorisini silmek istediğinizden emin misiniz?'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal')),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Sil'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                if (category.id == null)
                  throw Exception("Kategori ID bulunamadı.");
                await ref
                    .read(provider.notifier)
                    .deleteCustomCategory(category.id!);
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Kategori başarıyla silindi!'),
                      backgroundColor: Colors.green));
              } catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Hata: ${e.toString().replaceFirst("Exception: ", "")}'),
                      backgroundColor: Colors.redAccent));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCategories = ref.watch(provider);
    final theme = Theme.of(context);

    return asyncCategories.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                  'Henüz özel ${type == 'income' ? 'gelir' : 'gider'} kategorisi eklemediniz.\nYeni bir tane eklemek için \'+\' butonuna dokunun!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.grey.shade600)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor:
                        (type == 'income' ? Colors.green : Colors.red)
                            .withOpacity(0.1),
                    child: Icon(Icons.label_outline_rounded,
                        color: type == 'income'
                            ? Colors.green.shade700
                            : Colors.red.shade700)),
                title: Text(category.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: category.subcategories.isNotEmpty
                    ? Text(
                        'Alt Kategoriler: ${category.subcategories.join(", ")}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1)
                    : const Text('Alt kategori yok',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, fontSize: 12)),
                trailing: PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'edit')
                      _navigateToEditCategory(context, ref, category);
                    else if (value == 'delete')
                      _confirmAndDeleteCategory(context, ref, category);
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Düzenle'))),
                    const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                            leading:
                                Icon(Icons.delete_outline, color: Colors.red),
                            title: Text('Sil',
                                style: TextStyle(color: Colors.red)))),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Kategoriler yüklenemedi: $err',
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center),
      )),
    );
  }
}
