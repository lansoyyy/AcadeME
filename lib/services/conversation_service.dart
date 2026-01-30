import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Message types
enum MessageType { text, image, file, system }

extension MessageTypeExtension on MessageType {
  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
      case MessageType.system:
        return 'system';
    }
  }
}

/// Service for handling conversations and messages
class ConversationService {
  ConversationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('conversations');

  /// Stream all conversations where user is a participant
  /// Ordered by last message time (most recent first)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamConversations(
    String uid,
  ) {
    return _conversationsRef
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  /// Get a single conversation by ID
  Future<DocumentSnapshot<Map<String, dynamic>>?> getConversation(
    String conversationId,
  ) async {
    final doc = await _conversationsRef.doc(conversationId).get();
    return doc.exists ? doc : null;
  }

  /// Stream a single conversation
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamConversation(
    String conversationId,
  ) {
    return _conversationsRef.doc(conversationId).snapshots();
  }

  /// Get other participant's UID from a conversation
  String? getOtherParticipantId(
    DocumentSnapshot<Map<String, dynamic>> conversation,
    String currentUid,
  ) {
    final data = conversation.data();
    if (data == null) return null;

    final participants = List<String>.from(data['participants'] ?? []);
    return participants.firstWhere(
      (id) => id != currentUid,
      orElse: () => '',
    );
  }

  /// Get unread count for current user in a conversation
  int getUnreadCount(
    DocumentSnapshot<Map<String, dynamic>> conversation,
    String currentUid,
  ) {
    final data = conversation.data();
    if (data == null) return 0;

    final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
    if (unreadCount == null) return 0;

    return (unreadCount[currentUid] ?? 0) as int;
  }

  /// Stream messages for a conversation
  /// Paginated for performance
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(
    String conversationId, {
    int limit = 50,
  }) {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Load older messages (pagination)
  Future<QuerySnapshot<Map<String, dynamic>>> loadOlderMessages(
    String conversationId, {
    required DocumentSnapshot<Map<String, dynamic>> lastDocument,
    int limit = 50,
  }) async {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastDocument)
        .limit(limit)
        .get();
  }

  /// Send a text message
  Future<void> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String? clientId,
  }) async {
    await _sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      type: MessageType.text,
      text: text,
      clientId: clientId,
    );
  }

  /// Send an image message
  /// Image should already be uploaded to Storage, pass the URL
  Future<void> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String imageUrl,
    String? clientId,
  }) async {
    await _sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      type: MessageType.image,
      mediaUrl: imageUrl,
      clientId: clientId,
    );
  }

  /// Send a file message
  Future<void> sendFileMessage({
    required String conversationId,
    required String senderId,
    required String fileUrl,
    required String fileName,
    int? fileSize,
    String? clientId,
  }) async {
    await _sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      type: MessageType.file,
      mediaUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      clientId: clientId,
    );
  }

  /// Core method to send any message type
  Future<void> _sendMessage({
    required String conversationId,
    required String senderId,
    required MessageType type,
    String? text,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    String? clientId,
  }) async {
    final conversationRef = _conversationsRef.doc(conversationId);

    // Get conversation to find other participant
    final conversationDoc = await conversationRef.get();
    if (!conversationDoc.exists) {
      throw Exception('Conversation not found');
    }

    final conversationData = conversationDoc.data()!;
    final participants = List<String>.from(conversationData['participants'] ?? []);
    final otherParticipantId = participants.firstWhere(
      (id) => id != senderId,
      orElse: () => '',
    );

    if (otherParticipantId.isEmpty) {
      throw Exception('Other participant not found');
    }

    // Generate client ID if not provided (for idempotency)
    final messageClientId = clientId ?? '${senderId}_${DateTime.now().millisecondsSinceEpoch}';

    // Use transaction to ensure atomic write
    await _firestore.runTransaction((transaction) async {
      // Create message
      final messageRef = conversationRef.collection('messages').doc();
      final now = FieldValue.serverTimestamp();

      transaction.set(messageRef, {
        'senderId': senderId,
        'type': type.value,
        'text': text,
        'mediaUrl': mediaUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'createdAt': now,
        'clientId': messageClientId,
      });

      // Update conversation
      final lastMessage = <String, dynamic>{
        'text': type == MessageType.text ? text : _getLastMessagePreview(type, fileName),
        'senderId': senderId,
        'createdAt': now,
        'type': type.value,
      };

      transaction.update(conversationRef, {
        'lastMessage': lastMessage,
        'lastMessageAt': now,
        'updatedAt': now,
        'unreadCount.$otherParticipantId': FieldValue.increment(1),
      });
    });
  }

  /// Mark messages as read for current user
  Future<void> markAsRead({
    required String conversationId,
    required String uid,
  }) async {
    final conversationRef = _conversationsRef.doc(conversationId);

    await conversationRef.update({
      'unreadCount.$uid': 0,
    });

    // Also update read receipt
    final readRef = conversationRef.collection('reads').doc(uid);
    await readRef.set({
      'lastReadAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get read receipt for a user
  Future<DateTime?> getLastReadAt(
    String conversationId,
    String uid,
  ) async {
    final readDoc = await _conversationsRef
        .doc(conversationId)
        .collection('reads')
        .doc(uid)
        .get();

    if (!readDoc.exists) return null;

    final data = readDoc.data()!;
    final timestamp = data['lastReadAt'];
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  /// Stream read receipts for real-time updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamReadReceipt(
    String conversationId,
    String uid,
  ) {
    return _conversationsRef
        .doc(conversationId)
        .collection('reads')
        .doc(uid)
        .snapshots();
  }

  /// Get preview text for last message based on type
  String _getLastMessagePreview(MessageType type, String? fileName) {
    switch (type) {
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 ${fileName ?? 'File'}';
      case MessageType.system:
        return '';
      case MessageType.text:
        return '';
    }
  }

  /// Delete a conversation (soft delete - mark as inactive)
  Future<void> deleteConversation(String conversationId) async {
    await _conversationsRef.doc(conversationId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get total unread count across all conversations for a user
  Future<int> getTotalUnreadCount(String uid) async {
    final snapshot = await _conversationsRef
        .where('participants', arrayContains: uid)
        .where('isActive', isEqualTo: true)
        .get();

    int total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
      if (unreadCount != null) {
        total += (unreadCount[uid] ?? 0) as int;
      }
    }
    return total;
  }

  /// Stream total unread count (real-time)
  Stream<int> streamTotalUnreadCount(String uid) {
    return _conversationsRef
        .where('participants', arrayContains: uid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
        if (unreadCount != null) {
          total += (unreadCount[uid] ?? 0) as int;
        }
      }
      return total;
    });
  }
}

/// Model class for a conversation
class Conversation {
  final String id;
  final String type;
  final String? matchId;
  final List<String> participants;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final LastMessage? lastMessage;
  final Map<String, int> unreadCount;
  final bool isActive;

  Conversation({
    required this.id,
    required this.type,
    this.matchId,
    required this.participants,
    this.createdAt,
    this.updatedAt,
    this.lastMessage,
    required this.unreadCount,
    required this.isActive,
  });

  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Conversation(
      id: doc.id,
      type: data['type'] ?? 'match_chat',
      matchId: data['matchId'] as String?,
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      lastMessage: data['lastMessage'] != null
          ? LastMessage.fromMap(data['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: Map<String, int>.from(
        (data['unreadCount'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            ) ??
            {},
      ),
      isActive: data['isActive'] ?? true,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// Model for last message in a conversation
class LastMessage {
  final String text;
  final String senderId;
  final DateTime? createdAt;
  final String type;

  LastMessage({
    required this.text,
    required this.senderId,
    this.createdAt,
    required this.type,
  });

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      createdAt: Conversation._parseDateTime(map['createdAt']),
      type: map['type'] ?? 'text',
    );
  }
}

/// Model class for a message
class Message {
  final String id;
  final String senderId;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final DateTime? createdAt;
  final String? clientId;

  Message({
    required this.id,
    required this.senderId,
    required this.type,
    this.text,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.createdAt,
    this.clientId,
  });

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      type: _parseMessageType(data['type']),
      text: data['text'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      fileName: data['fileName'] as String?,
      fileSize: data['fileSize'] as int?,
      createdAt: Conversation._parseDateTime(data['createdAt']),
      clientId: data['clientId'] as String?,
    );
  }

  static MessageType _parseMessageType(String? value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  bool get isSystem => type == MessageType.system;
  bool get hasMedia => type == MessageType.image || type == MessageType.file;
}
