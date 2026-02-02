import 'package:cloud_firestore/cloud_firestore.dart';

/// Academic Data Service
/// Fetches curriculum data from Firestore `academic/*` collections
/// This replaces hardcoded curriculum data in constants.dart
class AcademicDataService {
  AcademicDataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Collection references
  CollectionReference<Map<String, dynamic>> get _subjectsRef =>
      _firestore.collection('academic/subjects');

  CollectionReference<Map<String, dynamic>> get _strandsRef =>
      _firestore.collection('academic/strands');

  CollectionReference<Map<String, dynamic>> get _gradeLevelsRef =>
      _firestore.collection('academic/gradeLevels');

  /// Stream all active subjects
  Stream<QuerySnapshot<Map<String, dynamic>>> streamSubjects() {
    return _subjectsRef
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots();
  }

  /// Get all active subjects (one-time fetch)
  Future<List<Map<String, dynamic>>> getSubjects() async {
    final snapshot = await _subjectsRef
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Get subjects by type (Core, Applied, Specialized, Program)
  Future<List<Map<String, dynamic>>> getSubjectsByType(String type) async {
    final snapshot = await _subjectsRef
        .where('isActive', isEqualTo: true)
        .where('type', isEqualTo: type)
        .orderBy('name')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Get subject by code
  Future<Map<String, dynamic>?> getSubjectByCode(String code) async {
    final snapshot = await _subjectsRef.where('code', isEqualTo: code).get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
  }

  /// Stream all active strands
  Stream<QuerySnapshot<Map<String, dynamic>>> streamStrands() {
    return _strandsRef
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots();
  }

  /// Get all active strands (one-time fetch)
  Future<List<Map<String, dynamic>>> getStrands() async {
    final snapshot = await _strandsRef
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Stream all active grade levels
  Stream<QuerySnapshot<Map<String, dynamic>>> streamGradeLevels() {
    return _gradeLevelsRef
        .where('isActive', isEqualTo: true)
        .orderBy('value')
        .snapshots();
  }

  /// Get all active grade levels (one-time fetch)
  Future<List<Map<String, dynamic>>> getGradeLevels() async {
    final snapshot = await _gradeLevelsRef
        .where('isActive', isEqualTo: true)
        .orderBy('value')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Admin-only: Create subject
  Future<void> createSubject({
    required String code,
    required String name,
    required String type,
  }) async {
    await _subjectsRef.add({
      'code': code,
      'name': name,
      'type': type,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin-only: Update subject
  Future<void> updateSubject(
    String subjectId,
    Map<String, dynamic> data,
  ) async {
    await _subjectsRef.doc(subjectId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin-only: Delete subject (soft delete by setting isActive to false)
  Future<void> deleteSubject(String subjectId) async {
    await _subjectsRef.doc(subjectId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin-only: Create strand
  Future<void> createStrand({required String name}) async {
    await _strandsRef.add({
      'name': name,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin-only: Update strand
  Future<void> updateStrand(String strandId, Map<String, dynamic> data) async {
    await _strandsRef.doc(strandId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin-only: Delete strand (soft delete by setting isActive to false)
  Future<void> deleteStrand(String strandId) async {
    await _strandsRef.doc(strandId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin-only: Create grade level
  Future<void> createGradeLevel({required int value}) async {
    await _gradeLevelsRef.add({
      'value': value,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin-only: Update grade level
  Future<void> updateGradeLevel(
    String gradeId,
    Map<String, dynamic> data,
  ) async {
    await _gradeLevelsRef.doc(gradeId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin-only: Delete grade level (soft delete by setting isActive to false)
  Future<void> deleteGradeLevel(String gradeId) async {
    await _gradeLevelsRef.doc(gradeId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
