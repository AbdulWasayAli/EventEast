import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../widgets/premium_ui.dart';

class UnifiedProfileScreen extends StatefulWidget {
  final String userRole;
  final String userName;
  final String userEmail;

  const UnifiedProfileScreen({
    super.key,
    this.userRole = 'User',
    this.userName = '',
    this.userEmail = '',
  });

  @override
  State<UnifiedProfileScreen> createState() => _UnifiedProfileScreenState();
}

class _UnifiedProfileScreenState extends State<UnifiedProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoggingOut = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  String _role = 'User';
  String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();

    _role = widget.userRole;

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        _loadFallbackProfile();
        return;
      }

      String name = '';
      String email = user.email?.trim() ?? '';
      String phone = '';
      String role = widget.userRole;
      String profileImage = user.photoURL?.trim() ?? '';

      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('Users').doc(user.uid).get();

      if (!snapshot.exists) {
        final QuerySnapshot<Map<String, dynamic>> result = await _firestore
            .collection('Users')
            .where('UserId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (result.docs.isNotEmpty) {
          snapshot = result.docs.first;
        }
      }

      if (snapshot.exists) {
        final Map<String, dynamic> data =
            snapshot.data() ?? <String, dynamic>{};

        name = _getString(data['Name']);

        final String firestoreEmail = _getString(data['Email']);
        if (firestoreEmail.isNotEmpty) {
          email = firestoreEmail;
        }

        for (final key in const [
          'Phone',
          'phone',
          'ContactNumber',
          'contactNumber',
          'MobileNumber',
          'mobileNumber',
        ]) {
          final value = _getString(data[key]);
          if (value.isNotEmpty) {
            phone = value;
            break;
          }
        }

        final String firestoreRole = _getString(data['Role']);
        if (firestoreRole.isNotEmpty) {
          role = firestoreRole;
        }

        final String firestoreImage = _getString(data['ProfileImage']);
        if (firestoreImage.isNotEmpty) {
          profileImage = firestoreImage;
        }
      }

      if (name.isEmpty) {
        name = user.displayName?.trim() ?? '';
      }

      if (name.isEmpty) {
        name = widget.userName.trim();
      }

      if (name.isEmpty && email.isNotEmpty) {
        name = _nameFromEmail(email);
      }

      if (name.isEmpty) {
        name = 'User';
      }

      if (email.isEmpty) {
        email = widget.userEmail.trim();
      }

      if (email.isEmpty) {
        email = 'No email available';
      }

      if (role.isEmpty) {
        role = widget.userRole.trim().isNotEmpty
            ? widget.userRole.trim()
            : 'Attendee';
      }

      if (!mounted) return;

      setState(() {
        _nameController.text = name;
        _phoneController.text = phone;
        _emailController.text = email;

        _role = role;
        _profileImageUrl = profileImage;

        _isLoading = false;
      });

      try {
        if (name.isNotEmpty && name != 'User' && user.displayName != name) {
          await user.updateDisplayName(name);
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('PROFILE LOAD ERROR: $e');
      if (!mounted) return;
      _loadFallbackProfile();
    }
  }


  void _loadFallbackProfile() {
    final User? user = _auth.currentUser;

    String name = user?.displayName?.trim() ?? '';
    String email = user?.email?.trim() ?? '';

    if (name.isEmpty) {
      name = widget.userName.trim();
    }

    if (email.isEmpty) {
      email = widget.userEmail.trim();
    }

    if (name.isEmpty && email.isNotEmpty) {
      name = _nameFromEmail(email);
    }

    if (name.isEmpty) {
      name = 'User';
    }

    if (email.isEmpty) {
      email = 'No email available';
    }

    if (!mounted) return;

    setState(() {
      _nameController.text = name;
      _emailController.text = email;
      _phoneController.text = '';

      _role = widget.userRole.trim().isNotEmpty
          ? widget.userRole.trim()
          : 'Attendee';

      _profileImageUrl = user?.photoURL?.trim() ?? '';

      _isLoading = false;
    });
  }

  String _getString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  String _nameFromEmail(String email) {
    final String value = email.trim();

    if (value.isEmpty || !value.contains('@')) {
      return '';
    }

    String name = value.split('@').first.trim();

    if (name.isEmpty) {
      return '';
    }

    name = name.replaceAll(RegExp(r'[._\-]+'), ' ');

    name = name
        .split(' ')
        .where((item) => item.isNotEmpty)
        .map((item) =>
            item[0].toUpperCase() + item.substring(1).toLowerCase())
        .join(' ');

    return name;
  }
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      _showSnackBar('User is not logged in.', isError: true);
      return;
    }

    if (_isSaving) {
      return;
    }

    final String name = _nameController.text.trim();
    final String phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Please enter your name.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String email = user.email?.trim() ?? '';

      if (email.isEmpty) {
        email = _emailController.text.trim();
      }

      await _firestore.collection('Users').doc(user.uid).set(
        {
          'Name': name,
          'Email': email,
          'Phone': phone,
          'ProfileImage': _profileImageUrl,
          'Role': _role,
          'UserId': user.uid,
          'Status': 'Active',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (user.displayName != name) {
        await user.updateDisplayName(name);
      }

      await user.reload();

      if (!mounted) return;

      setState(() {
        _nameController.text = name;
        _emailController.text = email;
      });

      _showSnackBar('Profile updated successfully!');
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.message ?? 'Could not update profile.',
        isError: true,
      );
    } catch (e) {
      debugPrint('SAVE PROFILE ERROR: $e');

      if (!mounted) return;

      _showSnackBar('Could not update profile.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final User? user = _auth.currentUser;
    debugPrint('▶ _pickProfileImage called (Cloudinary), user: ${user?.uid}');

    if (user == null) {
      _showSnackBar('User is not logged in.', isError: true);
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      debugPrint('▶ Opening gallery picker...');

      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      debugPrint('▶ Picker returned: ${pickedImage?.path}');

      if (pickedImage == null) {
        debugPrint('▶ User cancelled picker');
        return;
      }

      if (!mounted) return;

      setState(() {
        _isUploadingImage = true;
      });

      final File imageFile = File(pickedImage.path);
      final bool fileExists = await imageFile.exists();
      final int fileSize = fileExists ? await imageFile.length() : 0;
      debugPrint('▶ File exists: $fileExists, size: $fileSize bytes');

      if (!fileExists || fileSize == 0) {
        _showSnackBar('Selected image file not found.', isError: true);
        return;
      }

      debugPrint('▶ Uploading to Cloudinary...');

      final Uri uri = Uri.parse('https://api.cloudinary.com/v1_1/don1e4hj5/image/upload');
      final http.MultipartRequest request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = 'flutter_upload';
      request.files.add(await http.MultipartFile.fromPath('file', pickedImage.path));

      final http.StreamedResponse response = await request.send();
      final String responseData = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        debugPrint('▶ Cloudinary error: $responseData');
        if (!mounted) return;

        String errorMessage = 'Could not upload image to Cloudinary.';
        try {
          final Map<String, dynamic> errJson = jsonDecode(responseData);
          if (errJson['error'] != null && errJson['error']['message'] != null) {
            errorMessage = errJson['error']['message'];
          }
        } catch (_) {}

        _showSnackBar(errorMessage, isError: true);
        return;
      }

      final Map<String, dynamic> jsonData = jsonDecode(responseData);
      final String downloadUrl = jsonData['secure_url'];
      debugPrint('▶ Download URL: $downloadUrl');

      await _firestore.collection('Users').doc(user.uid).set(
        {
          'ProfileImage': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('▶ Firestore updated');

      await user.updatePhotoURL(downloadUrl);
      debugPrint('▶ Auth photoURL updated');

      if (!mounted) return;

      setState(() {
        _profileImageUrl = downloadUrl;
      });

      _showSnackBar('Profile image updated successfully!');
    } on FirebaseException catch (e) {
      debugPrint('▶ FIREBASE ERROR: ${e.code} - ${e.message}');
      if (!mounted) return;

      _showSnackBar(
        e.message ?? 'Could not save profile image URL.',
        isError: true,
      );
    } catch (e, stackTrace) {
      debugPrint('▶ IMAGE UPLOAD ERROR: $e');
      debugPrint('▶ STACK TRACE: $stackTrace');

      if (!mounted) return;

      _showSnackBar('Could not upload profile image.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _removeProfileImage() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    if (_profileImageUrl.isEmpty) {
      return;
    }

    try {
      await _firestore.collection('Users').doc(user.uid).set(
        {
          'ProfileImage': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await user.updatePhotoURL(null);

      if (!mounted) return;

      setState(() {
        _profileImageUrl = '';
      });

      _showSnackBar('Profile image removed.');
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.message ?? 'Could not remove profile image.',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar('Could not remove profile image.', isError: true);
    }
  }


  void _showProfileImageOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF007E7B),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    _pickProfileImage();
                  },
                ),

                if (_profileImageUrl.isNotEmpty)
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    title: Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(sheetContext);

                      _removeProfileImage();
                    },
                  ),

                ListTile(
                  leading: Icon(
                    Icons.close_rounded,
                    color: Colors.blueGrey,
                  ),
                  title: Text('Cancel'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

 
  Future<void> _sendPasswordResetEmail() async {
    final String email = _auth.currentUser?.email?.trim() ?? '';
    if (email.isEmpty) {
      _showSnackBar('No email address is available for this account.', isError: true);
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showSnackBar('Password reset link has been sent to $email.');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message ?? 'Could not send the reset email.', isError: true);
    }
  }





  Widget _buildProfileAvatar({required double radius}) {
    final String name = _nameController.text.trim();
    final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    Widget avatarInner;
    if (_profileImageUrl.isEmpty) {
      avatarInner = CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFF0FDF9),
        child: Text(
          firstLetter,
          style: TextStyle(
            fontSize: radius * 0.72,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF007E7B),
          ),
        ),
      );
    } else {
      avatarInner = CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFF1F5F9),
        child: ClipOval(
          child: Image.network(
            _profileImageUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) {
              return Container(
                width: radius * 2,
                height: radius * 2,
                color: const Color(0xFFF0FDF9),
                alignment: Alignment.center,
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    fontSize: radius * 0.72,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF007E7B),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF00A896), Color(0xFF00524F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A896).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: avatarInner,
    );
  }


  Widget _sectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : const Color(0xFF007E7B).withValues(alpha: 0.05),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  
  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final fieldBg = readOnly
        ? (isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9))
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
    final fieldBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: readOnly
            ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
            : textColor,
        fontWeight: FontWeight.w600,
        fontSize: 14.5,
      ),
      cursorColor: const Color(0xFF007E7B),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 14, right: 12),
          child: Icon(
            icon,
            color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF007E7B),
            size: 20,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 20),
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: fieldBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: fieldBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF007E7B),
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.8,
          ),
        ),
      ),
    );
  }

  
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
        final bodyColor = isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade600;

        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 10),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: bodyColor),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(80, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    foregroundColor: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade600,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoggingOut
                      ? null
                      : () async {
                          Navigator.of(dialogContext).pop();
                          setState(() => _isLoggingOut = true);
                          try {
                            await _auth.signOut();
                            if (!mounted) return;

                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          } on FirebaseAuthException catch (error) {
                            if (!mounted) return;
                            _showSnackBar(
                              error.message ?? 'Unable to log out. Please try again.',
                              isError: true,
                            );
                          } catch (_) {
                            if (!mounted) return;
                            _showSnackBar(
                              'Unable to log out. Please try again.',
                              isError: true,
                            );
                          } finally {
                            if (mounted) setState(() => _isLoggingOut = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(_isLoggingOut ? 'Logging out...' : 'Log Out'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : const Color(0xFF007E7B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final String lowerRole = _role.toLowerCase();

    final Color roleColor = lowerRole == 'admin' || lowerRole == 'super admin'
        ? Colors.purple
        : lowerRole == 'organizer'
            ? const Color(0xFF028090)
            : const Color(0xFF00A896);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textDark = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textMuted = isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade400;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: SettingsStyleAppBar(
        title: 'My Profile',
        actions: [
          IconButton(
            onPressed: _confirmLogout,
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.25)
                          : const Color(0xFF007E7B).withValues(alpha: 0.08),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00A896), Color(0xFF00524F)],
                            ),
                          ),
                          child: _buildProfileAvatar(radius: 50),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _isUploadingImage ? null : _showProfileImageOptions,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF007E7B),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: _isUploadingImage
                                  ? Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.trim().isNotEmpty
                          ? _nameController.text.trim()
                          : 'User',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _emailController.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _role,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _isUploadingImage ? null : _showProfileImageOptions,
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 17,
                      ),
                      label: const Text('Change Profile Photo'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF007E7B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _sectionTitle('Personal Information'),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _textField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      controller: _phoneController,
                      label: 'Contact Number',
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007E7B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Profile Changes',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _sectionTitle('Security & Access'),

              const SizedBox(height: 14),

              Container(
                decoration: _cardDecoration(),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF007E7B),
                  ),
                  title: Text(
                    'Reset Password',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: textMuted,
                  ),
                  onTap: _sendPasswordResetEmail,
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoggingOut ? null : _confirmLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    _isLoggingOut ? 'Logging out...' : 'Log Out from EventEase',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
