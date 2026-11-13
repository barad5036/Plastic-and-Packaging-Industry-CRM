import 'package:crm/core/network/api_client.dart';
import 'package:crm/core/providers/auth_provider.dart';
import 'package:crm/core/theme/app_theme.dart';
import 'package:crm/screens/analytics/analytics_screen.dart';
import 'package:crm/screens/dashboard/dashboard_screen.dart';
import 'package:crm/screens/dealers/dealers_screen.dart';
import 'package:crm/screens/leads/leads_screen.dart';
import 'package:crm/screens/leads/pipeline_screen.dart';
import 'package:crm/screens/quotes/quotes_screen.dart';
import 'package:crm/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  int _getBottomNavIndex() {
    switch (_selectedIndex) {
      case 0:
        return 0; // Dashboard
      case 1:
        return 1; // Leads
      case 5:
        return 2; // Pipeline
      case 2:
        return 3; // Quotation
      default:
        return 4; // More
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == 4) {
      _scaffoldKey.currentState?.openDrawer();
    } else {
      setState(() {
        switch (index) {
          case 0:
            _selectedIndex = 0;
            break; // Dashboard
          case 1:
            _selectedIndex = 1;
            break; // Leads
          case 2:
            _selectedIndex = 5;
            break; // Pipeline
          case 3:
            _selectedIndex = 2;
            break; // Quotation
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          key: _scaffoldKey,
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text('SalesHub'),
                  iconTheme: const IconThemeData(color: AppColors.textMain),
                  backgroundColor: AppColors.sidebarBackground,
                ),
          drawer: isDesktop
              ? null
              : Drawer(
                  child: Sidebar(
                    selectedIndex: _selectedIndex,
                    onItemSelected: (index) {
                      _onItemSelected(index);
                      Navigator.pop(context); // Close drawer after selection
                    },
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onItemSelected,
                ),
              Expanded(child: _buildBody()),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10,
                      ),
                      child: GNav(
                        gap: 8,
                        activeColor: Colors.white,
                        iconSize: 20,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        duration: const Duration(milliseconds: 400),
                        tabBackgroundColor: AppColors.darkAccent,
                        tabBorderRadius: 14,
                        color: AppColors.textSecondary,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        tabs: const [
                          GButton(
                            icon: Icons.dashboard_rounded,
                            text: 'Home',
                            iconActiveColor: Colors.white,
                          ),
                          GButton(
                            icon: Icons.people_alt_rounded,
                            text: 'Leads',
                            iconActiveColor: Colors.white,
                          ),
                          GButton(
                            icon: Icons.view_kanban_rounded,
                            text: 'Pipeline',
                            iconActiveColor: Colors.white,
                          ),
                          GButton(
                            icon: Icons.receipt_long_rounded,
                            text: 'Quotes',
                            iconActiveColor: Colors.white,
                          ),
                          GButton(
                            icon: Icons.menu_rounded,
                            text: 'More',
                            iconActiveColor: Colors.white,
                          ),
                        ],
                        selectedIndex: _getBottomNavIndex(),
                        onTabChange: _onBottomNavTapped,
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const LeadsScreen();
      case 2:
        return const QuotationsScreen();
      case 3:
        return const DealersScreen();
      case 4:
        return const AnalyticsScreen();
      case 5:
        return const PipelineScreen();
      case 6:
        return _buildSettingsPlaceholder();
      default:
        return const Center(child: Text('Under Construction'));
    }
  }

  Widget _buildSettingsPlaceholder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your account and system preferences.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Builder(
            builder: (context) {
              final auth = context.watch<AuthProvider>();
              return _settingsCard('Profile', Icons.person_outline, [
                _settingsRow('Full Name', auth.userName ?? 'N/A'),
                _settingsRow('Email', auth.userEmail ?? 'N/A'),
                _settingsRow('Role', 'Admin'),
              ]);
            },
          ),
          const SizedBox(height: 20),
          _settingsCard('System', Icons.tune_outlined, [
            _settingsRow('App Version', 'v1.0.0'),
            _settingsRow('Backend', ApiClient.baseUrl),
            _settingsRow('Database', 'PostgreSQL'),
          ]),
          const SizedBox(height: 20),
          _settingsCard('Danger Zone', Icons.warning_amber_outlined, [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear all data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.alert,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _settingsCard(String title, IconData icon, List<Widget> children) {
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _settingsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }
}
