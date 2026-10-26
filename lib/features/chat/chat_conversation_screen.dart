import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import 'group_info_sheet.dart';

class ChatConversationScreen extends StatefulWidget {
  final AppState state;
  final String conversationId;

  const ChatConversationScreen({
    super.key,
    required this.state,
    required this.conversationId,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearching = false;

  final List<String> _quickReplies = [
    'Any 3BHK inventory available?',
    'Client site visit scheduled for tomorrow',
    'Open for 50:50 co-broking on this deal?',
    'Have an active NRI buyer for ready possession',
    'Sharing project updates and price sheet',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.markConversationAsRead(widget.conversationId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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

  void _sendMessage([String? textToSend]) {
    final text = textToSend ?? _textController.text.trim();
    if (text.isEmpty) return;

    widget.state.sendChatMessage(
      conversationId: widget.conversationId,
      text: text,
    );

    if (textToSend == null) {
      _textController.clear();
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _openGroupInfo(ChatConversationModel conv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GroupInfoSheet(
        state: widget.state,
        conversationId: conv.id,
      ),
    );
  }

  Color _getGroupColor(int index) {
    const colors = [
      Color(0xFF2563EB), // Royal Blue
      Color(0xFF0D9488), // Teal
      Color(0xFF7C3AED), // Purple
      Color(0xFFEA580C), // Orange
      Color(0xFF0284C7), // Sky Blue
      Color(0xFF059669), // Emerald
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final isDark = widget.state.isDarkMode;
        final conversations = widget.state.conversations;
        final convIndex = conversations.indexWhere((c) => c.id == widget.conversationId);

        if (convIndex == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('Conversation')),
            body: const Center(child: Text('This conversation has been removed.')),
          );
        }

        final conversation = conversations[convIndex];
        final allMessages = widget.state.getMessagesForConversation(widget.conversationId);
        final messages = _searchQuery.isEmpty
            ? allMessages
            : allMessages.where((m) => m.text.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        final currentUserId = widget.state.currentUser?.id ?? 'usr_guest';

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F7FB),
          appBar: _buildAppBar(context, conversation, isDark),
          body: SafeArea(
            child: Column(
              children: [
                if (_isSearching) _buildSearchBar(isDark),

                // Strict Text-Only Security Notice Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Text-Only Verified CP Network • Calls & Dialers Restricted',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Message Thread
                Expanded(
                  child: messages.isEmpty
                      ? _buildEmptyState(conversation, isDark)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final showDateSeparator = index == 0 ||
                                !_isSameDay(messages[index - 1].timestamp, msg.timestamp);

                            return Column(
                              children: [
                                if (showDateSeparator) _buildDateSeparator(msg.timestamp, isDark),
                                if (msg.isSystemMessage)
                                  _buildSystemMessageBubble(msg, isDark)
                                else
                                  _buildMessageBubble(
                                    msg: msg,
                                    isMe: msg.senderId == currentUserId,
                                    isGroup: conversation.isGroup,
                                    isDark: isDark,
                                  ),
                              ],
                            );
                          },
                        ),
                ),

                // Quick Broker Reply Chips
                _buildQuickRepliesBar(isDark),

                // Input Bar
                _buildInputBar(isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ChatConversationModel conversation,
    bool isDark,
  ) {
    final avatarColor = _getGroupColor(conversation.avatarColorIndex);

    return AppBar(
      elevation: 0.5,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      foregroundColor: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
      titleSpacing: 0,
      title: InkWell(
        onTap: conversation.isGroup ? () => _openGroupInfo(conversation) : null,
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 19,
              backgroundColor: avatarColor.withValues(alpha: 0.15),
              child: conversation.isGroup
                  ? Icon(Icons.groups_rounded, color: avatarColor, size: 20)
                  : Text(
                      conversation.title.isNotEmpty ? conversation.title[0].toUpperCase() : 'C',
                      style: TextStyle(fontWeight: FontWeight.bold, color: avatarColor, fontSize: 16),
                    ),
            ),
            const SizedBox(width: 10),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          conversation.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (conversation.isGroup) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: avatarColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'GROUP',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: avatarColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    conversation.isGroup
                        ? '${conversation.participantIds.length} partners • Tap for group info'
                        : 'Verified Partner • Active in network',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Strictly Text-Only Action Menu (NO CALL BUTTONS)
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search_rounded,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = '';
            });
          },
        ),
        if (conversation.isGroup)
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 22),
            onPressed: () => _openGroupInfo(conversation),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            if (value == 'clear') {
              _showClearChatDialog(conversation.id);
            } else if (value == 'group_info' && conversation.isGroup) {
              _openGroupInfo(conversation);
            } else if (value == 'mute') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications muted for this conversation.')),
              );
            }
          },
          itemBuilder: (ctx) => [
            if (conversation.isGroup)
              const PopupMenuItem(
                value: 'group_info',
                child: Row(
                  children: [
                    Icon(Icons.group_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Group Info'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(Icons.notifications_off_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Mute Notifications'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.cleaning_services_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Clear Chat History'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: TextField(
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search messages...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime timestamp, bool isDark) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(timestamp, now)) {
      label = 'Today';
    } else if (_isSameDay(timestamp, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(timestamp);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessageBubble(ChatMessageModel msg, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        msg.text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required ChatMessageModel msg,
    required bool isMe,
    required bool isGroup,
    required bool isDark,
  }) {
    final timeStr = DateFormat('h:mm a').format(msg.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF2563EB)
              : (isDark ? AppColors.darkSurfaceCard : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name header for Group Chat (when not me)
            if (!isMe && isGroup) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.senderName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  if (msg.senderFirm.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '• ${msg.senderFirm}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
            ],

            // Message text
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: isMe
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 2),

            // Timestamp and status tick
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.8)
                        : (isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8)),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all_rounded,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ChatConversationModel conv, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              conv.isGroup ? 'Welcome to ${conv.title}' : 'Chat with ${conv.title}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              conv.isGroup
                  ? 'Send a message to start co-broking, share leads, and discuss luxury inventory.'
                  : 'Send a direct text message to discuss buyer requirements or project bookings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRepliesBar(bool isDark) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return ActionChip(
            label: Text(
              reply,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
              ),
            ),
            backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => _sendMessage(reply),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Type message...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(22),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog(String conversationId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text('All messages in this conversation will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              widget.state.clearConversationMessages(conversationId);
              Navigator.pop(ctx);
            },
            child: const Text('Clear Chat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
