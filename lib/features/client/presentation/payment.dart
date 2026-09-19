import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/booking_service.dart';
import '../../shared/models/booking.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Booking? _booking;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String _selectedMethod = 'card';
  final _referenceController = TextEditingController();

  final List<PaymentMethod> _methods = const [
    PaymentMethod(id: 'card', label: 'بطاقة بنكية / دفع إلكتروني', icon: Icons.credit_card),
    PaymentMethod(id: 'wallet', label: 'محفظة إلكترونية', icon: Icons.account_balance_wallet_outlined),
    PaymentMethod(id: 'fawry', label: 'فوري', icon: Icons.qr_code_2),
  ];

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final booking = await BookingService().getBooking(widget.bookingId);
      if (booking == null) {
        if (mounted) setState(() => _errorMessage = 'الحجز غير موجود');
        return;
      }
      if (mounted) setState(() => _booking = booking);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'حدث خطأ أثناء تحميل بيانات الدفع');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPayment() async {
    final booking = _booking;
    if (booking == null || _isProcessing) return;
    if (booking.paymentStatus == 'awaiting_verification') return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final reference = _referenceController.text.trim();
      await BookingService().submitPaymentForVerification(
        bookingId: booking.id,
        paymentMethod: _selectedMethod,
        paymentReference: reference.isEmpty ? null : reference,
      );

      if (!mounted) return;
      setState(() {
        _booking = booking.copyWith(
          paymentStatus: 'awaiting_verification',
          paymentMethod: _selectedMethod,
          paymentReference: reference.isEmpty ? null : reference,
          paymentSubmittedAt: DateTime.now(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال بلاغ الدفع للمراجعة. لن يتم تأكيد الحجز قبل التحقق.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'تعذر إرسال الدفع للمراجعة. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;

    return Scaffold(
      appBar: AppBar(title: const Text('دفع الحجز')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && booking == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_errorMessage!, textAlign: TextAlign.center),
                  ),
                )
              : booking == null
                  ? const Center(child: Text('الحجز غير موجود'))
                  : _buildContent(booking),
    );
  }

  Widget _buildContent(Booking booking) {
    final awaiting = booking.paymentStatus == 'awaiting_verification';
    final verified = booking.paymentStatus == 'verified';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow('قيمة الخدمة', '${booking.totalAmount.toStringAsFixed(2)} ج.م'),
                _buildSummaryRow('عمولة HomeCare (15%)', '${booking.platformFee.toStringAsFixed(2)} ج.م'),
                const Divider(),
                _buildSummaryRow('صافي الممرض', '${booking.nurseEarnings.toStringAsFixed(2)} ج.م', isTotal: true),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'العمولة تُخصم من قيمة الخدمة بعد نجاح الدفع، وليست مبلغًا إضافيًا على العميل.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (verified)
          _statusCard(
            icon: Icons.verified,
            color: AppColors.success,
            title: 'تم التحقق من الدفع',
            message: 'تم تأكيد الدفع. بعد استكمال الشيفت يظهر صافي الممرض في الأرباح.',
          )
        else if (awaiting)
          _statusCard(
            icon: Icons.hourglass_top,
            color: Colors.orange,
            title: 'الدفع قيد المراجعة',
            message: 'تم استلام بلاغ الدفع. لن يتحول الحجز إلى مؤكد ولن تُحتسب أرباح للممرض قبل مراجعة الدفع.',
          )
        else ...[
          const Text('طريقة الدفع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._methods.map(
            (method) => RadioListTile<String>(
              title: Row(
                children: [
                  Icon(method.icon, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(method.label)),
                ],
              ),
              value: method.id,
              groupValue: _selectedMethod,
              onChanged: (value) {
                if (value != null) setState(() => _selectedMethod = value);
              },
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: 'رقم العملية / المرجع (اختياري)',
              hintText: 'اكتبه بعد تنفيذ الدفع',
              prefixIcon: Icon(Icons.receipt_long_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'مهم: زر الإرسال لا يعتبر الدفع ناجحًا. هو فقط يرسل بلاغ الدفع للمراجعة. تأكيد الدفع يجب أن يتم من بوابة الدفع أو من لوحة الإدارة.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _submitPayment,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('أرسلت الدفع - إرسال للمراجعة'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Card(
      color: color.withValues(alpha: .08),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 46, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethod {
  final String id;
  final String label;
  final IconData icon;

  const PaymentMethod({
    required this.id,
    required this.label,
    required this.icon,
  });
}
