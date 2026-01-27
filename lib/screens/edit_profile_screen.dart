import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/profile_image_service.dart';
import '../services/user_profile_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  bool _isLoading = false;
  bool _initialized = false;

  XFile? _pickedPhoto;
  Uint8List? _pickedPhotoBytes;
  String _photoUrl = '';

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _birthdayController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    XFile? file;
    if (source == 'camera') {
      file = await ProfileImageService().pickFromCamera();
    } else {
      file = await ProfileImageService().pickFromGallery();
    }

    if (file == null) return;
    final bytes = await file.readAsBytes();

    if (!mounted) return;
    setState(() {
      _pickedPhoto = file;
      _pickedPhotoBytes = bytes;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text =
            "${picked.month}/${picked.day}/${picked.year}";
      });
    }
  }

  Future<void> _onSave(UserProfile currentProfile) async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You are not logged in.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String photoUrl = _photoUrl;
      if (_pickedPhoto != null) {
        photoUrl = await ProfileImageService().uploadProfileImage(
          uid: uid,
          file: _pickedPhoto!,
        );
      }

      final updated = UserProfile(
        uid: uid,
        fullName: _nameController.text.trim(),
        studentId: _idController.text.trim(),
        birthday: _birthdayController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        photoUrl: photoUrl,
      );

      await UserProfileService().upsertProfile(updated);

      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    IconData? suffixIcon,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.black)
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('You are not logged in.')),
      );
    }

    return StreamBuilder<UserProfile?>(
      stream: UserProfileService().streamProfile(uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Profile not found.')),
          );
        }

        if (!_initialized) {
          _nameController.text = profile.fullName;
          _idController.text = profile.studentId;
          _birthdayController.text = profile.birthday;
          _ageController.text = profile.age.toString();
          _photoUrl = profile.photoUrl;
          _initialized = true;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const Text(
              'Edit Profile',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.backgroundLight,
                                image: _pickedPhotoBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(_pickedPhotoBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : (_photoUrl.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(_photoUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null),
                              ),
                              child:
                                  (_pickedPhotoBytes == null &&
                                      _photoUrl.isEmpty)
                                  ? const Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 56,
                                        color: Colors.black54,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickPhoto,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXL),
                    _buildLabel('Full Name'),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Enter your full name',
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    _buildLabel('Student ID Number'),
                    _buildTextField(
                      controller: _idController,
                      hint: 'Enter your ID number',
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    _buildLabel('Birthday'),
                    _buildTextField(
                      controller: _birthdayController,
                      hint: 'mm/dd/yyyy',
                      suffixIcon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    _buildLabel('Age'),
                    _buildTextField(
                      controller: _ageController,
                      hint: 'Enter your age',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppConstants.paddingXL),
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: () => _onSave(profile),
                      fullWidth: true,
                      type: ButtonType.primary,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
