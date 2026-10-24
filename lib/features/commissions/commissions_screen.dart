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
  int _selectedViewTab = 0; // 0 = Invoices & Claims, 1 = Projects Directory
  String _projectSearchQuery = '';
  String _invoiceSearchQuery = '';
  String _statusFilter = 'ALL'; // ALL, PENDING, APPROVED, PAID
  String _typeFilter = 'ALL'; // ALL, SITE_VISIT, BOOKING

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
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final isDark = widget.state.isDarkMode;
        final allInvoices = widget.state.allInvoices;

        // Pending invoices include both pending & approved (awaiting bank payout credit)
        final pendingInvoices = allInvoices.where(
          (inv) => inv.status == InvoiceStatus.pending || inv.status == InvoiceStatus.approved,
        ).toList();
        final paidInvoices = allInvoices.where((inv) => inv.status == InvoiceStatus.paid).toList();

        // Filtered Invoices List
        final filteredInvoices = allInvoices.where((inv) {
          // Status filter
          if (_statusFilter == 'PENDING' && inv.status != InvoiceStatus.pending) return false;
          if (_statusFilter == 'APPROVED' && inv.status != InvoiceStatus.approved) return false;
          if (_statusFilter == 'PAID' && inv.status != InvoiceStatus.paid) return false;

          // Type filter
          if (_typeFilter == 'SITE_VISIT' && inv.type != InvoiceType.siteVisit) return false;
          if (_typeFilter == 'BOOKING' && inv.type != InvoiceType.booking) return false;

          // Search query
          if (_invoiceSearchQuery.trim().isNotEmpty) {
            final q = _invoiceSearchQuery.trim().toLowerCase();
            final matchNo = inv.invoiceNumber.toLowerCase().contains(q);
            final matchClient = inv.clientName.toLowerCase().contains(q);
            final matchProj = inv.projectName.toLowerCase().contains(q);
            final matchPhone = inv.clientPhone.contains(q);
            if (!matchNo && !matchClient && !matchProj && !matchPhone) return false;
          }
          return true;
        }).toList();

        // Projects List (only actual registered projects)
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
                              'Track raised invoices, pending audit & credited payouts',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
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
                        // 1. KPI Financial Metrics Header (Total Claimed, Pending Approval, Received)
                        _buildFinancialSummaryCards(
                          isDark: isDark,
                          totalClaimed: widget.state.totalCommissionClaimed,
                          pendingAmount: widget.state.pendingCommissionAmount,
                          paidAmount: widget.state.paidCommissionAmount,
                          totalCount: allInvoices.length,
                          pendingCount: pendingInvoices.length,
                          paidCount: paidInvoices.length,
                        ),
                        const SizedBox(height: 14),

                        // 2. Verified Settlement Bank Banner
                        _buildBankBanner(isDark),
                        const SizedBox(height: 16),

                        // 3. Segmented Switcher (Invoices & Claims vs Projects Directory)
                        _buildViewSwitcher(
                          isDark: isDark,
                          invoicesCount: allInvoices.length,
                          projectsCount: filteredProjects.length,
                        ),
                        const SizedBox(height: 14),

                        // 4. View Content based on selected tab
                        if (_selectedViewTab == 0) ...[
                          _buildInvoicesSection(
                            isDark: isDark,
                            invoices: filteredInvoices,
                            totalCount: allInvoices.length,
                          ),
                        ] else ...[
                          _buildProjectsSection(
                            isDark: isDark,
                            projects: filteredProjects,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1. Financial Summary KPI Cards (Total, Pending, Received)
  Widget _buildFinancialSummaryCards({
    required bool isDark,
    required double totalClaimed,
    required double pendingAmount,
    required double paidAmount,
    required int totalCount,
    required int pendingCount,
    required int paidCount,
  }) {
    return Row(
      children: [
        // Card 1: Total Claims
        Expanded(
          child: _buildMetricCard(
            title: 'Total Claimed',
            amount: AppState.formatCurrency(totalClaimed),
            subtitle: '$totalCount Invoices',
            icon: Icons.receipt_long_rounded,
            accentColor: const Color(0xFF6366F1),
            bgColor: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.15 : 0.08),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),

        // Card 2: Pending Approval
        Expanded(
          child: _buildMetricCard(
            title: 'Pending Audit',
            amount: AppState.formatCurrency(pendingAmount),
            subtitle: '$pendingCount Pending',
            icon: Icons.hourglass_top_rounded,
            accentColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),

        // Card 3: Credited / Paid
        Expanded(
          child: _buildMetricCard(
            title: 'Settled Payout',
            amount: AppState.formatCurrency(paidAmount),
            subtitle: '$paidCount Credited',
            icon: Icons.check_circle_rounded,
            accentColor: const Color(0xFF10B981),
            bgColor: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Settlement Bank Banner
  Widget _buildBankBanner(bool isDark) {
    final bank = widget.state.savedBankDetails;
    final acc = bank?.accountNumber ?? '';
    final maskedAcc = acc.length > 4 ? '•••• •••• ${acc.substring(acc.length - 4)}' : (acc.isNotEmpty ? acc : 'Not Set');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 1),
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

  // 3. Segmented View Switcher (Invoices & Claims vs Projects Directory)
  Widget _buildViewSwitcher({
    required bool isDark,
    required int invoicesCount,
    required int projectsCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F2E) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Tab 0: Invoices & Claims
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedViewTab = 0),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedViewTab == 0
                      ? (isDark ? AppColors.darkSurface : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedViewTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 15,
                      color: _selectedViewTab == 0 ? AppColors.primary : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'All Invoices ($invoicesCount)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _selectedViewTab == 0 ? FontWeight.w800 : FontWeight.w600,
                        color: _selectedViewTab == 0
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab 1: Projects Directory
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedViewTab = 1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedViewTab == 1
                      ? (isDark ? AppColors.darkSurface : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedViewTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apartment_rounded,
                      size: 15,
                      color: _selectedViewTab == 1 ? AppColors.primary : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'By Projects ($projectsCount)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _selectedViewTab == 1 ? FontWeight.w800 : FontWeight.w600,
                        color: _selectedViewTab == 1
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Invoices Section (Tab 0)
  Widget _buildInvoicesSection({
    required bool isDark,
    required List<CommissionInvoiceModel> invoices,
    required int totalCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Filter Row
        TextField(
          onChanged: (val) => setState(() => _invoiceSearchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search by client, invoice # or project...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _invoiceSearchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () => setState(() => _invoiceSearchQuery = ''),
                    icon: const Icon(Icons.clear, size: 18),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),

        // Filter Chips (All, Pending, Approved, Paid)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', 'All Invoices', isDark),
              const SizedBox(width: 6),
              _buildFilterChip('PENDING', 'Pending Approval', isDark),
              const SizedBox(width: 6),
              _buildFilterChip('APPROVED', 'Approved', isDark),
              const SizedBox(width: 6),
              _buildFilterChip('PAID', 'Settled / Credited', isDark),
              const SizedBox(width: 6),
              _buildTypeFilterChip('SITE_VISIT', 'Site Visits', isDark),
              const SizedBox(width: 6),
              _buildTypeFilterChip('BOOKING', 'Bookings', isDark),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Submitted Claims (${invoices.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              'Tap invoice to audit / edit status',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Invoices Cards List
        if (invoices.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 44,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFFCBD5E1),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Invoices Found',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _invoiceSearchQuery.isNotEmpty || _statusFilter != 'ALL'
                      ? 'No invoices match your current search/filter criteria.'
                      : 'Generate site visit or booking commission claims from Lead Details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ...invoices.map((inv) => _buildInvoiceCard(inv, isDark)),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label, bool isDark) {
    final isSelected = _statusFilter == filterKey && _typeFilter == 'ALL';
    return InkWell(
      onTap: () {
        setState(() {
          _statusFilter = filterKey;
          _typeFilter = 'ALL';
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E283A) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(String typeKey, String label, bool isDark) {
    final isSelected = _typeFilter == typeKey;
    return InkWell(
      onTap: () {
        setState(() {
          _typeFilter = isSelected ? 'ALL' : typeKey;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF38BDF8)
              : (isDark ? const Color(0xFF1E283A) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // Individual Invoice Card in Invoices Tab
  Widget _buildInvoiceCard(CommissionInvoiceModel inv, bool isDark) {
    final isSiteVisit = inv.type == InvoiceType.siteVisit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showInvoiceVoucherModal(context, inv),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Number, Type Badge, Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSiteVisit ? Icons.tour_rounded : Icons.real_estate_agent_rounded,
                          size: 15,
                          color: isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        inv.invoiceNumber,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inv.type.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(inv.status),
                ],
              ),
              const SizedBox(height: 10),

              // Middle: Client info and Project
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                inv.clientName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (inv.clientPhone.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                '• ${inv.clientPhone}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.apartment_rounded,
                              size: 13,
                              color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                inv.projectName,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
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

                  // Claim Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppState.formatCurrency(inv.amount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(inv.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Bottom footer: quick tap hint
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_outlined,
                        size: 12,
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'A/C: ${inv.bankDetails.bankName}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'View Voucher',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. Projects Directory Section (Tab 1)
  Widget _buildProjectsSection({
    required bool isDark,
    required List<ProjectModel> projects,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar for Projects
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Projects Directory (${projects.length})',
                  style: TextStyle(
                    fontSize: 15,
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

        // Projects Commission Cards List
        if (projects.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.apartment_outlined, size: 44, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 12),
                Text(
                  'No Projects Found',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No project matched "$_projectSearchQuery"',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ...projects.map((project) => _buildProjectCommissionCard(project, isDark)),
        ],
      ],
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
                          AppState.formatCurrency(total),
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
                          AppState.formatCurrency(received),
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
                          AppState.formatCurrency(pending),
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

  // Digital Voucher Modal for Viewing / Auditing Invoices
  void _showInvoiceVoucherModal(BuildContext context, CommissionInvoiceModel invoice) {
    final isDark = widget.state.isDarkMode;
    final isSiteVisit = invoice.type == InvoiceType.siteVisit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF131A26) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSiteVisit ? Icons.tour_rounded : Icons.real_estate_agent_rounded,
                          color: isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            invoice.type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Digital Voucher Card Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF182232) : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF28364D) : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Claim Amount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppState.formatCurrency(invoice.amount),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        _buildStatusBadge(invoice.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    _buildReceiptRow('Client Name', invoice.clientName, isDark),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Client Phone', invoice.clientPhone, isDark),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Project', invoice.projectName, isDark),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Claim Date', _formatDate(invoice.date), isDark),
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildReceiptRow('Remarks', invoice.notes!, isDark),
                    ],
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    Text(
                      'Settlement Destination Bank',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReceiptRow('A/C Holder', invoice.bankDetails.accountHolder, isDark),
                    const SizedBox(height: 6),
                    _buildReceiptRow('Bank', invoice.bankDetails.bankName, isDark),
                    const SizedBox(height: 6),
                    _buildReceiptRow('Account No', invoice.bankDetails.accountNumber, isDark),
                    const SizedBox(height: 6),
                    _buildReceiptRow('IFSC', invoice.bankDetails.ifscCode, isDark),
                    if (invoice.bankDetails.upiId != null && invoice.bankDetails.upiId!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildReceiptRow('UPI ID', invoice.bankDetails.upiId!, isDark),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF4F46E5),
                            content: Text('Downloading digital invoice PDF for ${invoice.invoiceNumber}...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showEditReceivedStatusDialog(context, invoice);
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Update Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditReceivedStatusDialog(BuildContext context, CommissionInvoiceModel invoice) {
    final isDark = widget.state.isDarkMode;
    InvoiceStatus selectedStatus = invoice.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF151C28) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Claim Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        invoice.invoiceNumber,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: ${AppState.formatCurrency(invoice.amount)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Client: ${invoice.clientName} (${invoice.projectName})',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Status:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // Radio options for Status
                ...[
                  InvoiceStatus.pending,
                  InvoiceStatus.approved,
                  InvoiceStatus.paid,
                  InvoiceStatus.rejected,
                ].map((st) {
                  final isChecked = selectedStatus == st;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedStatus = st),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            isChecked ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isChecked ? AppColors.primary : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            st.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isChecked ? FontWeight.w800 : FontWeight.w600,
                              color: isChecked
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.state.updateInvoiceStatus(invoice.id, selectedStatus);
                  Navigator.of(ctx).pop();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF10B981),
                      content: Text('Status updated to ${selectedStatus.displayName}!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save Status'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(InvoiceStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case InvoiceStatus.pending:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'Pending Approval';
        break;
      case InvoiceStatus.approved:
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF4338CA);
        label = 'Approved';
        break;
      case InvoiceStatus.paid:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        label = 'Credited / Paid';
        break;
      case InvoiceStatus.rejected:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
