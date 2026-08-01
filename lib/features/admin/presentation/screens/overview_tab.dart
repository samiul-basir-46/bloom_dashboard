import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/admin_firestore_service.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final _firestoreService = AdminFirestoreService();
  bool _loadingStats = true;
  Map<String, int> _stats = {
    'totalUsers': 0,
    'totalCouples': 0,
    'pairedUsers': 0,
    'completedProfiles': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    final stats = await _firestoreService.getOverviewStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 850;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xFF7C4DFF),
      backgroundColor: const Color(0xFF14172D),
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control Center Overview',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'System-wide metrics, active relationships, and real-time operations feed',
                    style: GoogleFonts.dmSans(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: IconButton(
                  onPressed: _loadStats,
                  tooltip: 'Refresh Metrics',
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF9E77FF)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1E38),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stats Grid (Responsive: 4 columns on desktop, 2 on mobile)
          _loadingStats
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
                  ),
                )
              : GridView.count(
                  crossAxisCount: isDesktop ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 1.7 : 1.3,
                  children: [
                    _buildStatCard(
                      title: 'Total Users',
                      value: _stats['totalUsers'].toString(),
                      icon: Icons.people_alt_rounded,
                      colors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                    ),
                    _buildStatCard(
                      title: 'Active Couples',
                      value: _stats['totalCouples'].toString(),
                      icon: Icons.favorite_rounded,
                      colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                    ),
                    _buildStatCard(
                      title: 'Paired Users',
                      value: _stats['pairedUsers'].toString(),
                      icon: Icons.link_rounded,
                      colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                    ),
                    _buildStatCard(
                      title: 'Completed Profiles',
                      value: _stats['completedProfiles'].toString(),
                      icon: Icons.assignment_turned_in_rounded,
                      colors: [const Color(0xFFEC407A), const Color(0xFFC2185B)],
                    ),
                  ],
                ),
          const SizedBox(height: 36),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              Text(
                'Live System Operations Feed',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.watchSystemActivities(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha:0.3)),
                  ),
                  child: Text(
                    'Error loading live activities: ${snapshot.error}',
                    style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 13),
                  ),
                );
              }
              final activities = snapshot.data ?? [];
              if (activities.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14172D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF222644)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.history_toggle_off_rounded, color: Colors.white24, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No recent system activities found.',
                          style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final act = activities[index];
                  final userName = act['user']?.toString() ?? 'Someone';
                  final action = act['action']?.toString() ?? 'performed an action';
                  final type = act['type']?.toString() ?? '';
                  final timestamp = act['createdAt'] as Timestamp?;
                  final dateStr = timestamp != null
                      ? DateFormat('h:mm a, MMM d').format(timestamp.toDate())
                      : 'Just now';

                  IconData icon = Icons.notifications_none_outlined;
                  Color iconColor = const Color(0xFF7C4DFF);

                  if (type == 'bucket_list') {
                    icon = Icons.shopping_bag_outlined;
                    iconColor = const Color(0xFF10B981);
                  } else if (type == 'task') {
                    icon = Icons.task_alt_outlined;
                    iconColor = const Color(0xFF3B82F6);
                  } else if (type == 'anniversary' || type == 'special_day') {
                    icon = Icons.favorite_border_rounded;
                    iconColor = const Color(0xFFEC407A);
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14172D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF222644)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha:0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$userName ',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: action,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: GoogleFonts.dmSans(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> colors,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha:0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 76,
                color: Colors.white.withValues(alpha:0.14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white70, size: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
