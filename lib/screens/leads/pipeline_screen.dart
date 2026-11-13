// ignore_for_file: unnecessary_underscores

import 'package:crm/core/providers/lead_provider.dart';
import 'package:crm/core/responsive.dart';
import 'package:crm/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  // Track which column is being hovered over for visual feedback
  String? _hoveredColumn;

  static const _stageColors = {
    'New': Color(0xFF6C63FF),
    'Contacted': Color(0xFF4ECDC4),
    'Quotation Sent': Color(0xFFFFA500),
    'Negotiation': Color(0xFFFF6B6B),
    'Order Confirmed': Color(0xFF2ECC71),
    'Lost': Color(0xFF95A5A6),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadProvider>().fetchLeads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);
    final colWidth = isMobile ? 240.0 : 280.0;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pipeline',
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Drag & drop leads between stages',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddLeadDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Lead'),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 28),

          // Kanban board
          Expanded(
            child: Consumer<LeadProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: kLeadStatuses.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final status = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: idx < kLeadStatuses.length - 1
                              ? (isMobile ? 10.0 : 16.0)
                              : 0,
                        ),
                        child: SizedBox(
                          width: colWidth,
                          child: _buildDropColumn(
                            context,
                            provider,
                            status,
                            colWidth,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── DROP TARGET COLUMN ──────────────────────────────────────
  Widget _buildDropColumn(
    BuildContext context,
    LeadProvider provider,
    String status,
    double width,
  ) {
    final leads = provider.byStatus(status);
    final stageColor = _stageColors[status] ?? AppColors.darkAccent;
    final isHovered = _hoveredColumn == status;

    return DragTarget<Lead>(
      onWillAcceptWithDetails: (details) {
        final lead = details.data;
        if (lead.status != status) {
          setState(() => _hoveredColumn = status);
          return true;
        }
        return false;
      },
      onLeave: (_) {
        setState(() => _hoveredColumn = null);
      },
      onAcceptWithDetails: (details) async {
        final lead = details.data;
        setState(() => _hoveredColumn = null);
        // Update in backend
        final success = await provider.updateStatus(lead.id, status);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? '${lead.name} moved to $status'
                    : 'Failed to update lead',
              ),
              backgroundColor: success ? AppColors.success : AppColors.alert,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovered
                ? stageColor.withOpacity(0.08)
                : AppColors.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? stageColor : AppColors.divider,
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: stageColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: stageColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${leads.length}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: stageColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Total value
              Text(
                '₹ ${_fmtValue(leads.fold(0.0, (sum, l) => sum + l.value))}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),

              // Cards list
              Expanded(
                child: leads.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 32,
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Drop leads here',
                              style: GoogleFonts.outfit(
                                color: AppColors.textSecondary.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: leads.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildDraggableCard(provider, leads[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── DRAGGABLE CARD ─────────────────────────────────────────
  Widget _buildDraggableCard(LeadProvider provider, Lead lead) {
    return Draggable<Lead>(
      data: lead,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 240,
          child: _leadCardContent(lead, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _leadCardContent(lead)),
      child: _leadCardContent(lead, provider: provider),
    );
  }

  Widget _leadCardContent(
    Lead lead, {
    bool isDragging = false,
    LeadProvider? provider,
  }) {
    final stageColor = _stageColors[lead.status] ?? AppColors.darkAccent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDragging ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDragging ? stageColor : AppColors.divider,
          width: isDragging ? 2 : 1,
        ),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: stageColor.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + actions
          Row(
            children: [
              Expanded(
                child: Text(
                  lead.company.isNotEmpty ? lead.company : lead.name,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (provider != null && !isDragging)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      await provider.deleteLead(lead.id);
                    } else {
                      await provider.updateStatus(lead.id, value);
                    }
                  },
                  itemBuilder: (_) => [
                    ...kLeadStatuses
                        .where((s) => s != lead.status)
                        .map(
                          (s) => PopupMenuItem(
                            value: s,
                            child: Text(
                              '→ $s',
                              style: GoogleFonts.outfit(fontSize: 13),
                            ),
                          ),
                        ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: GoogleFonts.outfit(
                          color: AppColors.alert,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Contact
          if (lead.email.isNotEmpty)
            Text(
              lead.email,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          if (lead.name.isNotEmpty && lead.company.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                lead.name,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 10),
          // Value + handle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹ ${lead.value.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: stageColor,
                ),
              ),
              if (!isDragging)
                Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: AppColors.textSecondary.withOpacity(0.4),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── ADD LEAD DIALOG ────────────────────────────────────────
  void _showAddLeadDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final valueCtrl = TextEditingController(text: '0');
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
                  _field('Name *', nameCtrl),
                  const SizedBox(height: 12),
                  _field('Company', companyCtrl),
                  const SizedBox(height: 12),
                  _field(
                    'Email',
                    emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _field('Phone', phoneCtrl, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field(
                    'Deal Value (₹)',
                    valueCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      labelText: 'Stage',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a name'),
                      backgroundColor: AppColors.alert,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final success = await context.read<LeadProvider>().createLead({
                  'name': nameCtrl.text.trim(),
                  'company': companyCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'status': status,
                  'value': double.tryParse(valueCtrl.text) ?? 0.0,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Lead added to $status!'
                            : 'Failed to add lead',
                      ),
                      backgroundColor: success
                          ? AppColors.success
                          : AppColors.alert,
                    ),
                  );
                }
              },
              child: const Text('Add Lead'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _fmtValue(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
