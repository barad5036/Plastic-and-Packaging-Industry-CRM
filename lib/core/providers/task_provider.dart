import 'package:crm/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class TaskModel {
  final int id;
  final String title;
  final String description;
  final String status;
  final String dueDate;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.dueDate,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        status: json['status'] ?? 'Pending',
        dueDate: json['due_date'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'status': status,
        'due_date': dueDate,
      };
}

class TaskProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;

  static final List<TaskModel> _demoTasks = [
    TaskModel(
      id: 1,
      title: 'Review Q3 Marketing Strategy',
      description: 'Analyze campaign performance and plan Q4',
      status: 'Pending',
      dueDate: '2026-03-15T00:00:00Z',
    ),
    TaskModel(
      id: 2,
      title: 'Update CRM Customer Data',
      description: 'Clean up duplicate entries and verify contacts',
      status: 'In Progress',
      dueDate: '2026-03-12T00:00:00Z',
    ),
    TaskModel(
      id: 3,
      title: 'Send Partnership Proposals',
      description: 'Draft and send proposals to 3 new partners',
      status: 'Completed',
      dueDate: '2026-03-10T00:00:00Z',
    ),
    TaskModel(
      id: 4,
      title: 'Prepare Sales Report',
      description: 'Generate monthly sales metrics report',
      status: 'Pending',
      dueDate: '2026-03-20T00:00:00Z',
    ),
    TaskModel(
      id: 5,
      title: 'Client Onboarding Call',
      description: 'Welcome call with DataFlow team',
      status: 'In Progress',
      dueDate: '2026-03-08T00:00:00Z',
    ),
    TaskModel(
      id: 6,
      title: 'Demo Preparation',
      description: 'Prepare product demo for AI Labs meeting',
      status: 'Pending',
      dueDate: '2026-03-18T00:00:00Z',
    ),
  ];

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingCount => _tasks.where((t) => t.status != 'Completed').length;

  Future<void> fetchTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/tasks');
      if (res.data is List) {
        _tasks = (res.data as List)
            .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _tasks = List.from(_demoTasks);
      }
    } catch (e) {
      if (e is DioException) {
        _error = e.response?.data?['error'] ?? 'Failed to load tasks';
      } else {
        _error = 'Failed to load tasks';
      }
      if (_tasks.isEmpty) {
        _tasks = List.from(_demoTasks);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTask(Map<String, dynamic> data) async {
    try {
      await _api.dio.post('/api/tasks', data: data);
      await fetchTasks();
      return true;
    } catch (_) {
      final newId = (_tasks.map((t) => t.id).fold(0, (a, b) => a > b ? a : b)) + 1;
      _tasks.insert(0, TaskModel.fromJson({'id': newId, ...data}));
      notifyListeners();
      return true;
    }
  }

  Future<bool> completeTask(int id) async {
    try {
      await _api.dio.put('/api/tasks/$id', data: {'status': 'Completed'});
    } catch (_) {}
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx >= 0) {
      _tasks[idx] = TaskModel(
        id: _tasks[idx].id,
        title: _tasks[idx].title,
        description: _tasks[idx].description,
        status: 'Completed',
        dueDate: _tasks[idx].dueDate,
      );
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteTask(int id) async {
    try {
      await _api.dio.delete('/api/tasks/$id');
    } catch (_) {}
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    return true;
  }
}
