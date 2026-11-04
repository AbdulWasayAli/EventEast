import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class AdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _users = [];
  bool _isLoading = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
  _pendingEventApprovals = [];

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
  _pendingOrganizerApprovals = [];

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
  _flaggedGalleryItems = [];

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allEvents = [];

  final List<Map<String, String>> _systemLogs = [];

  int _totalRegistrationsCount = 0;
  double _averageFeedbackRating = 0.0;

  String? _errorMessage;

  List<UserModel> get users => List.unmodifiable(_users);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
  get pendingEventApprovals =>
      List.unmodifiable(_pendingEventApprovals);

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
  get pendingOrganizerApprovals =>
      List.unmodifiable(_pendingOrganizerApprovals);

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
  get flaggedGalleryItems =>
      List.unmodifiable(_flaggedGalleryItems);

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
  get allEvents => List.unmodifiable(_allEvents);

  List<Map<String, String>> get systemLogs =>
      List.unmodifiable(_systemLogs);

  int get totalUsersCount => _users.length;

  int get pendingApprovalsCount =>
      _pendingEventApprovals.length +
          _pendingOrganizerApprovals.length;

  int get flaggedItemsCount => _flaggedGalleryItems.length;

  int get totalRegistrationsCount =>
      _totalRegistrationsCount;

  double get averageFeedbackRating =>
      _averageFeedbackRating;

  String _getString(
      Map<String, dynamic> data,
      String upperKey,
      String lowerKey, [
        String defaultValue = '',
      ]) {
    final value =
        data[upperKey] ?? data[lowerKey];

    if (value == null) {
      return defaultValue;
    }

    return value.toString().trim();
  }
  
  Future<DocumentReference<Map<String, dynamic>>?>
  _findUserDocument(String userId) async {
    try {
      final directDoc = await _firestore
          .collection('Users')
          .doc(userId)
          .get();

      if (directDoc.exists) {
        return directDoc.reference;
      }

      final upperQuery = await _firestore
          .collection('Users')
          .where(
        'UserId',
        isEqualTo: userId,
      )
          .limit(1)
          .get();

      if (upperQuery.docs.isNotEmpty) {
        return upperQuery.docs.first.reference;
      }

      final lowerQuery = await _firestore
          .collection('Users')
          .where(
        'userId',
        isEqualTo: userId,
      )
          .limit(1)
          .get();

      if (lowerQuery.docs.isNotEmpty) {
        return lowerQuery.docs.first.reference;
      }

      return null;
    } catch (e) {
      debugPrint(
        'Error finding user document: $e',
      );

      return null;
    }
  }
  Future<void> fetchUsers() async {
    try {
      _isLoading = true;
      _errorMessage = null;

      notifyListeners();

      final snapshot =
      await _firestore.collection('Users').get();

      final List<UserModel> loadedUsers = [];
      final Set<String> addedUserIds = {};

      for (final doc in snapshot.docs) {
        final data =
        Map<String, dynamic>.from(doc.data());

        String userId = _getString(
          data,
          'UserId',
          'userId',
        );

        if (userId.isEmpty) {
          userId = doc.id;
        }

        final userData =
        <String, dynamic>{
          ...data,

          'UserId': userId,

          'Name': _getString(
            data,
            'Name',
            'name',
            'Unknown User',
          ),

          'Email': _getString(
            data,
            'Email',
            'email',
          ),

          'Phone': _getString(
            data,
            'Phone',
            'phone',
          ),

          'Role': _getString(
            data,
            'Role',
            'role',
            'Attendee',
          ),

          'ProfileImage': _getString(
            data,
            'ProfileImage',
            'profileImage',
          ),

          'Status': _getString(
            data,
            'Status',
            'status',
            'Active',
          ),
        };
        if (addedUserIds.contains(userId)) {
          debugPrint(
            'Duplicate user skipped: $userId',
          );

          continue;
        }

        addedUserIds.add(userId);
        try {
          loadedUsers.add(
            UserModel.fromMap(userData),
          );
        } catch (e) {
          debugPrint(
            'Error converting user ${doc.id}: $e',
          );
        }
      }

      _users = loadedUsers;

      debugPrint('====================================');
      debugPrint('USERS COLLECTION: Users');
      debugPrint(
        'FIRESTORE DOCUMENTS: ${snapshot.docs.length}',
      );
      debugPrint(
        'UNIQUE USERS: ${_users.length}',
      );

      for (final user in _users) {
        debugPrint(
          'User: ${user.name} | '
              'Email: ${user.email} | '
              'Role: ${user.role} | '
              'Status: ${user.status} | '
              'ID: ${user.userId}',
        );
      }

      debugPrint('====================================');
    } catch (e) {
      debugPrint(
        'Error fetching Users: $e',
      );

      _errorMessage =
      'Could not load users.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<UserModel> searchUsers(String query) {
    if (query.trim().isEmpty) {
      return List<UserModel>.from(_users);
    }

    final q =
    query.trim().toLowerCase();

    return _users.where((user) {
      return user.name
          .toLowerCase()
          .contains(q) ||
          user.email
              .toLowerCase()
              .contains(q) ||
          user.role
              .toLowerCase()
              .contains(q);
    }).toList();
  }

  Future<bool> toggleUserStatus(
      String userId,
      ) async {
    final index = _users.indexWhere(
          (user) => user.userId == userId,
    );

    if (index == -1) {
      debugPrint(
        'User not found: $userId',
      );

      _errorMessage =
      'User not found.';

      notifyListeners();

      return false;
    }

    final user = _users[index];

    final currentStatus =
    user.status
        .trim()
        .toLowerCase();

    final newStatus =
    currentStatus == 'suspended'
        ? 'Active'
        : 'Suspended';

    try {
      final userRef =
      await _findUserDocument(userId);

      if (userRef == null) {
        _errorMessage =
        'User document not found.';

        notifyListeners();

        return false;
      }

      final snapshot =
      await userRef.get();

      final data =
          snapshot.data() ?? {};

      if (data.containsKey('Status')) {
        await userRef.update({
          'Status': newStatus,
        });
      } else {
        await userRef.update({
          'status': newStatus,
        });
      }

      _users[index] =
          user.copyWith(
            status: newStatus,
          );
      _systemLogs.insert(
        0,
        {
          'title':
          'User Status Changed',
          'subtitle':
          '${user.name} is now $newStatus.',
          'time':
          'Just now',
          'type':
          'user',
        },
      );

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error updating user status: $e',
      );

      _errorMessage =
      'Could not update user status.';

      notifyListeners();

      return false;
    }
  }
  Future<void> fetchPendingApprovals() async {
    try {
      final eventsSnapshot =
      await _firestore
          .collection('Events')
          .get();

      _pendingEventApprovals =
          eventsSnapshot.docs.where((doc) {
            final data = doc.data();

            final status =
            _getString(
              data,
              'Status',
              'status',
            ).toLowerCase();

            return status == 'pending' ||
                status == 'pending approval' ||
                status == 'pending_approval';
          }).toList();

      final usersSnapshot =
      await _firestore
          .collection('Users')
          .get();

      _pendingOrganizerApprovals =
          usersSnapshot.docs.where((doc) {
            final data = doc.data();

            final role =
            _getString(
              data,
              'Role',
              'role',
            ).toLowerCase();

            final status =
            _getString(
              data,
              'Status',
              'status',
            ).toLowerCase();

            return role == 'organizer' &&
                (
                    status == 'pending' ||
                        status == 'pending approval' ||
                        status == 'pending_approval'
                );
          }).toList();

      debugPrint(
        'Pending Events: '
            '${_pendingEventApprovals.length}',
      );

      debugPrint(
        'Pending Organizers: '
            '${_pendingOrganizerApprovals.length}',
      );

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Error fetching pending approvals: $e',
      );

      _errorMessage =
      'Could not load pending approvals.';

      notifyListeners();
    }
  }
  
  Future<bool> approveEvent(
      String eventId,
      ) async {
    try {
      final eventRef =
      _firestore
          .collection('Events')
          .doc(eventId);

      final snapshot =
      await eventRef.get();

      if (!snapshot.exists) {
        _errorMessage =
        'Event not found.';

        notifyListeners();

        return false;
      }

      final data =
          snapshot.data() ?? {};

      if (data.containsKey('Status')) {
        await eventRef.update({
          'Status': 'Approved',
          'updatedAt':
          FieldValue.serverTimestamp(),
        });
      } else {
        await eventRef.update({
          'status': 'Approved',
          'updatedAt':
          FieldValue.serverTimestamp(),
        });
      }

      _pendingEventApprovals.removeWhere(
            (doc) => doc.id == eventId,
      );

      await fetchAllEventsForAdmin();

      _systemLogs.insert(
        0,
        {
          'title':
          'Event Approved',
          'subtitle':
          'Event $eventId was approved.',
          'time':
          'Just now',
          'type':
          'approval',
        },
      );

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error approving event: $e',
      );

      _errorMessage =
      'Could not approve event.';

      notifyListeners();

      return false;
    }
  }

  Future<bool> rejectEvent(
      String eventId,
      ) async {
    try {
      final eventRef =
      _firestore
          .collection('Events')
          .doc(eventId);

      final snapshot =
      await eventRef.get();

      if (!snapshot.exists) {
        _errorMessage =
        'Event not found.';

        notifyListeners();

        return false;
      }

      final data =
          snapshot.data() ?? {};

      if (data.containsKey('Status')) {
        await eventRef.update({
          'Status': 'Rejected',
          'updatedAt':
          FieldValue.serverTimestamp(),
        });
      } else {
        await eventRef.update({
          'status': 'Rejected',
          'updatedAt':
          FieldValue.serverTimestamp(),
        });
      }

      _pendingEventApprovals.removeWhere(
            (doc) => doc.id == eventId,
      );

      await fetchAllEventsForAdmin();

      _systemLogs.insert(
        0,
        {
          'title':
          'Event Rejected',
          'subtitle':
          'Event $eventId was rejected.',
          'time':
          'Just now',
          'type':
          'approval',
        },
      );

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error rejecting event: $e',
      );

      _errorMessage =
      'Could not reject event.';

      notifyListeners();

      return false;
    }
  }

  Future<bool> approveOrganizer(
      String userId,
      ) async {
    try {
      final userRef =
      await _findUserDocument(userId);

      if (userRef == null) {
        _errorMessage =
        'Organizer not found.';

        notifyListeners();

        return false;
      }

      final snapshot =
      await userRef.get();

      final data =
          snapshot.data() ?? {};

      if (data.containsKey('Status')) {
        await userRef.update({
          'Status': 'Active',
        });
      } else {
        await userRef.update({
          'status': 'Active',
        });
      }

      _pendingOrganizerApprovals.removeWhere(
            (doc) => doc.id == userRef.id,
      );

      final index =
      _users.indexWhere(
            (user) => user.userId == userId,
      );

      if (index != -1) {
        _users[index] =
            _users[index].copyWith(
              status: 'Active',
            );
      }

      _systemLogs.insert(
        0,
        {
          'title':
          'Organizer Approved',
          'subtitle':
          'Organizer account $userId was approved.',
          'time':
          'Just now',
          'type':
          'approval',
        },
      );

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error approving organizer: $e',
      );

      _errorMessage =
      'Could not approve organizer.';

      notifyListeners();

      return false;
    }
  }

  Future<bool> rejectOrganizer(
      String userId,
      ) async {
    try {
      final userRef =
      await _findUserDocument(userId);

      if (userRef == null) {
        _errorMessage =
        'Organizer not found.';

        notifyListeners();

        return false;
      }

      final snapshot =
      await userRef.get();

      final data =
          snapshot.data() ?? {};

      if (data.containsKey('Status')) {
        await userRef.update({
          'Status': 'Rejected',
        });
      } else {
        await userRef.update({
          'status': 'Rejected',
        });
      }

      _pendingOrganizerApprovals.removeWhere(
            (doc) => doc.id == userRef.id,
      );

      final index =
      _users.indexWhere(
            (user) => user.userId == userId,
      );

      if (index != -1) {
        _users[index] =
            _users[index].copyWith(
              status: 'Rejected',
            );
      }

      _systemLogs.insert(
        0,
        {
          'title':
          'Organizer Rejected',
          'subtitle':
          'Organizer account $userId was rejected.',
          'time':
          'Just now',
          'type':
          'approval',
        },
      );

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error rejecting organizer: $e',
      );

      _errorMessage =
      'Could not reject organizer.';

      notifyListeners();

      return false;
    }
  }

  Future<void> fetchFlaggedContent() async {
    try {
      final snapshot =
      await _firestore
          .collection('gallery')
          .where(
        'flagged',
        isEqualTo: true,
      )
          .get();

      _flaggedGalleryItems =
          snapshot.docs;

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Error fetching flagged content: $e',
      );

      _errorMessage =
      'Could not load flagged content.';

      notifyListeners();
    }
  }

  void ignoreModerationItem(
      String id,
      ) {
    _flaggedGalleryItems.removeWhere(
          (doc) => doc.id == id,
    );

    notifyListeners();
  }

  Future<bool> deleteModerationItem(
      String id,
      ) async {
    try {
      await _firestore
          .collection('gallery')
          .doc(id)
          .delete();

      _flaggedGalleryItems.removeWhere(
            (doc) => doc.id == id,
      );

      _systemLogs.insert(
        0,
        {
          'title':
          'Content Removed',
          'subtitle':
          'Flagged gallery item was deleted.',
          'time':
          'Just now',
          'type':
          'moderation',
        },
      );

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error deleting content: $e',
      );

      _errorMessage =
      'Could not delete content.';

      notifyListeners();

      return false;
    }
  }
  Future<void> fetchReportMetrics() async {
    try {
      final registrationsSnapshot =
      await _firestore
          .collection('registrations')
          .get();

      _totalRegistrationsCount =
          registrationsSnapshot.docs
              .where((doc) {
            final data = doc.data();

            final status =
            (
                data['status'] ??
                    data['Status'] ??
                    ''
            )
                .toString()
                .trim()
                .toLowerCase();

            return status != 'cancelled';
          }).length;

      final feedbackSnapshot =
      await _firestore
          .collection('feedback')
          .get();

      if (feedbackSnapshot.docs.isEmpty) {
        _averageFeedbackRating = 0.0;
      } else {
        double total = 0.0;
        int validRatings = 0;

        for (final doc
        in feedbackSnapshot.docs) {
          final data = doc.data();

          final ratingRaw =
              data['rating'] ??
                  data['Rating'];

          double? rating;

          if (ratingRaw is num) {
            rating =
                ratingRaw.toDouble();
          } else {
            rating =
                double.tryParse(
                  ratingRaw?.toString() ?? '',
                );
          }

          if (rating != null) {
            total += rating;
            validRatings++;
          }
        }

        if (validRatings > 0) {
          _averageFeedbackRating =
              total / validRatings;
        } else {
          _averageFeedbackRating = 0.0;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Error fetching report metrics: $e',
      );

      _errorMessage =
      'Could not load report metrics.';

      notifyListeners();
    }
  }

  Future<void> fetchAllEventsForAdmin() async {
    try {
      final snapshot =
      await _firestore
          .collection('Events')
          .get();

      _allEvents = snapshot.docs;

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Error fetching all events: $e',
      );
    }
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await Future.wait([
        fetchUsers(),
        fetchPendingApprovals(),
        fetchFlaggedContent(),
        fetchReportMetrics(),
        fetchAllEventsForAdmin(),
      ]);
    } catch (e) {
      debugPrint(
        'Error loading dashboard data: $e',
      );

      _errorMessage =
      'Could not load dashboard data.';
    }

    _isLoading = false;

    notifyListeners();
  }
  Future<bool> suspendEvent(
      String eventId,
      ) async {
    try {
      final eventRef =
      _firestore
          .collection('Events')
          .doc(eventId);

      final snapshot =
      await eventRef.get();

      if (!snapshot.exists) {
        _errorMessage =
        'Event not found.';

        notifyListeners();

        return false;
      }

      final data =
          snapshot.data() ?? {};

      if (data.containsKey('Status')) {
        await eventRef.update({
          'Status': 'Suspended',
          'updatedAt':
          FieldValue.serverTimestamp(),
        });
      } else {
        await eventRef.update({
          'status': 'Suspended',
          'updatedAt':
          FieldValue.serverTimestamp(),
        });
      }

      await fetchAllEventsForAdmin();

      _systemLogs.insert(
        0,
        {
          'title':
          'Event Suspended',
          'subtitle':
          'Event $eventId was suspended.',
          'time':
          'Just now',
          'type':
          'moderation',
        },
      );

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error suspending event: $e',
      );

      _errorMessage =
      'Could not suspend event.';

      notifyListeners();

      return false;
    }
  }

  Future<bool> activateEvent(
      String eventId,
      ) async {
    try {
      final eventRef =
      _firestore
          .collection('Events')
          .doc(eventId);

      final snapshot =
      await eventRef.get();

      if (!snapshot.exists) {
        _errorMessage =
        'Event not found.';

        notifyListeners();

        return false;
      }

      final data =
          snapshot.data() ?? {};

      if (data.containsKey('Status')) {
        await eventRef.update({
          'Status': 'Approved',
          'updatedAt':
          FieldValue.serverTimestamp(),
        });
      } else {
        await eventRef.update({
          'status': 'Approved',
          'updatedAt':
          FieldValue.serverTimestamp(),
        });
      }

      await fetchAllEventsForAdmin();

      _systemLogs.insert(
        0,
        {
          'title':
          'Event Activated',
          'subtitle':
          'Event $eventId was reactivated.',
          'time':
          'Just now',
          'type':
          'approval',
        },
      );

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error activating event: $e',
      );

      _errorMessage =
      'Could not activate event.';

      notifyListeners();

      return false;
    }
  }

  Future<bool> cancelEvent(
      String eventId,
      ) async {
    try {
      final eventRef =
      _firestore
          .collection('Events')
          .doc(eventId);

      final eventSnapshot =
      await eventRef.get();

      if (!eventSnapshot.exists) {
        _errorMessage =
        'Event not found.';

        notifyListeners();

        return false;
      }

      final eventData =
          eventSnapshot.data() ?? {};

      final eventTitle =
      (
          eventData['title'] ??
              eventData['Title'] ??
              'the event'
      ).toString();

      if (eventData.containsKey('Status')) {
        await eventRef.update({
          'Status': 'Cancelled',
          'updatedAt':
          FieldValue.serverTimestamp(),
        });
      } else {
        await eventRef.update({
          'status': 'Cancelled',
          'updatedAt':
          FieldValue.serverTimestamp(),
        });
      }

      final registrations =
      await _firestore
          .collection('registrations')
          .where(
        'eventId',
        isEqualTo: eventId,
      )
          .get();

      if (registrations.docs.isNotEmpty) {
        WriteBatch batch =
        _firestore.batch();

        int batchCount = 0;

        for (final regDoc
        in registrations.docs) {
          final data =
          regDoc.data();

          final status =
          (
              data['status'] ??
                  data['Status'] ??
                  ''
          )
              .toString()
              .trim()
              .toLowerCase();

          if (status == 'cancelled') {
            continue;
          }

          final userId =
          (
              data['userId'] ??
                  data['UserId'] ??
                  ''
          )
              .toString()
              .trim();

          if (userId.isEmpty) {
            continue;
          }

          if (!await NotificationService.isPushNotificationsEnabled(userId)) {
            continue;
          }

          final notificationRef =
          _firestore
              .collection('notifications')
              .doc();

          batch.set(
            notificationRef,
            {
              'userId': userId,
              'eventId': eventId,
              'title':
              'Event Cancelled',
              'message':
              '$eventTitle has been cancelled by the organizer.',
              'type':
              'cancellation',
              'isRead':
              false,
              'createdAt':
              FieldValue.serverTimestamp(),
            },
          );

          batchCount++;

          if (batchCount >= 450) {
            await batch.commit();

            batch =
                _firestore.batch();

            batchCount = 0;
          }
        }

        if (batchCount > 0) {
          await batch.commit();
        }
      }

      await fetchAllEventsForAdmin();

      _systemLogs.insert(
        0,
        {
          'title':
          'Event Cancelled',
          'subtitle':
          '$eventTitle was cancelled by admin.',
          'time':
          'Just now',
          'type':
          'moderation',
        },
      );

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error cancelling event: $e',
      );

      _errorMessage =
      'Could not cancel event.';

      notifyListeners();

      return false;
    }
  }

  Future<bool> deleteEvent(
      String eventId,
      ) async {
    try {
      await _firestore
          .collection('Events')
          .doc(eventId)
          .delete();

      _allEvents.removeWhere(
            (doc) => doc.id == eventId,
      );

      _pendingEventApprovals.removeWhere(
            (doc) => doc.id == eventId,
      );

      _systemLogs.insert(
        0,
        {
          'title':
          'Event Deleted',
          'subtitle':
          'Event $eventId was permanently deleted.',
          'time':
          'Just now',
          'type':
          'moderation',
        },
      );

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error deleting event: $e',
      );

      _errorMessage =
      'Could not delete event.';

      notifyListeners();

      return false;
    }
  }

  Future<bool> editEvent({
    required String eventId,
    required String title,
    required String description,
    required String category,
    required double price,
    required String organizer,
    required String organizerId,
    required String imageUrl,
    required String location,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String rules,
    required String contactInfo,
    required int maxParticipants,
    required int availableSeats,
    required String status,
  }) async {
    try {
      _errorMessage = null;

      final eventRef =
      _firestore
          .collection('Events')
          .doc(eventId);

      final snapshot =
      await eventRef.get();

      if (!snapshot.exists) {
        _errorMessage =
        'Event not found.';

        notifyListeners();

        return false;
      }

      final existingData =
          snapshot.data() ?? {};

      final updateData =
      <String, dynamic>{
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'organizer': organizer,
        'organizerId': organizerId,
        'imageUrl': imageUrl,
        'location': location,
        'date':
        Timestamp.fromDate(date),
        'startTime': startTime,
        'endTime': endTime,
        'rules': rules,
        'contactInfo': contactInfo,
        'maxParticipants':
        maxParticipants,
        'availableSeats':
        availableSeats,
        'status': status,
        'updatedAt':
        FieldValue.serverTimestamp(),
      };

      if (existingData.containsKey('Status')) {
        updateData.remove('status');

        updateData['Status'] =
            status;
      }

      await eventRef.update(
        updateData,
      );

      await fetchAllEventsForAdmin();

      await fetchPendingApprovals();

      _systemLogs.insert(
        0,
        {
          'title':
          'Event Updated',
          'subtitle':
          '$title was edited.',
          'time':
          'Just now',
          'type':
          'approval',
        },
      );

      _errorMessage = null;

      notifyListeners();

      return true;
    } on FirebaseException catch (e) {
      debugPrint(
        'Error editing event (${e.code}): ${e.message}',
      );

      _errorMessage = _eventUpdateErrorMessage(e);

      notifyListeners();

      return false;
    } catch (e) {
      debugPrint(
        'Error editing event: $e',
      );

      _errorMessage = 'Could not update event. Please try again.';

      notifyListeners();

      return false;
    }
  }
  
  String _eventUpdateErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to update this event. '
            'Please sign in with an approved admin account.';
      case 'not-found':
        return 'This event no longer exists. Refresh the list and try again.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Unable to reach the server. Check your internet connection and try again.';
      case 'unauthenticated':
        return 'Your session has expired. Please sign in again.';
      default:
        return 'Could not update event (${error.code}). Please try again.';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
