import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CareRequest {
  final String id;
  final String clientId;
  final String patientName;
  final int patientAge;
  final String patientGender; // male, female
  final String careType; // elderly, post_surgery, chronic, etc.
  final List<String> services; // e.g., ['medication', 'blood_pressure']
  final int shiftHours;
  final int daysCount;
  final DateTime startDate;
  final TimeOfDay startTime;
  final String governorate;
  final String area;
  final String address;
  final String? notes;
  final String status; // open, matching, booked, in_progress, completed, cancelled
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

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        'patientName': patientName,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'careType': careType,
        'services': services,
        'shiftHours': shiftHours,
        'daysCount': daysCount,
        'startDate': Timestamp.fromDate(startDate),
        'startTime': '${startTime.hour}:${startTime.minute}',
        'governorate': governorate,
        'area': area,
        'address': address,
        'notes': notes,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory CareRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timeParts = (data['startTime'] as String?)?.split(':') ?? ['0', '0'];
    return CareRequest(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      patientName: data['patientName'] ?? '',
      patientAge: data['patientAge'] ?? 0,
      patientGender: data['patientGender'] ?? 'male',
      careType: data['careType'] ?? '',
      services: List<String>.from(data['services'] ?? []),
      shiftHours: data['shiftHours'] ?? 8,
      daysCount: data['daysCount'] ?? 1,
      startDate: (data['startDate'] as Timestamp).toDate(),
      startTime: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      governorate: data['governorate'] ?? '',
      area: data['area'] ?? '',
      address: data['address'] ?? '',
      notes: data['notes'],
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}