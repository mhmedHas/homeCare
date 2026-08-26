import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/booking_service.dart';
import '../../../services/auth_service.dart';
import '../../shared/models/booking.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'all'; // all, upcoming, past, cancelled

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'يرجى تسجيل الدخول';
        });
        return;
      }
      final bookings = await BookingService().getClientBookings(user.uid);
      setState(() {
        _bookings = bookings;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في تحميل الحجوزات';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Booking> get _filteredBookings {
    if (_filter == 'all') return _bookings;
    if (_filter == 'upcoming')
      return _bookings
          .where(
              (b) => b.status == 'confirmed' || b.status == 'pending_payment')
          .toList();
    if (_filter == 'past')
      return _bookings
          .where((b) => b.status == 'completed' || b.status == 'cancelled')
          .toList();
    if (_filter == 'cancelled')
      return _bookings.where((b) => b.status == 'cancelled').toList();
    return _bookings;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حجوزاتي'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الكل'),
              Tab(text: 'القادمة'),
              Tab(text: 'السابقة'),
              Tab(text: 'الملغاة'),
            ],
          ),
        ),
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
                            onPressed: _loadBookings,
                            child: const Text('إعادة المحاولة')),
                      ]))
                : _bookings.isEmpty
                    ? const Center(child: Text('لا توجد حجوزات'))
                    : TabBarView(
                        children: [
                          _buildList(_filteredBookings),
                          _buildList(_filteredBookings),
                          _buildList(_filteredBookings),
                          _buildList(_filteredBookings),
                        ],
                      ),
      ),
    );
  }

  Widget _buildList(List<Booking> list) {
    if (list.isEmpty) return const Center(child: Text('لا توجد حجوزات'));
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final booking = list[index];
        return Card(
          child: ListTile(
            title: Text('حجز #${booking.id.substring(0, 6)}'),
            subtitle: Text(
                '${DateFormat.yMMMd().format(booking.shiftStart)} | ${booking.totalAmount} ج.م'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(booking.status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(_getStatusLabel(booking.status),
                  style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
            onTap: () => context.go('/client/booking-details/${booking.id}'),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'انتظار دفع';
      case 'confirmed':
        return 'مؤكد';
      case 'in_progress':
        return 'جاري';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}
