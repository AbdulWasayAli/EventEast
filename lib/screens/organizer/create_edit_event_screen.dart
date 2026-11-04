import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_upload_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/premium_ui.dart';
import 'package:latlong2/latlong.dart';
import '../shared/location_picker_screen.dart';

class CreateEditEventScreen extends StatefulWidget {
  final DocumentSnapshot? eventDoc;
  final Future<void> Function()? onEventSaved;

  const CreateEditEventScreen({
    super.key,
    this.eventDoc,
    this.onEventSaved,
  });

  @override
  State<CreateEditEventScreen> createState() =>
      _CreateEditEventScreenState();
}

class _CreateEditEventScreenState
    extends State<CreateEditEventScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _capacityController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _rulesController;
  late final TextEditingController _contactController;

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();


  String _selectedCategory = 'Technology';

  double? _latitude;
  double? _longitude;

  DateTime _selectedDate =
  DateTime.now().add(const Duration(days: 1));

  TimeOfDay _startTime =
  const TimeOfDay(hour: 10, minute: 0);

  TimeOfDay _endTime =
  const TimeOfDay(hour: 13, minute: 0);

  bool _isLoading = false;

  final List<String> _categories = const [
    'Technology',
    'Education',
    'Sports',
    'Music',
    'Business',
    'Workshop',
    'Conference',
    'Community',
  ];

  
  @override
  void initState() {
    super.initState();

    final Map<String, dynamic> data = _getEventData();

    _titleController = TextEditingController(
      text: _stringValue(data['title']),
    );

    _descriptionController = TextEditingController(
      text: _stringValue(data['description']),
    );

    _locationController = TextEditingController(
      text: _stringValue(data['location']),
    );

    _capacityController = TextEditingController(
      text: data['maxParticipants']?.toString() ?? '',
    );

    _priceController = TextEditingController(
      text: _priceText(data['price']),
    );

    _imageUrlController = TextEditingController(
      text: _stringValue(data['imageUrl']),
    );

    _rulesController = TextEditingController(
      text: _stringValue(data['rules']),
    );

    _contactController = TextEditingController(
      text: _stringValue(data['contactInfo']),
    );

    // CATEGORY
    final String category =
    _stringValue(data['category']);

    if (_categories.contains(category)) {
      _selectedCategory = category;
    }

    _latitude = (data['latitude'] as num?)?.toDouble();
    _longitude = (data['longitude'] as num?)?.toDouble();

    // DATE
    final dynamic dateValue = data['date'];

    if (dateValue is Timestamp) {
      _selectedDate = dateValue.toDate();
    } else if (dateValue is DateTime) {
      _selectedDate = dateValue;
    } else if (dateValue is String) {
      final DateTime? parsed =
      DateTime.tryParse(dateValue);

      if (parsed != null) {
        _selectedDate = parsed;
      }
    }

    // START TIME
    _startTime = _parseTimeOfDay(
      _stringValue(data['startTime']),
      const TimeOfDay(hour: 10, minute: 0),
    );

    
    _endTime = _parseTimeOfDay(
      _stringValue(data['endTime']),
      const TimeOfDay(hour: 13, minute: 0),
    );

  }

  
  Map<String, dynamic> _getEventData() {
    if (widget.eventDoc == null) {
      return {};
    }

    try {
      final dynamic rawData =
      widget.eventDoc!.data();

      if (rawData is Map) {
        return Map<String, dynamic>.from(rawData);
      }
    } catch (_) {}

    return {};
  }


  String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  String _priceText(dynamic value) {
    if (value is num && value > 0) return value.toString();
    final double? parsed = double.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed.toString() : '';
  }

  
  TimeOfDay _parseTimeOfDay(
      String? value,
      TimeOfDay fallback,
      ) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    try {
      final String text =
      value.trim().toUpperCase();

      final RegExpMatch? match = RegExp(
        r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      ).firstMatch(text);

      if (match == null) {
        return fallback;
      }

      int hour =
      int.parse(match.group(1)!);

      final int minute =
      int.parse(match.group(2)!);

      final String? period =
      match.group(3);

      if (minute < 0 || minute > 59) {
        return fallback;
      }

      if (period == 'AM') {
        if (hour == 12) {
          hour = 0;
        }
      } else if (period == 'PM') {
        if (hour != 12) {
          hour += 12;
        }
      }

      if (hour < 0 || hour > 23) {
        return fallback;
      }

      return TimeOfDay(
        hour: hour,
        minute: minute,
      );
    } catch (_) {
      return fallback;
    }
  }

  
  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (pickedFile == null) return;
      if (!mounted) return;
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageUrlController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Could not select image: $e');
    }
  }

  void _showImageSourceSheet() {
    if (_isLoading) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Select Image',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSourceButton(
                        icon: Icons.photo_library_rounded,
                        title: 'Gallery',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSourceButton(
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickImage(ImageSource.camera);
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

  Widget _buildSourceButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF007E7B).withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF007E7B).withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFF007E7B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF007E7B), size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _rulesController.dispose();
    _contactController.dispose();

    super.dispose();
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate(
      BuildContext context,
      ) async {
    final DateTime now = DateTime.now();

    final DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    DateTime initialDate = _selectedDate;

    if (initialDate.isBefore(today)) {
      initialDate = today;
    }

    final DateTime? picked =
    await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
            const ColorScheme.light(
              primary: Color(0xFF007E7B),
              secondary: Color(0xFF00A896),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ============================================================
  // START TIME
  // ============================================================

  Future<void> _selectStartTime(
      BuildContext context,
      ) async {
    final TimeOfDay? picked =
    await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _startTime = picked;

      final int startMinutes =
          picked.hour * 60 + picked.minute;

      final int endMinutes =
          _endTime.hour * 60 +
              _endTime.minute;

      if (startMinutes >= endMinutes) {
        final int newEndMinutes =
            startMinutes + 60;

        if (newEndMinutes < 24 * 60) {
          _endTime = TimeOfDay(
            hour: newEndMinutes ~/ 60,
            minute: newEndMinutes % 60,
          );
        }
      }
    });
  }

  // ============================================================
  // END TIME
  // ============================================================

  Future<void> _selectEndTime(
      BuildContext context,
      ) async {
    final TimeOfDay? picked =
    await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked != null && mounted) {
      setState(() {
        _endTime = picked;
      });
    }
  }



  bool _isEndTimeAfterStartTime() {
    final int startMinutes =
        _startTime.hour * 60 +
            _startTime.minute;

    final int endMinutes =
        _endTime.hour * 60 +
            _endTime.minute;

    return endMinutes > startMinutes;
  }

  bool _hasImportantChanges(
      Map<String, dynamic> currentData,
      ) {
    final String currentTitle =
    _stringValue(currentData['title']);

    final String currentDescription =
    _stringValue(currentData['description']);

    final String currentCategory =
    _stringValue(currentData['category']);

    final String currentLocation =
    _stringValue(currentData['location']);

    final String currentImageUrl =
    _stringValue(currentData['imageUrl']);

    final String currentRules =
    _stringValue(currentData['rules']);

    final String currentContact =
    _stringValue(currentData['contactInfo']);

    final int currentCapacity =
    _safeInt(currentData['maxParticipants']);

    final double currentPrice =
        double.tryParse(currentData['price']?.toString() ?? '') ?? 0;

    final String currentStartTime =
    _stringValue(currentData['startTime']);

    final String currentEndTime =
    _stringValue(currentData['endTime']);

    // ------------------------------------------------------------
    // DATE COMPARISON
    // ------------------------------------------------------------

    DateTime? currentDate;

    final dynamic currentDateValue =
    currentData['date'];

    if (currentDateValue is Timestamp) {
      currentDate =
          currentDateValue.toDate();
    } else if (currentDateValue is DateTime) {
      currentDate = currentDateValue;
    } else if (currentDateValue is String) {
      currentDate =
          DateTime.tryParse(currentDateValue);
    }

    final DateTime newDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    bool dateChanged = false;

    if (currentDate != null) {
      final DateTime oldDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      );

      dateChanged =
          oldDate != newDate;
    } else {
      dateChanged = true;
    }

    // ------------------------------------------------------------
    // NEW VALUES
    // ------------------------------------------------------------

    final String newTitle =
    _titleController.text.trim();

    final String newDescription =
    _descriptionController.text.trim();

    final String newCategory =
    _selectedCategory.trim();

    final String newLocation =
    _locationController.text.trim();

    final String newImageUrl =
    _imageUrlController.text.trim();

    final String newRules =
    _rulesController.text.trim();

    final String newContact =
    _contactController.text.trim();

    final int newCapacity =
        int.tryParse(
          _capacityController.text.trim(),
        ) ??
            0;

    final double newPrice =
        double.tryParse(_priceController.text.trim()) ?? 0;

    final String newStartTime =
    _startTime.format(context);

    final String newEndTime =
    _endTime.format(context);

    // ------------------------------------------------------------
    // CHECK IMPORTANT CHANGES
    // ------------------------------------------------------------

    if (currentTitle != newTitle) {
      return true;
    }

    if (currentDescription != newDescription) {
      return true;
    }

    if (currentCategory != newCategory) {
      return true;
    }

    if (currentLocation != newLocation) {
      return true;
    }

    if (currentImageUrl != newImageUrl) {
      return true;
    }

    if (currentRules != newRules) {
      return true;
    }

    if (currentContact != newContact) {
      return true;
    }

    if (currentCapacity != newCapacity) {
      return true;
    }

    if (currentPrice != newPrice) {
      return true;
    }

    if (currentStartTime != newStartTime) {
      return true;
    }

    if (currentEndTime != newEndTime) {
      return true;
    }

    if (dateChanged) {
      return true;
    }

    return false;
  }

  // ============================================================
  // SAVE EVENT
  // ============================================================

  Future<void> _saveEvent() async {
    final FormState? form =
        _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    if (!_isEndTimeAfterStartTime()) {
      _showError(
        'End time must be after start time.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // --------------------------------------------------------
      // USER
      // --------------------------------------------------------

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'You must be logged in to create an event.',
        );
      }

      // --------------------------------------------------------
      // CAPACITY
      // --------------------------------------------------------

      final int? capacity =
      int.tryParse(
        _capacityController.text.trim(),
      );

      if (capacity == null || capacity <= 0) {
        throw Exception(
          'Please enter a valid capacity.',
        );
      }

      final double? enteredPrice = double.tryParse(_priceController.text.trim());
      if (_priceController.text.trim().isNotEmpty &&
          (enteredPrice == null || enteredPrice < 0)) {
        throw Exception('Please enter a valid price or leave it empty for a free event.');
      }
      final double price = enteredPrice ?? 0;

      // --------------------------------------------------------
      // DATE
      // --------------------------------------------------------

      final DateTime eventDate =
      DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      // --------------------------------------------------------
      // TIME
      // --------------------------------------------------------

      final String startTime =
      _startTime.format(context);

      final String endTime =
      _endTime.format(context);

      // --------------------------------------------------------
      // IMAGE
      // --------------------------------------------------------

      String imageUrl =
      _imageUrlController.text.trim();

      if (_selectedImage != null) {
        imageUrl = await ImageUploadService.uploadImage(_selectedImage!);
      }

      // ========================================================
      // CREATE EVENT
      // ========================================================

      if (widget.eventDoc == null) {
        final Map<String, dynamic> eventData = {
          'organizerId': user.uid,

          'title':
          _titleController.text.trim(),

          'description':
          _descriptionController.text.trim(),

          'category':
          _selectedCategory,

          'date':
          Timestamp.fromDate(eventDate),

          'startTime':
          startTime,

          'endTime':
          endTime,

          'location':
          _locationController.text.trim(),

          if (_latitude != null) 'latitude': _latitude,
          if (_longitude != null) 'longitude': _longitude,

          'maxParticipants':
          capacity,

          'price': price,

          'imageUrl': imageUrl.isNotEmpty
              ? imageUrl
              : 'https://images.unsplash.com/photo-1540575467063-178a50c2df87',

          'rules':
          _rulesController.text.trim(),

          'contactInfo':
          _contactController.text.trim(),

          'createdAt':
          FieldValue.serverTimestamp(),

          'updatedAt':
          FieldValue.serverTimestamp(),

          // New event always requires admin approval.
          'status':
          'Pending Approval',

          'isRegistered':
          false,

          'isFavorite':
          false,

          'availableSeats':
          capacity,

        };

        await FirebaseFirestore.instance
            .collection('Events')
            .add(eventData);

        // Send notification to all Admins about new pending event
        final String eventTitle = _titleController.text.trim();
        try {
          final adminSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .where('role', isEqualTo: 'Admin')
              .get();
          for (final adminDoc in adminSnapshot.docs) {
            await NotificationService.sendNotification(
              recipientUserId: adminDoc.id,
              title: 'New Event Pending Approval 📋',
              message: 'A new event "$eventTitle" has been submitted for approval.',
              type: 'admin_approval_request',
            );
          }
        } catch (_) {
          // Don't fail event creation if admin notification fails
        }
      }

      // ========================================================
      // UPDATE EVENT
      // ========================================================

      else {
        final DocumentReference<
            Map<String, dynamic>> eventRef =
        FirebaseFirestore.instance
            .collection('Events')
            .doc(widget.eventDoc!.id);

        // ------------------------------------------------------
        // GET CURRENT EVENT
        // ------------------------------------------------------

        final DocumentSnapshot<
            Map<String, dynamic>> currentDoc =
        await eventRef.get();

        if (!currentDoc.exists) {
          throw Exception(
            'Event no longer exists.',
          );
        }

        final Map<String, dynamic>? currentData =
        currentDoc.data();

        if (currentData == null) {
          throw Exception(
            'Unable to read existing event data.',
          );
        }

        // ------------------------------------------------------
        // CURRENT STATUS
        // ------------------------------------------------------

        final String currentStatus =
            currentData['status']
                ?.toString()
                .trim() ??
                '';

        // ------------------------------------------------------
        // CHECK IMPORTANT EDITS
        // ------------------------------------------------------

        final bool importantChanges =
        _hasImportantChanges(
          currentData,
        );

        // ------------------------------------------------------
        // STATUS LOGIC
        // ------------------------------------------------------
        //
        // NEW REQUIREMENT IMPLEMENTED:
        //
        // Approved event + important edit
        //             ↓
        //      Pending Approval
        //
        // Approved event + no edit
        //             ↓
        //      Approved
        //
        // Pending event + edit
        //             ↓
        //      Pending Approval
        //
        // Cancelled event remains Cancelled unless
        // application logic changes it elsewhere.
        //
        // ------------------------------------------------------

        String updatedStatus;

        if (importantChanges) {
          updatedStatus = 'Pending Approval';
        } else if (currentStatus.isNotEmpty) {
          updatedStatus = currentStatus;
        } else {
          updatedStatus = 'Pending Approval';
        }

        // ------------------------------------------------------
        // AVAILABLE SEATS
        // ------------------------------------------------------

        final int oldCapacity =
        _safeInt(
          currentData['maxParticipants'],
        );

        final int oldAvailableSeats =
        _safeInt(
          currentData['availableSeats'],
        );

        int availableSeats;

        if (currentData.containsKey(
          'availableSeats',
        )) {
          final int usedSeats =
              oldCapacity -
                  oldAvailableSeats;

          availableSeats =
              (capacity - usedSeats)
                  .clamp(0, capacity);
        } else {
          availableSeats = capacity;
        }

        // ------------------------------------------------------
        // UPDATE DATA
        // ------------------------------------------------------

        final Map<String, dynamic> eventData = {
          'organizerId': user.uid,

          'title':
          _titleController.text.trim(),

          'description':
          _descriptionController.text.trim(),

          'category':
          _selectedCategory,

          'date':
          Timestamp.fromDate(eventDate),

          'startTime':
          startTime,

          'endTime':
          endTime,

          'location':
          _locationController.text.trim(),

          if (_latitude != null) 'latitude': _latitude,
          if (_longitude != null) 'longitude': _longitude,

          'maxParticipants':
          capacity,

          'price': price,

          'imageUrl': imageUrl.isNotEmpty
              ? imageUrl
              : 'https://images.unsplash.com/photo-1540575467063-178a50c2df87',

          'rules':
          _rulesController.text.trim(),

          'contactInfo':
          _contactController.text.trim(),

          'status':
          updatedStatus,

          'availableSeats':
          availableSeats,

          'updatedAt':
          FieldValue.serverTimestamp(),

        };

        await eventRef.update(eventData);

        // ------------------------------------------------------
        // SHOW APPROVAL MESSAGE
        // ------------------------------------------------------

        if (importantChanges &&
            currentStatus == 'Approved') {
          if (mounted) {
            _showSuccess(
              'Event updated. Important changes require administrator approval.',
            );
          }
        }
      }

      if (!mounted) {
        return;
      }

      // ========================================================
      // NORMAL SUCCESS
      // ========================================================

      if (widget.eventDoc == null) {
        _showSuccess(
          'Event created successfully and submitted for approval!',
        );
      } else {
        final Map<String, dynamic> currentData =
        _getEventData();

        final String currentStatus =
        _stringValue(
          currentData['status'],
        );

        final bool importantChanges =
        _hasImportantChanges(
          currentData,
        );

        if (!(importantChanges &&
            currentStatus == 'Approved')) {
          _showSuccess(
            'Event updated successfully!',
          );
        }
      }

      // ========================================================
      // REFRESH
      // ========================================================

      if (widget.onEventSaved != null) {
        await widget.onEventSaved!();
      }

      if (!mounted) {
        return;
      }

      // ========================================================
      // AFTER CREATE
      // ========================================================

      if (widget.eventDoc == null) {
        _clearForm();
      }
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Firebase Error: ${e.message ?? e.code}',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final String message =
      e.toString().replaceFirst(
        'Exception: ',
        '',
      );

      _showError(
        'Error: $message',
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
  // SAFE INT
  // ============================================================

  int _safeInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  // ============================================================
  // CLEAR FORM
  // ============================================================

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _capacityController.clear();
    _imageUrlController.clear();
    _rulesController.clear();
    _contactController.clear();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedCategory =
      'Technology';

      _selectedDate =
          DateTime.now().add(
            const Duration(days: 1),
          );

      _startTime =
      const TimeOfDay(
        hour: 10,
        minute: 0,
      );

      _endTime =
      const TimeOfDay(
        hour: 13,
        minute: 0,
      );
    });
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _showSuccess(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).cardColor,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor:
        const Color(0xFF007E7B),
        behavior:
        SnackBarBehavior.floating,
        margin:
        const EdgeInsets.all(16),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(14),
        ),
        duration:
        const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).cardColor,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor:
        Colors.redAccent,
        behavior:
        SnackBarBehavior.floating,
        margin:
        const EdgeInsets.all(16),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isEditing =
        widget.eventDoc != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: SettingsStyleAppBar(
        title: isEditing ? 'Edit Event' : 'Create Event',
      ),

      body: _isLoading
          ? Center(
        child:
        CircularProgressIndicator(
          color: Color(0xFF007E7B),
        ),
      )
          : SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // IMAGE
                _buildLabel('Event Banner'),
                _buildImagePicker(),

                SizedBox(
                  height: 20,
                ),

                // TITLE
                _buildLabel(
                  'Event Title',
                ),

                _buildTextField(
                  'e.g. Global Tech Summit',
                  controller:
                  _titleController,
                ),

                SizedBox(
                  height: 20,
                ),

                // CATEGORY + CAPACITY
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          _buildLabel(
                            'Category',
                          ),
                          _buildCategoryDropdown(),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          _buildLabel(
                            'Max Capacity',
                          ),
                          _buildTextField(
                            'e.g. 150',
                            controller:
                            _capacityController,
                            keyboardType:
                            TextInputType
                                .number,
                            icon: Icons
                                .group_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 20,
                ),

                // TICKET PRICE (OPTIONAL)
                _buildLabel('Ticket Price (PKR) — optional'),
                _buildTextField(
                  'Leave empty or enter 0 for a free event',
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  icon: Icons.payments_outlined,
                  requiredField: false,
                ),
                const SizedBox(height: 6),
                Text(
                  'A price greater than 0 creates a paid event.',
                  style: TextStyle(
                    color: Colors.blueGrey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(
                  height: 20,
                ),

                // DATE
                _buildLabel(
                  'Event Date',
                ),

                _buildDatePicker(),

                SizedBox(
                  height: 20,
                ),

                // TIME
                Row(
                  children: [
                    Expanded(
                      child:
                      _buildTimePicker(
                        label:
                        'Start Time',
                        time:
                        _startTime,
                        onTap: () =>
                            _selectStartTime(
                              context,
                            ),
                      ),
                    ),

                    SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child:
                      _buildTimePicker(
                        label:
                        'End Time',
                        time:
                        _endTime,
                        onTap: () =>
                            _selectEndTime(
                              context,
                            ),
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 20,
                ),

                // LOCATION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('Location'),
                    TextButton.icon(
                      onPressed: () async {
                        LatLng? initial;
                        if (_latitude != null && _longitude != null) {
                          initial = LatLng(_latitude!, _longitude!);
                        }
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocationPickerScreen(initialLocation: initial),
                          ),
                        );
                        if (result != null && result is Map) {
                          setState(() {
                            _latitude = (result['latLng'] as LatLng).latitude;
                            _longitude = (result['latLng'] as LatLng).longitude;
                            _locationController.text = result['address'] ?? '';
                          });
                        }
                      },
                      icon: Icon(
                        _latitude != null ? Icons.check_circle : Icons.map_rounded,
                        color: _latitude != null ? Colors.green : const Color(0xFF007E7B),
                        size: 20,
                      ),
                      label: Text(
                        _latitude != null ? 'Location Pinned' : 'Pick on Map',
                        style: TextStyle(
                          color: _latitude != null ? Colors.green : const Color(0xFF007E7B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                _buildTextField(
                  'e.g. Karachi Expo Center',
                  controller:
                  _locationController,
                  icon: Icons
                      .location_on_rounded,
                ),

                SizedBox(
                  height: 20,
                ),

                // DESCRIPTION
                _buildLabel(
                  'Description',
                ),

                _buildTextField(
                  'Describe your event...',
                  controller:
                  _descriptionController,
                  maxLines: 4,
                ),

                SizedBox(
                  height: 20,
                ),

                // RULES
                _buildLabel(
                  'Rules & Guidelines',
                ),

                _buildTextField(
                  'Enter event rules...',
                  controller:
                  _rulesController,
                  maxLines: 4,
                ),

                SizedBox(
                  height: 20,
                ),

                // CONTACT
                _buildLabel(
                  'Contact Information',
                ),

                _buildTextField(
                  'e.g. support@eventease.com',
                  controller:
                  _contactController,
                  icon: Icons
                      .contact_support_rounded,
                ),

                SizedBox(
                  height: 40,
                ),

                // SAVE
                _buildSaveButton(
                  isEditing,
                ),

                SizedBox(
                  height: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY DROPDOWN
  // ============================================================

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      isExpanded: true,
      dropdownColor: Theme.of(context).cardColor,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
      ),
      items: _categories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(
            category,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        );
      }).toList(),
      onChanged: _isLoading ? null : (String? value) {
        if (value == null) return;
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  // ============================================================
  // IMAGE PICKER UI
  // ============================================================

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: _selectedImage != null
              ? Image.file(_selectedImage!, fit: BoxFit.cover)
              : _imageUrlController.text.isNotEmpty
                  ? Image.network(
                      _imageUrlController.text,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 40),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 48,
                          color: const Color(0xFF007E7B).withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload event banner',
                          style: TextStyle(
                            color: Colors.blueGrey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE PICKER UI
  // ============================================================

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _isLoading
          ? null
          : () => _selectDate(context),
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration:
        BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
          BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        ),
        child: Row(
          children: [
            Icon(
              Icons
                  .calendar_month_rounded,
              color:
              Colors.blueGrey.shade400,
            ),

            SizedBox(
              width: 12,
            ),

            Expanded(
              child: Text(
                '${_selectedDate.day.toString().padLeft(2, '0')}/'
                    '${_selectedDate.month.toString().padLeft(2, '0')}/'
                    '${_selectedDate.year}',
                style:
                TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),

            Icon(
              Icons
                  .edit_calendar_rounded,
              color:
              Colors.blueGrey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton(
      bool isEditing,
      ) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration:
        BoxDecoration(
          borderRadius:
          BorderRadius.circular(20),
          gradient:
          const LinearGradient(
            colors: [
              Color(0xFF00A896),
              Color(0xFF028090),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59028090),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed:
          _isLoading
              ? null
              : _saveEvent,
          style:
          ElevatedButton.styleFrom(
            backgroundColor:
            Colors.transparent,
            disabledBackgroundColor:
            Colors.transparent,
            shadowColor:
            Colors.transparent,
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(20),
            ),
            padding:
            const EdgeInsets.symmetric(
              vertical: 18,
            ),
          ),
          child: _isLoading
              ? SizedBox(
            height: 24,
            width: 24,
            child:
            CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Theme.of(context).cardColor,
            ),
          )
              : Text(
            isEditing
                ? 'Update Event'
                : 'Submit Event for Approval',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w800,
              color: Theme.of(context).cardColor,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(
      String text,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 8,
        left: 4,
      ),
      child: Text(
        text,
        style:
        TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
          fontWeight:
          FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField(
      String hint, {
        required TextEditingController
        controller,
        IconData? icon,
        int maxLines = 1,
        TextInputType? keyboardType,
        bool requiredField = true,
      }) {
    return Container(
      decoration:
      BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType:
        keyboardType,
        cursorColor:
        const Color(0xFF007E7B),
        validator: (value) {
          final String text =
              value?.trim() ?? '';

          if (requiredField &&
              text.isEmpty) {
            return 'This field cannot be empty';
          }

          if (keyboardType ==
              TextInputType.number) {
            if (text.isEmpty) {
              return 'Capacity is required';
            }

            final int? number =
            int.tryParse(text);

            if (number == null) {
              return 'Please enter a valid number';
            }

            if (number <= 0) {
              return 'Capacity must be greater than 0';
            }
          }

          return null;
        },
        decoration:
        InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color:
            Colors.blueGrey.shade300,
          ),
          contentPadding:
          const EdgeInsets.all(16),
          suffixIcon: icon != null
              ? Icon(
            icon,
            color: Colors
                .blueGrey.shade300,
          )
              : null,
        ),
      ),
    );
  }

  // ============================================================
  // TIME PICKER
  // ============================================================

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _buildLabel(label),

        GestureDetector(
          onTap:
          _isLoading ? null : onTap,
          child: Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            decoration:
            BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
              BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons
                      .access_time_rounded,
                  color: Colors
                      .blueGrey.shade400,
                ),

                SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    time.format(context),
                    style:
                    TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
