import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/event_model.dart';
import '../../services/certificate_service.dart';
import '../../widgets/premium_ui.dart';

class CertificatePreviewScreen extends StatefulWidget {
  final EventModel event;

  const CertificatePreviewScreen({super.key, required this.event});

  @override
  State<CertificatePreviewScreen> createState() =>
      _CertificatePreviewScreenState();
}

class _CertificatePreviewScreenState extends State<CertificatePreviewScreen> {
  bool _isCreating = false;
  String _attendeeName = 'Event Attendee';

  String get _certificateId {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return 'EE-${widget.event.id.substring(0, widget.event.id.length.clamp(0, 6))}-${userId.substring(0, userId.length.clamp(0, 4))}'
        .toUpperCase();
  }

  String get _eventDate =>
      '${widget.event.date.day}/${widget.event.date.month}/${widget.event.date.year}';

  @override
  void initState() {
    super.initState();
    _loadPreviewName();
  }

  Future<void> _loadPreviewName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fallback = user.displayName?.trim();
    if (fallback != null && fallback.isNotEmpty && mounted) {
      setState(() => _attendeeName = fallback);
    }

    try {
      final attendance = await FirebaseFirestore.instance
          .collection('attendance')
          .doc('${widget.event.id}_${user.uid}')
          .get();
      final name = attendance.data()?['userName']?.toString().trim();
      if (mounted && name != null && name.isNotEmpty) {
        setState(() => _attendeeName = name);
      }
    } catch (_) {
    }
  }

  Future<void> _createAndShare({required bool share}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isCreating) return;

    setState(() => _isCreating = true);
    try {
      final attendance = await FirebaseFirestore.instance
          .collection('attendance')
          .doc('${widget.event.id}_${user.uid}')
          .get();
      if (!attendance.exists) {
        throw Exception('Attendance has not been verified.');
      }

      final data = attendance.data() ?? <String, dynamic>{};
      final attendeeName =
          (data['userName'] ?? user.displayName ?? _attendeeName).toString();
      await FirebaseFirestore.instance
          .collection('certificates')
          .doc('${widget.event.id}_${user.uid}')
          .set({
        'eventId': widget.event.id,
        'userId': user.uid,
        'attendanceId': attendance.id,
        'certificateNumber': _certificateId,
        'issuedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final bytes = await CertificateService.buildCertificatePdf(
        attendeeName: attendeeName,
        eventTitle: widget.event.title,
        organizerName:
            widget.event.organizer.isEmpty ? 'EventEase' : widget.event.organizer,
        eventDate: widget.event.date,
        certificateNumber: _certificateId,
      );

      if (share) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'EventEase_Certificate_${widget.event.id}.pdf',
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: 'EventEase Certificate',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF007E7B);
    const navy = Color(0xFF102A43);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final organizer =
        widget.event.organizer.isEmpty ? 'EventEase' : widget.event.organizer;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: SettingsStyleAppBar(
        title: 'My Certificate',
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: primary,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'EVENTEASE',
                            style: TextStyle(
                              color: primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Icon(Icons.workspace_premium_rounded,
                              color: primary, size: 44),
                          const SizedBox(height: 10),
                          Text(
                            'CERTIFICATE OF\nPARTICIPATION',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white : navy,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              height: 1.18,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'This is proudly presented to',
                            style: TextStyle(fontSize: 13, color: textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _attendeeName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: primary,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'for verified attendance at',
                            style: TextStyle(fontSize: 13, color: textSecondary),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            widget.event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white : navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Held on $_eventDate',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              'Certificate ID: $_certificateId',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 104,
                            child: Column(
                              children: [
                                Container(height: 1, color: const Color(0xFF94A3B8)),
                                const SizedBox(height: 4),
                                Text(
                                  organizer,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Event Organizer',
                                  style: TextStyle(fontSize: 9, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCreating ? null : () => _createAndShare(share: false),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(
                    _isCreating ? 'Preparing certificate...' : 'Download PDF',
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isCreating ? null : () => _createAndShare(share: true),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Certificate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
