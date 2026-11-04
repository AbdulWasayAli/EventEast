import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/notification_service.dart';

import '../../widgets/premium_ui.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<AdminProvider>(context, listen: false).fetchPendingApprovals();
    });
  }

  String _formatDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    return Scaffold(
      appBar: PremiumScreenAppBar(
        eyebrow: 'Admin Workflow',
        title: 'Pending approvals',
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final eventDocs = adminProvider.pendingEventApprovals;
          final organizerDocs = adminProvider.pendingOrganizerApprovals;

          if (eventDocs.isEmpty && organizerDocs.isEmpty) {
            return RefreshIndicator(
              onRefresh: adminProvider.fetchPendingApprovals,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 80, color: Colors.blueGrey.shade200),
                          SizedBox(height: 16),
                          Text(
                            'All caught up!',
                            style: TextStyle(
                              color: Colors.blueGrey.shade400,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No pending approvals at the moment.',
                            style: TextStyle(
                                color: Colors.blueGrey.shade300, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: adminProvider.fetchPendingApprovals,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (eventDocs.isNotEmpty) ...[
                  Text(
                    'Events (${eventDocs.length})',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...eventDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _ApprovalCard(
                      typeLabel: 'Event',
                      title: data['title']?.toString() ?? 'Untitled Event',
                      subtitle: data['description']?.toString() ?? '',
                      dateLabel: _formatDate(data['date']),
                      onApprove: () async {
                        await adminProvider.approveEvent(doc.id);
                        final organizerId = data['organizerId']?.toString() ?? data['userId']?.toString();
                        if (organizerId != null && organizerId.isNotEmpty) {
                          await NotificationService.sendNotification(
                            recipientUserId: organizerId,
                            title: 'Event Approved! 🎉',
                            message: 'Your event "${data['title'] ?? 'Untitled'}" has been approved.',
                            eventId: doc.id,
                            type: 'approval',
                          );
                        }
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event approved & notification sent'),
                            backgroundColor: Color(0xFF00A896),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      onReject: () async {
                        await adminProvider.rejectEvent(doc.id);
                        final organizerId = data['organizerId']?.toString() ?? data['userId']?.toString();
                        if (organizerId != null && organizerId.isNotEmpty) {
                          await NotificationService.sendNotification(
                            recipientUserId: organizerId,
                            title: 'Event Rejected',
                            message: 'Your event "${data['title'] ?? 'Untitled'}" was not approved.',
                            eventId: doc.id,
                            type: 'rejection',
                          );
                        }
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event rejected'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  }),
                  SizedBox(height: 24),
                ],
                if (organizerDocs.isNotEmpty) ...[
                  Text(
                    'Organizer Accounts (${organizerDocs.length})',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...organizerDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _ApprovalCard(
                      typeLabel: 'Organizer Account',
                      title: data['name']?.toString() ?? 'Unnamed Organizer',
                      subtitle: data['email']?.toString() ?? '',
                      dateLabel: _formatDate(data['createdAt']),
                      onApprove: () async {
                        await adminProvider.approveOrganizer(doc.id);
                        await NotificationService.sendNotification(
                          recipientUserId: doc.id,
                          title: 'Account Verified! 🌟',
                          message: 'Your Organizer account has been verified. You can now post events!',
                          type: 'approval',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Organizer approved & notified'),
                            backgroundColor: Color(0xFF00A896),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      onReject: () async {
                        await adminProvider.rejectOrganizer(doc.id);
                        await NotificationService.sendNotification(
                          recipientUserId: doc.id,
                          title: 'Account Verification Update',
                          message: 'Your Organizer account request was not approved.',
                          type: 'rejection',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Organizer rejected'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final String typeLabel;
  final String title;
  final String subtitle;
  final String dateLabel;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryText = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final secondaryText = isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade500;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF64748B)
                        : Colors.blueGrey.shade300,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: secondaryText,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Reject',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A896),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Approve',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
