import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../shared/widgets/app_widgets.dart';
import '../leads/lead_detail_screen.dart';
import '../commissions/commissions_screen.dart';

class DashboardScreen extends StatelessWidget {
  final AppState state;
  final Function(int tabIndex) onNavigateTab;
  final VoidCallback onOpenAddLead;
  final VoidCallback onOpenScheduleVisit;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenSiteVisits;
  final VoidCallback? onOpenCollaterals;
  final VoidCallback? onOpenSpocHelpdesk;

  const DashboardScreen({
    super.key,
    required this.state,
    required this.onNavigateTab,
    required this.onOpenAddLead,
    required this.onOpenScheduleVisit,
    this.onOpenProfile,
    this.onOpenSiteVisits,
    this.onOpenCollaterals,
    this.onOpenSpocHelpdesk,
  });

  Future<void> _openCalendarPicker(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = state.customDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: initialRange,
      helpText: 'SELECT TIMELINE / DATE RANGE',
      cancelText: 'CANCEL',
      confirmText: 'APPLY FILTER',
      saveText: 'APPLY',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.darkSurface,
                    onSurface: Colors.white,
                    secondary: AppColors.secondary,
                  )
                : ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.lightTextPrimary,
                    secondary: AppColors.secondary,
                  ), dialogTheme: DialogThemeData(backgroundColor: isDark ? AppColors.darkBg : Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      state.setCustomDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome & Partner Badge Header
            InkWell(
              onTap: onOpenProfile ??
                  () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => UserProfileModalSheet(state: state),
                    );
                  },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            state.currentUser?.name ?? 'Vaishu',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 14, color: Color(0xFF6366F1)),
                        const SizedBox(width: 4),
                        Text(
                          state.currentUser?.isAgency == true ? 'AGENCY' : 'REALTOR',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6366F1),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date / Timeline Filter Bar
            _buildDateFilterBar(context, isDark),
            const SizedBox(height: 12),

            // Active Filter Notice / Pill (if filtered)
            if (state.isDateFilterActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filtered by: ${state.dateFilterLabel} (${state.dashboardLeads.length} leads, ${state.dashboardSiteVisits.length} visits)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => state.resetDashboardDateFilter(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh, size: 12, color: isDark ? Colors.white70 : AppColors.lightTextSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Quick Action Hub (1-Tap Field Utilities)
            _buildQuickActionsHub(context, isDark),
            const SizedBox(height: 16),

            // Analytics KPI Cards Grid (6 Cards: Leads, Visits, Bookings, Commissions)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: MediaQuery.sizeOf(context).width < 360
                  ? 1.05
                  : (MediaQuery.sizeOf(context).width > 600
                      ? 1.6
                      : (MediaQuery.textScalerOf(context).scale(1.0) > 1.15 ? 1.12 : 1.28)),
              children: [
                // 1. Active Leads Card
                StatKpiCard(
                  title: 'Active Leads',
                  value: '${state.activeLeadsCount}',
                  icon: Icons.groups_rounded,
                  accentColor: const Color(0xFF3B82F6), // Blue
                  secondaryGraphic: _buildBarChartGraphic(const Color(0xFF3B82F6)),
                  subtext: 'Zero-OTP protection locked',
                  onTap: () => onNavigateTab(1),
                ),

                // 2. Visits Scheduled Card
                StatKpiCard(
                  title: 'Visits Scheduled',
                  value: '${state.visitsScheduledCount}',
                  icon: Icons.calendar_month_rounded,
                  accentColor: const Color(0xFFF59E0B), // Amber / Orange
                  secondaryGraphic: _buildClockGraphic(const Color(0xFFF59E0B)),
                  subtext: 'Digital passes generated',
                  onTap: onOpenSiteVisits ?? () => onNavigateTab(1),
                ),

                // 3. Visits Completed Card
                StatKpiCard(
                  title: 'Visits Completed',
                  value: '${state.visitsCompletedCount}',
                  icon: Icons.fact_check_rounded,
                  accentColor: const Color(0xFF10B981), // Teal / Emerald
                  secondaryGraphic: _buildSealGraphic(const Color(0xFF10B981)),
                  subtext: 'Site tours completed',
                  onTap: onOpenSiteVisits ?? () => onNavigateTab(1),
                ),

                // 4. Bookings / Holds Card
                StatKpiCard(
                  title: 'Bookings / Holds',
                  value: '${state.bookingsCount}',
                  icon: Icons.military_tech_rounded,
                  accentColor: const Color(0xFF06B6D4), // Cyan
                  secondaryGraphic: _buildHandshakeGraphic(const Color(0xFF06B6D4)),
                  subtext: 'Deals closed / hold active',
                  onTap: () => onNavigateTab(1),
                ),

                // 5. Commission Pending Card
                StatKpiCard(
                  title: 'Commission Pending',
                  value: state.commissionPendingFormatted,
                  icon: Icons.hourglass_top_rounded,
                  accentColor: const Color(0xFFF43F5E), // Rose / Coral
                  secondaryGraphic: _buildPendingGraphic(const Color(0xFFF43F5E)),
                  subtext: 'Invoice in builder audit',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => CommissionsScreen(state: state),
                      ),
                    );
                  },
                ),

                // 6. Commission Received Card
                StatKpiCard(
                  title: 'Commission Received',
                  value: state.commissionReceivedFormatted,
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: const Color(0xFF8B5CF6), // Purple
                  secondaryGraphic: _buildReceivedGraphic(const Color(0xFF8B5CF6)),
                  subtext: 'Disbursed to RERA bank',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => CommissionsScreen(state: state),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Pipeline Health Stepper Card (Reacts to Date Filter)
            PipelineFunnelBar(
              newCount: state.funnelNewLeadsCount,
              contactedCount: state.funnelContactedCount,
              visitFixedCount: state.funnelVisitScheduledCount,
              visitDoneCount: state.funnelVisitCompletedCount,
              bookedCount: state.funnelBookingsCount,
            ),
            const SizedBox(height: 22),

            // Leads Section Header (Replaces Builder Announcements & Activity Stream)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Leads',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.dashboardLeads.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => onNavigateTab(1), // Jumps to Leads tab
                  icon: const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                  label: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Leads List with structured details
            if (state.dashboardLeads.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      size: 38,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No Leads in this Timeframe',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try choosing another date filter or reset to All Time.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => state.resetDashboardDateFilter(),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Reset Filter'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...state.dashboardLeads.map((lead) {
                return DashboardLeadCard(
                  lead: lead,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => LeadDetailScreen(state: state, leadId: lead.id),
                      ),
                    );
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  // Date Filter Bar Widget with Horizontal Scrolling Chips
  Widget _buildDateFilterBar(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Today Chip
          _buildFilterChip(
            label: 'Today',
            isSelected: state.dashboardDatePreset == DashboardDatePreset.today,
            isDark: isDark,
            onTap: () => state.setDashboardDatePreset(DashboardDatePreset.today),
          ),
          const SizedBox(width: 8),

          // Yesterday Chip
          _buildFilterChip(
            label: 'Yesterday',
            isSelected: state.dashboardDatePreset == DashboardDatePreset.yesterday,
            isDark: isDark,
            onTap: () => state.setDashboardDatePreset(DashboardDatePreset.yesterday),
          ),
          const SizedBox(width: 8),

          // 7 Days Chip
          _buildFilterChip(
            label: '7 Days',
            isSelected: state.dashboardDatePreset == DashboardDatePreset.last7Days,
            isDark: isDark,
            onTap: () => state.setDashboardDatePreset(DashboardDatePreset.last7Days),
          ),
          const SizedBox(width: 8),

          // 30 Days Chip
          _buildFilterChip(
            label: '30 Days',
            isSelected: state.dashboardDatePreset == DashboardDatePreset.last30Days,
            isDark: isDark,
            onTap: () => state.setDashboardDatePreset(DashboardDatePreset.last30Days),
          ),
          const SizedBox(width: 8),

          // Calendar Custom Range Picker Chip
          InkWell(
            onTap: () => _openCalendarPicker(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: state.dashboardDatePreset == DashboardDatePreset.custom
                    ? AppColors.primary
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: state.dashboardDatePreset == DashboardDatePreset.custom
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 15,
                    color: state.dashboardDatePreset == DashboardDatePreset.custom
                        ? Colors.white
                        : (isDark ? Colors.white70 : AppColors.lightTextPrimary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    state.dashboardDatePreset == DashboardDatePreset.custom ? state.dateFilterLabel : 'Calendar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: state.dashboardDatePreset == DashboardDatePreset.custom
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppColors.lightTextPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reset / All Time Button
          if (state.isDateFilterActive) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => state.resetDashboardDateFilter(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 14, color: isDark ? Colors.white60 : Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  // Right-side Mini Illustrations for Stat Cards
  Widget _buildBarChartGraphic(Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(width: 3, height: 8, decoration: BoxDecoration(color: color.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 2),
          Container(width: 3, height: 14, decoration: BoxDecoration(color: color.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 2),
          Container(width: 3, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  Widget _buildClockGraphic(Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.alarm_on_rounded, size: 18, color: color),
    );
  }

  Widget _buildSealGraphic(Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.verified_rounded, size: 18, color: color),
    );
  }

  Widget _buildHandshakeGraphic(Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.handshake_rounded, size: 18, color: color),
    );
  }

  Widget _buildPendingGraphic(Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.schedule_send_rounded, size: 18, color: color),
    );
  }

  Widget _buildReceivedGraphic(Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check_circle_rounded, size: 18, color: color),
    );
  }

  Widget _buildQuickActionsHub(BuildContext context, bool isDark) {
    final actions = [
      _QuickActionItem(
        label: '+ Add Lead',
        icon: Icons.person_add_alt_1_rounded,
        color: AppColors.primary,
        onTap: onOpenAddLead,
      ),
      _QuickActionItem(
        label: '📅 Visit',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFFF59E0B),
        onTap: onOpenScheduleVisit,
      ),
      _QuickActionItem(
        label: '🎟️ Passes',
        icon: Icons.qr_code_rounded,
        color: const Color(0xFF10B981),
        onTap: onOpenSiteVisits ?? () => onNavigateTab(1),
      ),
      _QuickActionItem(
        label: '📤 Share Kit',
        icon: Icons.send_to_mobile_rounded,
        color: const Color(0xFF0284C7),
        onTap: onOpenCollaterals ?? () => onNavigateTab(2),
      ),
      _QuickActionItem(
        label: '🏢 Projects',
        icon: Icons.apartment_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () => onNavigateTab(2),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((item) {
          return InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
