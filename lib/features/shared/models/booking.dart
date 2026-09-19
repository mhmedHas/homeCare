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
  final double nurseEarnings;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? paymentReference;
  final DateTime? paymentSubmittedAt;
  final DateTime? paymentVerifiedAt;
  final String? paymentVerifiedBy;
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
    double? nurseEarnings,
    this.status = 'pending_payment',
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.paymentReference,
    this.paymentSubmittedAt,
    this.paymentVerifiedAt,
    this.paymentVerifiedBy,
    required this.createdAt,
    required this.updatedAt,
  }) : nurseEarnings = nurseEarnings ?? (totalAmount - platformFee);

  static DateTime _date(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
    }
    return fallback ?? DateTime.now();
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
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

    final totalAmount = _double(data['totalAmount']);
    final platformFee = _double(data['platformFee']);

    return Booking(
      id: doc.id,
      clientId: data['clientId']?.toString() ?? '',
      nurseId: data['nurseId']?.toString() ?? '',
      careRequestId: data['careRequestId']?.toString() ?? '',
      shiftStart: _date(data['shiftStart']),
      shiftEnd: _date(data['shiftEnd']),
      shiftHours: _int(data['shiftHours']),
      pricePerHour: _double(data['pricePerHour']),
      platformFee: platformFee,
      totalAmount: totalAmount,
      nurseEarnings: data['nurseEarnings'] == null
          ? totalAmount - platformFee
          : _double(data['nurseEarnings']),
      status: data['status']?.toString() ?? 'pending_payment',
      paymentStatus: data['paymentStatus']?.toString() ?? 'unpaid',
      paymentMethod: data['paymentMethod']?.toString(),
      paymentReference: data['paymentReference']?.toString(),
      paymentSubmittedAt: _nullableDate(data['paymentSubmittedAt']),
      paymentVerifiedAt: _nullableDate(data['paymentVerifiedAt']),
      paymentVerifiedBy: data['paymentVerifiedBy']?.toString(),
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
        'nurseEarnings': nurseEarnings,
        'status': status,
        'paymentStatus': paymentStatus,
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
        'paymentSubmittedAt': paymentSubmittedAt == null
            ? null
            : Timestamp.fromDate(paymentSubmittedAt!),
        'paymentVerifiedAt': paymentVerifiedAt == null
            ? null
            : Timestamp.fromDate(paymentVerifiedAt!),
        'paymentVerifiedBy': paymentVerifiedBy,
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
    double? nurseEarnings,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentReference,
    DateTime? paymentSubmittedAt,
    DateTime? paymentVerifiedAt,
    String? paymentVerifiedBy,
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
      nurseEarnings: nurseEarnings ?? this.nurseEarnings,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentSubmittedAt: paymentSubmittedAt ?? this.paymentSubmittedAt,
      paymentVerifiedAt: paymentVerifiedAt ?? this.paymentVerifiedAt,
      paymentVerifiedBy: paymentVerifiedBy ?? this.paymentVerifiedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
