import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationModel {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String email;
  final DateTime registrationDate;
  final String status;
  final String qrCode;
  final String paymentMethod;
  final String paymentStatus;
  final double amountPaid;

  RegistrationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.email,
    required this.registrationDate,
    required this.status,
    required this.qrCode,
    this.paymentMethod = 'free',
    this.paymentStatus = 'notRequired',
    this.amountPaid = 0,
  });

  
  factory RegistrationModel.fromMap(
      Map<String, dynamic> map,
      String documentId,
      ) {
    DateTime registrationDate = DateTime.now();

    final dateValue = map['registrationDate'];

    if (dateValue is Timestamp) {
      registrationDate = dateValue.toDate();
    } else if (dateValue is DateTime) {
      registrationDate = dateValue;
    } else if (dateValue is String) {
      registrationDate =
          DateTime.tryParse(dateValue) ?? DateTime.now();
    }

    return RegistrationModel(
      id: documentId,
      eventId: (map['eventId'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      userName: (map['userName'] ?? 'Attendee User').toString(),
      email: (map['email'] ?? '').toString(),
      registrationDate: registrationDate,
      status: (map['status'] ?? 'Pending').toString(),
      qrCode: (map['qrCode'] ?? '').toString(),
      paymentMethod: (map['paymentMethod'] ?? 'free').toString(),
      paymentStatus: (map['paymentStatus'] ?? 'notRequired').toString(),
      amountPaid: _parseAmount(map['amountPaid']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'email': email,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'status': status,
      'qrCode': qrCode,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'amountPaid': amountPaid,
    };
  }

  
  RegistrationModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? email,
    DateTime? registrationDate,
    String? status,
    String? qrCode,
    String? paymentMethod,
    String? paymentStatus,
    double? amountPaid,
  }) {
    return RegistrationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amountPaid: amountPaid ?? this.amountPaid,
    );
  }

  @override
  String toString() {
    return 'RegistrationModel('
        'id: $id, '
        'eventId: $eventId, '
        'userId: $userId, '
        'userName: $userName, '
        'email: $email, '
        'registrationDate: $registrationDate, '
        'status: $status, '
        'qrCode: $qrCode, '
        'paymentMethod: $paymentMethod, '
        'paymentStatus: $paymentStatus, '
        'amountPaid: $amountPaid'
        ')';
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
