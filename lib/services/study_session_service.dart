import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

/// Service for managing study sessions
class StudySessionService {
  StudySessionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sessionsRef =>
      _firestore.collection('studySessions');

  /// Create a new study session
  Future<String> createSession({
    required String guestUid,
    required String subject,
    required DateTime scheduledAt,
    String? conversationId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final docRef = _sessionsRef.doc();
    await docRef.set({
      'hostUid': currentUser.uid,
      'guestUid': guestUid,
      'participants': [currentUser.uid, guestUid],
      'subject': subject,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': 'pending',
      'conversationId': conversationId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Stream ALL sessions where the current user is either host or guest
  Stream<List<StudySession>> streamAllUserSessions() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final hostStream = _sessionsRef
        .where('hostUid', isEqualTo: currentUser.uid)
        .snapshots();

    final guestStream = _sessionsRef
        .where('guestUid', isEqualTo: currentUser.uid)
        .snapshots();

    return Rx.combineLatest2<
      QuerySnapshot<Map<String, dynamic>>,
      QuerySnapshot<Map<String, dynamic>>,
      List<StudySession>
    >(hostStream, guestStream, (hostSnap, guestSnap) {
      final allDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in hostSnap.docs) {
        allDocs[doc.id] = doc;
      }
      for (final doc in guestSnap.docs) {
        allDocs[doc.id] = doc;
      }
      final sessions = allDocs.values
          .map((doc) {
            try {
              return StudySession.fromDoc(doc);
            } catch (_) {
              return null;
            }
          })
          .whereType<StudySession>()
          .toList();
      sessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return sessions;
    });
  }

  /// Get all sessions where user is the host
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserSessions() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _sessionsRef
        .where('hostUid', isEqualTo: currentUser.uid)
        .orderBy('scheduledAt', descending: false)
        .snapshots();
  }

  /// Get sessions where user is the guest
  Stream<QuerySnapshot<Map<String, dynamic>>> streamGuestSessions() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _sessionsRef
        .where('guestUid', isEqualTo: currentUser.uid)
        .orderBy('scheduledAt', descending: false)
        .snapshots();
  }

  /// Update session status
  Future<void> updateSessionStatus({
    required String sessionId,
    required String status,
  }) async {
    await _sessionsRef.doc(sessionId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Confirm a session (as guest)
  Future<void> confirmSession(String sessionId) async {
    await updateSessionStatus(sessionId: sessionId, status: 'confirmed');
  }

  /// Cancel a session
  Future<void> cancelSession(String sessionId) async {
    await updateSessionStatus(sessionId: sessionId, status: 'cancelled');
  }

  /// Complete a session
  Future<void> completeSession(String sessionId) async {
    await updateSessionStatus(sessionId: sessionId, status: 'completed');
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    await _sessionsRef.doc(sessionId).delete();
  }

  /// Get session by ID
  Future<DocumentSnapshot<Map<String, dynamic>>?> getSession(
    String sessionId,
  ) async {
    final doc = await _sessionsRef.doc(sessionId).get();
    return doc.exists ? doc : null;
  }
}

/// Model for a study session
class StudySession {
  final String id;
  final String hostUid;
  final String guestUid;
  final String subject;
  final DateTime scheduledAt;
  final String status;
  final String? conversationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudySession({
    required this.id,
    required this.hostUid,
    required this.guestUid,
    required this.subject,
    required this.scheduledAt,
    required this.status,
    this.conversationId,
    this.createdAt,
    this.updatedAt,
  });

  factory StudySession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return StudySession(
      id: doc.id,
      hostUid: data['hostUid'] as String,
      guestUid: data['guestUid'] as String,
      subject: data['subject'] as String,
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      status: data['status'] as String,
      conversationId: data['conversationId'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFA726); // Orange
      case 'confirmed':
        return const Color(0xFF66BB6A); // Green
      case 'completed':
        return const Color(0xFF42A5F5); // Blue
      case 'cancelled':
        return const Color(0xFFEF5350); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}
