// File: flutter_app/lib/src/presentation/providers/category_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart'; // Gerekli import eklendi
import '../../data/models/user_category_model.dart';
import '../../data/services/category_flutter_service.dart';

final categoryFlutterServiceProvider = Provider<CategoryFlutterService>((ref) {
  return CategoryFlutterService(ref);
});

class CustomCategoriesNotifier
    extends StateNotifier<AsyncValue<List<UserCategoryModel>>> {
  final CategoryFlutterService _service;
  final String? _categoryType;
  final _logger = Logger(); // Logger nesnesi eklendi

  CustomCategoriesNotifier(this._service, [this._categoryType])
      : super(const AsyncValue.loading()) {
    fetchCustomCategories();
  }

  Future<void> fetchCustomCategories() async {
    _logger.i("Fetching categories (type: ${_categoryType ?? 'all'})...");
    state = const AsyncValue.loading();
    try {
      final categories =
          await _service.listCategories(categoryType: _categoryType);
      state = AsyncValue.data(categories);
      _logger.i("Categories fetched successfully, count: ${categories.length}");
    } catch (e, s) {
      _logger.e("Error fetching categories", error: e, stackTrace: s);
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addCategory(UserCategoryModel category) async {
    try {
      await _service.createCategory(category);
      await fetchCustomCategories();
    } catch (e) {
      _logger.e("Error adding category", error: e);
      rethrow;
    }
  }

  Future<void> updateCustomCategory(UserCategoryModel category) async {
    if (category.id == null) {
      _logger.w("Category ID is null, cannot update.");
      throw ArgumentError("Category ID cannot be null for update.");
    }
    try {
      await _service.updateCategory(category.id!, category);
      await fetchCustomCategories(); // Listeyi yenile
    } catch (e) {
      _logger.e("Error updating category: ${category.id}", error: e);
      rethrow;
    }
  }

  Future<void> deleteCustomCategory(String categoryId) async {
    try {
      await _service.deleteCategory(categoryId);
      await fetchCustomCategories();
    } catch (e) {
      _logger.e("Error deleting category: $categoryId", error: e);
      rethrow;
    }
  }
}

// Bu provider tanımlamalarında bir değişiklik yok.
final allCustomCategoriesProvider = StateNotifierProvider<
    CustomCategoriesNotifier, AsyncValue<List<UserCategoryModel>>>((ref) {
  return CustomCategoriesNotifier(ref.watch(categoryFlutterServiceProvider));
});

final incomeCustomCategoriesProvider = StateNotifierProvider<
    CustomCategoriesNotifier, AsyncValue<List<UserCategoryModel>>>((ref) {
  return CustomCategoriesNotifier(
      ref.watch(categoryFlutterServiceProvider), 'income');
});

final expenseCustomCategoriesProvider = StateNotifierProvider<
    CustomCategoriesNotifier, AsyncValue<List<UserCategoryModel>>>((ref) {
  return CustomCategoriesNotifier(
      ref.watch(categoryFlutterServiceProvider), 'expense');
});
