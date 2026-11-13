import 'package:crm/core/providers/dashboard_provider.dart';
import 'package:crm/core/providers/lead_provider.dart';
import 'package:crm/core/responsive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Theme constants matching the provided screenshot
  static const Color bgColor = Color(0xFFF4F7FE);
  static const Color cardColor = Colors.white;
  static const Color textMain = Color(0xFF2B3674);
  static const Color textDisabled = Color(0xFFA3AED0);
  static const Color primaryBlue = Color(0xFF4318FF);
  static const Color bgLightBlue = Color(0xFFF4F7FE); // Icon background
  static const Color greenTrend = Color(0xFF05CD99);
  static const Color redTrend = Color(0xFFEE5D50);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchSummary();
      context.read<LeadProvider>().fetchLeads();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DashboardProvider, LeadProvider>(
      builder: (context, dashProvider, leadProvider, _) {
        if (dashProvider.isLoading || leadProvider.isLoading) {
          return Container(
            color: bgColor,
            child: const Center(
              child: CircularProgressIndicator(color: primaryBlue),
            ),
          );
        }

        final summary = dashProvider.displaySummary;
        final leads = leadProvider.leads;
        final totalLeads = leads.length;
        final newLeads = leads.where((l) => l.status == 'New').length;
        final contacted = leads.where((l) => l.status == 'Contacted').length;
        final quotationSent = leads
            .where((l) => l.status == 'Quotation Sent')
            .length;
        final negotiation = leads
            .where((l) => l.status == 'Negotiation')
            .length;
        final orderConfirmed = leads
            .where((l) => l.status == 'Order Confirmed')
            .length;

        final totalRevenue = summary.totalRevenue;
        final avgDealSize = orderConfirmed > 0
            ? totalRevenue / orderConfirmed
            : 0.0;
        final conversionRate = totalLeads > 0
            ? (orderConfirmed / totalLeads) * 100
            : 0.0;

        String formatCurrency(double val) {
          if (val >= 100000) {
            return '₹${(val / 100000).toStringAsFixed(1)}L';
          }
          return '₹${val.toStringAsFixed(0)}';
        }

        final isMobile = Responsive.isMobile(context);
        final isTablet = Responsive.isTablet(context);
        final hPad = isMobile ? 16.0 : (isTablet ? 24.0 : 40.0);
        final vPad = isMobile ? 16.0 : 32.0;

        return Container(
          color: bgColor,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: isMobile ? 20 : 36),

                // ── 8 KPI CARDS ──
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 1200
                        ? 4
                        : (constraints.maxWidth > 800 ? 2 : 1);
                    double childAspectRatio;
                    if (constraints.maxWidth > 1200) {
                      childAspectRatio = 2.2;
                    } else if (constraints.maxWidth > 800) {
                      childAspectRatio = 2.5;
                    } else if (constraints.maxWidth > 400) {
                      childAspectRatio = 3.0;
                    } else {
                      childAspectRatio = 2.5;
                    }
                    final spacing = isMobile ? 12.0 : 20.0;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildStatCard(
                          'TOTAL LEADS',
                          '$totalLeads',
                          Icons.people_outline,
                          '+12% vs last month',
                          true,
                        ),
                        _buildStatCard(
                          'HOT LEADS',
                          '$negotiation',
                          Icons.local_fire_department_outlined,
                          '+8% vs last month',
                          true,
                        ),
                        _buildStatCard(
                          'QUOTES PENDING',
                          '$quotationSent',
                          Icons.request_quote_outlined,
                          '-5% vs last month',
                          false,
                        ),
                        _buildStatCard(
                          'MTD REVENUE',
                          formatCurrency(totalRevenue),
                          Icons.currency_rupee,
                          '+18% vs last month',
                          true,
                        ),
                        _buildStatCard(
                          'CONVERSION RATE',
                          '${conversionRate.toStringAsFixed(0)}%',
                          Icons.track_changes,
                          '+2.1% vs last month',
                          true,
                        ),
                        _buildStatCard(
                          'AVG DEAL SIZE',
                          formatCurrency(avgDealSize),
                          Icons.insights,
                          '+5% vs last month',
                          true,
                        ),
                        _buildStatCard(
                          'OVERDUE FOLLOW-UPS',
                          '${summary.pendingTasks}',
                          Icons.access_time,
                          '-15% vs last month',
                          false,
                        ),
                        _buildStatCard(
                          'ACTIVE CAMPAIGNS',
                          '3',
                          Icons.campaign_outlined,
                          '- 0% vs last month',
                          true,
                          greyNeutral: true,
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: isMobile ? 16 : 24),

                // ── BOTTOM CHARTS ──
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 1000;
                    if (isWide) {
                      return SizedBox(
                        height: 480,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _buildLeadInflowChart(leads),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 4,
                              child: _buildConversionFunnel(
                                newLeads,
                                contacted,
                                quotationSent,
                                negotiation,
                                orderConfirmed,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Column(
                        children: [
                          SizedBox(
                            height: 480,
                            child: _buildLeadInflowChart(leads),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 480,
                            child: _buildConversionFunnel(
                              newLeads,
                              contacted,
                              quotationSent,
                              negotiation,
                              orderConfirmed,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                SizedBox(height: isMobile ? 20 : 40), // Bottom padding
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final isMobile = Responsive.isMobile(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Dashboard',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 22 : 32,
                fontWeight: FontWeight.w700,
                color: textMain,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome back, Rajesh - PackWell Industries',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textDisabled,
              ),
            ),
          ],
        ),
        if (!isMobile)
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 320,
                height: 48,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20, color: textDisabled),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search leads, quotes, dealers...',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 14,
                            color: textDisabled,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: GoogleFonts.outfit(
                          color: textMain,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 26,
                    color: textDisabled,
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: redTrend,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgColor, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryBlue,
                child: Text(
                  'RK',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    String trend,
    bool isPositive, {
    bool greyNeutral = false,
  }) {
    Color trendColor = greyNeutral
        ? textDisabled
        : (isPositive ? greenTrend : redTrend);
    IconData trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    if (greyNeutral) trendIcon = Icons.remove;

    final isMobile = Responsive.isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 14 : 20,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with TITLE and ICON
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: textDisabled,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                width: isMobile ? 36 : 44,
                height: isMobile ? 36 : 44,
                decoration: BoxDecoration(
                  color: bgLightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(icon, size: 22, color: primaryBlue)),
              ),
            ],
          ),
          const Spacer(),
          // Main Value
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 24 : 34,
                fontWeight: FontWeight.w700,
                color: textMain,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Trend Box
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: 4),
              Text(
                trend,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[(month - 1) % 12];
  }

  Widget _buildLeadInflowChart(List<Lead> leads) {
    final isMobile = Responsive.isMobile(context);
    final now = DateTime.now();
    final monthsLabels = <String>[];
    final monthlyData = <int, Map<String, int>>{};

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      monthsLabels.add(_getMonthName(monthDate.month));
      monthlyData[5 - i] = {
        'New': 0,
        'Contacted': 0,
        'Quotation Sent': 0,
        'Negotiation': 0,
        'Order Confirmed': 0,
      };
    }

    for (var lead in leads) {
      if (lead.createdAt != null) {
        final date = lead.createdAt!;
        int monthDiff = (now.year - date.year) * 12 + now.month - date.month;
        if (monthDiff >= 0 && monthDiff < 6) {
          int index = 5 - monthDiff;
          String status = lead.status;
          if (monthlyData[index]!.containsKey(status)) {
            monthlyData[index]![status] = monthlyData[index]![status]! + 1;
          }
        }
      }
    }

    double maxY = 10.0;
    for (var monthMap in monthlyData.values) {
      for (var val in monthMap.values) {
        if (val > maxY) maxY = val.toDouble() + (val * 0.2); // Add 20% headroom
      }
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Pipeline Activity',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 15 : 18,
              fontWeight: FontWeight.w700,
              color: textMain,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 40),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            value.toInt() >= 0 && value.toInt() < 6
                                ? monthsLabels[value.toInt()]
                                : '',
                            style: GoogleFonts.outfit(
                              color: textDisabled,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 9,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.outfit(
                            color: textDisabled,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
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
                  horizontalInterval: 9,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1.5,
                    dashArray: [6, 6],
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                    left: BorderSide.none,
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                barGroups: List.generate(6, (index) {
                  final data = monthlyData[index]!;
                  return _group(
                    index,
                    data['New']!.toDouble(),
                    data['Contacted']!.toDouble(),
                    data['Quotation Sent']!.toDouble(),
                    data['Negotiation']!.toDouble(),
                    data['Order Confirmed']!.toDouble(),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _group(
    int x,
    double y1,
    double y2,
    double y3,
    double y4,
    double y5,
  ) {
    BarChartRodData rod(double y, Color color) {
      return BarChartRodData(
        toY: y,
        color: color,
        width: 8, // Thinner bars to match design
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      );
    }

    return BarChartGroupData(
      x: x,
      barsSpace: 6, // Wider space between bars in a group
      barRods: [
        rod(y1, const Color(0xFF1E70F6)), // Distinct blue
        rod(y2, const Color(0xFF33B6A7)), // Teal
        rod(y3, const Color(0xFFF9A825)), // Amber/Yellow
        rod(y4, const Color(0xFFA55ECA)), // Light Purple
        rod(y5, const Color(0xFF67C26F)), // Green
      ],
    );
  }

  Widget _buildConversionFunnel(
    int newLeads,
    int contacted,
    int quoted,
    int negotiation,
    int confirmed,
  ) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversion Funnel',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textMain,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _funnelRow(
                  'New Inquiry',
                  newLeads,
                  newLeads,
                  const Color(0xFF1E70F6),
                ), // Dark Blue
                _funnelRow(
                  'Contacted',
                  contacted,
                  newLeads,
                  const Color(0xFF4B8DF8),
                ), // Light Blue
                _funnelRow(
                  'Quotation Sent',
                  quoted,
                  contacted,
                  const Color(0xFF33B6A7),
                ), // Teal
                _funnelRow(
                  'Negotiation',
                  negotiation,
                  quoted,
                  const Color(0xFFF9A825),
                ), // Amber
                _funnelRow(
                  'Order Confirmed',
                  confirmed,
                  negotiation,
                  const Color(0xFF67C26F),
                ), // Green
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _funnelRow(String title, int count, int prevCount, Color color) {
    double pctNum = prevCount == 0 ? 0 : (count / prevCount);
    if (pctNum > 1.0) pctNum = 1.0;

    bool hidePct = title == 'New Inquiry';
    String pctString = '${(pctNum * 100).toStringAsFixed(0)}%';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: textDisabled,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: textMain,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 34,
          width: double.infinity,
          decoration: BoxDecoration(
            color: hidePct ? Colors.transparent : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth * pctNum,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                },
              ),
              if (!hidePct && prevCount > 0)
                Positioned.fill(
                  child: Center(
                    child: Text(
                      pctString,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
