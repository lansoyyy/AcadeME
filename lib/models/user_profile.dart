import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile for the AcadeME app
/// Includes both basic profile info and matching/discovery fields for Study Buddy feature
class UserProfile {
  // Basic profile fields (existing)
  final String uid;
  final String fullName;
  final String studentId;
  final String birthday;
  final int age;
  final String photoUrl;

  // Matching/discovery fields (new)
  final String track;
  final int gradeLevel;
  final List<String> subjectsInterested;
  final List<String> studyGoals;
  final String bio;
  final Map<String, dynamic> availability;
  final Map<String, dynamic> location;
  final Map<String, dynamic> matchPreferences;
  final bool isDiscoverable;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.studentId,
    required this.birthday,
    required this.age,
    this.photoUrl = '',
    this.track = '',
    this.gradeLevel = 11,
    this.subjectsInterested = const [],
    this.studyGoals = const [],
    this.bio = '',
    this.availability = const {},
    this.location = const {},
    this.matchPreferences = const {},
    this.isDiscoverable = true,
    this.lastActiveAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      fullName: (map['fullName'] ?? '') as String,
      studentId: (map['studentId'] ?? '') as String,
      birthday: (map['birthday'] ?? '') as String,
      age: (map['age'] ?? 0) is int
          ? map['age'] as int
          : int.tryParse('${map['age']}') ?? 0,
      photoUrl: (map['photoUrl'] ?? '') as String,
      track: (map['track'] ?? '') as String,
      gradeLevel: (map['gradeLevel'] ?? 11) is int
          ? map['gradeLevel'] as int
          : int.tryParse('${map['gradeLevel']}') ?? 11,
      subjectsInterested: _parseStringList(map['subjectsInterested']),
      studyGoals: _parseStringList(map['studyGoals']),
      bio: (map['bio'] ?? '') as String,
      availability: _parseMap(map['availability']),
      location: _parseMap(map['location']),
      matchPreferences: _parseMap(map['matchPreferences']),
      isDiscoverable: map['isDiscoverable'] ?? true,
      lastActiveAt: _parseTimestamp(map['lastActiveAt']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'studentId': studentId,
      'birthday': birthday,
      'age': age,
      'photoUrl': photoUrl,
      'track': track,
      'gradeLevel': gradeLevel,
      'subjectsInterested': subjectsInterested,
      'studyGoals': studyGoals,
      'bio': bio,
      'availability': availability,
      'location': location,
      'matchPreferences': matchPreferences,
      'isDiscoverable': isDiscoverable,
      'lastActiveAt': lastActiveAt != null
          ? Timestamp.fromDate(lastActiveAt!)
          : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Creates a copy with updated fields
  UserProfile copyWith({
    String? fullName,
    String? studentId,
    String? birthday,
    int? age,
    String? photoUrl,
    String? track,
    int? gradeLevel,
    List<String>? subjectsInterested,
    List<String>? studyGoals,
    String? bio,
    Map<String, dynamic>? availability,
    Map<String, dynamic>? location,
    Map<String, dynamic>? matchPreferences,
    bool? isDiscoverable,
    DateTime? lastActiveAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      studentId: studentId ?? this.studentId,
      birthday: birthday ?? this.birthday,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      track: track ?? this.track,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      subjectsInterested: subjectsInterested ?? this.subjectsInterested,
      studyGoals: studyGoals ?? this.studyGoals,
      bio: bio ?? this.bio,
      availability: availability ?? this.availability,
      location: location ?? this.location,
      matchPreferences: matchPreferences ?? this.matchPreferences,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static UserProfile? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    return UserProfile.fromMap(doc.id, data);
  }

  // Helper methods
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  static Map<String, dynamic> _parseMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  /// Returns a display string for matching card
  String get displayAge => age > 0 ? '$age' : '';

  /// Returns formatted name with age if available
  String get displayNameWithAge {
    if (age > 0) {
      return '$fullName, $age';
    }
    return fullName;
  }

  /// Returns a summary of subjects for display
  String get subjectsSummary {
    if (subjectsInterested.isEmpty) return '';
    if (subjectsInterested.length == 1) {
      return subjectsInterested.first;
    }
    return '${subjectsInterested.first} + ${subjectsInterested.length - 1} more';
  }
}
