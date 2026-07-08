import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_auth_service.dart';
import '../../../../helpers/toast.dart';

import 'overview_tab.dart';
import 'users_tab.dart';
import 'couples_tab.dart';
import 'trivia_tab.dart';
import 'milestones_tab.dart';

class DashboardShellScreen extends StatefulWidget {
  const DashboardShellScreen({super.key});

  @override
  State<DashboardShellScreen> createState() => _DashboardShellScreenState();
}

class _DashboardShellScreenState extends State<DashboardShellScreen> {
  int _currentTabIndex = 0;
  final _authService = AdminAuthService();

  final List<Widget> _tabs = const [
    OverviewTab(),
    UsersTab(),
    CouplesTab(),
    TriviaTab(),
    MilestonesTab(),
  ];

  final List<String> _tabTitles = const [
    'Overview',
    'Users',
    'Couples',
    'Trivia',
    'Milestones',
  ];

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      ToastUtil.showShortToast('Logged out successfully.');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/adminLogin');
      }
    } catch (e) {
      ToastUtil.showShortToast('Logout failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768; // standard desktop threshold

    return Scaffold(
      backgroundColor: const Color(0xFF0F1026),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161930),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Color(0xFF7C4DFF), size: 24),
            const SizedBox(width: 10),
            Text(
              'Bloom Control Panel - ${_tabTitles[_currentTabIndex]}',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1F214A),
                  title: Text(
                    'Sign Out?',
                    style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Are you sure you want to end your administrator session?',
                    style: GoogleFonts.dmSans(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () {
                        Navigator.pop(context);
                        _handleSignOut();
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Desktop Navigation Sidebar
          if (isDesktop) _buildSidebar(),
          // Main Screen Content
          Expanded(
            child: Container(
              color: const Color(0xFF0F1026),
              child: _tabs[_currentTabIndex],
            ),
          ),
        ],
      ),
      // Mobile Navigation Bottom Bar
      bottomNavigationBar: !isDesktop ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240, // Standard web sidebar width
      color: const Color(0xFF161930),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSidebarItem(index: 0, icon: Icons.dashboard_outlined, label: 'Overview'),
          _buildSidebarItem(index: 1, icon: Icons.people_outline, label: 'Users'),
          _buildSidebarItem(index: 2, icon: Icons.favorite_border, label: 'Couples'),
          _buildSidebarItem(index: 3, icon: Icons.quiz_outlined, label: 'Trivia'),
          _buildSidebarItem(index: 4, icon: Icons.star_outline, label: 'Milestones'),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                Divider(color: Colors.white10),
                SizedBox(height: 8),
                Text(
                  'v1.0.0 (Alpha)',
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C4DFF).withOpacity(0.08) : Colors.transparent,
          border: isSelected
              ? const Border(left: BorderSide(color: Color(0xFF7C4DFF), width: 4))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF7C4DFF) : Colors.white60,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (index) => setState(() => _currentTabIndex = index),
      backgroundColor: const Color(0xFF161930),
      selectedItemColor: const Color(0xFF7C4DFF),
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedLabelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold),
      unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined, size: 20),
          label: 'Overview',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline, size: 20),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border, size: 20),
          label: 'Couples',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz_outlined, size: 20),
          label: 'Trivia',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star_outline, size: 20),
          label: 'Milestones',
        ),
      ],
    );
  }
}
