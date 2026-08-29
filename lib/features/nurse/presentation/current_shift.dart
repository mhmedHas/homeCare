import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/booking_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/booking.dart';
import '../../shared/models/app_user.dart';

class CurrentShiftScreen extends StatefulWidget {
  /// When provided, shows this specific booking. Otherwise falls back to the
  /// nurse's most recent active (confirmed/in_progress) booking.
  final String? bookingId;
  const CurrentShiftScreen({super.key, this.bookingId});

  @override
  State<CurrentShiftScreen> createState() => _CurrentShiftScreenState();
}

class _CurrentShiftScreenState extends State<CurrentShiftScreen> {
  Booking? _booking;
  AppUser? _client;
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

      Booking? booking;
      final requestedId = widget.bookingId;
      if (requestedId != null && requestedId.isNotEmpty) {
        booking = await BookingService().getBooking(requestedId);
      } else {
        final snapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('nurseId', isEqualTo: user.uid)
            .where('status', whereIn: ['confirmed', 'in_progress'])
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          booking = Booking.fromFirestore(snapshot.docs.first);
        }
      }

      if (booking != null) {
        final client = await UserService().getUser(booking.clientId);
        if (!mounted) return;
        setState(() {
          _booking = booking;
          _client = client;
          _isCheckedIn = booking!.status == 'in_progress';
          _isCheckedOut = booking.status == 'completed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء تحميل الشيفت';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkIn() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      await BookingService().checkInShift(_booking!.id);
      if (!mounted) return;
      setState(() {
        _isCheckedIn = true;
        _booking = _booking!.copyWith(status: 'in_progress');
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم تسجيل الحضور')));
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في تسجيل الحضور';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _checkOut() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      await BookingService().checkOutShift(_booking!.id);
      if (!mounted) return;
      setState(() {
        _isCheckedOut = true;
        _booking = _booking!.copyWith(status: 'completed');
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم تسجيل الانصراف')));
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في تسجيل الانصراف';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  : RefreshIndicator(
                      onRefresh: _loadCurrentShift,
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          // Client card
                          Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.primaryLight,
                                    backgroundImage: (_client?.photoUrl?.isNotEmpty ?? false)
                                        ? NetworkImage(_client!.photoUrl!)
                                        : null,
                                    child: (_client?.photoUrl?.isNotEmpty ?? false)
                                        ? null
                                        : Icon(Icons.person_outline, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _client?.name.trim().isNotEmpty == true
                                              ? _client!.name.trim()
                                              : 'العميل',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                        ),
                                        if (_client?.phone.isNotEmpty ?? false)
                                          Text(_client!.phone, style: const TextStyle(color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'مراسلة العميل',
                                    onPressed: () => context.push('/nurse/chat/${_booking!.id}'),
                                    icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                          Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildInfoRow('رقم الحجز', _booking!.id.substring(0, 8)),
                                  _buildInfoRow('التاريخ', DateFormat.yMMMd().format(_booking!.shiftStart)),
                                  _buildInfoRow('البداية', DateFormat.jm().format(_booking!.shiftStart)),
                                  _buildInfoRow('النهاية', DateFormat.jm().format(_booking!.shiftEnd)),
                                  _buildInfoRow('المدة', '${_booking!.shiftHours} ساعة'),
                                  _buildInfoRow('السعر', '${_booking!.totalAmount} ج.م'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
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
