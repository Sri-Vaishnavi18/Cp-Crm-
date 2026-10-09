import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class ProjectCommissionTableScreen extends StatefulWidget {
  final AppState state;
  final ProjectModel project;

  const ProjectCommissionTableScreen({
    super.key,
    required this.state,
    required this.project,
  });

  @override
  State<ProjectCommissionTableScreen> createState() => _ProjectCommissionTableScreenState();
}

class _ProjectCommissionTableScreenState extends State<ProjectCommissionTableScreen> {
  String _typeFilter = 'ALL'; // ALL, SITE_VISIT, BOOKING
  String _statusFilter = 'ALL'; // ALL, RECEIVED, PENDING
  String _searchQuery = '';

  void _showEditReceivedStatusDialog(BuildContext context, CommissionInvoiceModel invoice) {
    final isDark = widget.state.isDarkMode;
    final isCurrentlyReceived = invoice.status == InvoiceStatus.paid;
    bool newIsReceived = isCurrentlyReceived;
    final noteCtrl = TextEditingController();

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
                    color: (newIsReceived ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    newIsReceived ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                    color: newIsReceived ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Payment Status',
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
                  'Invoice Amount: ₹${invoice.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Client: ${invoice.clientName} (${invoice.type.displayName})',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Has this amount been received in your bank?',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),

                // Choice Toggle Cards
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => newIsReceived = true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          decoration: BoxDecoration(
                            color: newIsReceived
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : (isDark ? const Color(0xFF1E283A) : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: newIsReceived ? const Color(0xFF10B981) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: newIsReceived ? const Color(0xFF10B981) : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Received / Paid',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: newIsReceived ? const Color(0xFF10B981) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => newIsReceived = false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          decoration: BoxDecoration(
                            color: !newIsReceived
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                : (isDark ? const Color(0xFF1E283A) : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !newIsReceived ? const Color(0xFFF59E0B) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.hourglass_top_rounded,
                                color: !newIsReceived ? const Color(0xFFF59E0B) : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Not Received (Pending)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: !newIsReceived ? const Color(0xFFF59E0B) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Settlement Note (Optional)',
                    hintText: 'e.g. Bank credit ref # / builder remittance',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.state.toggleInvoiceReceivedStatus(
                    invoice.id,
                    isReceived: newIsReceived,
                    note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                  );

                  Navigator.of(ctx).pop();
                  setState(() {});

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: newIsReceived ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      content: Text(
                        'Invoice ${invoice.invoiceNumber} status updated to ${newIsReceived ? "RECEIVED / PAID" : "PENDING"}.',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: newIsReceived ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
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
                              '₹${invoice.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 26,
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
                      label: const Text('Edit Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildReceiptRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(InvoiceStatus status) {
    final isPaid = status == InvoiceStatus.paid;
    final color = isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final icon = isPaid ? Icons.check_circle_rounded : Icons.hourglass_top_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            isPaid ? 'Received / Paid' : 'Pending',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final projectInvoices = widget.state.getInvoicesForProject(widget.project.id);

    // Apply Filter & Search
    final filteredInvoices = projectInvoices.where((inv) {
      if (_typeFilter == 'SITE_VISIT' && inv.type != InvoiceType.siteVisit) {
        return false;
      }
      if (_typeFilter == 'BOOKING' && inv.type != InvoiceType.booking) {
        return false;
      }
      if (_statusFilter == 'RECEIVED' && inv.status != InvoiceStatus.paid) {
        return false;
      }
      if (_statusFilter == 'PENDING' && inv.status == InvoiceStatus.paid) {
        return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final match = inv.clientName.toLowerCase().contains(q) ||
            inv.invoiceNumber.toLowerCase().contains(q) ||
            inv.clientPhone.contains(q);
        if (!match) return false;
      }

      return true;
    }).toList();

    // Calculate Dynamic Footer Totals
    final totalClaimed = filteredInvoices.fold(0.0, (sum, inv) => sum + inv.amount);
    final totalReceived = filteredInvoices.where((inv) => inv.status == InvoiceStatus.paid).fold(0.0, (sum, inv) => sum + inv.amount);
    final totalPending = filteredInvoices.where((inv) => inv.status != InvoiceStatus.paid).fold(0.0, (sum, inv) => sum + inv.amount);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F17) : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B0F17) : AppColors.lightSurface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF1E293B) : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.project.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.project.location} • Invoices Ledger',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search lead name, phone, or invoice #...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () => setState(() => _searchQuery = ''),
                                icon: const Icon(Icons.clear, size: 18),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip('All Types', 'ALL', _typeFilter, (val) => setState(() => _typeFilter = val), isDark),
                          const SizedBox(width: 6),
                          _buildFilterChip('Site Visit (Type 1)', 'SITE_VISIT', _typeFilter, (val) => setState(() => _typeFilter = val), isDark),
                          const SizedBox(width: 6),
                          _buildFilterChip('Booking (Type 2)', 'BOOKING', _typeFilter, (val) => setState(() => _typeFilter = val), isDark),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 20, color: Colors.grey.shade400),
                          const SizedBox(width: 12),
                          _buildFilterChip('All Status', 'ALL', _statusFilter, (val) => setState(() => _statusFilter = val), isDark),
                          const SizedBox(width: 6),
                          _buildFilterChip('Received', 'RECEIVED', _statusFilter, (val) => setState(() => _statusFilter = val), isDark),
                          const SizedBox(width: 6),
                          _buildFilterChip('Pending', 'PENDING', _statusFilter, (val) => setState(() => _statusFilter = val), isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TABLE SECTION HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.table_chart_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Commission Invoices Table',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${filteredInvoices.length} Records',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // STRUCTURED INVOICES TABLE CONTAINER
                    if (filteredInvoices.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 38, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            const SizedBox(height: 10),
                            Text(
                              'No Invoices for this Project',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Invoices will appear here once generated from the Lead Details page upon Site Visit or Booking.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _buildInvoicesTable(filteredInvoices, isDark),

                    const SizedBox(height: 18),

                    // UNDER TABLE: TOTAL & PENDING SUMMARY FOOTER CARD
                    _buildSummaryFooter(totalClaimed, totalReceived, totalPending, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Responsive Table View
  Widget _buildInvoicesTable(List<CommissionInvoiceModel> invoices, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A26) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF182232) : AppColors.lightSurfaceSubtle,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
                ),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('LEAD & TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey))),
                Expanded(flex: 2, child: Text('AMOUNT', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey))),
                Expanded(flex: 3, child: Text('STATUS', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey))),
                SizedBox(width: 48, child: Text('ACTION', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey))),
              ],
            ),
          ),

          // Table Rows
          ...invoices.asMap().entries.map((entry) {
            final idx = entry.key;
            final inv = entry.value;
            final isSiteVisit = inv.type == InvoiceType.siteVisit;
            final isPaid = inv.status == InvoiceStatus.paid;
            final isLast = idx == invoices.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? (idx.isEven ? const Color(0xFF131A26) : const Color(0xFF161F2E))
                    : (idx.isEven ? Colors.white : AppColors.lightSurfaceSubtle.withValues(alpha: 0.5)),
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: isDark ? const Color(0xFF1E283A) : AppColors.lightBorder,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  // Col 1: Lead Name, Type & Invoice #
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.clientName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isSiteVisit ? 'Site Visit' : 'Booking',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSiteVisit ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                inv.invoiceNumber,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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

                  // Col 2: Amount (₹)
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${inv.amount.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),

                  // Col 3: Status Badge + Tap to Edit
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: InkWell(
                        onTap: () => _showEditReceivedStatusDialog(context, inv),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPaid ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                                size: 12,
                                color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPaid ? 'Received' : 'Pending',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.edit,
                                size: 10,
                                color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Col 4: Action (View / Download Voucher)
                  SizedBox(
                    width: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.primary),
                          tooltip: 'View / Download Voucher',
                          onPressed: () => _showInvoiceVoucherModal(context, inv),
                        ),
                      ],
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

  // Summary Footer under the Table
  Widget _buildSummaryFooter(double total, double received, double pending, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2A) : AppColors.lightSurfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF222F43) : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Project Settlement Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // 1. Total Claimed
              Expanded(
                child: _buildFooterStatItem(
                  label: 'Total Claimed',
                  value: '₹${total.toStringAsFixed(0)}',
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // 2. Total Received
              Expanded(
                child: _buildFooterStatItem(
                  label: 'Amount Received',
                  value: '₹${received.toStringAsFixed(0)}',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // 3. Total Pending
              Expanded(
                child: _buildFooterStatItem(
                  label: 'Pending Amount',
                  value: '₹${pending.toStringAsFixed(0)}',
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterStatItem({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1520) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    Function(String) onSelect,
    bool isDark,
  ) {
    final isSelected = value == currentValue;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF161F2E) : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF24344B) : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
