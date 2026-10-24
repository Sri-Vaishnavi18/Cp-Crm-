import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/license_service.dart';
import '../../core/state/app_state.dart';

class SubscriptionLockScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback? onUnlocked;

  const SubscriptionLockScreen({
    super.key,
    required this.state,
    this.onUnlocked,
  });

  @override
  State<SubscriptionLockScreen> createState() => _SubscriptionLockScreenState();
}

class _SubscriptionLockScreenState extends State<SubscriptionLockScreen> {
  bool _isVerifying = false;
  String? _statusFeedback;
  int _secretTapCount = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final user = widget.state.currentUser;
    final license = widget.state.licenseService;
    final status = license.currentStatus;

    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top header / Secret tap trigger
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        color: subtextColor,
                      ),
                      onPressed: () => widget.state.toggleTheme(),
                      tooltip: 'Toggle Theme',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: subtextColor.withValues(alpha: 0.4),
                      ),
                      onPressed: _openAdminSettingsDialog,
                      tooltip: 'Admin / Sheet Configuration',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lock Illustration / Icon
                GestureDetector(
                  onTap: () {
                    _secretTapCount++;
                    if (_secretTapCount >= 5) {
                      _secretTapCount = 0;
                      _openAdminSettingsDialog();
                    }
                  },
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _getStatusGradient(status),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(status).withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _getStatusIcon(status),
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusBadgeText(status),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(status),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Main Title
                Text(
                  _getTitleForStatus(status),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Description message
                Text(
                  _getDescriptionForStatus(status),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 28),

                // CP Info Card
                if (user != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Partner Name', user.name, textColor, subtextColor),
                        const Divider(height: 20),
                        _buildInfoRow('Firm Name', user.firmName, textColor, subtextColor),
                        const Divider(height: 20),
                        _buildInfoRow('Registered Phone', user.phone, textColor, subtextColor),
                        if (license.validUntil != null) ...[
                          const Divider(height: 20),
                          _buildInfoRow(
                            'Valid Until',
                            '${license.validUntil!.day}/${license.validUntil!.month}/${license.validUntil!.year}',
                            textColor,
                            subtextColor,
                          ),
                        ],
                        if (license.lastVerifiedAt != null) ...[
                          const Divider(height: 20),
                          _buildInfoRow(
                            'Last Online Check',
                            _formatLastVerified(license.lastVerifiedAt!),
                            textColor,
                            subtextColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                if (_statusFeedback != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusFeedback!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Button: Verify Now
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _handleVerifyNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.refresh_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Check & Unlock Now',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action Button: WhatsApp Admin
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _contactAdminWhatsApp,
                    icon: const Icon(Icons.chat_outlined, color: Color(0xFF22C55E), size: 20),
                    label: Text(
                      'Contact Admin on WhatsApp',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                            : const Color(0xFF22C55E),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Action Button: Call Admin
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: _callAdmin,
                    icon: Icon(Icons.phone_outlined, size: 18, color: subtextColor),
                    label: Text(
                      'Call Support (${license.adminPhone})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: subtextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Log out / Switch Account
                TextButton(
                  onPressed: () async {
                    await widget.state.logout();
                  },
                  child: Text(
                    'Log out / Switch Account',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, Color subtextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: subtextColor,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  String _formatLastVerified(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  Color _getStatusColor(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.active:
        return const Color(0xFF10B981);
      case LicenseStatus.expired:
        return const Color(0xFFF59E0B);
      case LicenseStatus.pending:
        return const Color(0xFF6366F1);
      case LicenseStatus.verificationRequired:
        return const Color(0xFFEAB308);
      case LicenseStatus.inactive:
        return const Color(0xFFEF4444);
    }
  }

  List<Color> _getStatusGradient(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.active:
        return const [Color(0xFF10B981), Color(0xFF059669)];
      case LicenseStatus.expired:
        return const [Color(0xFFF59E0B), Color(0xFFD97706)];
      case LicenseStatus.pending:
        return const [Color(0xFF6366F1), Color(0xFF4F46E5)];
      case LicenseStatus.verificationRequired:
        return const [Color(0xFFF59E0B), Color(0xFFCA8A04)];
      case LicenseStatus.inactive:
        return const [Color(0xFFEF4444), Color(0xFFDC2626)];
    }
  }

  IconData _getStatusIcon(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.active:
        return Icons.lock_open_rounded;
      case LicenseStatus.expired:
        return Icons.event_busy_rounded;
      case LicenseStatus.pending:
        return Icons.hourglass_top_rounded;
      case LicenseStatus.verificationRequired:
        return Icons.wifi_find_rounded;
      case LicenseStatus.inactive:
        return Icons.lock_rounded;
    }
  }

  String _getStatusBadgeText(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.active:
        return 'LICENSE ACTIVE';
      case LicenseStatus.expired:
        return 'SUBSCRIPTION EXPIRED';
      case LicenseStatus.pending:
        return 'PAYMENT UNDER REVIEW';
      case LicenseStatus.verificationRequired:
        return 'DAILY CHECK REQUIRED';
      case LicenseStatus.inactive:
        return 'PAYMENT PENDING / INACTIVE';
    }
  }

  String _getTitleForStatus(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.active:
        return 'Access Granted';
      case LicenseStatus.expired:
        return 'Subscription Expired';
      case LicenseStatus.pending:
        return 'Account Pending Approval';
      case LicenseStatus.verificationRequired:
        return 'Connect to Internet';
      case LicenseStatus.inactive:
        return 'Subscription Required';
    }
  }

  String _getDescriptionForStatus(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.active:
        return 'Your channel partner license is valid.';
      case LicenseStatus.expired:
        return 'Your plan has expired. Please complete renewal payment to regain full access to your CRM.';
      case LicenseStatus.pending:
        return 'Your payment is being verified by admin. Once approved, the app will unlock automatically.';
      case LicenseStatus.verificationRequired:
        return 'A daily security verification is required. Please turn on mobile data or Wi-Fi and tap "Check & Unlock Now".';
      case LicenseStatus.inactive:
        return 'Access to CP CRM is reserved for active partners. Please complete your subscription payment to unlock.';
    }
  }

  Future<void> _handleVerifyNow() async {
    setState(() {
      _isVerifying = true;
      _statusFeedback = null;
    });

    final result = await widget.state.checkSubscription(force: true);

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      _statusFeedback = result.message;
    });

    if (result.isAllowed) {
      widget.onUnlocked?.call();
    }
  }

  Future<void> _contactAdminWhatsApp() async {
    final phone = widget.state.currentUser?.phone ?? '';
    final name = widget.state.currentUser?.name ?? 'Partner';
    final adminWhatsApp = widget.state.licenseService.adminWhatsApp;

    final message = Uri.encodeComponent(
      'Hello Admin, I have made the payment for CP CRM access.\n'
      'Name: $name\n'
      'Phone: $phone\n'
      'Please activate my account in the Google Sheet.',
    );

    final url = Uri.parse('https://wa.me/$adminWhatsApp?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callAdmin() async {
    final adminPhone = widget.state.licenseService.adminPhone;
    final url = Uri.parse('tel:$adminPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openAdminSettingsDialog() {
    final urlController = TextEditingController(text: widget.state.licenseService.sheetUrl);
    final phoneController = TextEditingController(text: widget.state.licenseService.adminPhone);
    final waController = TextEditingController(text: widget.state.licenseService.adminWhatsApp);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.admin_panel_settings_outlined, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(
                'Admin Control Setup',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Google Apps Script Web App URL:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: 'https://script.google.com/macros/s/.../exec',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                Text(
                  'Admin Phone (For Calls):',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    hintText: '+91 9876543210',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Admin WhatsApp (Without + sign):',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: waController,
                  decoration: const InputDecoration(
                    hintText: '919876543210',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                Text(
                  'Quick Testing / Override:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Unlock (Active)'),
                      onPressed: () async {
                        await widget.state.overrideLicenseStatus(LicenseStatus.active);
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      },
                    ),
                    ActionChip(
                      label: const Text('Lock (Inactive)'),
                      onPressed: () async {
                        await widget.state.overrideLicenseStatus(LicenseStatus.inactive);
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      },
                    ),
                    ActionChip(
                      label: const Text('Expired'),
                      onPressed: () async {
                        await widget.state.overrideLicenseStatus(
                          LicenseStatus.expired,
                          validUntil: DateTime.now().subtract(const Duration(days: 1)),
                        );
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await widget.state.updateLicenseConfig(
                  sheetUrl: urlController.text,
                  phone: phoneController.text,
                  whatsApp: waController.text,
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
                if (mounted) {
                  _handleVerifyNow();
                }
              },
              child: const Text('Save & Check'),
            ),
          ],
        );
      },
    );
  }
}
