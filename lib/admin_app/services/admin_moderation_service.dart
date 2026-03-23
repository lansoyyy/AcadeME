import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_auth_service.dart';

class AdminModerationResult {
  const AdminModerationResult({required this.message, this.payload = const {}});

  final String message;
  final Map<String, dynamic> payload;

  factory AdminModerationResult.fromMap(Map<String, dynamic> data) {
    return AdminModerationResult(
      message: data['message'] as String? ?? 'Action completed successfully.',
      payload: Map<String, dynamic>.from(data),
    );
  }
}

class AdminModerationService {
  AdminModerationService({FirebaseFirestore? firestore})
  : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
    _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
    _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> get _reportsRef =>
    _firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> get _ratingsRef =>
    _firestore.collection('ratings');

  CollectionReference<Map<String, dynamic>> get _matchesRef =>
    _firestore.collection('matches');

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
    _firestore.collection('conversations');

  CollectionReference<Map<String, dynamic>> get _studyGroupsRef =>
    _firestore.collection('studyGroups');

  CollectionReference<Map<String, dynamic>> get _studySessionsRef =>
    _firestore.collection('studySessions');

  CollectionReference<Map<String, dynamic>> get _forumPostsRef =>
    _firestore.collection('forumPosts');

  CollectionReference<Map<String, dynamic>> get _adminActionsRef =>
    _firestore.collection('adminActions');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamStudyGroups() {
    return _firestore.collection('studyGroups').snapshots();
  }

  Future<AdminModerationResult> deleteUserAccount({
    required String uid,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw ArgumentError('A deletion reason is required.');
    }

    final userRef = _usersRef.doc(uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      throw Exception('User not found.');
    }

    final userData = userDoc.data() ?? const <String, dynamic>{};
    final userName = userData['fullName'] as String? ?? uid;

    final deletedNotifications = await _deleteQueryDocs(
      _notificationsRef.where('uid', isEqualTo: uid),
    );
    final deletedReports =
        await _deleteQueryDocs(_reportsRef.where('reporterUid', isEqualTo: uid)) +
        await _deleteQueryDocs(_reportsRef.where('reportedUid', isEqualTo: uid));
    final deletedRatings =
        await _deleteQueryDocs(_ratingsRef.where('ratedUid', isEqualTo: uid)) +
        await _deleteQueryDocs(_ratingsRef.where('raterUid', isEqualTo: uid));
    final deletedSessions =
        await _deleteQueryDocs(_studySessionsRef.where('hostUid', isEqualTo: uid)) +
        await _deleteQueryDocs(_studySessionsRef.where('guestUid', isEqualTo: uid));
    final deletedMatches = await _deleteQueryDocs(
      _matchesRef.where('users', arrayContains: uid),
    );
    final deletedConversations = await _deleteUserConversations(uid);
    final studyGroupCleanup = await _cleanUpStudyGroupsForUser(uid, trimmedReason);
    final deletedForumPosts = await _deleteForumPostsByAuthor(uid);
    final deletedForumComments = await _deleteQueryDocs(
      _firestore.collectionGroup('comments').where('authorUid', isEqualTo: uid),
    );
    final deletedUserSubcollections = await _deleteUserSubcollections(uid);

    await userRef.set({
      'fullName': 'Deleted Account',
      'studentId': '',
      'birthday': '',
      'age': 0,
      'photoUrl': '',
      'track': '',
      'gradeLevel': 0,
      'subjectsInterested': <String>[],
      'studyGoals': <String>[],
      'bio': '',
      'availability': <String, dynamic>{},
      'location': <String, dynamic>{},
      'matchPreferences': <String, dynamic>{},
      'isDiscoverable': false,
      'isActive': false,
      'accountStatus': 'deleted',
      'deletionReason': trimmedReason,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: false));

    await _logAdminAction(
      action: 'delete_user_account',
      details:
          'Deleted Firestore data for $userName ($uid). Reason: $trimmedReason',
    );

    return AdminModerationResult(
      message:
          'Deleted app data for $userName and blocked future app sign-ins for this account.',
      payload: {
        'uid': uid,
        'reason': trimmedReason,
        'deletedNotifications': deletedNotifications,
        'deletedReports': deletedReports,
        'deletedRatings': deletedRatings,
        'deletedSessions': deletedSessions,
        'deletedMatches': deletedMatches,
        'deletedConversations': deletedConversations,
        'deletedStudyGroups': studyGroupCleanup['deletedGroups'] ?? 0,
        'removedFromStudyGroups': studyGroupCleanup['removedMemberships'] ?? 0,
        'deletedForumPosts': deletedForumPosts,
        'deletedForumComments': deletedForumComments,
        'deletedUserSubcollections': deletedUserSubcollections,
      },
    );
  }

  Future<AdminModerationResult> takeDownStudyGroup({
    required String groupId,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw ArgumentError('A takedown reason is required.');
    }

    final groupRef = _studyGroupsRef.doc(groupId);
    final groupDoc = await groupRef.get();
    if (!groupDoc.exists) {
      throw Exception('Study group not found.');
    }

    final data = groupDoc.data() ?? const <String, dynamic>{};
    final groupName = data['name'] as String? ?? 'Untitled Group';
    final members = List<String>.from(data['members'] ?? const <String>[])
        .where((uid) => uid.trim().isNotEmpty)
        .toSet()
        .toList();

    await groupRef.update({
      'isActive': false,
      'takedownReason': trimmedReason,
      'takenDownAt': FieldValue.serverTimestamp(),
      'takenDownBy': _currentAdminIdentity(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _createNotifications(
      uids: members,
      title: 'Study Group Removed',
      body:
          '"$groupName" was removed by an administrator. Reason: $trimmedReason',
      data: {'groupId': groupId, 'route': '/study_groups'},
    );

    await _logAdminAction(
      action: 'take_down_study_group',
      details:
          'Took down study group $groupName ($groupId). Reason: $trimmedReason',
    );

    return AdminModerationResult(
      message: 'Study group "$groupName" was taken down successfully.',
      payload: {
        'groupId': groupId,
        'groupName': groupName,
        'reason': trimmedReason,
        'notifiedMembers': members.length,
      },
    );
  }

  Future<int> _deleteUserConversations(String uid) async {
    final snapshot = await _conversationsRef
        .where('participants', arrayContains: uid)
        .get();

    int deletedCount = 0;
    for (final doc in snapshot.docs) {
      await _deleteSubcollection(doc.reference.collection('messages'));
      await _deleteSubcollection(doc.reference.collection('reads'));
      await doc.reference.delete();
      deletedCount++;
    }
    return deletedCount;
  }

  Future<Map<String, int>> _cleanUpStudyGroupsForUser(
    String uid,
    String reason,
  ) async {
    final ownerSnapshot = await _studyGroupsRef.where('ownerUid', isEqualTo: uid).get();
    final memberSnapshot = await _studyGroupsRef
        .where('members', arrayContains: uid)
        .get();

    final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in ownerSnapshot.docs) {
      docsById[doc.id] = doc;
    }
    for (final doc in memberSnapshot.docs) {
      docsById[doc.id] = doc;
    }

    int deletedGroups = 0;
    int removedMemberships = 0;

    for (final doc in docsById.values) {
      final data = doc.data();
      if (data['ownerUid'] == uid) {
        await _deleteSubcollection(doc.reference.collection('messages'));
        await doc.reference.delete();
        deletedGroups++;
        continue;
      }

      await doc.reference.update({
        'members': FieldValue.arrayRemove([uid]),
        'memberCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      removedMemberships++;
    }

    if (deletedGroups > 0 || removedMemberships > 0) {
      await _logAdminAction(
        action: 'cleanup_user_study_groups',
        details:
            'Removed user $uid from $removedMemberships study groups and deleted $deletedGroups owned groups. Reason: $reason',
      );
    }

    return {
      'deletedGroups': deletedGroups,
      'removedMemberships': removedMemberships,
    };
  }

  Future<int> _deleteForumPostsByAuthor(String uid) async {
    final snapshot = await _forumPostsRef.where('authorUid', isEqualTo: uid).get();
    int deletedCount = 0;

    for (final doc in snapshot.docs) {
      await _deleteSubcollection(doc.reference.collection('comments'));
      await doc.reference.delete();
      deletedCount++;
    }

    return deletedCount;
  }

  Future<int> _deleteUserSubcollections(String uid) async {
    final userRef = _usersRef.doc(uid);
    return await _deleteSubcollection(userRef.collection('swipes')) +
        await _deleteSubcollection(userRef.collection('blocks')) +
        await _deleteSubcollection(userRef.collection('fcmTokens'));
  }

  Future<int> _deleteSubcollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) {
    return _deleteQueryDocs(collection);
  }

  Future<int> _deleteQueryDocs(Query<Map<String, dynamic>> query) async {
    int totalDeleted = 0;

    while (true) {
      final snapshot = await query.limit(200).get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      totalDeleted += snapshot.docs.length;
      if (snapshot.docs.length < 200) {
        break;
      }
    }

    return totalDeleted;
  }

  Future<void> _createNotifications({
    required Iterable<String> uids,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    final uniqueUids = uids.where((uid) => uid.trim().isNotEmpty).toSet().toList();
    if (uniqueUids.isEmpty) {
      return;
    }

    for (var index = 0; index < uniqueUids.length; index += 200) {
      final batch = _firestore.batch();
      final chunk = uniqueUids.skip(index).take(200);
      for (final uid in chunk) {
        final docRef = _notificationsRef.doc();
        batch.set(docRef, {
          'uid': uid,
          'type': 'admin_action',
          'title': title,
          'body': body,
          'data': data,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<void> _logAdminAction({
    required String action,
    required String details,
  }) async {
    await _adminActionsRef.add({
      'action': action,
      'adminEmail': _currentAdminIdentity(),
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  String _currentAdminIdentity() {
    final username = AdminAuthService().adminUsername.trim();
    if (username.isEmpty) {
      return 'admin@local';
    }
    return username.contains('@') ? username : '$username@local';
  }
}
