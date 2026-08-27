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

  static DateTime _date(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
    return fallback ?? DateTime.now();
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final now = DateTime.now();
    return Booking(
      id: doc.id,
      clientId: data['clientId']?.toString() ?? '',
      nurseId: data['nurseId']?.toString() ?? '',
      careRequestId: data['careRequestId']?.toString() ?? '',
      shiftStart: _date(data['shiftStart']),
      shiftEnd: _date(data['shiftEnd']),
      shiftHours: _int(data['shiftHours']),
      pricePerHour: _double(data['pricePerHour']),
      platformFee: _double(data['platformFee']),
      totalAmount: _double(data['totalAmount']),
      status: data['status']?.toString() ?? 'pending_payment',
      paymentStatus: data['paymentStatus']?.toString() ?? 'unpaid',
      createdAt: _date(data['createdAt'], fallback: now),
      updatedAt: _date(data['updatedAt'], fallback: now),
    );
  }

  Map<String, dynamic> toMap() => {
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
