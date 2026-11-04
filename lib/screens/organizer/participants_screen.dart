import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/premium_ui.dart';

class ParticipantsScreen extends StatefulWidget {
  final String? eventId;

  const ParticipantsScreen({
    super.key,
    this.eventId,
  });

  @override
  State<ParticipantsScreen> createState() =>
      _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    final String? organizerId = currentUser?.uid;

    
    if (organizerId == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const SettingsStyleAppBar(
          title: 'Attendees',
        ),
        body: Center(
          child: Text(
            'Please login first.',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.blueGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // SCREEN
    // ----------------------------------------------------------

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: SettingsStyleAppBar(
        title: widget.eventId == null ? 'Attendees' : 'Event Attendees',
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildEventsAndParticipants(
              organizerId,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EVENTS + PARTICIPANTS
  // ============================================================

  Widget _buildEventsAndParticipants(
      String organizerId,
      ) {
    Query<Map<String, dynamic>> eventQuery =
    FirebaseFirestore.instance
        .collection('Events')
        .where(
      'organizerId',
      isEqualTo: organizerId,
    );

    // ----------------------------------------------------------
    // IF SPECIFIC EVENT
    // ----------------------------------------------------------

    if (widget.eventId != null &&
        widget.eventId!.trim().isNotEmpty) {
      return FutureBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('Events')
            .doc(widget.eventId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(
              'Error loading event:\n${snapshot.error}',
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return _buildEmptyState(
              icon: Icons.event_busy_rounded,
              title: 'Event not found',
              subtitle:
              'This event could not be found.',
            );
          }

          final eventData =
          snapshot.data!.data();

          if (eventData == null) {
            return _buildEmptyState(
              icon: Icons.event_busy_rounded,
              title: 'Event not found',
              subtitle:
              'Event information is unavailable.',
            );
          }

          // ----------------------------------------------------
          // SECURITY CHECK
          // ----------------------------------------------------

          final String eventOrganizerId =
          (eventData['organizerId'] ?? '')
              .toString();

          if (eventOrganizerId != organizerId) {
            return _buildErrorState(
              'You are not authorized to view this event.',
            );
          }

          final Map<String, String> eventTitles = {
            snapshot.data!.id:
            (eventData['title'] ??
                'Untitled Event')
                .toString(),
          };

          return _buildRegistrations(
            [snapshot.data!.id],
            eventTitles,
          );
        },
      );
    }

    // ----------------------------------------------------------
    // ALL ORGANIZER EVENTS
    // ----------------------------------------------------------

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: eventQuery.snapshots(),
      builder: (context, eventSnapshot) {
        if (eventSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (eventSnapshot.hasError) {
          return _buildErrorState(
            'Error loading events:\n${eventSnapshot.error}',
          );
        }

        final docs =
            eventSnapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_busy_rounded,
            title: 'No events found',
            subtitle:
            'Create an event first to see attendees.',
          );
        }

        final Map<String, String> eventTitles = {};

        for (final event in docs) {
          final data = event.data();

          eventTitles[event.id] =
              (data['title'] ?? 'Untitled Event')
                  .toString();
        }

        final List<String> eventIds =
        docs.map((event) => event.id).toList();

        return _buildRegistrations(
          eventIds,
          eventTitles,
        );
      },
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        8,
        24,
        16,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color:
              const Color(0xFF0F172A)
                  .withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          textInputAction:
          TextInputAction.search,
          onChanged: (value) {
            if (!mounted) return;

            setState(() {
              _searchQuery =
                  value.trim().toLowerCase();
            });
          },
          decoration: InputDecoration(
            // isDense + explicit vertical padding keeps the field height
            // consistent and stops the default Material border/underline
            // from flashing or peeking through on focus/tap.
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            hintText: 'Search attendees...',
            hintStyle: TextStyle(
              color: Colors.blueGrey.shade300,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.blueGrey.shade300,
            ),
            suffixIcon:
            _searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(
                Icons.clear_rounded,
              ),
              color:
              Colors.blueGrey.shade400,
              onPressed: () {
                _searchController.clear();

                setState(() {
                  _searchQuery = '';
                });
              },
            )
                : null,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REGISTRATIONS
  // ============================================================

  Widget _buildRegistrations(
      List<String> eventIds,
      Map<String, String> eventTitles,
      ) {
    if (eventIds.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No participants',
        subtitle:
        'No participants registered yet.',
      );
    }

    final List<List<String>> chunks =
    _chunkList(eventIds, 30);

    return _RegistrationStreams(
      chunks: chunks,
      eventTitles: eventTitles,
      searchQuery: _searchQuery,
    );
  }

  // ============================================================
  // CHUNK LIST
  // ============================================================

  List<List<String>> _chunkList(
      List<String> list,
      int size,
      ) {
    final List<List<String>> result = [];

    for (int i = 0; i < list.length; i += size) {
      final int end =
      (i + size < list.length)
          ? i + size
          : list.length;

      result.add(
        list.sublist(i, end),
      );
    }

    return result;
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(
      String message,
      ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 55,
              color: Colors.redAccent,
            ),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                const Color(0xFF00A896)
                    .withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: const Color(0xFF00A896),
              ),
            ),
            SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// REGISTRATION STREAM HANDLER
// =================================================================

class _RegistrationStreams extends StatefulWidget {
  final List<List<String>> chunks;
  final Map<String, String> eventTitles;
  final String searchQuery;

  const _RegistrationStreams({
    required this.chunks,
    required this.eventTitles,
    required this.searchQuery,
  });

  @override
  State<_RegistrationStreams> createState() =>
      _RegistrationStreamsState();
}

class _RegistrationStreamsState
    extends State<_RegistrationStreams> {
  late List<List<QueryDocumentSnapshot<
      Map<String, dynamic>>>> _chunkResults;

  final List<
      StreamSubscription<
          QuerySnapshot<Map<String, dynamic>>>> _subscriptions =
  [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _initializeResults();
    _listenToChunks();
  }

  @override
  void didUpdateWidget(
      covariant _RegistrationStreams oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (!_sameChunks(
      oldWidget.chunks,
      widget.chunks,
    )) {
      _cancelSubscriptions();

      _initializeResults();

      _listenToChunks();

      return;
    }

    // Search query changes do not require
    // new Firestore listeners.
    if (oldWidget.searchQuery !=
        widget.searchQuery) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  void _initializeResults() {
    _chunkResults = List.generate(
      widget.chunks.length,
          (_) => <
          QueryDocumentSnapshot<
              Map<String, dynamic>> >[],
    );

    _loading = true;
    _error = null;
  }

  // ============================================================
  // SAME CHUNKS
  // ============================================================

  bool _sameChunks(
      List<List<String>> a,
      List<List<String>> b,
      ) {
    if (a.length != b.length) {
      return false;
    }

    for (int i = 0; i < a.length; i++) {
      if (a[i].length != b[i].length) {
        return false;
      }

      for (int j = 0; j < a[i].length; j++) {
        if (a[i][j] != b[i][j]) {
          return false;
        }
      }
    }

    return true;
  }

  // ============================================================
  // LISTEN TO CHUNKS
  // ============================================================

  void _listenToChunks() {
    if (widget.chunks.isEmpty) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      return;
    }

    _loading = true;
    _error = null;

    for (int i = 0;
    i < widget.chunks.length;
    i++) {
      final List<String> chunk =
      widget.chunks[i];

      final StreamSubscription<
          QuerySnapshot<Map<String, dynamic>>>
      subscription = FirebaseFirestore
          .instance
          .collection('registrations')
          .where(
        'eventId',
        whereIn: chunk,
      )
          .snapshots()
          .listen(
            (snapshot) {
          if (!mounted) return;

          setState(() {
            _chunkResults[i] =
                snapshot.docs;

            _loading = false;
          });
        },
        onError: (Object error) {
          if (!mounted) return;

          setState(() {
            _loading = false;
            _error = error.toString();
          });
        },
      );

      _subscriptions.add(subscription);
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  void _cancelSubscriptions() {
    for (final subscription
    in _subscriptions) {
      subscription.cancel();
    }

    _subscriptions.clear();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_loading &&
        _chunkResults.every(
              (list) => list.isEmpty,
        )) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error loading participants:\n$_error',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // MERGE REGISTRATIONS
    // ==========================================================

    final Map<
        String,
        QueryDocumentSnapshot<
            Map<String, dynamic>>> uniqueRegistrations =
    {};

    for (final chunk in _chunkResults) {
      for (final registration in chunk) {
        uniqueRegistrations[
        registration.id] =
            registration;
      }
    }

    List<
        QueryDocumentSnapshot<
            Map<String, dynamic>>> registrations =
    uniqueRegistrations.values.toList();

    // ==========================================================
    // REMOVE CANCELLED REGISTRATIONS
    // ==========================================================

    registrations = registrations.where(
          (registration) {
        final Map<String, dynamic> data =
        registration.data();

        final String status =
        (data['status'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        return status != 'cancelled' &&
            status != 'canceled';
      },
    ).toList();

    // ==========================================================
    // SORT
    // ==========================================================

    registrations.sort(
          (a, b) {
        final Map<String, dynamic> aData =
        a.data();

        final Map<String, dynamic> bData =
        b.data();

        final String aName =
        (aData['userName'] ??
            aData['name'] ??
            '')
            .toString()
            .toLowerCase();

        final String bName =
        (bData['userName'] ??
            bData['name'] ??
            '')
            .toString()
            .toLowerCase();

        return aName.compareTo(bName);
      },
    );

    // ==========================================================
    // SEARCH
    // ==========================================================

    final String query =
    widget.searchQuery.trim().toLowerCase();

    final List<
        QueryDocumentSnapshot<
            Map<String, dynamic>>> filteredRegistrations =
    registrations.where(
          (doc) {
        if (query.isEmpty) {
          return true;
        }

        final Map<String, dynamic> data =
        doc.data();

        final String userId =
        (data['userId'] ?? '')
            .toString()
            .toLowerCase();

        final String userName =
        (data['userName'] ??
            data['name'] ??
            '')
            .toString()
            .toLowerCase();

        final String email =
        (data['email'] ?? '')
            .toString()
            .toLowerCase();

        final String phone =
        (data['phone'] ?? '')
            .toString()
            .toLowerCase();

        final String eventId =
        (data['eventId'] ?? '')
            .toString();

        final String eventTitle =
        (widget.eventTitles[eventId] ??
            '')
            .toLowerCase();

        return userId.contains(query) ||
            userName.contains(query) ||
            email.contains(query) ||
            phone.contains(query) ||
            eventTitle.contains(query);
      },
    ).toList();

    // ==========================================================
    // NO REGISTRATIONS
    // ==========================================================

    if (registrations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 55,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 14),
            Text(
              'No participants registered yet.',
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // NO SEARCH RESULTS
    // ==========================================================

    if (filteredRegistrations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 55,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 14),
            Text(
              'No matching attendees found.',
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (query.isNotEmpty) ...[
              SizedBox(height: 6),
              Text(
                'Try another name, email or phone.',
                style: TextStyle(
                  color: Colors.blueGrey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // ==========================================================
    // LIST
    // ==========================================================

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24,
      ),
      itemCount:
      filteredRegistrations.length,
      itemBuilder: (context, index) {
        final QueryDocumentSnapshot<
            Map<String, dynamic>> registration =
        filteredRegistrations[index];

        final Map<String, dynamic> data =
        registration.data();

        final String eventId =
        (data['eventId'] ?? '')
            .toString();

        return _ParticipantCard(
          registrationId:
          registration.id,
          data: data,
          eventTitle:
          widget.eventTitles[eventId] ??
              'Unknown Event',
        );
      },
    );
  }
}

// =================================================================
// PARTICIPANT CARD
// =================================================================

class _ParticipantCard extends StatelessWidget {
  final String registrationId;
  final Map<String, dynamic> data;
  final String eventTitle;

  const _ParticipantCard({
    required this.registrationId,
    required this.data,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    final String userName =
    (data['userName'] ??
        data['name'] ??
        'Participant')
        .toString()
        .trim();

    final String email =
    (data['email'] ?? '')
        .toString()
        .trim();

    final String phone =
    (data['phone'] ?? '')
        .toString()
        .trim();

    final String image =
    (data['image'] ??
        data['photoURL'] ??
        data['photoUrl'] ??
        '')
        .toString()
        .trim();

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where(
        'registrationId',
        isEqualTo: registrationId,
      )
          .limit(1)
          .snapshots(),
      builder: (
          context,
          attendanceSnapshot,
          ) {
        final bool isCheckedIn =
            attendanceSnapshot.hasData &&
                attendanceSnapshot
                    .data!
                    .docs
                    .isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(
            bottom: 16,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius:
            BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
            boxShadow: [
              BoxShadow(
                color:
                const Color(0xFF0F172A)
                    .withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              // ------------------------------------------------
              // AVATAR
              // ------------------------------------------------

              _buildAvatar(
                image,
                userName,
              ),

              SizedBox(width: 14),

              // ------------------------------------------------
              // INFORMATION
              // ------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.isEmpty
                          ? 'Participant'
                          : userName,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      eventTitle,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                        Colors.blueGrey.shade500,
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text(
                      _paymentSummary(data),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF007E7B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (email.isNotEmpty) ...[
                      SizedBox(height: 3),
                      Text(
                        email,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                          Colors.blueGrey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    if (phone.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        phone,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                          Colors.blueGrey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(width: 8),

              // ------------------------------------------------
              // STATUS
              // ------------------------------------------------

              _buildStatus(
                isCheckedIn,
              ),
            ],
          ),
        );
      },
    );
  }

  String _paymentSummary(Map<String, dynamic> data) {
    final double amount = (data['amountPaid'] as num?)?.toDouble() ??
        double.tryParse(data['amountPaid']?.toString() ?? '') ??
        0;
    final String method = (data['paymentMethod'] ?? 'free').toString();

    if (method.toLowerCase() == 'free' || amount <= 0) return 'Free registration';
    final String readableMethod = method[0].toUpperCase() + method.substring(1);
    return 'Paid • $readableMethod • Rs. ${amount.toStringAsFixed(0)}';
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar(
      String image,
      String name,
      ) {
    final String trimmedName =
    name.trim();

    final String firstLetter =
    trimmedName.isNotEmpty
        ? trimmedName[0].toUpperCase()
        : 'U';

    if (image.isEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundColor:
        const Color(0xFF00A896)
            .withOpacity(0.1),
        child: Text(
          firstLetter,
          style: TextStyle(
            color: Color(0xFF007E7B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 25,
      backgroundColor:
      const Color(0xFFF1F5F9),
      child: ClipOval(
        child: Image.network(
          image,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) {
            return Container(
              width: 50,
              height: 50,
              color:
              const Color(0xFFF1F5F9),
              alignment: Alignment.center,
              child: Text(
                firstLetter,
                style: TextStyle(
                  color:
                  Color(0xFF007E7B),
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatus(
      bool isCheckedIn,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: isCheckedIn
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCheckedIn
                ? Icons.check_circle_rounded
                : Icons.pending_rounded,
            size: 14,
            color: isCheckedIn
                ? Colors.green.shade700
                : Colors.orange.shade700,
          ),
          SizedBox(width: 5),
          Text(
            isCheckedIn
                ? 'Checked In'
                : 'Pending',
            style: TextStyle(
              color: isCheckedIn
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
