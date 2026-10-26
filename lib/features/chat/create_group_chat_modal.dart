import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import 'chat_conversation_screen.dart';

class CreateGroupChatModal extends StatefulWidget {
  final AppState state;

  const CreateGroupChatModal({super.key, required this.state});

  @override
  State<CreateGroupChatModal> createState() => _CreateGroupChatModalState();
}

class _CreateGroupChatModalState extends State<CreateGroupChatModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final Set<UserModel> _selectedMembers = {};
  int _selectedColorIndex = 0;
  String _searchQuery = '';

  final List<Color> _groupColors = const [
    Color(0xFF2563EB), // Royal Blue
    Color(0xFF0D9488), // Teal
    Color(0xFF7C3AED), // Purple
    Color(0xFFEA580C), // Orange
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF059669), // Emerald
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _submitGroup() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one Channel Partner to join the group.')),
      );
      return;
    }

    final newGroup = widget.state.createGroupChat(
      groupName: _nameController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      selectedMembers: _selectedMembers.toList(),
      colorIndex: _selectedColorIndex,
    );

    Navigator.pop(context); // Close modal

    // Navigate directly into new group conversation
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ChatConversationScreen(
          state: widget.state,
          conversationId: newGroup.id,
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
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
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

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.group_add_rounded, color: Color(0xFF2563EB), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Create New CP Group Chat',
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
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Name
                    Text(
                      'Group Name *',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. West Hyderabad Luxury Mastermind',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a name for the group chat.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Group Purpose / Description
                    Text(
                      'Group Topic / Purpose (Optional)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Co-broking, high-ticket inventory, and buyer leads',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Avatar Palette Selector
                    Text(
                      'Group Color Badge',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(_groupColors.length, (idx) {
                        final isSelected = _selectedColorIndex == idx;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColorIndex = idx),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _groupColors[idx],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _groupColors[idx].withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Member Selection Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Channel Partners (${_selectedMembers.length}) *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                        ),
                        if (_selectedMembers.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => _selectedMembers.clear()),
                            child: const Text('Clear All', style: TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Selected Members Chip Row
                    if (_selectedMembers.isNotEmpty) ...[
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedMembers.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, idx) {
                            final cp = _selectedMembers.elementAt(idx);
                            return Chip(
                              backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                              label: Text(
                                cp.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF2563EB)),
                              onDeleted: () => setState(() => _selectedMembers.remove(cp)),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Search CP Directory
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search partners by name, firm, city...',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
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
                    const SizedBox(height: 10),

                    // CP Checkbox List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredCps.length,
                      itemBuilder: (context, index) {
                        final cp = filteredCps[index];
                        final isSelected = _selectedMembers.contains(cp);

                        return CheckboxListTile(
                          value: isSelected,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedMembers.add(cp);
                              } else {
                                _selectedMembers.remove(cp);
                              }
                            });
                          },
                          title: Text(
                            cp.name,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            '${cp.firmName} • ${cp.city}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                            ),
                          ),
                          secondary: CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            child: Text(
                              cp.name.isNotEmpty ? cp.name[0].toUpperCase() : 'C',
                              style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitGroup,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                label: Text(
                  'Create Group (${_selectedMembers.length} Partners)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
