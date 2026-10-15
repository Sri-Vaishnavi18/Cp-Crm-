import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../commissions/commissions_screen.dart';
import '../../shared/widgets/date_filter_bar.dart';

class DashboardScreen extends StatelessWidget {
  final AppState state;
  final Function(int tabIndex) onNavigateTab;
  final VoidCallback onOpenAddLead;
  final VoidCallback onOpenScheduleVisit;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenSiteVisits;
  final VoidCallback? onOpenCollaterals;
  final VoidCallback? onOpenSpocHelpdesk;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenCommissions;
  final VoidCallback? onOpenDocs;
  final VoidCallback? onOpenInvoices;
  final Function(String filter)? onOpenLeadsWithFilter;

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
    this.onOpenNotifications,
    this.onOpenCommissions,
    this.onOpenDocs,
    this.onOpenInvoices,
    this.onOpenLeadsWithFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    final user = state.currentUser;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'Vaishu';
    final rera = user?.reraNumber.isNotEmpty == true ? user!.reraNumber : '0283838';
    final safeRera = rera.startsWith('RERA:') ? rera : 'RERA: $rera';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F7FB),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Custom App Bar (Briefcase + Vaishu + RERA + SYNCED + moon + bell + V avatar)
              _buildTopBar(context, userName, safeRera, isDark),
              const SizedBox(height: 12),

              // Date Filter Bar (Today, Yesterday, 7 Days, 30 Days, Manual Calendar, Reset)
              DateFilterBar(
                state: state,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 14),

              // 2. Lead Pipeline Analytics (Total Leads, Sitevisited Leads, Booked Leads)
              _buildLeadAnalyticsSection(context, isDark),
              const SizedBox(height: 16),

              // 4. Commission Financial 2x2 Grid (Commission Recieved, Commission Pending, Invoices, Total Commission Earned)
              _buildCommissionFinancialGrid(context, isDark),
              const SizedBox(height: 12),

              // 5. Settlement Destination Bank Card (Exact screenshot match)
              _buildSettlementBankCard(context, isDark),
              const SizedBox(height: 20),

              // 6. Pipeline Conversion Funnel
              _buildConversionFunnelSection(context, isDark),
              const SizedBox(height: 20),

              // 7. Brokerage & Revenue Performance Trajectory Graph
              _buildBrokeragePerformanceGraph(context, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Top Bar matching reference screenshot
  Widget _buildTopBar(BuildContext context, String userName, String safeRera, bool isDark) {
    return Row(
      children: [
        // Blue briefcase rounded container
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.business_center_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),

        // Name & RERA Number
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                safeRera,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // SYNCED pill badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_done_rounded, color: Color(0xFF16A34A), size: 12),
              SizedBox(width: 4),
              Text(
                'SYNCED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16A34A),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Dark mode moon icon
        IconButton(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
          ),
          onPressed: state.toggleTheme,
        ),

        // Notification Bell with red badge
        IconButton(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          icon: Badge(
            smallSize: 8,
            backgroundColor: const Color(0xFFEF4444),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 22,
              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
            ),
          ),
          onPressed: onOpenNotifications,
        ),
        const SizedBox(width: 4),

        // User Avatar "V"
        InkWell(
          onTap: onOpenProfile,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2563EB),
            ),
            alignment: Alignment.center,
            child: Text(
              userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'V',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }


  // Lead Pipeline Analytics: Total Leads, Sitevisited Leads, Booked Leads
  Widget _buildLeadAnalyticsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Color(0xFF4F46E5),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Lead Pipeline Analytics',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                if (onOpenLeadsWithFilter != null) {
                  onOpenLeadsWithFilter!('All');
                } else {
                  onNavigateTab(1);
                }
              },
              child: const Text(
                'View Leads →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3 Cards Row: Total Leads, Sitevisited Leads, Booked Leads
        Row(
          children: [
            // Card 1: Total Leads
            Expanded(
              child: _buildLeadMetricCard(
                context: context,
                icon: Icons.people_alt_rounded,
                iconBgColor: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4F46E5),
                trendText: 'Ingested',
                trendBgColor: const Color(0xFFEEF2FF),
                trendTextColor: const Color(0xFF4F46E5),
                value: '${state.totalLeadsCount}',
                label: 'Total Leads',
                subtext: 'Pipeline Leads',
                subtextColor: const Color(0xFF4F46E5),
                onTap: () {
                  if (onOpenLeadsWithFilter != null) {
                    onOpenLeadsWithFilter!('All');
                  } else {
                    onNavigateTab(1);
                  }
                },
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),

            // Card 2: Sitevisited Leads
            Expanded(
              child: _buildLeadMetricCard(
                context: context,
                icon: Icons.location_on_rounded,
                iconBgColor: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                trendText: 'Tours',
                trendBgColor: const Color(0xFFE0F2FE),
                trendTextColor: const Color(0xFF0284C7),
                value: '${state.siteVisitedLeadsCount}',
                label: 'Sitevisited Leads',
                subtext: 'Visits Done',
                subtextColor: const Color(0xFF0284C7),
                onTap: () {
                  if (onOpenLeadsWithFilter != null) {
                    onOpenLeadsWithFilter!('Site Visit');
                  } else {
                    onNavigateTab(1);
                  }
                },
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),

            // Card 3: Booked Leads
            Expanded(
              child: _buildLeadMetricCard(
                context: context,
                icon: Icons.workspace_premium_rounded,
                iconBgColor: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                trendText: 'Token Paid',
                trendBgColor: const Color(0xFFDCFCE7),
                trendTextColor: const Color(0xFF16A34A),
                value: '${state.bookedLeadsCount}',
                label: 'Booked Leads',
                subtext: 'Deals Closed',
                subtextColor: const Color(0xFF16A34A),
                onTap: () {
                  if (onOpenLeadsWithFilter != null) {
                    onOpenLeadsWithFilter!('Booked');
                  } else {
                    onNavigateTab(1);
                  }
                },
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeadMetricCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String trendText,
    required Color trendBgColor,
    required Color trendTextColor,
    required String value,
    required String label,
    required String subtext,
    required Color subtextColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: trendBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trendText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: trendTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: subtextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 2x2 Commission & Financial Analytics Cards
  Widget _buildCommissionFinancialGrid(BuildContext context, bool isDark) {
    final earned = AppState.formatCurrency(state.dashboardTotalCommissionEarned);
    final received = AppState.formatCurrency(state.dashboardPaidCommissionAmount);
    final pending = AppState.formatCurrency(state.dashboardPendingCommissionAmount);
    final totalInvoices = '${state.dashboardInvoicesCount} Invoices';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFF059669),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Commission & Financial Analytics',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: onOpenCommissions ?? () => onNavigateTab(4),
              child: const Text(
                'Ledger →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // Card 1: Commission Recieved
            Expanded(
              child: _buildFinancialMetricCard(
                title: 'Commission Recieved',
                value: received,
                valueColor: const Color(0xFF10B981),
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFFD1FAE5),
                isIconCircle: true,
                subtext: 'Disbursed to bank',
                onTap: onOpenCommissions ?? () => onNavigateTab(4),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),

            // Card 2: Commission Pending
            Expanded(
              child: _buildFinancialMetricCard(
                title: 'Commission Pending',
                value: pending,
                valueColor: const Color(0xFFF59E0B),
                icon: Icons.hourglass_top_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBgColor: const Color(0xFFFEF3C7),
                isIconCircle: true,
                subtext: 'In clearance queue',
                onTap: onOpenCommissions ?? () => onNavigateTab(4),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 3: Invoices
            Expanded(
              child: _buildFinancialMetricCard(
                title: 'Invoices',
                value: totalInvoices,
                valueColor: const Color(0xFF0284C7),
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBgColor: const Color(0xFFE0F2FE),
                isIconCircle: false,
                subtext: 'KYC & Payout Vouchers',
                onTap: onOpenInvoices ?? onOpenDocs ?? () => onNavigateTab(3),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),

            // Card 4: Total Commission Earned
            Expanded(
              child: _buildFinancialMetricCard(
                title: 'Total Commission Earned',
                value: earned,
                valueColor: const Color(0xFF6366F1),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF6366F1),
                iconBgColor: const Color(0xFFEDE9FE),
                isIconCircle: false,
                subtext: 'Lifetime brokerage',
                onTap: onOpenCommissions ?? () => onNavigateTab(4),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialMetricCard({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool isIconCircle,
    String? subtext,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: isIconCircle ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isIconCircle ? null : BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtext != null) ...[
              const SizedBox(height: 3),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Settlement Destination Bank matching the reference image with interactive Edit action
  Widget _buildSettlementBankCard(BuildContext context, bool isDark) {
    final bankName = state.savedBankDetails?.bankName ?? 'HDFC Bank Ltd';
    final displayBank = bankName.toLowerCase().contains('ltd') ? bankName : '$bankName Ltd';
    final acc = state.savedBankDetails?.accountNumber ?? '7263';
    final last4 = acc.length >= 4 ? acc.substring(acc.length - 4) : '7263';
    final ifsc = state.savedBankDetails?.ifscCode ?? 'HDFC0001234';
    final bankText = '$displayBank (•••• •••• $last4) • IFSC: $ifsc';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settlement Destination Bank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bankText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              CommissionsScreen.showEditBankModal(context, state);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pipeline Conversion Funnel Section
  Widget _buildConversionFunnelSection(BuildContext context, bool isDark) {
    final total = state.totalLeadsCount > 0 ? state.totalLeadsCount : 1;
    final cold = state.coldLeadsCount;
    final visited = state.siteVisitedLeadsCount;
    final booked = state.bookedLeadsCount;
    final winRate = state.totalLeadsCount > 0 ? ((booked / state.totalLeadsCount) * 100).toInt() : 0;

    final coldPct = (cold / total).clamp(0.0, 1.0);
    final coldLabel = '${(coldPct * 100).toStringAsFixed(0)}%';

    final visitedPct = (visited / total).clamp(0.0, 1.0);
    final visitedLabel = '${(visitedPct * 100).toStringAsFixed(0)}%';

    final bookedPct = (booked / total).clamp(0.0, 1.0);
    final bookedLabel = '${(bookedPct * 100).toStringAsFixed(0)}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.filter_alt_rounded,
                      color: Color(0xFF4F46E5),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pipeline Conversion Funnel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Lead qualification to closure velocity',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$winRate% Win Rate',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Funnel Stage 1: Cold Leads
          _buildFunnelStageItem(
            stageName: '1. Cold Leads',
            countText: '$cold Leads',
            percentage: coldPct > 0 ? coldPct : 0.2,
            percentLabel: coldLabel,
            gradientColors: [const Color(0xFF6366F1), const Color(0xFF818CF8)],
            dropOffText: '$visitedLabel progress to site visit',
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          // Funnel Stage 2: Site Visits Completed
          _buildFunnelStageItem(
            stageName: '2. Site Visited Leads',
            countText: '$visited Visited',
            percentage: visitedPct > 0 ? visitedPct : 0.2,
            percentLabel: visitedLabel,
            gradientColors: [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
            dropOffText: '$bookedLabel progress to booking',
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          // Funnel Stage 3: Booked & Commissioned
          _buildFunnelStageItem(
            stageName: '3. Booked Leads',
            countText: '$booked Closed Deals',
            percentage: bookedPct > 0 ? bookedPct : 0.2,
            percentLabel: bookedLabel,
            gradientColors: [const Color(0xFF059669), const Color(0xFF34D399)],
            dropOffText: null,
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // Funnel Summary Footnotes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161F2E) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFunnelMiniStat('Avg Cycle', '4.2 Days', const Color(0xFF2563EB), isDark),
                Container(width: 1, height: 24, color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                _buildFunnelMiniStat('Lead → Visit', '${(visitedPct * 100).toStringAsFixed(1)}%', const Color(0xFF0EA5E9), isDark),
                Container(width: 1, height: 24, color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                _buildFunnelMiniStat('Visit → Close', '${visited > 0 ? ((booked / visited) * 100).toStringAsFixed(1) : '0.0'}%', const Color(0xFF10B981), isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelMiniStat(String label, String value, Color valueColor, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFunnelStageItem({
    required String stageName,
    required String countText,
    required double percentage,
    required String percentLabel,
    required List<Color> gradientColors,
    required String? dropOffText,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              stageName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
              ),
            ),
            Row(
              children: [
                Text(
                  countText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: gradientColors[0].withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    percentLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: gradientColors[0],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth * percentage;
            return Container(
              height: 14,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.centerLeft,
              child: Container(
                width: barWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            );
          },
        ),
        if (dropOffText != null) ...[
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.south_rounded,
                  size: 11,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  dropOffText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Brokerage & Revenue Performance Trend Graph
  Widget _buildBrokeragePerformanceGraph(BuildContext context, bool isDark) {
    // 6-month data trajectory (May to Oct)
    final monthlyData = [
      {'month': 'MAY', 'settled': 15.0, 'pending': 40.0, 'current': false},
      {'month': 'JUN', 'settled': 25.0, 'pending': 60.0, 'current': false},
      {'month': 'JUL', 'settled': 40.0, 'pending': 85.0, 'current': false},
      {'month': 'AUG', 'settled': 30.0, 'pending': 110.0, 'current': false},
      {'month': 'SEP', 'settled': 50.0, 'pending': 140.0, 'current': false},
      {'month': 'OCT', 'settled': 6.0, 'pending': 188.0, 'current': true},
    ];
    const maxVal = 200.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF16A34A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Brokerage Trajectory',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '6-Month Settled vs Pending',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: onOpenCommissions ?? () => onNavigateTab(4),
                child: const Text(
                  'Ledger →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Legend Row
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(
                'Settled: ${AppState.formatCurrency(state.paidCommissionAmount)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(
                'Pending: ${AppState.formatCurrency(state.pendingCommissionAmount)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar Graph Canvas
          SizedBox(
            height: 135,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-axis markers
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹200K', style: TextStyle(fontSize: 9, color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8))),
                    Text('₹100K', style: TextStyle(fontSize: 9, color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8))),
                    Text('₹0', style: TextStyle(fontSize: 9, color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(width: 8),

                // Chart Bars Area
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: monthlyData.map((data) {
                      final settled = data['settled'] as double;
                      final pending = data['pending'] as double;
                      final isCurrent = data['current'] as bool;
                      final month = data['month'] as String;

                      final settledH = (settled / maxVal) * 78;
                      final pendingH = (pending / maxVal) * 78;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                AppState.formatCurrency(state.totalCommissionEarned),
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Settled Bar (Emerald)
                              Container(
                                width: 9,
                                height: settledH.clamp(4.0, 78.0),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                              ),
                              const SizedBox(width: 3),
                              // Pending Bar (Amber)
                              Container(
                                width: 9,
                                height: pendingH.clamp(4.0, 78.0),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            month,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                              color: isCurrent
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bottom Insight Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161F2E) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFBBF7D0),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_rounded, size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prestige Sunshine Sanctuary holds ₹1.50L in clearance queue.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF166534),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
