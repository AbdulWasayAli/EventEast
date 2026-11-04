import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final double price;
  final String organizer;
  final String organizerId;
  final String imageUrl;
  final String location;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String rules;
  final String contactInfo;
  final int maxParticipants;
  final int availableSeats;
  final String status;


  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool isRegistered;
  bool isFavorite;
  bool get isPaid => price > 0;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.organizer,
    required this.organizerId,
    required this.imageUrl,
    required this.location,
    required this.date,
    this.startTime = '',
    this.endTime = '',
    this.rules = '',
    this.contactInfo = '',
    this.maxParticipants = 0,
    this.availableSeats = 0,
    this.status = 'Pending',
    this.latitude,
    this.longitude,
    this.isRegistered = false,
    this.isFavorite = false,
  });

  factory EventModel.fromMap(
      Map<String, dynamic> map,
      String documentId,
      ) {
    return EventModel(
      id: documentId,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      price: _parsePrice(map['price']),
      organizer: map['organizer']?.toString() ?? '',
      organizerId: map['organizerId']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      date: _parseDate(map['date']),
      startTime: map['startTime']?.toString() ?? '',
      endTime: map['endTime']?.toString() ?? '',
      rules: map['rules']?.toString() ?? '',
      contactInfo: map['contactInfo']?.toString() ?? '',
      maxParticipants: _parseInt(map['maxParticipants']),
      availableSeats: _parseInt(map['availableSeats']),
      status: map['status']?.toString() ?? 'Pending',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),

    );
  }
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'organizer': organizer,
      'organizerId': organizerId,
      'imageUrl': imageUrl,
      'location': location,
      'startTime': startTime,
      'endTime': endTime,
      'rules': rules,
      'contactInfo': contactInfo,
      'maxParticipants': maxParticipants,
      'availableSeats': availableSeats,
      'status': status,
      'date': Timestamp.fromDate(date),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? price,
    String? organizer,
    String? organizerId,
    String? imageUrl,
    String? location,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? rules,
    String? contactInfo,
    int? maxParticipants,
    int? availableSeats,
    String? status,
    double? latitude,
    double? longitude,
    bool? isRegistered,
    bool? isFavorite,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      organizer: organizer ?? this.organizer,
      organizerId: organizerId ?? this.organizerId,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      rules: rules ?? this.rules,
      contactInfo: contactInfo ?? this.contactInfo,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      availableSeats: availableSeats ?? this.availableSeats,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isRegistered: isRegistered ?? this.isRegistered,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
