import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

/// Service for managing user notifications in Firestore
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>>? _notificationsRef;

  void initialize() {
    _notificationsRef ??= _firestore.collection('notifications');
  }

  CollectionReference<Map<String, dynamic>> get _ref {
    if (_notificationsRef == null) {
      initialize();
    }
    return _notificationsRef!;
  }

  /// Stream of notifications for a user, ordered by newest first
  Stream<List<UserNotification>> streamNotifications(String uid) {
    return _ref
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserNotification.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Stream of unread notification count
  Stream<int> streamUnreadCount(String uid) {
    return _ref
        .where('uid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get paginated notifications
  Future<List<UserNotification>> getNotifications({
    required String uid,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    var query = _ref
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => UserNotification.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Create a new notification
  Future<String> createNotification({
    required String uid,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    final docRef = _ref.doc();
    final notification = UserNotification(
      id: docRef.id,
      uid: uid,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await docRef.set(notification.toMap());
    return docRef.id;
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _ref.doc(notificationId).update({
      'isRead': true,
      'readAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String uid) async {
    final batch = _firestore.batch();
    final unread = await _ref
        .where('uid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': Timestamp.fromDate(DateTime.now()),
      });
    }

    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _ref.doc(notificationId).delete();
  }

  /// Delete all notifications for a user (with optional filter)
  Future<void> deleteAllNotifications(
    String uid, {
    bool onlyRead = false,
  }) async {
    var query = _ref.where('uid', isEqualTo: uid);
    if (onlyRead) {
      query = query.where('isRead', isEqualTo: true);
    }

    final snapshot = await query.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Create match notification
  Future<void> notifyMatch({
    required String uid,
    required String matchedUserName,
    required String conversationId,
  }) async {
    await createNotification(
      uid: uid,
      type: NotificationType.match,
      title: 'New Match!',
      body: 'You matched with $matchedUserName. Start chatting!',
      data: {'conversationId': conversationId, 'route': '/chat'},
    );
  }

  /// Create new message notification
  Future<void> notifyMessage({
    required String uid,
    required String senderName,
    required String messagePreview,
    required String conversationId,
  }) async {
    await createNotification(
      uid: uid,
      type: NotificationType.message,
      title: 'New message from $senderName',
      body: messagePreview,
      data: {'conversationId': conversationId, 'route': '/chat'},
    );
  }

  /// Create study session notification
  Future<void> notifyStudySession({
    required String uid,
    required String
    sessionType, // 'invited', 'accepted', 'declined', 'reminder'
    required String otherUserName,
    required String subject,
    required String sessionId,
  }) async {
    String title;
    String body;

    switch (sessionType) {
      case 'invited':
        title = 'Study Session Invitation';
        body = '$otherUserName invited you to study $subject';
        break;
      case 'accepted':
        title = 'Session Accepted';
        body = '$otherUserName accepted your study session for $subject';
        break;
      case 'declined':
        title = 'Session Declined';
        body = '$otherUserName declined your study session for $subject';
        break;
      case 'reminder':
        title = 'Study Session Reminder';
        body = 'Your study session for $subject starts soon!';
        break;
      default:
        title = 'Study Session Update';
        body = 'Update regarding your $subject study session';
    }

    await createNotification(
      uid: uid,
      type: NotificationType.studySession,
      title: title,
      body: body,
      data: {'sessionId': sessionId, 'route': '/sessions'},
    );
  }

  /// Create study group notification
  Future<void> notifyStudyGroup({
    required String uid,
    required String groupName,
    required String notificationType, // 'new_member', 'message', 'invite'
    String? otherUserName,
    String? messagePreview,
    required String groupId,
  }) async {
    String title;
    String body;

    switch (notificationType) {
      case 'new_member':
        title = 'New Group Member';
        body = '$otherUserName joined $groupName';
        break;
      case 'message':
        title = '$groupName: New Message';
        body = messagePreview ?? 'New message in $groupName';
        break;
      case 'invite':
        title = 'Group Invitation';
        body = 'You were invited to join $groupName';
        break;
      default:
        title = 'Group Update';
        body = 'Update from $groupName';
    }

    await createNotification(
      uid: uid,
      type: NotificationType.studyGroup,
      title: title,
      body: body,
      data: {'groupId': groupId, 'route': '/study_groups'},
    );
  }

  /// Create registration approval notification
  Future<void> notifyApproval({
    required String uid,
    required String status, // 'approved', 'rejected'
  }) async {
    final isApproved = status == 'approved';
    await createNotification(
      uid: uid,
      type: NotificationType.approval,
      title: isApproved ? 'Registration Approved!' : 'Registration Status',
      body: isApproved
          ? 'Your registration has been approved. Welcome to AcadeME!'
          : 'Your registration was not approved. Contact support for more information.',
      data: {'route': isApproved ? '/home' : '/login'},
    );
  }

  /// Create system notification
  Future<void> notifySystem({
    required String uid,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    await createNotification(
      uid: uid,
      type: NotificationType.system,
      title: title,
      body: body,
      data: data,
    );
  }
}
