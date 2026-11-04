import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String? userId;
  final String? eventId;
  final String title;
  final String message;
  final String? type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.userId,
    this.eventId,
    required this.title,
    required this.message,
    this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate = DateTime.now();
    final dynamic value = map['createdAt'];

    if (value is Timestamp) {
      parsedDate = value.toDate();
    } else if (value is DateTime) {
      parsedDate = value;
    } else if (value is String) {
      parsedDate = DateTime.tryParse(value) ?? DateTime.now();
    }

    return NotificationModel(
      id: id,
      userId: map['userId']?.toString(),
      eventId: map['eventId']?.toString(),
      title: (map['title'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      type: map['type']?.toString(),
      isRead: map['isRead'] ?? false,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
