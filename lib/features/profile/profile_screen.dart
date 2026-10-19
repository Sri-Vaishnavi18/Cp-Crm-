import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../commissions/commissions_screen.dart';
import '../docs/docs_screen.dart';
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
    final userName = user?.name.isNotEmpty == true ? user!.name : 'Channel Partner';
    final rera = user?.reraNumber.isNotEmpty == true ? user!.reraNumber : 'Verified Partner';
    final safeRera = rera.startsWith('RERA:') ? rera : (rera == 'Verified Partner' ? rera : 'RERA: $rera');
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

            // Interactive Cloud Sync Status Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: state.isSyncing
                    ? null
                    : () async {
                        final count = await state.triggerCloudSync();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      count > 0
                                          ? 'Cloud sync complete! $count queued offline item(s) synchronized.'
                                          : 'Everything is up to date with cloud!',
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                child: Container(
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
                          color: state.isSyncing
                              ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE))
                              : state.isOffline
                                  ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
                                  : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: state.isSyncing
                            ? const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              )
                            : Icon(
                                state.isOffline ? Icons.cloud_off_rounded : Icons.cloud_outlined,
                                color: state.isOffline ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                                size: 20,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Sync Status',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(Tap to sync)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.isSyncing
                                  ? 'Syncing pipeline with cloud...'
                                  : state.isOffline
                                      ? 'Offline mode • ${state.offlineQueueCount} leads queued'
                                      : 'Last synced ${DateFormat('dd MMM yyyy • hh:mm a').format(state.lastSyncedAt)}',
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
                          color: state.isSyncing
                              ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE))
                              : state.isOffline
                                  ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
                                  : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              state.isSyncing
                                  ? Icons.sync_rounded
                                  : state.isOffline
                                      ? Icons.wifi_off_rounded
                                      : Icons.cloud_done_rounded,
                              color: state.isSyncing
                                  ? const Color(0xFF2563EB)
                                  : state.isOffline
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF16A34A),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              state.isSyncing
                                  ? 'SYNCING...'
                                  : state.isOffline
                                      ? 'OFFLINE (${state.offlineQueueCount})'
                                      : 'SYNCED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: state.isSyncing
                                  ? const Color(0xFF2563EB)
                                  : state.isOffline
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF16A34A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                    badgeText: state.unreadNotificationCount > 0 ? '${state.unreadNotificationCount}' : null,
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
                    icon: Icons.folder_shared_outlined,
                    title: 'KYC Documents & Invoices',
                    badgeText: '${(state.kycCompletionPercentage * 100).toInt()}% KYC',
                    isPillBadge: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => DocsScreen(
                            state: state,
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Commissions & Payouts',
                    badgeText: state.commissionPendingFormatted,
                    isPillBadge: true,
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
            const SizedBox(height: 20),
            PoweredByBranding(isDark: isDark),
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
    bool isPillBadge = false,
    bool isDestructive = false,
  }) {
    final isPill = isPillBadge || (badgeText != null && badgeText.length > 2);

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
                padding: EdgeInsets.symmetric(
                  horizontal: isPill ? 8 : 7,
                  vertical: isPill ? 3 : 2,
                ),
                decoration: BoxDecoration(
                  color: isPill
                      ? (isDark ? const Color(0xFF065F46) : const Color(0xFFDCFCE7))
                      : const Color(0xFFEF4444),
                  borderRadius: isPill ? BorderRadius.circular(10) : null,
                  shape: isPill ? BoxShape.rectangle : BoxShape.circle,
                  border: isPill
                      ? Border.all(
                          color: isDark ? const Color(0xFF10B981) : const Color(0xFF86EFAC),
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPill
                        ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D))
                        : Colors.white,
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
              Navigator.of(context).popUntil((route) => route.isFirst);
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
