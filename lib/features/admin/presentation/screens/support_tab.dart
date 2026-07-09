import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_firestore_service.dart';
import '../../../../helpers/toast.dart';

class SupportTab extends StatefulWidget {
  const SupportTab({super.key});

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab> {
  final _firestoreService = AdminFirestoreService();
  String? _selectedChatId;
  Map<String, dynamic>? _selectedChatData;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedChatId == null) return;

    _messageController.clear();
    try {
      await _firestoreService.sendSupportMessage(_selectedChatId!, text);
      // Wait a brief moment for the message to render, then scroll down
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      ToastUtil.showShortToast('Failed to send message: $e');
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return '';
    }
    
    final now = DateTime.now();
    if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
      return DateFormat('h:mm a').format(dateTime);
    }
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        
        return Row(
          children: [
            // Left panel: Chat list
            if (!isNarrow || _selectedChatId == null)
              Container(
                width: isNarrow ? constraints.maxWidth : 320,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.white10, width: 1),
                  ),
                  color: Color(0xFF161930),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Support Tickets',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _firestoreService.watchSupportChats(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF7C4DFF),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            );
                          }

                          final chats = snapshot.data ?? [];
                          if (chats.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.white24,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No support chats yet',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white30,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: chats.length,
                            separatorBuilder: (context, index) =>
                                const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, index) {
                              final chat = chats[index];
                              final chatId = chat['chatId'] as String;
                              final userName = chat['userName'] ?? 'User';
                              final lastMsg = chat['lastMessage'] ?? '';
                              final lastTime = chat['lastMessageTime'];
                              final unread = chat['unreadByAdmin'] == true;
                              final isSelected = chatId == _selectedChatId;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedChatId = chatId;
                                    _selectedChatData = chat;
                                  });
                                  _firestoreService.markSupportChatAsRead(chatId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  color: isSelected
                                      ? const Color(0xFF7C4DFF).withValues(alpha:0.1)
                                      : Colors.transparent,
                                  child: Row(
                                    children: [
                                      // Circle Avatar with initials
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: unread
                                            ? const Color(0xFF7C4DFF)
                                            : const Color(0xFF1F214A),
                                        child: Text(
                                          userName.isNotEmpty
                                              ? userName[0].toUpperCase()
                                              : 'U',
                                          style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // User name & message snippet
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    userName,
                                                    style: GoogleFonts.dmSans(
                                                      color: Colors.white,
                                                      fontWeight: unread
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatTime(lastTime),
                                                  style: GoogleFonts.dmSans(
                                                    color: unread
                                                        ? const Color(0xFF7C4DFF)
                                                        : Colors.white30,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              lastMsg,
                                              style: GoogleFonts.dmSans(
                                                color: unread
                                                    ? Colors.white.withValues(alpha:0.87)
                                                    : Colors.white30,
                                                fontSize: 12,
                                                fontWeight: unread
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (unread)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF7C4DFF),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Right panel: Messaging view
            if (_selectedChatId != null)
              Expanded(
                child: Container(
                  color: const Color(0xFF0F1026),
                  child: Column(
                    children: [
                      // Chat Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF161930),
                          border: Border(
                            bottom:
                                BorderSide(color: Colors.white10, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isNarrow)
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white70),
                                onPressed: () {
                                  setState(() {
                                    _selectedChatId = null;
                                    _selectedChatData = null;
                                  });
                                },
                              ),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF7C4DFF),
                              child: Text(
                                _selectedChatData?['userName'] != null &&
                                        _selectedChatData!['userName']
                                            .toString()
                                            .isNotEmpty
                                    ? _selectedChatData!['userName']
                                        .toString()[0]
                                        .toUpperCase()
                                    : 'U',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedChatData?['userName'] ?? 'User',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    _selectedChatData?['userEmail'] ?? 'N/A',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Messages list
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _firestoreService
                              .watchSupportMessages(_selectedChatId!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF7C4DFF),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error loading messages',
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
                              );
                            }

                            final messages = snapshot.data ?? [];
                            
                            // Auto scroll to bottom when new messages arrive
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToBottom();
                            });

                            if (messages.isEmpty) {
                              return Center(
                                child: Text(
                                  'No messages in this chat yet.',
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white24),
                                ),
                              );
                            }

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(20),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isAdmin = msg['senderId'] == 'admin';
                                final text = msg['text'] ?? '';
                                final time = msg['timestamp'];

                                return Align(
                                  alignment: isAdmin
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          constraints.maxWidth * 0.6 > 400
                                              ? 400
                                              : constraints.maxWidth * 0.6,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isAdmin
                                          ? const Color(0xFF7C4DFF)
                                          : const Color(0xFF1E2142),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: isAdmin
                                            ? const Radius.circular(16)
                                            : Radius.zero,
                                        bottomRight: isAdmin
                                            ? Radius.zero
                                            : const Radius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          text,
                                          style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            _formatTime(time),
                                            style: GoogleFonts.dmSans(
                                              color: Colors.white54,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // Message Input Area
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        color: const Color(0xFF161930),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Type your message...',
                                  hintStyle:
                                      const TextStyle(color: Colors.white24),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF1F214A),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                onSubmitted: (_) => _handleSendMessage(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF7C4DFF),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white),
                                onPressed: _handleSendMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (!isNarrow)
              Expanded(
                child: Container(
                  color: const Color(0xFF0F1026),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF161930),
                            border: Border.all(
                                color: const Color(0xFF7C4DFF)
                                    .withValues(alpha:0.15)),
                          ),
                          child: const Icon(
                            Icons.contact_support_outlined,
                            color: Color(0xFF7C4DFF),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a ticket to start responding',
                          style: GoogleFonts.dmSans(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chat in real-time with users who request support from the app',
                          style: GoogleFonts.dmSans(
                            color: Colors.white30,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
