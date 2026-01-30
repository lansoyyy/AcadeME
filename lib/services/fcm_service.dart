import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Service for handling Firebase Cloud Messaging (FCM) push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
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
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('FCM: User granted provisional permission');
    } else {
      debugPrint('FCM: User declined permission');
    }
  }

  /// Setup FCM token and listeners
  Future<void> _setupFCM() async {
    // Get initial token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    // Listen for token refresh
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

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM: Foreground message received');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Notification: ${message.notification?.title}');
      // Show local notification or in-app toast
      _showInAppNotification(message);
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
    // Simplified platform detection
    // In production, use dart:io Platform or package_info_plus
    return 'unknown';
  }

  /// Cleanup
  void dispose() {
    _tokenRefreshSubscription?.cancel();
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
