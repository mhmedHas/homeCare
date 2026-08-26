import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/booking_service.dart';
import '../../shared/models/booking.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  const ChatScreen({super.key, required this.bookingId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _chatId;
  String? _otherUserId;
  Booking? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final booking = await BookingService().getBooking(widget.bookingId);
      if (booking == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _booking = booking;
      });

      final user = AuthService().currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final clientId = booking.clientId;
      final nurseId = booking.nurseId;
      final currentUserId = user.uid;

      _otherUserId = (currentUserId == clientId) ? nurseId : clientId;

      final chatId = await _chatService.getOrCreateChat(
        widget.bookingId,
        clientId,
        nurseId,
      );
      setState(() {
        _chatId = chatId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _chatId == null ||
        _otherUserId == null) return;
    final user = AuthService().currentUser;
    if (user == null) return;

    await _chatService.sendMessage(
      _chatId!,
      user.uid,
      _otherUserId!,
      _messageController.text.trim(),
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثة'),
        actions: [
          IconButton(
              onPressed: () =>
                  context.go('/client/booking-details/${widget.bookingId}'),
              icon: const Icon(Icons.info_outline)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatId == null
              ? const Center(child: Text('لا يمكن بدء المحادثة'))
              : Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<dynamic>>(
                        stream: _chatService.getMessages(_chatId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(child: Text('حدث خطأ'));
                          }
                          final messages = snapshot.data ?? [];
                          if (messages.isEmpty) {
                            return const Center(
                                child: Text('لا توجد رسائل بعد'));
                          }
                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(8),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages.reversed.toList()[index];
                              final isMe = msg.senderId ==
                                  AuthService().currentUser?.uid;
                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.primary
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    msg.text,
                                    style: TextStyle(
                                        color:
                                            isMe ? Colors.white : Colors.black),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'اكتب رسالتك...',
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(24))),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
