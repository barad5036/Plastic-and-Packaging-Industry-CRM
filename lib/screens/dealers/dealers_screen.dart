import 'package:crm/core/providers/dealer_provider.dart';
import 'package:crm/core/responsive.dart';
import 'package:crm/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DealersScreen extends StatefulWidget {
  const DealersScreen({super.key});

  @override
  State<DealersScreen> createState() => _DealersScreenState();
}

class _DealersScreenState extends State<DealersScreen> {
  String _statusFilter = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DealerProvider>().fetchDealers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.alert : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Text(
                'Dealers',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Search
                  SizedBox(
                    width: 220,
                    height: 38,
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search dealers…',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      onChanged: (v) {
                        context.read<DealerProvider>().fetchDealers(
                          search: v,
                          status: _statusFilter,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status filter
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.textMain,
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _statusFilter = v);
                          context.read<DealerProvider>().fetchDealers(
                            search: _searchCtrl.text,
                            status: v,
                          );
                        },
                        items: ['All', ...kDealerStatuses]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDealerDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Dealer'),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          // ── KPI Cards ──
          Consumer<DealerProvider>(
            builder: (context, provider, _) {
              final allDealers = provider.dealers;
              final active = allDealers
                  .where((d) => d.status == 'Active')
                  .length;
              final inactive = allDealers
                  .where((d) => d.status == 'Inactive')
                  .length;
              final totalCredit = allDealers.fold<double>(
                0,
                (sum, d) => sum + d.creditLimit,
              );
              if (isMobile) {
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.8,
                  children: [
                    _kpiCard(
                      'Total Dealers',
                      '${allDealers.length}',
                      Icons.storefront,
                      const Color(0xFF6C63FF),
                    ),
                    _kpiCard(
                      'Active',
                      '$active',
                      Icons.check_circle_outline,
                      const Color(0xFF2ECC71),
                    ),
                    _kpiCard(
                      'Inactive',
                      '$inactive',
                      Icons.pause_circle_outline,
                      const Color(0xFFFFA500),
                    ),
                    _kpiCard(
                      'Total Credit',
                      '₹${totalCredit.toStringAsFixed(0)}',
                      Icons.account_balance_wallet,
                      const Color(0xFF4ECDC4),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  _kpiCard(
                    'Total Dealers',
                    '${allDealers.length}',
                    Icons.storefront,
                    const Color(0xFF6C63FF),
                  ),
                  const SizedBox(width: 16),
                  _kpiCard(
                    'Active',
                    '$active',
                    Icons.check_circle_outline,
                    const Color(0xFF2ECC71),
                  ),
                  const SizedBox(width: 16),
                  _kpiCard(
                    'Inactive',
                    '$inactive',
                    Icons.pause_circle_outline,
                    const Color(0xFFFFA500),
                  ),
                  const SizedBox(width: 16),
                  _kpiCard(
                    'Total Credit Limit',
                    '₹${totalCredit.toStringAsFixed(0)}',
                    Icons.account_balance_wallet,
                    const Color(0xFF4ECDC4),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: isMobile ? 16 : 24),
          // ── Data Table ──
          Expanded(
            child: Consumer<DealerProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final dealers = provider.dealers;
                if (dealers.isEmpty) {
                  return Center(
                    child: Text(
                      'No dealers found.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                final scrollH = ScrollController();
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Scrollbar(
                    controller: scrollH,
                    child: SingleChildScrollView(
                      controller: scrollH,
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingTextStyle: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                          columns: const [
                            DataColumn(label: Text('Code')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Company')),
                            DataColumn(label: Text('Phone')),
                            DataColumn(label: Text('City')),
                            DataColumn(label: Text('State')),
                            DataColumn(label: Text('GST No.')),
                            DataColumn(label: Text('Credit Limit')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: dealers.map((d) {
                            return DataRow(
                              cells: [
                                DataCell(Text(d.dealerCode)),
                                DataCell(Text(d.name)),
                                DataCell(
                                  Text(d.company.isEmpty ? '-' : d.company),
                                ),
                                DataCell(Text(d.phone.isEmpty ? '-' : d.phone)),
                                DataCell(Text(d.city.isEmpty ? '-' : d.city)),
                                DataCell(Text(d.state.isEmpty ? '-' : d.state)),
                                DataCell(
                                  Text(d.gstNumber.isEmpty ? '-' : d.gstNumber),
                                ),
                                DataCell(
                                  Text('₹${d.creditLimit.toStringAsFixed(0)}'),
                                ),
                                DataCell(_statusChip(d.status)),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.alert,
                                          size: 18,
                                        ),
                                        onPressed: () async {
                                          final ok = await provider
                                              .deleteDealer(d.id);
                                          _showMsg(
                                            ok
                                                ? 'Dealer deleted.'
                                                : 'Failed to delete.',
                                            isError: !ok,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    final isMobile = Responsive.isMobile(context);
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'Active':
        color = const Color(0xFF2ECC71);
        break;
      case 'Inactive':
        color = const Color(0xFFFFA500);
        break;
      case 'Suspended':
        color = const Color(0xFFFF6B6B);
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showAddDealerDialog() {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final gstCtrl = TextEditingController();
    final creditCtrl = TextEditingController(text: '0');
    final addressCtrl = TextEditingController();
    String status = 'Active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(
            'Add New Dealer',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(labelText: 'Company'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: stateCtrl,
                          decoration: const InputDecoration(labelText: 'State'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: gstCtrl,
                    decoration: const InputDecoration(labelText: 'GST Number'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: creditCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Credit Limit (₹)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: kDealerStatuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setDlg(() => status = v ?? status),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  _showMsg('Name is required.', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                final ok = await context.read<DealerProvider>().createDealer({
                  'name': nameCtrl.text.trim(),
                  'company': companyCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'city': cityCtrl.text.trim(),
                  'state': stateCtrl.text.trim(),
                  'gst_number': gstCtrl.text.trim(),
                  'credit_limit': double.tryParse(creditCtrl.text) ?? 0.0,
                  'address': addressCtrl.text.trim(),
                  'status': status,
                });
                _showMsg(
                  ok ? 'Dealer added successfully.' : 'Failed to add dealer.',
                  isError: !ok,
                );
              },
              child: const Text('Add Dealer'),
            ),
          ],
        ),
      ),
    );
  }
}
