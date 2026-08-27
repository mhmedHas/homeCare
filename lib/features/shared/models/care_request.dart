import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CareRequest {
  static const List<int> allowedShiftHours = [6, 12, 24];

  final String id;
  final String clientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String careType;
  final List<String> services;
  final int shiftHours;
  final int daysCount;
  final DateTime startDate;
  final TimeOfDay startTime;
  final String governorate;
  final String area;
  final String address;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  CareRequest({
    required this.id,
    required this.clientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.careType,
    required this.services,
    required this.shiftHours,
    required this.daysCount,
    required this.startDate,
    required this.startTime,
    required this.governorate,
    required this.area,
    required this.address,
    this.notes,
    this.status = 'open',
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _date(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
    return fallback ?? DateTime.now();
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static TimeOfDay _time(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return TimeOfDay(hour: date.hour, minute: date.minute);
    }
    if (value is String) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  factory CareRequest.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final now = DateTime.now();
    final rawServices = data['services'];
    final services = rawServices is List
        ? rawServices.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    final rawShift = _int(data['shiftHours'], fallback: 12);
    final shiftHours = allowedShiftHours.contains(rawShift) ? rawShift : 12;

    return CareRequest(
      id: doc.id,
      clientId: data['clientId']?.toString() ?? '',
      patientName: data['patientName']?.toString() ?? '',
      patientAge: _int(data['patientAge']),
      patientGender: data['patientGender']?.toString() ?? 'male',
      careType: data['careType']?.toString() ?? '',
      services: services,
      shiftHours: shiftHours,
      daysCount: _int(data['daysCount'], fallback: 1).clamp(1, 30),
      startDate: _date(data['startDate'], fallback: now),
      startTime: _time(data['startTime']),
      governorate: data['governorate']?.toString() ?? '',
      area: data['area']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      notes: data['notes']?.toString(),
      status: data['status']?.toString() ?? 'open',
      createdAt: _date(data['createdAt'], fallback: now),
      updatedAt: _date(data['updatedAt'], fallback: now),
    );
  }

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'patientName': patientName,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'careType': careType,
        'services': services,
        'shiftHours': allowedShiftHours.contains(shiftHours) ? shiftHours : 12,
        'daysCount': daysCount.clamp(1, 30),
        'startDate': Timestamp.fromDate(startDate),
        'startTime': '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
        'governorate': governorate,
        'area': area,
        'address': address,
        'notes': notes,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
