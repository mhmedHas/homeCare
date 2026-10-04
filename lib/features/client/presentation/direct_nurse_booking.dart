import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';

class DirectNurseBookingScreen extends StatefulWidget {
  final String nurseId;

  const DirectNurseBookingScreen({
    super.key,
    required this.nurseId,
  });

  @override
  State<DirectNurseBookingScreen> createState() =>
      _DirectNurseBookingScreenState();
}

class _DirectNurseBookingScreenState extends State<DirectNurseBookingScreen> {
  AppUser? _nurse;
  double _shiftPrice = 0;
  int _shiftHours = 12;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _loading = true;
  bool _booking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        UserService().getUser(widget.nurseId),
        FirebaseFirestore.instance
            .collection('nurseProfiles')
            .doc(widget.nurseId)
            .get(),
      ]);

      final nurse = results[0] as AppUser?;
      final profile = (results[1]
              as DocumentSnapshot<Map<String, dynamic>>)
          .data() ??
          <String, dynamic>{};

      final price = (profile['expectedPrice'] as num?)?.toDouble() ?? 0;
      final hours = (profile['shiftHours'] as num?)?.toInt() ?? 12;

      if (nurse == null ||
          nurse.role != 'nurse' ||
          !nurse.isActive ||
          !nurse.isVerified ||
          price <= 0) {
        throw StateError('الممرض غير متاح للحجز المباشر');
      }

      if (!mounted) return;
      setState(() {
        _nurse = nurse;
        _shiftPrice = price;
        _shiftHours = [6, 12, 24].contains(hours) ? hours : 12;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is StateError ? e.message : 'تعذر تحميل بيانات الممرض';
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null && mounted) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _submit() async {
    final user = AuthService().currentUser;
    if (user == null) {
      setState(() => _error = 'يرجى تسجيل الدخول أولاً');
      return;
    }

    final shiftStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (shiftStart.isBefore(DateTime.now())) {
      setState(() => _error = 'اختار موعدًا قادمًا');
      return;
    }

    setState(() {
      _booking = true;
      _error = null;
    });

    try {
      final bookingId = await BookingService().createDirectBooking(
        clientId: user.uid,
        nurseId: widget.nurseId,
        shiftStart: shiftStart,
      );

      if (mounted) {
        context.go('/client/booking-confirmation/' + bookingId);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is StateError
          ? e.message
          : 'تعذر إنشاء الحجز. حاول مرة أخرى.';
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nurse = _nurse;

    return Scaffold(
      appBar: AppBar(title: const Text('حجز الممرض')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && nurse == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    if (nurse != null) _buildNurseCard(nurse),
                    const SizedBox(height: 14),
                    _buildPriceCard(),
                    const SizedBox(height: 14),
                    _buildScheduleCard(),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _booking ? null : _submit,
                        icon: _booking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _booking ? 'جاري تأكيد الحجز...' : 'تأكيد حجز الممرض',
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNurseCard(AppUser nurse) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: nurse.photoUrl?.isNotEmpty == true
                    ? NetworkImage(nurse.photoUrl!)
                    : null,
                child: nurse.photoUrl?.isNotEmpty == true
                    ? null
                    : const Icon(Icons.person_outline, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nurse.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Row(
                      children: [
                        Icon(Icons.verified, size: 16, color: AppColors.success),
                        SizedBox(width: 4),
                        Text('ممرض موثق من شفاء'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPriceCard() => Card(
        color: AppColors.primaryLight,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'سعر الشيفت ثابت',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _shiftPrice.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text('ج.م'),
                  ),
                  const Spacer(),
                  Text(
                    '$_shiftHours ساعة',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'السعر المحدد في بروفايل الممرض، ولا يتم تغييره أثناء الحجز.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );

  Widget _buildScheduleCard() => Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('تاريخ الشيفت'),
              subtitle: Text(DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate)),
              onTap: _booking ? null : _pickDate,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.access_time_outlined),
              title: const Text('وقت البداية'),
              subtitle: Text(DateFormat.jm('ar').format(DateTime(2026, 1, 1, _selectedTime.hour, _selectedTime.minute))),
              onTap: _booking ? null : _pickTime,
            ),
          ],
        ),
      );
}