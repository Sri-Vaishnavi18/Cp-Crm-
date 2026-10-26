import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import 'chat_conversation_screen.dart';
import 'create_group_chat_modal.dart';
import 'cp_directory_modal.dart';

class ChatListScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback? onBack;

  const ChatListScreen({
    super.key,
    required this.state,
    this.onBack,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _activeFilterIndex = 0; // 0: All, 1: Direct, 2: Groups
  String _searchQuery = '';
  bool _isSearching = false;

  void _openDirectChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CpDirectoryModal(state: widget.state),
    );
  }

  void _openCreateGroupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateGroupChatModal(state: widget.state),
    );
  }

  void _showNewChatActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = widget.state.isDarkMode;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Start a Conversation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('Direct 1-on-1 Message', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Text a verified Channel Partner in the network', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _openDirectChatModal();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group_add_rounded, color: Color(0xFF0D9488)),
                ),
                title: const Text('Create New Group Chat', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Form a broker mastermind, regional pool, or deal circle', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateGroupModal();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getGroupColor(int index) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF0D9488),
      Color(0xFF7C3AED),
      Color(0xFFEA580C),
      Color(0xFF0284C7),
      Color(0xFF059669),
    ];
    return colors[index % colors.length];
  }

  String _formatConversationTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0 && now.day == time.day) {
      return DateFormat('h:mm a').format(time);
    } else if (difference.inDays < 7) {
      return DateFormat('E').format(time); // e.g. Mon, Tue
    } else {
      return DateFormat('dd/MM/yy').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final isDark = widget.state.isDarkMode;
        final conversations = widget.state.conversations;

        // Apply tab filter
        var filteredList = conversations.where((c) {
          if (_activeFilterIndex == 1) return !c.isGroup;
          if (_activeFilterIndex == 2) return c.isGroup;
          return true;
        }).toList();

        // Apply search query
        if (_searchQuery.isNotEmpty) {
          filteredList = filteredList.where((c) {
            final q = _searchQuery.toLowerCase();
            final matchesTitle = c.title.toLowerCase().contains(q);
            final matchesLastMsg = c.lastMessage?.toLowerCase().contains(q) ?? false;
            return matchesTitle || matchesLastMsg;
          }).toList();
        }

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F7FB),
          appBar: AppBar(
            elevation: 0.5,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            foregroundColor: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            leading: widget.onBack != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: widget.onBack,
                  )
                : null,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CP Community & Chats',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Verified Broker Network',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) _searchQuery = '';
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_outlined),
                tooltip: 'Direct Message',
                onPressed: _openDirectChatModal,
              ),
              IconButton(
                icon: const Icon(Icons.group_add_outlined),
                tooltip: 'New Group',
                onPressed: _openCreateGroupModal,
              ),
            ],
          ),
          body: Column(
            children: [
              if (_isSearching) _buildSearchBar(isDark),

              // Strict Text-Only Compliance Banner
              Container(
                margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: 0.12),
                      const Color(0xFF0D9488).withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🔒 Text-Only Network: Voice & phone calls are strictly disabled to protect partner privacy. Co-broke and discuss deals securely via text.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E3A8A),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    _buildFilterChip(0, 'All Chats (${conversations.length})', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, 'Direct (${conversations.where((c) => !c.isGroup).length})', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, 'Groups (${conversations.where((c) => c.isGroup).length})', isDark),
                  ],
                ),
              ),

              // Conversations List
              Expanded(
                child: filteredList.isEmpty
                    ? _buildEmptyView(isDark)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 80),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final conv = filteredList[index];
                          return _buildConversationCard(conv, isDark);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showNewChatActionSheet,
            backgroundColor: const Color(0xFF2563EB),
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 22),
            label: const Text(
              'New Chat',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(int index, String label, bool isDark) {
    final isSelected = _activeFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: isSelected
            ? Colors.white
            : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
      ),
      side: BorderSide(
        color: isSelected
            ? Colors.transparent
            : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (_) => setState(() => _activeFilterIndex = index),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: TextField(
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search chats, brokers, or group topics...',
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

  Widget _buildConversationCard(ChatConversationModel conv, bool isDark) {
    final avatarColor = _getGroupColor(conv.avatarColorIndex);
    final timeStr = _formatConversationTime(conv.lastMessageTime);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      color: isDark ? AppColors.darkSurfaceCard : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => ChatConversationScreen(
                state: widget.state,
                conversationId: conv.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: avatarColor.withValues(alpha: 0.15),
                child: conv.isGroup
                    ? Icon(Icons.groups_rounded, color: avatarColor, size: 22)
                    : Text(
                        conv.title.isNotEmpty ? conv.title[0].toUpperCase() : 'C',
                        style: TextStyle(
                          color: avatarColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Title, Snippet & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            conv.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (conv.isGroup) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: avatarColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'GROUP',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: avatarColor),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            color: conv.unreadCount > 0
                                ? const Color(0xFF2563EB)
                                : (isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.lastMessage ?? 'No messages yet',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: conv.unreadCount > 0
                                  ? (isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A))
                                  : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                              fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (conv.unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${conv.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_outlined, size: 32, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 16),
            Text(
              'No Conversations Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start direct text messaging with peer Channel Partners or form a new regional mastermind group.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _openDirectChatModal,
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                  label: const Text('Direct Message'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  onPressed: _openCreateGroupModal,
                  icon: const Icon(Icons.group_add_outlined, size: 16, color: Colors.white),
                  label: const Text('Create Group', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
