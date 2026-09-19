import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String role; // 'client' or 'nurse'
  final String name;
  final String phone;
  final String? email;
  final String? photoUrl;
  final bool isActive;
  final bool isVerified;
  final bool profileCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.phone,
    this.email,
    this.photoUrl,
    this.isActive = true,
    this.isVerified = false,
    this.profileCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'name': name,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'isVerified': isVerified,
      'profileCompleted': profileCompleted,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};

    return AppUser(
      uid: data['uid']?.toString() ?? doc.id,
      role: data['role']?.toString() ?? 'client',
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
      isVerified: data['isVerified'] is bool ? data['isVerified'] as bool : false,
      profileCompleted:
          data['profileCompleted'] is bool ? data['profileCompleted'] as bool : false,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    bool? profileCompleted,
  }) {
    return AppUser(
      uid: uid,
      role: role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive,
      isVerified: isVerified,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
