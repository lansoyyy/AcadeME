import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageService {
  final ImagePicker _picker;

  ProfileImageService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  Future<XFile?> pickFromGallery() {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  }

  Future<XFile?> pickFromCamera() {
    return _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
  }

  Future<String> uploadProfileImage({
    required String uid,
    required XFile file,
  }) async {
    // Use folder-based path: profile_photos/{uid}/profile.jpg
    // This ensures the {userId} wildcard in storage rules matches
    // the uid exactly (not "uid.jpg"), so isOwner() works correctly.
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child(uid)
        .child('profile.jpg');

    final bytes = await file.readAsBytes();
    final snapshot = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return snapshot.ref.getDownloadURL();
  }
}
