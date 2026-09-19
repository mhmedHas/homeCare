import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/admin_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/booking.dart';

class AdminPaymentDashboard extends StatefulWidget {
  const AdminPaymentDashboard({super.key});

  @override
  State<AdminPaymentDashboard> createState() => _AdminPaymentDashboardState();
}

class _AdminPaymentDashboardState extends State<AdminPaymentDashboard> {
  final _adminService = AdminService();
  final _userService = UserService();

  List<Booking> _bookings = [];
  Map<String, AppUser> _users = {};
  bool _loading = true;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final isAdmin = await _adminService.isAdmin();
      if (!isAdmin) throw StateError('هذا الحساب ليس حساب إدارة.');

      final bookings = await _adminService.getPendingPayments();
      final ids = <String>{};
      for (final booking in bookings) {
        ids.add(booking.clientId);
        ids.add(booking.nurseId);
      }

      final users = await _userService.getUsersByIds(ids);

      if (mounted) {
        setState(() {
          _bookings = bookings;
          _users = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is StateError ? e.message : 'تعذر تحميل المدفوعات المعلقة.';
        });
      }
    }
  }

  Future<void> _verify(Booking booking) async {
    final nurse = _users[booking.nurseId];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الدفع'),
        content: Text(
          'هل تم التأكد من الإيصال الخاص بالطلب ${booking.id}؟\n\n'
          'المبلغ: ${booking.totalAmount.toStringAsFixed(2)} ج.م\n'
          'سيتم إضافة ${booking.nurseEarnings.toStringAsFixed(2)} ج.م إلى رصيد ${nurse?.name ?? 'الممرض'} مرة واحدة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تأكيد الدفع'),
          ),
        ],
      ),
    );

    if (confirmed != true || _working) return;

    setState(() => _working = true);
    try {
      final changed = await _adminService.verifyPayment(booking.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            changed
                ? 'تم تأكيد الدفع وإضافة صافي الممرض إلى الرصيد.'
                : 'الدفع كان مؤكدًا بالفعل ولم تتم إضافة الرصيد مرة أخرى.',
          ),
        ),
      );

      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _reject(Booking booking) async {
    final controller = TextEditingController();

    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رفض إثبات الدفع'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'سبب الرفض (اختياري)',
            hintText: 'مثال: المبلغ أو رقم المستفيد غير مطابق',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('رفض'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (reason == null || _working) return;

    setState(() => _working = true);
    try {
      await _adminService.rejectPayment(
        bookingId: booking.id,
        reason: reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض إثبات الدفع بدون إضافة أي رصيد.')),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدفوعات HomeCare'),
        actions: [
          IconButton(
            onPressed: _working ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.admin_panel_settings_outlined, size: 56),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : _bookings.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mark_email_read_outlined, size: 64),
                          SizedBox(height: 12),
                          Text(
                            'لا توجد مدفوعات في انتظار المراجعة.',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          final client = _users[booking.clientId];
                          final nurse = _users[booking.nurseId];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.pending_actions, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'طلب ${booking.id}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${booking.totalAmount.toStringAsFixed(0)} ج.م',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 22),
                                  _info('العميل', client?.name ?? booking.clientId),
                                  _info('رقم العميل', client?.phone ?? '—'),
                                  _info('الممرض', nurse?.name ?? booking.nurseId),
                                  _info('رقم الممرض', nurse?.phone ?? '—'),
                                  _info(
                                    'طريقة الدفع',
                                    booking.paymentMethod == 'wallet'
                                        ? 'محفظة إلكترونية'
                                        : 'InstaPay',
                                  ),
                                  _info(
                                    'صافي الممرض',
                                    '${booking.nurseEarnings.toStringAsFixed(2)} ج.م',
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _working ? null : () => _reject(booking),
                                          icon: const Icon(Icons.close),
                                          label: const Text('رفض'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: _working ? null : () => _verify(booking),
                                          icon: const Icon(Icons.check),
                                          label: const Text('تأكيد الدفع'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
