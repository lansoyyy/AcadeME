import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/academic_data_service.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../services/profile_image_service.dart';
import '../services/user_profile_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'auth/login_screen.dart';

class ProfileCreationScreen extends StatefulWidget {
  final bool canGoBack;
  const ProfileCreationScreen({super.key, this.canGoBack = true});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _selectedTrack = '';
  int _selectedGradeLevel = 11;
  final List<String> _selectedSubjects = [];

  final AcademicDataService _academicService = AcademicDataService();

  // Academic data from Firestore
  List<String> _tracks = [];
  List<int> _gradeLevels = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoadingAcademicData = true;

  bool _isLoading = false;
  bool _obscure = true;

  XFile? _pickedPhoto;
  Uint8List? _pickedPhotoBytes;

  @override
  void initState() {
    super.initState();
    _loadAcademicData();
  }

  Future<void> _loadAcademicData() async {
    try {
      final [tracksData, gradeLevelsData, subjectsData] = await Future.wait([
        _academicService.getStrands(),
        _academicService.getGradeLevels(),
        _academicService.getSubjects(),
      ]);

      setState(() {
        _tracks = tracksData.map((s) => s['name'] as String).toList();
        _gradeLevels = gradeLevelsData.map((g) => g['value'] as int).toList();
        _subjects = subjectsData;
        _isLoadingAcademicData = false;
      });
    } catch (e) {
      debugPrint('Error loading academic data: $e');
      setState(() => _isLoadingAcademicData = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _idController.dispose();
    _birthdayController.dispose();
    _ageController.dispose();
    _bioController.dispose();
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

  Future<void> _onNext() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    String? uid = currentUser?.uid;

    setState(() {
      _isLoading = true;
    });

    try {
      if (uid == null) {
        final credential = await AuthService().register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        uid = credential.user?.uid;
      }

      if (uid == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'Failed to create account.',
        );
      }

      String photoUrl = '';
      if (_pickedPhoto != null) {
        photoUrl = await ProfileImageService().uploadProfileImage(
          uid: uid,
          file: _pickedPhoto!,
        );
      }

      final profile = UserProfile(
        uid: uid,
        fullName: _nameController.text.trim(),
        studentId: _idController.text.trim(),
        birthday: _birthdayController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        photoUrl: photoUrl,
        track: _selectedTrack,
        gradeLevel: _selectedGradeLevel,
        subjectsInterested: _selectedSubjects,
        bio: _bioController.text.trim(),
        isDiscoverable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await UserProfileService().upsertProfile(profile);

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to create account.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save profile.')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          "Let's Get Started",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
                if (!isLoggedIn) ...[
                  _buildLabel('Email'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      hintStyle: const TextStyle(color: AppColors.textLight),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingM,
                        vertical: AppConstants.paddingM,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  _buildLabel('Password'),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Create a password',
                      hintStyle: const TextStyle(color: AppColors.textLight),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingM,
                        vertical: AppConstants.paddingM,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final v = value ?? '';
                      if (v.isEmpty) return 'Password is required';
                      if (v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  _buildLabel('Confirm Password'),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Re-enter your password',
                      hintStyle: const TextStyle(color: AppColors.textLight),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingM,
                        vertical: AppConstants.paddingM,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final v = value ?? '';
                      if (v.isEmpty) return 'Confirm your password';
                      if (v != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingXL),
                ],

                // Progress Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressStep(true),
                    const SizedBox(width: 8),
                    _buildProgressStep(false),
                    const SizedBox(width: 8),
                    _buildProgressStep(false),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingXL),

                // Profile Picture Placeholder
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
                                : null,
                          ),
                          child: _pickedPhotoBytes == null
                              ? const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 52,
                                    color: Colors.black54,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: GestureDetector(
                            onTap: _pickPhoto,
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
                const SizedBox(height: AppConstants.paddingS),
                const Center(
                  child: Text(
                    'Add a Profile Picture',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingXL),

                // Form Fields
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
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: _buildTextField(
                      controller: _birthdayController,
                      hint: 'mm/dd/yyyy',
                      suffixIcon: Icons.calendar_today_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),

                _buildLabel('Age'),
                _buildTextField(
                  controller: _ageController,
                  hint: 'Enter your age',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppConstants.paddingM),

                // Track Selection
                _buildLabel('Track'),
                _buildDropdownField<String>(
                  value: _selectedTrack.isEmpty ? null : _selectedTrack,
                  hint: 'Select your track',
                  items: _tracks,
                  onChanged: (value) {
                    setState(() => _selectedTrack = value ?? '');
                  },
                ),
                const SizedBox(height: AppConstants.paddingM),

                // Grade Level Selection
                _buildLabel('Grade Level'),
                _buildDropdownField<int>(
                  value: _selectedGradeLevel,
                  hint: 'Select grade level',
                  items: _gradeLevels,
                  onChanged: (value) {
                    setState(() => _selectedGradeLevel = value ?? 11);
                  },
                ),
                const SizedBox(height: AppConstants.paddingM),

                // Bio
                _buildLabel('Bio'),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Tell us about yourself and what you\'re looking for...',
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(AppConstants.paddingM),
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
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),

                // Subjects Interested
                _buildLabel('Subjects Interested In'),
                _isLoadingAcademicData
                    ? const Center(child: CircularProgressIndicator())
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _subjects.take(20).map<Widget>((subject) {
                          final name = subject['name'] ?? '';
                          final isSelected = _selectedSubjects.contains(name);
                          return FilterChip(
                            label: Text(name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSubjects.add(name);
                                } else {
                                  _selectedSubjects.remove(name);
                                }
                              });
                            },
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primary,
                          );
                        }).toList(),
                      ),
                const SizedBox(height: AppConstants.paddingXL),

                // Next Button
                CustomButton(
                  text: isLoggedIn ? 'Next' : 'Create Account',
                  onPressed: _onNext,
                  fullWidth: true,
                  type: ButtonType.primary,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppConstants.paddingL),

                if (!isLoggedIn)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Already have an account? Login',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(bool isActive) {
    return Container(
      width: 40,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(3),
      ),
    );
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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

  Widget _buildDropdownField<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: AppColors.textLight)),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
