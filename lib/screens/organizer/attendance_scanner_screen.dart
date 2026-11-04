import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AttendanceScannerScreen extends StatefulWidget {
  const AttendanceScannerScreen({super.key});

  @override
  State<AttendanceScannerScreen> createState() =>
      _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState
    extends State<AttendanceScannerScreen>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;

  final MobileScannerController _scannerController =
  MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

 
  bool _isProcessing = false;
  bool _isTorchOn = false;

 
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }


  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  
  Future<void> _onQRDetected(BarcodeCapture capture) async {
    if (_isProcessing) {
      return;
    }

    if (capture.barcodes.isEmpty) {
      return;
    }

    final Barcode barcode = capture.barcodes.first;

    final String? rawValue = barcode.rawValue;

    if (rawValue == null || rawValue.trim().isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Stop scanner while QR is being processed.
    try {
      await _scannerController.stop();
    } catch (_) {}

    await _markAttendance(
      rawValue.trim(),
    );
  }

 
  Future<void> _markAttendance(String qrValue) async {
    try {
      final FirebaseFirestore firestore =
          FirebaseFirestore.instance;

      
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (!mounted) return;

        await _showMessageDialog(
          title: 'Login Required',
          message:
          'You must be logged in as an organizer to mark attendance.',
          isSuccess: false,
        );

        await _resetScanner();
        return;
      }

      
      String registrationId =
      _extractRegistrationId(qrValue);

      if (registrationId.isEmpty) {
        if (!mounted) return;

        await _showMessageDialog(
          title: 'Invalid QR Code',
          message:
          'The scanned QR code does not contain a valid registration ID.',
          isSuccess: false,
        );

        await _resetScanner();
        return;
      }

     
      final DocumentReference<Map<String, dynamic>>
      registrationRef =
      firestore
          .collection('registrations')
          .doc(registrationId);

      final DocumentSnapshot<Map<String, dynamic>>
      registrationDoc =
      await registrationRef.get();

      if (!registrationDoc.exists) {
        if (!mounted) return;

        await _showMessageDialog(
          title: 'Invalid Pass',
          message:
          'This QR code does not belong to a valid registration.',
          isSuccess: false,
        );

        await _resetScanner();
        return;
      }

      final Map<String, dynamic> regData =
          registrationDoc.data() ?? {};

    

      final String eventId =
      _stringValue(
        regData['eventId'],
      );

      final String userId =
      _stringValue(
        regData['userId'],
      );

      final String userName =
      _stringValue(
        regData['userName'],
      ).isNotEmpty
          ? _stringValue(
        regData['userName'],
      )
          : 'Participant';

      final String registrationStatus =
      _stringValue(
        regData['status'],
      ).toLowerCase();

      
      if (eventId.isEmpty || userId.isEmpty) {
        if (!mounted) return;

        await _showMessageDialog(
          title: 'Invalid Registration',
          message:
          'This registration is missing required attendee information.',
          isSuccess: false,
        );

        await _resetScanner();
        return;
      }

    
      if (_isCancelledStatus(registrationStatus)) {
        if (!mounted) return;

        await _showMessageDialog(
          title: 'Registration Cancelled',
          message:
          '$userName\'s registration has been cancelled.',
          isSuccess: false,
        );

        await _resetScanner();
        return;
      }

  
      final _EventDocument? event =
      await _findEvent(
        firestore: firestore,
        eventId: eventId,
      );

      if (event == null) {
        if (!mounted) return;

        await _showMessageDialog(
          title: 'Event Not Found',
          message:
          'The event associated with this registration could not be found.',
          isSuccess: false,
        );

        await _resetScanner();
        return;
      }

      final Map<String, dynamic> eventData =
          event.data;

      
      final String eventTitle =
      _stringValue(
        eventData['title'],
      ).isNotEmpty
          ? _stringValue(
        eventData['title'],
      )
          : 'Event';

      final String eventStatus =
      _stringValue(
        eventData['status'],
      ).toLowerCase();

      final String organizerId =
      _stringValue(
        eventData['organizerId'],
      );

    

      if (organizerId.isEmpty) {
        if (!mounted) return;

        await _showMessageDialog(
          title: 'Invalid Event',
          message:
          'This event does not have a valid organizer assigned to it.',
          isSuccess: false,
        );

        await _resetScanner();
        return;
      }

      if (organizerId != currentUser.uid) {
        if (!mounted) return;

        await _showMessageDialog(
          title: 'Not Authorized',
          message:
          'You are not authorized to mark attendance for "$eventTitle".',
          isSuccess: false,
        );

        await _resetScanner();
        return;
      }

     
      if (_isCancelledStatus(eventStatus)) {
        if (!mounted) return;

        await _showMessageDialog(
          title: 'Event Cancelled',
          message:
          '$eventTitle has been cancelled. Attendance cannot be marked.',
          isSuccess: false,
        );

        await _resetScanner();
        return;
      }

      
      final QuerySnapshot<Map<String, dynamic>>
      existingAttendanceQuery =
      await firestore
          .collection('attendance')
          .where(
        'eventId',
        isEqualTo: eventId,
      )
          .where(
        'userId',
        isEqualTo: userId,
      )
          .limit(1)
          .get();

      if (existingAttendanceQuery.docs.isNotEmpty) {
        if (!mounted) return;

        await _showMessageDialog(
          title: 'Already Checked-in',
          message:
          '$userName has already been marked present for this event.',
          isSuccess: false,
        );

        await _resetScanner();
        return;
      }

      
      final String attendanceDocumentId =
          '${eventId}_$userId';

      final DocumentReference<Map<String, dynamic>>
      attendanceRef =
      firestore
          .collection('attendance')
          .doc(attendanceDocumentId);

      bool createdSuccessfully = false;

      await firestore.runTransaction(
            (transaction) async {
          final DocumentSnapshot<Map<String, dynamic>>
          attendanceSnapshot =
          await transaction.get(
            attendanceRef,
          );

          if (attendanceSnapshot.exists) {
            return;
          }

          transaction.set(
            attendanceRef,
            {
              'eventId': eventId,
              'eventTitle': eventTitle,
              'userId': userId,
              'userName': userName,
              'registrationId': registrationId,
              'timestamp':
              FieldValue.serverTimestamp(),
              'status': 'Present',
              'markedBy': currentUser.uid,
              'createdAt':
              FieldValue.serverTimestamp(),
            },
          );

          createdSuccessfully = true;
        },
      );

      
      if (!createdSuccessfully) {
        if (!mounted) return;

        await _showMessageDialog(
          title: 'Already Checked-in',
          message:
          '$userName has already been marked present for this event.',
          isSuccess: false,
        );

        await _resetScanner();
        return;
      }

      
      if (!mounted) return;

      await _showMessageDialog(
        title: 'Check-in Successful!',
        message:
        '$userName\n\n'
            'Event: $eventTitle\n\n'
            'Attendance marked as Present.',
        isSuccess: true,
      );

      await _resetScanner();
    } on FirebaseException catch (e) {
      if (!mounted) return;

      await _showMessageDialog(
        title: 'Firebase Error',
        message:
        e.message ??
            'A Firebase error occurred while processing the attendance.',
        isSuccess: false,
      );

      await _resetScanner();
    } catch (e) {
      if (!mounted) return;

      await _showMessageDialog(
        title: 'Error',
        message:
        'Something went wrong while verifying the QR code.\n\n$e',
        isSuccess: false,
      );

      await _resetScanner();
    }
  }

 
  Future<_EventDocument?> _findEvent({
    required FirebaseFirestore firestore,
    required String eventId,
  }) async {
    
    try {
      final DocumentSnapshot<Map<String, dynamic>>
      doc =
      await firestore
          .collection('events')
          .doc(eventId)
          .get();

      if (doc.exists) {
        return _EventDocument(
          collection: 'events',
          data: doc.data() ?? {},
        );
      }
    } catch (_) {}

   
    try {
      final DocumentSnapshot<Map<String, dynamic>>
      doc =
      await firestore
          .collection('Events')
          .doc(eventId)
          .get();

      if (doc.exists) {
        return _EventDocument(
          collection: 'Events',
          data: doc.data() ?? {},
        );
      }
    } catch (_) {}

    return null;
  }

  // ============================================================
  // EXTRACT REGISTRATION ID
  // ============================================================

  String _extractRegistrationId(String qrValue) {
    String value = qrValue.trim();

    if (value.isEmpty) {
      return '';
    }

    // ----------------------------------------------------------
    // If QR is a simple registration ID
    // ----------------------------------------------------------

    if (!value.contains('/') &&
        !value.contains('?') &&
        !value.contains('=') &&
        !value.contains('{') &&
        !value.contains('}')) {
      return value;
    }

    // ----------------------------------------------------------
    // Try URL parsing
    // ----------------------------------------------------------

    try {
      final Uri? uri = Uri.tryParse(value);

      if (uri != null) {
        // Example:
        // https://example.com/ticket?id=ABC123

        final String? queryId =
        uri.queryParameters['id'];

        if (queryId != null &&
            queryId.trim().isNotEmpty) {
          return queryId.trim();
        }

        final String? registrationId =
        uri.queryParameters['registrationId'];

        if (registrationId != null &&
            registrationId.trim().isNotEmpty) {
          return registrationId.trim();
        }

        // Example:
        // https://example.com/ticket/ABC123

        if (uri.pathSegments.isNotEmpty) {
          final String lastSegment =
          uri.pathSegments.last.trim();

          if (lastSegment.isNotEmpty) {
            return lastSegment;
          }
        }
      }
    } catch (_) {}

    // ----------------------------------------------------------
    // JSON-like fallback
    // ----------------------------------------------------------

    final RegExp registrationIdRegex =
    RegExp(
      r'"registrationId"\s*:\s*"([^"]+)"',
      caseSensitive: false,
    );

    final Match? registrationMatch =
    registrationIdRegex.firstMatch(value);

    if (registrationMatch != null) {
      return registrationMatch
          .group(1)
          ?.trim() ??
          '';
    }

    final RegExp idRegex =
    RegExp(
      r'"id"\s*:\s*"([^"]+)"',
      caseSensitive: false,
    );

    final Match? idMatch =
    idRegex.firstMatch(value);

    if (idMatch != null) {
      return idMatch.group(1)?.trim() ?? '';
    }

    // ----------------------------------------------------------
    // Last fallback
    // ----------------------------------------------------------

    if (value.contains('/')) {
      final List<String> parts =
      value.split('/');

      final String last =
      parts.last.trim();

      if (last.isNotEmpty) {
        return last;
      }
    }

    return value;
  }

  // ============================================================
  // RESET SCANNER
  // ============================================================

  Future<void> _resetScanner() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
    });

    try {
      await _scannerController.start();
    } catch (_) {}
  }

  // ============================================================
  // TOGGLE TORCH
  // ============================================================

  Future<void> _toggleTorch() async {
    if (_isProcessing) {
      return;
    }

    try {
      await _scannerController.toggleTorch();
    } catch (_) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  // ============================================================
  // MESSAGE DIALOG
  // ============================================================

  Future<void> _showMessageDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (dialogContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            24,
            28,
            24,
            24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------------------------------------
                // ICON
                // ------------------------------------------------

                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: (isSuccess
                        ? const Color(0xFF007E7B)
                        : Colors.redAccent)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: isSuccess
                        ? const Color(0xFF007E7B)
                        : Colors.redAccent,
                    size: 52,
                  ),
                ),

                SizedBox(height: 18),

                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSuccess
                        ? const Color(0xFF1E293B)
                        : Colors.redAccent,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 12),

                // ------------------------------------------------
                // MESSAGE
                // ------------------------------------------------

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 26),

                // ------------------------------------------------
                // BUTTON
                // ------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        dialogContext,
                      ).pop();
                    },
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor: isSuccess
                          ? const Color(0xFF007E7B)
                          : Colors.redAccent,
                      foregroundColor:
                      Colors.white,
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                    child: Text(
                      isSuccess
                          ? 'Scan Next'
                          : 'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ======================================================
          // REAL CAMERA
          // ======================================================

          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onQRDetected,
            ),
          ),

          // ======================================================
          // DARK OVERLAY
          // ======================================================

          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color:
                Colors.black.withOpacity(0.28),
              ),
            ),
          ),

          // ======================================================
          // TOP HEADER
          // ======================================================

          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                0,
              ),
              child: Row(
                children: [
                  // BACK BUTTON
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.35),
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons
                            .arrow_back_rounded,
                        color: Colors.white,
                      ),
                      onPressed:
                      _isProcessing
                          ? null
                          : () {
                        Navigator.pop(
                          context,
                        );
                      },
                    ),
                  ),

                  SizedBox(width: 12),

                  // TITLE
                  const Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ATTENDANCE CHECK-IN',
                          style: TextStyle(
                            color: Color(0xB3FFFFFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Scan ticket',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TORCH
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.35),
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isTorchOn
                            ? Icons
                            .flash_on_rounded
                            : Icons
                            .flash_off_rounded,
                        color: Colors.white,
                      ),
                      onPressed:
                      _toggleTorch,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // CENTER SCANNER
          // ======================================================

          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment:
                    Alignment.center,
                    children: [
                      // ------------------------------------------
                      // SCANNER FRAME
                      // ------------------------------------------

                      Container(
                        width: 280,
                        height: 280,
                        decoration:
                        BoxDecoration(
                          borderRadius:
                          BorderRadius
                              .circular(
                            30,
                          ),
                          border:
                          Border.all(
                            color: Colors.white
                                .withOpacity(
                              0.35,
                            ),
                            width: 2,
                          ),
                        ),
                      ),

                      // ------------------------------------------
                      // ANIMATED SCANNING LINE
                      // ------------------------------------------

                      AnimatedBuilder(
                        animation:
                        _animationController,
                        builder:
                            (context, child) {
                          return Positioned(
                            top: 20 +
                                (_animationController
                                    .value *
                                    240),
                            child:
                            Container(
                              width: 245,
                              height: 3,
                              decoration:
                              BoxDecoration(
                                color: const Color(
                                  0xFF007E7B,
                                ),
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  10,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF007E7B,
                                    ).withOpacity(
                                      0.9,
                                    ),
                                    blurRadius:
                                    12,
                                    spreadRadius:
                                    2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // ------------------------------------------
                      // CORNERS
                      // ------------------------------------------

                      _buildCorner(
                        Alignment.topLeft,
                      ),

                      _buildCorner(
                        Alignment.topRight,
                      ),

                      _buildCorner(
                        Alignment.bottomLeft,
                      ),

                      _buildCorner(
                        Alignment.bottomRight,
                      ),
                    ],
                  ),

                  SizedBox(height: 28),

                  Text(
                    'Align QR Code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    _isProcessing
                        ? 'Verifying registration...'
                        : 'Scanning automatically',
                    style: TextStyle(
                      color: Colors.white
                          .withOpacity(0.7),
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // PROCESSING OVERLAY
          // ======================================================

          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black
                    .withOpacity(0.55),
                child: Center(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child:
                        CircularProgressIndicator(
                          color: Color(
                            0xFF007E7B,
                          ),
                          strokeWidth: 4,
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Verifying QR Code...',
                        style:
                        TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ======================================================
          // BOTTOM INFO
          // ======================================================

          Positioned(
            left: 24,
            right: 24,
            bottom: 30,
            child: SafeArea(
              child: Container(
                padding:
                const EdgeInsets.all(
                  16,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.black
                      .withOpacity(0.55),
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                  border:
                  Border.all(
                    color: Colors.white
                        .withOpacity(0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .qr_code_2_rounded,
                      color: Color(
                        0xFF007E7B,
                      ),
                      size: 28,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Scan the attendee QR ticket to verify their registration and mark attendance.',
                        style:
                        TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCANNER CORNERS
  // ============================================================

  Widget _buildCorner(
      Alignment alignment,
      ) {
    return Positioned(
      top: alignment.y == -1
          ? 0
          : null,
      bottom: alignment.y == 1
          ? 0
          : null,
      left: alignment.x == -1
          ? 0
          : null,
      right: alignment.x == 1
          ? 0
          : null,
      child: Container(
        width: 42,
        height: 42,
        decoration:
        BoxDecoration(
          border: Border(
            top: alignment.y == -1
                ? const BorderSide(
              color: Color(
                0xFF007E7B,
              ),
              width: 5,
            )
                : BorderSide.none,
            bottom: alignment.y == 1
                ? const BorderSide(
              color: Color(
                0xFF007E7B,
              ),
              width: 5,
            )
                : BorderSide.none,
            left: alignment.x == -1
                ? const BorderSide(
              color: Color(
                0xFF007E7B,
              ),
              width: 5,
            )
                : BorderSide.none,
            right: alignment.x == 1
                ? const BorderSide(
              color: Color(
                0xFF007E7B,
              ),
              width: 5,
            )
                : BorderSide.none,
          ),
          borderRadius:
          BorderRadius.only(
            topLeft:
            alignment ==
                Alignment.topLeft
                ? const Radius
                .circular(8)
                : Radius.zero,
            topRight:
            alignment ==
                Alignment.topRight
                ? const Radius
                .circular(8)
                : Radius.zero,
            bottomLeft:
            alignment ==
                Alignment.bottomLeft
                ? const Radius
                .circular(8)
                : Radius.zero,
            bottomRight:
            alignment ==
                Alignment.bottomRight
                ? const Radius
                .circular(8)
                : Radius.zero,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STRING HELPER
  // ============================================================

  static String _stringValue(
      dynamic value,
      ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // CANCELLED STATUS HELPER
  // ============================================================

  static bool _isCancelledStatus(
      String status,
      ) {
    final String value =
    status.trim().toLowerCase();

    return value == 'cancelled' ||
        value == 'canceled';
  }
}


class _EventDocument {
  final String collection;
  final Map<String, dynamic> data;

  const _EventDocument({
    required this.collection,
    required this.data,
  });
}
