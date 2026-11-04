import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/event_provider.dart';

class QRPassScreen extends StatefulWidget {
  final String eventId;
  final String? registrationId;

  const QRPassScreen({
    super.key,
    required this.eventId,
    this.registrationId,
  });

  @override
  State<QRPassScreen> createState() => _QRPassScreenState();
}

class _QRPassScreenState extends State<QRPassScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);

    final event = eventProvider.getEventById(widget.eventId);
    final registration =
    eventProvider.getRegistrationForEvent(widget.eventId);
    final String? displayId =
        widget.registrationId ?? registration?.qrCode;

    if (event == null || displayId == null || displayId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.white54, size: 48),
              SizedBox(height: 16),
              Text(
                'No valid pass found for this event',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    final bool isCancelled =
        (registration?.status.toLowerCase() ?? '') == 'cancelled';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('DIGITAL ENTRY',
                style: TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1)),
            SizedBox(height: 3),
            Text('Your pass',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth > 460
                ? 430.0
                : constraints.maxWidth;
            final qrSize = cardWidth < 360 ? 132.0 : 148.0;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardWidth),
                  child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (isCancelled
                          ? Colors.redAccent
                          : const Color(0xFF00A896))
                          .withOpacity(0.15 + (_glowController.value * 0.2)),
                      blurRadius: 40 + (_glowController.value * 20),
                      spreadRadius: 5 + (_glowController.value * 10),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCancelled
                            ? [Colors.redAccent, Colors.red.shade700]
                            : const [Color(0xFF00A896), Color(0xFF028090)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isCancelled
                              ? Icons.cancel_rounded
                              : Icons.event_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(height: 8),
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          isCancelled
                              ? 'This registration has been cancelled'
                              : 'Organized by ${event.organizer}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: List.generate(
                        30,
                            (index) => Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            color: index.isEven
                                ? Colors.grey.shade200
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey.shade200, width: 2),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: isCancelled ? 0.25 : 1.0,
                                child: QrImageView(
                                  data: displayId,
                                  version: QrVersions.auto,
                                  size: qrSize,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                displayId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildDetailRow('Date',
                            '${event.date.day}/${event.date.month}/${event.date.year}'),
                        SizedBox(height: 8),
                        _buildDetailRow(
                          'Time',
                          (event.startTime.isNotEmpty || event.endTime.isNotEmpty)
                              ? '${event.startTime} - ${event.endTime}'
                              : 'To be announced',
                        ),
                        SizedBox(height: 8),
                        _buildDetailRow('Ticket', '1x General Admission'),
                        SizedBox(height: 8),
                        _buildDetailRow('ID', displayId),
                        if (registration != null) ...[
                          SizedBox(height: 8),
                          _buildDetailRow('Status', registration.status),
                        ],

                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: (isCancelled
                                ? Colors.redAccent
                                : const Color(0xFF007E7B))
                                .withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isCancelled
                                    ? Icons.info_outline_rounded
                                    : Icons.info_outline_rounded,
                                color: isCancelled
                                    ? Colors.redAccent
                                    : const Color(0xFF007E7B),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isCancelled
                                      ? 'This pass is no longer valid for entry'
                                      : 'Show this QR code at entrance',
                                  style: TextStyle(
                                    color: isCancelled
                                        ? Colors.redAccent
                                        : const Color(0xFF007E7B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final pdf = await _generateTicketPdf(event, displayId, registration?.status);
                                  await Printing.layoutPdf(
                                    onLayout: (PdfPageFormat format) async => pdf.save(),
                                    name: 'EventEase_Pass_${displayId.replaceAll(' ', '_')}.pdf',
                                  );
                                },
                                icon: Icon(Icons.download_rounded, size: 18),
                                label: Text('Download', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF007E7B),
                                  side: const BorderSide(color: Color(0xFF007E7B)),
                                  minimumSize: const Size(0, 48),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final pdf = await _generateTicketPdf(event, displayId, registration?.status);
                                  await Printing.sharePdf(
                                    bytes: await pdf.save(),
                                    filename: 'EventEase_Pass_${displayId.replaceAll(' ', '_')}.pdf',
                                  );
                                },
                                icon: Icon(Icons.share_rounded, size: 18, color: Colors.white),
                                label: Text('Share', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF007E7B),
                                  minimumSize: const Size(0, 48),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<pw.Document> _generateTicketPdf(dynamic event, String displayId, String? status) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#007E7B'), width: 2),
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'EventEase Pass',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#007E7B'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Official Digital Ticket Pass',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#007E7B')),
                pw.SizedBox(height: 12),
                pw.Text(
                  event.title ?? 'Event Ticket',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Organized by: ${event.organizer ?? 'EventEase'}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 16),

                // QR Code Widget
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: displayId,
                  width: 140,
                  height: 140,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'ID: $displayId',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('${event.date.day}/${event.date.month}/${event.date.year}', style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Status:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text(status ?? 'Active', style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.blueGrey.shade400,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
