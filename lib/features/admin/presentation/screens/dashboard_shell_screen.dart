import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_auth_service.dart';
import '../../../../helpers/toast.dart';

import 'overview_tab.dart';
import 'users_tab.dart';
import 'couples_tab.dart';
import 'trivia_tab.dart';
import 'milestones_tab.dart';
import 'support_tab.dart';

class DashboardShellScreen extends StatefulWidget {
  const DashboardShellScreen({super.key});

  @override
  State<DashboardShellScreen> createState() => _DashboardShellScreenState();
}

class _DashboardShellScreenState extends State<DashboardShellScreen> {
  int _currentTabIndex = 0;
  bool _isSidebarCollapsed = false;
  final _authService = AdminAuthService();
  final TextEditingController _searchController = TextEditingController();

  final List<Widget> _tabs = const [
    OverviewTab(),
    UsersTab(),
    CouplesTab(),
    TriviaTab(),
    MilestonesTab(),
    SupportTab(),
  ];

  final List<String> _tabTitles = const [
    'Overview',
    'Users',
    'Couples',
    'Trivia',
    'Milestones',
    'Support',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      ToastUtil.showSuccessToast('Logged out successfully from Bloom Admin.');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/adminLogin');
      }
    } catch (e) {
      ToastUtil.showErrorToast('Logout failed: $e');
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2E325A)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirm Sign Out',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to terminate your administrative control session?',
          style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: Colors.white54),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _handleSignOut();
              },
              child: Text(
                'Logout Session',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 850;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1D),
      drawer: !isDesktop ? _buildDrawer() : null,
      body: SafeArea(
        child: Row(
          children: [
            // Desktop Left Navigation Sidebar
            if (isDesktop) _buildDesktopSidebar(),
            // Main Web Right Column (Top Bar + Main Tab Content)
            Expanded(
              child: Column(
                children: [
                  _buildWebTopHeader(isDesktop),
                  Expanded(
                    child: Container(
                      color: const Color(0xFF0D0F1D),
                      child: _tabs[_currentTabIndex],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Web Top Bar Navigation Header
  Widget _buildWebTopHeader(bool isDesktop) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF14172D),
        border: Border(
          bottom: BorderSide(color: Color(0xFF222644), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          // Page Breadcrumb Title
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Bloom Control',
                    style: GoogleFonts.dmSans(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right, color: Colors.white24, size: 14),
                  ),
                  Text(
                    _tabTitles[_currentTabIndex],
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF9E77FF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _tabTitles[_currentTabIndex],
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // System Status Chip
          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Systems Active',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Global Search Input
          if (isDesktop)
            Container(
              width: 260,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1E38),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2C3056)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white38, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search workspace...',
                        hintStyle: GoogleFonts.dmSans(color: Colors.white30, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 16),
          // Notifications Bell Icon
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                ToastUtil.showInfoToast('No new unread system alerts.');
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1E38),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2C3056)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 20),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C4DFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Admin Profile Pill
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _showLogoutConfirmation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1E38),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2C3056)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'AD',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Administrator',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Super Admin',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF7C4DFF),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.logout_rounded, color: Colors.white38, size: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Left Sidebar Navigation Component
  Widget _buildDesktopSidebar() {
    final width = _isSidebarCollapsed ? 76.0 : 250.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFF14172D),
        border: Border(
          right: BorderSide(color: Color(0xFF222644), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Sidebar Logo Header
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 16 : 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF222644), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF6200EA)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bloom Control',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Web Dashboard',
                          style: GoogleFonts.dmSans(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Navigation Menu Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSectionHeader('MAIN'),
                _buildSidebarMenuItem(index: 0, icon: Icons.grid_view_rounded, label: 'Overview'),
                const SizedBox(height: 12),
                _buildSectionHeader('MANAGEMENT'),
                _buildSidebarMenuItem(index: 1, icon: Icons.people_alt_outlined, label: 'Users'),
                _buildSidebarMenuItem(index: 2, icon: Icons.favorite_border_rounded, label: 'Couples'),
                const SizedBox(height: 12),
                _buildSectionHeader('ENGAGEMENT'),
                _buildSidebarMenuItem(index: 3, icon: Icons.extension_outlined, label: 'Trivia'),
                _buildSidebarMenuItem(index: 4, icon: Icons.workspace_premium_outlined, label: 'Milestones'),
                const SizedBox(height: 12),
                _buildSectionHeader('SUPPORT'),
                _buildSidebarMenuItem(index: 5, icon: Icons.headset_mic_outlined, label: 'Support'),
              ],
            ),
          ),
          // Sidebar Footer Toggle Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF222644), width: 1)),
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isSidebarCollapsed = !_isSidebarCollapsed;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_isSidebarCollapsed)
                        Text(
                          'v1.0.0 Pro',
                          style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12),
                        ),
                      Icon(
                        _isSidebarCollapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left,
                        color: Colors.white60,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    if (_isSidebarCollapsed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.dmSans(
          color: Colors.white24,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSidebarMenuItem({
    required int index,
    required IconData icon,
    required String label,
    bool isDrawer = false,
  }) {
    final isSelected = _currentTabIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() => _currentTabIndex = index);
            if (isDrawer) {
              Navigator.pop(context);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed && !isDrawer ? 16 : 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF7C4DFF).withOpacity(0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.4), width: 1)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: _isSidebarCollapsed && !isDrawer ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF9E77FF) : Colors.white54,
                  size: 20,
                ),
                if (!_isSidebarCollapsed || isDrawer) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF14172D),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Bloom Control',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarMenuItem(index: 0, icon: Icons.grid_view_rounded, label: 'Overview', isDrawer: true),
                _buildSidebarMenuItem(index: 1, icon: Icons.people_alt_outlined, label: 'Users', isDrawer: true),
                _buildSidebarMenuItem(index: 2, icon: Icons.favorite_border_rounded, label: 'Couples', isDrawer: true),
                _buildSidebarMenuItem(index: 3, icon: Icons.extension_outlined, label: 'Trivia', isDrawer: true),
                _buildSidebarMenuItem(index: 4, icon: Icons.workspace_premium_outlined, label: 'Milestones', isDrawer: true),
                _buildSidebarMenuItem(index: 5, icon: Icons.headset_mic_outlined, label: 'Support', isDrawer: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.2),
                foregroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
              onPressed: () {
                Navigator.pop(context);
                _showLogoutConfirmation();
              },
            ),
          ),
        ],
      ),
    );
  }
}
