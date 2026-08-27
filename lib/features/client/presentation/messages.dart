import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';

class ClientMessagesScreen extends StatefulWidget {
  const ClientMessagesScreen({super.key});

  @override
  State<ClientMessagesScreen> createState() => _ClientMessagesScreenState();
}

class _ClientMessagesScreenState extends State<ClientMessagesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (mounted) setState(() => _errorMessage = 'يرجى تسجيل الدخول');
        return;
      }

      // One bounded query only. We intentionally avoid an always-on listener
      // for the inbox to keep Firestore usage low on the Spark plan.
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('clientId', isEqualTo: user.uid)
          .limit(30)
          .get();

      final chats = [...snapshot.docs]
        ..sort((a, b) {
          final aTime = a.data()['updatedAt'];
          final bTime = b.data()['updatedAt'];
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });

      if (mounted) {
        setState(() => _chats = chats);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'تعذر تحميل الرسائل');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('الرسائل'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loadChats,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadChats,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chats.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadChats,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.chat_bubble_outline, size: 64),
            SizedBox(height: 16),
            Center(
              child: Text(
                'لا توجد محادثات حتى الآن',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text('بعد إنشاء حجز، هتقدر تتواصل مع مقدم الرعاية.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final data = _chats[index].data();
          final bookingId = data['bookingId'] as String?;
          final lastMessage = data['lastMessage'] as String?;
          final updatedAt = data['updatedAt'];
          final dateText = updatedAt is Timestamp
              ? _formatDate(updatedAt.toDate())
              : '';

          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(
                child: Icon(Icons.person_outline),
              ),
              title: Text(
                bookingId == null ? 'محادثة' : 'محادثة الحجز #${_shortId(bookingId)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                lastMessage?.trim().isNotEmpty == true
                    ? lastMessage!
                    : 'ابدأ المحادثة',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: dateText.isEmpty
                  ? const Icon(Icons.chevron_left)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dateText, style: const TextStyle(fontSize: 11)),
                        const Icon(Icons.chevron_left, size: 18),
                      ],
                    ),
              onTap: bookingId == null
                  ? null
                  : () => context.push('/client/chat/$bookingId'),
            ),
          );
        },
      ),
    );
  }

  String _shortId(String id) => id.length <= 6 ? id : id.substring(0, 6);

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.year == date.year && now.month == date.month && now.day == date.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
}
