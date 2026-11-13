import 'package:crm/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class DashboardSummary {
  final int totalCustomers;
  final int totalTasks;
  final int pendingTasks;
  final double totalRevenue;

  DashboardSummary({
    required this.totalCustomers,
    required this.totalTasks,
    required this.pendingTasks,
    required this.totalRevenue,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        totalCustomers: json['total_customers'] ?? 0,
        totalTasks: json['total_tasks'] ?? 0,
        pendingTasks: json['pending_tasks'] ?? 0,
        totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      );
}

class DashboardProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  DashboardSummary? _summary;
  bool _isLoading = false;

  DashboardSummary? get summary => _summary;
  bool get isLoading => _isLoading;

  // Demo values shown while offline
  DashboardSummary get displaySummary =>
      _summary ??
      DashboardSummary(
        totalCustomers: 53,
        totalTasks: 12,
        pendingTasks: 4,
        totalRevenue: 15890,
      );

  Future<void> fetchSummary() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/dashboard/summary');
      if (res.data is Map<String, dynamic>) {
        _summary = DashboardSummary.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Keep demo values on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
