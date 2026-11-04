import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_ease/providers/event_provider.dart';
import '../auth/login_screen.dart';
import 'create_edit_event_screen.dart';
import 'attendance_scanner_screen.dart';
import 'participants_screen.dart';
import 'announcements_screen.dart';
import 'organizer_feedback_screen.dart';
import 'gallery_upload_screen.dart';
import '../common/settings_screen.dart';
import '../common/notifications_screen.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

import '../../widgets/premium_ui.dart';

class _Palette {
  static const Color primary = Color(0xFF007E7B);
  static const Color primaryDark = Color(0xFF005E5C);
  static const Color primaryLight = Color(0xFF00A39E);
  static const Color ink = Color(0xFF0F172A);
  static const Color subtitle = Color(0xFF64748B);
  static const Color muted = Color(0xFF94A3B8);
  static const Color hairline = Color(0xFFEEF2F6);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color amber = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color violet = Color(0xFF7C3AED);
}

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Provider.of<EventProvider>(
        context,
        listen: false,
      ).fetchEvents(includePending: true, loadUserData: false);
    });

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshEvents() async {
    if (!mounted) return;

    await Provider.of<EventProvider>(
      context,
      listen: false,
    ).fetchEvents(includePending: true, loadUserData: false);

    if (!mounted) return;

    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const _DashboardHome(),

      CreateEditEventScreen(
        onEventSaved: () async {
          await _refreshEvents();
        },
      ),

      const ParticipantsScreen(),

      const AttendanceScannerScreen(),

      const UnifiedSettingsScreen(userRole: 'Organizer'),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      drawer: _buildNavigationDrawer(context),

      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: screens,
      ),

      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        items: const [
          PremiumNavItem(icon: Icons.bar_chart_rounded, label: 'Overview'),
          PremiumNavItem(icon: Icons.add_box_rounded, label: 'Create'),
          PremiumNavItem(icon: Icons.groups_rounded, label: 'People'),
          PremiumNavItem(icon: Icons.qr_code_scanner_rounded, label: 'Scanner'),
          PremiumNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
                .collection('Users')
                .doc(user.uid)
                .snapshots()
          : null,
      builder: (context, snapshot) {
        String name = user?.displayName ?? 'Organizer';
        String email = user?.email ?? 'organizer@eventease.com';
        String? photoUrl = user?.photoURL;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['Name'] ?? data?['name'] ?? name;
          email = data?['Email'] ?? data?['email'] ?? email;
          photoUrl = data?['ProfileImage'] ?? photoUrl;
        }

        void openPage(int index) {
          Navigator.pop(context);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }

        void openScreen(Widget screen) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }

        return PremiumDrawer(
          name: name,
          email: email,
          photoUrl: photoUrl,
          roleLabel: 'ORGANIZER',
          onLogout: () {
            Navigator.pop(context);
            _DashboardHomeState._logout(context);
          },
          sections: [
            PremiumDrawerSection(
              label: 'MAIN MENU',
              items: [
                PremiumDrawerItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'Overview',
                  selected: _currentIndex == 0,
                  onTap: () => openPage(0),
                ),
                PremiumDrawerItem(
                  icon: Icons.add_box_rounded,
                  title: 'Create Event',
                  selected: _currentIndex == 1,
                  onTap: () => openPage(1),
                ),
                PremiumDrawerItem(
                  icon: Icons.groups_rounded,
                  title: 'Participants',
                  selected: _currentIndex == 2,
                  onTap: () => openPage(2),
                ),
                PremiumDrawerItem(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Attendance Scanner',
                  selected: _currentIndex == 3,
                  onTap: () => openPage(3),
                ),
                PremiumDrawerItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  selected: _currentIndex == 4,
                  onTap: () => openPage(4),
                ),
              ],
            ),
            PremiumDrawerSection(
              label: 'MANAGE',
              items: [
                PremiumDrawerItem(
                  icon: Icons.campaign_rounded,
                  title: 'Announcements',
                  onTap: () => openScreen(const AnnouncementsScreen()),
                ),
                PremiumDrawerItem(
                  icon: Icons.star_rounded,
                  title: 'Feedback & Ratings',
                  onTap: () => openScreen(const OrganizerFeedbackScreen()),
                ),
                PremiumDrawerItem(
                  icon: Icons.photo_library_rounded,
                  title: 'Event Gallery',
                  onTap: () => openScreen(const GalleryUploadScreen()),
                ),
                PremiumDrawerItem(
                  icon: Icons.notifications_rounded,
                  title: 'Alerts & Notifications',
                  onTap: () => openScreen(const NotificationsScreen()),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}


class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  String _organizerName = 'Organizer Portal';
  String _organizerPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchOrganizerName();
  }

  Future<void> _fetchOrganizerName() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _organizerName = 'Organizer';
        });

        return;
      }

      String photo = user.photoURL?.trim() ?? '';
      String name = user.displayName?.trim() ?? '';

      final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final Map<String, dynamic>? data = doc.data();

        final dynamic nameValue = data?['Name'] ?? data?['name'] ?? data?['FullName'] ?? data?['fullName'] ?? data?['DisplayName'];
        if (nameValue != null && nameValue.toString().trim().isNotEmpty) {
          name = nameValue.toString().trim();
        }

        final dynamic photoValue = data?['ProfileImage'] ?? data?['profileImage'] ?? data?['PhotoUrl'] ?? data?['photoUrl'];
        if (photoValue != null && photoValue.toString().trim().isNotEmpty) {
          photo = photoValue.toString().trim();
        }
      }

      if (name.isEmpty && user.email != null) {
        name = user.email!.split('@').first;
      }

      if (!mounted) return;

      setState(() {
        _organizerName = name.isNotEmpty ? name : 'Organizer';
        _organizerPhotoUrl = photo;
      });
    } catch (e) {
      debugPrint('Error fetching organizer name: $e');

      if (!mounted) return;

      setState(() {
        _organizerName = 'Organizer';
      });
    }
  }

  static Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'active':
        return const Color(0xFF16A34A);

      case 'rejected':
        return _Palette.danger;

      case 'cancelled':
      case 'canceled':
        return Colors.blueGrey.shade400;

      case 'completed':
        return const Color(0xFF2563EB);

      case 'pending':
      case 'pending approval':
        return _Palette.amber;

      default:
        return _Palette.amber;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'active':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'cancelled':
      case 'canceled':
        return Icons.block_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  static Future<void> _confirmCancelEvent(
    BuildContext context,
    String eventId,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: const [
              Icon(Icons.cancel_outlined, color: _Palette.danger),
              SizedBox(width: 10),
              Text(
                'Cancel Event?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: const Text(
            'Registered attendees will be notified. '
            'This action cannot be undone.',
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx, false);
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(80, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'No',
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.danger,
                    elevation: 0,
                    minimumSize: const Size(110, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Yes, Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final DocumentReference<Map<String, dynamic>> eventRef = firestore
          .collection('Events')
          .doc(eventId);

      final DocumentSnapshot<Map<String, dynamic>> eventSnapshot =
          await eventRef.get();

      if (!eventSnapshot.exists) {
        throw Exception('Event not found.');
      }

      await eventRef.update({
        'status': 'Cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final QuerySnapshot<Map<String, dynamic>> registrationsSnapshot =
          await firestore
              .collection('registrations')
              .where('eventId', isEqualTo: eventId)
              .get();

      final WriteBatch batch = firestore.batch();

      for (final registrationDoc in registrationsSnapshot.docs) {
        final Map<String, dynamic> data = registrationDoc.data();

        final String registrationStatus =
            data['status']?.toString().trim().toLowerCase() ?? '';

        if (registrationStatus == 'cancelled') {
          continue;
        }

        final String userId = data['userId']?.toString().trim() ?? '';

        if (userId.isEmpty) {
          continue;
        }

        if (!await NotificationService.isPushNotificationsEnabled(userId)) {
          continue;
        }

        final DocumentReference<Map<String, dynamic>> notificationRef =
            firestore.collection('notifications').doc();

        batch.set(notificationRef, {
          'userId': userId,
          'eventId': eventId,
          'title': 'Event Cancelled',
          'message': 'An event you registered for has been cancelled.',
          'type': 'event_cancellation',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!context.mounted) return;

      await Provider.of<EventProvider>(
        context,
        listen: false,
      ).fetchEvents(includePending: true, loadUserData: false);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event cancelled and attendees notified.'),
          backgroundColor: _Palette.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error cancelling event: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not cancel event. Please try again.'),
          backgroundColor: _Palette.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  static Future<void> _editEvent(BuildContext context, String eventId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> eventDoc =
          await FirebaseFirestore.instance
              .collection('Events')
              .doc(eventId)
              .get();

      if (!eventDoc.exists) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event not found.'),
            backgroundColor: _Palette.danger,
          ),
        );

        return;
      }

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateEditEventScreen(
            eventDoc: eventDoc,
            onEventSaved: () async {
              await Provider.of<EventProvider>(
                context,
                listen: false,
              ).fetchEvents(includePending: true, loadUserData: false);
            },
          ),
        ),
      );

      if (!context.mounted) return;

      await Provider.of<EventProvider>(
        context,
        listen: false,
      ).fetchEvents(includePending: true, loadUserData: false);
    } catch (e) {
      debugPrint('Error opening edit event: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open event for editing.'),
          backgroundColor: _Palette.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final EventProvider provider = Provider.of<EventProvider>(context);

    final User? currentUser = FirebaseAuth.instance.currentUser;

    final List<dynamic> myEvents = provider.events.where((event) {
      if (currentUser == null) {
        return false;
      }

      return event.organizerId == currentUser.uid;
    }).toList();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('registrations')
          .snapshots(),
      builder: (context, registrationsSnapshot) {
        final registrations = registrationsSnapshot.data?.docs ?? [];

        int soldCountFor(String eventId) {
          return registrations.where((doc) {
            final Map<String, dynamic> data = doc.data();

            final String registrationEventId =
                data['eventId']?.toString() ?? '';

            final String status =
                data['status']?.toString().trim().toLowerCase() ?? '';

            return registrationEventId == eventId && status != 'cancelled';
          }).length;
        }

        int totalTicketsSold = 0;

        for (final event in myEvents) {
          totalTicketsSold += soldCountFor(event.id);
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('feedback').snapshots(),
          builder: (context, feedbackSnapshot) {
            double totalRating = 0;
            int totalFeedbackCount = 0;

            if (feedbackSnapshot.hasData) {
              for (final feedbackDoc in feedbackSnapshot.data!.docs) {
                final Map<String, dynamic> data = feedbackDoc.data();

                final String feedbackEventId =
                    data['eventId']?.toString() ?? '';

                final bool belongsToOrganizer = myEvents.any(
                  (event) => event.id == feedbackEventId,
                );

                if (!belongsToOrganizer) {
                  continue;
                }

                final dynamic ratingValue = data['rating'];

                int rating = 0;

                if (ratingValue is int) {
                  rating = ratingValue;
                } else if (ratingValue is double) {
                  rating = ratingValue.round();
                } else {
                  rating = int.tryParse(ratingValue?.toString() ?? '') ?? 0;
                }

                if (rating >= 1 && rating <= 5) {
                  totalRating += rating;
                  totalFeedbackCount++;
                }
              }
            }

            final double averageRating = totalFeedbackCount == 0
                ? 0
                : totalRating / totalFeedbackCount;

            final int pendingEvents = myEvents.where((event) {
              final String status = event.status
                  .toString()
                  .trim()
                  .toLowerCase();

              return status == 'pending' || status == 'pending approval';
            }).length;

            final int totalCapacity = myEvents.fold<int>(
              0,
              (runningTotal, event) =>
                  runningTotal + _safeInt(event.maxParticipants),
            );

            final int upcomingEvents = myEvents
                .where((event) => (event.date as DateTime).isAfter(DateTime.now()))
                .length;

            final String displayName =
                (currentUser?.displayName?.isNotEmpty == true)
                ? currentUser!.displayName!
                : _organizerName;
            final String initial = displayName.trim().isNotEmpty
                ? displayName.trim()[0].toUpperCase()
                : 'O';
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            final String effectivePhoto = _organizerPhotoUrl.isNotEmpty
                ? _organizerPhotoUrl
                : (currentUser?.photoURL ?? '');

            return RefreshIndicator(
              color: _Palette.primary,
              onRefresh: () => Provider.of<EventProvider>(
                context,
                listen: false,
              ).fetchEvents(includePending: true, loadUserData: false),
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: _Palette.primary,
                    elevation: 0,
                    pinned: true,
                    stretch: true,
                    expandedHeight: 154.0,
                    toolbarHeight: 60,
                    leading: Builder(
                      builder: (ctx) => Padding(
                        padding: const EdgeInsets.all(12),
                        child: Material(
                          color: Colors.white.withOpacity(0.16),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Scaffold.of(ctx).openDrawer(),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              backgroundImage:
                                  effectivePhoto.isNotEmpty
                                  ? NetworkImage(effectivePhoto)
                                  : null,
                              child: effectivePhoto.isNotEmpty
                                  ? null
                                  : Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _Palette.primaryDark,
                                _Palette.primary,
                                _Palette.primaryLight,
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Soft decorative circles for depth.
                              Positioned(
                                right: -30,
                                top: -30,
                                child: _glowCircle(140, 0.08),
                              ),
                              Positioned(
                                right: 50,
                                top: 40,
                                child: _glowCircle(60, 0.06),
                              ),
                              Positioned(
                                left: -20,
                                bottom: -40,
                                child: _glowCircle(120, 0.05),
                              ),
                              Positioned(
                                left: 24,
                                right: 24,
                                bottom: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'WELCOME BACK, ${displayName.toUpperCase()}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.78),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Organizer Dashboard',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        height: 1.15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      StreamBuilder<List<NotificationModel>>(
                        stream: NotificationService.getUserNotificationsStream(),
                        builder: (context, snapshot) {
                          final unreadCount =
                              snapshot.data?.where((n) => !n.isRead).length ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Material(
                                  color: Colors.white.withOpacity(0.16),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: _Palette.danger,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _Palette.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        unreadCount > 9 ? '9+' : '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  label: 'TOTAL EVENTS',
                                  value: '${myEvents.length}',
                                  icon: Icons.event_available_rounded,
                                  progress: myEvents.length / 100,
                                  caption: '$upcomingEvents upcoming',
                                  accent: _Palette.primary,
                                  isDark: Theme.of(context).brightness == Brightness.dark,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildStatCard(
                                  label: 'TICKETS SOLD',
                                  value: '$totalTicketsSold',
                                  icon: Icons.confirmation_number_rounded,
                                  progress: totalCapacity == 0
                                      ? 0
                                      : totalTicketsSold / totalCapacity,
                                  caption: totalCapacity == 0
                                      ? 'No seats yet'
                                      : 'of $totalCapacity seats',
                                  accent: _Palette.violet,
                                  isDark: Theme.of(context).brightness == Brightness.dark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  label: 'AVG RATING',
                                  value: averageRating.toStringAsFixed(1),
                                  icon: Icons.star_rounded,
                                  progress: averageRating / 5,
                                  ring: true,
                                  caption: totalFeedbackCount == 0
                                      ? 'No reviews yet'
                                      : 'from $totalFeedbackCount reviews',
                                  accent: _Palette.amber,
                                  isDark: Theme.of(context).brightness == Brightness.dark,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildStatCard(
                                  label: 'PENDING',
                                  value: '$pendingEvents',
                                  icon: Icons.hourglass_top_rounded,
                                  accent: _Palette.amber,
                                  progress: myEvents.isEmpty
                                      ? 0
                                      : pendingEvents / myEvents.length,
                                  caption: pendingEvents == 0
                                      ? 'All approved'
                                      : 'awaiting admin',
                                  isDark: Theme.of(context).brightness == Brightness.dark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Events',
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.color ??
                                      _Palette.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  await Provider.of<EventProvider>(
                                    context,
                                    listen: false,
                                  ).fetchEvents(
                                    includePending: true,
                                    loadUserData: false,
                                  );
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                  color: _Palette.primary,
                                ),
                                label: const Text(
                                  'Refresh',
                                  style: TextStyle(
                                    color: _Palette.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (provider.isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (myEvents.isEmpty) {
                            return _buildEmptyState(context);
                          }

                          final event = myEvents[index];

                          List<QueryDocumentSnapshot<Map<String, dynamic>>>
                          eventFeedbacks = [];

                          if (feedbackSnapshot.hasData) {
                            eventFeedbacks = feedbackSnapshot.data!.docs.where((
                              doc,
                            ) {
                              final Map<String, dynamic> data = doc.data();

                              return data['eventId']?.toString() == event.id;
                            }).toList();
                          }

                          return _buildManagedEventCard(
                            context,
                            event,
                            eventFeedbacks,
                            soldCountFor(event.id),
                          );
                        },
                        childCount: provider.isLoading
                            ? 1
                            : (myEvents.isEmpty ? 1 : myEvents.length),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _glowCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  static Widget _buildEmptyState(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : _Palette.hairline),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : _Palette.ink.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _Palette.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 38,
              color: _Palette.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No events found',
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.titleLarge?.color ?? _Palette.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first event to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color ??
                  _Palette.subtitle,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _logout(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: const [
              Icon(Icons.logout_rounded, color: _Palette.danger),
              SizedBox(width: 10),
              Text(
                'Confirm Logout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: const Text('Are you sure you want to log out of your account?'),
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx, false);
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(80, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.danger,
                    elevation: 0,
                    minimumSize: const Size(100, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Logout error: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not logout. Please try again.'),
          backgroundColor: _Palette.danger,
        ),
      );
    }
  }

  /// A stat tile: label, the number as the loudest element, and a small
  /// visual driven by [progress] (0-1) — a ring for ratings, a bar otherwise.
  /// Icon badge now uses a soft gradient chip instead of flat opacity fill.
  static Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required double progress,
    required String caption,
    required bool isDark,
    Color accent = _Palette.primary,
    bool ring = false,
  }) {
    final double clamped = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;
    // A non-zero metric should remain noticeable even when the capacity is
    // large (for example, 3 tickets out of several hundred seats).
    final double visibleProgress =
        clamped > 0 ? clamped.clamp(0.055, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? const Color(0xFF334155) : accent.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : accent.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ring
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          value: clamped,
                          strokeWidth: 3,
                          backgroundColor: accent.withOpacity(0.18),
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      )
                    : Icon(icon, size: 18, color: accent),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : _Palette.ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : _Palette.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          if (!ring) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: visibleProgress,
                minHeight: 6,
                backgroundColor: accent.withOpacity(0.10),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ] else
            const SizedBox(height: 10),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildManagedEventCard(
    BuildContext context,
    dynamic event,
    // ignore: unused_element
    List<QueryDocumentSnapshot<Map<String, dynamic>>> eventFeedbacks,
    int soldCount,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime eventDate = event.date;

    final String status = event.status.toString();

    final String normalizedStatus = status.trim().toLowerCase();

    final bool canEdit =
        eventDate.isAfter(DateTime.now()) &&
        normalizedStatus != 'cancelled' &&
        normalizedStatus != 'canceled' &&
        normalizedStatus != 'rejected';

    final int maxParticipants = _safeInt(event.maxParticipants);

    final int availableSeats = _safeInt(event.availableSeats);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : _Palette.hairline),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : _Palette.ink.withOpacity(0.045),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Banner with a status badge floated on top of the image and a
          // bottom gradient scrim so white/light text stays legible.
          Stack(
            children: [
              _buildEventImage(event),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.30),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _statusPill(status),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Text(
                  event.title?.toString() ?? 'Untitled Event',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(color: Colors.black38, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${eventDate.day}/${eventDate.month}/${eventDate.year}',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade400,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (canEdit)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _editEvent(context, event.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _Palette.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 13,
                                color: _Palette.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: _Palette.primary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Registered + seats-left in one info bar — reads as a
                // single stat block instead of two disconnected lines.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : _Palette.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.confirmation_number_rounded,
                          '$soldCount Registered',
                          _Palette.primary,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 22,
                        color: isDark ? const Color(0xFF334155) : Colors.blueGrey.shade100,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.event_seat_rounded,
                          '$availableSeats/$maxParticipants left',
                          isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Theme.of(context).dividerColor),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionIcon(
                  context,
                  Icons.people_alt_rounded,
                  'Attendees',
                  ParticipantsScreen(eventId: event.id),
                ),

                _buildActionIcon(
                  context,
                  Icons.campaign_rounded,
                  'Announce',
                  AnnouncementsScreen(eventId: event.id),
                ),

                _buildActionIcon(
                  context,
                  Icons.rate_review_rounded,
                  'Feedback (${eventFeedbacks.length})',
                  OrganizerFeedbackScreen(eventId: event.id),
                ),

                _buildActionIcon(
                  context,
                  Icons.photo_library_rounded,
                  'Gallery',
                  GalleryUploadScreen(eventId: event.id),
                ),
              ],
            ),
          ),

          if (normalizedStatus != 'cancelled' &&
              normalizedStatus != 'canceled' &&
              normalizedStatus != 'completed' &&
              eventDate.isAfter(DateTime.now()))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _confirmCancelEvent(context, event.id);
                  },
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 16,
                    color: _Palette.danger,
                  ),
                  label: const Text(
                    'Cancel Event',
                    style: TextStyle(
                      color: _Palette.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _Palette.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _statusPill(String status) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.28),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_statusIcon(status), size: 12, color: _statusColor(status)),
              const SizedBox(width: 5),
              Text(
                status,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Full-width banner header. 16:9 matches the shape event posters are
  // usually made in, so the whole image stays visible instead of being
  // cropped down to a square.
  static const double _bannerAspect = 16 / 9;

  static Widget _buildEventImage(dynamic event) {
    final String imageUrl = event.imageUrl?.toString() ?? '';

    if (imageUrl.isEmpty) {
      return AspectRatio(
        aspectRatio: _bannerAspect,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey.shade200, Colors.grey.shade300],
            ),
          ),
          child: const Icon(Icons.image_rounded, size: 40, color: Colors.grey),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _bannerAspect,
      child: Image.network(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _Palette.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_rounded, size: 40, color: Colors.grey),
          );
        },
      ),
    );
  }

  static Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildActionIcon(
    BuildContext context,
    IconData icon,
    String label,
    Widget targetScreen,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => targetScreen),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : _Palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : _Palette.hairline),
                ),
                child: Icon(icon, color: _Palette.primary, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int _safeInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
