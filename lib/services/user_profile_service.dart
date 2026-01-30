import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ref(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Stream<UserProfile?> streamProfile(String uid) {
    return _ref(uid).snapshots().map(UserProfile.fromDoc);
  }

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _ref(uid).get();
    return UserProfile.fromDoc(doc);
  }

  Future<void> upsertProfile(UserProfile profile) {
    return _ref(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  /// Get discoverable users for matching
  /// Excludes already swiped users and blocked users
  Future<List<UserProfile>> getDiscoverableUsers({
    required String currentUid,
    required Set<String> excludeUids,
    String? track,
    int? gradeLevel,
    int limit = 20,
  }) async {
    var query = _firestore
        .collection('users')
        .where('isDiscoverable', isEqualTo: true)
        .where(FieldPath.documentId, isNotEqualTo: currentUid)
        .limit(limit * 2); // Fetch more to account for filtering

    // Optional filters
    if (track != null && track.isNotEmpty) {
      query = query.where('track', isEqualTo: track);
    }
    if (gradeLevel != null) {
      query = query.where('gradeLevel', isEqualTo: gradeLevel);
    }

    final snapshot = await query.get();

    final profiles = snapshot.docs
        .map((doc) => UserProfile.fromDoc(doc))
        .whereType<UserProfile>()
        .where((profile) => !excludeUids.contains(profile.uid))
        .take(limit)
        .toList();

    return profiles;
  }

  /// Stream a single user profile
  Stream<UserProfile?> streamUserProfile(String uid) {
    return _ref(uid).snapshots().map(UserProfile.fromDoc);
  }
}
