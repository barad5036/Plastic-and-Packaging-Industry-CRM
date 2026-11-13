import 'dart:convert';
import 'dart:io';

import 'package:crm/core/providers/lead_provider.dart';
import 'package:crm/core/responsive.dart';
import 'package:crm/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:intl/intl.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  String _selectedStatusFilter = 'All Active';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadProvider>().fetchLeads();
    });
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final extension = result.files.single.extension?.toLowerCase();

        List<List<dynamic>> rows = [];

        if (extension == 'csv') {
          final input = File(path).openRead();
          rows = await input
              .transform(utf8.decoder)
              .transform(const CsvToListConverter())
              .toList();
        } else if (extension == 'xlsx' || extension == 'xls') {
          var bytes = File(path).readAsBytesSync();
          var excel = Excel.decodeBytes(bytes);

          for (var table in excel.tables.keys) {
            final sheet = excel.tables[table];
            if (sheet != null) {
              for (var row in sheet.rows) {
                rows.add(row.map((e) => e?.value?.toString() ?? '').toList());
              }
            }
            break; // Read first sheet only
          }
        }

        if (rows.length <= 1) {
          _showMessage(
            context,
            'File is empty or missing headers.',
            isError: true,
          );
          return;
        }

        final headers = rows[0]
            .map((e) => e.toString().toLowerCase().trim())
            .toList();

        // ── Flexible column detection ──
        int findCol(List<String> hdrs, List<String> candidates) {
          for (final c in candidates) {
            final idx = hdrs.indexOf(c);
            if (idx != -1) return idx;
          }
          // Fallback: partial match
          for (final c in candidates) {
            final idx = hdrs.indexWhere((h) => h.contains(c));
            if (idx != -1) return idx;
          }
          return -1;
        }

        int nameIdx = findCol(headers, [
          'party name',
          'name',
          'contact',
          'company / contact',
        ]);
        int companyIdx = findCol(headers, ['company', 'company / contact']);
        int emailIdx = findCol(headers, ['email']);
        int phoneIdx = findCol(headers, [
          'party number',
          'phone',
          'mobile',
          'contact number',
        ]);
        int statusIdx = findCol(headers, ['status']);
        int valueIdx = findCol(headers, ['value', 'amount']);
        int typeIdx = findCol(headers, [
          'one time',
          'customer type',
          'type',
          'repeated',
        ]);
        int cityIdx = findCol(headers, ['city']);
        int stateIdx = findCol(headers, ['state']);
        int dateIdx = findCol(headers, ['inquiry date', 'date', 'inquiry']);
        int f1Idx = findCol(headers, [
          'follow up-1',
          'follow up 1',
          'followup1',
          'follow_up_1',
        ]);
        int f2Idx = findCol(headers, [
          'follow up-2',
          'follow up 2',
          'followup2',
          'follow_up_2',
        ]);
        int f3Idx = findCol(headers, [
          'follow up-3',
          'follow up 3',
          'followup3',
          'follow_up_3',
        ]);

        String cell(List<dynamic> row, int idx) {
          if (idx == -1 || idx >= row.length) return '';
          return row[idx].toString().trim();
        }

        int importedCount = 0;
        final provider = context.read<LeadProvider>();
        final List<Map<String, dynamic>> bulkLeads = [];

        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];

          String name = '';
          String company = '';

          if (nameIdx != -1 && nameIdx < row.length) {
            String combined = row[nameIdx].toString().trim();
            if (headers[nameIdx].contains('company / contact')) {
              var parts = combined.split('/');
              if (parts.length > 1) {
                company = parts[0].trim();
                name = parts[1].trim();
              } else {
                name = combined;
              }
            } else {
              name = combined;
            }
          }

          if (company.isEmpty) company = cell(row, companyIdx);

          String email = cell(row, emailIdx);
          String phone = cell(row, phoneIdx);
          String customerType = cell(row, typeIdx);
          String city = cell(row, cityIdx);
          String state = cell(row, stateIdx);
          String followUp1 = cell(row, f1Idx);
          String followUp2 = cell(row, f2Idx);
          String followUp3 = cell(row, f3Idx);
          String dateStr = cell(row, dateIdx);

          String rawStatus = cell(row, statusIdx);
          if (rawStatus.isEmpty) rawStatus = 'New';

          String lowerStatus = rawStatus.toLowerCase();
          if (lowerStatus.contains('not respond')) {
            rawStatus = 'Contacted';
          } else if (lowerStatus.contains('order closed') ||
              lowerStatus.contains('order') ||
              lowerStatus.contains('won') ||
              lowerStatus.contains('closed')) {
            rawStatus = 'Order Confirmed';
          } else if (lowerStatus.contains('forward')) {
            rawStatus = 'Contacted';
          } else if (lowerStatus.contains('rate given') ||
              lowerStatus.contains('rate')) {
            rawStatus = 'Quotation Sent';
          } else if (lowerStatus.contains('new')) {
            rawStatus = 'New';
          } else if (lowerStatus.contains('contact')) {
            rawStatus = 'Contacted';
          } else if (lowerStatus.contains('quotation')) {
            rawStatus = 'Quotation Sent';
          } else if (lowerStatus.contains('negotiation')) {
            rawStatus = 'Negotiation';
          } else if (lowerStatus.contains('lost')) {
            rawStatus = 'Lost';
          } else {
            rawStatus = 'New';
          }

          double value = 0.0;
          if (valueIdx != -1 && valueIdx < row.length) {
            String valStr = row[valueIdx].toString().replaceAll(
              RegExp(r'[^0-9.]'),
              '',
            );
            value = double.tryParse(valStr) ?? 0.0;
          }

          if (name.isEmpty && company.isEmpty && phone.isEmpty) {
            continue; // Skip entirely empty rows
          }

          bulkLeads.add({
            'name': name.isEmpty
                ? (company.isNotEmpty ? company : 'Unknown')
                : name,
            'company': company,
            'email': email,
            'phone': phone,
            'customer_type': customerType,
            'city': city,
            'state': state,
            'follow_up_1': followUp1,
            'follow_up_2': followUp2,
            'follow_up_3': followUp3,
            'inquiry_date': dateStr,
            'status': rawStatus,
            'value': value,
          });
        }

        if (bulkLeads.isEmpty) {
          _showMessage(
            context,
            'No valid data rows found in file.',
            isError: true,
          );
          return;
        }

        // Single bulk API call
        final importResult = await provider.importLeads(bulkLeads);
        importedCount = importResult['imported'] ?? 0;
        final message = importResult['message'] ?? 'Import complete';

        _showMessage(
          context,
          '$message ($importedCount leads)',
          isError: importedCount == 0,
        );
      }
    } catch (e) {
      _showMessage(context, 'Failed to import data: $e', isError: true);
    }
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final provider = context.read<LeadProvider>();
      final leads = provider.leads;

      // Ask user to choose format
      final format = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Export Format',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Choose the export file format:',
            style: GoogleFonts.outfit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'csv'),
              child: const Text('CSV'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'xlsx'),
              child: const Text('Excel (.xlsx)'),
            ),
          ],
        ),
      );

      if (format == null) return;

      List<List<dynamic>> rows = [];
      rows.add(['Name', 'Company', 'Email', 'Phone', 'Status', 'Value']);

      for (var lead in leads) {
        rows.add([
          lead.name,
          lead.company,
          lead.email,
          lead.phone,
          lead.status,
          lead.value,
        ]);
      }

      String fileName = 'leads_export.$format';
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Leads List',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [format],
      );

      if (result != null) {
        final file = File(result);

        if (format == 'csv') {
          String csv = const ListToCsvConverter().convert(rows);
          await file.writeAsString(csv);
        } else {
          var excel = Excel.createExcel();
          Sheet sheetObject = excel[excel.getDefaultSheet()!];

          for (var i = 0; i < rows.length; i++) {
            final row = rows[i];
            List<CellValue> cellValues = row.map((e) {
              if (e is double) {
                return DoubleCellValue(e);
              } else if (e is num) {
                return IntCellValue(e.toInt());
              }
              return TextCellValue(e.toString());
            }).toList();
            sheetObject.appendRow(cellValues);
          }

          var fileBytes = excel.save();
          if (fileBytes != null) {
            await file.writeAsBytes(fileBytes);
          }
        }

        _showMessage(context, 'Successfully exported leads to $result');
      }
    } catch (e) {
      _showMessage(context, 'Failed to export data: $e', isError: true);
    }
  }

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.alert : AppColors.success,
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Clear All Leads',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete ALL leads? This action cannot be undone.',
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
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await context.read<LeadProvider>().clearAllLeads();
      _showMessage(
        context,
        success ? 'All leads cleared.' : 'Failed to clear leads.',
        isError: !success,
      );
    }
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leads',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              if (isMobile)
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showAddLeadDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        textStyle: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          size: 18,
                          color: AppColors.textMain,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'import':
                            _importData(context);
                            break;
                          case 'export':
                            _exportData(context);
                            break;
                          case 'clear':
                            _confirmClearAll(context);
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'import',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.upload_file,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Import CSV/Excel',
                                style: GoogleFonts.outfit(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.download,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Export CSV/Excel',
                                style: GoogleFonts.outfit(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_forever,
                                size: 18,
                                color: AppColors.alert,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Clear All',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppColors.alert,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Filter row ──
          if (isMobile)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatusFilter,
                  isExpanded: true,
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
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  menuMaxHeight: 300,
                  onChanged: (String? newValue) {
                    if (newValue != null)
                      setState(() => _selectedStatusFilter = newValue);
                  },
                  items: {'All Active', 'All Leads', ...kLeadStatuses}
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: _selectedStatusFilter == value
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: _selectedStatusFilter == value
                                  ? AppColors.darkAccent
                                  : AppColors.textMain,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
            ),
          if (!isMobile)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
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
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      menuMaxHeight: 300,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedStatusFilter = newValue;
                          });
                        }
                      },
                      items: {'All Active', 'All Leads', ...kLeadStatuses}
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Container(
                                alignment: Alignment.centerLeft,
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  value,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: _selectedStatusFilter == value
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: _selectedStatusFilter == value
                                        ? AppColors.darkAccent
                                        : AppColors.textMain,
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _importData(context),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Import CSV/Excel'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _exportData(context),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export CSV/Excel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddLeadDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Lead'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _confirmClearAll(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alert,
                  ),
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('Clear All'),
                ),
              ],
            ),
          SizedBox(height: isMobile ? 16 : 28),
          Expanded(
            child: Consumer<LeadProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null && provider.leads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 40,
                          color: AppColors.alert.withValues(alpha: 0.9),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Backend: ${provider.leads.isEmpty ? 'not loaded' : 'loaded'} · ${context.read<LeadProvider>().leads.length} cached leads',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: provider.fetchLeads,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final leads = provider.leads.where((l) {
                  if (_selectedStatusFilter == 'All Active') {
                    return l.status != 'Order Confirmed' && l.status != 'Lost';
                  } else if (_selectedStatusFilter == 'All Leads') {
                    return true;
                  }
                  return l.status == _selectedStatusFilter;
                }).toList();
                if (leads.isEmpty) {
                  return Center(
                    child: Text(
                      'No active leads available.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                final scrollController = ScrollController();
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingTextStyle: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Company')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Phone')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Value')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Date'), numeric: true),
                            DataColumn(label: Text('City')),
                            DataColumn(label: Text('State')),
                            DataColumn(label: Text('Follow Up 1')),
                            DataColumn(label: Text('Follow Up 2')),
                            DataColumn(label: Text('Follow Up 3')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: leads.map((lead) {
                            return DataRow(
                              cells: [
                                DataCell(Text(lead.name)),
                                DataCell(
                                  Text(
                                    lead.company.isEmpty ? '-' : lead.company,
                                  ),
                                ),
                                DataCell(
                                  Text(lead.email.isEmpty ? '-' : lead.email),
                                ),
                                DataCell(
                                  Text(lead.phone.isEmpty ? '-' : lead.phone),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        lead.status,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      lead.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(lead.status),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text('\$${lead.value.toStringAsFixed(0)}'),
                                ),
                                DataCell(
                                  Text(
                                    lead.customerType.isEmpty
                                        ? '-'
                                        : lead.customerType,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    lead.inquiryDate != null
                                        ? DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(lead.inquiryDate!)
                                        : '-',
                                  ),
                                ),
                                DataCell(
                                  Text(lead.city.isEmpty ? '-' : lead.city),
                                ),
                                DataCell(
                                  Text(lead.state.isEmpty ? '-' : lead.state),
                                ),
                                // Follow Up 1 — read-only
                                DataCell(
                                  Text(
                                    lead.followUp1.isEmpty
                                        ? '-'
                                        : lead.followUp1,
                                  ),
                                ),
                                // Follow Up 2 — inline editable
                                DataCell(
                                  Text(
                                    lead.followUp2.isEmpty
                                        ? '+ Add'
                                        : lead.followUp2,
                                    style: TextStyle(
                                      color: lead.followUp2.isEmpty
                                          ? AppColors.darkAccent
                                          : AppColors.textMain,
                                      fontWeight: lead.followUp2.isEmpty
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  showEditIcon: true,
                                  onTap: () => _showInlineFollowUpEditor(
                                    context,
                                    lead,
                                    'follow_up_2',
                                    lead.followUp2,
                                    'Follow Up 2',
                                  ),
                                ),
                                // Follow Up 3 — inline editable
                                DataCell(
                                  Text(
                                    lead.followUp3.isEmpty
                                        ? '+ Add'
                                        : lead.followUp3,
                                    style: TextStyle(
                                      color: lead.followUp3.isEmpty
                                          ? AppColors.darkAccent
                                          : AppColors.textMain,
                                      fontWeight: lead.followUp3.isEmpty
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  showEditIcon: true,
                                  onTap: () => _showInlineFollowUpEditor(
                                    context,
                                    lead,
                                    'follow_up_3',
                                    lead.followUp3,
                                    'Follow Up 3',
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: AppColors.darkAccent,
                                          size: 18,
                                        ),
                                        tooltip: 'Edit Lead',
                                        onPressed: () =>
                                            _showEditLeadDialog(context, lead),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.alert,
                                          size: 18,
                                        ),
                                        tooltip: 'Delete Lead',
                                        onPressed: () {
                                          provider.deleteLead(lead.id);
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

  /// Inline editor popup for Follow Up 2 / Follow Up 3
  void _showInlineFollowUpEditor(
    BuildContext context,
    Lead lead,
    String fieldKey,
    String currentValue,
    String label,
  ) {
    final ctrl = TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Edit $label',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: label,
                hintText: 'Enter follow-up notes...',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return '$label cannot be empty';
                if (v.trim().length < 3) return 'Enter at least 3 characters';
                return null;
              },
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
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final provider = context.read<LeadProvider>();
              final data = <String, dynamic>{fieldKey: ctrl.text.trim()};
              await provider.updateLead(lead.id, data);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Full edit lead dialog — edits all fields
  void _showEditLeadDialog(BuildContext context, Lead lead) {
    final nameCtrl = TextEditingController(text: lead.name);
    final companyCtrl = TextEditingController(text: lead.company);
    final emailCtrl = TextEditingController(text: lead.email);
    final phoneCtrl = TextEditingController(text: lead.phone);
    final valueCtrl = TextEditingController(
      text: lead.value.toStringAsFixed(0),
    );
    final typeCtrl = TextEditingController(text: lead.customerType);
    final cityCtrl = TextEditingController(text: lead.city);
    final stateCtrl = TextEditingController(text: lead.state);
    final f1Ctrl = TextEditingController(text: lead.followUp1);
    final f2Ctrl = TextEditingController(text: lead.followUp2);
    final f3Ctrl = TextEditingController(text: lead.followUp3);
    String status = lead.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(
            'Edit Lead',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: 450,
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
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valueCtrl,
                    decoration: const InputDecoration(labelText: 'Value'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Type (One time/Repeated)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stateCtrl,
                    decoration: const InputDecoration(labelText: 'State'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: f1Ctrl,
                    decoration: const InputDecoration(labelText: 'Follow Up 1'),
                    readOnly: true,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: f2Ctrl,
                    decoration: const InputDecoration(labelText: 'Follow Up 2'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: f3Ctrl,
                    decoration: const InputDecoration(labelText: 'Follow Up 3'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: kLeadStatuses.contains(status) ? status : 'New',
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: kLeadStatuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setStateDialog(() => status = v ?? status),
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
                  _showMessage(context, 'Name is required.', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                final provider = context.read<LeadProvider>();
                await provider.updateLead(lead.id, {
                  'name': nameCtrl.text.trim(),
                  'company': companyCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'customer_type': typeCtrl.text.trim(),
                  'city': cityCtrl.text.trim(),
                  'state': stateCtrl.text.trim(),
                  'follow_up_1': f1Ctrl.text.trim(),
                  'follow_up_2': f2Ctrl.text.trim(),
                  'follow_up_3': f3Ctrl.text.trim(),
                  'status': status,
                  'value': double.tryParse(valueCtrl.text) ?? 0.0,
                });
                _showMessage(context, 'Lead updated successfully.');
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLeadDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final valueCtrl = TextEditingController(text: '0');
    final typeCtrl = TextEditingController(text: 'one time');
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final f1Ctrl = TextEditingController();
    final f2Ctrl = TextEditingController();
    final f3Ctrl = TextEditingController();
    String status = 'New';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(
            'Add New Lead',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: 420,
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
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valueCtrl,
                    decoration: const InputDecoration(labelText: 'Value (₹)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Type (One time/Repeated)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stateCtrl,
                    decoration: const InputDecoration(labelText: 'State'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: f1Ctrl,
                    decoration: const InputDecoration(labelText: 'Follow Up 1'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: f2Ctrl,
                    decoration: const InputDecoration(labelText: 'Follow Up 2'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: f3Ctrl,
                    decoration: const InputDecoration(labelText: 'Follow Up 3'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: kLeadStatuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setStateDialog(() => status = v ?? status),
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
                  _showMessage(context, 'Name is required.', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                final success = await context.read<LeadProvider>().createLead({
                  'name': nameCtrl.text.trim(),
                  'company': companyCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'customer_type': typeCtrl.text.trim(),
                  'city': cityCtrl.text.trim(),
                  'state': stateCtrl.text.trim(),
                  'follow_up_1': f1Ctrl.text.trim(),
                  'follow_up_2': f2Ctrl.text.trim(),
                  'follow_up_3': f3Ctrl.text.trim(),
                  'inquiry_date': DateTime.now().toIso8601String(),
                  'status': status,
                  'value': double.tryParse(valueCtrl.text) ?? 0.0,
                });
                _showMessage(
                  context,
                  success ? 'Lead added successfully.' : 'Failed to add lead.',
                  isError: !success,
                );
              },
              child: const Text('Add Lead'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return const Color(0xFF6C63FF);
      case 'Contacted':
        return const Color(0xFF4ECDC4);
      case 'Quotation Sent':
        return const Color(0xFFFFA500);
      case 'Negotiation':
        return const Color(0xFFFF6B6B);
      case 'Order Confirmed':
        return const Color(0xFF2ECC71);
      case 'Lost':
        return const Color(0xFF95A5A6);
      default:
        return AppColors.textSecondary;
    }
  }
}
