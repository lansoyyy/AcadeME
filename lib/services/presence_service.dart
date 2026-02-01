import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Service for tracking user presence and online status
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _heartbeatTimer;
  StreamSubscription<User?>? _authSubscription;

  /// Initialize presence tracking
  void initialize() {
    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startPresenceTracking(user.uid);
      } else {
        _stopPresenceTracking();
      }
    });
  }

  /// Start tracking presence for a user
  void _startPresenceTracking(String uid) {
    // Update status immediately
    _updatePresence(uid);
    
    // Set up periodic heartbeat every 5 minutes
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _updatePresence(uid),
    );

    // Set up disconnect handler
    _setupDisconnectHandler(uid);
  }

  /// Update user's presence timestamp
  Future<void> _updatePresence(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
        'isOnline': true,
      });
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  /// Set up handler for when app disconnects
  void _setupDisconnectHandler(String uid) {
    // Note: In a real production app, you'd use Cloud Functions
    // to handle disconnects reliably. Client-side onDisconnect
    // only works while the app is running.
    // For now, we just track lastActiveAt
  }

  /// Stop presence tracking
  void _stopPresenceTracking() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Manually update presence (call this when app comes to foreground)
  Future<void> updatePresence() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _updatePresence(user.uid);
    }
  }

  /// Mark user as offline (call this when app goes to background)
  Future<void> setOffline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': false,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error setting offline: $e');
      }
    }
  }

  /// Get stream of user's online status
  Stream<bool> streamUserOnlineStatus(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      final data = doc.data();
      if (data == null) return false;
      
      // Check if online flag is set
      final isOnline = data['isOnline'] as bool? ?? false;
      
      // Also check lastActiveAt - if within last 5 minutes, consider online
      final lastActiveAt = data['lastActiveAt'] as Timestamp?;
      if (lastActiveAt != null) {
        final lastActive = lastActiveAt.toDate();
        final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
        if (lastActive.isAfter(fiveMinutesAgo)) {
          return true;
        }
      }
      
      return isOnline;
    });
  }

  /// Get formatted "last seen" text
  String getLastSeenText(DateTime? lastActiveAt) {
    if (lastActiveAt == null) return 'Offline';
    
    final now = DateTime.now();
    final diff = now.difference(lastActiveAt);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return 'Long time ago';
    }
  }

  /// Dispose and clean up
  void dispose() {
    _heartbeatTimer?.cancel();
    _authSubscription?.cancel();
  }
}

/// Widget that wraps the app to handle presence updates
class PresenceWrapper extends StatefulWidget {
  final Widget child;
  
  const PresenceWrapper({
    super.key,
    required this.child,
  });

  @override
  State<PresenceWrapper> createState() => _PresenceWrapperState();
}

class _PresenceWrapperState extends State<PresenceWrapper>
    with WidgetsBindingObserver {
  final PresenceService _presenceService = PresenceService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _presenceService.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - update presence
        _presenceService.updatePresence();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App went to background - set offline
        _presenceService.setOffline();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        _presenceService.setOffline();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
