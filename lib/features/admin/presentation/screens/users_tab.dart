import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_firestore_service.dart';
import '../../../../helpers/toast.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final _firestoreService = AdminFirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F214A),
        title: Text(
          'Delete Account?',
          style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to permanently delete $name\'s account? This action will unpair them if paired, remove their database profile, and cannot be undone.',
          style: GoogleFonts.dmSans(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteUserAccount(uid);
                ToastUtil.showShortToast('User deleted successfully.');
              } catch (e) {
                ToastUtil.showShortToast('Failed to delete: $e');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    String uid,
    String currentName,
    String currentNickname,
    String currentBio,
    String currentGender,
    String currentRelationshipStartDate,
    String profilePic,
  ) {
    final nameCtrl = TextEditingController(text: currentName);
    final nicknameCtrl = TextEditingController(text: currentNickname);
    final bioCtrl = TextEditingController(text: currentBio);
    final dateCtrl = TextEditingController(text: currentRelationshipStartDate);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        String selectedGender = currentGender.toLowerCase();
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectDate() async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1980),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF7C4DFF),
                        onPrimary: Colors.white,
                        surface: Color(0xFF1F214A),
                        onSurface: Colors.white,
                      ),
                      dialogTheme: const DialogThemeData(
                        backgroundColor: Color(0xFF161930),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                final months = [
                  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
                ];
                setDialogState(() {
                  dateCtrl.text = "${months[picked.month - 1]} ${picked.day}, ${picked.year}";
                });
              }
            }

            return Dialog(
              backgroundColor: const Color(0xFF161930),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha:0.08)),
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dialog Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Edit User Profile',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // User Avatar
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha:0.5), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C4DFF).withValues(alpha:0.2),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: const Color(0xFF7C4DFF).withValues(alpha:0.1),
                                  backgroundImage: profilePic.isNotEmpty
                                      ? NetworkImage(profilePic)
                                      : null,
                                  child: profilePic.isEmpty
                                      ? Text(
                                          currentName.isNotEmpty ? currentName[0].toUpperCase() : 'U',
                                          style: GoogleFonts.dmSans(
                                            color: const Color(0xFF7C4DFF),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 28,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Name Field
                        TextFormField(
                          controller: nameCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: _customInputDecoration('Full Name', Icons.person_outline),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Nickname Field
                        TextFormField(
                          controller: nicknameCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: _customInputDecoration('Nickname', Icons.alternate_email_outlined),
                        ),
                        const SizedBox(height: 16),

                        // Bio Field
                        TextFormField(
                          controller: bioCtrl,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: _customInputDecoration('Bio description', Icons.info_outline),
                        ),
                        const SizedBox(height: 20),

                        // Gender Field Section
                        Text(
                          'GENDER',
                          style: GoogleFonts.dmSans(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Male Option Card
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedGender = 'male';
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: selectedGender == 'male'
                                        ? const Color(0xFF7C4DFF).withValues(alpha:0.12)
                                        : Colors.white.withValues(alpha:0.02),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedGender == 'male'
                                          ? const Color(0xFF7C4DFF)
                                          : Colors.white.withValues(alpha:0.06),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.male,
                                        color: selectedGender == 'male'
                                            ? const Color(0xFF7C4DFF)
                                            : Colors.white38,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Male',
                                        style: GoogleFonts.dmSans(
                                          color: selectedGender == 'male'
                                              ? Colors.white
                                              : Colors.white38,
                                          fontSize: 13,
                                          fontWeight: selectedGender == 'male' ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Female Option Card
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedGender = 'female';
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: selectedGender == 'female'
                                        ? const Color(0xFFEC407A).withValues(alpha:0.12)
                                        : Colors.white.withValues(alpha:0.02),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedGender == 'female'
                                          ? const Color(0xFFEC407A)
                                          : Colors.white.withValues(alpha:0.06),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.female,
                                        color: selectedGender == 'female'
                                            ? const Color(0xFFEC407A)
                                            : Colors.white38,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Female',
                                        style: GoogleFonts.dmSans(
                                          color: selectedGender == 'female'
                                              ? Colors.white
                                              : Colors.white38,
                                          fontSize: 13,
                                          fontWeight: selectedGender == 'female' ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Relationship Start Date Field
                        GestureDetector(
                          onTap: selectDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: dateCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _customInputDecoration('Relationship Start Date', Icons.calendar_today_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C4DFF), Color(0xFFEC407A)],
                                ),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;
                                  Navigator.pop(context);
                                  try {
                                    await _firestoreService.updateUserProfile(
                                      uid,
                                      name: nameCtrl.text.trim(),
                                      nickname: nicknameCtrl.text.trim(),
                                      bio: bioCtrl.text.trim(),
                                      gender: selectedGender.isNotEmpty ? selectedGender : null,
                                      relationshipStartDate: dateCtrl.text.trim().isNotEmpty ? dateCtrl.text.trim() : null,
                                    );
                                    ToastUtil.showShortToast('Profile updated successfully.');
                                  } catch (e) {
                                    ToastUtil.showShortToast('Failed to update: $e');
                                  }
                                },
                                child: Text(
                                  'Save',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white30, size: 18),
      filled: true,
      fillColor: Colors.white.withValues(alpha:0.02),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha:0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _showManualPairDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where('pairStatus', isNotEqualTo: 'paired')
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                backgroundColor: Color(0xFF1F214A),
                content: SizedBox(
                  height: 100,
                  child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF7C4DFF))),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final unpairedUsers = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'uid': doc.id,
                'name': data['name']?.toString() ?? 'No Name',
                'email': data['email']?.toString() ?? 'No Email',
              };
            }).toList();

            if (unpairedUsers.length < 2) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1F214A),
                title: Text(
                  'Cannot Pair',
                  style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  'There must be at least 2 unpaired users in the database to link a new couple.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK',
                        style: TextStyle(color: Color(0xFF7C4DFF))),
                  ),
                ],
              );
            }

            String? selectedUser1Uid;
            String? selectedUser2Uid;

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF1F214A),
                  title: Text(
                    'Manually Pair Users',
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select User 1:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF1F214A),
                        value: selectedUser1Uid,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dialogInputDecoration(),
                        items: unpairedUsers
                            .where((u) => u['uid'] != selectedUser2Uid)
                            .map((u) => DropdownMenuItem(
                                  value: u['uid'],
                                  child: Text('${u['name']} (${u['email']})',
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedUser1Uid = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Select User 2:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF1F214A),
                        value: selectedUser2Uid,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dialogInputDecoration(),
                        items: unpairedUsers
                            .where((u) => u['uid'] != selectedUser1Uid)
                            .map((u) => DropdownMenuItem(
                                  value: u['uid'],
                                  child: Text('${u['name']} (${u['email']})',
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedUser2Uid = val;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white54)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        disabledBackgroundColor: Colors.white12,
                      ),
                      onPressed: (selectedUser1Uid == null ||
                              selectedUser2Uid == null)
                          ? null
                          : () async {
                              Navigator.pop(context);
                              try {
                                await _firestoreService.manuallyPairUsers(
                                  selectedUser1Uid!,
                                  selectedUser2Uid!,
                                );
                                ToastUtil.showShortToast(
                                    'Users paired successfully.');
                              } catch (e) {
                                ToastUtil.showShortToast('Pairing failed: $e');
                              }
                            },
                      child: const Text('Pair Link'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  InputDecoration _dialogInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            // Search & Pairing Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.white54, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.white54),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFF7C4DFF), width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Manual Pair trigger button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.link, color: Colors.white, size: 18),
                    label: const Text('Pair Users',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showManualPairDialog(context),
                  ),
                ],
              ),
            ),
            // Users Stream
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.watchUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF7C4DFF)));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading users: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }
                  var users = snapshot.data ?? [];

                  // Apply search query filter
                  if (_searchQuery.isNotEmpty) {
                    users = users.where((u) {
                      final name = (u['name'] ?? '').toString().toLowerCase();
                      final email = (u['email'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) ||
                          email.contains(_searchQuery);
                    }).toList();
                  }

                  if (users.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              color: Colors.white30, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'No matching users found',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: users.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final uid = user['uid']?.toString() ?? '';
                      final name = user['name']?.toString() ?? 'No Name';
                      final email = user['email']?.toString() ?? 'No Email';
                      final nickname = user['nickname']?.toString() ?? '';
                      final bio = user['bio']?.toString() ?? '';
                      final profilePic = user['profilePicture']?.toString() ?? '';
                      final gender = user['gender']?.toString() ?? '';
                      final relationshipStartDate = user['relationshipStartDate']?.toString() ?? '';
                      final pairStatus =
                          user['pairStatus']?.toString() ?? 'none';
                      final inviteCode =
                          user['inviteCode']?.toString() ?? 'None';
                      final isBlocked = user['status'] == 'blocked';
                      final isComplete = user['profileComplete'] == true;
                      final createdAt = user['createdAt']?.toDate();
                      final dateStr = createdAt != null
                          ? DateFormat('MMM d, yyyy').format(createdAt)
                          : 'N/A';

                      // Pair Chip Style
                      Color pairChipColor = Colors.white24;
                      if (pairStatus == 'paired') {
                        pairChipColor = const Color(0xFF00E676);
                      } else if (pairStatus == 'unpaired') {
                        pairChipColor = const Color(0xFFFF3D00);
                      }

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isBlocked
                                ? Colors.redAccent.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.06),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFF7C4DFF)
                                      .withValues(alpha: 0.12),
                                  backgroundImage: profilePic.isNotEmpty
                                      ? NetworkImage(profilePic)
                                      : null,
                                  child: profilePic.isEmpty
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'U',
                                          style: GoogleFonts.dmSans(
                                            color: const Color(0xFF7C4DFF),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: GoogleFonts.dmSans(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isComplete)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  left: 8),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF7C4DFF)
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'COMPLETE',
                                                style: TextStyle(
                                                  color: Color(0xFF7C4DFF),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Action PopUp Menu
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.white54),
                                  color: const Color(0xFF1F214A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined,
                                              color: Color(0xFF7C4DFF),
                                              size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit Profile',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'block',
                                      child: Row(
                                        children: [
                                          Icon(
                                            isBlocked
                                                ? Icons.check_circle_outline
                                                : Icons.block,
                                            color: isBlocked
                                                ? const Color(0xFF00E676)
                                                : Colors.orangeAccent,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isBlocked
                                                ? 'Activate User'
                                                : 'Block User',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline,
                                              color: Colors.redAccent,
                                              size: 18),
                                          SizedBox(width: 8),
                                          Text('Delete Account',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (val) async {
                                    if (val == 'block') {
                                      try {
                                        await _firestoreService
                                            .toggleUserBlockStatus(
                                                uid, !isBlocked);
                                        ToastUtil.showShortToast(
                                          isBlocked
                                              ? 'User activated successfully.'
                                              : 'User blocked successfully.',
                                        );
                                      } catch (e) {
                                        ToastUtil.showShortToast('Error: $e');
                                      }
                                    } else if (val == 'delete') {
                                      _showDeleteConfirmation(
                                          context, uid, name);
                                    } else if (val == 'edit') {
                                      _showEditProfileDialog(
                                          context, uid, name, nickname, bio, gender, relationshipStartDate, profilePic);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildCardMetaItem('NICKNAME', nickname.isNotEmpty ? nickname : 'None yet'),
                                _buildCardMetaItem('GENDER', gender.isNotEmpty ? gender.toUpperCase() : 'N/A'),
                                _buildCardMetaItem('RELATIONSHIP START', relationshipStartDate.isNotEmpty ? relationshipStartDate : 'N/A'),
                                _buildCardMetaItem('INVITE CODE', inviteCode),
                                _buildCardMetaItem('REGISTERED', dateStr),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        pairChipColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    pairStatus.toUpperCase(),
                                    style: GoogleFonts.dmSans(
                                      color: pairChipColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (isBlocked) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      'BLOCKED',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
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

  Widget _buildCardMetaItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
