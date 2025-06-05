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
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Custom Categories'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Income Categories'),
              Tab(text: 'Expense Categories'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Categories',
              onPressed: () {
                // ignore: unused_result
                ref.refresh(incomeCustomCategoriesProvider);
                // ignore: unused_result
                ref.refresh(expenseCustomCategoriesProvider);
              },
            )
          ],
        ),
        body: TabBarView(
          children: [
            _CategoryList(type: 'income', provider: incomeCustomCategoriesProvider),
            _CategoryList(type: 'expense', provider: expenseCustomCategoriesProvider),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => const AddEditCategoryFormScreen(), 
              ),
            ).then((result) {
              if (result == true) { 
                // ignore: unused_result
                ref.refresh(incomeCustomCategoriesProvider);
                // ignore: unused_result
                ref.refresh(expenseCustomCategoriesProvider);
              }
            });
          },
          label: const Text('Add Category'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final String type;
  final StateNotifierProvider<CustomCategoriesNotifier, AsyncValue<List<UserCategoryModel>>> provider;

  const _CategoryList({required this.type, required this.provider});

  void _navigateToEditCategory(BuildContext context, WidgetRef ref, UserCategoryModel category) {
     Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => AddEditCategoryFormScreen(categoryToEdit: category),
        ),
      ).then((result) {
        if (result == true && context.mounted) { 
          // ignore: unused_result
          ref.refresh(incomeCustomCategoriesProvider);
          // ignore: unused_result
          ref.refresh(expenseCustomCategoriesProvider);
        }
      });
  }

  void _confirmAndDeleteCategory(BuildContext context, WidgetRef ref, UserCategoryModel category) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete the category "${category.categoryName}" and all its subcategories? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(ctx).pop(); 
                try {
                  if (category.id == null) {
                    throw Exception("Category ID is null, cannot delete.");
                  }
                  // Call the delete method on the specific notifier instance for this list
                  await ref.read(provider.notifier).deleteCustomCategory(category.id!);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category deleted successfully!'), backgroundColor: Colors.green),
                    );
                    // The list will rebuild automatically due to the provider state change.
                    // No need to call ref.refresh here if deleteCustomCategory updates the state correctly.
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting category: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCategories = ref.watch(provider);
    final theme = Theme.of(context);

    return asyncCategories.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center( /* ... No categories message as before ... */ 
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No custom $type categories found.\nTap "+" to add your first one!',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: ListTile(
                leading: Icon(
                  Icons.label_outline_rounded, // Generic icon for custom categories
                  color: type == 'income' ? Colors.green.shade700 : Colors.red.shade700,
                ),
                title: Text(category.categoryName, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: category.subcategories.isNotEmpty
                    ? Text('Sub: ${category.subcategories.join(", ")}', 
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis, maxLines: 1,
                          )
                    : const Text('No subcategories', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: "Options",
                  onSelected: (String value) {
                    if (value == 'edit') {
                      _navigateToEditCategory(context, ref, category);
                    } else if (value == 'delete') {
                      _confirmAndDeleteCategory(context, ref, category);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete', style: TextStyle(color: Colors.red))),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) { /* ... error handling as before ... */ 
        print("Error loading custom $type categories: $err\n$stack");
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading $type categories: ${err.toString().replaceFirst("Exception: ", "")}',
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          )
        );
      },
    );
  }
}