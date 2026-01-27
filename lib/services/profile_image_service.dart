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
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child('$uid.jpg');

    final bytes = await file.readAsBytes();
    final snapshot = await ref.putData(bytes);
    return snapshot.ref.getDownloadURL();
  }
}
