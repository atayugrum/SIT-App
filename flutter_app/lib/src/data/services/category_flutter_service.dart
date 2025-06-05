// File: flutter_app/lib/src/data/services/category_flutter_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/user_category_model.dart';
import '../../presentation/providers/auth_providers.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryFlutterService {
  static const String _flaskApiBaseUrl = 'http://10.0.2.2:5000'; 
  final Ref _ref;

  CategoryFlutterService(this._ref);

  Future<UserCategoryModel> createCategory(UserCategoryModel category) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception("User not logged in. Cannot create category.");
    }

    final Map<String, dynamic> categoryDataForApi = category.toMapForApi()
        ..['userId'] = currentUser.uid;

    final url = Uri.parse('$_flaskApiBaseUrl/api/categories');
    print("CATEGORY_FLUTTER_SERVICE: Creating category at $url with data: ${jsonEncode(categoryDataForApi)}");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(categoryDataForApi),
      ).timeout(const Duration(seconds: 10));

      print("CATEGORY_FLUTTER_SERVICE: Create response status: ${response.statusCode}");

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('category')) {
          print("CATEGORY_FLUTTER_SERVICE: Custom category created: ${responseData['category']}");
          return UserCategoryModel.fromMap(responseData['category'] as Map<String, dynamic>);
        } else {
          throw Exception(responseData['error'] ?? 'Failed to create category: Unexpected API response format.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print("CATEGORY_FLUTTER_SERVICE: Error creating category - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to create category: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("CATEGORY_FLUTTER_SERVICE: Exception during createCategory: $e\n$s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is your Flask API server running and accessible?');
      }
      rethrow;
    }
  }

  Future<List<UserCategoryModel>> listCategories({String? categoryType}) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      print("CATEGORY_FLUTTER_SERVICE: User not logged in. Cannot list categories.");
      return [];
    }

    final Map<String, String> queryParams = {'userId': currentUser.uid};
    if (categoryType != null) {
      queryParams['type'] = categoryType;
    }

    final url = Uri.parse('$_flaskApiBaseUrl/api/categories').replace(queryParameters: queryParams);
    print("CATEGORY_FLUTTER_SERVICE: Listing categories from $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print("CATEGORY_FLUTTER_SERVICE: List response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('categories')) {
          final List<dynamic> categoriesData = responseData['categories'];
          final categories = categoriesData
              .map((data) => UserCategoryModel.fromMap(data as Map<String, dynamic>))
              .toList();
          print("CATEGORY_FLUTTER_SERVICE: Fetched ${categories.length} custom categories.");
          return categories;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to list categories: Unexpected API response format.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print("CATEGORY_FLUTTER_SERVICE: Error listing categories - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to list categories: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("CATEGORY_FLUTTER_SERVICE: Exception during listCategories: $e\n$s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is your Flask API server running and accessible?');
      }
      rethrow;
    }
  }

  // NEW: Update Category
  Future<UserCategoryModel> updateCategory(String categoryId, UserCategoryModel category) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception("User not logged in. Cannot update category.");
    }
    // Backend expects only fields to update, but also needs userId for auth (handled by backend route if from token)
    // Our current Flask route for PUT expects userId in payload if not using token auth yet.
    final Map<String, dynamic> categoryUpdateData = category.toMapForApi()
        ..['userId'] = currentUser.uid; // Pass userId for backend auth check for now
                                      // Remove other non-updatable fields if necessary,
                                      // but Flask service selects allowed fields.

    final url = Uri.parse('$_flaskApiBaseUrl/api/categories/$categoryId');
    print("CATEGORY_FLUTTER_SERVICE: Updating category $categoryId at $url with data: ${jsonEncode(categoryUpdateData)}");

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(categoryUpdateData),
      ).timeout(const Duration(seconds: 10));

      print("CATEGORY_FLUTTER_SERVICE: Update response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('category')) {
          print("CATEGORY_FLUTTER_SERVICE: Category updated: ${responseData['category']}");
          return UserCategoryModel.fromMap(responseData['category'] as Map<String, dynamic>);
        } else {
          throw Exception(responseData['error'] ?? 'Failed to update category: Unexpected API response.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        print("CATEGORY_FLUTTER_SERVICE: Error updating category - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to update category: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("CATEGORY_FLUTTER_SERVICE: Exception during updateCategory: $e\n$s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is API server running?');
      }
      rethrow;
    }
  }

  // NEW: Delete Category
  Future<void> deleteCategory(String categoryId) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      throw Exception("User not logged in. Cannot delete category.");
    }

    final url = Uri.parse('$_flaskApiBaseUrl/api/categories/$categoryId').replace(queryParameters: {'userId': currentUser.uid});
    print("CATEGORY_FLUTTER_SERVICE: Deleting category $categoryId at $url");

    try {
      final response = await http.delete(url).timeout(const Duration(seconds: 10));
      print("CATEGORY_FLUTTER_SERVICE: Delete response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          print("CATEGORY_FLUTTER_SERVICE: Category $categoryId deleted successfully.");
          return;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to delete category: Unexpected API response.');
        }
      } else {
         final errorData = jsonDecode(response.body);
        print("CATEGORY_FLUTTER_SERVICE: Error deleting - ${response.statusCode}: ${response.body}");
        throw Exception('Failed to delete category: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e, s) {
      print("CATEGORY_FLUTTER_SERVICE: Exception during deleteCategory: $e\n$s");
      if (e is http.ClientException || e is TimeoutException) {
        throw Exception('Network error. Is API server running?');
      }
      rethrow;
    }
  }
}