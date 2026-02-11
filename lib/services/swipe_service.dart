import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for swipe directions
enum SwipeDirection { like, nope, superlike }

/// Extension to get string value
extension SwipeDirectionExtension on SwipeDirection {
  String get value {
    switch (this) {
      case SwipeDirection.like:
        return 'like';
      case SwipeDirection.nope:
        return 'nope';
      case SwipeDirection.superlike:
        return 'superlike';
    }
  }
}

/// Service for handling swipe actions and match creation
/// All operations are client-side (no Cloud Functions)
class SwipeService {
  SwipeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Collection references
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _matchesRef =>
      _firestore.collection('matches');

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('conversations');

  /// Record a swipe action and check for mutual match
  /// Returns MatchResult with match info if it's a mutual match
  Future<SwipeResult> swipe({
    required String fromUid,
    required String toUid,
    required SwipeDirection direction,
  }) async {
    // Don't allow self-swipes
    if (fromUid == toUid) {
      throw ArgumentError('Cannot swipe on yourself');
    }

    // Create swipe document in subcollection
    final swipeRef = _usersRef.doc(fromUid).collection('swipes').doc(toUid);

    // Check if already swiped
    final existingSwipe = await swipeRef.get();
    if (existingSwipe.exists) {
      // Already swiped this user, return existing result
      return SwipeResult(
        isMatch: false,
        matchId: null,
        conversationId: null,
        alreadySwiped: true,
      );
    }

    // Record the swipe
    await swipeRef.set({
      'direction': direction.value,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // If it's a like/superlike, check for mutual match
    if (direction == SwipeDirection.like ||
        direction == SwipeDirection.superlike) {
      return await _checkAndCreateMatch(fromUid: fromUid, toUid: toUid);
    }

    // It's a nope, no match possible
    return SwipeResult(
      isMatch: false,
      matchId: null,
      conversationId: null,
      alreadySwiped: false,
    );
  }

  /// Check if the other user has already liked us, and create match if so
  /// Uses a transaction to ensure atomicity
  Future<SwipeResult> _checkAndCreateMatch({
    required String fromUid,
    required String toUid,
  }) async {
    // Check if toUid has already liked fromUid
    final theirSwipeRef = _usersRef
        .doc(toUid)
        .collection('swipes')
        .doc(fromUid);
    final theirSwipeDoc = await theirSwipeRef.get();

    // If they haven't liked us, no match
    if (!theirSwipeDoc.exists) {
      return SwipeResult(
        isMatch: false,
        matchId: null,
        conversationId: null,
        alreadySwiped: false,
      );
    }

    final theirSwipeData = theirSwipeDoc.data()!;
    final theirDirection = theirSwipeData['direction'] as String;

    // They must have liked or superliked us
    if (theirDirection != 'like' && theirDirection != 'superlike') {
      return SwipeResult(
        isMatch: false,
        matchId: null,
        conversationId: null,
        alreadySwiped: false,
      );
    }

    // It's a mutual match! Create match and conversation atomically
    final matchId = _generateMatchId(fromUid, toUid);
    final conversationId = matchId; // Use same ID for simplicity

    try {
      await _firestore.runTransaction((transaction) async {
        // Check if match already exists (idempotency)
        final matchRef = _matchesRef.doc(matchId);
        final matchDoc = await transaction.get(matchRef);

        if (matchDoc.exists) {
          // Match already created by another transaction
          return;
        }

        final now = FieldValue.serverTimestamp();

        // Create match document
        transaction.set(matchRef, {
          'users': [fromUid, toUid],
          'createdAt': now,
          'createdBy': fromUid,
          'isActive': true,
          'lastMessageAt': null,
          'lastMessageText': null,
          'lastMessageSenderId': null,
        });

        // Create conversation document
        final convRef = _conversationsRef.doc(conversationId);
        transaction.set(convRef, {
          'type': 'match_chat',
          'matchId': matchId,
          'participants': [fromUid, toUid],
          'createdAt': now,
          'updatedAt': now,
          'lastMessage': {
            'text': 'You matched! Start your study session planning.',
            'senderId': 'system',
            'createdAt': now,
            'type': 'system',
          },
          'lastMessageAt': now,
          'unreadCount': {fromUid: 0, toUid: 0},
          'isActive': true,
        });

        // Add system message
        final messageRef = convRef.collection('messages').doc();
        transaction.set(messageRef, {
          'senderId': 'system',
          'type': 'system',
          'text': 'You matched! Start your study session planning.',
          'createdAt': now,
          'clientId': 'system_${DateTime.now().millisecondsSinceEpoch}',
        });
      });

      return SwipeResult(
        isMatch: true,
        matchId: matchId,
        conversationId: conversationId,
        alreadySwiped: false,
      );
    } catch (e) {
      // Transaction failed, likely due to race condition
      // Check if match was created by concurrent transaction
      final matchDoc = await _matchesRef.doc(matchId).get();
      if (matchDoc.exists) {
        return SwipeResult(
          isMatch: true,
          matchId: matchId,
          conversationId: conversationId,
          alreadySwiped: false,
        );
      }
      rethrow;
    }
  }

  /// Get list of UIDs that the user has already swiped on
  /// Used to filter candidates
  Future<Set<String>> getSwipedUserIds(String uid) async {
    final snapshot = await _usersRef.doc(uid).collection('swipes').get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  /// Stream of swipes for real-time updates (optional)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamSwipes(String uid) {
    return _usersRef
        .doc(uid)
        .collection('swipes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Check if two users have matched
  Future<bool> haveMatched(String uid1, String uid2) async {
    final matchId = _generateMatchId(uid1, uid2);
    final matchDoc = await _matchesRef.doc(matchId).get();
    return matchDoc.exists;
  }

  /// Get match document if it exists
  Future<DocumentSnapshot<Map<String, dynamic>>?> getMatch(
    String uid1,
    String uid2,
  ) async {
    final matchId = _generateMatchId(uid1, uid2);
    final matchDoc = await _matchesRef.doc(matchId).get();
    return matchDoc.exists ? matchDoc : null;
  }

  /// Generate a consistent match ID from two UIDs
  /// Alphabetically sorted to ensure same ID regardless of order
  String _generateMatchId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Unmatch a user (delete match and conversation)
  /// Only the match creator can unmatch, or either participant
  Future<void> unmatch({required String uid, required String otherUid}) async {
    final matchId = _generateMatchId(uid, otherUid);
    final conversationId = matchId;

    await _firestore.runTransaction((transaction) async {
      // Delete match
      final matchRef = _matchesRef.doc(matchId);
      transaction.delete(matchRef);

      // Delete conversation
      final convRef = _conversationsRef.doc(conversationId);
      transaction.delete(convRef);

      // Note: Messages are in a subcollection and will be orphaned
      // You may want to delete them too or keep for audit purposes
    });
  }

  /// Block a user
  /// Records block and removes any existing match
  Future<void> blockUser({
    required String uid,
    required String blockedUid,
  }) async {
    // Record the block
    await _usersRef.doc(uid).collection('blocks').doc(blockedUid).set({
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Remove any existing match
    try {
      await unmatch(uid: uid, otherUid: blockedUid);
    } catch (e) {
      // No match exists, that's fine
    }
  }

  /// Get list of blocked user IDs
  Future<Set<String>> getBlockedUserIds(String uid) async {
    final snapshot = await _usersRef.doc(uid).collection('blocks').get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  /// Report a user
  Future<void> reportUser({
    required String reporterUid,
    required String reportedUid,
    required String reason,
    String? conversationId,
  }) async {
    final reportRef = _firestore.collection('reports').doc();
    await reportRef.set({
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': reason,
      'conversationId': conversationId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Result of a swipe operation
class SwipeResult {
  final bool isMatch;
  final String? matchId;
  final String? conversationId;
  final bool alreadySwiped;

  const SwipeResult({
    required this.isMatch,
    required this.matchId,
    required this.conversationId,
    required this.alreadySwiped,
  });

  bool get hasNewMatch => isMatch && !alreadySwiped;
}
