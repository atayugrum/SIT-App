// File: flutter_app/lib/src/data/services/category_flutter_service.dart
import 'dart:convert';
import '../../core/network/api_constants.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/user_category_model.dart';
import '../../presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryFlutterService {
  final Ref _ref;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 1, errorMethodCount: 5));

  CategoryFlutterService(this._ref);

  String? get _userId => _ref.read(currentUserProvider)?.uid;

  Future<UserCategoryModel> createCategory(UserCategoryModel category) async {
    if (_userId == null) {
      _logger.w("User not logged in. Cannot create category.");
      throw Exception("User not logged in. Cannot create category.");
    }

    final Map<String, dynamic> categoryDataForApi = category.toMapForApi()..['userId'] = _userId;
    final url = Uri.parse('${ApiConstants.baseUrl}/api/categories');
    _logger.i("Creating category at $url");
    _logger.d("Category data for API: ${jsonEncode(categoryDataForApi)}");

    try {
      final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(categoryDataForApi),
          ).timeout(const Duration(seconds: 60));

      _logger.d("Create category response status: ${response.statusCode}");

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('category')) {
          _logger.i("Custom category created successfully.");
          return UserCategoryModel.fromMap(responseData['category'] as Map<String, dynamic>);
        } else {
          _logger.e("API success but response format is invalid.", error: response.body);
          throw Exception(responseData['error'] ?? 'Failed to create category: Unexpected API response format.');
        }
      } else {
        Map<String, dynamic> errorData = {};
        try { errorData = jsonDecode(response.body); } catch (_) { errorData = {"error": response.body}; }
        _logger.e("Error creating category - ${response.statusCode}", error: response.body);
        throw Exception('Failed to create category: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } on SocketException catch (e, s) {
      _logger.e("Network error during createCategory", error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e("Timeout during createCategory", error: e, stackTrace: s);
      throw Exception('Network error: Request timed out.');
    } catch (e, s) {
      _logger.e("Generic exception during createCategory", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<UserCategoryModel>> listCategories({String? categoryType}) async {
    if (_userId == null) {
      _logger.w("User not logged in. Cannot list categories.");
      return [];
    }

    final Map<String, String> queryParams = {'userId': _userId!};
    if (categoryType != null) {
      queryParams['type'] = categoryType;
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/api/categories').replace(queryParameters: queryParams);
    _logger.i("Listing categories from $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 60));
      _logger.d("List categories response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('categories')) {
          final List<dynamic> categoriesData = responseData['categories'];
          final categories = categoriesData.map((data) => UserCategoryModel.fromMap(data as Map<String, dynamic>)).toList();
          _logger.i("Fetched ${categories.length} custom categories.");
          return categories;
        } else {
          _logger.e("API success but response format is invalid.", error: response.body);
          throw Exception(responseData['error'] ?? 'Failed to list categories: Unexpected API response format.');
        }
      } else {
        Map<String, dynamic> errorData = {};
        try { errorData = jsonDecode(response.body); } catch (_) { errorData = {"error": response.body}; }
        _logger.e("Error listing categories - ${response.statusCode}", error: response.body);
        throw Exception('Failed to list categories: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } on SocketException catch (e, s) {
      _logger.e("Network error during listCategories", error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e("Timeout during listCategories", error: e, stackTrace: s);
      throw Exception('Network error: Request timed out.');
    } catch (e, s) {
      _logger.e("Generic exception during listCategories", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<UserCategoryModel> updateCategory(String categoryId, UserCategoryModel category) async {
    if (_userId == null) {
      _logger.w("User not logged in. Cannot update category.");
      throw Exception("User not logged in. Cannot update category.");
    }
    
    final Map<String, dynamic> categoryUpdateData = category.toMapForApi()..['userId'] = _userId;

    final url = Uri.parse('${ApiConstants.baseUrl}/api/categories/$categoryId');
    _logger.i("Updating category $categoryId at $url");
    _logger.d("Update data: ${jsonEncode(categoryUpdateData)}");

    try {
      final response = await http.put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(categoryUpdateData),
          ).timeout(const Duration(seconds: 60));

      _logger.d("Update category response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData.containsKey('category')) {
          _logger.i("Category $categoryId updated successfully.");
          return UserCategoryModel.fromMap(responseData['category'] as Map<String, dynamic>);
        } else {
          _logger.e("API success but response format is invalid.", error: response.body);
          throw Exception(responseData['error'] ?? 'Failed to update category: Unexpected API response.');
        }
      } else {
        Map<String, dynamic> errorData = {};
        try { errorData = jsonDecode(response.body); } catch (_) { errorData = {"error": response.body}; }
        _logger.e("Error updating category - ${response.statusCode}", error: response.body);
        throw Exception('Failed to update category: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } on SocketException catch (e, s) {
      _logger.e("Network error during updateCategory", error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e("Timeout during updateCategory", error: e, stackTrace: s);
      throw Exception('Network error: Request timed out.');
    } catch (e, s) {
      _logger.e("Generic exception during updateCategory", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    if (_userId == null) {
      _logger.w("User not logged in. Cannot delete category.");
      throw Exception("User not logged in. Cannot delete category.");
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/api/categories/$categoryId').replace(queryParameters: {'userId': _userId});
    _logger.i("Deleting category $categoryId at $url");

    try {
      final response = await http.delete(url).timeout(const Duration(seconds: 60));
      _logger.d("Delete category response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          _logger.i("Category $categoryId deleted successfully.");
          return;
        } else {
          _logger.e("API success but response format is invalid.", error: response.body);
          throw Exception(responseData['error'] ?? 'Failed to delete category: Unexpected API response.');
        }
      } else {
        Map<String, dynamic> errorData = {};
        try { errorData = jsonDecode(response.body); } catch (_) { errorData = {"error": response.body}; }
        _logger.e("Error deleting category - ${response.statusCode}", error: response.body);
        throw Exception('Failed to delete category: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } on SocketException catch (e, s) {
      _logger.e("Network error during deleteCategory", error: e, stackTrace: s);
      throw Exception('Lütfen internet bağlantınızı kontrol edin.');
    } on TimeoutException catch (e, s) {
      _logger.e("Timeout during deleteCategory", error: e, stackTrace: s);
      throw Exception('Network error: Request timed out.');
    } catch (e, s) {
      _logger.e("Generic exception during deleteCategory", error: e, stackTrace: s);
      rethrow;
    }
  }
}