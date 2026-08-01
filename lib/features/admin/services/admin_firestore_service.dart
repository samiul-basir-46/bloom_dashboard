import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Statistics & Overview ---

  Future<Map<String, int>> getOverviewStats() async {
    try {
      final usersSnap = await _firestore.collection('users').get();
      final couplesSnap = await _firestore.collection('couples').get();
      
      int totalUsers = usersSnap.docs.length;
      int totalCouples = couplesSnap.docs.length;
      
      int pairedUsers = usersSnap.docs
          .where((doc) => doc.data()['pairStatus'] == 'paired')
          .length;
          
      int completedProfiles = usersSnap.docs
          .where((doc) => doc.data()['profileComplete'] == true)
          .length;

      return {
        'totalUsers': totalUsers,
        'totalCouples': totalCouples,
        'pairedUsers': pairedUsers,
        'completedProfiles': completedProfiles,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'totalCouples': 0,
        'pairedUsers': 0,
        'completedProfiles': 0,
      };
    }
  }

  // Activity Feed (System-wide moments group query)
  Stream<List<Map<String, dynamic>>> watchSystemActivities() {
    return _firestore
        .collectionGroup('moments')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              data['path'] = doc.reference.path;
              return data;
            }).toList())
        .handleError((error) {
          return <Map<String, dynamic>>[];
        });
  }

  // --- Users Management ---

  Stream<List<Map<String, dynamic>>> watchUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['uid'] = doc.id;
              return data;
            }).toList())
        .handleError((error) {
          return <Map<String, dynamic>>[];
        });
  }

  Future<void> toggleUserBlockStatus(String uid, bool isBlocked) async {
    await _firestore.collection('users').doc(uid).set({
      'status': isBlocked ? 'blocked' : 'active',
    }, SetOptions(merge: true));
  }

  Future<void> deleteUserAccount(String uid) async {
    // Check if user is paired, if so, unpair first
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null) {
        final pairStatus = userData['pairStatus'] as String? ?? 'none';
        final pairId = userData['pairId'] as String?;
        if (pairStatus == 'paired' && pairId != null) {
          await forceUnpair(pairId);
        }
      }
    }
    // Delete user doc
    await _firestore.collection('users').doc(uid).delete();
  }

  Future<void> updateUserProfile(
    String uid, {
    required String name,
    required String nickname,
    required String bio,
    String? gender,
    String? relationshipStartDate,
  }) async {
    final updates = <String, dynamic>{
      'name': name,
      'nickname': nickname,
      'bio': bio,
    };
    if (gender != null) updates['gender'] = gender;
    if (relationshipStartDate != null) updates['relationshipStartDate'] = relationshipStartDate;

    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), updates);

    if (relationshipStartDate != null) {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          final isPaired = userData['pairStatus'] == 'paired';
          final pairId = userData['pairId'] as String?;
          if (isPaired && pairId != null) {
            final coupleDoc = await _firestore.collection('couples').doc(pairId).get();
            if (coupleDoc.exists && coupleDoc.data() != null) {
              final coupleData = coupleDoc.data()!;
              final u1 = coupleData['user1Uid'] as String?;
              final u2 = coupleData['user2Uid'] as String?;
              final partnerUid = u1 == uid ? u2 : u2 == uid ? u1 : null;
              if (partnerUid != null && partnerUid.isNotEmpty) {
                batch.update(_firestore.collection('users').doc(partnerUid), {
                  'relationshipStartDate': relationshipStartDate,
                });
              }
            }
          }
        }
      }
    }
    await batch.commit();
  }

  Future<void> manuallyPairUsers(String user1Uid, String user2Uid) async {
    final coupleId = '${user1Uid}_$user2Uid';
    final batch = _firestore.batch();

    // 1. Create/update couple document
    final coupleRef = _firestore.collection('couples').doc(coupleId);
    batch.set(coupleRef, {
      'user1Uid': user1Uid,
      'user2Uid': user2Uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    }, SetOptions(merge: true));

    // 2. Update user 1 profile
    final u1Ref = _firestore.collection('users').doc(user1Uid);
    batch.update(u1Ref, {
      'pairId': coupleId,
      'pairStatus': 'paired',
    });

    // 3. Update user 2 profile
    final u2Ref = _firestore.collection('users').doc(user2Uid);
    batch.update(u2Ref, {
      'pairId': coupleId,
      'pairStatus': 'paired',
    });

    await batch.commit();
  }

  // --- Couples Management ---

  Stream<List<Map<String, dynamic>>> watchCouples() {
    return _firestore
        .collection('couples')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['coupleId'] = doc.id;
              return data;
            }).toList())
        .handleError((error) {
          return <Map<String, dynamic>>[];
        });
  }

  // Fetch full details of a couple (combines partner names)
  Future<Map<String, dynamic>?> getCoupleDetails(String coupleId) async {
    final doc = await _firestore.collection('couples').doc(coupleId).get();
    if (!doc.exists) return null;
    
    final data = doc.data()!;
    data['coupleId'] = doc.id;
    
    // Resolve partner details
    final u1 = data['user1Uid'] as String?;
    final u2 = data['user2Uid'] as String?;
    
    if (u1 != null) {
      final u1Doc = await _firestore.collection('users').doc(u1).get();
      if (u1Doc.exists) data['user1'] = u1Doc.data();
    }
    if (u2 != null) {
      final u2Doc = await _firestore.collection('users').doc(u2).get();
      if (u2Doc.exists) data['user2'] = u2Doc.data();
    }
    
    return data;
  }

  // Stream subcollection of couple
  Stream<List<Map<String, dynamic>>> watchCoupleSubcollection(
      String coupleId, String subcollection) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection(subcollection)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList())
        .handleError((error) {
          return <Map<String, dynamic>>[];
        });
  }

  // Force unpair a couple
  Future<void> forceUnpair(String coupleId) async {
    final coupleRef = _firestore.collection('couples').doc(coupleId);
    final coupleDoc = await coupleRef.get();
    if (!coupleDoc.exists) return;

    final data = coupleDoc.data()!;
    final u1 = data['user1Uid'] as String?;
    final u2 = data['user2Uid'] as String?;

    final batch = _firestore.batch();

    // Reset user 1
    if (u1 != null && u1.isNotEmpty) {
      batch.set(_firestore.collection('users').doc(u1), {
        'pairStatus': 'unpaired',
        'pairId': FieldValue.delete(),
      }, SetOptions(merge: true));
    }

    // Reset user 2
    if (u2 != null && u2.isNotEmpty) {
      batch.set(_firestore.collection('users').doc(u2), {
        'pairStatus': 'unpaired',
        'pairId': FieldValue.delete(),
      }, SetOptions(merge: true));
    }

    // Update couple doc
    batch.update(coupleRef, {'status': 'unpaired'});

    await batch.commit();
  }

  // --- Trivia Management ---

  Stream<List<Map<String, dynamic>>> watchGlobalTrivia() {
    return _firestore
        .collection('global_trivia')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList())
        .handleError((error) {
          return <Map<String, dynamic>>[];
        });
  }

  Future<void> addGlobalTrivia(String dateYmd, String question) async {
    // 1. Write to global trivia collection
    await _firestore.collection('global_trivia').doc(dateYmd).set({
      'date': dateYmd,
      'question': question,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Propagate to active couples' daily trivia if they don't have answers yet
    final couplesSnap = await _firestore.collection('couples').get();
    final batch = _firestore.batch();
    for (final doc in couplesSnap.docs) {
      final status = doc.data()['status'] as String? ?? 'active';
      if (status != 'unpaired') {
        final triviaRef = doc.reference.collection('trivia').doc(dateYmd);
        // Only set if not already answered/configured
        batch.set(triviaRef, {
          'question': question,
        }, SetOptions(merge: true));
      }
    }
    await batch.commit();
  }

  // --- Announcements / System Broadcast ---

  Future<void> sendBroadcastAnnouncement(String title, String body) async {
    await _firestore.collection('announcements').add({
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Support Chats Management ---

  Stream<List<Map<String, dynamic>>> watchSupportChats() {
    return _firestore
        .collection('support_chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['chatId'] = doc.id;
              return data;
            }).toList())
        .handleError((error) {
          return <Map<String, dynamic>>[];
        });
  }

  Stream<List<Map<String, dynamic>>> watchSupportMessages(String chatId) {
    return _firestore
        .collection('support_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList())
        .handleError((error) {
          return <Map<String, dynamic>>[];
        });
  }

  Future<void> sendSupportMessage(String chatId, String text) async {
    final messageRef = _firestore
        .collection('support_chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final batch = _firestore.batch();
    
    batch.set(messageRef, {
      'senderId': 'admin',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.update(_firestore.collection('support_chats').doc(chatId), {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadByUser': true,
      'unreadByAdmin': false,
    });

    await batch.commit();
  }

  Future<void> markSupportChatAsRead(String chatId) async {
    await _firestore.collection('support_chats').doc(chatId).update({
      'unreadByAdmin': false,
    });
  }
}
