import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MilestonesTab extends StatefulWidget {
  const MilestonesTab({super.key});

  @override
  State<MilestonesTab> createState() => _MilestonesTabState();
}

class _MilestonesTabState extends State<MilestonesTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Relationship Milestones',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Monitor couple profiles, relationship durations, and upcoming anniversaries',
                    style: GoogleFonts.dmSans(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('couples')
                    .where('status', isNotEqualTo: 'unpaired')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading milestones: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }
                  final couples = snapshot.data?.docs ?? [];
                  if (couples.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(Icons.favorite_border, color: Colors.white30, size: 48),
                           SizedBox(height: 12),
                          Text(
                            'No active couples found',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: couples.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final doc = couples[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return MilestoneCoupleCard(
                        coupleId: doc.id,
                        data: data,
                        firestore: _firestore,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MilestoneCoupleCard extends StatefulWidget {
  final String coupleId;
  final Map<String, dynamic> data;
  final FirebaseFirestore firestore;

  const MilestoneCoupleCard({
    super.key,
    required this.coupleId,
    required this.data,
    required this.firestore,
  });

  @override
  State<MilestoneCoupleCard> createState() => _MilstoneCoupleCardState();
}

class _MilstoneCoupleCardState extends State<MilestoneCoupleCard> {
  Map<String, dynamic>? _user1Profile;
  Map<String, dynamic>? _user2Profile;
  bool _loadingProfiles = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfiles();
  }

  Future<void> _loadUserProfiles() async {
    final u1 = widget.data['user1Uid'] as String?;
    final u2 = widget.data['user2Uid'] as String?;
    
    if (u1 != null) {
      final snap = await widget.firestore.collection('users').doc(u1).get();
      if (snap.exists) _user1Profile = snap.data();
    }
    if (u2 != null) {
      final snap = await widget.firestore.collection('users').doc(u2).get();
      if (snap.exists) _user2Profile = snap.data();
    }

    if (mounted) {
      setState(() {
        _loadingProfiles = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfiles) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: LinearProgressIndicator(color: Color(0xFF7C4DFF))),
      );
    }

    // Dynamic relationship duration calculation
    final createdAt = widget.data['createdAt'] as Timestamp?;
    int daysTogether = 0;
    String dateStr = 'N/A';
    if (createdAt != null) {
      final createdDate = createdAt.toDate();
      daysTogether = DateTime.now().difference(createdDate).inDays;
      dateStr = DateFormat('MMMM d, yyyy').format(createdDate);
    }

    final user1Name = _user1Profile?['name']?.toString() ?? 'Partner 1';
    final user2Name = _user2Profile?['name']?.toString() ?? 'Partner 2';
    final user1Bio = _user1Profile?['bio']?.toString() ?? 'No bio';
    final user2Bio = _user2Profile?['bio']?.toString() ?? 'No bio';
    final user1Pic = _user1Profile?['profilePicture']?.toString() ?? '';
    final user2Pic = _user2Profile?['profilePicture']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partners header with avatars
          Row(
            children: [
              _buildPartnerAvatar(user1Name, user1Pic),
              const SizedBox(width: 8),
              const Icon(Icons.favorite, color: Color(0xFFEC407A), size: 20),
              const SizedBox(width: 8),
              _buildPartnerAvatar(user2Name, user2Pic),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$user1Name & $user2Name',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Anniversary Start: $dateStr',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Relationship Duration Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFFEC407A)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alarm, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$daysTogether Days Together',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          
          // Partner details bios
          Row(
            children: [
              Expanded(
                child: _buildPartnerDetailPanel(user1Name, _user1Profile?['email']?.toString() ?? 'N/A', user1Bio),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildPartnerDetailPanel(user2Name, _user2Profile?['email']?.toString() ?? 'N/A', user2Bio),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text(
            'UPCOMING SPECIAL DAYS & CELEBRATIONS',
            style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Stream special days list
          StreamBuilder<QuerySnapshot>(
            stream: widget.firestore
                .collection('couples')
                .doc(widget.coupleId)
                .collection('special_days')
                .orderBy('date', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 40,
                  child: Center(child: LinearProgressIndicator(color: Color(0xFF7C4DFF))),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.01),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No special days registered by this couple.',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final dayDoc = docs[index];
                    final dayData = dayDoc.data() as Map<String, dynamic>;
                    final title = dayData['title']?.toString() ?? 'Celebration';
                    final description = dayData['description']?.toString() ?? '';
                    final dayDateStamp = dayData['date'] as Timestamp?;
                    
                    String dayDateStr = 'N/A';
                    if (dayDateStamp != null) {
                      dayDateStr = DateFormat('MMM d, yyyy').format(dayDateStamp.toDate());
                    }

                    return Container(
                      width: 220,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cake, color: Color(0xFF00E676), size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  title,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayDateStr,
                            style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          if (description.isNotEmpty)
                            Text(
                              description,
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerAvatar(String name, String picUrl) {
    if (picUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(picUrl),
        backgroundColor: Colors.transparent,
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildPartnerDetailPanel(String name, String email, String bio) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            email,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            bio.isNotEmpty ? bio : 'No profile bio configured.',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
