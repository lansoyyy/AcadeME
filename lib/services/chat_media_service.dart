import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Service for handling chat media uploads (images, files)
class ChatMediaService {
  static final ChatMediaService _instance = ChatMediaService._internal();
  factory ChatMediaService() => _instance;
  ChatMediaService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Generate unique ID using timestamp and random
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${(1000 + DateTime.now().microsecond)}';
  }

  /// Pick an image from the gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Take a photo with the camera
  Future<XFile?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      return photo;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  /// Pick a file (PDF, DOC, etc.)
  Future<XFile?> pickFile() async {
    try {
      // For files, we'll use image picker as a fallback
      // In production, use file_picker package
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      return file;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  /// Upload an image to Firebase Storage
  /// Returns the download URL
  Future<String> uploadImage({
    required String conversationId,
    required XFile file,
    String? messageId,
  }) async {
    try {
      final String messageIdStr = messageId ?? _generateId();
      final String fileName = path.basename(file.path);
      final String extension = path.extension(file.path).toLowerCase();
      
      // Validate image extension
      final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
      if (!validExtensions.contains(extension)) {
        throw Exception('Invalid image format. Supported: ${validExtensions.join(', ')}');
      }

      // Create storage reference: chat_attachments/{conversationId}/{messageId}/{filename}
      final Reference storageRef = _storage.ref().child(
        'chat_attachments/$conversationId/$messageIdStr/$fileName',
      );

      // Upload file
      final UploadTask uploadTask = storageRef.putFile(
        File(file.path),
        SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'conversationId': conversationId,
            'messageId': messageIdStr,
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload a file to Firebase Storage
  /// Returns the download URL and file metadata
  Future<Map<String, dynamic>> uploadFile({
    required String conversationId,
    required XFile file,
    String? messageId,
  }) async {
    try {
      final String messageIdStr = messageId ?? _generateId();
      final String fileName = path.basename(file.path);
      final String extension = path.extension(file.path).toLowerCase();

      // Create storage reference
      final Reference storageRef = _storage.ref().child(
        'chat_attachments/$conversationId/$messageIdStr/$fileName',
      );

      // Get file size
      final File ioFile = File(file.path);
      final int fileSize = await ioFile.length();

      // Upload file
      final UploadTask uploadTask = storageRef.putFile(
        ioFile,
        SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'conversationId': conversationId,
            'messageId': messageIdStr,
            'originalName': fileName,
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return {
        'url': downloadUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'extension': extension,
      };
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Delete a file from storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get content type based on file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get file icon based on extension
  String getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.pdf':
        return '📄';
      case '.doc':
      case '.docx':
        return '📝';
      case '.xls':
      case '.xlsx':
        return '📊';
      case '.ppt':
      case '.pptx':
        return '📽️';
      case '.txt':
        return '📃';
      case '.zip':
      case '.rar':
        return '📦';
      default:
        return '📎';
    }
  }

  /// Format file size to human readable string
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
