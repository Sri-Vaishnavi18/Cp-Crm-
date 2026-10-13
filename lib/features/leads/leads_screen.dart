import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/services/url_action_service.dart';
import 'lead_detail_screen.dart';
import '../../shared/widgets/app_widgets.dart';
export 'add_lead_modal.dart';

class LeadsScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onOpenAddLead;
  final VoidCallback? onBack;
  final String? initialFilter;

  const LeadsScreen({
    super.key,
    required this.state,
    required this.onOpenAddLead,
    this.onBack,
    this.initialFilter,
  });

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedFilter = 'All'; // All, New, Contacted, Site Visit, Booked, Hot
  String _sortFilter = 'Sort ▾';
  String _projectFilter = 'Project ▾';
  String _budgetFilter = 'Budget ▾';
  String _sourceFilter = 'Source ▾';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null && widget.initialFilter!.isNotEmpty) {
      _selectedFilter = widget.initialFilter!;
    }
    _searchController.text = widget.state.leadSearchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openScheduleVisit(LeadModel lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ScheduleVisitModalSheet(state: widget.state, preselectedLeadId: lead.id),
    );
  }

  void _navigateToDetail(LeadModel lead) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => LeadDetailScreen(state: widget.state, leadId: lead.id),
      ),
    );
  }

  List<LeadModel> _getFilteredLeads() {
    final all = widget.state.allLeads;
    final query = _searchController.text.trim().toLowerCase();

    return all.where((lead) {
      // Tab filter
      if (_selectedFilter == 'Cold') {
        if (lead.stage != LeadStage.cold) return false;
      } else if (_selectedFilter == 'Site Visited' || _selectedFilter == 'Site Visit') {
        if (lead.stage != LeadStage.siteVisited) return false;
      } else if (_selectedFilter == 'Booked') {
        if (lead.stage != LeadStage.booked) return false;
      }

      // Project filter
      if (_projectFilter != 'Project ▾') {
        final cleanProj = _projectFilter.replaceAll(' ▾', '').toLowerCase();
        if (!lead.projectName.toLowerCase().contains(cleanProj)) return false;
      }

      // Search query
      if (query.isNotEmpty) {
        final matchName = lead.fullName.toLowerCase().contains(query);
        final matchPhone = lead.phone.contains(query);
        final matchProj = lead.projectName.toLowerCase().contains(query);
        if (!matchName && !matchPhone && !matchProj) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final isDark = widget.state.isDarkMode;
        final leads = _getFilteredLeads();

        // Tab counts
        final allCount = widget.state.allLeads.length;
        final coldCount = widget.state.allLeads.where((l) => l.stage == LeadStage.cold).length;
        final siteVisitedCount = widget.state.allLeads.where((l) => l.stage == LeadStage.siteVisited).length;
        final bookedCount = widget.state.allLeads.where((l) => l.stage == LeadStage.booked).length;

        return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header (Back arrow + Leads + Search icon + "+ Add Lead" blue pill button)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                    onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Leads',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isSearching ? Icons.close_rounded : Icons.search_rounded,
                      size: 22,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF475569),
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                        }
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: widget.onOpenAddLead,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      'Add Lead',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar Input (if search toggled)
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by client name, project, phone...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF2563EB)),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0)),
                    ),
                  ),
                ),
              ),

            // 2. Top Filter Tabs: All, Cold, Site Visited, Booked
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildTabPill('All ($allCount)', 'All', isDark),
                  const SizedBox(width: 8),
                  _buildTabPill('Cold ($coldCount)', 'Cold', isDark),
                  const SizedBox(width: 8),
                  _buildTabPill('Site Visited ($siteVisitedCount)', 'Site Visited', isDark),
                  const SizedBox(width: 8),
                  _buildTabPill('Booked ($bookedCount)', 'Booked', isDark),
                ],
              ),
            ),

            // 3. Dropdown Filter Chips: Sort ▾, Project ▾, Budget ▾, Source ▾
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildDropdownChip(
                    label: _sortFilter,
                    options: ['Sort ▾', 'Newest First', 'Oldest First', 'Budget High-Low'],
                    onSelected: (val) => setState(() => _sortFilter = val),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownChip(
                    label: _projectFilter,
                    options: ['Project ▾', 'My Home Avatar', 'Prestige Sunshine', 'Rajapushpa', 'Aparna Zenon'],
                    onSelected: (val) => setState(() => _projectFilter = val),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownChip(
                    label: _budgetFilter,
                    options: ['Budget ▾', '< ₹75L', '₹75L - ₹1Cr', '> ₹1Cr'],
                    onSelected: (val) => setState(() => _budgetFilter = val),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownChip(
                    label: _sourceFilter,
                    options: ['Source ▾', 'Website', 'Meta Ads', 'Referral', 'Walk-in'],
                    onSelected: (val) => setState(() => _sourceFilter = val),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 4. Leads List
            Expanded(
              child: leads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No leads found matching filters',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: leads.length,
                      itemBuilder: (context, index) {
                        final lead = leads[index];
                        return _buildLeadCard(context, lead, index, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  // Segmented Pill Tab
  Widget _buildTabPill(String title, String filterKey, bool isDark) {
    final isSelected = _selectedFilter == filterKey;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // Dropdown Filter Chip
  Widget _buildDropdownChip({
    required String label,
    required List<String> options,
    required Function(String) onSelected,
    required bool isDark,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => options.map((opt) {
        return PopupMenuItem<String>(
          value: opt,
          child: Text(opt, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // Lead Card matching reference screenshot
  Widget _buildLeadCard(BuildContext context, LeadModel lead, int index, bool isDark) {
    // Dynamic status badge styling
    Color badgeBgColor;
    Color badgeTextColor;
    String badgeText;

    if (lead.stage == LeadStage.booked) {
      badgeText = 'BOOKED';
      badgeBgColor = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF16A34A);
    } else if (lead.stage == LeadStage.siteVisited) {
      badgeText = 'SITE VISITED';
      badgeBgColor = const Color(0xFFE0F2FE);
      badgeTextColor = const Color(0xFF0284C7);
    } else {
      badgeText = 'COLD';
      badgeBgColor = const Color(0xFFF1F5F9);
      badgeTextColor = const Color(0xFF64748B);
    }

    // Source icon & label
    IconData sourceIcon = Icons.language_rounded;
    String sourceLabel = lead.source.isNotEmpty ? lead.source : 'Website';
    if (sourceLabel.toLowerCase().contains('meta') || sourceLabel.toLowerCase().contains('ad')) {
      sourceIcon = Icons.campaign_rounded;
      sourceLabel = 'Meta Ads';
    } else if (sourceLabel.toLowerCase().contains('referral')) {
      sourceIcon = Icons.people_outline_rounded;
      sourceLabel = 'Referral';
    } else if (sourceLabel.toLowerCase().contains('walk')) {
      sourceIcon = Icons.directions_walk_rounded;
      sourceLabel = 'Walk-in';
    }

    // Relative timestamp display
    final timeDisplay = index == 0
        ? '2 days ago'
        : (index == 1 ? '1 day ago' : (index == 2 ? '3 days ago' : 'Today'));

    final bhk = lead.configurations.isNotEmpty ? lead.configurations.first : '3 BHK';
    final budget = lead.budget.isNotEmpty ? lead.budget : '₹85L';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Name & Info + Status Pill + 3-dots
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + Subtitle (BHK • Budget) + Project
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.fullName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$bhk • $budget',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      lead.projectName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // 3-dots Menu
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                ),
                onSelected: (val) {
                  if (val == 'view') {
                    _navigateToDetail(lead);
                  } else if (val == 'schedule') {
                    _openScheduleVisit(lead);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'view', child: Text('View Details')),
                  const PopupMenuItem(value: 'schedule', child: Text('Schedule Visit')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Metadata Row: Source & Timestamp
          Row(
            children: [
              Icon(sourceIcon, size: 14, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                sourceLabel,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                timeDisplay,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons: Call, WhatsApp, Schedule
          Row(
            children: [
              // Call Button
              Expanded(
                child: _buildLeadActionButton(
                  icon: Icons.phone_rounded,
                  iconColor: const Color(0xFF16A34A),
                  label: 'Call',
                  textColor: const Color(0xFF16A34A),
                  onTap: () => UrlActionService.makePhoneCall(context, lead.phone),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // WhatsApp Button
              Expanded(
                child: _buildLeadActionButton(
                  icon: Icons.chat_rounded,
                  iconColor: const Color(0xFF16A34A),
                  label: 'WhatsApp',
                  textColor: const Color(0xFF16A34A),
                  onTap: () => UrlActionService.openWhatsApp(
                    context,
                    phoneNumber: lead.phone,
                    message: 'Hello ${lead.fullName}, touching base regarding your inquiry for ${lead.projectName}.',
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // View Details Button (Replaces Schedule button)
              Expanded(
                child: _buildLeadActionButton(
                  icon: Icons.visibility_outlined,
                  iconColor: const Color(0xFF2563EB),
                  label: 'View Details',
                  textColor: const Color(0xFF2563EB),
                  onTap: () => _navigateToDetail(lead),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
