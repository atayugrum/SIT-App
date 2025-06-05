// File: flutter_app/lib/src/presentation/providers/category_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_category_model.dart';
import '../../data/services/category_flutter_service.dart';

final categoryFlutterServiceProvider = Provider<CategoryFlutterService>((ref) {
  return CategoryFlutterService(ref);
});

class CustomCategoriesNotifier extends StateNotifier<AsyncValue<List<UserCategoryModel>>> {
  final CategoryFlutterService _service;
  final String? _categoryType; 

  CustomCategoriesNotifier(this._service, [this._categoryType]) : super(const AsyncValue.loading()) {
    fetchCustomCategories();
  }

  Future<void> fetchCustomCategories() async {
    print("CUSTOM_CATEGORIES_PROVIDER: Fetching categories (type: $_categoryType)...");
    state = const AsyncValue.loading();
    try {
      final categories = await _service.listCategories(categoryType: _categoryType);
      state = AsyncValue.data(categories);
      print("CUSTOM_CATEGORIES_PROVIDER: Categories fetched successfully, count: ${categories.length}");
    } catch (e, s) {
      print("CUSTOM_CATEGORIES_PROVIDER: Error fetching categories: $e\n$s");
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addCategory(UserCategoryModel category) async {
    try {
      await _service.createCategory(category);
      await fetchCustomCategories(); 
    } catch (e) {
      print("CUSTOM_CATEGORIES_PROVIDER: Error adding category: $e");
      rethrow; 
    }
  }

  // NEW: Update Category
  Future<void> updateCustomCategory(UserCategoryModel category) async {
    if (category.id == null) {
      print("CUSTOM_CATEGORIES_PROVIDER: Category ID is null, cannot update.");
      throw ArgumentError("Category ID cannot be null for update.");
    }
    try {
      await _service.updateCategory(category.id!, category);
      await fetchCustomCategories(); // Refresh the list
    } catch (e) {
      print("CUSTOM_CATEGORIES_PROVIDER: Error updating category: $e");
      rethrow;
    }
  }

  // NEW: Delete Category
  Future<void> deleteCustomCategory(String categoryId) async {
    try {
      await _service.deleteCategory(categoryId);
      // Optimistic update: remove from local list immediately
      // state = state.whenData((categories) => categories.where((cat) => cat.id != categoryId).toList());
      // Or simply refetch:
      await fetchCustomCategories();
    } catch (e) {
      print("CUSTOM_CATEGORIES_PROVIDER: Error deleting category: $e");
      rethrow;
    }
  }
}

final allCustomCategoriesProvider = StateNotifierProvider<CustomCategoriesNotifier, AsyncValue<List<UserCategoryModel>>>((ref) {
  return CustomCategoriesNotifier(ref.watch(categoryFlutterServiceProvider));
});

final incomeCustomCategoriesProvider = StateNotifierProvider<CustomCategoriesNotifier, AsyncValue<List<UserCategoryModel>>>((ref) {
  return CustomCategoriesNotifier(ref.watch(categoryFlutterServiceProvider), 'income');
});

final expenseCustomCategoriesProvider = StateNotifierProvider<CustomCategoriesNotifier, AsyncValue<List<UserCategoryModel>>>((ref) {
  return CustomCategoriesNotifier(ref.watch(categoryFlutterServiceProvider), 'expense');
});