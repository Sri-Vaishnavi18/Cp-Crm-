import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/services/url_action_service.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class LeadDetailScreen extends StatefulWidget {
  final AppState state;
  final String leadId;

  const LeadDetailScreen({
    super.key,
    required this.state,
    required this.leadId,
  });

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  LeadModel? _getLead() {
    final list = widget.state.allLeads;
    final idx = list.indexWhere((l) => l.id == widget.leadId);
    if (idx != -1) return list[idx];
    return null;
  }

  void _showEditLeadModal(BuildContext context, LeadModel lead) {
    final firstNameController = TextEditingController(text: lead.firstName);
    final lastNameController = TextEditingController(text: lead.lastName);
    final phoneController = TextEditingController(text: lead.phone);
    final emailController = TextEditingController(text: lead.email ?? '');
    final budgetController = TextEditingController(text: lead.budget);
    String selectedProject = lead.projectName;
    String selectedProjectId = lead.projectId;
    String selectedSource = lead.source;

    final isDark = widget.state.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF131A26) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Lead Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First / Full Name *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name (Optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: budgetController,
                    decoration: const InputDecoration(labelText: 'Budget Range'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: widget.state.projects.any((p) => p.name == selectedProject)
                        ? selectedProject
                        : (widget.state.projects.isNotEmpty ? widget.state.projects.first.name : null),
                    decoration: const InputDecoration(labelText: 'Interested Project'),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    items: widget.state.projects.map((p) {
                      return DropdownMenuItem(value: p.name, child: Text(p.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedProject = val;
                          final proj = widget.state.projects.firstWhere((p) => p.name == val);
                          selectedProjectId = proj.id;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedSource,
                    decoration: const InputDecoration(labelText: 'Source'),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'CHANNEL_PARTNER', child: Text('CHANNEL_PARTNER')),
                      DropdownMenuItem(value: 'Channel Partner', child: Text('Channel Partner')),
                      DropdownMenuItem(value: 'Digital Ads', child: Text('Digital Ads')),
                      DropdownMenuItem(value: 'Walk-in', child: Text('Walk-in')),
                      DropdownMenuItem(value: 'Referral', child: Text('Referral')),
                      DropdownMenuItem(value: 'Website Inquiry', child: Text('Website Inquiry')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedSource = val);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (firstNameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields.')),
                          );
                          return;
                        }
                        widget.state.updateLeadInfo(
                          leadId: lead.id,
                          firstName: firstNameController.text.trim(),
                          lastName: lastNameController.text.trim(),
                          phone: phoneController.text.trim(),
                          email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                          projectId: selectedProjectId,
                          projectName: selectedProject,
                          source: selectedSource,
                          budget: budgetController.text.trim(),
                        );
                        Navigator.of(ctx).pop();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, LeadModel lead) {
    final noteController = TextEditingController();
    final isDark = widget.state.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF151C28) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.sticky_note_2_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Add Lead Note',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: noteController,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter observation, client preferences, or follow-up note...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.trim().isNotEmpty) {
                widget.state.addLeadNote(lead.id, noteController.text.trim());
                Navigator.of(ctx).pop();
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(BuildContext context, LeadModel lead) {
    final isDark = widget.state.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF131A26) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Lead Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Temperature will automatically update (New = Cold, Visited = Warm, Booked = Hot)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...LeadStage.values.map((stage) {
                        final isSelected = lead.stage == stage;
                        final tempForStage = LeadModel.getTemperatureForStage(stage);
                        Color tempColor;
                        switch (tempForStage) {
                          case LeadTemperature.hot:
                            tempColor = const Color(0xFFEF4444);
                            break;
                          case LeadTemperature.warm:
                            tempColor = const Color(0xFFF59E0B);
                            break;
                          case LeadTemperature.cold:
                            tempColor = const Color(0xFF0EA5E9);
                            break;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              widget.state.updateLeadStage(lead.id, stage);
                              Navigator.of(ctx).pop();
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : (isDark ? const Color(0xFF1B2433) : AppColors.lightSurfaceSubtle),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: isSelected ? AppColors.primary : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      stage.readableTitle,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: tempColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: tempColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      tempForStage.shortLabelWithEmoji,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: tempColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullHistoryModal(BuildContext context, LeadModel lead) {
    final isDark = widget.state.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF131A26) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, color: Color(0xFF818CF8), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Full Activity Timeline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: lead.activityList.isEmpty
                    ? Center(
                        child: Text(
                          'No activity recorded yet',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: lead.activityList.length,
                        itemBuilder: (context, idx) {
                          final act = lead.activityList[idx];
                          final isLast = idx == lead.activityList.length - 1;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF818CF8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 48,
                                      color: const Color(0xFF334155),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        act.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatActivityDate(act.timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatActivityDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final period = d.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year} • ${hour.toString().padLeft(2, '0')}:$minuteStr $period';
  }

  @override
  Widget build(BuildContext context) {
    final lead = _getLead();
    final isDark = widget.state.isDarkMode;

    if (lead == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B0F17) : AppColors.lightBg,
        appBar: AppBar(title: const Text('Lead Detail')),
        body: const Center(child: Text('Lead not found')),
      );
    }

    // Dynamic temperature colors
    Color tempColor;
    switch (lead.temperature) {
      case LeadTemperature.hot:
        tempColor = const Color(0xFFEF4444);
        break;
      case LeadTemperature.warm:
        tempColor = const Color(0xFFF59E0B);
        break;
      case LeadTemperature.cold:
        tempColor = const Color(0xFF0EA5E9);
        break;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F17) : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header (Matching Screenshots)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B0F17) : AppColors.lightSurface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF1E293B) : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lead Detail',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'View and manage lead information',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HERO LEAD PROFILE CARD (Screenshot 1)
                    _buildHeroCard(lead, isDark, tempColor),
                    const SizedBox(height: 16),

                    // 2. QUICK ACTION BUTTONS GRID (Screenshot 1)
                    _buildActionButtonsGrid(lead, isDark),
                    const SizedBox(height: 16),

                    // 3. LEAD INFORMATION CARD (Screenshot 1)
                    _buildLeadInformationCard(lead, isDark),
                    const SizedBox(height: 16),

                    // 4. STATUS & TEMPERATURE CARD (Screenshot 2)
                    _buildStatusAndTemperatureCard(lead, isDark, tempColor),
                    const SizedBox(height: 16),

                    // 5. UPDATE STATUS CARD (Screenshot 2)
                    _buildUpdateStatusCard(lead, isDark),
                    const SizedBox(height: 16),

                    // 6. NOTES CARD (Screenshot 3)
                    _buildNotesCard(lead, isDark),
                    const SizedBox(height: 16),

                    // 7. SITE VISIT HISTORY CARD (Screenshot 3 - Zero-OTP)
                    _buildSiteVisitHistoryCard(lead, isDark),
                    const SizedBox(height: 16),

                    // 8. ACTIVITY TIMELINE CARD (Screenshot 3)
                    _buildActivityTimelineCard(lead, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. HERO PROFILE CARD
  Widget _buildHeroCard(LeadModel lead, bool isDark, Color tempColor) {
    final avatarNumber = '01';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left Warm Amber Accent Strip
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar with Star, Name, Temperature Badge, Channel Partner Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with Star Badge at bottom-right
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              avatarNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Name, Temperature Pill, Phone, Project
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                lead.fullName.isNotEmpty ? lead.fullName : 'Lead',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Temperature Pill (e.g. ☀️ Warm Lead)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: tempColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: tempColor.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  lead.temperature.labelWithEmoji,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: tempColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Phone with Icon
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 15,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                lead.phone,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Project with Icon
                          Row(
                            children: [
                              Icon(
                                Icons.apartment_rounded,
                                size: 15,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                lead.projectName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Role Pill (e.g. Channel Partner)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF382B55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Channel Partner',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC7D2FE),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Subtle Divider Line
                Container(
                  height: 1,
                  color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
                ),
                const SizedBox(height: 18),

                // 5-Stage Pipeline Progress Stepper (Screenshot 1)
                _buildPipelineStepper(lead, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pipeline Stepper (5 Steps: Lead Created, Contacted, Site Visit, Negotiation, Booked)
  Widget _buildPipelineStepper(LeadModel lead, bool isDark) {
    const steps = [
      'Lead Created',
      'Contacted',
      'Site Visit',
      'Negotiation',
      'Booked',
    ];

    final currentIndex = lead.pipelineStepIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Connector Nodes Row
            Row(
              children: List.generate(steps.length * 2 - 1, (index) {
                if (index.isEven) {
                  // Node
                  final stepIndex = index ~/ 2;
                  final isCompleted = stepIndex <= currentIndex;

                  return Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFF59E0B)
                          : (isDark ? const Color(0xFF131A26) : Colors.white),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFFF59E0B)
                            : (isDark ? const Color(0xFF334155) : Colors.grey.shade400),
                        width: isCompleted ? 2 : 2.5,
                      ),
                    ),
                  );
                } else {
                  // Connecting Line
                  final stepBefore = index ~/ 2;
                  final isCompleted = stepBefore < currentIndex;

                  return Expanded(
                    child: Container(
                      height: 2.5,
                      color: isCompleted
                          ? const Color(0xFFF59E0B)
                          : (isDark ? const Color(0xFF2A374A) : Colors.grey.shade300),
                    ),
                  );
                }
              }),
            ),
            const SizedBox(height: 8),

            // Step Labels Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(steps.length, (index) {
                final isCompleted = index <= currentIndex;
                final isCurrent = index == currentIndex;

                return SizedBox(
                  width: (constraints.maxWidth - 20) / steps.length,
                  child: Text(
                    steps[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w800 : (isCompleted ? FontWeight.w700 : FontWeight.w500),
                      color: isCompleted
                          ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  // 2. QUICK ACTION BUTTONS GRID (Call, WhatsApp, Edit, Email)
  Widget _buildActionButtonsGrid(LeadModel lead, bool isDark) {
    return Column(
      children: [
        // Row 1: Call, WhatsApp, Edit
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.phone_outlined,
                label: 'Call',
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => UrlActionService.makePhoneCall(context, lead.phone),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () {
                  final msg =
                      'Hello ${lead.firstName}, this is ${widget.state.currentUser?.name ?? "your representative"} from ${widget.state.currentUser?.firmName ?? "our firm"}. Sharing project details for ${lead.projectName}.';
                  UrlActionService.openWhatsApp(context, phoneNumber: lead.phone, message: msg);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                color: const Color(0xFFA855F7),
                isDark: isDark,
                onTap: () => _showEditLeadModal(context, lead),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: Email
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildActionButton(
                icon: Icons.email_outlined,
                label: 'Email',
                color: const Color(0xFF818CF8),
                isDark: isDark,
                onTap: () {
                  if (lead.email != null && lead.email!.isNotEmpty) {
                    UrlActionService.sendEmail(
                      context,
                      email: lead.email!,
                      subject: 'Information regarding ${lead.projectName}',
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No email address provided for this lead.')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            const Spacer(flex: 2),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151C28) : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. LEAD INFORMATION CARD (Screenshot 1)
  Widget _buildLeadInformationCard(LeadModel lead, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Color(0xFF818CF8), size: 20),
              const SizedBox(width: 8),
              Text(
                'Lead Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2x2 Grid (Phone | Source, Email | Interested Project)
          Row(
            children: [
              Expanded(
                child: _buildInfoGridItem(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: lead.phone,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoGridItem(
                  icon: Icons.public_rounded,
                  label: 'Source',
                  value: lead.source,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoGridItem(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: lead.email?.isNotEmpty == true ? lead.email! : 'Not Provided',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoGridItem(
                  icon: Icons.apartment_rounded,
                  label: 'Interested Project',
                  value: lead.projectName,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGridItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E283D) : AppColors.lightSurfaceSubtle,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFF818CF8),
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. STATUS & TEMPERATURE CARD (Screenshot 2)
  Widget _buildStatusAndTemperatureCard(LeadModel lead, bool isDark, Color tempColor) {
    String siteVisitText = 'None';
    if (lead.stage == LeadStage.visitScheduled) {
      siteVisitText = 'Scheduled';
    } else if (lead.stage == LeadStage.visitCompleted) {
      siteVisitText = 'Completed';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thermostat_outlined, color: Color(0xFF818CF8), size: 20),
              const SizedBox(width: 8),
              Text(
                'Status & Temperature',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Metric Sub-Cards
          Row(
            children: [
              // Temperature Sub-Card
              Expanded(
                child: _buildMetricSubCard(
                  label: 'Temperature',
                  isDark: isDark,
                  pillContent: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lead.temperature.shortLabelWithEmoji,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: tempColor,
                        ),
                      ),
                    ],
                  ),
                  pillColor: tempColor.withValues(alpha: 0.15),
                  borderColor: tempColor.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 8),

              // Status Sub-Card
              Expanded(
                child: _buildMetricSubCard(
                  label: 'Status',
                  isDark: isDark,
                  pillContent: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outlined, color: Color(0xFF38BDF8), size: 12),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          lead.stage.readableTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  pillColor: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                  borderColor: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 8),

              // Site Visit Sub-Card
              Expanded(
                child: _buildMetricSubCard(
                  label: 'Site Visit',
                  isDark: isDark,
                  pillContent: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, color: Color(0xFFF59E0B), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        siteVisitText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  pillColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSubCard({
    required String label,
    required bool isDark,
    required Widget pillContent,
    required Color pillColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17202F) : AppColors.lightSurfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF28364D) : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Center(child: pillContent),
          ),
        ],
      ),
    );
  }

  // 5. UPDATE STATUS CARD (Screenshot 2)
  Widget _buildUpdateStatusCard(LeadModel lead, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF222944),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.sync_rounded, color: Color(0xFF818CF8), size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Update Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Current Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Custom Green Text Dropdown Container
          InkWell(
            onTap: () => _showStatusPicker(context, lead),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151C28) : AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF26354B) : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lead.stage.readableTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981), // Green text from mockup
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.grey.shade400 : AppColors.lightTextSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. NOTES CARD (Screenshot 3)
  Widget _buildNotesCard(LeadModel lead, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Color(0xFF818CF8), size: 20),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Full-width "+ Add Note" Primary Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddNoteDialog(context, lead),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add Note',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5), // Electric Indigo from mockup
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Empty state or Notes list
          if (lead.notesList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No notes yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            )
          else
            ...lead.notesList.map((n) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF17202F) : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF28364D) : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'By ${n.author}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Text(
                          _formatActivityDate(n.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 7. SITE VISIT HISTORY CARD (Screenshot 3 - Zero-OTP direct verification)
  Widget _buildSiteVisitHistoryCard(LeadModel lead, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF818CF8), size: 20),
              const SizedBox(width: 8),
              Text(
                'Site Visit History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (lead.siteVisitHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No site visit history yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            )
          else
            ...lead.siteVisitHistory.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF17202F) : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF28364D) : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // 8. ACTIVITY TIMELINE CARD (Screenshot 3)
  Widget _buildActivityTimelineCard(LeadModel lead, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded, color: Color(0xFF818CF8), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showFullHistoryModal(context, lead),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'View Full History',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF818CF8),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF818CF8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (lead.activityList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No activity recorded yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            )
          else
            ...lead.activityList.take(3).toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final act = entry.value;
              final isLast = idx == (lead.activityList.length > 3 ? 2 : lead.activityList.length - 1);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF818CF8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 44,
                          color: const Color(0xFF334155),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatActivityDate(act.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}
