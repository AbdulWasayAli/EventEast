import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../models/registration_model.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class EventProvider with ChangeNotifier {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static const String _eventsCollection = 'Events';
  static const String _registrationsCollection = 'registrations';
  static const String _favoritesCollection = 'favorites';
  static const String _usersCollection = 'users';
  static const String _notificationsCollection = 'notifications';

  List<EventModel> _events = [];

  List<RegistrationModel> _userRegistrations = [];

  List<NotificationModel> _notifications = [];

  bool _isLoading = false;

  String? _errorMessage;

  Map<String, bool> _notificationPreferences = {
    'reminders': true,
    'updates': true,
    'announcements': true,
    'feedback': true,
  };


  List<EventModel> get events =>
      List.unmodifiable(_events);

  List<RegistrationModel> get userRegistrations =>
      List.unmodifiable(_userRegistrations);

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Map<String, bool> get notificationPreferences =>
      Map.unmodifiable(_notificationPreferences);


  List<EventModel> get registeredEvents {
    return _events
        .where((event) => event.isRegistered)
        .toList();
  }


  List<EventModel> get myUpcomingEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _events.where((event) {
      if (!event.isRegistered) return false;
      final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
      return eventDate.isAtSameMomentAs(today) || eventDate.isAfter(today);
    }).toList();
  }


  List<EventModel> get myCompletedEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _events.where((event) {
      if (!event.isRegistered) return false;
      final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
      return eventDate.isBefore(today);
    }).toList();
  }


  List<EventModel> get myCancelledEvents {
    final cancelledEventIds = _userRegistrations
        .where((reg) => reg.status.trim().toLowerCase() == 'cancelled')
        .map((reg) => reg.eventId)
        .toSet();

    return _events
        .where((event) => cancelledEventIds.contains(event.id))
        .toList();
  }



  List<EventModel> get favoriteEvents {
    return _events
        .where((event) => event.isFavorite)
        .toList();
  }



  Future<void> fetchEvents({
    bool includePending = false,
    bool loadUserData = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .get();

      final List<EventModel> loadedEvents =
      snapshot.docs
          .map(
            (doc) => EventModel.fromMap(
          doc.data(),
          doc.id,
        ),
      )
          .where((event) {
        final String status =
        event.status.trim().toLowerCase();

        if (includePending) {
          return status == 'approved' ||
              status == 'active' ||
              status == 'pending' ||
              status == 'pending approval' ||
              status == 'pending_approval' ||
              status == 'suspended';
        }

        return status == 'approved' ||
            status == 'active';
      }).toList();

      _events = loadedEvents;

      if (loadUserData) {
        await fetchUserRegistrations(
          notify: false,
        );

        await fetchUserFavorites(
          notify: false,
        );

        await loadNotifications(
          notify: false,
        );

        await loadNotificationPreferences(
          notify: false,
        );
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage =
      'Failed to load events. Please check your connection.';

      debugPrint(
        'Error fetching events: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchManageEvents() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .get();

      final List<EventModel> loadedEvents =
      snapshot.docs
          .map(
            (doc) => EventModel.fromMap(
          doc.data(),
          doc.id,
        ),
      )
          .toList();

      _events = loadedEvents;

      await fetchUserFavorites(
        notify: false,
      );

      _errorMessage = null;

      debugPrint(
        '====================================',
      );

      debugPrint(
        'MANAGE EVENTS: ${_events.length}',
      );

      for (final event in _events) {
        debugPrint(
          'ID: ${event.id} | '
              'TITLE: ${event.title} | '
              'STATUS: ${event.status}',
        );
      }

      debugPrint(
        '====================================',
      );
    } catch (e) {
      _errorMessage =
      'Failed to load manage events. Please check your connection.';

      debugPrint(
        'Error fetching manage events: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshEvents({
    bool includePending = false,
  }) async {
    await fetchEvents(
      includePending: includePending,
    );
  }

  Future<void> refreshManageEvents() async {
    await fetchManageEvents();
  }

  Future<bool> updateEvent(
      EventModel updatedEvent,
      ) async {
    try {
      _errorMessage = null;

      await _firestore
          .collection(_eventsCollection)
          .doc(updatedEvent.id)
          .update(
        updatedEvent.toMap(),
      );

      final int index = _events.indexWhere(
            (event) => event.id == updatedEvent.id,
      );

      if (index != -1) {
        final EventModel oldEvent =
        _events[index];

        _events[index] = updatedEvent.copyWith(
          isRegistered: oldEvent.isRegistered,
          isFavorite: oldEvent.isFavorite,
        );
      }

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage =
      'Could not update event. Please try again.';

      debugPrint(
        'Error updating event: $e',
      );

      notifyListeners();

      return false;
    }
  }
  Future<bool> editEvent({
    required String eventId,
    String? title,
    String? description,
    String? category,
    double? price,
    String? organizer,
    String? organizerId,
    String? imageUrl,
    String? location,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? rules,
    String? contactInfo,
    int? maxParticipants,
    int? availableSeats,
    String? status,
  }) async {
    try {
      final EventModel? oldEvent =
      getEventById(eventId);

      if (oldEvent == null) {
        _errorMessage = 'Event not found.';
        notifyListeners();
        return false;
      }

      final EventModel updatedEvent =
      oldEvent.copyWith(
        title: title,
        description: description,
        category: category,
        price: price,
        organizer: organizer,
        organizerId: organizerId,
        imageUrl: imageUrl,
        location: location,
        date: date,
        startTime: startTime,
        endTime: endTime,
        rules: rules,
        contactInfo: contactInfo,
        maxParticipants: maxParticipants,
        availableSeats: availableSeats,
        status: status,
      );

      return await updateEvent(
        updatedEvent,
      );
    } catch (e) {
      _errorMessage =
      'Could not edit event.';

      debugPrint(
        'Error editing event: $e',
      );

      notifyListeners();

      return false;
    }
  }
  Future<bool> deleteEvent(
      String eventId,
      ) async {
    try {
      _errorMessage = null;

      final int index = _events.indexWhere(
            (event) => event.id == eventId,
      );

      if (index == -1) {
        _errorMessage = 'Event not found.';
        notifyListeners();
        return false;
      }

      final EventModel deletedEvent =
      _events[index];

      await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .delete();

      try {
        final favoritesSnapshot =
        await _firestore
            .collection(_favoritesCollection)
            .where(
          'eventId',
          isEqualTo: eventId,
        )
            .get();

        if (favoritesSnapshot.docs.isNotEmpty) {
          final WriteBatch batch =
          _firestore.batch();

          for (final doc
          in favoritesSnapshot.docs) {
            batch.delete(doc.reference);
          }

          await batch.commit();
        }
      } catch (e) {
        debugPrint(
          'Could not delete event favorites: $e',
        );
      }

      _events.removeAt(index);

      notifyListeners();

      debugPrint(
        'Event deleted: ${deletedEvent.title}',
      );

      return true;
    } catch (e) {
      _errorMessage =
      'Could not delete event. Please try again.';

      debugPrint(
        'Error deleting event: $e',
      );

      notifyListeners();

      return false;
    }
  }
  Future<bool> suspendEvent(
      String eventId,
      ) async {
    try {
      final int index = _events.indexWhere(
            (event) => event.id == eventId,
      );

      if (index == -1) {
        _errorMessage = 'Event not found.';
        notifyListeners();
        return false;
      }

      final EventModel oldEvent =
      _events[index];

      await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .update({
        'status': 'Suspended',
      });

      _events[index] = oldEvent.copyWith(
        status: 'Suspended',
      );

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage =
      'Could not suspend event. Please try again.';

      debugPrint(
        'Error suspending event: $e',
      );

      notifyListeners();

      return false;
    }
  }
  Future<bool> activateEvent(
      String eventId,
      ) async {
    try {
      final int index = _events.indexWhere(
            (event) => event.id == eventId,
      );

      if (index == -1) {
        _errorMessage = 'Event not found.';
        notifyListeners();
        return false;
      }

      final EventModel oldEvent =
      _events[index];

      await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .update({
        'status': 'Approved',
      });

      _events[index] = oldEvent.copyWith(
        status: 'Approved',
      );

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage =
      'Could not activate event. Please try again.';

      debugPrint(
        'Error activating event: $e',
      );

      notifyListeners();

      return false;
    }
  }

  Future<void> fetchUserRegistrations({
    bool notify = true,
  }) async {
    try {
      final User? user =
          _auth.currentUser;

      if (user == null) {
        _userRegistrations = [];

        for (final event in _events) {
          event.isRegistered = false;
        }

        if (notify) {
          notifyListeners();
        }

        return;
      }

      final snapshot = await _firestore
          .collection(_registrationsCollection)
          .where(
        'userId',
        isEqualTo: user.uid,
      )
          .get();

      _userRegistrations = snapshot.docs
          .map(
            (doc) =>
            RegistrationModel.fromMap(
              doc.data(),
              doc.id,
            ),
      )
          .toList();

      for (final event in _events) {
        event.isRegistered =
            _userRegistrations.any(
                  (registration) =>
              registration.eventId ==
                  event.id &&
                  registration.status
                      .trim()
                      .toLowerCase() !=
                      'cancelled',
            );
      }

      if (notify) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
        'Error fetching user registrations: $e',
      );
    }
  }
  Future<void> fetchUserFavorites({
    bool notify = true,
  }) async {
    try {
      final User? user =
          _auth.currentUser;

      if (user == null) {
        for (final event in _events) {
          event.isFavorite = false;
        }

        if (notify) {
          notifyListeners();
        }

        return;
      }

      final snapshot = await _firestore
          .collection(_favoritesCollection)
          .where(
        'userId',
        isEqualTo: user.uid,
      )
          .get();

      final Set<String> favoriteEventIds =
      snapshot.docs
          .map(
            (doc) =>
        doc.data()['eventId']
            ?.toString() ??
            '',
      )
          .where(
            (id) => id.isNotEmpty,
      )
          .toSet();

      for (final event in _events) {
        event.isFavorite =
            favoriteEventIds.contains(
              event.id,
            );
      }

      if (notify) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
        'Error fetching user favorites: $e',
      );
    }
  }
  EventModel findById(
      String eventId,
      ) {
    return _events.firstWhere(
          (event) => event.id == eventId,
      orElse: () => throw Exception(
        'Event not found: $eventId',
      ),
    );
  }
  EventModel? getEventById(
      String eventId,
      ) {
    for (final event in _events) {
      if (event.id == eventId) {
        return event;
      }
    }

    return null;
  }
  Future<bool> toggleFavoriteStatus(
      String eventId,
      ) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      _errorMessage =
      'Please log in to save favorites.';

      notifyListeners();

      return false;
    }

    final int index = _events.indexWhere(
          (event) => event.id == eventId,
    );

    if (index == -1) {
      _errorMessage =
      'Event not found.';

      notifyListeners();

      return false;
    }

    final EventModel event =
    _events[index];

    final bool oldStatus =
        event.isFavorite;

    final bool newStatus =
    !oldStatus;

    event.isFavorite = newStatus;

    _errorMessage = null;

    notifyListeners();

    try {
      final favoritesRef =
      _firestore.collection(
        _favoritesCollection,
      );

      if (newStatus) {
        final existing =
        await favoritesRef
            .where(
          'userId',
          isEqualTo: user.uid,
        )
            .where(
          'eventId',
          isEqualTo: eventId,
        )
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          await favoritesRef.add({
            'userId': user.uid,
            'eventId': eventId,
            'createdAt':
            FieldValue.serverTimestamp(),
          });
        }
      } else {
        final snapshot =
        await favoritesRef
            .where(
          'userId',
          isEqualTo: user.uid,
        )
            .where(
          'eventId',
          isEqualTo: eventId,
        )
            .get();

        if (snapshot.docs.isNotEmpty) {
          final WriteBatch batch =
          _firestore.batch();

          for (final doc
          in snapshot.docs) {
            batch.delete(doc.reference);
          }

          await batch.commit();
        }
      }

      return true;
    } catch (e) {
      debugPrint(
        'Error toggling favorite: $e',
      );

      event.isFavorite = oldStatus;

      _errorMessage =
      'Could not update favorites. Please try again.';

      notifyListeners();

      return false;
    }
  }

  Future<String> _getUserName(
      User user,
      ) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();

        final dynamic name =
        data?['name'];

        if (name != null &&
            name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }

        final dynamic displayName =
        data?['displayName'];

        if (displayName != null &&
            displayName
                .toString()
                .trim()
                .isNotEmpty) {
          return displayName
              .toString()
              .trim();
        }
      }
    } catch (e) {
      debugPrint(
        'Error getting user name: $e',
      );
    }

    if (user.displayName != null &&
        user.displayName!
            .trim()
            .isNotEmpty) {
      return user.displayName!.trim();
    }

    if (user.email != null &&
        user.email!.contains('@')) {
      return user.email!.split('@').first;
    }

    return 'Attendee User';
  }
  Future<bool> registerForEvent(
    String eventId, {
    String paymentMethod = 'free',
  }) async {
    try {
      final User? user =
          _auth.currentUser;

      if (user == null) {
        _errorMessage =
        'Please log in to register.';

        notifyListeners();

        return false;
      }

      final int eventIndex =
      _events.indexWhere(
            (event) => event.id == eventId,
      );

      if (eventIndex == -1) {
        _errorMessage =
        'Event not found.';

        notifyListeners();

        return false;
      }

      final existingSnapshot =
      await _firestore
          .collection(
        _registrationsCollection,
      )
          .where(
        'userId',
        isEqualTo: user.uid,
      )
          .where(
        'eventId',
        isEqualTo: eventId,
      )
          .get();

      DocumentSnapshot<
          Map<String, dynamic>>?
      cancelledRegistration;

      for (final doc
      in existingSnapshot.docs) {
        final String status =
        (doc.data()['status'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        if (status != 'cancelled') {
          _events[eventIndex]
              .isRegistered = true;

          _errorMessage =
          'You are already registered for this event.';

          notifyListeners();

          return false;
        }

        cancelledRegistration = doc;
      }

      final String userName =
      await _getUserName(user);

      final DocumentReference<
          Map<String, dynamic>> eventRef =
      _firestore
          .collection(_eventsCollection)
          .doc(eventId);

      final DocumentReference<
          Map<String, dynamic>>
      registrationRef;

      if (cancelledRegistration !=
          null) {
        registrationRef =
            cancelledRegistration.reference;
      } else {
        registrationRef = _firestore
            .collection(
          _registrationsCollection,
        )
            .doc();
      }

      bool success = false;

      String? failReason;

      await _firestore.runTransaction(
            (transaction) async {
          final eventSnap =
          await transaction.get(
            eventRef,
          );

          if (!eventSnap.exists) {
            failReason =
            'Event no longer exists.';
            return;
          }

          final Map<String, dynamic>
          data =
          eventSnap.data()!;

          final String status =
          (data['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

          if (status != 'approved' &&
              status != 'active') {
            failReason =
            'Registration is not open for this event.';
            return;
          }

          final double eventPrice =
              double.tryParse(data['price']?.toString() ?? '') ?? 0;
          final bool isPaidEvent = eventPrice > 0;
          final String normalizedPaymentMethod = paymentMethod.trim().toLowerCase();

          if (isPaidEvent &&
              (normalizedPaymentMethod.isEmpty || normalizedPaymentMethod == 'free')) {
            failReason = 'Please select a payment method for this paid event.';
            return;
          }

          final int maxParticipants =
          _safeInt(
            data['maxParticipants'],
          );

          int availableSeats =
          _safeInt(
            data['availableSeats'],
          );

          if (!data.containsKey(
            'availableSeats',
          )) {
            availableSeats =
                maxParticipants;
          }

          if (maxParticipants > 0 &&
              availableSeats <= 0) {
            failReason =
            'This event is fully booked.';
            return;
          }

          final RegistrationModel
          registration =
          RegistrationModel(
            id: registrationRef.id,
            eventId: eventId,
            userId: user.uid,
            userName: userName,
            email:
            user.email ?? 'No Email',
            registrationDate:
            DateTime.now(),
            status: 'Confirmed',
            qrCode:
            registrationRef.id,
            paymentMethod: isPaidEvent ? normalizedPaymentMethod : 'free',
            paymentStatus: isPaidEvent ? 'paid' : 'notRequired',
            amountPaid: isPaidEvent ? eventPrice : 0,
          );

          transaction.set(
            registrationRef,
            registration.toMap(),
          );

          final Map<String, dynamic>
          eventUpdate = {};

          if (maxParticipants > 0) {
            eventUpdate[
            'availableSeats'] =
                availableSeats - 1;
          }

          if (eventUpdate.isNotEmpty) {
            transaction.update(
              eventRef,
              eventUpdate,
            );
          }

          success = true;
        },
      );

      if (!success) {
        _errorMessage =
            failReason ??
                'Registration failed. Please try again.';

        notifyListeners();

        return false;
      }

      _events[eventIndex]
          .isRegistered = true;

      await fetchUserRegistrations(
        notify: false,
      );

      final EventModel event =
      _events[eventIndex];

      await createNotification(
        title: 'Registration Confirmed',
        message:
        'You have successfully registered for ${event.title}.',
        type:
        'registration_confirmation',
        eventId: eventId,
        userId: user.uid,
      );

      await NotificationService.sendNotification(
        recipientUserId: user.uid,
        title: 'Registration Confirmed! 🎫',
        message: 'You have successfully registered for ${event.title}.',
        eventId: eventId,
        type: 'registration_confirmation',
      );
      final String? organizerId = event.organizerId;
      if (organizerId != null && organizerId.isNotEmpty && organizerId != user.uid) {
        await NotificationService.sendNotification(
          recipientUserId: organizerId,
          title: 'New Registration! 🎉',
          message: '${userName} has registered for your event "${event.title}".',
          eventId: eventId,
          type: 'new_registration',
        );
      }

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error registering for event: $e',
      );

      _errorMessage =
      'Something went wrong. Please check your connection.';

      notifyListeners();

      return false;
    }
  }

  Future<bool> cancelRegistration(
      String eventId,
      ) async {
    try {
      final User? user =
          _auth.currentUser;

      if (user == null) {
        _errorMessage =
        'Please log in.';

        notifyListeners();

        return false;
      }

      final RegistrationModel?
      registration =
      getActiveRegistrationForEvent(
        eventId,
      );

      if (registration == null) {
        _errorMessage =
        'Active registration not found.';

        notifyListeners();

        return false;
      }

      final DocumentReference<
          Map<String, dynamic>> eventRef =
      _firestore
          .collection(_eventsCollection)
          .doc(eventId);

      final DocumentReference<
          Map<String, dynamic>>
      registrationRef =
      _firestore
          .collection(
        _registrationsCollection,
      )
          .doc(registration.id);

      await _firestore.runTransaction(
            (transaction) async {
          final eventSnap =
          await transaction.get(
            eventRef,
          );

          final registrationSnap =
          await transaction.get(
            registrationRef,
          );

          if (!registrationSnap.exists) {
            throw Exception(
              'Registration no longer exists.',
            );
          }

          final registrationData =
          registrationSnap.data()!;

          final String currentStatus =
          (registrationData['status'] ??
              '')
              .toString()
              .trim()
              .toLowerCase();

          if (currentStatus ==
              'cancelled') {
            throw Exception(
              'This registration is already cancelled.',
            );
          }

          int newAvailableSeats = 0;

          if (eventSnap.exists) {
            final Map<String, dynamic>
            data =
            eventSnap.data()!;

            final int
            currentAvailableSeats =
            _safeInt(
              data['availableSeats'],
            );

            final int maxParticipants =
            _safeInt(
              data['maxParticipants'],
            );

            newAvailableSeats =
                currentAvailableSeats + 1;

            if (maxParticipants > 0 &&
                newAvailableSeats >
                    maxParticipants) {
              newAvailableSeats =
                  maxParticipants;
            }

            transaction.update(
              eventRef,
              {
                'availableSeats':
                newAvailableSeats,
              },
            );
          }

          transaction.update(
            registrationRef,
            {
              'status': 'Cancelled',
              'cancelledAt':
              FieldValue.serverTimestamp(),
            },
          );
        },
      );

      final int eventIndex =
      _events.indexWhere(
            (event) => event.id == eventId,
      );

      if (eventIndex != -1) {
        _events[eventIndex]
            .isRegistered = false;
      }

      await fetchUserRegistrations(
        notify: false,
      );

      if (eventIndex != -1) {
        final EventModel event =
        _events[eventIndex];

        await createNotification(
          title: 'Registration Cancelled',
          message:
          'Your registration for ${event.title} has been cancelled.',
          type: 'cancellation',
          eventId: eventId,
          userId: user.uid,
        );
      }

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        'Error cancelling registration: $e',
      );

      final String message =
      e.toString().replaceFirst(
        'Exception: ',
        '',
      );

      _errorMessage = message.isNotEmpty
          ? message
          : 'Could not cancel registration. Please try again.';

      notifyListeners();

      return false;
    }
  }
  RegistrationModel?
  getRegistrationForEvent(
      String eventId,
      ) {
    for (final registration
    in _userRegistrations) {
      if (registration.eventId ==
          eventId) {
        return registration;
      }
    }

    return null;
  }

  RegistrationModel?
  getActiveRegistrationForEvent(
      String eventId,
      ) {
    for (final registration
    in _userRegistrations) {
      if (registration.eventId ==
          eventId &&
          registration.status
              .trim()
              .toLowerCase() !=
              'cancelled') {
        return registration;
      }
    }

    return null;
  }
  String? getRegistrationId(
      String eventId,
      ) {
    return getActiveRegistrationForEvent(
      eventId,
    )?.id;
  }
  bool isRegisteredForEvent(
      String eventId,
      ) {
    return _userRegistrations.any(
          (registration) =>
      registration.eventId ==
          eventId &&
          registration.status
              .trim()
              .toLowerCase() !=
              'cancelled',
    );
  }

  bool isFavoriteEvent(
      String eventId,
      ) {
    return getEventById(
      eventId,
    )?.isFavorite ??
        false;
  }

  List<EventModel> searchEvents(
      String query,
      ) {
    final String searchQuery =
    query.trim().toLowerCase();

    if (searchQuery.isEmpty) {
      return List<EventModel>.from(
        _events,
      );
    }

    return _events.where((event) {
      return event.title
          .toLowerCase()
          .contains(searchQuery) ||
          event.description
              .toLowerCase()
              .contains(searchQuery) ||
          event.category
              .toLowerCase()
              .contains(searchQuery) ||
          event.location
              .toLowerCase()
              .contains(searchQuery) ||
          event.organizer
              .toLowerCase()
              .contains(searchQuery);
    }).toList();
  }

  List<EventModel> getEventsByCategory(
      String category,
      ) {
    if (category.trim().toLowerCase() == 'all') {
      return List<EventModel>.from(_events);
    }

    return _events.where((event) {
      return event.category.trim().toLowerCase() ==
          category.trim().toLowerCase();
    }).toList();
  }

  Future<void> loadNotifications({
    bool notify = true,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        _notifications = [];
        if (notify) notifyListeners();
        return;
      }

      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      _notifications = snapshot.docs
          .map(
            (doc) => NotificationModel.fromMap(
          doc.data(),
          doc.id,
        ),
      )
          .toList();

      if (notify) notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> loadNotificationPreferences({
    bool notify = true,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .get();

      if (doc.exists &&
          doc.data()!.containsKey('notificationPreferences')) {
        final prefs = doc.data()!['notificationPreferences'];
        if (prefs is Map) {
          _notificationPreferences = prefs.map(
                (key, value) =>
                MapEntry(key.toString(), value == true),
          );
        }
      }
      if (notify) notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    }
  }

  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    String? eventId,
    required String userId,
  }) async {
    try {
      if (!await NotificationService.isPushNotificationsEnabled(userId)) {
        return;
      }

      await _firestore.collection(_notificationsCollection).add({
        'userId': userId,
        'eventId': eventId ?? '',
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }
  
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});

      await loadNotifications(notify: true);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      await loadNotifications(notify: true);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _notifications = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> restoreNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());

      await loadNotifications(notify: true);
    } catch (e) {
      debugPrint('Error restoring notification: $e');
    }
  }

  Future<void> updateNotificationPreference(String key, bool value) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      _notificationPreferences[key] = value;
      notifyListeners();

      await _firestore.collection(_usersCollection).doc(user.uid).set({
        'notificationPreferences': _notificationPreferences,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating notification preference: $e');
    }
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
