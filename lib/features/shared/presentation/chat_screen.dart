import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/user_service.dart';
import '../models/booking.dart';
import '../models/app_user.dart';
import '../models/message.dart';

/// Chat screen shared by both the client and the nurse.
/// It shows the *other* participant's real name and photo in the app bar
/// (the client sees the nurse's name, the nurse sees the client's name),
/// instead of a generic "Conversation" title.
class ChatScreen extends StatefulWidget {
  final String bookingId;
  const ChatScreen({super.key, required this.bookingId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  String? _chatId;
  String? _otherUserId;
  AppUser? _otherUser;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final booking = await BookingService().getBooking(widget.bookingId);
      if (booking == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'الحجز غير موجود';
          });
        }
        return;
      }

      final user = AuthService().currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'يرجى تسجيل الدخول';
          });
        }
        return;
      }

      final currentUserId = user.uid;
      final otherUserId =
          currentUserId == booking.clientId ? booking.nurseId : booking.clientId;

      final otherUser = await UserService().getUser(otherUserId);

      final chatId = await _chatService.getOrCreateChat(
        widget.bookingId,
        booking.clientId,
        booking.nurseId,
      );

      if (!mounted) return;
      setState(() {
        _chatId = chatId;
        _otherUserId = otherUserId;
        _otherUser = otherUser;
        _isLoading = false;
      });

      // Mark the other side's messages as seen once we open the thread.
      unawaited(_chatService.markMessagesAsSeen(chatId, currentUserId));
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'تعذر فتح المحادثة';
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null || _otherUserId == null || _isSending) {
      return;
    }
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _isSending = true);
    _messageController.clear();
    try {
      await _chatService.sendMessage(_chatId!, user.uid, _otherUserId!, text);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إرسال الرسالة، حاول مرة أخرى')),
        );
        // Give the person their text back so they don't retype it.
        _messageController.text = text;
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherName = _otherUser?.name.trim().isNotEmpty == true
        ? _otherUser!.name.trim()
        : 'محادثة';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: (_otherUser?.photoUrl?.isNotEmpty ?? false)
                  ? NetworkImage(_otherUser!.photoUrl!)
                  : null,
              child: (_otherUser?.photoUrl?.isNotEmpty ?? false)
                  ? null
                  : Icon(Icons.person_outline, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                otherName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatId == null
              ? Center(child: Text(_errorMessage ?? 'لا يمكن بدء المحادثة'))
              : Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Message>>(
                        stream: _chatService.getMessages(_chatId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(child: Text('حدث خطأ أثناء تحميل الرسائل'));
                          }
                          final messages = snapshot.data ?? const <Message>[];
                          if (messages.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textSecondary),
                                    const SizedBox(height: 10),
                                    Text('ابدأ المحادثة مع $otherName', textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            );
                          }
                          // Newest first for a reversed ListView.
                          final reversed = messages.reversed.toList(growable: false);
                          final myId = AuthService().currentUser?.uid;
                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(12),
                            itemCount: reversed.length,
                            itemBuilder: (context, index) {
                              final msg = reversed[index];
                              final isMe = msg.senderId == myId;
                              return _MessageBubble(message: msg, isMe: isMe);
                            },
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendMessage(),
                                decoration: InputDecoration(
                                  hintText: 'اكتب رسالتك...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primary,
                              child: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                                      onPressed: _sendMessage,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm('ar').format(message.createdAt);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
