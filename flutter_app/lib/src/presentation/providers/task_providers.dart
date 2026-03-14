// File: lib/src/presentation/providers/task_providers.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'auth_providers.dart';
import '../../core/network/api_constants.dart';

class TaskModel {
  final String id;
  final String description;
  final bool isCompleted;

  TaskModel({
    required this.id,
    required this.description,
    this.isCompleted = false,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}

class TasksNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final Ref _ref;
  String get _baseUrl => ApiConstants.baseUrl;

  TasksNotifier(this._ref) : super(const AsyncLoading()) {
    fetchTasks();
  }

  String? get _userId => _ref.read(userIdProvider);

  Future<void> fetchTasks() async {
    if (_userId == null) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    try {
      final url = Uri.parse('$_baseUrl/api/tasks?userId=$_userId');
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> taskList = data['tasks'] ?? [];
        state = AsyncData(taskList.map((t) => TaskModel.fromMap(t)).toList());
      } else {
        throw Exception('Görevler yüklenemedi: ${response.statusCode}');
      }
    } on SocketException {
      state = AsyncError(
          Exception('İnternet bağlantısı yok.'), StackTrace.current);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> completeTask(String taskId) async {
    final url =
        Uri.parse('$_baseUrl/api/tasks/$taskId/complete');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': _userId}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      await fetchTasks();
    } else {
      throw Exception('Görev tamamlanamadı: ${response.statusCode}');
    }
  }

  Future<void> addTask(String description) async {
    final url = Uri.parse('$_baseUrl/api/tasks');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': _userId, 'description': description}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 201) {
      await fetchTasks();
    } else {
      throw Exception('Görev eklenemedi: ${response.statusCode}');
    }
  }
}

final activeTasksProvider = StateNotifierProvider.autoDispose<TasksNotifier,
    AsyncValue<List<TaskModel>>>((ref) {
  return TasksNotifier(ref);
});
