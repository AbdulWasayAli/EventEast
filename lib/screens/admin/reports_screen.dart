import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/pdf_report_service.dart';
import '../../widgets/premium_ui.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventProvider = Provider.of<EventProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final textDark = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textMuted = isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade400;

    final allEvents = eventProvider.events;

    final List<Map<String, dynamic>> eventRevenues = allEvents.map((e) {
      final sold = e.maxParticipants - e.availableSeats;
      final revenue = (sold > 0 ? sold : 0) * e.price;
      return {'event': e, 'sold': sold > 0 ? sold : 0, 'revenue': revenue};
    }).toList();

    eventRevenues.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    final topEvents = eventRevenues.take(3).toList();

    final now = DateTime.now();
    final Map<int, double> monthlyRevenue = {};
    for (int i = 5; i >= 0; i--) {
      int month = now.month - i;
      if (month <= 0) month += 12;
      monthlyRevenue[month] = 0.0;
    }
    for (var er in eventRevenues) {
      final e = er['event'];
      if (monthlyRevenue.containsKey(e.date.month)) {
        monthlyRevenue[e.date.month] = monthlyRevenue[e.date.month]! + (er['revenue'] as double);
      }
    }
    final maxMonthlyRev = monthlyRevenue.values.fold(0.0, (prev, amt) => amt > prev ? amt : prev);
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final totalAttendees = adminProvider.users.where((u) => u.role.toLowerCase() == 'attendee').length;
    final totalOrganizers = adminProvider.users.where((u) => u.role.toLowerCase() == 'organizer').length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: SettingsStyleAppBar(
        title: 'Analytics & Reports',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating PDF Report... 📄'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF007E7B),
                    duration: Duration(seconds: 1),
                  ),
                );
                await PdfReportService.generateAndExportReport(
                  totalUsers: adminProvider.totalUsersCount,
                  events: eventProvider.events,
                  pendingApprovalsCount: adminProvider.pendingApprovalsCount,
                  flaggedItemsCount: adminProvider.flaggedItemsCount,
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.file_download_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Over Time',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 220,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyRevenue.entries.map((entry) {
                  final heightFactor = maxMonthlyRev == 0
                      ? 0.1
                      : (entry.value / maxMonthlyRev).clamp(0.1, 1.0);
                  return _buildBar(monthNames[entry.key - 1], heightFactor, textMuted);
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Top Performing Events',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            if (topEvents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder),
                ),
                child: Text('No events available.', style: TextStyle(color: textMuted)),
              )
            else
              ...List.generate(topEvents.length, (index) {
                final er = topEvents[index];
                final e = er['event'];
                final revValue = er['revenue'] as double;
                final rev = revValue > 0
                    ? 'Rs. ${revValue.toStringAsFixed(0)}'
                    : 'Free';
                final tickets = '${er['sold']} Tickets';
                return _buildTopEventRow(
                  '${index + 1}',
                  e.title,
                  rev,
                  tickets,
                  cardBg,
                  cardBorder,
                  textDark,
                  textMuted,
                  isDark,
                );
              }),

            const SizedBox(height: 28),
            Text(
              'Platform Growth',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildGrowthCard(
                    'Total Attendees',
                    '$totalAttendees',
                    Icons.people_rounded,
                    const Color(0xFF6366F1),
                    cardBg,
                    cardBorder,
                    textMuted,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGrowthCard(
                    'Total Organizers',
                    '$totalOrganizers',
                    Icons.business_rounded,
                    const Color(0xFF007E7B),
                    cardBg,
                    cardBorder,
                    textMuted,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, double heightFactor, Color labelColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 34,
          height: 140 * heightFactor,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00A896), Color(0xFF028090)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTopEventRow(
    String rank,
    String title,
    String revenue,
    String tickets,
    Color cardBg,
    Color cardBorder,
    Color titleColor,
    Color subtitleColor,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007E7B), Color(0xFF00A896)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              rank,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  tickets,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            revenue,
            style: const TextStyle(
              color: Color(0xFF00A896),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color cardBg,
    Color cardBorder,
    Color subtitleColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
