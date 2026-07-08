import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_firestore_service.dart';
import '../../../../helpers/toast.dart';

class CouplesTab extends StatefulWidget {
  const CouplesTab({super.key});

  @override
  State<CouplesTab> createState() => _CouplesTabState();
}

class _CouplesTabState extends State<CouplesTab> {
  final _firestoreService = AdminFirestoreService();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.watchCouples(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading couples: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }
                  final couples = snapshot.data ?? [];
                  if (couples.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite_border, color: Colors.white30, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No couple configurations active',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: couples.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final couple = couples[index];
                      return CoupleCard(
                        couple: couple,
                        firestoreService: _firestoreService,
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

class CoupleCard extends StatefulWidget {
  final Map<String, dynamic> couple;
  final AdminFirestoreService firestoreService;

  const CoupleCard({
    super.key,
    required this.couple,
    required this.firestoreService,
  });

  @override
  State<CoupleCard> createState() => _CoupleCardState();
}

class _CoupleCardState extends State<CoupleCard> {
  bool _isExpanded = false;
  Map<String, dynamic>? _user1Profile;
  Map<String, dynamic>? _user2Profile;
  bool _loadingProfiles = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfiles();
  }

  Future<void> _loadUserProfiles() async {
    setState(() => _loadingProfiles = true);
    final u1 = widget.couple['user1Uid'] as String?;
    final u2 = widget.couple['user2Uid'] as String?;
    
    if (u1 != null) {
      final snap = await FirebaseFirestore.instance.collection('users').doc(u1).get();
      if (snap.exists) _user1Profile = snap.data();
    }
    if (u2 != null) {
      final snap = await FirebaseFirestore.instance.collection('users').doc(u2).get();
      if (snap.exists) _user2Profile = snap.data();
    }
    
    if (mounted) {
      setState(() => _loadingProfiles = false);
    }
  }

  void _showUnpairConfirmation(BuildContext context, String coupleId, String names) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F214A),
        title: Text(
          'Force Unpair?',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to forcibly unpair $names? This will reset their relationship link, delete their pairId references, and update their pairing statuses to unpaired.',
          style: GoogleFonts.dmSans(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.firestoreService.forceUnpair(coupleId);
                ToastUtil.showShortToast('Couple unpaired successfully.');
              } catch (e) {
                ToastUtil.showShortToast('Unpairing failed: $e');
              }
            },
            child: const Text('Unpair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coupleId = widget.couple['coupleId'] as String? ?? '';
    final isUnpaired = widget.couple['status'] == 'unpaired';
    final createdAt = widget.couple['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? DateFormat('MMM d, yyyy').format(createdAt.toDate())
        : 'N/A';

    final user1Name = _user1Profile?['name']?.toString() ?? 'Partner 1';
    final user2Name = _user2Profile?['name']?.toString() ?? 'Partner 2';
    final coupleNames = '$user1Name & $user2Name';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnpaired 
              ? Colors.redAccent.withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
          width: 1.2,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: _loadingProfiles
              ? const LinearProgressIndicator(color: Color(0xFF7C4DFF))
              : Row(
                  children: [
                    Icon(
                      isUnpaired ? Icons.heart_broken_outlined : Icons.favorite,
                      color: isUnpaired ? Colors.redAccent : const Color(0xFFEC407A),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coupleNames,
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Paired on: $dateStr',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4, left: 34),
            child: Text(
              'ID: ${coupleId.substring(0, 8)}...',
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ),
          onExpansionChanged: (val) {
            setState(() {
              _isExpanded = val;
            });
          },
          children: [
            if (_isExpanded) ...[
              const Divider(color: Colors.white10, height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Member details
                    const Text(
                      'COUPLE MEMBERS',
                      style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildMemberRow(user1Name, _user1Profile?['email']?.toString() ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildMemberRow(user2Name, _user2Profile?['email']?.toString() ?? 'N/A'),
                    const SizedBox(height: 20),

                    // Subcollection aggregates
                    const Text(
                      'SHARED CONTENTS',
                      style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCountItem(coupleId, 'tasks', Icons.task_alt, 'Tasks'),
                        _buildCountItem(coupleId, 'bucket_list', Icons.shopping_bag_outlined, 'Bucket'),
                        _buildCountItem(coupleId, 'special_days', Icons.cake_outlined, 'Special Days'),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (!isUnpaired) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.heart_broken, color: Colors.redAccent, size: 16),
                          label: Text(
                            'Forcibly Unpair Couple',
                            style: GoogleFonts.dmSans(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => _showUnpairConfirmation(context, coupleId, coupleNames),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'This couple configuration is currently inactive/unpaired.',
                            style: TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRow(String name, String email) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
        Text(email, style: const TextStyle(color: Colors.white38)),
      ],
    );
  }

  Widget _buildCountItem(String coupleId, String sub, IconData icon, String label) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.firestoreService.watchCoupleSubcollection(coupleId, sub),
      builder: (context, snapshot) {
        final countStr = snapshot.hasData ? snapshot.data!.length.toString() : '...';
        return Container(
          width: 140, // Increased size for desktop layout
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF7C4DFF), size: 20),
              const SizedBox(height: 6),
              Text(
                countStr,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}
