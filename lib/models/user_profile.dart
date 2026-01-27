import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String fullName;
  final String studentId;
  final String birthday;
  final int age;
  final String photoUrl;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.studentId,
    required this.birthday,
    required this.age,
    this.photoUrl = '',
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'studentId': studentId,
      'birthday': birthday,
      'age': age,
      'photoUrl': photoUrl,
    };
  }

  static UserProfile? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    return UserProfile.fromMap(doc.id, data);
  }
}
