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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: data['uid'] ?? '',
      role: data['role'] ?? 'client',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      photoUrl: data['photoUrl'],
      isActive: data['isActive'] ?? true,
      isVerified: data['isVerified'] ?? false,
      profileCompleted: data['profileCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
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
