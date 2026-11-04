import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String profileImage;
  final String status;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.profileImage,
    required this.status,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      
      userId: (map['UserId'] ?? map['userId'] ?? '').toString(),

      name: (map['Name'] ?? map['name'] ?? 'Unknown User').toString(),

      email: (map['Email'] ?? map['email'] ?? '').toString(),

      phone: (map['Phone'] ?? map['phone'] ?? '').toString(),

      role: (map['Role'] ?? map['role'] ?? 'Attendee').toString(),

      profileImage:
      (map['ProfileImage'] ?? map['profileImage'] ?? '').toString(),

      status: (map['Status'] ?? map['status'] ?? 'Active').toString(),

      createdAt: _parseDate(
        map['CreatedAt'] ?? map['createdAt'],
      ),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'UserId': userId,
      'Name': name,
      'Email': email,
      'Phone': phone,
      'Role': role,
      'ProfileImage': profileImage,
      'Status': status,
      'CreatedAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? profileImage,
    String? status,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      profileImage: profileImage ?? this.profileImage,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
