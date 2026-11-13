import 'package:crm/core/providers/lead_provider.dart';
import 'package:crm/core/providers/quote_provider.dart';
import 'package:crm/core/responsive.dart';
import 'package:crm/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class NewQuoteScreen extends StatefulWidget {
  final Quote? editQuote;
  const NewQuoteScreen({super.key, this.editQuote});

  @override
  State<NewQuoteScreen> createState() => _NewQuoteScreenState();
}

class _NewQuoteScreenState extends State<NewQuoteScreen> {
  DateTime? _validUntil;
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _customerNameCtrl = TextEditingController();
  final TextEditingController _companyCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  int? _selectedLeadId;
  String _selectedStatus = 'Draft';
  final List<QuoteItemDraft> _lineItems = [];

  bool get _isEditing => widget.editQuote != null;

  @override
  void initState() {
    super.initState();
    final eq = widget.editQuote;
    if (eq != null) {
      _customerNameCtrl.text = eq.customerName;
      _companyCtrl.text = eq.customerCompany;
      _emailCtrl.text = eq.customer?.email ?? '';
      _phoneCtrl.text = eq.customer?.phone ?? '';
      _notesCtrl.text = eq.notes;
      _validUntil =
          eq.validUntil ?? DateTime.now().add(const Duration(days: 30));
      _selectedLeadId = eq.leadId;
      _selectedStatus = eq.status;
      for (final item in eq.items) {
        _lineItems.add(
          QuoteItemDraft()
            ..productCtrl.text = item.product
            ..qtyCtrl.text = item.quantity.toString()
            ..priceCtrl.text = item.unitPrice.toString()
            ..discountCtrl.text = item.discount.toString()
            ..gstCtrl.text = item.gst.toString(),
        );
      }
      if (_lineItems.isEmpty) _lineItems.add(QuoteItemDraft());
    } else {
      _validUntil = DateTime.now().add(const Duration(days: 30));
      _lineItems.add(QuoteItemDraft());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leadProvider = context.read<LeadProvider>();
      if (leadProvider.leads.isEmpty) {
        leadProvider.fetchLeads();
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _customerNameCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    for (final item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _recalculate() {
    setState(
      () {},
    ); // Trigger rebuild to update totals based on line item getters
  }

  double get _subtotal =>
      _lineItems.fold(0, (sum, item) => sum + item.lineTotalBase);
  double get _gstTotal =>
      _lineItems.fold(0, (sum, item) => sum + item.lineGstBase);
  double get _grandTotal => _subtotal + _gstTotal;

  Future<void> _saveQuote() async {
    if (_customerNameCtrl.text.isEmpty || _lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    final data = QuoteSaveRequest(
      customerId: _selectedLeadId ?? 1,
      leadId: _selectedLeadId,
      status: _selectedStatus,
      validUntil: _validUntil ?? DateTime.now(),
      notes: _notesCtrl.text,
      customer: QuoteCustomer(
        id: widget.editQuote?.customer?.id ?? 0,
        name: _customerNameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        company: _companyCtrl.text,
        address: '',
      ),
      items: _lineItems
          .map(
            (e) => QuoteSaveItem(
              product: e.productCtrl.text,
              quantity: int.tryParse(e.qtyCtrl.text) ?? 1,
              unitPrice: double.tryParse(e.priceCtrl.text) ?? 0,
              discount: double.tryParse(e.discountCtrl.text) ?? 0,
              gst: double.tryParse(e.gstCtrl.text) ?? 0,
            ),
          )
          .toList(),
    );

    final provider = context.read<QuoteProvider>();
    final Quote? result = _isEditing
        ? await provider.updateQuote(widget.editQuote!.id, data)
        : await provider.createQuote(data);
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context);
    } else {
      final error = provider.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to save quotation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Quotation' : 'New Quotation',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppColors.textMain,
              ),
            ),
            Text(
              _isEditing
                  ? 'Update your quotation'
                  : 'Build and save your quotation',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 1,
        actions: [
          if (!Responsive.isMobile(context))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 16),
              width: 250,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search leads...',
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: GoogleFonts.outfit(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!Responsive.isMobile(context))
            const Icon(
              Icons.notifications_none_outlined,
              color: AppColors.textSecondary,
            ),
          if (!Responsive.isMobile(context)) const SizedBox(width: 16),
          if (!Responsive.isMobile(context))
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                'RK',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          if (!Responsive.isMobile(context)) const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final bodyPadding = isMobile ? 16.0 : 32.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(bodyPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Quotations > Edit' : 'Quotations > New',
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                if (isMobile)
                  Column(
                    children: [
                      _buildCustomerDetailsPane(),
                      const SizedBox(height: 16),
                      _buildQuoteInfoPane(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: _buildCustomerDetailsPane()),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _buildQuoteInfoPane()),
                    ],
                  ),
                const SizedBox(height: 24),
                _buildLineItemsPane(),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _saveQuote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Update Quotation' : 'Save Quotation',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerDetailsPane() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Details',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          _inputLabel('Link to Lead (optional)'),
          Container(
            height: 44,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Consumer<LeadProvider>(
              builder: (ctx, leadsP, _) {
                return DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedLeadId,
                    hint: Text(
                      'Select a lead...',
                      style: GoogleFonts.outfit(color: AppColors.textSecondary),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...leadsP.leads.map(
                        (l) =>
                            DropdownMenuItem(value: l.id, child: Text(l.name)),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedLeadId = val;
                        if (val != null) {
                          final lead = leadsP.leads.firstWhere(
                            (e) => e.id == val,
                          );
                          _customerNameCtrl.text = lead.name;
                          _companyCtrl.text = lead.company;
                          _emailCtrl.text = lead.email;
                          _phoneCtrl.text = lead.phone;
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    _labeledField('Customer Name *', _customerNameCtrl),
                    const SizedBox(height: 16),
                    _labeledField('Company Name *', _companyCtrl),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _labeledField('Customer Name *', _customerNameCtrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _labeledField('Company Name *', _companyCtrl),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    _labeledField('Email', _emailCtrl),
                    const SizedBox(height: 16),
                    _labeledField('Phone', _phoneCtrl),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _labeledField('Email', _emailCtrl)),
                  const SizedBox(width: 16),
                  Expanded(child: _labeledField('Phone', _phoneCtrl)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteInfoPane() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quote Info',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          _inputLabel('Status'),
          Container(
            height: 44,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                isExpanded: true,
                items: kQuotationStatuses
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: GoogleFonts.outfit(fontSize: 14)),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedStatus = v ?? _selectedStatus),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _inputLabel('Valid Until'),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _validUntil ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (d != null) setState(() => _validUntil = d);
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd-MM-yyyy').format(_validUntil!),
                    style: GoogleFonts.outfit(fontSize: 14),
                  ),
                  const Icon(Icons.calendar_today_outlined, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _inputLabel('Notes / Terms'),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Add notes or terms...',
                hintStyle: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsPane() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Line Items (${_lineItems.length})',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _lineItems.add(QuoteItemDraft())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: MediaQuery.of(context).size.width < 600 ? 700 : null,
              constraints: MediaQuery.of(context).size.width >= 600
                  ? BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 100,
                    )
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: AppColors.background,
              child: Row(
                children: [
                  Expanded(flex: 4, child: _headerText('Product')),
                  Expanded(flex: 1, child: _headerText('Qty')),
                  Expanded(flex: 2, child: _headerText('Unit Price (₹)')),
                  Expanded(flex: 2, child: _headerText('Discount %')),
                  Expanded(flex: 1, child: _headerText('GST %')),
                  Expanded(
                    flex: 2,
                    child: _headerText('Line Total', alignRight: true),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),
          ..._lineItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: MediaQuery.of(context).size.width < 600 ? 700 : null,
                constraints: MediaQuery.of(context).size.width >= 600
                    ? BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width - 100,
                      )
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 4, child: _productDropdown(item)),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _numberInput(item.qtyCtrl, () => _recalculate()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _numberInput(item.priceCtrl, () => _recalculate()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _numberInput(
                        item.discountCtrl,
                        () => _recalculate(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          '18%',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ), // Hardcoded 18% in visual
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${(item.lineTotalBase / 1000).toStringAsFixed(1)}K',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '+₹${item.lineGstBase.toStringAsFixed(0)} GST',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.alert,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _lineItems.removeAt(idx)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'GST',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${(_subtotal / 1000).toStringAsFixed(1)}K',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${(_gstTotal / 1000).toStringAsFixed(1)}K',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '₹${(_grandTotal / 1000).toStringAsFixed(1)}K',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productDropdown(QuoteItemDraft item) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: item.productCtrl.text.isEmpty ? null : item.productCtrl.text,
          isExpanded: true,
          hint: Text(
            'Select Product',
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          items:
              [
                    'Insulation -pipe',
                    'Insulation Roll',
                    'Floor kavach',
                    'Tank kavach',
                  ]
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: GoogleFonts.outfit(fontSize: 13)),
                    ),
                  )
                  .toList(),
          onChanged: (v) {
            setState(() {
              item.productCtrl.text = v!;
              _recalculate();
            });
          },
        ),
      ),
    );
  }

  Widget _numberInput(TextEditingController ctrl, VoidCallback onChange) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        controller: ctrl,
        onChanged: (v) => onChange(),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(bottom: 10),
          isDense: true,
          hintStyle: GoogleFonts.outfit(fontSize: 13),
        ),
        style: GoogleFonts.outfit(fontSize: 14),
      ),
    );
  }

  Widget _labeledField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputLabel(label),
        Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              hintText: label.contains('*')
                  ? label.replaceAll('*', '').trim()
                  : label,
              hintStyle: GoogleFonts.outfit(
                color: AppColors.divider,
                fontSize: 14,
              ),
            ),
            style: GoogleFonts.outfit(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _inputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _headerText(String text, {bool alignRight = false}) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class QuoteItemDraft {
  final TextEditingController productCtrl = TextEditingController(
    text: 'Insulation -pipe',
  );
  final TextEditingController qtyCtrl = TextEditingController(text: '100');
  final TextEditingController priceCtrl = TextEditingController(text: '120');
  final TextEditingController discountCtrl = TextEditingController(text: '0');
  final TextEditingController gstCtrl = TextEditingController(text: '18');

  void dispose() {
    productCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
    discountCtrl.dispose();
    gstCtrl.dispose();
  }

  double get qty => double.tryParse(qtyCtrl.text) ?? 0;
  double get price => double.tryParse(priceCtrl.text) ?? 0;
  double get discount => double.tryParse(discountCtrl.text) ?? 0;
  double get gst => double.tryParse(gstCtrl.text) ?? 0;

  double get lineTotalBase => (qty * price) * (1 - (discount / 100));
  double get lineGstBase => lineTotalBase * (gst / 100);
  double get lineTotalComplete => lineTotalBase + lineGstBase;
}
