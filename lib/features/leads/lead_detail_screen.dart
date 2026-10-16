import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/services/document_picker_service.dart';
import '../../core/services/url_action_service.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';

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

  void _openScheduleVisit(LeadModel lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleVisitModalSheet(
        state: widget.state,
        preselectedLeadId: lead.id,
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

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
                    initialValue: widget.state.projects.any((p) => p.name == selectedProject)
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
                    initialValue: selectedSource,
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

                              if (stage == LeadStage.siteVisited) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Status updated to Site Visited! You can now upload the Site Visit invoice.'),
                                    backgroundColor: const Color(0xFF0284C7),
                                    duration: const Duration(seconds: 6),
                                    action: SnackBarAction(
                                      label: 'Upload Invoice',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        _showGenerateInvoiceModal(context, lead, InvoiceType.siteVisit);
                                      },
                                    ),
                                  ),
                                );
                              } else if (stage == LeadStage.booked) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Status updated to Booked! You can now upload the Booked invoice.'),
                                    backgroundColor: const Color(0xFF16A34A),
                                    duration: const Duration(seconds: 6),
                                    action: SnackBarAction(
                                      label: 'Upload Invoice',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        _showGenerateInvoiceModal(context, lead, InvoiceType.booking);
                                      },
                                    ),
                                  ),
                                );
                              }
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

                    // 3. UNIFIED LEAD DETAILS CONTENT
                    _buildLeadInformationCard(lead, isDark),
                    const SizedBox(height: 16),
                    _buildStatusAndTemperatureCard(lead, isDark, tempColor),
                    const SizedBox(height: 16),
                    _buildSiteVisitHistoryCard(lead, isDark),
                    const SizedBox(height: 16),
                    _buildInvoicesAndCommissionsCard(lead, isDark),
                    const SizedBox(height: 16),
                    _buildNotesCard(lead, isDark),
                    const SizedBox(height: 16),
                    _buildActivityTimelineCard(lead, isDark),
                    const SizedBox(height: 16),
                    _buildUpdateStatusCard(lead, isDark),
                    const SizedBox(height: 20),
                    PoweredByBranding(isDark: isDark),
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
    final firstLetter = lead.firstName.trim().isNotEmpty ? lead.firstName.trim()[0].toUpperCase() : 'L';
    final secondLetter = lead.lastName.trim().isNotEmpty && lead.lastName.trim().toLowerCase() != 'client'
        ? lead.lastName.trim()[0].toUpperCase()
        : '';
    final avatarInitials = '$firstLetter$secondLetter'.trim();

    final avatarColors = [
      const Color(0xFF2563EB), // Blue
      const Color(0xFF7C3AED), // Purple
      const Color(0xFF0D9488), // Teal
      const Color(0xFFEA580C), // Orange
      const Color(0xFF0284C7), // Sky
      const Color(0xFF16A34A), // Emerald
    ];
    final avatarBgColor = avatarColors[lead.id.hashCode.abs() % avatarColors.length];

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar with Star, Name, Temperature Badge, Channel Partner Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Initials Avatar with Temperature Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: avatarBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              avatarInitials.isNotEmpty ? avatarInitials : 'L',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
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
                            child: Center(
                              child: Icon(
                                lead.stage == LeadStage.booked
                                    ? Icons.star_rounded
                                    : (lead.stage == LeadStage.siteVisited
                                        ? Icons.verified_rounded
                                        : Icons.person_rounded),
                                color: avatarBgColor,
                                size: 13,
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
              ],
            ),
          ),
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
    String siteVisitText = 'Pending';
    if (lead.stage == LeadStage.siteVisited) {
      siteVisitText = 'Completed';
    } else if (lead.stage == LeadStage.booked) {
      siteVisitText = 'Deal Booked';
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
                child: InkWell(
                  onTap: () => _showStatusPicker(context, lead),
                  borderRadius: BorderRadius.circular(14),
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

  // 7. SITE VISIT HISTORY CARD (Rich Zero-OTP verification & schedule action)
  Widget _buildSiteVisitHistoryCard(LeadModel lead, bool isDark) {
    final visits = widget.state.siteVisits
        .where((v) => v.leadId == lead.id)
        .toList();
    final rawHistory = lead.siteVisitHistory;
    final totalCount = visits.length + rawHistory.length;

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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.location_on_rounded, color: Color(0xFF2563EB), size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Site Visit History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (totalCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: () => _openScheduleVisit(lead),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 3),
                      Text(
                        'Schedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (visits.isEmpty && rawHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 32,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No site visits recorded yet for this client',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _openScheduleVisit(lead),
                      icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF2563EB)),
                      label: const Text(
                        'Schedule First Visit',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...visits.map((v) => _buildSiteVisitItem(v, isDark)),
            ...rawHistory.map((item) {
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
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 16, color: Color(0xFF818CF8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSiteVisitItem(SiteVisitModel visit, bool isDark) {
    Color statusColor;
    Color statusBg;
    switch (visit.status.toUpperCase()) {
      case 'COMPLETED':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFDCFCE7);
        break;
      case 'CHECKED_IN':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        break;
      case 'CANCELLED':
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
        break;
      default: // SCHEDULED
        statusColor = const Color(0xFF2563EB);
        statusBg = const Color(0xFFDBEAFE);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17202F) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF28364D) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.apartment_rounded, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        visit.projectName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  visit.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 13, color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B)),
              const SizedBox(width: 5),
              Text(
                _formatActivityDate(visit.scheduledAt),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PASS: ${visit.visitCode}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                  ),
                ),
              ),
              if (visit.accompanying)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'With Partner',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4338CA),
                    ),
                  ),
                ),
              if (visit.cabRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '🚖 Cab Requested',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
            ],
          ),
          if (visit.salesRepName != null && visit.salesRepName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Attended by: ${visit.salesRepName}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
              ),
            ),
          ],
          if (visit.feedback != null && visit.feedback!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      visit.feedback!,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  // 6. INVOICES & COMMISSION CLAIMS CARD (Type 1 & Type 2)
  Widget _buildInvoicesAndCommissionsCard(LeadModel lead, bool isDark) {
    final invoices = widget.state.getInvoicesForLead(lead.id);

    // Eligibility check
    // Type 1 (Site Visit): Unlocked ONLY if status is siteVisited or booked
    final isType1Eligible = lead.stage == LeadStage.siteVisited || lead.stage == LeadStage.booked;

    // Type 2 (Booking): Unlocked ONLY if status is booked
    final isType2Eligible = lead.stage == LeadStage.booked;

    final hasSiteVisitInvoice = invoices.any((inv) => inv.type == InvoiceType.siteVisit);
    final hasBookingInvoice = invoices.any((inv) => inv.type == InvoiceType.booking);

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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Invoices & Commission Claims',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              if (invoices.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${invoices.length} Generated',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Eligibility Helper Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF182232) : AppColors.lightSurfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF28364D) : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isType2Eligible
                      ? Icons.check_circle_rounded
                      : (isType1Eligible ? Icons.info_outline_rounded : Icons.lock_outline_rounded),
                  size: 15,
                  color: isType2Eligible
                      ? const Color(0xFF10B981)
                      : (isType1Eligible ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isType2Eligible
                        ? 'Status is BOOKED: Both Site Visit and Booked invoices are unlocked!'
                        : (isType1Eligible
                            ? 'Status is SITE VISITED: Site Visit Invoice is unlocked! (Booked invoice unlocks when status is changed to Booked).'
                            : 'Status is COLD: Change status to Site Visited or Booked in lead details to upload invoices.'),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2 Invoices Generation Action Tiles
          // Type 1: Site Visit Invoice Action Tile
          _buildInvoiceActionTile(
            title: '1. Site Visit Invoice (Type 1)',
            subtitle: 'Claim partner travel & client escort payout',
            icon: Icons.tour_rounded,
            color: const Color(0xFF38BDF8),
            isEligible: isType1Eligible,
            hasGenerated: hasSiteVisitInvoice,
            onClaim: () => _showGenerateInvoiceModal(context, lead, InvoiceType.siteVisit),
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // Type 2: Booking Commission Invoice Action Tile
          _buildInvoiceActionTile(
            title: '2. Booking Commission Invoice (Type 2)',
            subtitle: 'Claim full deal closure brokerage / success fee',
            icon: Icons.real_estate_agent_rounded,
            color: const Color(0xFF10B981),
            isEligible: isType2Eligible,
            hasGenerated: hasBookingInvoice,
            onClaim: () => _showGenerateInvoiceModal(context, lead, InvoiceType.booking),
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Invoices Generated for this Lead List
          if (invoices.isNotEmpty) ...[
            Text(
              'Generated Invoices for this Lead',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...invoices.map((inv) => _buildLeadInvoiceItem(inv, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isEligible,
    required bool hasGenerated,
    required VoidCallback onClaim,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17202F) : AppColors.lightSurfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEligible
              ? color.withValues(alpha: 0.35)
              : (isDark ? const Color(0xFF28364D) : AppColors.lightBorder),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEligible ? color.withValues(alpha: 0.15) : (isDark ? const Color(0xFF1E283A) : Colors.grey.shade200),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: isEligible ? color : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isEligible
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isEligible)
            ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                visualDensity: VisualDensity.compact,
                elevation: 0,
              ),
              child: Text(
                hasGenerated ? '+ Add Another' : 'Upload & Claim',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
              ),
            )
          else
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      title.contains('Booking')
                          ? 'Change status to "Booked" to unlock Booked invoice upload.'
                          : 'Change status to "Site Visited" to unlock Site Visit invoice upload.',
                    ),
                    backgroundColor: const Color(0xFFF59E0B),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Locked',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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

  Widget _buildLeadInvoiceItem(CommissionInvoiceModel inv, bool isDark) {
    final isSiteVisit = inv.type == InvoiceType.siteVisit;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182232) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF28364D) : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        onTap: () => _showInvoiceReceiptModal(context, inv),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSiteVisit ? Icons.tour_rounded : Icons.real_estate_agent_rounded,
                size: 14,
                color: isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        inv.invoiceNumber,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${inv.type.shortLabel})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatActivityDate(inv.date)} • A/C: •••• ${inv.bankDetails.accountNumber.length > 4 ? inv.bankDetails.accountNumber.substring(inv.bankDetails.accountNumber.length - 4) : inv.bankDetails.accountNumber}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${inv.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 2),
                _buildInvoiceStatusPill(inv.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceStatusPill(InvoiceStatus status) {
    Color color;
    switch (status) {
      case InvoiceStatus.pending:
        color = const Color(0xFFF59E0B);
        break;
      case InvoiceStatus.approved:
        color = const Color(0xFF38BDF8);
        break;
      case InvoiceStatus.paid:
        color = const Color(0xFF10B981);
        break;
      case InvoiceStatus.rejected:
        color = const Color(0xFFEF4444);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  // Invoice Generation Modal with Sequential Upload Document -> Enter Amount Flow
  void _showGenerateInvoiceModal(BuildContext context, LeadModel lead, InvoiceType type) {
    final isDark = widget.state.isDarkMode;
    final isSiteVisit = type == InvoiceType.siteVisit;

    // Amount begins empty: User uploads document first, then types/chooses amount
    final defaultSuggestedAmount = isSiteVisit ? '3000' : '150000';
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController(
      text: isSiteVisit
          ? 'Site visit escort and presentation completed for ${lead.fullName} at ${lead.projectName}.'
          : 'Brokerage commission claim on deal closure for ${lead.fullName} (${lead.projectName}).',
    );

    // Bank Details from saved state
    final savedBank = widget.state.savedBankDetails ??
        BankDetailsModel(
          accountHolder: widget.state.currentUser?.firmName ?? lead.firstName,
          bankName: 'HDFC Bank Ltd',
          accountNumber: '50100492817263',
          ifscCode: 'HDFC0001234',
          upiId: 'partner@okhdfcbank',
        );

    final holderCtrl = TextEditingController(text: savedBank.accountHolder);
    final bankCtrl = TextEditingController(text: savedBank.bankName);
    final accCtrl = TextEditingController(text: savedBank.accountNumber);
    final ifscCtrl = TextEditingController(text: savedBank.ifscCode);
    final upiCtrl = TextEditingController(text: savedBank.upiId ?? '');

    final presetAmounts = isSiteVisit
        ? ['1500', '2500', '3000', '5000']
        : ['75000', '100000', '150000', '200000', '250000'];

    PickedDocument? attachedDoc;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF131A26) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDocUploaded = attachedDoc != null;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
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
                  // Title Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSiteVisit ? Icons.tour_rounded : Icons.real_estate_agent_rounded,
                              color: isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload & Claim ${type.shortLabel}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                '${lead.fullName} • ${lead.projectName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
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

                  // STEP 1: UPLOAD INVOICE DOCUMENT / PROOF (REQUIRED FIRST)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDocUploaded
                          ? const Color(0xFF10B981).withValues(alpha: 0.08)
                          : (isDark ? const Color(0xFF0F172A) : AppColors.lightSurfaceSubtle),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDocUploaded
                            ? const Color(0xFF10B981)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        width: isDocUploaded ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDocUploaded
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isDocUploaded ? 'STEP 1 ✓ DONE' : 'STEP 1 • UPLOAD FIRST',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isSiteVisit
                                    ? 'Site Visit Invoice Document *'
                                    : 'Booked Invoice Document *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isDocUploaded
                              ? '✓ Attached: ${attachedDoc!.fileName} (${(attachedDoc!.sizeBytes / 1024).toStringAsFixed(1)} KB)'
                              : (isSiteVisit
                                  ? 'Upload site visit pass, client visitor register sheet, or sales gallery selfie photo first.'
                                  : 'Upload signed builder booking sheet, token advance receipt, or customer allotment form first.'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isDocUploaded ? FontWeight.w700 : FontWeight.w500,
                            color: isDocUploaded
                                ? const Color(0xFF10B981)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final doc = await DocumentPickerService.pickDocumentFromCamera();
                                  if (doc != null) {
                                    setModalState(() {
                                      attachedDoc = doc;
                                      if (amountCtrl.text.isEmpty) {
                                        amountCtrl.text = defaultSuggestedAmount;
                                      }
                                    });
                                  }
                                },
                                icon: const Icon(Icons.camera_alt_outlined, size: 15),
                                label: Text(
                                  isDocUploaded ? 'Retake Photo' : 'Camera',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(
                                    color: isDocUploaded
                                        ? const Color(0xFF10B981)
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final doc = await DocumentPickerService.pickDocumentFromGallery();
                                  if (doc != null) {
                                    setModalState(() {
                                      attachedDoc = doc;
                                      if (amountCtrl.text.isEmpty) {
                                        amountCtrl.text = defaultSuggestedAmount;
                                      }
                                    });
                                  }
                                },
                                icon: const Icon(Icons.photo_library_outlined, size: 15),
                                label: Text(
                                  isDocUploaded ? 'Change File' : 'Upload File / Gallery',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(
                                    color: isDocUploaded
                                        ? const Color(0xFF10B981)
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // STEP 2: ENTER CLAIM AMOUNT (₹) - Gated on Step 1
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDocUploaded ? const Color(0xFF10B981) : Colors.grey.shade500,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isDocUploaded ? 'STEP 2 • UNLOCKED' : 'STEP 2 • LOCKED',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Claim Amount (₹) *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDocUploaded
                              ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: amountCtrl,
                    enabled: isDocUploaded,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDocUploaded
                          ? const Color(0xFF10B981)
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.currency_rupee_rounded,
                        color: isDocUploaded ? const Color(0xFF10B981) : Colors.grey,
                      ),
                      hintText: isDocUploaded
                          ? 'Enter claim amount in ₹ (e.g. $defaultSuggestedAmount)'
                          : 'Upload document above in Step 1 first',
                      helperText: isDocUploaded
                          ? '✓ Document uploaded. Type or adjust your claim amount.'
                          : '🔒 Amount entry is locked until the invoice document is uploaded above.',
                      helperStyle: TextStyle(
                        fontSize: 11,
                        color: isDocUploaded
                            ? const Color(0xFF10B981)
                            : (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706)),
                        fontWeight: FontWeight.w600,
                      ),
                      filled: !isDocUploaded,
                      fillColor: !isDocUploaded
                          ? (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100)
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick preset chips (Only clickable when doc is uploaded)
                  if (isDocUploaded)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: presetAmounts.map((amt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () {
                                setModalState(() {
                                  amountCtrl.text = amt;
                                });
                              },
                              child: Chip(
                                label: Text('₹$amt'),
                                backgroundColor: isDark ? const Color(0xFF1E283A) : Colors.grey.shade100,
                                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 18),

                  // 3. BANK DETAILS SECTION
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Settlement Bank Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confirm or update where the builder should credit this commission.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: holderCtrl,
                    decoration: const InputDecoration(labelText: 'Account Holder / Firm Name *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bankCtrl,
                    decoration: const InputDecoration(labelText: 'Bank Name *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: accCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Account Number *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ifscCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'IFSC Code *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: upiCtrl,
                    decoration: const InputDecoration(labelText: 'UPI ID (Optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Claim Remarks / Unit Details (Optional)',
                      hintText: 'e.g. Unit 401 Tower B booking token verified',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // OK / SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // GATING CHECK 1: Document MUST be uploaded first
                        if (attachedDoc == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please upload the invoice document in Step 1 first before submitting.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        // GATING CHECK 2: Amount entered after uploading
                        final amt = double.tryParse(amountCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid claim amount greater than ₹0.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        // GATING CHECK 3: Bank details
                        if (holderCtrl.text.trim().isEmpty ||
                            bankCtrl.text.trim().isEmpty ||
                            accCtrl.text.trim().isEmpty ||
                            ifscCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all mandatory bank account fields.')),
                          );
                          return;
                        }

                        final bank = BankDetailsModel(
                          accountHolder: holderCtrl.text.trim(),
                          bankName: bankCtrl.text.trim(),
                          accountNumber: accCtrl.text.trim(),
                          ifscCode: ifscCtrl.text.trim().toUpperCase(),
                          upiId: upiCtrl.text.trim().isNotEmpty ? upiCtrl.text.trim() : null,
                        );

                        final remarks = notesCtrl.text.trim();
                        final finalNotes = remarks.isNotEmpty
                            ? '$remarks [Proof: ${attachedDoc!.fileName}]'
                            : '[Proof: ${attachedDoc!.fileName}]';

                        final createdInv = widget.state.submitCommissionInvoice(
                          leadId: lead.id,
                          type: type,
                          amount: amt,
                          bankDetails: bank,
                          notes: finalNotes,
                        );

                        Navigator.of(ctx).pop();
                        setState(() {});

                        // Show Success Snackbar and Open Digital Voucher Receipt
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('${type.shortLabel} submitted successfully! (Inv #${createdInv.invoiceNumber})'),
                          ),
                        );

                        _showInvoiceReceiptModal(context, createdInv);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981), // Emerald OK Button
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'OK • Submit ${type.shortLabel}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
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

  // Digital Voucher / Receipt Preview Modal
  void _showInvoiceReceiptModal(BuildContext context, CommissionInvoiceModel invoice) {
    final isDark = widget.state.isDarkMode;
    final isSiteVisit = invoice.type == InvoiceType.siteVisit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF131A26) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSiteVisit ? Icons.tour_rounded : Icons.real_estate_agent_rounded,
                          color: isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            invoice.type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                            ),
                          ),
                        ],
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

              // Digital Voucher Card Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF182232) : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF28364D) : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Claim Amount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${invoice.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        _buildInvoiceStatusPill(invoice.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    _buildReceiptRowItem('Client Name', invoice.clientName, isDark),
                    const SizedBox(height: 8),
                    _buildReceiptRowItem('Client Phone', invoice.clientPhone, isDark),
                    const SizedBox(height: 8),
                    _buildReceiptRowItem('Project', invoice.projectName, isDark),
                    const SizedBox(height: 8),
                    _buildReceiptRowItem('Claim Date', _formatActivityDate(invoice.date), isDark),
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildReceiptRowItem('Remarks', invoice.notes!, isDark),
                    ],
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    Text(
                      'Settlement Destination Bank',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReceiptRowItem('A/C Holder', invoice.bankDetails.accountHolder, isDark),
                    const SizedBox(height: 6),
                    _buildReceiptRowItem('Bank', invoice.bankDetails.bankName, isDark),
                    const SizedBox(height: 6),
                    _buildReceiptRowItem('Account No', invoice.bankDetails.accountNumber, isDark),
                    const SizedBox(height: 6),
                    _buildReceiptRowItem('IFSC', invoice.bankDetails.ifscCode, isDark),
                    if (invoice.bankDetails.upiId != null && invoice.bankDetails.upiId!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildReceiptRowItem('UPI ID', invoice.bankDetails.upiId!, isDark),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF4F46E5),
                            content: Text('Downloading digital invoice PDF for ${invoice.invoiceNumber}...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('Sharing invoice voucher ${invoice.invoiceNumber} with builder accounts desk...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share Voucher'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRowItem(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

