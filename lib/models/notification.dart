import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Types of notifications
enum NotificationType {
  match,
  message,
  studySession,
  studyGroup,
  sessionReminder,
  system,
  approval,
}

/// User notification model
class UserNotification {
  final String id;
  final String uid; // recipient user ID
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data; // payload for navigation
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const UserNotification({
    required this.id,
    required this.uid,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory UserNotification.fromMap(String id, Map<String, dynamic> map) {
    return UserNotification(
      id: id,
      uid: map['uid'] as String,
      type: _parseType(map['type'] as String? ?? 'system'),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      data: (map['data'] as Map<String, dynamic>?) ?? {},
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  UserNotification copyWith({bool? isRead, DateTime? readAt}) {
    return UserNotification(
      id: id,
      uid: uid,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  static NotificationType _parseType(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NotificationType.system,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.match:
        return Icons.favorite;
      case NotificationType.message:
        return Icons.chat_bubble;
      case NotificationType.studySession:
        return Icons.calendar_today;
      case NotificationType.studyGroup:
        return Icons.groups;
      case NotificationType.sessionReminder:
        return Icons.alarm;
      case NotificationType.approval:
        return Icons.verified;
      case NotificationType.system:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.match:
        return const Color(0xFFE91E63); // pink
      case NotificationType.message:
        return const Color(0xFF2196F3); // blue
      case NotificationType.studySession:
        return const Color(0xFF4CAF50); // green
      case NotificationType.studyGroup:
        return const Color(0xFF9C27B0); // purple
      case NotificationType.sessionReminder:
        return const Color(0xFFFF9800); // orange
      case NotificationType.approval:
        return const Color(0xFF00BCD4); // cyan
      case NotificationType.system:
        return const Color(0xFF607D8B); // grey
    }
  }
}
