import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing study groups
class StudyGroupService {
  StudyGroupService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _groupsRef =>
      _firestore.collection('studyGroups');

  /// Create a new study group
  Future<String> createGroup({
    required String name,
    required String subject,
    String description = '',
    int maxMembers = 10,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final docRef = _groupsRef.doc();
    await docRef.set({
      'name': name,
      'subject': subject,
      'description': description,
      'ownerUid': currentUser.uid,
      'members': [currentUser.uid],
      'memberCount': 1,
      'maxMembers': maxMembers,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Stream groups where user is a member
  Stream<List<StudyGroup>> streamMyGroups() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    return _groupsRef
        .where('members', arrayContains: currentUser.uid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final groups = snap.docs
              .map((doc) {
                try {
                  return StudyGroup.fromDoc(doc);
                } catch (_) {
                  return null;
                }
              })
              .whereType<StudyGroup>()
              .toList();
          groups.sort(
            (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
              a.updatedAt ?? DateTime(2000),
            ),
          );
          return groups;
        });
  }

  /// Stream all public/active groups (for browsing/joining)
  Stream<List<StudyGroup>> streamAllGroups() {
    return _groupsRef
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) {
                try {
                  return StudyGroup.fromDoc(doc);
                } catch (_) {
                  return null;
                }
              })
              .whereType<StudyGroup>()
              .toList();
        });
  }

  /// Join a group
  Future<void> joinGroup(String groupId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final doc = await _groupsRef.doc(groupId).get();
    if (!doc.exists) throw Exception('Group not found');

    final data = doc.data()!;
    final members = List<String>.from(data['members'] ?? []);
    final maxMembers = data['maxMembers'] as int? ?? 10;

    if (members.contains(currentUser.uid)) {
      throw Exception('Already a member');
    }
    if (members.length >= maxMembers) {
      throw Exception('Group is full');
    }

    await _groupsRef.doc(groupId).update({
      'members': FieldValue.arrayUnion([currentUser.uid]),
      'memberCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final doc = await _groupsRef.doc(groupId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final ownerUid = data['ownerUid'] as String?;

    if (ownerUid == currentUser.uid) {
      throw Exception('Owner cannot leave. Delete the group instead.');
    }

    await _groupsRef.doc(groupId).update({
      'members': FieldValue.arrayRemove([currentUser.uid]),
      'memberCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a group (owner only)
  Future<void> deleteGroup(String groupId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final doc = await _groupsRef.doc(groupId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    if (data['ownerUid'] != currentUser.uid) {
      throw Exception('Only the owner can delete this group');
    }

    await _groupsRef.doc(groupId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Send a message to the group chat
  Future<void> sendGroupMessage({
    required String groupId,
    required String text,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    await _groupsRef.doc(groupId).collection('messages').add({
      'senderUid': currentUser.uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _groupsRef.doc(groupId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream group messages
  Stream<QuerySnapshot<Map<String, dynamic>>> streamGroupMessages(
    String groupId,
  ) {
    return _groupsRef
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Get a single group
  Future<StudyGroup?> getGroup(String groupId) async {
    final doc = await _groupsRef.doc(groupId).get();
    if (!doc.exists) return null;
    return StudyGroup.fromDoc(doc);
  }
}

/// Model for a study group
class StudyGroup {
  final String id;
  final String name;
  final String subject;
  final String description;
  final String ownerUid;
  final List<String> members;
  final int memberCount;
  final int maxMembers;
  final bool isActive;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudyGroup({
    required this.id,
    required this.name,
    required this.subject,
    required this.description,
    required this.ownerUid,
    required this.members,
    required this.memberCount,
    required this.maxMembers,
    required this.isActive,
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
  });

  factory StudyGroup.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return StudyGroup(
      id: doc.id,
      name: data['name'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      description: data['description'] as String? ?? '',
      ownerUid: data['ownerUid'] as String? ?? '',
      members: List<String>.from(data['members'] ?? []),
      memberCount: data['memberCount'] as int? ?? 0,
      maxMembers: data['maxMembers'] as int? ?? 10,
      isActive: data['isActive'] as bool? ?? true,
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  bool get isFull => memberCount >= maxMembers;
}
