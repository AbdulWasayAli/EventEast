import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';

import 'registration_confirmation_screen.dart';
import '../shared/event_map_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class _Palette {
  static const Color primary = Color(0xFF007E7B);
  static const Color primaryDark = Color(0xFF005E5C);
  static const Color primaryLight = Color(0xFF00A896);
  static const Color ink = Color(0xFF0F172A);
  static const Color subtitle = Color(0xFF64748B);
  static const Color hairline = Color(0xFFEEF2F6);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color amber = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isRegistering = false;
  bool _isTogglingFavorite = false;
  bool _isSharing = false;

  Future<void> _shareEvent(EventModel event) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    final List<String> details = [
      'Check out this event on EventEase!',
      '',
      event.title,
      '',
      'Category: ${event.category}',
      'Date: ${event.date.day}/${event.date.month}/${event.date.year}',
      'Time: ${event.startTime.isNotEmpty ? event.startTime : 'TBA'}${event.endTime.isNotEmpty ? ' - ${event.endTime}' : ''}',
      'Location: ${event.location}',
      'Price: ${event.isPaid ? 'Rs. ${event.price.toStringAsFixed(0)}' : 'Free'}',
      if (event.maxParticipants > 0)
        'Seats available: ${event.availableSeats} of ${event.maxParticipants}',
      if (event.description.trim().isNotEmpty) ...[
        '',
        'About:',
        event.description.trim(),
      ],
      if (event.rules.trim().isNotEmpty) ...[
        '',
        'Rules & Guidelines:',
        event.rules.trim(),
      ],
      if (event.contactInfo.trim().isNotEmpty) ...[
        '',
        'Contact: ${event.contactInfo.trim()}',
      ],
      '',
      'Book your spot on EventEase.',
    ];
    final String shareText = details.join('\n');

    try {
      final Uri? imageUri = Uri.tryParse(event.imageUrl.trim());
      if (imageUri != null && imageUri.hasScheme) {
        final response = await http.get(imageUri);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          await Share.shareXFiles(
            [
              XFile.fromData(
                response.bodyBytes,
                name: '${event.title.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}_event.jpg',
                mimeType: response.headers['content-type'] ?? 'image/jpeg',
              ),
            ],
            text: shareText,
            subject: event.title,
          );
          return;
        }
      }

      await Share.share(shareText, subject: event.title);
    } catch (_) {
      await Share.share(shareText, subject: event.title);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _handleRegister(EventProvider provider, EventModel event) async {
    if (event.isRegistered || _isRegistering) return;

    String paymentMethod = 'free';
    if (event.isPaid) {
      final String? selectedMethod = await _choosePaymentMethod(event);
      if (selectedMethod == null) return;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final bool confirmed = await _confirmPayment(event, selectedMethod);
      if (!confirmed) return;
      paymentMethod = selectedMethod;
    }

    setState(() => _isRegistering = true);

    final bool success = await provider.registerForEvent(
      widget.eventId,
      paymentMethod: paymentMethod,
    );

    if (!mounted) return;
    setState(() => _isRegistering = false);

    if (success) {
      final registration = provider.getRegistrationForEvent(widget.eventId);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationConfirmationScreen(
            bookingId: registration?.qrCode ?? registration?.id ?? '',
            eventTitle: event.title,
            date: '${event.date.day}/${event.date.month}/${event.date.year}',
            time: event.startTime.isNotEmpty ? event.startTime : 'TBA',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Registration failed. Please try again.'),
          backgroundColor: _Palette.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  Future<String?> _choosePaymentMethod(EventModel event) {
    const methods = <({String id, String label, IconData icon})>[
      (id: 'easypaisa', label: 'Easypaisa', icon: Icons.account_balance_wallet_rounded),
      (id: 'jazzcash', label: 'JazzCash', icon: Icons.phone_android_rounded),
      (id: 'paypal', label: 'PayPal', icon: Icons.paypal_rounded),
      (id: 'cash', label: 'Cash', icon: Icons.payments_rounded),
    ];

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.86,
        ),
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext).dividerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _Palette.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _Palette.primary,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Choose payment method',
                            style: TextStyle(
                              color: _Palette.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Total: Rs. ${event.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: _Palette.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...methods.map(
                (method) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.pop(sheetContext, method.id),
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _Palette.hairline),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _Palette.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(method.icon, color: _Palette.primary),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(method.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 2),
                                  Text(
                                    method.id == 'cash'
                                        ? 'Pay at the event venue'
                                        : 'Enter your account details to continue',
                                    style: const TextStyle(color: _Palette.subtitle, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: _Palette.subtitle),
                          ],
                        ),
                      ),
                    ),
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

  Future<bool> _confirmPayment(EventModel event, String paymentMethod) async {
    final String methodLabel = paymentMethod == 'jazzcash'
        ? 'JazzCash'
        : paymentMethod == 'easypaisa'
            ? 'Easypaisa'
            : paymentMethod == 'paypal'
                ? 'PayPal'
                : 'Cash';

    return await showDialog<bool>(
          context: context,
          builder: (_) => _PaymentConfirmationDialog(
            event: event,
            methodLabel: methodLabel,
            needsAccountDetails: paymentMethod != 'cash',
            isPayPal: paymentMethod == 'paypal',
          ),
        ) ??
        false;
  }

  Future<void> _handleToggleFavorite(EventProvider provider) async {
    if (_isTogglingFavorite) return;
    setState(() => _isTogglingFavorite = true);

    final bool success = await provider.toggleFavoriteStatus(widget.eventId);

    if (!mounted) return;
    setState(() => _isTogglingFavorite = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not update favorites.'),
          backgroundColor: _Palette.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventProvider>(context);

    final event = provider.getEventById(widget.eventId);

    if (event == null) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _Palette.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.event_busy_rounded, size: 38, color: _Palette.primary),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Event not found',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
      );
    }

    final bool isSoldOut = event.availableSeats <= 0 && !event.isRegistered;
    final theme = Theme.of(context);
    final daysLeft = event.date.difference(DateTime.now()).inDays;
    final String countdownText = daysLeft > 0 ? '$daysLeft Days Left' : (daysLeft == 0 ? 'Today!' : 'Past Event');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 340.0,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _glassIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: _glassIconButton(
                      icon: Icons.ios_share_rounded,
                      onTap: _isSharing ? () {} : () => _shareEvent(event),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
                    child: _isTogglingFavorite
                        ? Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _Palette.primary,
                              ),
                            ),
                          )
                        : _glassIconButton(
                            icon: event.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            iconColor: event.isFavorite ? _Palette.danger : null,
                            onTap: () => _handleToggleFavorite(provider),
                          ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'event_image_${event.id}',
                        child: Image.network(
                          event.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_Palette.primaryDark, _Palette.primary],
                              ),
                            ),
                            child: const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.0),
                              Colors.black.withOpacity(0.15),
                              Colors.black.withOpacity(0.62),
                            ],
                            stops: const [0.35, 0.65, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 28,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                event.category.toUpperCase(),
                                style: const TextStyle(
                                  color: _Palette.primary,
                                  fontSize: 10.5,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_Palette.primaryDark, _Palette.primary],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${event.date.day} ${_getMonthString(event.date.month)}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  transform: Matrix4.translationValues(0, -16, 0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: daysLeft > 0 ? _Palette.amber.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    daysLeft > 0 ? Icons.hourglass_top_rounded : Icons.event_available_rounded,
                                    size: 13,
                                    color: daysLeft > 0 ? const Color(0xFFB45309) : _Palette.subtitle,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    countdownText,
                                    style: TextStyle(
                                      color: daysLeft > 0 ? const Color(0xFFB45309) : _Palette.subtitle,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (isSoldOut)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _Palette.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'SOLD OUT',
                                  style: TextStyle(
                                    color: _Palette.danger,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          event.title,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.titleLarge?.color,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.calendar_month_rounded,
                                '${event.date.day}/${event.date.month}/${event.date.year}',
                                event.startTime.isNotEmpty && event.endTime.isNotEmpty
                                    ? '${event.startTime} - ${event.endTime}'
                                    : 'Time to be announced',
                              ),
                              _divider(),
                              _buildInfoRow(
                                Icons.location_on_rounded,
                                event.location,
                                'Venue',
                                trailing: event.hasCoordinates
                                    ? TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EventMapScreen(event: event),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        icon: const Icon(Icons.map_rounded, color: _Palette.primary, size: 16),
                                        label: const Text('Map', style: TextStyle(color: _Palette.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
                                      )
                                    : null,
                              ),
                              _divider(),
                              _buildInfoRow(Icons.person_rounded, event.organizer, 'Organizer'),
                              _divider(),
                              _buildInfoRow(
                                Icons.people_alt_rounded,
                                '${event.availableSeats} of ${event.maxParticipants} seats available',
                                'Capacity',
                              ),
                            ],
                          ),
                        ),

                        if (event.hasCoordinates) ...[
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(event.latitude!, event.longitude!),
                                      initialZoom: 14.0,
                                      interactionOptions: const InteractionOptions(
                                        flags: InteractiveFlag.none,
                                      ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.eventease.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(event.latitude!, event.longitude!),
                                            width: 40,
                                            height: 40,
                                            child: const Icon(Icons.location_on, color: _Palette.primary, size: 40),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Positioned.fill(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EventMapScreen(event: event),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 10,
                                    bottom: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.92),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.open_in_full_rounded, size: 12, color: _Palette.primary),
                                          SizedBox(width: 4),
                                          Text('Open map', style: TextStyle(color: _Palette.primary, fontSize: 10.5, fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 30),
                        _sectionTitle('About Event'),
                        const SizedBox(height: 10),
                        Text(
                          event.description,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            fontSize: 14.5,
                            height: 1.65,
                          ),
                        ),

                        if (event.rules.trim().isNotEmpty) ...[
                          const SizedBox(height: 26),
                          _sectionTitle('Rules & Guidelines'),
                          const SizedBox(height: 10),
                          Text(
                            event.rules,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontSize: 14.5,
                              height: 1.65,
                            ),
                          ),
                        ],

                        if (event.contactInfo.trim().isNotEmpty) ...[
                          const SizedBox(height: 26),
                          _sectionTitle('Contact'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _Palette.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.contact_phone_rounded, color: _Palette.primary, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    event.contactInfo,
                                    style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 13.5, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 150),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Sticky bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: _Palette.ink.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool stackAction =
                        constraints.maxWidth < 430 || event.isRegistered;
                    final Widget price = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PRICE',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.isPaid
                              ? 'Rs. ${event.price.toStringAsFixed(0)}'
                              : 'FREE',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.titleLarge?.color,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    );
                    final Widget action = Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: (event.isRegistered || isSoldOut)
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : const [
                                  _Palette.primaryLight,
                                  _Palette.primaryDark,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: (event.isRegistered || isSoldOut)
                            ? []
                            : [
                                BoxShadow(
                                  color: _Palette.primary.withOpacity(0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        onPressed: (event.isRegistered || isSoldOut || _isRegistering)
                            ? null
                            : () => _handleRegister(provider, event),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isRegistering
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (event.isRegistered) ...[
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      event.isRegistered
                                          ? 'Already Registered'
                                          : isSoldOut
                                              ? 'Sold Out'
                                              : event.isPaid
                                                  ? 'Buy Now'
                                                  : 'Register Now',
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    );

                    if (stackAction) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          price,
                          const SizedBox(height: 10),
                          action,
                        ],
                      );
                    }

                    return Row(
                  children: [
                    price,
                    const SizedBox(width: 12),
                    Expanded(child: action),
                  ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Builder(
      builder: (context) => Material(
        color: Theme.of(context).cardColor.withOpacity(0.85),
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color, size: 20),
          ),
        ),
      ),
    );
  }

  static Widget _sectionTitle(String title) {
    return Builder(
      builder: (context) => Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: _Palette.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _divider() {
    return Builder(
      builder: (context) => Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor, indent: 12, endIndent: 12),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Icon(icon, color: _Palette.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  String _getMonthString(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
class _PaymentConfirmationDialog extends StatefulWidget {
  final EventModel event;
  final String methodLabel;
  final bool needsAccountDetails;
  final bool isPayPal;

  const _PaymentConfirmationDialog({
    required this.event,
    required this.methodLabel,
    required this.needsAccountDetails,
    required this.isPayPal,
  });

  @override
  State<_PaymentConfirmationDialog> createState() =>
      _PaymentConfirmationDialogState();
}

class _PaymentConfirmationDialogState
    extends State<_PaymentConfirmationDialog> {
  late final TextEditingController _accountController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _accountController = TextEditingController();
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  void _confirm() {
    final String details = _accountController.text.trim();
    if (widget.needsAccountDetails) {
      final bool isValid = widget.isPayPal
          ? RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(details)
          : RegExp(r'^03\d{9}$').hasMatch(details);
      if (!isValid) {
        setState(() {
          _errorText = widget.isPayPal
              ? 'Enter a valid email address.'
              : 'Enter an 11-digit number starting with 03.';
        });
        return;
      }
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _Palette.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline_rounded, color: _Palette.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirm Payment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rs. ${widget.event.price.toStringAsFixed(0)} via ${widget.methodLabel}',
          ),
          const SizedBox(height: 8),
          const Text(
            'Review your payment details before confirming.',
            style: TextStyle(color: _Palette.subtitle, fontSize: 13),
          ),
          if (widget.needsAccountDetails) ...[
            const SizedBox(height: 18),
            TextField(
              controller: _accountController,
              keyboardType: widget.isPayPal
                  ? TextInputType.emailAddress
                  : TextInputType.phone,
              decoration: InputDecoration(
                labelText: widget.isPayPal
                    ? 'PayPal email address'
                    : '${widget.methodLabel} mobile account number',
                hintText: widget.isPayPal ? 'name@example.com' : '03XXXXXXXXX',
                errorText: _errorText,
                prefixIcon: Icon(
                  widget.isPayPal
                      ? Icons.email_outlined
                      : Icons.phone_android_rounded,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _Palette.primary,
                  side: const BorderSide(color: _Palette.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _Palette.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _confirm,
                child: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
