import 'package:crm/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const kQuotationStatuses = <String>[
  'Draft',
  'Pending Approval',
  'Accepted',
  'Sent',
];

class QuoteCustomer {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String address;

  const QuoteCustomer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.address,
  });

  factory QuoteCustomer.fromJson(Map<String, dynamic> json) => QuoteCustomer(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    company: json['company'] ?? '',
    address: json['address'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id > 0 ? id : null,
    'name': name.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    'company': company.trim(),
    'address': address.trim(),
  };
}

class QuoteLead {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String company;

  const QuoteLead({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
  });

  factory QuoteLead.fromJson(Map<String, dynamic> json) => QuoteLead(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    company: json['company'] ?? '',
  );
}

class QuoteItem {
  final int id;
  final int quotationId;
  final String product;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double gst;
  final double lineTotal;

  const QuoteItem({
    required this.id,
    required this.quotationId,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.gst,
    required this.lineTotal,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) => QuoteItem(
    id: json['id'] ?? 0,
    quotationId: json['quotation_id'] ?? 0,
    product: json['product'] ?? '',
    quantity: json['quantity'] ?? 0,
    unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
    discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    gst: (json['gst'] as num?)?.toDouble() ?? 0.0,
    lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0.0,
  );
}

class QuoteSaveItem {
  final String product;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double gst;

  const QuoteSaveItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.gst,
  });

  Map<String, dynamic> toJson() => {
    'product': product.trim(),
    'quantity': quantity,
    'unit_price': unitPrice,
    'discount': discount,
    'gst': gst,
  };
}

class QuoteSaveRequest {
  final String? quoteNumber;
  final int? customerId;
  final int? leadId;
  final String status;
  final DateTime validUntil;
  final String notes;
  final QuoteCustomer customer;
  final List<QuoteSaveItem> items;

  const QuoteSaveRequest({
    this.quoteNumber,
    this.customerId,
    this.leadId,
    required this.status,
    required this.validUntil,
    required this.notes,
    required this.customer,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    if (quoteNumber != null && quoteNumber!.trim().isNotEmpty)
      'quote_number': quoteNumber!.trim(),
    if (customerId != null) 'customer_id': customerId,
    if (leadId != null) 'lead_id': leadId,
    'status': status,
    'valid_until': validUntil.toIso8601String(),
    'notes': notes.trim(),
    'customer': customer.toJson(),
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class Quote {
  final int id;
  final String quoteNumber;
  final int customerId;
  final int? leadId;
  final String status;
  final DateTime? validUntil;
  final String notes;
  final double subtotal;
  final double taxTotal;
  final double totalAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final QuoteCustomer? customer;
  final QuoteLead? lead;
  final List<QuoteItem> items;

  const Quote({
    required this.id,
    required this.quoteNumber,
    required this.customerId,
    this.leadId,
    required this.status,
    this.validUntil,
    required this.notes,
    required this.subtotal,
    required this.taxTotal,
    required this.totalAmount,
    this.createdAt,
    this.updatedAt,
    this.customer,
    this.lead,
    this.items = const [],
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'];
    final leadJson = json['lead'];
    final itemsJson = json['items'] as List?;

    return Quote(
      id: json['id'] ?? 0,
      quoteNumber: json['quote_number'] ?? '',
      customerId: json['customer_id'] ?? 0,
      leadId: json['lead_id'],
      status: json['status'] ?? 'Draft',
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'])
          : null,
      notes: json['notes'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxTotal: (json['tax_total'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      customer: customerJson is Map<String, dynamic>
          ? QuoteCustomer.fromJson(customerJson)
          : null,
      lead: leadJson is Map<String, dynamic>
          ? QuoteLead.fromJson(leadJson)
          : null,
      items: itemsJson
              ?.map((item) => QuoteItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  String get customerName {
    final value = customer?.name.trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
    return 'Customer #$customerId';
  }

  String get customerCompany => customer?.company.trim() ?? '';

  String get leadReference {
    if (leadId == null || leadId == 0) {
      return '-';
    }
    return 'Lead #$leadId';
  }

  bool matchesSearch(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final searchTokens = <String>[
      id.toString(),
      quoteNumber.toLowerCase(),
      customerName.toLowerCase(),
      customerCompany.toLowerCase(),
      leadReference.toLowerCase(),
      notes.toLowerCase(),
      if (lead != null) ...[
        lead!.name.toLowerCase(),
        lead!.company.toLowerCase(),
        lead!.email.toLowerCase(),
        lead!.phone.toLowerCase(),
      ],
      ...items.map((item) => item.product.toLowerCase()),
    ];

    return searchTokens.any((token) => token.contains(query));
  }

  QuoteSaveRequest toSaveRequest() {
    return QuoteSaveRequest(
      quoteNumber: quoteNumber,
      customerId: (customer?.id ?? 0) > 0 ? customer!.id : customerId,
      leadId: leadId,
      status: status,
      validUntil: validUntil ?? DateTime.now(),
      notes: notes,
      customer: customer ??
          QuoteCustomer(
            id: customerId,
            name: '',
            email: '',
            phone: '',
            company: '',
            address: '',
          ),
      items: items
          .map(
            (item) => QuoteSaveItem(
              product: item.product,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              discount: item.discount,
              gst: item.gst,
            ),
          )
          .toList(),
    );
  }
}

class QuoteProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<Quote> _quotes = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  static final List<Quote> _demoQuotes = [
    Quote(
      id: 1,
      quoteNumber: 'QT-2026-001',
      customerId: 101,
      status: 'Accepted',
      notes: 'Standard bulk supply quote',
      subtotal: 50000.0,
      taxTotal: 9000.0,
      totalAmount: 59000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      customer: const QuoteCustomer(
        id: 101,
        name: 'Alice Smith',
        email: 'alice@techcorp.com',
        phone: '+1 555-0100',
        company: 'Tech Corp',
        address: '123 Main St, San Francisco',
      ),
      items: const [
        QuoteItem(
          id: 1,
          quotationId: 1,
          product: 'Corrugated Box 3-Ply',
          quantity: 1000,
          unitPrice: 50.0,
          discount: 0.0,
          gst: 18.0,
          lineTotal: 59000.0,
        ),
      ],
    ),
    Quote(
      id: 2,
      quoteNumber: 'QT-2026-002',
      customerId: 102,
      status: 'Pending Approval',
      notes: 'Custom printed packaging inquiry',
      subtotal: 120000.0,
      taxTotal: 21600.0,
      totalAmount: 141600.0,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      customer: const QuoteCustomer(
        id: 102,
        name: 'Bob Johnson',
        email: 'bob@acme.com',
        phone: '+1 555-0200',
        company: 'Acme Inc',
        address: '456 Oak Ave, New York',
      ),
      items: const [
        QuoteItem(
          id: 2,
          quotationId: 2,
          product: 'Heavy Duty Packaging Tape',
          quantity: 500,
          unitPrice: 240.0,
          discount: 0.0,
          gst: 18.0,
          lineTotal: 141600.0,
        ),
      ],
    ),
  ];

  List<Quote> get quotes => _quotes;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchQuotes({String? search, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final queryParameters = <String, dynamic>{
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.trim().isNotEmpty && status != 'All Status')
          'status': status,
      };
      final res = await _api.dio.get(
        '/api/quotes',
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
      _quotes = _parseQuotes(res.data);
      if (_quotes.isEmpty) {
        _quotes = List.from(_demoQuotes);
      }
    } catch (e) {
      if (e is DioException) {
        _error = _extractError(e, fallback: 'Failed to load quotations');
      } else {
        _error = 'Failed to load quotations';
      }
      if (_quotes.isEmpty) {
        _quotes = List.from(_demoQuotes);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Quote?> createQuote(QuoteSaveRequest request) async {
    return _saveQuote(() => _api.dio.post('/api/quotes', data: request.toJson()));
  }

  Future<Quote?> updateQuote(int id, QuoteSaveRequest request) async {
    return _saveQuote(
      () => _api.dio.put('/api/quotes/$id', data: request.toJson()),
    );
  }

  Future<bool> deleteQuote(int id) async {
    _error = null;
    notifyListeners();
    try {
      await _api.dio.delete('/api/quotes/$id');
    } catch (_) {}
    _quotes.removeWhere((quote) => quote.id == id);
    notifyListeners();
    return true;
  }

  Future<Quote?> _saveQuote(Future<Response<dynamic>> Function() request) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final response = await request();
      final quote = Quote.fromJson(response.data as Map<String, dynamic>);
      _upsertQuote(quote);
      return quote;
    } catch (e) {
      if (e is DioException) {
        _error = _extractError(e, fallback: 'Failed to save quotation');
      } else {
        _error = 'Failed to save quotation';
      }
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  List<Quote> _parseQuotes(dynamic data) {
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(Quote.fromJson)
        .toList();
  }

  void _upsertQuote(Quote quote) {
    final index = _quotes.indexWhere((existing) => existing.id == quote.id);
    if (index >= 0) {
      _quotes[index] = quote;
    } else {
      _quotes = [quote, ..._quotes];
    }
    _quotes.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }

  String _extractError(DioException error, {required String fallback}) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }
}
