import 'package:crm/core/providers/lead_provider.dart';
import 'package:crm/core/providers/quote_provider.dart';
import 'package:crm/core/providers/task_provider.dart';
import 'package:crm/core/responsive.dart';
import 'package:crm/core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteProvider>().fetchQuotes();
      context.read<LeadProvider>().fetchLeads();
      context.read<TaskProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);
    return SingleChildScrollView(
      padding: padding,
      child: Consumer3<QuoteProvider, LeadProvider, TaskProvider>(
        builder: (context, quoteP, leadsP, tasksP, _) {
          if (quoteP.isLoading || leadsP.isLoading || tasksP.isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(100.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final leads = leadsP.leads;
          final quotes = quoteP.quotes;
          final tasks = tasksP.tasks;

          // Derived analytics
          final totalLeads = leads.length;
          final closedLeads = leads
              .where((l) => l.status == 'Order Confirmed')
              .length;
          final winRate = totalLeads > 0
              ? (closedLeads / totalLeads * 100).toStringAsFixed(1)
              : '0.0';

          final totalRevenue = leads
              .where((l) => l.status == 'Order Confirmed')
              .fold(0.0, (sum, l) => sum + l.value);

          final pipelineValue = leads.fold(0.0, (sum, l) => sum + l.value);

          final avgDealSize = closedLeads > 0
              ? (totalRevenue / closedLeads).toStringAsFixed(0)
              : '0';

          final completedTasks = tasks
              .where((t) => t.status == 'Completed')
              .length;
          final taskCompletionRate = tasks.isNotEmpty
              ? (completedTasks / tasks.length * 100).toStringAsFixed(0)
              : '0';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER ───────────────────────────────────────────
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
                        'Analytics',
                        style: GoogleFonts.outfit(
                          fontSize: isMobile ? 22 : 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Power BI-style data analysis & insights',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  _chipBadge('Live Data', AppColors.success),
                ],
              ),
              const SizedBox(height: 32),

              // ─── TOP KPI CARDS ────────────────────────────────────
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final w = constraints.maxWidth;
                  final isNarrow = w < 500;
                  final isMedium = w >= 500 && w < 900;
                  final kpiCards = [
                    _kpiCard(
                      'Win Rate',
                      '$winRate%',
                      Icons.emoji_events_outlined,
                      AppColors.success,
                      sub: '$closedLeads / $totalLeads deals',
                    ),
                    _kpiCard(
                      'Total Revenue',
                      '₹ ${_fmt(totalRevenue)}',
                      Icons.attach_money,
                      const Color(0xFF6C63FF),
                    ),
                    _kpiCard(
                      'Pipeline Value',
                      '₹ ${_fmt(pipelineValue)}',
                      Icons.account_tree_outlined,
                      AppColors.darkAccent,
                    ),
                    _kpiCard(
                      'Avg Deal Size',
                      '₹ $avgDealSize',
                      Icons.bar_chart,
                      const Color(0xFFFF6B6B),
                    ),
                    _kpiCard(
                      'Total Quotes',
                      '${quotes.length}',
                      Icons.receipt_long_outlined,
                      const Color(0xFF4ECDC4),
                    ),
                    _kpiCard(
                      'Task Completion',
                      '$taskCompletionRate%',
                      Icons.task_alt,
                      const Color(0xFFFFA500),
                      sub: '$completedTasks / ${tasks.length} tasks',
                    ),
                  ];
                  return Wrap(
                    spacing: isMobile ? 12 : 16,
                    runSpacing: isMobile ? 12 : 16,
                    children: kpiCards.map((card) {
                      final double cardW;
                      if (isNarrow) {
                        cardW = (w - 12) / 2 - 0.5;
                      } else if (isMedium) {
                        cardW = (w - 16 * 2) / 3 - 0.5;
                      } else {
                        cardW = (w - 16 * 2) / 3 - 0.5;
                      }
                      return SizedBox(width: cardW, child: card);
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),

              // ─── CHARTS ROW ────────────────────────────────────────
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final w = constraints.maxWidth;
                  final isNarrow = w < 700;
                  if (isNarrow) {
                    return Column(
                      children: [
                        _salesFunnelCard(leads),
                        const SizedBox(height: 24),
                        _weeklyTrendCard(leads, quotes),
                      ],
                    );
                  }
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: _salesFunnelCard(leads)),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 5,
                          child: _weeklyTrendCard(leads, quotes),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ─── REVENUE BREAKDOWN + TASK STATUS ─────────────────
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final w = constraints.maxWidth;
                  final isNarrow = w < 700;
                  if (isNarrow) {
                    return Column(
                      children: [
                        _revenueByStageCard(leads),
                        const SizedBox(height: 24),
                        _taskStatusCard(tasks),
                      ],
                    );
                  }
                  return SizedBox(
                    height: 400,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 6, child: _revenueByStageCard(leads)),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: _taskStatusCard(tasks)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ─── LEADS CONVERSION TABLE ───────────────────────────
              _conversionTable(leads),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // KPI Card
  // ──────────────────────────────────────────────────────────────
  Widget _kpiCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(
              sub,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Sales Funnel Chart (Power BI style)
  // ──────────────────────────────────────────────────────────────
  Widget _salesFunnelCard(List<Lead> leads) {
    final stages = [
      'New',
      'Contacted',
      'Quotation Sent',
      'Negotiation',
      'Order Confirmed',
    ];
    final stageCounts = stages
        .map((s) => leads.where((l) => l.status == s).length)
        .toList();
    final maxCount = stageCounts.isEmpty
        ? 1
        : stageCounts.reduce((a, b) => a > b ? a : b);
    final stageColors = [
      const Color(0xFF6C63FF),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFA500),
      const Color(0xFFFF6B6B),
      const Color(0xFF2ECC71),
    ];

    return _chartCard(
      title: 'Sales Funnel',
      subtitle: 'Lead progression through pipeline stages',
      icon: Icons.filter_alt_outlined,
      child: Column(
        children: List.generate(stages.length, (i) {
          final count = stageCounts[i];
          final ratio = maxCount > 0 ? count / maxCount : 0.0;
          final conversionRate = i == 0
              ? '100%'
              : stageCounts[0] > 0
              ? '${(count / stageCounts[0] * 100).toStringAsFixed(0)}%'
              : '0%';
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stages[i],
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMain,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$count leads',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: stageColors[i].withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            conversionRate,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: stageColors[i],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio.toDouble(),
                    minHeight: 10,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(stageColors[i]),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Weekly Trend Line Chart (Real Data)
  // ──────────────────────────────────────────────────────────────
  Widget _weeklyTrendCard(List<Lead> leads, List<Quote> quotes) {
    final now = DateTime.now();

    // Group by week (0 = current week, 6 = 6 weeks ago)
    List<int> leadsPerWeek = List.filled(7, 0);
    List<int> quotesPerWeek = List.filled(7, 0);

    for (var lead in leads) {
      if (lead.createdAt != null) {
        final daysAgo = now.difference(lead.createdAt!).inDays;
        final weekIdx = 6 - (daysAgo ~/ 7);
        if (weekIdx >= 0 && weekIdx < 7) {
          leadsPerWeek[weekIdx]++;
        }
      }
    }

    for (var quote in quotes) {
      if (quote.createdAt != null) {
        final daysAgo = now.difference(quote.createdAt!).inDays;
        final weekIdx = 6 - (daysAgo ~/ 7);
        if (weekIdx >= 0 && weekIdx < 7) {
          quotesPerWeek[weekIdx]++;
        }
      }
    }

    double maxY = 10;
    for (int i = 0; i < 7; i++) {
      if (leadsPerWeek[i] > maxY) maxY = leadsPerWeek[i].toDouble();
      if (quotesPerWeek[i] > maxY) maxY = quotesPerWeek[i].toDouble();
    }
    maxY = (maxY * 1.2).ceilToDouble(); // Add 20% headroom

    return _chartCard(
      title: 'Weekly Acquisition Trend',
      subtitle: 'New quotes & leads over past 7 weeks',
      icon: Icons.trending_up,
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 20 ? maxY / 5 : 5,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: AppColors.divider, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final weeks = [
                      'W-6',
                      'W-5',
                      'W-4',
                      'W-3',
                      'W-2',
                      'Last',
                      'This',
                    ];
                    final i = v.toInt();
                    return i >= 0 && i < weeks.length
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              weeks[i],
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: 6,
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              // Quotes line -> mapped to what was Customers
              LineChartBarData(
                spots: List.generate(
                  7,
                  (i) => FlSpot(i.toDouble(), quotesPerWeek[i].toDouble()),
                ),
                isCurved: true,
                color: const Color(0xFF6C63FF),
                barWidth: 2.5,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.07),
                ),
              ),
              // Leads line
              LineChartBarData(
                spots: List.generate(
                  7,
                  (i) => FlSpot(i.toDouble(), leadsPerWeek[i].toDouble()),
                ),
                isCurved: true,
                color: AppColors.success,
                barWidth: 2.5,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.success.withValues(alpha: 0.07),
                ),
              ),
            ],
          ),
        ),
      ),
      legend: Row(
        children: [
          _legendDot(const Color(0xFF6C63FF), 'Quotes'),
          const SizedBox(width: 16),
          _legendDot(AppColors.success, 'Leads'),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Revenue by Stage Bar Chart
  // ──────────────────────────────────────────────────────────────
  Widget _revenueByStageCard(List<Lead> leads) {
    final stages = [
      'New',
      'Contacted',
      'Quotation Sent',
      'Negotiation',
      'Order Confirmed',
      'Lost',
    ];
    final revenues = stages.map((s) {
      return leads
          .where((l) => l.status == s)
          .fold(0.0, (sum, l) => sum + l.value);
    }).toList();

    final maxRev = revenues.isEmpty
        ? 10000.0
        : revenues.reduce((a, b) => a > b ? a : b);
    final stageColors = [
      const Color(0xFF6C63FF),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFA500),
      const Color(0xFFFF6B6B),
      const Color(0xFF2ECC71),
      const Color(0xFF95A5A6),
    ];

    return _chartCard(
      title: 'Revenue by Pipeline Stage',
      subtitle: 'Total deal value across each stage',
      icon: Icons.bar_chart,
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxRev == 0 ? 10000 : maxRev * 1.3,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '₹ ${_fmt(rod.toY)}',
                    GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final labels = [
                      'New',
                      'Contact',
                      'Quote',
                      'Negot',
                      'Confirm',
                      'Lost',
                    ];
                    final i = value.toInt();
                    return i >= 0 && i < labels.length
                        ? Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              labels[i],
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (v, _) => Text(
                    '₹${_fmtK(v)}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: AppColors.divider, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              stages.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: revenues[i],
                    color: stageColors[i],
                    width: 36,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Task Status Donut Chart
  // ──────────────────────────────────────────────────────────────
  Widget _taskStatusCard(List<TaskModel> tasks) {
    final pending = tasks.where((t) => t.status == 'Pending').length.toDouble();
    final inProgress = tasks
        .where((t) => t.status == 'In Progress')
        .length
        .toDouble();
    final completed = tasks
        .where((t) => t.status == 'Completed')
        .length
        .toDouble();
    final total = pending + inProgress + completed;

    return _chartCard(
      title: 'Task Status',
      subtitle: 'Breakdown of all tasks by status',
      icon: Icons.donut_large_outlined,
      child: total == 0
          ? Center(
              child: Text(
                'No task data yet',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            )
          : SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 48,
                  sections: [
                    if (pending > 0)
                      PieChartSectionData(
                        value: pending,
                        color: AppColors.alert,
                        title: '${pending.toInt()}',
                        titleStyle: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        radius: 55,
                      ),
                    if (inProgress > 0)
                      PieChartSectionData(
                        value: inProgress,
                        color: const Color(0xFFFFA500),
                        title: '${inProgress.toInt()}',
                        titleStyle: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        radius: 55,
                      ),
                    if (completed > 0)
                      PieChartSectionData(
                        value: completed,
                        color: AppColors.success,
                        title: '${completed.toInt()}',
                        titleStyle: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        radius: 55,
                      ),
                  ],
                ),
              ),
            ),
      legend: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(AppColors.alert, 'Pending'),
          const SizedBox(width: 12),
          _legendDot(const Color(0xFFFFA500), 'In Progress'),
          const SizedBox(width: 12),
          _legendDot(AppColors.success, 'Completed'),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Lead Conversion Metrics Table
  // ──────────────────────────────────────────────────────────────
  Widget _conversionTable(List<Lead> leads) {
    final stages = [
      'New',
      'Contacted',
      'Quotation Sent',
      'Negotiation',
      'Order Confirmed',
      'Lost',
    ];
    final totalLeads = leads.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.table_chart_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                'Conversion Rate Analysis',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Stage-by-stage lead drop-off analysis',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              dataTextStyle: GoogleFonts.outfit(
                color: AppColors.textMain,
                fontSize: 14,
              ),
              columns: const [
                DataColumn(label: Text('Stage')),
                DataColumn(label: Text('Count')),
                DataColumn(label: Text('% of Total')),
                DataColumn(label: Text('Conversion to Next')),
                DataColumn(label: Text('Pipeline Value')),
              ],
              rows: List.generate(stages.length, (i) {
                final count = leads.where((l) => l.status == stages[i]).length;
                final nextCount = i < stages.length - 1
                    ? leads.where((l) => l.status == stages[i + 1]).length
                    : count;
                final pct = totalLeads > 0
                    ? (count / totalLeads * 100).toStringAsFixed(1)
                    : '0';
                final convRate = count > 0
                    ? '${(nextCount / count * 100).toStringAsFixed(0)}%'
                    : '-';
                final stageValue = leads
                    .where((l) => l.status == stages[i])
                    .fold(0.0, (sum, l) => sum + l.value);
                return DataRow(
                  cells: [
                    DataCell(Text(stages[i])),
                    DataCell(Text('$count')),
                    DataCell(Text('$pct%')),
                    DataCell(
                      i == stages.length - 1
                          ? const Text('—')
                          : Text(
                              convRate,
                              style: TextStyle(
                                color: _parseConvRate(convRate) > 50
                                    ? AppColors.success
                                    : AppColors.alert,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    DataCell(Text('₹ ${_fmt(stageValue)}')),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────
  Widget _chartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? legend,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
          if (legend != null) ...[const SizedBox(height: 16), legend],
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _chipBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _fmtK(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  double _parseConvRate(String convRate) {
    final cleaned = convRate.replaceAll('%', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}
