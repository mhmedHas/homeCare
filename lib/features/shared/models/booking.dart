import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String clientId;
  final String nurseId;
  final String careRequestId;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final int shiftHours;
  final double pricePerHour;
  final double platformFee;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.clientId,
    required this.nurseId,
    required this.careRequestId,
    required this.shiftStart,
    required this.shiftEnd,
    required this.shiftHours,
    required this.pricePerHour,
    required this.platformFee,
    required this.totalAmount,
    this.status = 'pending_payment',
    this.paymentStatus = 'unpaid',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      nurseId: data['nurseId'] ?? '',
      careRequestId: data['careRequestId'] ?? '',
      shiftStart: (data['shiftStart'] as Timestamp).toDate(),
      shiftEnd: (data['shiftEnd'] as Timestamp).toDate(),
      shiftHours: data['shiftHours'] ?? 0,
      pricePerHour: (data['pricePerHour'] ?? 0).toDouble(),
      platformFee: (data['platformFee'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending_payment',
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        'nurseId': nurseId,
        'careRequestId': careRequestId,
        'shiftStart': Timestamp.fromDate(shiftStart),
        'shiftEnd': Timestamp.fromDate(shiftEnd),
        'shiftHours': shiftHours,
        'pricePerHour': pricePerHour,
        'platformFee': platformFee,
        'totalAmount': totalAmount,
        'status': status,
        'paymentStatus': paymentStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  // ✅ دالة copyWith كاملة
  Booking copyWith({
    String? id,
    String? clientId,
    String? nurseId,
    String? careRequestId,
    DateTime? shiftStart,
    DateTime? shiftEnd,
    int? shiftHours,
    double? pricePerHour,
    double? platformFee,
    double? totalAmount,
    String? status,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      nurseId: nurseId ?? this.nurseId,
      careRequestId: careRequestId ?? this.careRequestId,
      shiftStart: shiftStart ?? this.shiftStart,
      shiftEnd: shiftEnd ?? this.shiftEnd,
      shiftHours: shiftHours ?? this.shiftHours,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      platformFee: platformFee ?? this.platformFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
