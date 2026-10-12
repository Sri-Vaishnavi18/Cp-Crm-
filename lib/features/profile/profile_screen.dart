import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../commissions/commissions_screen.dart';
import '../notifications/notifications_screen.dart';
import '../spoc_helpdesk/spoc_screen.dart';
import '../../shared/widgets/app_widgets.dart';

class ProfileScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback? onBack;

  const ProfileScreen({
    super.key,
    required this.state,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;
    final user = state.currentUser;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'Vaishu';
    final rera = user?.reraNumber.isNotEmpty == true ? user!.reraNumber : '0283838';
    final safeRera = rera.startsWith('RERA:') ? rera : 'RERA: $rera';
    final firmOrRole = user?.firmName.isNotEmpty == true ? user!.firmName : 'Channel Partner (Realtor)';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              size: 22,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => UserProfileModalSheet(state: state),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // User Hero Card (Gradient Blue)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'V',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          firmOrRole,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFBFDBFE),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          safeRera,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF93C5FD),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sync Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cloud_outlined,
                      color: Color(0xFF16A34A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Last synced 10 Oct 2026 • 09:40 AM',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Profile Menu List Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
                ),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    badgeText: '4',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => NotificationCenterScreen(state: state)),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.people_outline_rounded,
                    title: 'My Team',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Team management view active.')),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Commissions & Payouts',
                    badgeText: state.commissionPendingFormatted,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => CommissionsScreen(state: state, showBackButton: true)),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.bar_chart_rounded,
                    title: 'Performance',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => CommissionsScreen(state: state)),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.favorite_border_rounded,
                    title: 'Targets & Incentives',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => CommissionsScreen(state: state)),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => SpocHelpdeskScreen(state: state)),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'App Settings',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => UserProfileModalSheet(state: state),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: () => _confirmLogout(context),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    String? badgeText,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive
                  ? const Color(0xFFEF4444)
                  : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDestructive
                      ? const Color(0xFFEF4444)
                      : (isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A)),
                ),
              ),
            ),
            if (badgeText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (!isDestructive)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
      indent: 48,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of CP CRM?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await state.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
