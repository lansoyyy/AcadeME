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
}
