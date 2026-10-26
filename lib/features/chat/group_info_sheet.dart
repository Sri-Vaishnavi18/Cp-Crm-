import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import 'chat_conversation_screen.dart';

class GroupInfoSheet extends StatelessWidget {
  final AppState state;
  final String conversationId;

  const GroupInfoSheet({
    super.key,
    required this.state,
    required this.conversationId,
  });

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

  void _showAddParticipantsModal(BuildContext context, ChatConversationModel conv) {
    final availableCps = state.networkCps
        .where((cp) => !conv.participantIds.contains(cp.id) && cp.id != state.currentUser?.id)
        .toList();

    if (availableCps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All verified CPs in your network are already in this group.')),
      );
      return;
    }

    final selected = <UserModel>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = state.isDarkMode;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Partners to Group',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: availableCps.length,
                    itemBuilder: (context, index) {
                      final cp = availableCps[index];
                      final isSelected = selected.contains(cp);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              selected.add(cp);
                            } else {
                              selected.remove(cp);
                            }
                          });
                        },
                        title: Text(
                          cp.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${cp.firmName} • ${cp.city}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                          ),
                        ),
                        secondary: CircleAvatar(
                          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                          child: Text(
                            cp.name.isNotEmpty ? cp.name[0].toUpperCase() : 'C',
                            style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: selected.isEmpty
                        ? null
                        : () {
                            state.addMembersToGroup(conv.id, selected.toList());
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added ${selected.length} partner(s) to ${conv.title}')),
                            );
                          },
                    child: Text(
                      'Add Selected (${selected.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmLeaveGroup(BuildContext context, ChatConversationModel conv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group?'),
        content: Text('Are you sure you want to exit "${conv.title}"? You will stop receiving messages from this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              state.leaveGroup(conv.id);
              Navigator.pop(context); // Close sheet
            },
            child: const Text('Leave Group', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openDirectChatWithCp(BuildContext context, UserModel cp) {
    Navigator.pop(context); // Close info sheet
    final directConv = state.getOrCreateDirectChat(cp);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ChatConversationScreen(
          state: state,
          conversationId: directConv.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final isDark = state.isDarkMode;
        final conversations = state.conversations;
        final convIndex = conversations.indexWhere((c) => c.id == conversationId);

        if (convIndex == -1) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: const Text('Group not found.'),
          );
        }

        final conv = conversations[convIndex];
        final avatarColor = _getGroupColor(conv.avatarColorIndex);
        final currentUserId = state.currentUser?.id ?? 'usr_guest';

        // Resolve member models from network CPs and current user
        final members = <UserModel>[];
        if (state.currentUser != null && conv.participantIds.contains(state.currentUser!.id)) {
          members.add(state.currentUser!);
        }
        for (final id in conv.participantIds) {
          if (id != state.currentUser?.id) {
            final match = state.networkCps.firstWhere(
              (cp) => cp.id == id,
              orElse: () => UserModel(
                id: id,
                name: 'Verified Partner',
                firmName: 'Real Estate Firm',
                reraNumber: 'RERA-VERIFIED',
                phone: '',
                email: '',
                city: 'Network Member',
                isAgency: false,
              ),
            );
            members.add(match);
          }
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              // Group Header Banner
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: avatarColor.withValues(alpha: 0.15),
                    child: Icon(Icons.groups_rounded, color: avatarColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conv.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Created ${DateFormat('MMM yyyy').format(conv.createdAt)} • ${conv.participantIds.length} Channel Partners',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Group Topic / Description
              if (conv.description != null && conv.description!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    conv.description!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Policy Notice: Text only, no phone dialers
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Direct phone calls are disabled. Connect with members via 1-on-1 text chat.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Participants Header & Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${members.length} Participants',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddParticipantsModal(context, conv),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                    label: const Text('Add Partners', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Members List
              Expanded(
                child: ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isMe = member.id == currentUserId;
                    final isAdmin = conv.adminIds.contains(member.id);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            child: Text(
                              member.name.isNotEmpty ? member.name[0].toUpperCase() : 'C',
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        isMe ? '${member.name} (You)' : member.name,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    if (isAdmin) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'ADMIN',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${member.firmName} • ${member.city}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Strictly Text-Only Action: "Message Privately" (NO CALL BUTTON)
                          if (!isMe)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(
                                  color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                                ),
                              ),
                              onPressed: () => _openDirectChatWithCp(context, member),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 13),
                              label: const Text('Text', style: TextStyle(fontSize: 11)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Leave Group Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _confirmLeaveGroup(context, conv),
                  icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                  label: const Text('Leave Group', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
