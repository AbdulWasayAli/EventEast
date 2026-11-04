import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../widgets/premium_ui.dart';


class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: SettingsStyleAppBar(
        title: 'Notifications',
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all_rounded, color: Colors.white),
            onPressed: () async {
              await NotificationService.markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationService.getUserNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _buildNotificationCard(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF007E7B).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 56,
                color: Color(0xFF007E7B),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Notifications Yet',
              style: TextStyle(
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'When you receive event updates, approvals, or reminders, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade400,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = item.isRead
        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
        : (isDark ? const Color(0xFF164E63) : const Color(0xFFE0F7F5).withOpacity(0.4));
    final borderColor = item.isRead
        ? (isDark ? const Color(0xFF334155) : Colors.blueGrey.shade100)
        : const Color(0xFF007E7B).withOpacity(0.3);
    final primaryText = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final secondaryText = isDark ? const Color(0xFFCBD5E1) : Colors.blueGrey.shade600;
    final mutedText = isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade300;
    IconData iconData = Icons.notifications_rounded;
    Color iconColor = const Color(0xFF007E7B);

    if (item.type == 'approval') {
      iconData = Icons.verified_rounded;
      iconColor = const Color(0xFF10B981);
    } else if (item.type == 'rejection' || item.type == 'warning') {
      iconData = Icons.error_rounded;
      iconColor = const Color(0xFFEF4444);
    } else if (item.type == 'announcement') {
      iconData = Icons.campaign_rounded;
      iconColor = const Color(0xFFF59E0B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: item.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(iconData, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 15,
                  fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w800,
                ),
              ),
            ),
            if (!item.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFF007E7B),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),
            Text(
              item.message,
              style: TextStyle(
                color: secondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _formatTime(item.createdAt),
              style: TextStyle(
                color: mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onTap: () async {
          if (!item.isRead) {
            await NotificationService.markAsRead(item.id);
          }
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
