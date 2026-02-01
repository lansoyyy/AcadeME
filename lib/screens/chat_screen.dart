import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/conversation_service.dart';
import '../services/chat_media_service.dart';
import '../services/swipe_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final UserProfile otherUser;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ConversationService _conversationService = ConversationService();
  final ChatMediaService _mediaService = ChatMediaService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? _currentUid;
  bool _isSending = false;
  bool _isUploadingImage = false;
  List<DocumentSnapshot<Map<String, dynamic>>> _messages = [];

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    if (_currentUid == null) return;
    await _conversationService.markAsRead(
      conversationId: widget.conversationId,
      uid: _currentUid!,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUid == null || _isSending) return;

    setState(() => _isSending = true);

    try {
      await _conversationService.sendTextMessage(
        conversationId: widget.conversationId,
        senderId: _currentUid!,
        text: text,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.backgroundLight,
              backgroundImage: widget.otherUser.photoUrl.isNotEmpty
                  ? NetworkImage(widget.otherUser.photoUrl)
                  : null,
              child: widget.otherUser.photoUrl.isEmpty
                  ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.fullName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.otherUser.track.isNotEmpty
                        ? '${widget.otherUser.track} • Grade ${widget.otherUser.gradeLevel}'
                        : 'Online',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog();
              } else if (value == 'block') {
                _showBlockDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _conversationService.streamMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                _messages = snapshot.data?.docs ?? [];

                if (_messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageItem(message);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            'Start chatting with ${widget.otherUser.fullName}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            'Say hello and plan your study session!',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(DocumentSnapshot<Map<String, dynamic>> messageDoc) {
    final data = messageDoc.data()!;
    final senderId = data['senderId'] as String;
    final type = data['type'] as String;
    final text = data['text'] as String?;
    final mediaUrl = data['mediaUrl'] as String?;
    final isMe = senderId == _currentUid;
    final isSystem = type == 'system';

    if (isSystem) {
      return _buildSystemMessage(text ?? '');
    }

    if (type == 'image' && mediaUrl != null) {
      return _buildImageMessage(mediaUrl, isMe);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.backgroundLight,
              backgroundImage: widget.otherUser.photoUrl.isNotEmpty
                  ? NetworkImage(widget.otherUser.photoUrl)
                  : null,
              child: widget.otherUser.photoUrl.isEmpty
                  ? const Icon(Icons.person, color: AppColors.primary, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0, left: 4),
                    child: Text(
                      widget.otherUser.fullName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                    ),
                    boxShadow: [
                      if (!isMe)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: Text(
                    text ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(String imageUrl, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.backgroundLight,
              backgroundImage: widget.otherUser.photoUrl.isNotEmpty
                  ? NetworkImage(widget.otherUser.photoUrl)
                  : null,
              child: widget.otherUser.photoUrl.isEmpty
                  ? const Icon(Icons.person, color: AppColors.primary, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0, left: 4),
                    child: Text(
                      widget.otherUser.fullName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () => _showFullImage(imageUrl),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                      maxHeight: 200,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        if (!isMe)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 150,
                          height: 150,
                          color: AppColors.backgroundLight,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 150,
                          height: 150,
                          color: AppColors.backgroundLight,
                          child: const Center(
                            child: Icon(Icons.error, color: AppColors.error),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMessage(String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            GestureDetector(
              onTap: _isUploadingImage ? null : _showAttachmentOptions,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: _isUploadingImage
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: (_isSending || _isUploadingImage) ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (_isSending || _isUploadingImage) ? AppColors.textLight : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _sendImage(fromCamera: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _sendImage(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.textLight),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendImage({required bool fromCamera}) async {
    if (_currentUid == null || _isUploadingImage) return;

    setState(() => _isUploadingImage = true);

    try {
      // Pick image
      final XFile? image = fromCamera
          ? await _mediaService.takePhoto()
          : await _mediaService.pickImageFromGallery();

      if (image == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      // Upload image
      final String imageUrl = await _mediaService.uploadImage(
        conversationId: widget.conversationId,
        file: image,
      );

      // Send image message
      await _conversationService.sendImageMessage(
        conversationId: widget.conversationId,
        senderId: _currentUid!,
        imageUrl: imageUrl,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showReportDialog() {
    final reasons = ['Inappropriate content', 'Harassment', 'Fake profile', 'Spam', 'Other'];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Report User'),
        children: reasons.map((reason) {
          return SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              if (_currentUid != null) {
                try {
                  await SwipeService().reportUser(
                    reporterUid: _currentUid!,
                    reportedUid: widget.otherUser.uid,
                    reason: reason,
                    conversationId: widget.conversationId,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error submitting report: $e')),
                    );
                  }
                }
              }
            },
            child: Text(reason),
          );
        }).toList(),
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${widget.otherUser.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_currentUid != null) {
                try {
                  await SwipeService().blockUser(
                    uid: _currentUid!,
                    blockedUid: widget.otherUser.uid,
                  );
                  if (mounted) {
                    Navigator.pop(context); // Go back to matches list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${widget.otherUser.fullName} blocked')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error blocking user: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
