import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/services/document_picker_service.dart';
import '../../core/state/app_state.dart';
import '../../features/commissions/commissions_screen.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback onThemeToggle;
  final bool isDark;
  final int unreadCount;
  final VoidCallback onNotificationTap;
  final bool isOffline;
  final VoidCallback onOfflineToggle;
  final VoidCallback? onProfileTap;
  final String? profileInitials;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBackButton = false,
    this.onBack,
    required this.onThemeToggle,
    required this.isDark,
    required this.unreadCount,
    required this.onNotificationTap,
    required this.isOffline,
    required this.onOfflineToggle,
    this.onProfileTap,
    this.profileInitials,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: isDark ? Colors.white : AppColors.lightTextPrimary),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
          ] else ...[
            InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.business_center, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Offline Simulation Badge Button
          InkWell(
            onTap: onOfflineToggle,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOffline ? AppColors.danger.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOffline ? AppColors.danger : AppColors.success,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOffline ? Icons.cloud_off : Icons.cloud_done,
                    size: 13,
                    color: isOffline ? AppColors.danger : AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOffline ? 'OFFLINE' : 'SYNCED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isOffline ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Dark/Light Theme Switch
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: isDark ? Colors.amber : AppColors.primary,
            ),
            onPressed: onThemeToggle,
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            visualDensity: VisualDensity.compact,
          ),
          // Notification Bell with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
                onPressed: onNotificationTap,
                visualDensity: VisualDensity.compact,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Profile Avatar Action
          if (onProfileTap != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.indigo.shade300 : AppColors.primary,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    profileInitials ?? 'CP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StatKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String subtext;
  final VoidCallback onTap;
  final Widget? secondaryGraphic;
  final IconData? secondaryIcon;

  const StatKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.subtext,
    required this.onTap,
    this.secondaryGraphic,
    this.secondaryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.05 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                if (secondaryGraphic != null)
                  secondaryGraphic!
                else if (secondaryIcon != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(secondaryIcon, color: accentColor.withValues(alpha: 0.85), size: 16),
                  )
                else
                  Icon(Icons.arrow_forward_ios, size: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ],
            ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 10,
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class PipelineFunnelBar extends StatelessWidget {
  final int newCount;
  final int contactedCount;
  final int visitFixedCount;
  final int visitDoneCount;
  final int bookedCount;

  const PipelineFunnelBar({
    super.key,
    required this.newCount,
    required this.contactedCount,
    required this.visitFixedCount,
    required this.visitDoneCount,
    required this.bookedCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = newCount + contactedCount + visitFixedCount + visitDoneCount + bookedCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pipeline Health',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                '$total Active Prospects',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Connected Stepper Progress Bar matching screenshot
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // Horizontal connecting gradient bar
              Positioned(
                top: 17,
                left: 20,
                right: 20,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6), // Blue
                        Color(0xFF8B5CF6), // Purple
                        Color(0xFFF59E0B), // Amber
                        Color(0xFF14B8A6), // Teal
                        Color(0xFF10B981), // Emerald
                      ],
                    ),
                  ),
                ),
              ),
              // 5 Circular Step Nodes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStepNode(
                    label: 'New',
                    count: '$newCount',
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                  ),
                  _buildStepNode(
                    label: 'Contacted',
                    count: '$contactedCount',
                    icon: contactedCount == 0 ? Icons.person : null,
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                  ),
                  _buildStepNode(
                    label: 'Visit Set',
                    count: '$visitFixedCount',
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                  ),
                  _buildStepNode(
                    label: 'Visit Done',
                    count: '$visitDoneCount',
                    color: const Color(0xFF14B8A6),
                    isDark: isDark,
                  ),
                  _buildStepNode(
                    label: 'Booked',
                    count: '$bookedCount',
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required String label,
    required String count,
    IconData? icon,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border.all(color: color, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 16, color: color)
                : Text(
                    count,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class DashboardLeadCard extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback onTap;
  final VoidCallback? onCall;

  const DashboardLeadCard({
    super.key,
    required this.lead,
    required this.onTap,
    this.onCall,
  });

  Color _getStageColor(LeadStage stage) {
    switch (stage) {
      case LeadStage.cold:
        return const Color(0xFF64748B); // Slate / Grey
      case LeadStage.siteVisited:
        return const Color(0xFF38BDF8); // Sky Blue
      case LeadStage.booked:
        return const Color(0xFF10B981); // Emerald
    }
  }

  String _getStageText(LeadStage stage) {
    switch (stage) {
      case LeadStage.cold:
        return 'COLD';
      case LeadStage.siteVisited:
        return 'SITE VISITED';
      case LeadStage.booked:
        return 'BOOKED';
    }
  }

  String _formatLeadTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $ampm';

    if (date == today) {
      return 'Today $timeStr';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday $timeStr';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stageColor = _getStageColor(lead.stage);
    final stageText = _getStageText(lead.stage);

    final initials = lead.firstName.isNotEmpty
        ? (lead.firstName[0] + (lead.lastName.isNotEmpty ? lead.lastName[0] : '')).toUpperCase()
        : 'LP';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with Initials
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        stageColor.withValues(alpha: 0.8),
                        stageColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name & Project Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              lead.fullName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Stage Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: stageColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: stageColor.withValues(alpha: 0.4), width: 1),
                            ),
                            child: Text(
                              stageText,
                              style: TextStyle(
                                color: stageColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.apartment_rounded,
                            size: 13,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${lead.projectName} • ${_formatLeadTime(lead.createdAt)}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Bottom Metadata and Action link
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          lead.configurations.join(', '),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•  ${lead.budget}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Lead Details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right, size: 14, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class UserProfileModalSheet extends StatelessWidget {
  final AppState state;

  const UserProfileModalSheet({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    final user = state.currentUser;
    final savedUsers = state.savedUsers;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Profile Header Card
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user?.name ?? 'Channel Partner',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, size: 16, color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.firmName ?? 'Real Estate Brokerage',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.indigo.shade200 : AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user?.isAgency == true ? 'AGENCY FIRM' : 'INDIVIDUAL REALTOR',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Profile Metadata Details Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.verified_user_outlined,
                    'RERA Registration',
                    user?.reraNumber ?? 'N/A',
                    isDark,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    Icons.phone_outlined,
                    'Mobile Number',
                    '+91 ${user?.phone ?? ""}',
                    isDark,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    Icons.email_outlined,
                    'Email Address',
                    user?.email ?? 'N/A',
                    isDark,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    'Operating Location',
                    user?.city ?? 'Bangalore, Karnataka',
                    isDark,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    Icons.storage_outlined,
                    'Storage Status',
                    'Device-Local Database (Encrypted Session)',
                    isDark,
                    valueColor: AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // RERA & KYC Verification Document Scanner Tile
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161F2E) : AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryTeal.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.document_scanner_rounded, color: AppColors.primaryTeal, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RERA & Business KYC Verification',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload or scan state RERA certificate and agency GSTIN to maintain verified partner badge.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final doc = await DocumentPickerService.pickDocumentFromCamera();
                            if (doc != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.success,
                                  content: Text('Scanned "${doc.fileName}" (${(doc.sizeBytes / 1024).toStringAsFixed(1)} KB) successfully!'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.camera_alt_outlined, size: 14),
                          label: const Text('Scan Certificate', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.primaryTeal,
                            side: BorderSide(color: AppColors.primaryTeal.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final doc = await DocumentPickerService.pickDocumentFromGallery();
                            if (doc != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.success,
                                  content: Text('Uploaded "${doc.fileName}" (${(doc.sizeBytes / 1024).toStringAsFixed(1)} KB) successfully!'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.photo_library_outlined, size: 14),
                          label: const Text('Upload Photo', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.accentGold,
                            side: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Commissions & Invoices Tile
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => CommissionsScreen(state: state)),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161F2E) : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commissions & Invoices Ledger',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Track site visit payouts & deal closure brokerage',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF10B981)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Switch User Account Section (if multiple registered)
            if (savedUsers.length > 1) ...[
              Text(
                'Switch Channel Partner Account (${savedUsers.length} on this device)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              ...savedUsers.where((u) => u.id != user?.id).map((otherUser) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        otherUser.name.isNotEmpty ? otherUser.name[0] : 'P',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    title: Text(
                      '${otherUser.name} (${otherUser.firmName})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    subtitle: Text(
                      'RERA: ${otherUser.reraNumber.length > 20 ? "${otherUser.reraNumber.substring(0, 20)}..." : otherUser.reraNumber}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.swap_horiz, color: AppColors.primary),
                    onTap: () async {
                      await state.switchUser(otherUser.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text('Switched to ${otherUser.name} (${otherUser.firmName})'),
                          ),
                        );
                      }
                    },
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Logout Action Button
            ElevatedButton.icon(
              onPressed: () {
                _showLogoutConfirmDialog(context, state);
              },
              icon: const Icon(Icons.logout, size: 18, color: Colors.white),
              label: const Text('Sign Out from CP CRM', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.white54 : AppColors.lightTextSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Confirm Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out? Your registered profile remains saved on this device and you can sign back in anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).popUntil((route) => route.isFirst); // Close modal and all pushed routes back to root
              await state.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class ScheduleVisitModalSheet extends StatefulWidget {
  final AppState state;
  final String? preselectedLeadId;

  const ScheduleVisitModalSheet({super.key, required this.state, this.preselectedLeadId});

  @override
  State<ScheduleVisitModalSheet> createState() => _ScheduleVisitModalSheetState();
}

class _ScheduleVisitModalSheetState extends State<ScheduleVisitModalSheet> {
  late String _selectedLeadId;
  late String _selectedProjectId;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1, hours: 4));
  bool _cabRequired = false;
  bool _accompanying = true;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedLeadId != null && widget.state.allLeads.any((l) => l.id == widget.preselectedLeadId)) {
      _selectedLeadId = widget.preselectedLeadId!;
      final lead = widget.state.allLeads.firstWhere((l) => l.id == widget.preselectedLeadId);
      _selectedProjectId = lead.projectId;
    } else {
      _selectedLeadId = widget.state.allLeads.isNotEmpty ? widget.state.allLeads.first.id : '';
      _selectedProjectId = widget.state.projects.isNotEmpty ? widget.state.projects.first.id : '';
    }
  }

  void _submit() {
    final visitCode = widget.state.scheduleSiteVisit(
      leadId: _selectedLeadId,
      projectId: _selectedProjectId,
      scheduledAt: _selectedDateTime,
      cabRequired: _cabRequired,
      accompanying: _accompanying,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Visit $visitCode Scheduled! Digital QR Pass generated.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final dateFormat = DateFormat('EEE, d MMM • hh:mm a');

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Schedule Digital Site Visit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Text('Select Lead', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedLeadId,
            items: widget.state.allLeads.map((l) => DropdownMenuItem(value: l.id, child: Text('${l.fullName} (${l.phone})'))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedLeadId = val);
            },
          ),
          const SizedBox(height: 14),

          Text('Target Project', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedProjectId,
            items: widget.state.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedProjectId = val);
            },
          ),
          const SizedBox(height: 14),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: AppColors.primary),
            title: const Text('Visit Date & Time Slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(dateFormat.format(_selectedDateTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            trailing: TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (date != null && context.mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
                  }
                }
              },
              child: const Text('Change'),
            ),
          ),
          const SizedBox(height: 10),

          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Request Builder Cab Pickup for Client', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            value: _cabRequired,
            activeTrackColor: AppColors.primary,
            onChanged: (val) => setState(() => _cabRequired = val),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Broker Accompanying Client', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            value: _accompanying,
            activeTrackColor: AppColors.primary,
            onChanged: (val) => setState(() => _accompanying = val),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _submit,
            child: const Text('Generate Digital QR Entry Pass (Zero-OTP)', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Flip7 Design System Buttons & Action Tokens
// ==========================================

enum Flip7ButtonVariant { teal, sky, gold, coral }

class Flip7PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Flip7ButtonVariant variant;
  final VoidCallback onPressed;
  final double? height;
  final double? width;

  const Flip7PillButton({
    super.key,
    required this.label,
    this.icon,
    this.variant = Flip7ButtonVariant.teal,
    required this.onPressed,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (variant) {
      case Flip7ButtonVariant.teal:
        bg = AppColors.primaryTeal.withValues(alpha: 0.12);
        fg = AppColors.primaryTeal;
        break;
      case Flip7ButtonVariant.sky:
        bg = AppColors.skyBlue.withValues(alpha: 0.12);
        fg = AppColors.skyBlue;
        break;
      case Flip7ButtonVariant.gold:
        bg = AppColors.accentGold.withValues(alpha: 0.12);
        fg = AppColors.accentGold;
        break;
      case Flip7ButtonVariant.coral:
        bg = AppColors.coral.withValues(alpha: 0.12);
        fg = AppColors.coral;
        break;
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: height,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: height != null ? Alignment.center : null,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fg.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Flip7GoldCTAButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;
  final double? width;
  final bool isFullWidth;

  const Flip7GoldCTAButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.height,
    this.width,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: isFullWidth ? (width ?? double.infinity) : width,
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: Flip7Shadows.shadowGoldGlow,
      ),

      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: height != null ? 0 : 12,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 17, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}



