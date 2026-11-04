import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';

import '../../widgets/premium_ui.dart';
import 'qr_pass_screen.dart';
import 'feedback_screen.dart';
import 'certificate_preview_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).fetchEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventProvider>(context);

    final upcoming = provider.myUpcomingEvents;
    final completed = provider.myCompletedEvents;
    final cancelled = provider.myCancelledEvents;

        return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: SettingsStyleTabAppBar(
        title: 'My Tickets',
        tabBar: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFF007E7B),
              unselectedLabelColor: Colors.white.withOpacity(0.6),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _EventListView(
                  events: upcoming,
                  emptyMessage: 'No upcoming tickets',
                  cardType: _CardType.upcoming,
                ),
                _EventListView(
                  events: completed,
                  emptyMessage: 'No completed events yet',
                  cardType: _CardType.completed,
                ),
                _EventListView(
                  events: cancelled,
                  emptyMessage: 'No cancelled events',
                  cardType: _CardType.cancelled,
                ),
              ],
            ),
    );
  }
}

enum _CardType { upcoming, completed, cancelled }

class _EventListView extends StatelessWidget {
  final List<EventModel> events;
  final String emptyMessage;
  final _CardType cardType;

  const _EventListView({
    required this.events,
    required this.emptyMessage,
    required this.cardType,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_activity_rounded,
                size: 80, color: Theme.of(context).dividerColor),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(event: event, cardType: cardType);
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final _CardType cardType;

  const _EventCard({required this.event, required this.cardType});

  String _getMonth(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = cardType == _CardType.cancelled;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = isCancelled ? Colors.blueGrey : const Color(0xFF007E7B);
    final Color bgColor = Theme.of(context).cardColor;
    final Color textPrimary = Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87;
    final Color textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return GestureDetector(
      onTap: () {
        if (cardType == _CardType.upcoming) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => QRPassScreen(eventId: event.id)));
        }
      },
      child: Opacity(
        opacity: isCancelled ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accent.withOpacity(isDark ? 0.25 : 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : accent).withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isCancelled
                          ? [Colors.blueGrey.shade300, Colors.blueGrey.shade500]
                          : [const Color(0xFF00A99D), const Color(0xFF005E5B)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      bottomLeft: Radius.circular(13),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getMonth(event.date.month),
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                '${event.date.day}',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCancelled) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Cancelled',
                                        style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 12, color: accent),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style: TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (cardType == _CardType.upcoming)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isCancelled
                                    ? [Colors.blueGrey.shade400, Colors.blueGrey.shade600]
                                    : [const Color(0xFF00A99D), const Color(0xFF005E5B)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.confirmation_number_rounded, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Pass', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          )
                        else if (cardType == _CardType.completed)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                future: FirebaseAuth.instance.currentUser == null
                                    ? null
                                    : FirebaseFirestore.instance
                                        .collection('attendance')
                                        .doc('${event.id}_${FirebaseAuth.instance.currentUser!.uid}')
                                        .get(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
                                  return GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CertificatePreviewScreen(event: event))),
                                    child: Icon(Icons.workspace_premium_rounded, size: 18, color: accent),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeedbackScreen(eventId: event.id, eventTitle: event.title))),
                                child: Icon(Icons.rate_review_rounded, size: 18, color: accent),
                              ),
                            ],
                          ),
                      ],
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
}
