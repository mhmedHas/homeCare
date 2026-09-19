import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/booking_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/booking.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _walletNumber = '01119684470';
  static const _instaPayNumber = '01124031904';

  // WhatsApp number that receives payment receipts.
  // Change only this constant if the receiving number changes.
  static const _homeCareWhatsApp = '201124031904';

  Booking? _booking;
  AppUser? _client;
  AppUser? _nurse;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  String _method = 'wallet';

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
      final booking = await BookingService().getBooking(widget.bookingId);
      if (booking == null) throw StateError('الحجز غير موجود.');

      final users = await UserService().getUsersByIds([
        booking.clientId,
        booking.nurseId,
      ]);

      if (mounted) {
        setState(() {
          _booking = booking;
          _client = users[booking.clientId];
          _nurse = users[booking.nurseId];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'تعذر تحميل بيانات الدفع. حاول مرة أخرى.';
        });
      }
    }
  }

  Future<void> _copyNumber(String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الرقم')),
    );
  }

  Future<void> _openTransferApp() async {
    Uri uri;

    if (_method == 'instapay') {
      uri = Uri.parse(
        'intent://#Intent;package=com.egyptianbanks.instapay;end',
      );
    } else {
      uri = Uri.parse(
        'intent://#Intent;package=com.etisalat.flous;end',
      );
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return;
    } catch (_) {
      // Fall through to a safe fallback.
    }

    if (_method == 'wallet') {
      final opened = await launchUrl(
        Uri(scheme: 'tel', path: '*777*1#'),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('افتح تطبيق المحفظة يدويًا لإتمام التحويل.')),
        );
      }
    } else {
      final opened = await launchUrl(
        Uri.parse('https://www.instapay.eg/?lang=ar'),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('افتح تطبيق InstaPay يدويًا لإتمام التحويل.')),
        );
      }
    }
  }

  Future<void> _sendReceiptOnWhatsApp() async {
    final booking = _booking;
    final client = _client;
    final nurse = _nurse;

    if (booking == null || client == null || nurse == null || _sending) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بيانات العميل أو الممرض غير مكتملة.')),
        );
      }
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      if (booking.paymentStatus != 'awaiting_verification') {
        await BookingService().submitPaymentForVerification(
          bookingId: booking.id,
          paymentMethod: _method,
        );
      }

      final methodLabel = _method == 'wallet'
          ? 'محفظة إلكترونية'
          : 'InstaPay';

      final message = [
        'مرحبًا HomeCare،',
        '',
        'أرغب في تأكيد تحويل قيمة الحجز.',
        'رقم الطلب: ${booking.id}',
        'اسم الممرض: ${nurse.name}',
        'رقم الممرض: ${nurse.phone}',
        'اسم العميل: ${client.name}',
        'رقم العميل: ${client.phone}',
        'المبلغ: ${booking.totalAmount.toStringAsFixed(2)} جنيه',
        'طريقة الدفع: ${methodLabel}',
        '',
        'يرجى مراجعة التحويل.',
        'سأرسل صورة من إيصال التحويل في نفس المحادثة.',
      ].join('\n');

      final uri = Uri.https(
        'wa.me',
        '/$_homeCareWhatsApp',
        {'text': message},
      );

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) throw StateError('whatsapp');

      if (!mounted) return;
      setState(() {
        _booking = booking.copyWith(
          paymentStatus: 'awaiting_verification',
          paymentMethod: _method,
          paymentSubmittedAt: DateTime.now(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تجهيز رسالة WhatsApp. أرسل الرسالة ثم أرفق صورة الإيصال.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذر فتح WhatsApp أو إرسال بلاغ الدفع.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الدفع')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error ?? 'الحجز غير موجود', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _load,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final booking = _booking!;
    final awaiting = booking.paymentStatus == 'awaiting_verification';
    final verified = booking.paymentStatus == 'verified';
    final rejected = booking.paymentStatus == 'rejected';

    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الدفع'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildOrderCard(booking),
            const SizedBox(height: 14),
            if (verified)
              _statusCard(
                Icons.verified,
                AppColors.success,
                'تم تأكيد الدفع',
                'تم اعتماد التحويل من الإدارة.',
              )
            else ...[
              if (rejected)
                _statusCard(
                  Icons.error_outline,
                  AppColors.error,
                  'تم رفض إثبات الدفع',
                  'يمكنك تنفيذ التحويل مرة أخرى ثم إرسال الإيصال عبر WhatsApp.',
                ),
              if (awaiting)
                _statusCard(
                  Icons.hourglass_top,
                  Colors.orange,
                  'الدفع قيد المراجعة',
                  'تم إرسال بلاغ الدفع. انتظر مراجعة الإدارة.',
                ),
              const SizedBox(height: 10),
              const Text(
                'اختر طريقة التحويل',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _methodCard(
                id: 'wallet',
                title: 'محفظة إلكترونية',
                subtitle: _walletNumber,
                icon: Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 10),
              _methodCard(
                id: 'instapay',
                title: 'InstaPay',
                subtitle: _instaPayNumber,
                icon: Icons.account_balance_outlined,
              ),
              const SizedBox(height: 14),
              Card(
                color: AppColors.primaryLight,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'حوّل المبلغ كاملًا ثم التقط Screenshot للإيصال. لا تعتبر HomeCare الدفع ناجحًا إلا بعد مراجعته من الإدارة.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _openTransferApp,
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  _method == 'wallet'
                      ? 'فتح تطبيق المحفظة للتحويل'
                      : 'فتح InstaPay للتحويل',
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _sendReceiptOnWhatsApp,
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.chat),
                  label: Text(
                    awaiting
                        ? 'فتح WhatsApp وإرسال الإيصال'
                        : 'إرسال إثبات الدفع عبر WhatsApp',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Booking booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.receipt_long, size: 42, color: AppColors.primary),
            const SizedBox(height: 8),
            const Text(
              'تفاصيل الطلب',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _row('رقم الطلب', booking.id),
            _row('المبلغ المطلوب', '${booking.totalAmount.toStringAsFixed(2)} ج.م'),
            _row('عمولة HomeCare', '${booking.platformFee.toStringAsFixed(2)} ج.م'),
            _row(
              'صافي الممرض',
              '${booking.nurseEarnings.toStringAsFixed(2)} ج.م',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _method == id;

    return Card(
      elevation: selected ? 3 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _method = id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontSize: 18, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'نسخ الرقم',
                onPressed: () => _copyNumber(subtitle),
                icon: const Icon(Icons.copy_outlined),
              ),
              Radio<String>(
                value: id,
                groupValue: _method,
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard(
    IconData icon,
    Color color,
    String title,
    String message,
  ) {
    return Card(
      color: color.withValues(alpha: .08),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 46, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
