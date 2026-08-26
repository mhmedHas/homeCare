import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/booking_service.dart';
import '../../shared/models/booking.dart';

class CurrentShiftScreen extends StatefulWidget {
  const CurrentShiftScreen({super.key});

  @override
  State<CurrentShiftScreen> createState() => _CurrentShiftScreenState();
}

class _CurrentShiftScreenState extends State<CurrentShiftScreen> {
  Booking? _booking;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentShift();
  }

  Future<void> _loadCurrentShift() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول';
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('nurseId', isEqualTo: user.uid)
          .where('status', whereIn: ['confirmed', 'in_progress'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _booking = Booking.fromFirestore(snapshot.docs.first);
          _isCheckedIn = _booking!.status == 'in_progress';
          _isCheckedOut = _booking!.status == 'completed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIn() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      await BookingService().checkInShift(_booking!.id);
      setState(() {
        _isCheckedIn = true;
        _booking = _booking!.copyWith(status: 'in_progress');
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم تسجيل الحضور')));
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تسجيل الحضور';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _checkOut() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      await BookingService().checkOutShift(_booking!.id);
      setState(() {
        _isCheckedOut = true;
        _booking = _booking!.copyWith(status: 'completed');
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم تسجيل الانصراف')));
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تسجيل الانصراف';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الشيفت الحالي')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Text(_errorMessage!,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadCurrentShift,
                          child: const Text('إعادة المحاولة')),
                    ]))
              : _booking == null
                  ? const Center(child: Text('لا يوجد شيفت حالياً'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _booking!.status == 'in_progress'
                                  ? Colors.green
                                  : _booking!.status == 'confirmed'
                                      ? Colors.blue
                                      : Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _booking!.status == 'in_progress'
                                  ? 'جاري'
                                  : 'قادم',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                              'رقم الحجز', _booking!.id.substring(0, 8)),
                          _buildInfoRow('التاريخ',
                              DateFormat.yMMMd().format(_booking!.shiftStart)),
                          _buildInfoRow('البداية',
                              DateFormat.jm().format(_booking!.shiftStart)),
                          _buildInfoRow('النهاية',
                              DateFormat.jm().format(_booking!.shiftEnd)),
                          _buildInfoRow(
                              'المدة', '${_booking!.shiftHours} ساعة'),
                          _buildInfoRow(
                              'السعر', '${_booking!.totalAmount} ج.م'),
                          const Spacer(),
                          if (_isCheckedOut)
                            const Center(
                                child: Text('تم الانتهاء من الشيفت',
                                    style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 18))),
                          if (!_isCheckedOut && _booking!.status == 'confirmed')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isProcessing ? null : _checkIn,
                                child: _isProcessing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Text('تسجيل الحضور (Check-in)'),
                              ),
                            ),
                          if (_isCheckedIn && !_isCheckedOut)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isProcessing ? null : _checkOut,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange),
                                child: _isProcessing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Text('تسجيل الانصراف (Check-out)'),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
