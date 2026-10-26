import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import 'chat_conversation_screen.dart';

class CpDirectoryModal extends StatefulWidget {
  final AppState state;

  const CpDirectoryModal({super.key, required this.state});

  @override
  State<CpDirectoryModal> createState() => _CpDirectoryModalState();
}

class _CpDirectoryModalState extends State<CpDirectoryModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startChatWithCp(UserModel cp) {
    Navigator.pop(context); // Close directory modal
    final conv = widget.state.getOrCreateDirectChat(cp);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ChatConversationScreen(
          state: widget.state,
          conversationId: conv.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final currentUserId = widget.state.currentUser?.id ?? 'usr_guest';
    final allCps = widget.state.networkCps.where((cp) => cp.id != currentUserId).toList();

    final filteredCps = _searchQuery.isEmpty
        ? allCps
        : allCps.where((cp) {
            final q = _searchQuery.toLowerCase();
            return cp.name.toLowerCase().contains(q) ||
                cp.firmName.toLowerCase().contains(q) ||
                cp.city.toLowerCase().contains(q);
          }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_search_rounded, color: Color(0xFF2563EB), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Direct Message Channel Partner',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search partners by name, brokerage, city...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 12),

          // Policy notice banner (strictly text messaging)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_outlined, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Select a verified Channel Partner to start a 1-on-1 text conversation. Direct calling is disabled.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Partners List
          Expanded(
            child: filteredCps.isEmpty
                ? Center(
                    child: Text(
                      'No matching Channel Partners found.',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredCps.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, index) {
                      final cp = filteredCps[index];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        onTap: () => _startChatWithCp(cp),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                          child: Text(
                            cp.name.isNotEmpty ? cp.name[0].toUpperCase() : 'C',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                cp.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (cp.isAgency) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'AGENCY',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0EA5E9),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              '${cp.firmName} • ${cp.city}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                              ),
                            ),
                            if (cp.reraNumber.isNotEmpty)
                              Text(
                                'RERA: ${cp.reraNumber}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
