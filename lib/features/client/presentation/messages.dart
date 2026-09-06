import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/user_service.dart';
import '../../shared/models/app_user.dart';

/// Client inbox. Loads conversations page by page (never the whole inbox
/// at once) so the screen stays fast even for a client with a very long
/// history of bookings/chats, and shows a cached unread badge per chat
/// instead of counting messages.
class ClientMessagesScreen extends StatefulWidget {
  const ClientMessagesScreen({super.key});

  @override
  State<ClientMessagesScreen> createState() => _ClientMessagesScreenState();
}

class _ClientMessagesScreenState extends State<ClientMessagesScreen> {
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String _searchQuery = '';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _chats = [];
  Map<String, AppUser> _nurses = {};
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = AuthService().currentUser;
      if (user == null) {
        if (mounted) setState(() => _errorMessage = 'يرجى تسجيل الدخول');
        return;
      }

      final snapshot = await _chatService.getChatsPage(
        fieldName: 'clientId',
        userId: user.uid,
      );

      final nurseIds = snapshot.docs
          .map((d) => d.data()['nurseId']?.toString() ?? '')
          .where((id) => id.isNotEmpty);
      final nurses = await UserService().getUsersByIds(nurseIds);

      if (mounted) {
        setState(() {
          _chats = snapshot.docs;
          _nurses = nurses;
          _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMore = snapshot.docs.length >= kChatListPageSize;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'تعذر تحميل الرسائل');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final user = AuthService().currentUser;
      if (user == null) return;

      final snapshot = await _chatService.getChatsPage(
        fieldName: 'clientId',
        userId: user.uid,
        startAfter: _lastDoc,
      );

      final newNurseIds = snapshot.docs
          .map((d) => d.data()['nurseId']?.toString() ?? '')
          .where((id) => id.isNotEmpty && !_nurses.containsKey(id));
      final newNurses = await UserService().getUsersByIds(newNurseIds);

      if (mounted) {
        setState(() {
          _chats = [..._chats, ...snapshot.docs];
          _nurses = {..._nurses, ...newNurses};
          _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDoc;
          _hasMore = snapshot.docs.length >= kChatListPageSize;
        });
      }
    } catch (_) {
      // Silent: the person can keep scrolling / retry via pull-to-refresh.
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filteredChats {
    if (_searchQuery.isEmpty) return _chats;
    final q = _searchQuery.toLowerCase();
    return _chats.where((doc) {
      final nurseId = doc.data()['nurseId']?.toString();
      final name = nurseId != null ? _nurses[nurseId]?.name ?? '' : '';
      return name.toLowerCase().contains(q);
    }).toList();
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
            onPressed: _loadFirstPage,
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
              Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadFirstPage,
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
        onRefresh: _loadFirstPage,
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

    final filtered = _filteredChats;

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('لا توجد نتائج')),
                    ],
                  )
                : ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final data = filtered[index].data();
                      final bookingId = data['bookingId'] as String?;
                      final nurseId = data['nurseId']?.toString();
                      final nurse = nurseId != null ? _nurses[nurseId] : null;
                      final displayName = nurse?.name.trim().isNotEmpty == true
                          ? nurse!.name.trim()
                          : 'محادثة';
                      final lastMessage = data['lastMessage'] as String?;
                      final updatedAt = data['updatedAt'];
                      final dateText = updatedAt is Timestamp
                          ? _formatDate(updatedAt.toDate())
                          : '';
                      final unread = (data['unreadForClient'] as num?)?.toInt() ?? 0;

                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage:
                                (nurse?.photoUrl?.isNotEmpty ?? false)
                                    ? NetworkImage(nurse!.photoUrl!)
                                    : null,
                            child: (nurse?.photoUrl?.isNotEmpty ?? false)
                                ? null
                                : Icon(Icons.person_outline,
                                    color: AppColors.primary),
                          ),
                          title: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  unread > 0 ? FontWeight.w800 : FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            lastMessage?.trim().isNotEmpty == true
                                ? lastMessage!
                                : 'ابدأ المحادثة',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  unread > 0 ? FontWeight.w600 : FontWeight.normal,
                              color: unread > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (dateText.isNotEmpty)
                                Text(dateText, style: const TextStyle(fontSize: 11)),
                              const SizedBox(height: 4),
                              unread > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        unread > 99 ? '99+' : '$unread',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.chevron_left, size: 18),
                            ],
                          ),
                          onTap: bookingId == null
                              ? null
                              : () => context.push('/client/chat/$bookingId'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.year == date.year && now.month == date.month && now.day == date.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
}
