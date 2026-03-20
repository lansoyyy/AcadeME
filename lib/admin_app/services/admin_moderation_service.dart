import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
  AdminModerationService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  }) : _functions = functions ?? FirebaseFunctions.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamStudyGroups() {
    return _firestore.collection('studyGroups').snapshots();
  }

  Future<AdminModerationResult> deleteUserAccount({
    required String uid,
    required String reason,
  }) async {
    final result = await _functions
        .httpsCallable('adminDeleteUserAccount')
        .call({'uid': uid, 'reason': reason});

    return AdminModerationResult.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }

  Future<AdminModerationResult> takeDownStudyGroup({
    required String groupId,
    required String reason,
  }) async {
    final result = await _functions
        .httpsCallable('adminTakeDownStudyGroup')
        .call({'groupId': groupId, 'reason': reason});

    return AdminModerationResult.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }
}
