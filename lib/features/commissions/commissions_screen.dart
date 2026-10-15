import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import 'project_commission_table_screen.dart';

class CommissionsScreen extends StatefulWidget {
  final AppState state;
  final bool showBackButton;
  final VoidCallback? onBack;

  const CommissionsScreen({
    super.key,
    required this.state,
    this.showBackButton = false,
    this.onBack,
  });

  static void showEditBankModal(BuildContext context, AppState state, {VoidCallback? onSaved}) {
    _CommissionsScreenState.showEditBankModal(context, state, onSaved: onSaved);
  }

  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen> {
  String _projectSearchQuery = '';

  static void showEditBankModal(BuildContext context, AppState state, {VoidCallback? onSaved}) {
    final isDark = state.isDarkMode;
    final currentBank = state.savedBankDetails ??
        BankDetailsModel(
          accountHolder: state.currentUser?.firmName ?? 'Channel Partner',
          bankName: 'HDFC Bank Ltd',
          accountNumber: '',
          ifscCode: '',
        );

    final holderCtrl = TextEditingController(text: currentBank.accountHolder);
    final bankCtrl = TextEditingController(text: currentBank.bankName);
    final accCtrl = TextEditingController(text: currentBank.accountNumber);
    final ifscCtrl = TextEditingController(text: currentBank.ifscCode);
    final upiCtrl = TextEditingController(text: currentBank.upiId ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF131A26) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Settlement Bank Account',
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
              const SizedBox(height: 6),
              Text(
                'Direct commission disbursements are credited to this verified account.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: holderCtrl,
                decoration: const InputDecoration(labelText: 'Account Holder / Firm Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bankCtrl,
                decoration: const InputDecoration(labelText: 'Bank Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Account Number *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ifscCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'IFSC Code *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: upiCtrl,
                decoration: const InputDecoration(labelText: 'UPI ID (Optional)'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (holderCtrl.text.trim().isEmpty ||
                        bankCtrl.text.trim().isEmpty ||
                        accCtrl.text.trim().isEmpty ||
                        ifscCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all mandatory bank details.')),
                      );
                      return;
                    }

                    final updatedBank = BankDetailsModel(
                      accountHolder: holderCtrl.text.trim(),
                      bankName: bankCtrl.text.trim(),
                      accountNumber: accCtrl.text.trim(),
                      ifscCode: ifscCtrl.text.trim().toUpperCase(),
                      upiId: upiCtrl.text.trim().isNotEmpty ? upiCtrl.text.trim() : null,
                    );

                    state.saveDefaultBankDetails(updatedBank);
                    Navigator.of(ctx).pop();
                    onSaved?.call();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF10B981),
                        content: Text('Settlement bank details updated successfully!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Save Bank Details', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBankModal(BuildContext context) {
    showEditBankModal(context, widget.state, onSaved: () => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final projects = widget.state.projects;

    final filteredProjects = projects.where((p) {
      if (_projectSearchQuery.trim().isEmpty) return true;
      final q = _projectSearchQuery.trim().toLowerCase();
      return p.name.toLowerCase().contains(q) || p.location.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (widget.onBack != null || widget.showBackButton || Navigator.of(context).canPop()) ...[
                    InkWell(
                      onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF16A34A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commissions & Payouts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Track project brokerage slabs & invoice settlements',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showEditBankModal(context),
                    icon: const Icon(Icons.account_balance_outlined, color: Color(0xFF2563EB)),
                    tooltip: 'Settlement Bank Account',
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Verified Settlement Bank Banner
                    _buildBankBanner(isDark),
                    const SizedBox(height: 18),

                    // 3. Search Bar for Projects
                    TextField(
                      onChanged: (val) => setState(() => _projectSearchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search projects by name or location...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _projectSearchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () => setState(() => _projectSearchQuery = ''),
                                icon: const Icon(Icons.clear, size: 18),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Projects Directory (${filteredProjects.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Tap project to view table',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 5. Projects Commission Cards List
                    ...filteredProjects.map((project) => _buildProjectCommissionCard(project, isDark)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // Settlement Bank Banner
  Widget _buildBankBanner(bool isDark) {
    final bank = widget.state.savedBankDetails;
    final acc = bank?.accountNumber ?? '';
    final maskedAcc = acc.length > 4 ? '•••• •••• ${acc.substring(acc.length - 4)}' : (acc.isNotEmpty ? acc : 'Not Set');

    return Container(
      padding: const EdgeInsets.all(14),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settlement Destination Bank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${bank?.bankName ?? "Bank"} ($maskedAcc) • IFSC: ${bank?.ifscCode ?? "N/A"}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showEditBankModal(context),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // Individual Project Commission Card
  Widget _buildProjectCommissionCard(ProjectModel project, bool isDark) {
    final projectInvoices = widget.state.getInvoicesForProject(project.id);
    final total = widget.state.getProjectTotalCommission(project.id);
    final received = widget.state.getProjectReceivedCommission(project.id);
    final pending = widget.state.getProjectPendingCommission(project.id);
    final leadsCount = widget.state.getProjectLeadsCount(project.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => ProjectCommissionTableScreen(
                state: widget.state,
                project: project,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      project.heroImageUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 52,
                        height: 52,
                        color: AppColors.primary.withValues(alpha: 0.15),
                        child: const Icon(Icons.apartment_rounded, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          project.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$leadsCount Active Leads',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${projectInvoices.length} Invoices',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 3 Financial Metric Pills
              Row(
                children: [
                  // Total Claimed
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Claims',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount Received
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Received',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${received.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pending
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${pending.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Button to View Table
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => ProjectCommissionTableScreen(
                          state: widget.state,
                          project: project,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.table_chart_rounded, size: 16),
                  label: const Text(
                    'View Invoices & Payout Table',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
