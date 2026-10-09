import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/services/url_action_service.dart';
import '../site_visits/site_visits_screen.dart';
import 'lead_detail_screen.dart';

class LeadsScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onOpenAddLead;

  const LeadsScreen({
    super.key,
    required this.state,
    required this.onOpenAddLead,
  });

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final _searchController = TextEditingController();
  String _selectedStage = 'ALL';
  String _selectedTemperature = 'ALL';
  String _selectedDateRange = 'ALL';
  String _selectedProject = 'ALL';

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.state.leadSearchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openLeadCreation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddLeadModalSheet(state: widget.state),
    );
  }

  void _showLeadDetailSheet(BuildContext context, LeadModel lead) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => LeadDetailScreen(state: widget.state, leadId: lead.id),
      ),
    );
  }

  void _openScheduleVisit(LeadModel lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ScheduleVisitModalSheet(state: widget.state, preselectedLeadId: lead.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final leads = widget.state.filteredLeads;
    final totalCount = widget.state.allLeads.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C1017) : AppColors.lightBg,
      body: Column(
        children: [
          // Top Header & Search Area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row with "+ New Lead" Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Lead Pipeline',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
                                ),
                                child: const Icon(Icons.trending_up, color: AppColors.primary, size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Manage and track your prospects efficiently',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // + New Lead Button
                    ElevatedButton.icon(
                      onPressed: _openLeadCreation,
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: const Text(
                        'New Lead',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        minimumSize: const Size(0, 38),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search Box
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2433) : AppColors.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2D3C52) : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => widget.state.setLeadSearch(val),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search leads, projects, owners...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF6E7E95) : AppColors.lightTextMuted,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: isDark ? const Color(0xFF8A9BB2) : AppColors.lightTextMuted,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                widget.state.setLeadSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Multi-Filter Dropdown Pills Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Date Range Filter Dropdown
                      _buildDropdownFilter(
                        icon: Icons.calendar_today_outlined,
                        label: _selectedDateRange == 'ALL' ? 'Date Range' : _selectedDateRange,
                        value: _selectedDateRange,
                        items: const ['ALL', 'Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days'],
                        labels: const {
                          'ALL': 'All Dates',
                          'Today': 'Today',
                          'Yesterday': 'Yesterday',
                          'Last 7 Days': 'Last 7 Days',
                          'Last 30 Days': 'Last 30 Days',
                        },
                        onChanged: (val) {
                          setState(() => _selectedDateRange = val);
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),

                      // Temperature Filter Dropdown
                      _buildDropdownFilter(
                        icon: Icons.local_fire_department_outlined,
                        label: _selectedTemperature == 'ALL'
                            ? 'All Temperatures'
                            : (_selectedTemperature == 'HOT'
                                ? '🔥 Hot Leads'
                                : _selectedTemperature == 'WARM'
                                    ? '☀️ Warm Leads'
                                    : '❄️ Cold Leads'),
                        value: _selectedTemperature,
                        items: const ['ALL', 'HOT', 'WARM', 'COLD'],
                        labels: const {
                          'ALL': 'All Temperatures',
                          'HOT': '🔥 Hot Leads',
                          'WARM': '☀️ Warm Leads',
                          'COLD': '❄️ Cold Leads',
                        },
                        onChanged: (val) {
                          setState(() => _selectedTemperature = val);
                          widget.state.setLeadFilters(temperature: val == 'ALL' ? 'ALL' : val);
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),

                      // Status / Stage Filter Dropdown
                      _buildDropdownFilter(
                        icon: Icons.alt_route,
                        label: _selectedStage == 'ALL' ? 'All Status' : _selectedStage,
                        value: _selectedStage,
                        items: const ['ALL', 'NEW', 'CONTACTED', 'VISIT SCHEDULED', 'VISIT COMPLETED', 'TOKEN / BOOKED', 'LOST'],
                        labels: const {
                          'ALL': 'All Statuses',
                          'NEW': 'New Lead',
                          'CONTACTED': 'Contacted',
                          'VISIT SCHEDULED': 'Visit Scheduled',
                          'VISIT COMPLETED': 'Visit Done',
                          'TOKEN / BOOKED': 'Token / Booked',
                          'LOST': 'Lost',
                        },
                        onChanged: (val) {
                          setState(() => _selectedStage = val);
                          widget.state.setLeadFilters(stage: val == 'ALL' ? 'ALL' : val);
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),

                      // Project Filter Dropdown
                      _buildDropdownFilter(
                        icon: Icons.apartment,
                        label: _selectedProject == 'ALL' ? 'All Projects' : _getProjectShortName(_selectedProject),
                        value: _selectedProject,
                        items: ['ALL', ...widget.state.projects.map((p) => p.id)],
                        labels: {
                          'ALL': 'All Projects',
                          for (final p in widget.state.projects) p.id: p.name,
                        },
                        onChanged: (val) {
                          setState(() => _selectedProject = val);
                          widget.state.setLeadFilters(project: val == 'ALL' ? 'ALL' : val);
                        },
                        isDark: isDark,
                      ),

                      if (_selectedStage != 'ALL' || _selectedTemperature != 'ALL' || _selectedProject != 'ALL' || _searchController.text.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Reset Filters',
                          icon: const Icon(Icons.refresh, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedStage = 'ALL';
                              _selectedTemperature = 'ALL';
                              _selectedDateRange = 'ALL';
                              _selectedProject = 'ALL';
                              _searchController.clear();
                            });
                            widget.state.resetLeadFilters();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Offline Queue Banner (if any offline leads)
          if (widget.state.offlineQueueCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.warning.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.state.offlineQueueCount} lead(s) saved in offline queue. Exclusivity timer running locally.',
                      style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.state.syncOfflineQueue,
                    child: const Text('Sync Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Leads List Area
          Expanded(
            child: leads.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: (isDark ? const Color(0xFF1E293B) : AppColors.lightSurfaceSubtle),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people_outline,
                            size: 48,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matching leads found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try clearing search or filter constraints, or register a new prospect.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _openLeadCreation,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add New Lead'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(160, 42),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    itemCount: leads.length,
                    itemBuilder: (context, index) {
                      final lead = leads[index];
                      return _buildModernLeadCard(context, lead, isDark);
                    },
                  ),
          ),

          // Bottom Pagination Bar (Matches Reference Image)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111722) : AppColors.lightSurface,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Items: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B2433) : AppColors.lightSurfaceSubtle,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2D3C52) : AppColors.lightBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '100',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 18),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    Text(
                      '1-${leads.length} of $totalCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 18),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProjectShortName(String projectId) {
    final proj = widget.state.projects.where((p) => p.id == projectId).firstOrNull;
    if (proj == null) return 'Project';
    return proj.name.length > 14 ? '${proj.name.substring(0, 14)}...' : proj.name;
  }

  Widget _buildDropdownFilter({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required Map<String, String> labels,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    final isFiltered = value != 'ALL';
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isFiltered
            ? AppColors.primary.withValues(alpha: 0.15)
            : (isDark ? const Color(0xFF1B2433) : AppColors.lightSurfaceSubtle),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFiltered
              ? AppColors.primary
              : (isDark ? const Color(0xFF2D3C52) : AppColors.lightBorder),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: isFiltered
                ? AppColors.primary
                : (isDark ? const Color(0xFF8A9BB2) : AppColors.lightTextSecondary),
          ),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w600,
            color: isFiltered
                ? (isDark ? Colors.indigo.shade200 : AppColors.primary)
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: isFiltered
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF8A9BB2) : AppColors.lightTextMuted),
                  ),
                  const SizedBox(width: 6),
                  Text(labels[item] ?? item),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Modern Lead Card (Matches Reference Image UI)
  Widget _buildModernLeadCard(BuildContext context, LeadModel lead, bool isDark) {
    // Left border accent color by temperature
    Color tempAccentColor;
    switch (lead.temperature) {
      case LeadTemperature.hot:
        tempAccentColor = const Color(0xFFEF4444); // Red/Hot
        break;
      case LeadTemperature.warm:
        tempAccentColor = const Color(0xFFF59E0B); // Amber/Warm
        break;
      case LeadTemperature.cold:
        tempAccentColor = const Color(0xFF0EA5E9); // Cyan/Cold
        break;
    }

    // Site visit status for this lead
    final hasCompletedVisit = widget.state.siteVisits.any(
      (v) => v.leadId == lead.id && v.status == 'COMPLETED',
    );
    final hasScheduledVisit = widget.state.siteVisits.any(
      (v) => v.leadId == lead.id && v.status == 'SCHEDULED',
    );
    final String siteVisitStatusText = hasCompletedVisit
        ? 'Completed'
        : hasScheduledVisit
            ? 'Scheduled'
            : (lead.stage == LeadStage.visitScheduled ? 'Scheduled' : 'Pending');

    final String createdDateText = '${_monthName(lead.createdAt.month)} ${lead.createdAt.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF243042) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                color: tempAccentColor,
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _showLeadDetailSheet(context, lead),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badge & Exclusivity Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Temperature Badge (e.g., ☀️ Warm Lead / 🔥 Hot Lead)
                    Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: tempAccentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: tempAccentColor.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                lead.temperature.labelWithEmoji,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: tempAccentColor,
                                ),
                              ),
                            ),

                            // Source & Exclusivity Badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E2838) : AppColors.lightSurfaceSubtle,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lead.source,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                                if (lead.isQueuedOffline) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'OFFLINE',
                                      style: TextStyle(fontSize: 9, color: AppColors.warning, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Client Name & Contact Info
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                lead.firstName.isNotEmpty ? lead.firstName[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lead.fullName,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '+91 ${lead.phone}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      if (lead.email != null && lead.email!.isNotEmpty) ...[
                                        Text(' • ', style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                                        Expanded(
                                          child: Text(
                                            lead.email!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                        const SizedBox(height: 14),

                        // Horizontal Divider
                        Divider(
                          color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
                          height: 1,
                          thickness: 1,
                        ),
                        const SizedBox(height: 14),

                        // 4-Metric Data Grid (TEMPERATURE, STATUS, SITE VISIT, CREATED)
                        Row(
                          children: [
                            // 1. Temperature
                            Expanded(
                              child: _buildMetricTile(
                                label: 'TEMPERATURE',
                                value: lead.temperature.shortLabelWithEmoji,
                                iconColor: tempAccentColor,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 2. Status
                            Expanded(
                              child: _buildMetricTile(
                                label: 'STATUS',
                                value: lead.stage.displayName,
                                icon: Icons.check_circle_outline,
                                iconColor: const Color(0xFF38BDF8),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 3. Site Visit
                            Expanded(
                              child: _buildMetricTile(
                                label: 'SITE VISIT',
                                value: siteVisitStatusText,
                                icon: Icons.location_on_outlined,
                                iconColor: hasCompletedVisit ? AppColors.success : const Color(0xFFF59E0B),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 4. Created
                            Expanded(
                              child: _buildMetricTile(
                                label: 'CREATED',
                                value: createdDateText,
                                icon: Icons.calendar_today_outlined,
                                iconColor: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Visual Interactive 5-Step Pipeline Progress Stepper
                        _buildPipelineProgressStepper(lead, isDark),
                        const SizedBox(height: 14),

                        // Horizontal Divider
                        Divider(
                          color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
                          height: 1,
                          thickness: 1,
                        ),
                        const SizedBox(height: 12),

                        // Project Info + Quick Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lead.projectName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${lead.budget} • ${lead.configurations.join(", ")}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Call Action
                            IconButton.filledTonal(
                              onPressed: () => UrlActionService.makePhoneCall(context, lead.phone),
                              icon: const Icon(Icons.call, size: 16),
                              tooltip: 'Call Client',
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.lightSurfaceSubtle,
                                foregroundColor: AppColors.primary,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 4),

                            // WhatsApp Action
                            IconButton.filled(
                              onPressed: () {
                                final msg = 'Hello ${lead.firstName}, this is ${widget.state.currentUser?.name} from ${widget.state.currentUser?.firmName}. Sharing updates regarding your interest in ${lead.projectName}.';
                                UrlActionService.openWhatsApp(context, phoneNumber: lead.phone, message: msg);
                              },
                              icon: const Icon(Icons.chat, size: 16),
                              tooltip: 'WhatsApp Client',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.whatsapp,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Schedule Visit Action
                            IconButton.filledTonal(
                              onPressed: () => _openScheduleVisit(lead),
                              icon: const Icon(Icons.calendar_month_outlined, size: 16),
                              tooltip: 'Schedule Visit Pass',
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.lightSurfaceSubtle,
                                foregroundColor: const Color(0xFFF59E0B),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    IconData? icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192230) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF27354A) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF7E8EA4) : AppColors.lightTextMuted,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: iconColor),
                const SizedBox(width: 3),
              ],
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5-Step Pipeline Stepper (Lead Created -> Contacted -> Site Visit -> Negotiation -> Booked)
  Widget _buildPipelineProgressStepper(LeadModel lead, bool isDark) {
    final stages = [
      'Lead Created',
      'Contacted',
      'Site Visit',
      'Negotiation',
      'Booked',
    ];

    final currentStep = lead.pipelineStepIndex; // 0 to 4
    final activeColor = const Color(0xFFF59E0B); // Vibrant Golden Amber
    final inactiveColor = isDark ? const Color(0xFF2D3C52) : const Color(0xFFCBD5E1);

    return Column(
      children: [
        // Stepper Nodes and Connecting Lines
        Row(
          children: List.generate(stages.length * 2 - 1, (index) {
            if (index % 2 == 0) {
              // Node Circle
              final nodeIndex = index ~/ 2;
              final isPassedOrCurrent = nodeIndex <= currentStep;
              return Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPassedOrCurrent ? activeColor : Colors.transparent,
                  border: Border.all(
                    color: isPassedOrCurrent ? activeColor : inactiveColor,
                    width: 2.5,
                  ),
                  boxShadow: isPassedOrCurrent
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isPassedOrCurrent && nodeIndex < currentStep
                    ? const Icon(Icons.check, size: 9, color: Colors.black87)
                    : null,
              );
            } else {
              // Line Segment
              final lineIndex = index ~/ 2;
              final isFilled = lineIndex < currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: isFilled ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 6),

        // Step Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stages.asMap().entries.map((entry) {
            final idx = entry.key;
            final label = entry.value;
            final isCurrent = idx == currentStep;
            final isPassed = idx < currentStep;

            return Expanded(
              child: Text(
                label,
                textAlign: idx == 0
                    ? TextAlign.left
                    : idx == stages.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w800 : (isPassed ? FontWeight.w600 : FontWeight.w500),
                  color: isCurrent
                      ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                      : (isPassed
                          ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                          : (isDark ? const Color(0xFF62738A) : AppColors.lightTextMuted)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1).clamp(0, 11)];
  }
}

// ---------------------------------------------------------------------------
// 2-Part Segregated "Lead Creation" Modal Sheet
// Part 1: Basic Info (Name, Email, Phone)
// Part 2: Project & Lead Details (Project, Source, Temperature, Budget, Timeline)
// ---------------------------------------------------------------------------
class AddLeadModalSheet extends StatefulWidget {
  final AppState state;

  const AddLeadModalSheet({super.key, required this.state});

  @override
  State<AddLeadModalSheet> createState() => _AddLeadModalSheetState();
}

class _AddLeadModalSheetState extends State<AddLeadModalSheet> {
  final _formKey = GlobalKey<FormState>();

  // Part 1: Basic Info Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();

  // Part 2: Project & Lead Details
  late String _selectedProjectId;
  String _selectedSource = 'Digital Ads';
  LeadTemperature _selectedTemperature = LeadTemperature.cold;
  String _selectedBudget = '₹80 Lakhs - ₹1.2 Cr';
  String _selectedTimeline = 'Immediate (<15 days)';
  final List<String> _selectedConfigs = ['2 BHK', '3 BHK'];
  final _notesController = TextEditingController();

  final List<String> _sources = [
    'Digital Ads',
    'Walk-in',
    'Referral',
    'Social Media',
    'Channel Partner',
    'Cold Calling',
    'Website Inquiry',
    'Property Expo',
  ];

  final List<String> _budgets = [
    '₹50L - ₹80L',
    '₹80 Lakhs - ₹1.2 Cr',
    '₹1.2 Cr - ₹2 Cr',
    '₹2 Cr+',
  ];

  final List<String> _configs = [
    '1 BHK',
    '2 BHK',
    '3 BHK',
    '4 BHK Luxury',
    'Penthouse',
    'Villa / Plot',
  ];

  final List<String> _timelines = [
    'Immediate (<15 days)',
    '1 Month',
    '3 Months',
    'Exploring',
  ];

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.state.projects.first.id;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitLead() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter client phone number')),
      );
      return;
    }

    // Algorithmic Zero-OTP Duplicate Exclusivity Check
    final dupCheck = widget.state.checkLeadDuplicate(rawPhone);
    if (dupCheck.isDuplicate) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
              SizedBox(width: 8),
              Text('Duplicate Exclusivity Conflict', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text(
            dupCheck.message ?? 'This phone number is already actively protected in the CP pipeline.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final project = widget.state.projects.firstWhere(
      (p) => p.id == _selectedProjectId,
      orElse: () => widget.state.projects.first,
    );

    widget.state.addLead(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty ? 'Client' : _lastNameController.text.trim(),
      phone: rawPhone,
      altPhone: _altPhoneController.text.trim().isEmpty ? null : _altPhoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      budget: _selectedBudget,
      configurations: _selectedConfigs.isEmpty ? ['2 BHK'] : _selectedConfigs,
      projectId: project.id,
      projectName: project.name,
      timeline: _selectedTimeline,
      notes: _notesController.text.trim(),
      temperature: _selectedTemperature,
      source: _selectedSource,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.verified, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lead "${_firstNameController.text}" registered with 60-day Zero-OTP exclusivity!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle Pill
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

              // Headline: Lead Creation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lead Creation',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Register prospect with algorithmic exclusivity protection',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1),
                    ),
                    child: const Text(
                      'ZERO-OTP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ==========================================================
              // PART 1: BASIC INFO (Name, Email, Phone)
              // ==========================================================
              _buildSectionHeader(
                stepNumber: '1',
                title: 'Basic Info',
                subtitle: 'Primary client contact details',
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2433) : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2B3A4F) : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Name Columns (First Name & Last Name)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            textCapitalization: TextCapitalization.words,
                            validator: (val) => val == null || val.trim().isEmpty ? 'First name required' : null,
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              hintText: 'e.g. Ramesh',
                              prefixIcon: Icon(Icons.person_outline, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              hintText: 'e.g. Kumar',
                              prefixIcon: Icon(Icons.person_outline, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'e.g. client@domain.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Primary Phone Number Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Primary phone is required';
                        final clean = val.replaceAll(RegExp(r'[^\d]'), '');
                        if (clean.length < 10) return 'Enter a valid 10-digit mobile number';
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Primary Phone Number (10 Digits) *',
                        hintText: '9876543210',
                        prefixText: '+91 ',
                        prefixIcon: Icon(Icons.phone_outlined, size: 18),
                        helperText: 'Duplicate check runs algorithmically without SMS OTP friction.',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Optional Alt Phone
                    TextFormField(
                      controller: _altPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Alternate Phone (Optional)',
                        hintText: 'e.g. 9811002233',
                        prefixIcon: Icon(Icons.phone_iphone_outlined, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ==========================================================
              // PART 2: PROJECT & LEAD DETAILS (Project, Source, Temperature, etc.)
              // ==========================================================
              _buildSectionHeader(
                stepNumber: '2',
                title: 'Project & Lead Details',
                subtitle: 'Select project, source, temperature & preferences',
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2433) : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2B3A4F) : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Select Project Dropdown
                    Text(
                      'Select Project *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProjectId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.apartment_outlined, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: widget.state.projects.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            p.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedProjectId = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Source Dropdown
                    Text(
                      'Lead Source *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSource,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.hub_outlined, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: _sources.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSource = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Temperature of the Leads (Hot, Warm, Cold)
                    Text(
                      'Temperature of the Lead *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTemperatureOption(
                          temperature: LeadTemperature.hot,
                          label: 'Hot Lead',
                          iconEmoji: '🔥',
                          color: const Color(0xFFEF4444),
                          subtext: 'High Intent / Ready',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildTemperatureOption(
                          temperature: LeadTemperature.warm,
                          label: 'Warm Lead',
                          iconEmoji: '☀️',
                          color: const Color(0xFFF59E0B),
                          subtext: 'Site Visit Ready',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildTemperatureOption(
                          temperature: LeadTemperature.cold,
                          label: 'Cold Lead',
                          iconEmoji: '❄️',
                          color: const Color(0xFF0EA5E9),
                          subtext: 'Early Exploration',
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. Budget Range Selector
                    Text(
                      'Budget Range',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _budgets.map((b) {
                        final isSelected = _selectedBudget == b;
                        return ChoiceChip(
                          label: Text(b, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _selectedBudget = b),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 5. Preferred Configurations
                    Text(
                      'Preferred Configurations',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _configs.map((c) {
                        final isSelected = _selectedConfigs.contains(c);
                        return FilterChip(
                          label: Text(c, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedConfigs.add(c);
                              } else {
                                _selectedConfigs.remove(c);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 6. Timeline
                    Text(
                      'Expected Purchase Timeline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _timelines.map((t) {
                        final isSelected = _selectedTimeline == t;
                        return ChoiceChip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _selectedTimeline = t),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 7. Client Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Requirements & Specific Notes',
                        hintText: 'e.g., East facing, Higher floor, Vastu compliant entrance',
                        prefixIcon: Icon(Icons.notes, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _submitLead,
                icon: const Icon(Icons.lock_outline, size: 18),
                label: const Text(
                  'Create Lead (Zero-OTP Protected)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemperatureOption({
    required LeadTemperature temperature,
    required String label,
    required String iconEmoji,
    required Color color,
    required String subtext,
    required bool isDark,
  }) {
    final isSelected = _selectedTemperature == temperature;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTemperature = temperature),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : (isDark ? const Color(0xFF131A26) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : (isDark ? const Color(0xFF2C394C) : AppColors.lightBorder),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(iconEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 8,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comprehensive Lead Detail Sheet
// Displays all lead info, pipeline stepper, temperature changer, visit status, and quick actions
// ---------------------------------------------------------------------------
class LeadDetailSheet extends StatefulWidget {
  final AppState state;
  final LeadModel lead;

  const LeadDetailSheet({super.key, required this.state, required this.lead});

  @override
  State<LeadDetailSheet> createState() => _LeadDetailSheetState();
}

class _LeadDetailSheetState extends State<LeadDetailSheet> {
  late LeadStage _currentStage;
  late LeadTemperature _currentTemperature;

  @override
  void initState() {
    super.initState();
    _currentStage = widget.lead.stage;
    _currentTemperature = widget.lead.temperature;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final lead = widget.lead;

    Color tempColor;
    switch (_currentTemperature) {
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: SingleChildScrollView(
        child: Column(
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

            // Lead Profile Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                  child: Text(
                    lead.firstName.isNotEmpty ? lead.firstName[0].toUpperCase() : 'C',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.fullName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+91 ${lead.phone} ${lead.email != null && lead.email!.isNotEmpty ? "• ${lead.email}" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tempColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tempColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Text(
                    _currentTemperature.labelWithEmoji,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tempColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 60-Day RERA Exclusivity Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Locked under ${widget.state.currentUser?.firmName ?? "Your Firm"} (60-day protection active)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Pipeline Stage Transition Stepper & Selector
            Text(
              'Pipeline Stage Transition',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2433) : AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF2E3E54) : AppColors.lightBorder, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<LeadStage>(
                  isExpanded: true,
                  value: _currentStage,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  items: LeadStage.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.displayName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    );
                  }).toList(),
                  onChanged: (newStage) {
                    if (newStage != null) {
                      setState(() => _currentStage = newStage);
                      widget.state.updateLeadStage(lead.id, newStage);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Temperature Selector
            Text(
              'Update Lead Temperature',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: LeadTemperature.values.map((temp) {
                final isSelected = _currentTemperature == temp;
                Color chipColor;
                switch (temp) {
                  case LeadTemperature.hot:
                    chipColor = const Color(0xFFEF4444);
                    break;
                  case LeadTemperature.warm:
                    chipColor = const Color(0xFFF59E0B);
                    break;
                  case LeadTemperature.cold:
                    chipColor = const Color(0xFF0EA5E9);
                    break;
                }
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() => _currentTemperature = temp);
                        widget.state.updateLeadTemperature(lead.id, temp);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? chipColor.withValues(alpha: 0.2) : (isDark ? const Color(0xFF1B2433) : AppColors.lightSurfaceSubtle),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? chipColor : (isDark ? const Color(0xFF2E3E54) : AppColors.lightBorder),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            temp.labelWithEmoji,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? chipColor : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Detailed Information Grid
            _buildDetailSection(
              title: 'Project & Buying Requirements',
              items: [
                _DetailItem(label: 'PROJECT', value: lead.projectName),
                _DetailItem(label: 'BUDGET', value: lead.budget),
                _DetailItem(label: 'CONFIGURATIONS', value: lead.configurations.join(', ')),
                _DetailItem(label: 'PURCHASE TIMELINE', value: lead.timeline),
                _DetailItem(label: 'SOURCE', value: lead.source),
                _DetailItem(label: 'SPECIFIC NOTES', value: lead.notes.isEmpty ? 'None provided' : lead.notes),
              ],
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      UrlActionService.makePhoneCall(context, lead.phone);
                    },
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Call Client'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      final msg = 'Hello ${lead.firstName}, this is ${widget.state.currentUser?.name} from ${widget.state.currentUser?.firmName}. Sharing project details for ${lead.projectName}.';
                      UrlActionService.openWhatsApp(context, phoneNumber: lead.phone, message: msg);
                    },
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.whatsapp,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildDetailSection({
    required String title,
    required List<_DetailItem> items,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2433) : AppColors.lightSurfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF2E3E54) : AppColors.lightBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF7E8EA4) : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;

  _DetailItem({required this.label, required this.value});
}
