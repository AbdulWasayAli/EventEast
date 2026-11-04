import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

import '../../widgets/premium_ui.dart';

class ManageEventsScreen extends StatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get backgroundColor => isDark ? const Color(0xFF0F172A) : const Color(0xFFF6FAFA);
  Color get cardColor => isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get primaryText => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF102A2C);
  Color get secondaryText => isDark ? const Color(0xFF94A3B8) : const Color(0xFF5C7A7B);
  Color get borderColor => isDark ? const Color(0xFF334155) : const Color(0xFFDCEBEA);
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color deepTeal = Color(0xFF134E4A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<AdminProvider>(context, listen: false)
          .fetchAllEventsForAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const SettingsStyleAppBar(title: 'Manage Events'),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          final events = provider.allEvents;

          if (provider.isLoading && events.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.event_note_rounded,
                        color: primaryTeal.withOpacity(0.6), size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events available',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: primaryTeal,
            onRefresh: provider.fetchAllEventsForAdmin,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final doc = events[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildEventCard(context, provider, doc.id, data);
              },
            ),
          );
        },
      ),
    );
  }
  Widget _buildEventCard(
    BuildContext context,
    AdminProvider provider,
    String eventId,
    Map<String, dynamic> data,
  ) {
    final String status =
        (data['status'] ?? '').toString().trim().toLowerCase();
    final bool isSuspended = status == 'suspended';
    final bool isCancelled = status == 'cancelled';
    final String title = (data['title'] ?? 'Untitled Event').toString();
    final String location = (data['location'] ?? '').toString();
    final String imageUrl = (data['imageUrl'] ?? '').toString();
    final String category = (data['category'] ?? '').toString();
    final DateTime date = _parseDate(data['date']);

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : deepTeal.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showEventDetailsSheet(context, data),
              child: Stack(
                children: [
                  _buildEventImage(imageUrl),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.45),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _buildStatusBadge(status),
                  ),
                  if (category.trim().isNotEmpty)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: deepTeal,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Colors.white70, size: 12),
                            const SizedBox(width: 5),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (location.trim().isNotEmpty) ...[
                              const SizedBox(width: 12),
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white70, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: 14,
                    child: category.trim().isEmpty
                        ? _buildTapHint()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12.0, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionIcon(
                      context,
                      Icons.edit_rounded,
                      'Edit',
                      primaryTeal,
                      () => _showEditDialog(
                          context, provider, eventId, data),
                    ),
                    _buildActionIcon(
                      context,
                      isSuspended
                          ? Icons.play_circle_fill_rounded
                          : Icons.pause_circle_filled_rounded,
                      isSuspended ? 'Activate' : 'Suspend',
                      isSuspended
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFD97706),
                      isCancelled
                          ? null
                          : () => _toggleSuspend(context, provider,
                              eventId, title, isSuspended),
                    ),
                    _buildActionIcon(
                      context,
                      Icons.event_busy_rounded,
                      'Cancel',
                      const Color(0xFFDC5F2C),
                      isCancelled
                          ? null
                          : () => _cancelEvent(
                              context, provider, eventId, title),
                    ),
                    _buildActionIcon(
                      context,
                      Icons.delete_rounded,
                      'Delete',
                      const Color(0xFFDC2626),
                      () => _deleteEvent(
                          context, provider, eventId, title),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildTapHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.info_outline_rounded,
          color: deepTeal, size: 16),
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
  Widget _buildEventImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return _imagePlaceholder();
    }

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: 190,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          height: 190,
          color: primaryTeal.withOpacity(0.08),
          alignment: Alignment.center,
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: primaryTeal),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryTeal.withOpacity(0.18),
            deepTeal.withOpacity(0.28),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_rounded,
          color: Colors.white.withOpacity(0.85), size: 38),
    );
  }
  Widget _buildStatusBadge(String value) {
    Color bg;
    Color dot;
    String text;

    if (value == 'suspended') {
      bg = const Color(0xFFD97706);
      dot = Colors.white;
      text = 'Suspended';
    } else if (value == 'cancelled') {
      bg = const Color(0xFFDC2626);
      dot = Colors.white;
      text = 'Cancelled';
    } else if (value == 'pending') {
      bg = const Color(0xFFCA8A04);
      dot = Colors.white;
      text = 'Pending';
    } else if (value == 'rejected') {
      bg = const Color(0xFF57534E);
      dot = Colors.white;
      text = 'Rejected';
    } else if (value == 'approved' || value == 'active') {
      bg = primaryTeal;
      dot = Colors.white;
      text = 'Active';
    } else {
      bg = const Color(0xFF64748B);
      dot = Colors.white;
      text = value.isEmpty ? 'Unknown' : value;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
  void _showEventDetailsSheet(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final String title = (data['title'] ?? 'Untitled Event').toString();
    final String status =
        (data['status'] ?? '').toString().trim().toLowerCase();
    final String description = (data['description'] ?? '').toString();
    final String location = (data['location'] ?? '').toString();
    final String organizer = (data['organizer'] ?? '').toString();
    final String category = (data['category'] ?? '').toString();
    final String rules = (data['rules'] ?? '').toString();
    final String contact = (data['contactInfo'] ?? '').toString();
    final String startTime = (data['startTime'] ?? '').toString();
    final String endTime = (data['endTime'] ?? '').toString();
    final String imageUrl = (data['imageUrl'] ?? '').toString();
    final num price = (data['price'] is num) ? data['price'] as num : 0;
    final num maxParticipants =
        (data['maxParticipants'] is num) ? data['maxParticipants'] as num : 0;
    final num availableSeats =
        (data['availableSeats'] is num) ? data['availableSeats'] as num : 0;
    final DateTime date = _parseDate(data['date']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                      children: [
                        // hero image
                        if (imageUrl.trim().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        if (imageUrl.trim().isNotEmpty)
                          const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: primaryText),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildStatusBadge(status),
                          ],
                        ),
                        if (category.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            category,
                            style: TextStyle(
                                color: primaryTeal,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ],

                        const SizedBox(height: 18),
                        _detailRow(Icons.calendar_today_rounded,
                            '${date.day}/${date.month}/${date.year}'),
                        if (startTime.trim().isNotEmpty ||
                            endTime.trim().isNotEmpty)
                          _detailRow(Icons.access_time_rounded,
                              '$startTime - $endTime'),
                        if (location.trim().isNotEmpty)
                            _detailRow(Icons.location_on_rounded, location),
                        if (organizer.trim().isNotEmpty)
                          _detailRow(Icons.person_rounded, organizer),
                        _detailRow(Icons.payments_rounded,
                            price == 0 ? 'Free' : 'Rs. $price'),
                        _detailRow(Icons.event_seat_rounded,
                            '$availableSeats / $maxParticipants seats available'),
                        if (contact.trim().isNotEmpty)
                          _detailRow(
                              Icons.contact_phone_rounded, contact),

                        if (description.trim().isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text('Description',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: primaryText,
                                  fontSize: 15)),
                          const SizedBox(height: 6),
                          Text(description,
                              style: TextStyle(
                                  color: secondaryText, height: 1.5)),
                        ],

                        if (rules.trim().isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text('Rules',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: primaryText,
                                  fontSize: 15)),
                          const SizedBox(height: 6),
                          Text(rules,
                              style: TextStyle(
                                  color: secondaryText, height: 1.5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primaryTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: primaryText, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
  Future<void> _toggleSuspend(
    BuildContext context,
    AdminProvider provider,
    String eventId,
    String title,
    bool isSuspended,
  ) async {
    final bool? confirm = await _showConfirmDialog(
      context,
      title: isSuspended ? 'Activate Event?' : 'Suspend Event?',
      message: isSuspended
          ? 'Do you want to activate "$title" again?'
          : 'Are you sure you want to suspend "$title"?',
      confirmText: isSuspended ? 'Activate' : 'Suspend',
      confirmColor:
          isSuspended ? const Color(0xFF16A34A) : const Color(0xFFD97706),
    );
    if (confirm != true) return;

    final bool success = isSuspended
        ? await provider.activateEvent(eventId)
        : await provider.suspendEvent(eventId);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSuspended
              ? '$title activated successfully.'
              : '$title suspended successfully.'),
          backgroundColor: isSuspended
              ? const Color(0xFF16A34A)
              : const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showError(
          context, provider.errorMessage ?? 'Action failed.');
    }
  }
  Future<void> _cancelEvent(
    BuildContext context,
    AdminProvider provider,
    String eventId,
    String title,
  ) async {
    final bool? confirm = await _showConfirmDialog(
      context,
      title: 'Cancel Event?',
      message:
          'This will cancel "$title" and notify all registered attendees. This cannot be undone.',
      confirmText: 'Cancel Event',
      confirmColor: const Color(0xFFDC5F2C),
    );
    if (confirm != true) return;

    final bool success = await provider.cancelEvent(eventId);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title cancelled. Attendees notified.'),
          backgroundColor: const Color(0xFFDC5F2C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showError(context,
          provider.errorMessage ?? 'Could not cancel event.');
    }
  }
  Future<void> _deleteEvent(
    BuildContext context,
    AdminProvider provider,
    String eventId,
    String title,
  ) async {
    final bool? confirm = await _showConfirmDialog(
      context,
      title: 'Delete Event?',
      message:
          'This will permanently delete "$title".\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: const Color(0xFFDC2626),
    );
    if (confirm != true) return;

    final bool success = await provider.deleteEvent(eventId);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title deleted successfully.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showError(context,
          provider.errorMessage ?? 'Could not delete event.');
    }
  }
  Future<void> _showEditDialog(
    BuildContext context,
    AdminProvider provider,
    String eventId,
    Map<String, dynamic> data,
  ) async {
    final titleController =
        TextEditingController(text: (data['title'] ?? '').toString());
    final descriptionController = TextEditingController(
        text: (data['description'] ?? '').toString());
    final categoryController = TextEditingController(
        text: (data['category'] ?? '').toString());
    final priceController = TextEditingController(
        text: (data['price'] ?? 0).toString());
    final organizerController = TextEditingController(
        text: (data['organizer'] ?? '').toString());
    final imageController = TextEditingController(
        text: (data['imageUrl'] ?? '').toString());
    final locationController = TextEditingController(
        text: (data['location'] ?? '').toString());
    final startTimeController = TextEditingController(
        text: (data['startTime'] ?? '').toString());
    final endTimeController = TextEditingController(
        text: (data['endTime'] ?? '').toString());
    final rulesController =
        TextEditingController(text: (data['rules'] ?? '').toString());
    final contactController = TextEditingController(
        text: (data['contactInfo'] ?? '').toString());
    final maxParticipantsController = TextEditingController(
        text: (data['maxParticipants'] ?? 0).toString());
    final availableSeatsController = TextEditingController(
        text: (data['availableSeats'] ?? 0).toString());

    DateTime selectedDate = _parseDate(data['date']);
    String selectedStatus =
        _validStatusValue((data['status'] ?? '').toString());

    final formKey = GlobalKey<FormState>();

    try {
      final Map<String, dynamic>? editedValues = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogBuildContext, setState) {
              final screenWidth = MediaQuery.of(dialogBuildContext).size.width;
              final screenHeight = MediaQuery.of(dialogBuildContext).size.height;
              
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Container(
                  width: screenWidth > 600 ? 560 : double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.88,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : deepTeal.withValues(alpha: 0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF004D4A), Color(0xFF007E7B)],
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(Icons.edit_calendar_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Edit Event Details',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Update event information & status',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(dialogContext, null),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- FORM CONTENT ---
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                            child: Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                _buildSectionTitle('Basic Information'),
                                _buildTextField(
                                  controller: titleController,
                                  label: 'Event Title',
                                  icon: Icons.title_rounded,
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty)
                                          ? 'Enter event title'
                                          : null,
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  controller: descriptionController,
                                  label: 'Description',
                                  icon: Icons.description_outlined,
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: categoryController,
                                        label: 'Category',
                                        icon: Icons.category_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: organizerController,
                                        label: 'Organizer',
                                        icon: Icons.person_outline,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  controller: imageController,
                                  label: 'Image URL',
                                  icon: Icons.image_outlined,
                                ),

                                const SizedBox(height: 32),
                                _buildSectionTitle('Date & Location'),
                                _buildTextField(
                                  controller: locationController,
                                  label: 'Location',
                                  icon: Icons.location_on_outlined,
                                ),
                                const SizedBox(height: 14),
                                InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                      context: dialogBuildContext,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                      builder: (ctx, child) {
                                        return Theme(
                                          data: Theme.of(ctx).copyWith(
                                            colorScheme:
                                                Theme.of(ctx).colorScheme.copyWith(
                                                      primary: primaryTeal,
                                                    ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(() => selectedDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: backgroundColor,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border:
                                          Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_outlined,
                                            color: primaryTeal, size: 22),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                          style: TextStyle(
                                              color: primaryText,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: startTimeController,
                                        label: 'Start Time',
                                        icon: Icons.access_time_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: endTimeController,
                                        label: 'End Time',
                                        icon: Icons.access_time_filled,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),
                                _buildSectionTitle('Ticketing & Capacity'),
                                _buildTextField(
                                  controller: priceController,
                                  label: 'Price',
                                  icon: Icons.payments_outlined,
                                  keyboardType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Enter price';
                                    }
                                    if (double.tryParse(value.trim()) ==
                                        null) return 'Enter valid price';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: maxParticipantsController,
                                        label: 'Max Participants',
                                        icon: Icons.groups_outlined,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: availableSeatsController,
                                        label: 'Available Seats',
                                        icon: Icons.event_seat_outlined,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),
                                _buildSectionTitle('Additional Details'),
                                _buildTextField(
                                  controller: rulesController,
                                  label: 'Rules',
                                  icon: Icons.rule_folder_outlined,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  controller: contactController,
                                  label: 'Contact Info',
                                  icon: Icons.contact_phone_outlined,
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: selectedStatus,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                                      color: primaryTeal),
                                  decoration: InputDecoration(
                                    labelText: 'Status',
                                    labelStyle: TextStyle(color: secondaryText),
                                    prefixIcon: Icon(Icons.verified_outlined,
                                        color: primaryTeal),
                                    filled: true,
                                    fillColor: backgroundColor,
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                          color: borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                          color: borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: primaryTeal, width: 1.5),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Approved',
                                        child: Text('Approved')),
                                    DropdownMenuItem(
                                        value: 'Pending',
                                        child: Text('Pending')),
                                    DropdownMenuItem(
                                        value: 'Suspended',
                                        child: Text('Suspended')),
                                    DropdownMenuItem(
                                        value: 'Cancelled',
                                        child: Text('Cancelled')),
                                    DropdownMenuItem(
                                        value: 'Rejected',
                                        child: Text('Rejected')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() =>
                                          selectedStatus = value);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // --- FOOTER ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(28)),
                          border: Border(
                              top: BorderSide(
                                  color: borderColor)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, null),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(80, 44),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Cancel',
                                  style: TextStyle(
                                      color: secondaryText,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryTeal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(140, 44),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 20),
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;

                                final double? price = double.tryParse(
                                    priceController.text.trim());
                                final int? maxParticipants = int.tryParse(
                                    maxParticipantsController.text.trim());
                                final int? availableSeats = int.tryParse(
                                    availableSeatsController.text.trim());

                                if (price == null || price < 0) {
                                  _showDialogError(dialogContext,
                                      'Please enter a valid, non-negative price.');
                                  return;
                                }
                                if (maxParticipants == null ||
                                    maxParticipants < 0) {
                                  _showDialogError(dialogContext,
                                      'Please enter valid max participants.');
                                  return;
                                }
                                if (availableSeats == null ||
                                    availableSeats < 0) {
                                  _showDialogError(dialogContext,
                                      'Please enter valid available seats.');
                                  return;
                                }
                                if (availableSeats > maxParticipants) {
                                  _showDialogError(dialogContext,
                                      'Available seats cannot exceed max participants.');
                                  return;
                                }
                                Navigator.pop(dialogContext, <String, dynamic>{
                                  'title': titleController.text.trim(),
                                  'description': descriptionController.text.trim(),
                                  'category': categoryController.text.trim(),
                                  'price': price,
                                  'organizer': organizerController.text.trim(),
                                  'organizerId': (data['organizerId'] ?? '').toString(),
                                  'imageUrl': imageController.text.trim(),
                                  'location': locationController.text.trim(),
                                  'date': selectedDate,
                                  'startTime': startTimeController.text.trim(),
                                  'endTime': endTimeController.text.trim(),
                                  'rules': rulesController.text.trim(),
                                  'contactInfo': contactController.text.trim(),
                                  'maxParticipants': maxParticipants,
                                  'availableSeats': availableSeats,
                                  'status': selectedStatus,
                                });
                              },
                              label: const Text('Save Changes',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          );
        },
      );

      if (editedValues == null || !context.mounted) return;

      final bool success = await provider.editEvent(
        eventId: eventId,
        title: editedValues['title'] as String,
        description: editedValues['description'] as String,
        category: editedValues['category'] as String,
        price: editedValues['price'] as double,
        organizer: editedValues['organizer'] as String,
        organizerId: editedValues['organizerId'] as String,
        imageUrl: editedValues['imageUrl'] as String,
        location: editedValues['location'] as String,
        date: editedValues['date'] as DateTime,
        startTime: editedValues['startTime'] as String,
        endTime: editedValues['endTime'] as String,
        rules: editedValues['rules'] as String,
        contactInfo: editedValues['contactInfo'] as String,
        maxParticipants: editedValues['maxParticipants'] as int,
        availableSeats: editedValues['availableSeats'] as int,
        status: editedValues['status'] as String,
      );

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event updated successfully.'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError(
          context,
          provider.errorMessage ?? 'Could not update event.',
        );
      }
    } catch (e, st) {
      debugPrint('Error in _showEditDialog: $e\n$st');
      if (context.mounted) {
        _showError(context, 'Could not open edit dialog: $e');
      }
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      categoryController.dispose();
      priceController.dispose();
      organizerController.dispose();
      imageController.dispose();
      locationController.dispose();
      startTimeController.dispose();
      endTimeController.dispose();
      rulesController.dispose();
      contactController.dispose();
      maxParticipantsController.dispose();
      availableSeatsController.dispose();
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: primaryTeal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: primaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
          color: primaryText, fontWeight: FontWeight.w600, fontSize: 14.5),
      cursorColor: primaryTeal,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: secondaryText, fontSize: 13.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: Icon(icon, color: primaryTeal, size: 20),
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: primaryTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
    );
  }
  Widget _buildActionIcon(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    final bool disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: disabled
                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F4))
                      : color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: disabled
                        ? (isDark ? const Color(0xFF64748B) : const Color(0xFFB7C6C5))
                        : color,
                    size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: disabled
                      ? const Color(0xFFB7C6C5)
                      : secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22)),
          title: Text(title,
              style: TextStyle(
                  color: primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          content: Text(message,
              style: TextStyle(
                  color: secondaryText,
                  fontSize: 14,
                  height: 1.5)),
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(80, 44),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  child: Text('Cancel',
                      style: TextStyle(
                          color: secondaryText,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(100, 44),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () =>
                      Navigator.pop(dialogContext, true),
                  child: Text(confirmText,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating),
    );
  }

  void _showDialogError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating),
    );
  }

  String _validStatusValue(String status) {
    const List<String> values = [
      'Approved',
      'Pending',
      'Suspended',
      'Cancelled',
      'Rejected'
    ];
    for (final value in values) {
      if (value.toLowerCase() == status.trim().toLowerCase())
        return value;
    }
    return 'Approved';
  }
}