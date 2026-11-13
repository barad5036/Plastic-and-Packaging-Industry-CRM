import 'package:crm/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Lead {
  final int id;
  final String name;
  final String company;
  final String email;
  final String phone;
  final String customerType;
  final DateTime? inquiryDate;
  final String city;
  final String state;
  final String followUp1;
  final String followUp2;
  final String followUp3;
  final String status;
  final double value;
  final DateTime? createdAt;

  Lead({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    this.customerType = '',
    this.inquiryDate,
    this.city = '',
    this.state = '',
    this.followUp1 = '',
    this.followUp2 = '',
    this.followUp3 = '',
    required this.status,
    required this.value,
    this.createdAt,
  });

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    company: json['company'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    customerType: json['customer_type'] ?? '',
    inquiryDate: json['inquiry_date'] != null
        ? DateTime.tryParse(json['inquiry_date'])
        : null,
    city: json['city'] ?? '',
    state: json['state'] ?? '',
    followUp1: json['follow_up_1'] ?? '',
    followUp2: json['follow_up_2'] ?? '',
    followUp3: json['follow_up_3'] ?? '',
    status: json['status'] ?? 'New',
    value: (json['value'] as num?)?.toDouble() ?? 0.0,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'company': company,
    'email': email,
    'phone': phone,
    'customer_type': customerType,
    if (inquiryDate != null) 'inquiry_date': inquiryDate!.toIso8601String(),
    'city': city,
    'state': state,
    'follow_up_1': followUp1,
    'follow_up_2': followUp2,
    'follow_up_3': followUp3,
    'status': status,
    'value': value,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}

const kLeadStatuses = [
  'New',
  'Contacted',
  'Quotation Sent',
  'Negotiation',
  'Order Confirmed',
  'Lost',
];

class LeadProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<Lead> _leads = [];
  bool _isLoading = false;
  String? _error;

  static final List<Lead> _demoLeads = [
    Lead(
      id: 1,
      name: 'James Brown',
      company: 'Prime Estate',
      email: 'james@prime.com',
      phone: '+1 555-1000',
      customerType: 'Enterprise',
      city: 'San Francisco',
      state: 'CA',
      status: 'Contacted',
      value: 20000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Lead(
      id: 2,
      name: 'Sarah Lee',
      company: 'CloudTech',
      email: 'sarah@cloudtech.com',
      phone: '+1 555-1100',
      customerType: 'Corporate',
      city: 'New York',
      state: 'NY',
      status: 'Contacted',
      value: 35000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Lead(
      id: 3,
      name: 'Mike Chen',
      company: 'DataSoft',
      email: 'mike@datasoft.com',
      phone: '+1 555-1200',
      customerType: 'Enterprise',
      city: 'Austin',
      state: 'TX',
      status: 'Negotiation',
      value: 80000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Lead(
      id: 4,
      name: 'Anna Park',
      company: 'WebApps',
      email: 'anna@webapps.com',
      phone: '+1 555-1300',
      customerType: 'SMB',
      city: 'Seattle',
      state: 'WA',
      status: 'Negotiation',
      value: 55000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Lead(
      id: 5,
      name: 'Tom Wright',
      company: 'AI Labs',
      email: 'tom@ailabs.com',
      phone: '+1 555-1400',
      customerType: 'Enterprise',
      city: 'Denver',
      state: 'CO',
      status: 'Quotation Sent',
      value: 120000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Lead(
      id: 6,
      name: 'Laura Gold',
      company: 'FinServe',
      email: 'laura@finserve.com',
      phone: '+1 555-1500',
      customerType: 'Corporate',
      city: 'Chicago',
      state: 'IL',
      status: 'Order Confirmed',
      value: 150000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    Lead(
      id: 7,
      name: 'Chris Young',
      company: 'MediaPro',
      email: 'chris@mediapro.com',
      phone: '+1 555-1600',
      customerType: 'SMB',
      city: 'Boston',
      state: 'MA',
      status: 'Order Confirmed',
      value: 95000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    Lead(
      id: 8,
      name: 'Rachel Adams',
      company: 'Nexus Group',
      email: 'rachel@nexus.com',
      phone: '+1 555-1700',
      customerType: 'Enterprise',
      city: 'Miami',
      state: 'FL',
      status: 'New',
      value: 45000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  List<Lead> get leads => _leads;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Lead> byStatus(String status) =>
      _leads.where((l) => l.status == status).toList();

  Future<void> fetchLeads() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final isDemo = prefs.getString('token') == 'demo-token';

    if (!isDemo) {
      try {
        final res = await _api.dio.get('/api/leads');
        final responseData = res.data;
        if (responseData is List) {
          _leads = responseData
              .map((e) => Lead.fromJson(e as Map<String, dynamic>))
              .toList();
          _error = null;
          _isLoading = false;
          notifyListeners();
          return;
        }
      } catch (e) {
        // Fallback to demo leads on network/auth failure
      }
    }

    if (_leads.isEmpty) {
      _leads = List.from(_demoLeads);
    }
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createLead(Map<String, dynamic> data) async {
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    final isDemo = prefs.getString('token') == 'demo-token';

    if (!isDemo) {
      try {
        final res = await _api.dio.post('/api/leads', data: data);
        if (res.data is Map<String, dynamic> && res.data['id'] != null) {
          final newLead = Lead.fromJson(res.data as Map<String, dynamic>);
          _leads.insert(0, newLead);
          notifyListeners();
          return true;
        }
      } catch (_) {}
    }

    final newId = (_leads.map((l) => l.id).fold(0, (a, b) => a > b ? a : b)) + 1;
    final newLead = Lead.fromJson({
      'id': newId,
      ...data,
      'created_at': DateTime.now().toIso8601String(),
    });
    _leads.insert(0, newLead);
    _error = null;
    notifyListeners();
    return true;
  }

  /// Bulk import: sends ALL leads in a single API call
  Future<Map<String, dynamic>> importLeads(
    List<Map<String, dynamic>> leads,
  ) async {
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    final isDemo = prefs.getString('token') == 'demo-token';

    if (!isDemo) {
      try {
        final res = await _api.dio.post('/api/leads/import', data: leads);
        if (res.data is Map<String, dynamic>) {
          await fetchLeads();
          return res.data as Map<String, dynamic>;
        }
      } catch (_) {}
    }

    final importedLeads = leads.map((data) {
      final newId = (_leads.map((l) => l.id).fold(0, (a, b) => a > b ? a : b)) + 1;
      return Lead.fromJson({
        'id': newId,
        ...data,
        'created_at': DateTime.now().toIso8601String(),
      });
    }).toList();
    _leads.insertAll(0, importedLeads);
    _error = null;
    notifyListeners();
    return {
      'imported': leads.length,
      'message': 'Leads imported successfully',
    };
  }

  /// General update — sends any field map to the backend
  Future<bool> updateLead(int id, Map<String, dynamic> data) async {
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    final isDemo = prefs.getString('token') == 'demo-token';

    if (!isDemo) {
      try {
        await _api.dio.put('/api/leads/$id', data: data);
      } catch (_) {}
    }

    final idx = _leads.indexWhere((l) => l.id == id);
    if (idx >= 0) {
      final existing = _leads[idx].toJson();
      existing.addAll(data);
      _leads[idx] = Lead.fromJson({'id': id, ...existing});
      notifyListeners();
    }
    return true;
  }

  Future<bool> updateStatus(int id, String newStatus) async {
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    final isDemo = prefs.getString('token') == 'demo-token';

    if (!isDemo) {
      try {
        await _api.dio.put('/api/leads/$id', data: {'status': newStatus});
      } catch (_) {}
    }

    final idx = _leads.indexWhere((l) => l.id == id);
    if (idx >= 0) {
      final l = _leads[idx];
      _leads[idx] = Lead(
        id: l.id,
        name: l.name,
        company: l.company,
        email: l.email,
        phone: l.phone,
        value: l.value,
        customerType: l.customerType,
        inquiryDate: l.inquiryDate,
        city: l.city,
        state: l.state,
        followUp1: l.followUp1,
        followUp2: l.followUp2,
        followUp3: l.followUp3,
        status: newStatus,
        createdAt: l.createdAt,
      );
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteLead(int id) async {
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    final isDemo = prefs.getString('token') == 'demo-token';

    if (!isDemo) {
      try {
        await _api.dio.delete('/api/leads/$id');
      } catch (_) {}
    }

    _leads.removeWhere((l) => l.id == id);
    notifyListeners();
    return true;
  }

  Future<bool> clearAllLeads() async {
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    final isDemo = prefs.getString('token') == 'demo-token';

    if (!isDemo) {
      try {
        await _api.dio.delete('/api/leads');
      } catch (_) {}
    }

    _leads.clear();
    notifyListeners();
    return true;
  }
}
