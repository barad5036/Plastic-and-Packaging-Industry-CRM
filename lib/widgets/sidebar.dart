import 'package:crm/core/providers/auth_provider.dart';
import 'package:crm/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.sidebarBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Logo Area
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'SalesHub',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Navigation Items
          _buildNavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.list_alt,
            label: 'Leads',
            index: 1,
            badge: 'New',
          ),
          _buildNavItem(
            icon: Icons.receipt_long_outlined,
            label: 'Quotation',
            index: 2,
          ),
          _buildNavItem(
            icon: Icons.storefront_outlined,
            label: 'Dealers',
            index: 3,
          ),
          _buildNavItem(
            icon: Icons.analytics_outlined,
            label: 'Reports',
            index: 4,
          ),
          _buildNavItem(
            icon: Icons.view_kanban_outlined,
            label: 'Pipeline',
            index: 5,
          ),
          _buildNavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            index: 6,
          ),

          const Spacer(),
          // Logout / user profile section
          const Divider(color: AppColors.divider),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final displayName =
                  auth.userName ?? auth.userEmail?.split('@').first ?? 'User';
              final initials = displayName.length >= 2
                  ? displayName.substring(0, 2).toUpperCase()
                  : displayName.toUpperCase();
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.darkAccent,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => auth.logout(),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.logout,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    String? badge,
  }) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.background : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.textMain : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textMain
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
