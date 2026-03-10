import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification.dart';
import 'notification_service.dart';

/// Service for handling Firebase Cloud Messaging (FCM) push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _notificationListenerSubscription;
  bool _notificationListenerInitialized = false;
  final Set<String> _knownNotificationIds = {};

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    await _initLocalNotifications();
    await _requestLocalNotificationPermission();
    // Request permission (iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM: User granted permission');
      await _setupFCM();
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('FCM: User granted provisional permission');
      await _setupFCM(); // Still set up FCM for provisional notifications
    } else {
      debugPrint('FCM: User declined permission');
      // Still set up message listeners; token won't deliver alerts but
      // data-only messages and future permission grants will still work.
      await _setupFCM();
    }
  }

  /// Setup FCM token and listeners
  Future<void> _setupFCM() async {
    // Save token immediately if a user is already signed in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }
      _startFirestoreNotificationListener(currentUser.uid);
    }

    // Also save the token whenever a user signs in (covers the case where
    // FCM initialises before login, which is the most common app-start flow).
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      if (user != null) {
        final token = await _messaging.getToken();
        if (token != null) {
          await _saveToken(token);
        }
        _startFirestoreNotificationListener(user.uid);
      } else {
        _notificationListenerSubscription?.cancel();
        _notificationListenerInitialized = false;
        _knownNotificationIds.clear();
      }
    });

    // Listen for token refresh (device token can rotate)
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (newToken) => _saveToken(newToken),
      onError: (err) => debugPrint('FCM Token refresh error: $err'),
    );

    // Setup foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification open (app in background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
  }

  /// Save FCM token to Firestore
  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'token': token,
            'platform': _getPlatform(),
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          });
      debugPrint('FCM: Token saved successfully');
    } catch (e) {
      debugPrint('FCM: Error saving token: $e');
    }
  }

  /// Delete FCM token (on logout)
  Future<void> deleteToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('fcmTokens')
            .doc(token)
            .delete();
      }
      await _messaging.deleteToken();
      debugPrint('FCM: Token deleted');
    } catch (e) {
      debugPrint('FCM: Error deleting token: $e');
    }
  }

  /// Handle foreground messages - shows local notification and saves to Firestore
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('FCM: Foreground message received');
    debugPrint('Message data: ${message.data}');

    final notification = message.notification;
    if (notification != null) {
      debugPrint('Notification: ${notification.title}');

      // Show system tray notification
      await showLocalNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
      );

      // Create notification in Firestore for in-app notification center
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final notificationService = NotificationService();

        final type = _parseNotificationType(message.data['type']);
        await notificationService.createNotification(
          uid: uid,
          type: type,
          title: notification.title ?? 'New Notification',
          body: notification.body ?? '',
          data: Map<String, dynamic>.from(message.data),
        );
      }

      _showInAppNotification(message);
    }
  }

  /// Parse notification type from string
  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'match':
        return NotificationType.match;
      case 'message':
        return NotificationType.message;
      case 'study_session':
        return NotificationType.studySession;
      case 'study_group':
        return NotificationType.studyGroup;
      case 'approval':
        return NotificationType.approval;
      default:
        return NotificationType.system;
    }
  }

  /// Handle notification tap when app is in background
  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('FCM: Notification opened');
    // Navigation handled by the app based on message data
    final data = message.data;
    if (data['conversationId'] != null) {
      // Navigate to specific chat
      // This should be handled by a navigation service or global key
    }
  }

  /// Show in-app notification for foreground messages
  void _showInAppNotification(RemoteMessage message) {
    // This can be implemented using a global overlay or snackbar
    // For now, just log it - the UI will update via streams
    debugPrint('FCM: In-app notification - ${message.notification?.title}');
  }

  /// Update FCM topic subscriptions to match the user's notification preferences.
  /// This lets the server send to topics and reach only users who opted in.
  Future<void> updateTopicSubscriptions({
    required bool newMatches,
    required bool newMessages,
    required bool sessionReminders,
    required bool studyTips,
    required bool marketing,
  }) async {
    final actions = {
      'new_matches': newMatches,
      'new_messages': newMessages,
      'session_reminders': sessionReminders,
      'study_tips': studyTips,
      'marketing': marketing,
    };

    for (final entry in actions.entries) {
      try {
        if (entry.value) {
          await _messaging.subscribeToTopic(entry.key);
        } else {
          await _messaging.unsubscribeFromTopic(entry.key);
        }
      } catch (e) {
        debugPrint('FCM: Error updating topic ${entry.key}: $e');
      }
    }
    debugPrint('FCM: Topic subscriptions updated');
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Get device platform string
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Initialise the flutter_local_notifications plugin and create the
  /// Android notification channel once per app session.
  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // firebase_messaging handles this
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    // Create high-importance channel so heads-up notifications are displayed
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'academe_notifications',
            'AcadeME Notifications',
            description: 'Push notifications for AcadeME',
            importance: Importance.high,
          ),
        );
  }

  Future<void> _requestLocalNotificationPermission() async {
    if (kIsWeb) {
      return;
    }

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return;
    }

    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Show a notification in the system notification tray.
  /// This method is self-contained so it can be called safely from the
  /// background isolate (which has its own plugin instance).
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    // Re-initialise if needed (e.g. background isolate)
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'academe_notifications',
            'AcadeME Notifications',
            description: 'Push notifications for AcadeME',
            importance: Importance.high,
          ),
        );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'academe_notifications',
          'AcadeME Notifications',
          channelDescription: 'Push notifications for AcadeME',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Watch the Firestore notifications collection and surface new documents
  /// as system tray notifications while the app is in the foreground.
  void _startFirestoreNotificationListener(String uid) {
    _notificationListenerSubscription?.cancel();
    _notificationListenerInitialized = false;
    _knownNotificationIds.clear();

    _notificationListenerSubscription = _firestore
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          if (!_notificationListenerInitialized) {
            // First snapshot: record existing IDs without showing anything
            for (final doc in snapshot.docs) {
              _knownNotificationIds.add(doc.id);
            }
            _notificationListenerInitialized = true;
            return;
          }
          // Subsequent snapshots: show system notification for new docs
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added &&
                !_knownNotificationIds.contains(change.doc.id)) {
              _knownNotificationIds.add(change.doc.id);
              final data = change.doc.data()!;
              showLocalNotification(
                title: data['title'] as String? ?? 'New Notification',
                body: data['body'] as String? ?? '',
              );
            }
          }
        });
  }

  /// Cleanup
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _authStateSubscription?.cancel();
    _notificationListenerSubscription?.cancel();
  }
}

/// Model for FCM notification payload
class FCMNotificationPayload {
  final String title;
  final String body;
  final String? conversationId;
  final String? senderId;
  final String? senderName;
  final String? type;

  FCMNotificationPayload({
    required this.title,
    required this.body,
    this.conversationId,
    this.senderId,
    this.senderName,
    this.type,
  });

  factory FCMNotificationPayload.fromMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    return FCMNotificationPayload(
      title: notification?.title ?? '',
      body: notification?.body ?? '',
      conversationId: data['conversationId'] as String?,
      senderId: data['senderId'] as String?,
      senderName: data['senderName'] as String?,
      type: data['type'] as String?,
    );
  }
}
