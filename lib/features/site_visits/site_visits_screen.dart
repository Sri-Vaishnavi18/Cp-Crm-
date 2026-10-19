import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/services/url_action_service.dart';
import '../../shared/widgets/powered_by_branding.dart';

class SiteVisitsScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onOpenSchedule;
  final VoidCallback? onBack;

  const SiteVisitsScreen({
    super.key,
    required this.state,
    required this.onOpenSchedule,
    this.onBack,
  });

  @override
  State<SiteVisitsScreen> createState() => _SiteVisitsScreenState();
}

class _SiteVisitsScreenState extends State<SiteVisitsScreen> {
  String _selectedTab = 'Upcoming'; // Upcoming (2), Completed (1), Cancelled

  void _showQrPassModal(BuildContext context, SiteVisitModel visit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildPassModalSheet(context, visit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;

    final upcomingVisits = widget.state.siteVisits
        .where((v) => v.status == 'SCHEDULED')
        .toList();
    final completedVisits = widget.state.siteVisits
        .where((v) => v.status == 'COMPLETED' || v.status == 'CHECKED_IN')
        .toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header (Back arrow + Visits + Calendar icon + "+ Schedule" blue pill button)
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
                    'Visits',
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
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF475569),
                    ),
                    onPressed: widget.onOpenSchedule,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: widget.onOpenSchedule,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      'Schedule',
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

            // 2. Sub-navigation Tabs: Upcoming (2), Completed (1), Cancelled
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildSubTabPill('Upcoming (${upcomingVisits.length})', 'Upcoming', isDark),
                  const SizedBox(width: 8),
                  _buildSubTabPill('Completed (${completedVisits.length})', 'Completed', isDark),
                  const SizedBox(width: 8),
                  _buildSubTabPill('Cancelled', 'Cancelled', isDark),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. Visits List Grouped by Date
            Expanded(
              child: _selectedTab == 'Completed'
                  ? _buildCompletedList(completedVisits, isDark)
                  : (_selectedTab == 'Cancelled'
                      ? _buildEmptyState('No cancelled visits', isDark)
                      : _buildUpcomingGroupedList(upcomingVisits, isDark)),
            ),
            PoweredByBranding(isDark: isDark, padding: const EdgeInsets.symmetric(vertical: 8)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabPill(String title, String tabKey, bool isDark) {
    final isSelected = _selectedTab == tabKey;

    return InkWell(
      onTap: () => setState(() => _selectedTab = tabKey),
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

  Widget _buildUpcomingGroupedList(List<SiteVisitModel> visits, bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Group 1 Header: Today • 10 Oct 2026
        _buildDateGroupHeader('Today • 10 Oct 2026', isDark),
        const SizedBox(height: 8),

        // Visit 1: Rahul Kumar (Oct 10 date box, 09:30 AM >)
        _buildVisitItem(
          context: context,
          clientName: 'Rahul Kumar',
          projectName: 'My Home Avatar',
          detailsText: '3 BHK • Site Visit',
          timeDisplay: '09:30 AM',
          phone: '9811223344',
          leadingType: _LeadingType.dateBox,
          isDark: isDark,
          onTap: () {
            final v = visits.isNotEmpty ? visits.first : null;
            if (v != null) _showQrPassModal(context, v);
          },
        ),
        const SizedBox(height: 12),

        // Visit 2: Priya Sharma (Award/ribbon icon leading, 11:00 AM >)
        _buildVisitItem(
          context: context,
          clientName: 'Priya Sharma',
          projectName: 'Rajapushpa',
          detailsText: '2 BHK • Site Visit',
          timeDisplay: '11:00 AM',
          phone: '9944556677',
          leadingType: _LeadingType.iconBox,
          isDark: isDark,
          onTap: () {
            final v = visits.length > 1 ? visits[1] : (visits.isNotEmpty ? visits.first : null);
            if (v != null) _showQrPassModal(context, v);
          },
        ),
        const SizedBox(height: 16),

        // Group 2 Header: Tomorrow • 11 Oct 2026
        _buildDateGroupHeader('Tomorrow • 11 Oct 2026', isDark),
        const SizedBox(height: 8),

        // Visit 3: Amit Verma (Avatar photo, 10:00 AM >)
        _buildVisitItem(
          context: context,
          clientName: 'Amit Verma',
          projectName: 'Prestige Sunshine',
          detailsText: '3 BHK • Site Visit',
          timeDisplay: '10:00 AM',
          phone: '9766554433',
          leadingType: _LeadingType.avatarPhoto,
          avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&q=80',
          isDark: isDark,
          onTap: () {
            final v = visits.length > 2 ? visits[2] : (visits.isNotEmpty ? visits.first : null);
            if (v != null) _showQrPassModal(context, v);
          },
        ),
      ],
    );
  }

  Widget _buildCompletedList(List<SiteVisitModel> visits, bool isDark) {
    if (visits.isEmpty) {
      return _buildEmptyState('No completed visits yet', isDark);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _buildDateGroupHeader('Today • 10 Oct 2026', isDark),
        const SizedBox(height: 8),
        _buildVisitItem(
          context: context,
          clientName: 'Amit Verma',
          projectName: 'Prestige Sunshine',
          detailsText: '3 BHK • Site Visit Completed',
          timeDisplay: '02:30 PM',
          phone: '9766554433',
          leadingType: _LeadingType.dateBox,
          isDark: isDark,
          onTap: () => _showQrPassModal(context, visits.first),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildDateGroupHeader(String text, bool isDark) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitItem({
    required BuildContext context,
    required String clientName,
    required String projectName,
    required String detailsText,
    required String timeDisplay,
    required String phone,
    required _LeadingType leadingType,
    required bool isDark,
    required VoidCallback onTap,
    String? avatarUrl,
  }) {
    // Leading Widget
    Widget leadingWidget;
    if (leadingType == _LeadingType.dateBox) {
      leadingWidget = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Oct',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
            ),
            Text(
              '10',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
          ],
        ),
      );
    } else if (leadingType == _LeadingType.iconBox) {
      leadingWidget = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFCE7F3),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.workspace_premium_outlined,
          color: Color(0xFF7C3AED),
          size: 22,
        ),
      );
    } else {
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          avatarUrl ?? 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&q=80',
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 44,
            height: 44,
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            alignment: Alignment.center,
            child: const Icon(Icons.person, color: Color(0xFF2563EB)),
          ),
        ),
      );
    }

    return Container(
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
          // Row 1: Leading + Info + Time with chevron
          InkWell(
            onTap: onTap,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leadingWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        projectName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        detailsText,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeDisplay,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row 2: Action Buttons (Call, WhatsApp, Navigate)
          Row(
            children: [
              // Call Button (Green)
              Expanded(
                child: _buildVisitActionButton(
                  icon: Icons.phone_rounded,
                  iconColor: const Color(0xFF16A34A),
                  label: 'Call',
                  textColor: const Color(0xFF16A34A),
                  onTap: () => UrlActionService.makePhoneCall(context, phone),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // WhatsApp Button (Green)
              Expanded(
                child: _buildVisitActionButton(
                  icon: Icons.chat_rounded,
                  iconColor: const Color(0xFF16A34A),
                  label: 'WhatsApp',
                  textColor: const Color(0xFF16A34A),
                  onTap: () => UrlActionService.openWhatsApp(
                    context,
                    phoneNumber: phone,
                    message: 'Hello $clientName, looking forward to your site visit at $projectName scheduled for $timeDisplay.',
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // Navigate Button (Blue)
              Expanded(
                child: _buildVisitActionButton(
                  icon: Icons.navigation_rounded,
                  iconColor: const Color(0xFF2563EB),
                  label: 'Navigate',
                  textColor: const Color(0xFF2563EB),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening GPS route for $projectName...')),
                    );
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitActionButton({
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

  // QR Pass Modal Sheet
  Widget _buildPassModalSheet(BuildContext context, SiteVisitModel visit) {
    final isDark = widget.state.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Digital Gate Entry Pass',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            visit.projectName,
            style: const TextStyle(fontSize: 14, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: QrImageView(
              data: 'CP_CRM:PASS:${visit.id}:${visit.clientName}:${visit.projectName}',
              version: QrVersions.auto,
              size: 160.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Client: ${visit.clientName}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Pass Code: ${visit.visitCode}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Close Pass', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

enum _LeadingType {
  dateBox,
  iconBox,
  avatarPhoto,
}
