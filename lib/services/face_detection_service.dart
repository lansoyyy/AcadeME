import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

/// Service for detecting faces in profile photos
class FaceDetectionService {
  static final FaceDetectionService _instance =
      FaceDetectionService._internal();
  factory FaceDetectionService() => _instance;
  FaceDetectionService._internal();

  /// Validates that the given image file contains exactly one face.
  /// Returns a [FaceValidationResult] with success/failure info.
  Future<FaceValidationResult> validateFace(XFile imageFile) async {
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      ),
    );

    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return FaceValidationResult(
          isValid: false,
          message: 'No face detected. Please take a clear photo of your face.',
          faceCount: 0,
        );
      }

      if (faces.length > 1) {
        return FaceValidationResult(
          isValid: false,
          message:
              'Multiple faces detected. Please use a photo with only your face.',
          faceCount: faces.length,
        );
      }

      // Single face found — check quality
      final face = faces.first;

      // Check if face is large enough (at least 15% of the image)
      final boundingBox = face.boundingBox;
      if (boundingBox.width < 50 || boundingBox.height < 50) {
        return FaceValidationResult(
          isValid: false,
          message: 'Face is too small. Please take a closer photo.',
          faceCount: 1,
        );
      }

      // Check head rotation — reject extreme angles
      final headAngleY = face.headEulerAngleY ?? 0;
      final headAngleZ = face.headEulerAngleZ ?? 0;
      if (headAngleY.abs() > 36 || headAngleZ.abs() > 36) {
        return FaceValidationResult(
          isValid: false,
          message:
              'Please face the camera directly. Avoid tilting your head too much.',
          faceCount: 1,
        );
      }

      return FaceValidationResult(
        isValid: true,
        message: 'Face detected successfully!',
        faceCount: 1,
      );
    } catch (e) {
      return FaceValidationResult(
        isValid: false,
        message: 'Could not process image. Please try again.',
        faceCount: 0,
      );
    } finally {
      faceDetector.close();
    }
  }
}

/// Result of face validation
class FaceValidationResult {
  final bool isValid;
  final String message;
  final int faceCount;

  const FaceValidationResult({
    required this.isValid,
    required this.message,
    required this.faceCount,
  });
}
