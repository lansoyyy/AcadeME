import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Admin User Service
/// Handles user management operations for admin
class AdminUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all users
  Stream<QuerySnapshot> streamUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get single user
  Future<DocumentSnapshot?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? doc : null;
  }

  /// Update user account status
  Future<void> updateUserStatus(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Suspend user until date
  Future<void> suspendUser(String uid, DateTime until) async {
    await _firestore.collection('users').doc(uid).update({
      'suspendedUntil': Timestamp.fromDate(until),
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add warning to user
  Future<void> addWarning(String uid, String reason) async {
    final userRef = _firestore.collection('users').doc(uid);
    
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      final currentWarnings = userDoc.data()?['warningsCount'] ?? 0;
      
      transaction.update(userRef, {
        'warningsCount': currentWarnings + 1,
        'lastWarningAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // Log the warning
    await _firestore.collection('adminActions').add({
      'type': 'warning',
      'targetUid': uid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  /// Flag a profile field as inappropriate
  Future<void> flagProfile(String uid, String fieldName, String reason) async {
    await _firestore.collection('users').doc(uid).update({
      'isFlagged': true,
      'flaggedFields': FieldValue.arrayUnion([
        {
          'field': fieldName,
          'reason': reason,
          'flaggedAt': FieldValue.serverTimestamp(),
        }
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove flag from a profile
  Future<void> unflagProfile(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isFlagged': false,
      'flaggedFields': [],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Send an in-app notification to a user
  Future<void> sendNotificationToUser({
    required String uid,
    required String title,
    required String body,
    String type = 'system',
    Map<String, dynamic> data = const {},
  }) async {
    await _firestore.collection('notifications').add({
      'uid': uid,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Search users by name (client-side filtering on result)
  Future<QuerySnapshot> searchUsers(String query) async {
    return _firestore
        .collection('users')
        .orderBy('fullName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .get();
  }
}
