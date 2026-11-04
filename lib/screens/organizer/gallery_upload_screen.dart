import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_upload_service.dart';

import '../../widgets/premium_ui.dart';

class GalleryUploadScreen extends StatefulWidget {
  const GalleryUploadScreen({super.key, this.eventId});

  final String? eventId;

  @override
  State<GalleryUploadScreen> createState() =>
      _GalleryUploadScreenState();
}

class _GalleryUploadScreenState extends State<GalleryUploadScreen> {


  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final ImagePicker _imagePicker =
  ImagePicker();

 

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController _captionController =
  TextEditingController();

  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    
   
    _selectedEventId = widget.eventId?.trim().isNotEmpty == true
        ? widget.eventId!.trim()
        : null;
  }

  File? _selectedImage;

  bool _isLoading = false;

  double _uploadProgress = 0.0;

 
  static const Color primaryColor =
  Color(0xFF007E7B);

  static const Color darkColor =
  Color(0xFF1E293B);

  
  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

 
  Future<void> _pickImage() async {
    if (_isLoading) return;

    try {
      final XFile? pickedFile =
      await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
      );

      if (pickedFile == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _uploadProgress = 0.0;
      });
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Could not select image: $e',
        isError: true,
      );
    }
  }

  
  Future<void> _takePhoto() async {
    if (_isLoading) return;

    try {
      final XFile? pickedFile =
      await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
      );

      if (pickedFile == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _uploadProgress = 0.0;
      });
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Could not open camera: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // IMAGE SOURCE SHEET
  // ============================================================

  void _showImageSourceSheet() {
    if (_isLoading) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            30,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                SizedBox(height: 24),

                Text(
                  'Select Image',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color ?? darkColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildSourceButton(
                        icon: Icons.photo_library_rounded,
                        title: 'Gallery',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickImage();
                        },
                      ),
                    ),

                    SizedBox(width: 14),

                    Expanded(
                      child: _buildSourceButton(
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _takePhoto();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SOURCE BUTTON
  // ============================================================

  Widget _buildSourceButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primaryColor.withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 28,
              ),
            ),

            SizedBox(height: 10),

            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color ?? darkColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UPLOAD MEDIA
  // ============================================================

  Future<void> _uploadMedia() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) {
      return;
    }

    // ----------------------------------------------------------
    // FORM VALIDATION
    // ----------------------------------------------------------

    final FormState? form =
        _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    // ----------------------------------------------------------
    // EVENT VALIDATION
    // ----------------------------------------------------------

    if (_selectedEventId == null ||
        _selectedEventId!.trim().isEmpty) {
      _showSnackBar(
        'Please select an event.',
        isError: true,
      );
      return;
    }

    // ----------------------------------------------------------
    // IMAGE VALIDATION
    // ----------------------------------------------------------

    if (_selectedImage == null) {
      _showSnackBar(
        'Please select an image.',
        isError: true,
      );
      return;
    }

    // ----------------------------------------------------------
    // USER VALIDATION
    // ----------------------------------------------------------

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar(
        'You must be logged in as an organizer.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      final String eventId =
      _selectedEventId!.trim();

      // ========================================================
      // 1. GET EVENT
      // ========================================================

      final DocumentReference<Map<String, dynamic>>
      eventRef =
      _firestore
          .collection('Events')
          .doc(eventId);

      final DocumentSnapshot<Map<String, dynamic>>
      eventDoc =
      await eventRef.get();

      if (!eventDoc.exists) {
        throw Exception(
          'Selected event was not found.',
        );
      }

      final Map<String, dynamic> eventData =
          eventDoc.data() ?? {};

      // ========================================================
      // 2. VERIFY ORGANIZER
      // ========================================================

      final String organizerId =
          eventData['organizerId']
              ?.toString()
              .trim() ??
              '';

      if (organizerId.isEmpty) {
        throw Exception(
          'This event does not have a valid organizer.',
        );
      }

      if (organizerId != user.uid) {
        throw Exception(
          'You are not authorized to upload media for this event.',
        );
      }

      // ========================================================
      // 3. VERIFY STATUS
      // ========================================================

      final String status =
          eventData['status']
              ?.toString()
              .trim()
              .toLowerCase() ??
              '';

      if (status != 'approved') {
        throw Exception(
          'Gallery photos can only be uploaded for approved events.',
        );
      }

      // ========================================================
      // 4. EVENT TITLE
      // ========================================================

      final String eventTitle =
      eventData['title']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? eventData['title']
          .toString()
          .trim()
          : 'Event';

      // ========================================================
      // 5. UPLOAD IMAGE
      // ========================================================
      //
      // Cloudinary's upload endpoint reports no byte-level progress, so the
      // bar runs indeterminate (_uploadProgress < 0) until the call returns.

      if (!mounted) return;

      setState(() {
        _uploadProgress = -1;
      });

      final String downloadUrl =
      await ImageUploadService.uploadImage(_selectedImage!);

      if (!mounted) return;

      setState(() {
        _uploadProgress = 1.0;
      });

      // ========================================================
      // 10. SAVE TO FIRESTORE
      // ========================================================

      final DocumentReference galleryRef =
      await _firestore
          .collection('gallery')
          .add({
        'eventId': eventId,
        'eventTitle': eventTitle,
        'organizerId': user.uid,
        'imageUrl': downloadUrl,
        'caption':
        _captionController.text.trim(),
        'createdAt':
        FieldValue.serverTimestamp(),
      });

      // ========================================================
      // 11. SUCCESS
      // ========================================================

      debugPrint(
        'Gallery uploaded successfully: ${galleryRef.id}',
      );

      if (!mounted) return;

      _showSuccessDialog(
        eventTitle: eventTitle,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Firebase Error: ${e.message ?? e.code}',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      final String message =
      e.toString().replaceFirst(
        'Exception: ',
        '',
      );

      _showSnackBar(
        'Upload failed: $message',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  void _showSuccessDialog({
    required String eventTitle,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (dialogContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            24,
            28,
            24,
            24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_done_rounded,
                    color: primaryColor,
                    size: 44,
                  ),
                ),

                SizedBox(height: 18),

                Text(
                  'Upload Successful!',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color ?? darkColor,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 10),

                Text(
                  'Your photo has been added to the "$eventTitle" gallery.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isError
              ? Colors.redAccent
              : darkColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String? currentOrganizerId =
        FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: const SettingsStyleAppBar(
        title: 'Upload Event Gallery',
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: currentOrganizerId == null
          ? _buildLoginRequired()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildInfoBanner(),

              SizedBox(height: 28),

              // ==================================================
              // EVENT
              // ==================================================

              _buildLabel(
                'Select Approved Event *',
              ),

              _buildEventDropdown(
                currentOrganizerId,
              ),

              SizedBox(height: 24),

              // ==================================================
              // IMAGE
              // ==================================================

              _buildLabel(
                'Event Photo *',
              ),

              _buildImagePicker(),

              SizedBox(height: 24),

              // ==================================================
              // CAPTION
              // ==================================================

              _buildLabel(
                'Caption / Description',
              ),

              _buildTextField(
                controller:
                _captionController,
                hint:
                'Write a brief description or highlight...',
                maxLines: 4,
              ),

              SizedBox(height: 32),

              // ==================================================
              // PROGRESS
              // ==================================================

              if (_isLoading) ...[
                _buildUploadProgress(),

                SizedBox(height: 20),
              ],

              // ==================================================
              // UPLOAD BUTTON
              // ==================================================

              _buildUploadButton(),

              SizedBox(height: 20),

              Divider(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
                thickness: 1,
                height: 1,
              ),

              SizedBox(height: 20),

              // ==================================================
              // WORKFLOW INFO
              // ==================================================

              _buildStorageInfo(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN REQUIRED
  // ============================================================

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_circle_rounded,
              size: 70,
              color: primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Login Required',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please log in as an organizer to upload event gallery photos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EVENT DROPDOWN
  // ============================================================

  Widget _buildEventDropdown(
      String organizerId,
      ) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('Events')
          .where(
        'organizerId',
        isEqualTo: organizerId,
      )
          .snapshots(),

      builder: (context, snapshot) {
        // --------------------------------------------------------
        // LOADING
        // --------------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
              BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // --------------------------------------------------------
        // ERROR
        // --------------------------------------------------------

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Could not load events. Please check your Firestore rules.',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // --------------------------------------------------------
        // NO DATA
        // --------------------------------------------------------

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return _buildNoEventsBox(
            'No events available for your organizer account.',
          );
        }

        // --------------------------------------------------------
        // ALL EVENTS
        // --------------------------------------------------------

        final List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
        allEvents =
            snapshot.data!.docs;

        // --------------------------------------------------------
        // ONLY APPROVED EVENTS
        // --------------------------------------------------------

        final List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
        approvedEvents =
        allEvents.where((doc) {
          final Map<String, dynamic> data =
          doc.data();

          final String status =
              data['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
                  '';

          return status == 'approved';
        }).toList();

        // --------------------------------------------------------
        // NO APPROVED EVENTS
        // --------------------------------------------------------

        if (approvedEvents.isEmpty) {
          return _buildNoEventsBox(
            'You do not have any approved events available for gallery upload.',
          );
        }

        // --------------------------------------------------------
        // SELECTED EVENT CHECK
        // --------------------------------------------------------

        final bool selectedExists =
        approvedEvents.any(
              (doc) =>
          doc.id == _selectedEventId,
        );

        if (!selectedExists &&
            _selectedEventId != null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            if (!mounted) return;

            setState(() {
              _selectedEventId = null;
            });
          });
        }

        // ========================================================
        // DROPDOWN
        // ========================================================

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007E7B).withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: selectedExists ? _selectedEventId : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
            hint: Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Choose an approved event...',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            icon: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                size: 20,
              ),
            ),
            isExpanded: true,
            dropdownColor: Theme.of(context).cardColor,
            menuMaxHeight: 300,
            items: approvedEvents.map((doc) {
              final Map<String, dynamic> data = doc.data();
              final String title = data['title']?.toString().trim().isNotEmpty == true
                  ? data['title'].toString().trim()
                  : 'Untitled Event';

              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              );
            }).toList(),
            onChanged: _isLoading ? null : (String? value) {
              setState(() {
                _selectedEventId = value;
              });
            },
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please select an event';
              }
              return null;
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // NO EVENTS BOX
  // ============================================================

  Widget _buildNoEventsBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: primaryColor,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO BANNER
  // ============================================================

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.photo_library_rounded,
            color: primaryColor,
            size: 28,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Upload photos and highlights from your approved events. Photos are securely stored in Firebase Storage and linked to the selected event.',
              style: TextStyle(
                color: primaryColor,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _isLoading
          ? null
          : _showImageSourceSheet,
      child: Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
          BorderRadius.circular(20),
          border: Border.all(
            color: _selectedImage == null
                ? Theme.of(context).dividerColor
                : primaryColor.withOpacity(0.4),
            width:
            _selectedImage == null ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A)
                  .withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedImage == null
            ? _buildEmptyImagePicker()
            : Stack(
          fit: StackFit.expand,
          children: [
            // ------------------------------------------------
            // IMAGE
            // ------------------------------------------------

            Image.file(
              _selectedImage!,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.grey,
                    size: 50,
                  ),
                );
              },
            ),

            // ------------------------------------------------
            // REMOVE BUTTON
            // ------------------------------------------------

            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color:
                  Colors.black.withOpacity(
                    0.65,
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                    setState(() {
                      _selectedImage =
                      null;
                      _uploadProgress =
                      0.0;
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // ------------------------------------------------
            // CHANGE IMAGE
            // ------------------------------------------------

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient:
                  LinearGradient(
                    begin:
                    Alignment.topCenter,
                    end:
                    Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black
                          .withOpacity(0.75),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),

                    SizedBox(width: 8),

                    Text(
                      'Tap to change image',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY IMAGE PICKER
  // ============================================================

  Widget _buildEmptyImagePicker() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add_photo_alternate_rounded,
            color: primaryColor,
            size: 42,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Select Event Photo',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Tap here to choose from gallery or camera',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // UPLOAD PROGRESS
  // ============================================================

  Widget _buildUploadProgress() {
    // A negative value means "uploading, progress unknown".
    final bool indeterminate = _uploadProgress < 0;

    final String percentage = indeterminate
        ? 'Uploading'
        : '${(_uploadProgress * 100).clamp(0.0, 100.0).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.06),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload_rounded,
                color: primaryColor,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Uploading image...',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color ?? darkColor,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              Text(
                percentage,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: indeterminate ? null : _uploadProgress,
              minHeight: 7,
              backgroundColor:
              primaryColor.withOpacity(0.1),
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPLOAD BUTTON
  // ============================================================

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
        _isLoading ? null : _uploadMedia,

        icon: _isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child:
          CircularProgressIndicator(
            color: Theme.of(context).cardColor,
            strokeWidth: 2,
          ),
        )
            : Icon(
          Icons.cloud_upload_rounded,
          color: Theme.of(context).cardColor,
        ),

        label: Text(
          _isLoading
              ? 'Uploading...'
              : 'Upload to Gallery',
          style: TextStyle(
            color: Theme.of(context).cardColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor:
          primaryColor.withOpacity(0.5),
          padding:
          const EdgeInsets.symmetric(
            vertical: 18,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),
          elevation: 8,
          shadowColor:
          primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  // ============================================================
  // STORAGE INFO
  // ============================================================

  Widget _buildStorageInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_rounded,
                color: primaryColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Gallery workflow',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _InfoRow(text: 'Only approved events are available'),
          _InfoRow(text: 'Image selected from gallery or camera'),
          _InfoRow(text: 'Organizer ownership is verified'),
          _InfoRow(text: 'Image uploaded to Firebase Storage'),
          _InfoRow(text: 'Download URL saved in Firestore'),
          _InfoRow(text: 'Image linked with selected event'),
        ],
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
        left: 4,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: 500,
        cursorColor: primaryColor,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: true,
          counterText: '',
          counterStyle: const TextStyle(fontSize: 0, height: 0),
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.35),
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ================================================================
// INFO ROW
// ================================================================

class _InfoRow extends StatelessWidget {
  final String text;

  const _InfoRow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: const Color(0xFF007E7B),
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
