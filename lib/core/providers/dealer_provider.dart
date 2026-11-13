import 'package:crm/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const kDealerStatuses = <String>['Active', 'Inactive', 'Suspended'];

class Dealer {
  final int id;
  final String name;
  final String company;
  final String email;
  final String phone;
  final String city;
  final String state;
  final String address;
  final String gstNumber;
  final String dealerCode;
  final String status;
  final double creditLimit;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Dealer({
    required this.id,
    required this.name,
    this.company = '',
    this.email = '',
    this.phone = '',
    this.city = '',
    this.state = '',
    this.address = '',
    this.gstNumber = '',
    this.dealerCode = '',
    this.status = 'Active',
    this.creditLimit = 0.0,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  factory Dealer.fromJson(Map<String, dynamic> json) => Dealer(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        company: json['company'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        address: json['address'] ?? '',
        gstNumber: json['gst_number'] ?? '',
        dealerCode: json['dealer_code'] ?? '',
        status: json['status'] ?? 'Active',
        creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
        notes: json['notes'] ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'company': company,
        'email': email,
        'phone': phone,
        'city': city,
        'state': state,
        'address': address,
        'gst_number': gstNumber,
        'dealer_code': dealerCode,
        'status': status,
        'credit_limit': creditLimit,
        'notes': notes,
      };
}

class DealerProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<Dealer> _dealers = [];
  bool _isLoading = false;
  String? _error;

  static final List<Dealer> _demoDealers = [
    Dealer(
      id: 1,
      name: 'Apex Industrial Supplies',
      company: 'Apex Corp',
      email: 'contact@apexind.com',
      phone: '+91 98765 43210',
      city: 'Mumbai',
      state: 'Maharashtra',
      dealerCode: 'DLR-1001',
      status: 'Active',
      creditLimit: 500000.0,
    ),
    Dealer(
      id: 2,
      name: 'Zenith Packagings',
      company: 'Zenith Ltd',
      email: 'info@zenithpack.com',
      phone: '+91 98123 45678',
      city: 'Delhi',
      state: 'Delhi',
      dealerCode: 'DLR-1002',
      status: 'Active',
      creditLimit: 750000.0,
    ),
    Dealer(
      id: 3,
      name: 'Metro Trading Co',
      company: 'Metro Group',
      email: 'sales@metrotrade.com',
      phone: '+91 99887 76655',
      city: 'Bengaluru',
      state: 'Karnataka',
      dealerCode: 'DLR-1003',
      status: 'Inactive',
      creditLimit: 250000.0,
    ),
  ];

  List<Dealer> get dealers => _dealers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDealers({String? search, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final qp = <String, dynamic>{
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.isNotEmpty && status != 'All')
          'status': status,
      };
      final res = await _api.dio.get('/api/dealers',
          queryParameters: qp.isEmpty ? null : qp);
      if (res.data is List) {
        _dealers = (res.data as List)
            .map((e) => Dealer.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _dealers = List.from(_demoDealers);
      }
    } catch (e) {
      if (e is DioException) {
        _error = e.response?.data?['error'] ?? 'Failed to load dealers';
      } else {
        _error = 'Failed to load dealers';
      }
      if (_dealers.isEmpty) {
        _dealers = List.from(_demoDealers);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDealer(Map<String, dynamic> data) async {
    try {
      await _api.dio.post('/api/dealers', data: data);
      await fetchDealers();
      return true;
    } catch (_) {
      final newId = (_dealers.map((d) => d.id).fold(0, (a, b) => a > b ? a : b)) + 1;
      _dealers.insert(0, Dealer.fromJson({'id': newId, ...data}));
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateDealer(int id, Map<String, dynamic> data) async {
    try {
      await _api.dio.put('/api/dealers/$id', data: data);
    } catch (_) {}
    final idx = _dealers.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      final existing = _dealers[idx].toJson();
      existing.addAll(data);
      _dealers[idx] = Dealer.fromJson({'id': id, ...existing});
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteDealer(int id) async {
    try {
      await _api.dio.delete('/api/dealers/$id');
    } catch (_) {}
    _dealers.removeWhere((d) => d.id == id);
    notifyListeners();
    return true;
  }
}
