import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level tap handler — must be a top-level function.
@pragma('vm:entry-point')
void _onNotificationResponse(NotificationResponse details) {
  debugPrint('Notification tapped id=${details.id}');
}

/// Drives system-tray notifications purely through Firestore.
///
/// No Firebase Cloud Messaging and no Cloud Functions are used.
///
/// How it works:
///   1. Another user's device writes a doc to the `notifications` Firestore
///      collection (e.g. ConversationService does this when a message is sent).
///   2. This service keeps a real-time listener on that collection filtered
///      to the currently signed-in user.
///   3. When a new doc appears it calls flutter_local_notifications to show
///      a heads-up notification in the device status bar.
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Tracks whether the plugin has been initialised in this Dart isolate.
  static bool _localNotificationsInitialized = false;

  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _notificationListenerSubscription;

  bool _notificationListenerInitialized = false;
  String? _lastListeningUid;
  final Set<String> _knownNotificationIds = {};

  // ─────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────

  /// Call once from main() before runApp().
  Future<void> initialize() async {
    await _initLocalNotifications();
    await _requestNotificationPermission();

    // authStateChanges() emits immediately with the current user on startup,
    // so a user who was already signed in gets their listener started right
    // away without any extra checks.
    _authStateSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startFirestoreNotificationListener(user.uid);
      } else {
        _stopFirestoreNotificationListener();
      }
    });
  }

  /// Show a notification in the system tray immediately.
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    if (!_localNotificationsInitialized) {
      await _initLocalNotifications();
    }
    await _localNotifications.show(
      // Rolling ID so successive notifications don't replace each other.
      DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'academe_notifications',
          'AcadeME Notifications',
          channelDescription: 'Notifications for AcadeME',
          importance: Importance.max, // triggers the heads-up (peeking) banner
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  void dispose() {
    _authStateSubscription?.cancel();
    _notificationListenerSubscription?.cancel();
  }

  // ─────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    // Create (or update) the high-importance Android notification channel.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'academe_notifications',
            'AcadeME Notifications',
            description: 'Notifications for AcadeME',
            importance: Importance.high,
          ),
        );
    _localNotificationsInitialized = true;
  }

  Future<void> _requestNotificationPermission() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      // Required for Android 13+ (API 33+).
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Subscribe to Firestore `notifications` for [uid] and show a local
  /// notification each time a new doc is added by another user.
  void _startFirestoreNotificationListener(String uid) {
    // Guard: don't restart if we're already listening for this user.
    if (_notificationListenerInitialized && _lastListeningUid == uid) return;

    _lastListeningUid = uid;
    _notificationListenerSubscription?.cancel();
    _notificationListenerInitialized = false;
    _knownNotificationIds.clear();

    _notificationListenerSubscription = _firestore
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (!_notificationListenerInitialized) {
          // First emission — baseline: record all existing doc IDs so we
          // do NOT show notifications for old entries on app launch.
          for (final doc in snapshot.docs) {
            _knownNotificationIds.add(doc.id);
          }
          _notificationListenerInitialized = true;
          return;
        }

        // Subsequent emissions — act only on newly added docs.
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
      },
      onError: (Object e) {
        debugPrint('FCMService: Firestore listener error: $e');
        // Reset so the listener restarts on the next auth-state change.
        _notificationListenerInitialized = false;
      },
    );
  }

  void _stopFirestoreNotificationListener() {
    _notificationListenerSubscription?.cancel();
    _notificationListenerInitialized = false;
    _lastListeningUid = null;
    _knownNotificationIds.clear();
  }
}
