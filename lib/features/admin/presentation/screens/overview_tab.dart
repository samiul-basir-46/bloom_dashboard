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
    final isDesktop = screenWidth > 768;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xFF7C4DFF),
      backgroundColor: const Color(0xFF161930),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Control Center Overview',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'System-wide metrics and real-time operations feed',
            style: GoogleFonts.dmSans(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          // Stats Grid (Responsive: 4 columns on desktop, 2 on mobile)
          _loadingStats
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
              : GridView.count(
                  crossAxisCount: isDesktop ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 1.6 : 1.3,
                  children: [
                    _buildStatCard(
                      title: 'Total Users',
                      value: _stats['totalUsers'].toString(),
                      icon: Icons.people_outline,
                      colors: [const Color(0xFF7C4DFF), const Color(0xFF9E00FF)],
                    ),
                    _buildStatCard(
                      title: 'Active Couples',
                      value: _stats['totalCouples'].toString(),
                      icon: Icons.favorite_border,
                      colors: [const Color(0xFF00E676), const Color(0xFF00B0FF)],
                    ),
                    _buildStatCard(
                      title: 'Paired Users',
                      value: _stats['pairedUsers'].toString(),
                      icon: Icons.link,
                      colors: [const Color(0xFFFF3D00), const Color(0xFFFF9100)],
                    ),
                    _buildStatCard(
                      title: 'Completed Profiles',
                      value: _stats['completedProfiles'].toString(),
                      icon: Icons.assignment_turned_in_outlined,
                      colors: [const Color(0xFFEC407A), const Color(0xFFAB47BC)],
                    ),
                  ],
                ),
          const SizedBox(height: 32),
          Text(
            'Live Activity Feed',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
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
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Error loading activities: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }
              final activities = snapshot.data ?? [];
              if (activities.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.history, color: Colors.white30, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No recent system activities found.',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
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
                    iconColor = const Color(0xFF00E676);
                  } else if (type == 'task') {
                    icon = Icons.task_alt_outlined;
                    iconColor = const Color(0xFF00B0FF);
                  } else if (type == 'anniversary' || type == 'special_day') {
                    icon = Icons.favorite_border;
                    iconColor = const Color(0xFFEC407A);
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.12),
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
                              const SizedBox(height: 6),
                              Text(
                                dateStr,
                                style: const TextStyle(
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 4),
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
              size: 72,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
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
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
