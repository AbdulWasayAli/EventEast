import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

import '../../widgets/premium_ui.dart';

class AnnouncementsScreen extends StatefulWidget {
  final String? eventId;

  const AnnouncementsScreen({
    super.key,
    this.eventId,
  });

  @override
  State<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState
    extends State<AnnouncementsScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController _titleController =
  TextEditingController();

  final TextEditingController _messageController =
  TextEditingController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String? _selectedEventId;
  String _selectedEventTitle = '';

  bool _isLoading = false;
  bool _isLoadingEvents = true;

  List<_OrganizerEvent> _events = [];

  int _recipientCount = 0;
  bool _isLoadingRecipients = false;

  @override
  void initState() {
    super.initState();

    _selectedEventId = widget.eventId;

    _loadOrganizerEvents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();

    super.dispose();
  }

  
  Future<void> _loadOrganizerEvents() async {
    if (mounted) {
      setState(() {
        _isLoadingEvents = true;
      });
    }

    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _events = [];
          _isLoadingEvents = false;
          _selectedEventId = null;
          _selectedEventTitle = '';
        });

        return;
      }

      final Map<String, _OrganizerEvent> uniqueEvents = {};

     
      await _loadEventsFromCollection(
        collectionName: 'Events',
        organizerId: user.uid,
        result: uniqueEvents,
      );

      

      await _loadEventsFromCollection(
        collectionName: 'events',
        organizerId: user.uid,
        result: uniqueEvents,
      );

      final List<_OrganizerEvent> events =
      uniqueEvents.values.toList();

      events.sort(
            (a, b) => a.title
            .toLowerCase()
            .compareTo(
          b.title.toLowerCase(),
        ),
      );

      String? selectedId;
      String selectedTitle = '';

      
      if (widget.eventId != null &&
          widget.eventId!.trim().isNotEmpty) {
        final String requestedId =
        widget.eventId!.trim();

        for (final event in events) {
          if (event.id == requestedId &&
              !_isCancelledStatus(event.status)) {
            selectedId = event.id;
            selectedTitle = event.title;
            break;
          }
        }
      }

      
      if (selectedId == null && events.isNotEmpty) {
        for (final event in events) {
          if (!_isCancelledStatus(event.status)) {
            selectedId = event.id;
            selectedTitle = event.title;
            break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _events = events;
        _selectedEventId = selectedId;
        _selectedEventTitle = selectedTitle;
        _isLoadingEvents = false;
      });

      // ----------------------------------------------------------
      // Load recipients
      // ----------------------------------------------------------

      if (selectedId != null) {
        await _loadRecipientCount(selectedId);
      } else {
        if (!mounted) return;

        setState(() {
          _recipientCount = 0;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _events = [];
        _isLoadingEvents = false;
        _recipientCount = 0;
      });

      _showSnackBar(
        'Could not load your events.',
        isError: true,
      );
    }
  }

  Future<void> _loadEventsFromCollection({
    required String collectionName,
    required String organizerId,
    required Map<String, _OrganizerEvent> result,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await _firestore
          .collection(collectionName)
          .where(
        'organizerId',
        isEqualTo: organizerId,
      )
          .get();

      for (final doc in snapshot.docs) {
        final Map<String, dynamic> data =
        doc.data();

        result[doc.id] = _OrganizerEvent(
          id: doc.id,
          title: _stringValue(
            data['title'],
            'Untitled Event',
          ),
          status: _stringValue(
            data['status'],
            'Pending',
          ),
        );
      }
    } catch (_) {
      
    }
  }

  
  Future<void> _loadRecipientCount(
      String eventId,
      ) async {
    if (eventId.trim().isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingRecipients = true;
      });
    }

    try {
      final Set<String> attendeeIds =
      await _getAttendeeIds(eventId);

      if (!mounted) return;

      setState(() {
        _recipientCount = attendeeIds.length;
        _isLoadingRecipients = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _recipientCount = 0;
        _isLoadingRecipients = false;
      });
    }
  }

 
  Future<Set<String>> _getAttendeeIds(
      String eventId,
      ) async {
    final QuerySnapshot<Map<String, dynamic>>
    registrationSnapshot =
    await _firestore
        .collection('registrations')
        .where(
      'eventId',
      isEqualTo: eventId,
    )
        .get();

    final Set<String> attendeeIds = {};

    for (final QueryDocumentSnapshot<
        Map<String, dynamic>> registration
    in registrationSnapshot.docs) {
      final Map<String, dynamic> data =
      registration.data();

      final String status =
      _stringValue(
        data['status'],
        '',
      ).toLowerCase();

      // Cancelled registration exclude.
      if (_isCancelledStatus(status)) {
        continue;
      }

      final String userId =
      _stringValue(
        data['userId'],
        '',
      );

      if (userId.isNotEmpty) {
        attendeeIds.add(userId);
      }
    }

    return attendeeIds;
  }

  
  Future<void> _sendAnnouncement() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String eventId =
    (_selectedEventId ?? '').trim();

    if (eventId.isEmpty) {
      _showSnackBar(
        'Please select an event.',
        isError: true,
      );
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar(
        'You must be logged in as an organizer.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      
      final _EventDocument? event =
      await _findEvent(eventId);

      if (event == null) {
        throw _AnnouncementException(
          'Selected event was not found.',
        );
      }

      final Map<String, dynamic> eventData =
          event.data;

     
      final String organizerId =
      _stringValue(
        eventData['organizerId'],
        '',
      );

      if (organizerId != user.uid) {
        throw _AnnouncementException(
          'You are not authorized to announce for this event.',
        );
      }

      
      final String eventTitle =
      _stringValue(
        eventData['title'],
        _selectedEventTitle.isNotEmpty
            ? _selectedEventTitle
            : 'Event',
      );

     
      final String eventStatus =
      _stringValue(
        eventData['status'],
        'Pending',
      ).toLowerCase();

      if (_isCancelledStatus(eventStatus)) {
        throw _AnnouncementException(
          'This event has been cancelled. You cannot send an announcement.',
        );
      }

      
      final Set<String> attendeeIds =
      await _getAttendeeIds(eventId);

     
      final String title =
      _titleController.text.trim();

      final String message =
      _messageController.text.trim();

      final DocumentReference<
          Map<String, dynamic>> announcementRef =
      _firestore
          .collection('announcements')
          .doc();

      final Map<String, dynamic>
      announcementData = {
        'eventId': eventId,
        'eventTitle': eventTitle,
        'organizerId': user.uid,
        'title': title,
        'message': message,
        'recipientCount': attendeeIds.length,
        'createdAt':
        FieldValue.serverTimestamp(),
      };

      
      await announcementRef.set(
        announcementData,
      );

      
      await _createNotifications(
        attendeeIds: attendeeIds,
        eventId: eventId,
        eventTitle: eventTitle,
        announcementId: announcementRef.id,
        title: title,
        message: message,
      );

      
      if (!mounted) return;

      final String recipientMessage =
      attendeeIds.isEmpty
          ? 'Announcement published. No registered attendees found.'
          : 'Announcement sent to ${attendeeIds.length} registered attendee(s).';

      _showSuccessDialog(
        eventTitle: eventTitle,
        recipientCount: attendeeIds.length,
        message: recipientMessage,
      );
    } on _AnnouncementException catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.message,
        isError: true,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Firebase Error: ${e.message ?? e.code}',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Could not send announcement.',
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

  
  Future<_EventDocument?> _findEvent(
      String eventId,
      ) async {
    
    try {
      final DocumentSnapshot<
          Map<String, dynamic>> doc =
      await _firestore
          .collection('Events')
          .doc(eventId)
          .get();

      if (doc.exists) {
        return _EventDocument(
          collection: 'Events',
          data: doc.data() ?? {},
        );
      }
    } catch (_) {}

   
    try {
      final DocumentSnapshot<
          Map<String, dynamic>> doc =
      await _firestore
          .collection('events')
          .doc(eventId)
          .get();

      if (doc.exists) {
        return _EventDocument(
          collection: 'events',
          data: doc.data() ?? {},
        );
      }
    } catch (_) {}

    return null;
  }


  Future<void> _createNotifications({
    required Set<String> attendeeIds,
    required String eventId,
    required String eventTitle,
    required String announcementId,
    required String title,
    required String message,
  }) async {
    if (attendeeIds.isEmpty) {
      return;
    }

    final List<String> attendeeList = attendeeIds.toList();
    final List<String> enabledAttendeeList = <String>[];

    for (final String attendeeId in attendeeList) {
      if (await NotificationService.isPushNotificationsEnabled(attendeeId)) {
        enabledAttendeeList.add(attendeeId);
      }
    }

  
    const int batchLimit = 450;

    for (
    int start = 0;
    start < enabledAttendeeList.length;
    start += batchLimit
    ) {
      final int end =
      (start + batchLimit <
          enabledAttendeeList.length)
          ? start + batchLimit
          : enabledAttendeeList.length;

      final WriteBatch batch =
      _firestore.batch();

      for (
      int i = start;
      i < end;
      i++
      ) {
        final String attendeeId =
        enabledAttendeeList[i];

        final DocumentReference<
            Map<String, dynamic>>
        notificationRef =
        _firestore
            .collection('notifications')
            .doc();

        batch.set(
          notificationRef,
          {
            'userId': attendeeId,
            'eventId': eventId,
            'eventTitle': eventTitle,
            'announcementId': announcementId,
            'title': title,
            'message': message,
            'type': 'announcement',
            'isRead': false,
            'createdAt':
            FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
    }

   
    for (final String attendeeId in enabledAttendeeList) {
      try {
        final userDoc = await _firestore.collection('Users').doc(attendeeId).get();
        if (userDoc.exists && userDoc.data()!.containsKey('fcmToken')) {
          final fcmToken = userDoc.data()!['fcmToken'];
          if (fcmToken != null && fcmToken.toString().isNotEmpty) {
            await NotificationService.sendPushNotification(
              fcmToken: fcmToken.toString(),
              title: title,
              body: message,
            );
          }
        }
      } catch (_) {
       
      }
    }
  }

  
  void _showSuccessDialog({
    required String eventTitle,
    required int recipientCount,
    required String message,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = Theme.of(context).cardColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (dialogContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007E7B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Color(0xFF007E7B), size: 42),
                ),

                const SizedBox(height: 18),

                Text(
                  'Announcement Sent!',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, color: Color(0xFF007E7B)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          eventTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.titleLarge?.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (recipientCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007E7B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$recipientCount notified',
                            style: const TextStyle(color: Color(0xFF007E7B), fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (mounted) Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007E7B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
              : const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SettingsStyleAppBar(
        title: 'Send Announcements',
      ),

      body: _isLoadingEvents
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        color: const Color(0xFF007E7B),
        onRefresh: _loadOrganizerEvents,
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _buildInfoBanner(),

                SizedBox(height: 28),

                _buildLabel(
                  'Select Event *',
                ),

                _buildEventDropdown(),

                SizedBox(height: 24),

                _buildLabel(
                  'Announcement Title *',
                ),

                _buildTextField(
                  controller:
                  _titleController,
                  hint:
                  'e.g. Venue Change Notice',
                  validatorMessage:
                  'Please enter an announcement title',
                  maxLength: 100,
                ),

                SizedBox(height: 24),

                _buildLabel(
                  'Message Content *',
                ),

                _buildTextField(
                  controller:
                  _messageController,
                  hint:
                  'Write your announcement here...',
                  validatorMessage:
                  'Please enter message content',
                  maxLines: 6,
                  maxLength: 1000,
                ),

                SizedBox(height: 24),

                if (_selectedEventId != null)
                  _buildRecipientInfo(),

                SizedBox(height: 32),

                _buildSubmitButton(),

                SizedBox(height: 20),

                _buildRequirementInfo(),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
        const Color(0xFF007E7B)
            .withOpacity(0.1),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFF007E7B)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.campaign_rounded,
            color: Color(0xFF007E7B),
            size: 28,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Select your event and broadcast important updates, schedule changes, venue changes, or other notices. Registered attendees will receive a notification.',
              style: TextStyle(
                color: Color(0xFF007E7B),
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

  Widget _buildEventDropdown() {
    if (_events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
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
              Icons.event_busy_rounded,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
            ),

            SizedBox(width: 12),

            Expanded(
              child: Text(
                'No events available for your organizer account.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bool hasSelectedEvent =
    _events.any(
          (event) =>
      event.id == _selectedEventId &&
          !_isCancelledStatus(event.status),
    );

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
        value: hasSelectedEvent ? _selectedEventId : null,
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
              Icons.campaign_rounded,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Choose an event...',
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
        items: _events.map((event) {
          final bool cancelled = _isCancelledStatus(event.status);

          return DropdownMenuItem<String>(
            value: event.id,
            enabled: !cancelled,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: cancelled
                          ? Colors.grey
                          : Theme.of(context).textTheme.titleLarge?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (cancelled)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Cancelled',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
          onChanged: _isLoading
              ? null
              : (String? value) async {
            if (value == null) return;
            final event = _events.firstWhere((item) => item.id == value);
            if (_isCancelledStatus(event.status)) return;

            setState(() {
              _selectedEventId = event.id;
              _selectedEventTitle = event.title;
              _recipientCount = 0;
              _isLoadingRecipients = true;
            });
            await _loadRecipientCount(event.id);
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please select an event';
            }
            return null;
          },
        ),
      );
  }

  
  Widget _buildRecipientInfo() {
    if (_isLoadingRecipients) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
          BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF007E7B),
              ),
            ),

            SizedBox(width: 12),

            Text(
              'Checking registered attendees...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final int count =
        _recipientCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
        const Color(0xFF007E7B)
            .withOpacity(0.06),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFF007E7B)
              .withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
              const Color(0xFF007E7B)
                  .withOpacity(0.1),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.people_alt_rounded,
              color: Color(0xFF007E7B),
            ),
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Recipients',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  count == 0
                      ? 'No registered attendees yet'
                      : '$count registered attendee${count == 1 ? '' : 's'} will be notified',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '$count',
            style: TextStyle(
              color: Color(0xFF007E7B),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
        _isLoading ||
            _events.isEmpty
            ? null
            : _sendAnnouncement,

        icon: _isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child:
          CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Icon(
          Icons.send_rounded,
          color: Colors.white,
        ),

        label: Text(
          _isLoading
              ? 'Broadcasting...'
              : 'Broadcast Announcement',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor:
          const Color(0xFF007E7B),
          disabledBackgroundColor:
          const Color(0xFF007E7B)
              .withOpacity(0.5),
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
          const Color(0xFF007E7B)
              .withOpacity(0.5),
        ),
      ),
    );
  }

  
  Widget _buildRequirementInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_rounded,
                color: Color(0xFF007E7B),
                size: 20,
              ),

              SizedBox(width: 8),

              Text(
                'Announcement workflow',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          _buildRequirementRow(
            'Announcement saved in Firestore',
          ),

          _buildRequirementRow(
            'Only your own events are available',
          ),

          _buildRequirementRow(
            'Cancelled registrations are excluded',
          ),

          _buildRequirementRow(
            'Registered attendees receive notifications',
          ),

          _buildRequirementRow(
            'Notification is marked unread initially',
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(
      String text,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF007E7B),
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
        style: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

 
  Widget _buildTextField({
    required TextEditingController
    controller,
    required String hint,
    required String validatorMessage,
    int maxLines = 1,
    int? maxLength,
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
        maxLength: maxLength,
        cursorColor: const Color(0xFF007E7B),
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return validatorMessage;
          }
          return null;
        },
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

 
  static String _stringValue(
      dynamic value,
      String fallback,
      ) {
    if (value == null) {
      return fallback;
    }

    final String result =
    value.toString().trim();

    if (result.isEmpty) {
      return fallback;
    }

    return result;
  }

  static bool _isCancelledStatus(
      String status,
      ) {
    final String value =
    status.trim().toLowerCase();

    return value == 'cancelled' ||
        value == 'canceled';
  }
}


class _OrganizerEvent {
  final String id;
  final String title;
  final String status;

  const _OrganizerEvent({
    required this.id,
    required this.title,
    required this.status,
  });
}

class _EventDocument {
  final String collection;
  final Map<String, dynamic> data;

  const _EventDocument({
    required this.collection,
    required this.data,
  });
}


class _AnnouncementException
    implements Exception {
  final String message;

  const _AnnouncementException(
      this.message,
      );

  @override
  String toString() => message;
}
