import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CertificateService {
  static Future<Uint8List> buildCertificatePdf({
    required String attendeeName,
    required String eventTitle,
    required String organizerName,
    required DateTime eventDate,
    required String certificateNumber,
  }) async {
    final pw.Document document = pw.Document();
    final String date = '${eventDate.day}/${eventDate.month}/${eventDate.year}';

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#007E7B'), width: 3),
          ),
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(children: [
                pw.Text('EVENTEASE',
                    style: pw.TextStyle(
                        color: PdfColor.fromHex('#007E7B'),
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 3)),
                pw.SizedBox(height: 18),
                pw.Text('CERTIFICATE OF PARTICIPATION',
                    style: pw.TextStyle(
                        color: PdfColor.fromHex('#102A43'),
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 18),
                pw.Text('This is proudly presented to',
                    style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 10),
                pw.Text(attendeeName,
                    style: pw.TextStyle(
                        fontSize: 27,
                        color: PdfColor.fromHex('#007E7B'),
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 14),
                pw.Text('for verified attendance at',
                    style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 8),
                pw.Text(eventTitle,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 19, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Held on $date', style: const pw.TextStyle(fontSize: 12)),
              ]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Certificate ID: $certificateNumber',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Column(children: [
                  pw.Container(width: 130, height: 1, color: PdfColors.grey700),
                  pw.SizedBox(height: 5),
                  pw.Text(organizerName,
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    'Event Organizer',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ]),
              ]),
            ],
          ),
        ),
      ),
    );
    return document.save();
  }
}
