import 'package:crm/core/providers/quote_provider.dart';
import 'package:crm/core/responsive.dart';
import 'package:crm/core/theme/app_theme.dart';
import 'package:crm/screens/quotes/new_quote_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All Status';
  static final DateFormat _tableDateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteProvider>().fetchQuotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          if (!isMobile) _buildHeader(),
          if (!isMobile) const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionBar(context),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildKPICards(),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildDataTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quotations',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Consumer<QuoteProvider>(
                builder: (context, provider, _) {
                  final total = provider.quotes.length;
                  final drafts = provider.quotes
                      .where((q) => q.status == 'Draft')
                      .length;
                  return Text(
                    '${total} quotations · ${drafts} drafts',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 300,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          hintText: 'Search leads, quotes, dealers...',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: GoogleFonts.outfit(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              const Icon(
                Icons.notifications_none_outlined,
                size: 24,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  'RK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              width: 250,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  hintText: 'Search quotes...',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
                style: GoogleFonts.outfit(fontSize: 14),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _statusFilter,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textMain,
                  ),
                  items:
                      [
                            'All Status',
                            'Draft',
                            'Pending Approval',
                            'Accepted',
                            'Sent',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _statusFilter = val!),
                ),
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewQuoteScreen()),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Quotation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            textStyle: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKPICards() {
    return Consumer<QuoteProvider>(
      builder: (context, provider, _) {
        final isMobile = Responsive.isMobile(context);
        final quotes = provider.quotes;
        final totalValue = quotes.fold<double>(
          0,
          (sum, q) => sum + q.totalAmount,
        );
        final accepted = quotes.where((q) => q.status == 'Accepted').length;
        final pending = quotes
            .where((q) => q.status == 'Pending Approval')
            .length;
        final drafts = quotes.where((q) => q.status == 'Draft').length;

        String formattedValue = '₹${(totalValue / 100000).toStringAsFixed(1)}L';
        if (totalValue < 100000) {
          formattedValue = '₹${totalValue.toStringAsFixed(0)}';
        }

        if (isMobile) {
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            children: [
              _kpiCard('Total Value', formattedValue, AppColors.primary),
              _kpiCard('Accepted', '$accepted', AppColors.success),
              _kpiCard('Pending', '$pending', AppColors.warning),
              _kpiCard('Drafts', '$drafts', AppColors.textMain),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _kpiCard('Total Value', formattedValue, AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _kpiCard('Accepted', '$accepted', AppColors.success),
            ),
            const SizedBox(width: 16),
            Expanded(child: _kpiCard('Pending', '$pending', AppColors.warning)),
            const SizedBox(width: 16),
            Expanded(child: _kpiCard('Drafts', '$drafts', AppColors.textMain)),
          ],
        );
      },
    );
  }

  Widget _kpiCard(String title, String value, Color valueColor) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 11 : 13,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 4 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 18 : 24,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final isMobile = Responsive.isMobile(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Consumer<QuoteProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          var filtered = provider.quotes;
          if (_statusFilter != 'All Status') {
            filtered = filtered
                .where((q) => q.status == _statusFilter)
                .toList();
          }
          if (_searchQuery.isNotEmpty) {
            filtered = filtered
                .where((q) => q.matchesSearch(_searchQuery))
                .toList();
          }

          if (filtered.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: Text('No quotations found.')),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: GoogleFonts.outfit(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              dataTextStyle: GoogleFonts.outfit(
                fontSize: isMobile ? 12 : 14,
                color: AppColors.textMain,
              ),
              horizontalMargin: isMobile ? 12 : 24,
              columnSpacing: isMobile ? 16 : 24,
              columns: const [
                DataColumn(label: Text('Quote #')),
                DataColumn(label: Text('Customer \u2191\u2193')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Amount \u2191\u2193')),
                DataColumn(label: Text('Ver')),
                DataColumn(label: Text('Valid Until')),
                DataColumn(label: Text('Created \u2191\u2193')),
                DataColumn(label: Text('Actions')),
              ],
              rows: filtered.map((quote) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        quote.quoteNumber,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            quote.customerName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (quote.customerCompany.isNotEmpty)
                            Text(
                              quote.customerCompany,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(_statusPill(quote.status)),
                    DataCell(
                      Text(
                        '₹${(quote.totalAmount / 100000).toStringAsFixed(1)}L',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(
                      const Text(
                        '-',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    DataCell(
                      Text(
                        quote.validUntil != null
                            ? _tableDateFormat.format(quote.validUntil!)
                            : '-',
                      ),
                    ),
                    DataCell(
                      Text(
                        quote.createdAt != null
                            ? _tableDateFormat.format(quote.createdAt!)
                            : '-',
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_red_eye_outlined,
                              size: 18,
                            ),
                            onPressed: () => _showQuoteDetails(context, quote),
                            color: AppColors.textSecondary,
                            splashRadius: 20,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      NewQuoteScreen(editQuote: quote),
                                ),
                              ).then(
                                (_) =>
                                    context.read<QuoteProvider>().fetchQuotes(),
                              );
                            },
                            color: AppColors.textSecondary,
                            splashRadius: 20,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => _confirmDelete(context, quote),
                            color: AppColors.alert,
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _statusPill(String status) {
    Color bg;
    Color text;
    switch (status) {
      case 'Accepted':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        break;
      case 'Pending Approval':
        bg = const Color(0xFFFFF8E1);
        text = const Color(0xFFF57F17);
        break;
      case 'Sent':
        bg = const Color(0xFFE3F2FD);
        text = const Color(0xFF1565C0);
        break;
      default: // Draft
        bg = const Color(0xFFF5F5F5);
        text = const Color(0xFF616161);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  void _showQuoteDetails(BuildContext context, Quote quote) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          quote.quoteNumber,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Customer', quote.customerName),
                if (quote.customerCompany.isNotEmpty)
                  _detailRow('Company', quote.customerCompany),
                _detailRow('Status', quote.status),
                _detailRow('Lead', quote.leadReference),
                _detailRow(
                  'Valid Until',
                  quote.validUntil != null
                      ? _tableDateFormat.format(quote.validUntil!)
                      : '-',
                ),
                _detailRow('Subtotal', '₹${quote.subtotal.toStringAsFixed(2)}'),
                _detailRow('Tax', '₹${quote.taxTotal.toStringAsFixed(2)}'),
                _detailRow('Total', '₹${quote.totalAmount.toStringAsFixed(2)}'),
                if (quote.notes.isNotEmpty) _detailRow('Notes', quote.notes),
                const SizedBox(height: 12),
                if (quote.items.isNotEmpty) ...[
                  Text(
                    'Items',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...quote.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${item.product} × ${item.quantity} @ ₹${item.unitPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: GoogleFonts.outfit(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Quote quote) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Quotation',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete ${quote.quoteNumber}? This cannot be undone.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alert),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await context.read<QuoteProvider>().deleteQuote(quote.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Quotation deleted successfully.'
                  : 'Failed to delete quotation.',
            ),
            backgroundColor: success ? AppColors.success : AppColors.alert,
          ),
        );
      }
    }
  }
}
