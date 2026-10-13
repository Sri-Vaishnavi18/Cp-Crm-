import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/services/document_picker_service.dart';
import '../../core/services/file_download_service.dart';

class DocsScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback? onBack;

  const DocsScreen({
    super.key,
    required this.state,
    this.onBack,
  });

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Tab 1 (CP Docs) Filters
  String _selectedDocCategory = 'All'; // All, Mandatory (KYC), Tax & Legal, Agreements, Banking

  // Tab 2 (Received Invoices) Filters
  String _selectedInvoiceType = 'All'; // All, Site Visit, Booking, Tax Invoices, TDS 16A
  String _selectedFinancialYear = 'FY 2024-25'; // FY 2024-25, FY 2023-24, All

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Filtering Helpers ---

  List<CpDocumentModel> _getFilteredDocuments() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.state.cpDocuments.where((doc) {
      if (_selectedDocCategory != 'All' && doc.type.category != _selectedDocCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesTitle = doc.title.toLowerCase().contains(query);
        final matchesNum = doc.documentNumber.toLowerCase().contains(query);
        final matchesRemarks = (doc.remarks ?? '').toLowerCase().contains(query);
        if (!matchesTitle && !matchesNum && !matchesRemarks) return false;
      }
      return true;
    }).toList();
  }

  List<ReceivedInvoiceModel> _getFilteredInvoices() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.state.receivedInvoices.where((inv) {
      if (_selectedFinancialYear != 'All' && inv.financialYear != _selectedFinancialYear) {
        return false;
      }
      if (_selectedInvoiceType == 'Site Visit' && inv.type != ReceivedInvoiceType.siteVisitPayout) {
        return false;
      }
      if (_selectedInvoiceType == 'Booking' && inv.type != ReceivedInvoiceType.bookingBrokerage) {
        return false;
      }
      if (_selectedInvoiceType == 'Tax Invoices' && inv.type != ReceivedInvoiceType.builderTaxInvoice) {
        return false;
      }
      if (_selectedInvoiceType == 'TDS 16A' && inv.type != ReceivedInvoiceType.tdsCertificate16A) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesClient = inv.clientName.toLowerCase().contains(query);
        final matchesProject = inv.projectName.toLowerCase().contains(query);
        final matchesVoucher = inv.voucherNumber.toLowerCase().contains(query);
        final matchesUtr = inv.utrNumber.toLowerCase().contains(query);
        if (!matchesClient && !matchesProject && !matchesVoucher && !matchesUtr) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final isDark = widget.state.isDarkMode;
        final missingCount = widget.state.missingMandatoryDocsCount;
        final kycPercent = (widget.state.kycCompletionPercentage * 100).toInt();

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F7FB),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(isDark, missingCount),
                _buildTabSwitcher(isDark, missingCount),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCpDocsView(isDark, kycPercent),
                      _buildReceivedInvoicesView(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Top Header ---
  Widget _buildHeader(bool isDark, int missingCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              onPressed: widget.onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (widget.onBack != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Docs & Billing',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        'Channel Partner',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'KYC regulatory compliance & received builder payout vouchers',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openUploadDocModal(context, null),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Upload',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

  // --- Segmented Tab Switcher ---
  Widget _buildTabSwitcher(bool isDark, int missingCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_shared_rounded, size: 16),
                const SizedBox(width: 6),
                const Text('CP Required Docs'),
                if (missingCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _tabController.index == 0 ? Colors.white : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$missingCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _tabController.index == 0 ? const Color(0xFF2563EB) : Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_rounded, size: 16),
                const SizedBox(width: 6),
                const Text('Invoices Received'),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _tabController.index == 1 ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF2563EB).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.state.receivedInvoices.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _tabController.index == 1 ? Colors.white : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: CP REQUIRED DOCS VIEW
  // ==========================================

  Widget _buildCpDocsView(bool isDark, int kycPercent) {
    final docs = _getFilteredDocuments();

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
        children: [
          // KYC Health Progress Card
          _buildKycHealthCard(isDark, kycPercent),
          const SizedBox(height: 14),

          // Search Field
          _buildSearchField(isDark, hint: 'Search RERA, PAN, GST, MOU...'),
          const SizedBox(height: 12),

          // Category Chips
          _buildDocCategoryChips(isDark),
          const SizedBox(height: 14),

          // Document List Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DOCUMENTS (${docs.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '${widget.state.cpDocuments.where((d) => d.status == CpDocumentStatus.verified).length} of ${widget.state.cpDocuments.length} Verified',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Documents List
          if (docs.isEmpty)
            _buildEmptyState(
              isDark,
              icon: Icons.folder_open_rounded,
              title: 'No Documents Found',
              subtitle: 'Try adjusting your search or category filter',
            )
          else
            ...docs.map((doc) => _buildDocCard(doc, isDark)),
        ],
      ),
    );
  }

  Widget _buildKycHealthCard(bool isDark, int kycPercent) {
    final verifiedCount = widget.state.cpDocuments.where((d) => d.status == CpDocumentStatus.verified).length;
    final totalMandatory = widget.state.cpDocuments.where((d) => d.isMandatory).length;
    final isComplete = kycPercent >= 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E40AF), const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isComplete ? Icons.verified_user_rounded : Icons.shield_outlined,
                  color: isComplete ? const Color(0xFF4ADE80) : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KYC Compliance Health',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isComplete
                          ? '100% Verified • Ready for Automatic Instant Payouts'
                          : '$verifiedCount of $totalMandatory Mandatory Documents Verified',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isComplete ? const Color(0xFF16A34A) : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$kycPercent%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: kycPercent / 100.0,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isComplete
                    ? 'All regulatory requirements satisfied'
                    : 'Upload remaining documents to clear payout holds',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              if (!isComplete)
                InkWell(
                  onTap: () {
                    final missing = widget.state.cpDocuments.firstWhere(
                      (d) => d.status != CpDocumentStatus.verified,
                      orElse: () => widget.state.cpDocuments.first,
                    );
                    _openUploadDocModal(context, missing);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Upload Now',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocCategoryChips(bool isDark) {
    final categories = ['All', 'Mandatory (KYC)', 'Tax & Legal', 'Agreements', 'Banking'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedDocCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedDocCategory = cat);
              },
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              selectedColor: const Color(0xFF2563EB),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : const Color(0xFF334155)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDocCard(CpDocumentModel doc, bool isDark) {
    final statusColor = _getStatusColor(doc.status);
    final iconData = _getDocIcon(doc.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openDocPreviewModal(context, doc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: const Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                doc.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (doc.isMandatory)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Mandatory',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          doc.documentNumber.isNotEmpty
                              ? 'Doc No: ${doc.documentNumber}'
                              : 'No document number provided',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                          ),
                        ),
                        if (doc.expiresAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Valid till: ${doc.expiresAt!.day} ${_getMonthName(doc.expiresAt!.month)} ${doc.expiresAt!.year}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusPill(doc.status, statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attachment_rounded,
                        size: 14,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        doc.fileName ?? 'No file attached',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                      if (doc.fileSize != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${doc.fileSize})',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined, size: 18),
                        color: const Color(0xFF2563EB),
                        tooltip: 'Download',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Downloading ${doc.fileName ?? doc.title}...'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF2563EB),
                            ),
                          );
                          await FileDownloadService.downloadDocumentPdf(
                            documentTitle: doc.title,
                            documentNumber: doc.documentNumber,
                            fileName: doc.fileName ?? '${doc.type.name}.pdf',
                            status: doc.status.displayName,
                            validTill: doc.expiresAt != null
                                ? '${doc.expiresAt!.day}/${doc.expiresAt!.month}/${doc.expiresAt!.year}'
                                : null,
                            partnerName: widget.state.currentUser?.name,
                            remarks: doc.remarks,
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.cloud_upload_outlined, size: 14, color: Color(0xFF2563EB)),
                        label: Text(
                          doc.status == CpDocumentStatus.missing ? 'Upload' : 'Replace',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        onPressed: () => _openUploadDocModal(context, doc),
                      ),
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

  // ==========================================
  // TAB 2: INVOICES RECEIVED VIEW
  // ==========================================

  Widget _buildReceivedInvoicesView(bool isDark) {
    final invoices = _getFilteredInvoices();
    final totalDisbursed = widget.state.totalReceivedDisbursedAmount;
    final netCredited = widget.state.totalNetReceivedAmount;
    final totalTds = widget.state.totalTdsDeductedAmount;

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
        children: [
          // Received Financial Stats Banner
          _buildFinancialStatsBanner(isDark, totalDisbursed, netCredited, totalTds),
          const SizedBox(height: 14),

          // Search Field
          _buildSearchField(isDark, hint: 'Search by client, project, UTR, or voucher...'),
          const SizedBox(height: 12),

          // Filter Controls (FY & Types)
          _buildInvoiceFilterRow(isDark),
          const SizedBox(height: 14),

          // Invoices Count Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DISBURSAL VOUCHERS (${invoices.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                _selectedFinancialYear == 'All' ? 'All Time' : _selectedFinancialYear,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Invoice Cards
          if (invoices.isEmpty)
            _buildEmptyState(
              isDark,
              icon: Icons.receipt_long_outlined,
              title: 'No Received Invoices Found',
              subtitle: 'No payout receipts match your current filter settings',
            )
          else
            ...invoices.map((inv) => _buildReceivedInvoiceCard(inv, isDark)),
        ],
      ),
    );
  }

  Widget _buildFinancialStatsBanner(bool isDark, double gross, double net, double tds) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Payouts Received',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      _formatCurrency(gross),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                    SizedBox(width: 4),
                    Text(
                      '100% Settled',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NET CREDITED TO BANK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatCurrency(net),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TDS (SEC 194H) CREDIT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatCurrency(tds),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceFilterRow(bool isDark) {
    final types = ['All', 'Booking', 'Site Visit', 'TDS 16A'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year selection row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FINANCIAL YEAR:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFinancialYear,
                  isDense: true,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                  ),
                  dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                  items: ['FY 2024-25', 'FY 2023-24', 'All'].map((year) {
                    return DropdownMenuItem(value: year, child: Text(year));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedFinancialYear = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Type filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: types.map((type) {
              final isSelected = _selectedInvoiceType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedInvoiceType = type);
                  },
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  selectedColor: const Color(0xFF2563EB),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextPrimary : const Color(0xFF334155)),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReceivedInvoiceCard(ReceivedInvoiceModel inv, bool isDark) {
    final isTds = inv.type == ReceivedInvoiceType.tdsCertificate16A;
    final isVisit = inv.type == ReceivedInvoiceType.siteVisitPayout;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openInvoiceVoucherModal(context, inv),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Top: Voucher ID + Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isTds
                                  ? const Color(0xFF8B5CF6)
                                  : isVisit
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF16A34A))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isTds
                              ? Icons.description_rounded
                              : isVisit
                                  ? Icons.directions_car_rounded
                                  : Icons.home_work_rounded,
                          size: 16,
                          color: isTds
                              ? const Color(0xFF8B5CF6)
                              : isVisit
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.voucherNumber,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${inv.disbursedDate.day} ${_getMonthName(inv.disbursedDate.month)} ${inv.disbursedDate.year}',
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text(
                          'Credited',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Project & Client Info
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.projectName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Client: ${inv.clientName} ${inv.unitNumber != null ? '• ${inv.unitNumber}' : ''}',
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
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        inv.type.displayName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Breakdown & Amount Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gross Disbursed',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        _formatCurrency(inv.grossAmount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TDS (5% Sec 194H)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '- ${_formatCurrency(inv.tdsAmount)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Net Credited',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF16A34A),
                        ),
                      ),
                      Text(
                        _formatCurrency(inv.netAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9)),
              const SizedBox(height: 8),

              // Bottom Bar: Bank info & Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_outlined,
                        size: 14,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${inv.bankName} (${inv.bankAccountNumber})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_outlined, size: 16),
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        tooltip: 'Share Receipt',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text: 'Receipt #${inv.voucherNumber}: Disbursed ₹${inv.netAmount.toStringAsFixed(0)} for ${inv.projectName} (UTR: ${inv.utrNumber})',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Voucher details copied to clipboard for sharing!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        color: const Color(0xFF16A34A),
                        tooltip: 'Download PDF Voucher',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Downloading voucher ${inv.voucherNumber}...'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                          await FileDownloadService.downloadInvoiceVoucherPdf(
                            voucherNumber: inv.voucherNumber,
                            clientName: inv.clientName,
                            projectName: inv.projectName,
                            grossAmount: inv.grossAmount,
                            tdsAmount: inv.tdsAmount,
                            netAmount: inv.netAmount,
                            utrNumber: inv.utrNumber,
                            bankName: inv.bankName,
                            dateStr: '${inv.disbursedDate.day} ${_getMonthName(inv.disbursedDate.month)} ${inv.disbursedDate.year}',
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF2563EB)),
                        label: const Text(
                          'View Voucher',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        onPressed: () => _openInvoiceVoucherModal(context, inv),
                      ),
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

  // ==========================================
  // MODALS & SHEETS
  // ==========================================

  // 1. Upload / Update Document Modal
  void _openUploadDocModal(BuildContext context, CpDocumentModel? existingDoc) {
    final isDark = widget.state.isDarkMode;
    final docNumCtrl = TextEditingController(text: existingDoc?.documentNumber ?? '');
    final remarksCtrl = TextEditingController(text: existingDoc?.remarks ?? '');
    CpDocumentType selectedType = existingDoc?.type ?? CpDocumentType.reraCertificate;
    String selectedFileName = existingDoc?.fileName ?? 'Attach document (PDF, PNG, JPG)';
    String selectedFileSize = existingDoc?.fileSize ?? '1.5 MB';
    bool hasUserPickedFile = existingDoc?.fileName != null;
    DateTime? selectedExpiry = existingDoc?.expiresAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF2563EB), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              existingDoc != null ? 'Update ${existingDoc.title}' : 'Upload Required Document',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Submitted for compliance verification by developer desk',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Document Type Selector
                  if (existingDoc == null) ...[
                    Text(
                      'Document Type',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CpDocumentType>(
                          value: selectedType,
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                          items: CpDocumentType.values.map((t) {
                            return DropdownMenuItem(value: t, child: Text(t.displayName));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedType = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Document Identifier / Number Input
                  Text(
                    'Document Number / Reference ID *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: docNumCtrl,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. A51800034921 / ABCDE1234F',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // File Picker Simulation
                  Text(
                    'Attach File (PDF, JPG, PNG) *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await DocumentPickerService.pickAnyDocument();
                            if (picked != null) {
                              setModalState(() {
                                selectedFileName = picked.fileName;
                                selectedFileSize = picked.formattedSize;
                                hasUserPickedFile = true;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasUserPickedFile
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF2563EB).withValues(alpha: 0.4),
                                width: hasUserPickedFile ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selectedFileName.endsWith('.pdf') ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                                  color: hasUserPickedFile ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedFileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        hasUserPickedFile
                                            ? 'File attached • $selectedFileSize'
                                            : 'Tap to browse files on your device',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: hasUserPickedFile ? FontWeight.bold : FontWeight.normal,
                                          color: hasUserPickedFile
                                              ? const Color(0xFF16A34A)
                                              : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasUserPickedFile)
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2563EB), size: 20),
                        tooltip: 'Capture with Camera',
                        onPressed: () async {
                          final picked = await DocumentPickerService.pickDocumentFromCamera();
                          if (picked != null) {
                            setModalState(() {
                              selectedFileName = picked.fileName;
                              selectedFileSize = picked.formattedSize;
                              hasUserPickedFile = true;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Optional Expiry Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Validity / Expiry Date (Optional)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF2563EB)),
                        label: Text(
                          selectedExpiry != null
                              ? '${selectedExpiry!.day}/${selectedExpiry!.month}/${selectedExpiry!.year}'
                              : 'Set Date',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedExpiry ?? DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setModalState(() => selectedExpiry = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Remarks / Notes Field
                  Text(
                    'Remarks / Notes (Optional)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: remarksCtrl,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Updated corporate entity proof',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final numText = docNumCtrl.text.trim();
                        if (numText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter the document number / ID')),
                          );
                          return;
                        }

                        final targetId = existingDoc?.id ?? 'doc_${DateTime.now().millisecondsSinceEpoch}';
                        widget.state.uploadOrUpdateDocument(
                          documentId: targetId,
                          documentNumber: numText,
                          fileName: selectedFileName,
                          fileSize: selectedFileSize,
                          expiresAt: selectedExpiry,
                          documentType: selectedType,
                          title: existingDoc?.title ?? selectedType.displayName,
                          remarks: remarksCtrl.text.trim().isNotEmpty ? remarksCtrl.text.trim() : null,
                        );

                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${existingDoc?.title ?? selectedType.displayName} uploaded successfully for verification!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Submit for Verification',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 2. Document Details & Preview Modal
  void _openDocPreviewModal(BuildContext context, CpDocumentModel doc) {
    final isDark = widget.state.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Category: ${doc.type.category}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusPill(doc.status, _getStatusColor(doc.status)),
                ],
              ),
              const SizedBox(height: 18),

              // Mock Certificate Graphic Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 40),
                    const SizedBox(height: 8),
                    Text(
                      doc.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E40AF),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doc.documentNumber.isNotEmpty ? doc.documentNumber : 'PENDING SUBMISSION',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2563EB),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'DIGITALLY REGISTERED & ENCRYPTED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Metadata Grid
              _buildMetaRow('File Attached', doc.fileName ?? 'None', isDark),
              _buildMetaRow('File Size', doc.fileSize ?? 'N/A', isDark),
              if (doc.uploadedAt != null)
                _buildMetaRow(
                  'Uploaded On',
                  '${doc.uploadedAt!.day}/${doc.uploadedAt!.month}/${doc.uploadedAt!.year}',
                  isDark,
                ),
              if (doc.expiresAt != null)
                _buildMetaRow(
                  'Expiry / Validity',
                  '${doc.expiresAt!.day}/${doc.expiresAt!.month}/${doc.expiresAt!.year}',
                  isDark,
                ),
              if (doc.remarks != null && doc.remarks!.isNotEmpty)
                _buildMetaRow('Compliance Notes', doc.remarks!, isDark),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF2563EB)),
                      label: const Text(
                        'Download PDF',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading ${doc.fileName ?? doc.title}...'),
                            backgroundColor: const Color(0xFF2563EB),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        await FileDownloadService.downloadDocumentPdf(
                          documentTitle: doc.title,
                          documentNumber: doc.documentNumber,
                          fileName: doc.fileName ?? '${doc.type.name}.pdf',
                          status: doc.status.displayName,
                          validTill: doc.expiresAt != null
                              ? '${doc.expiresAt!.day}/${doc.expiresAt!.month}/${doc.expiresAt!.year}'
                              : null,
                          partnerName: widget.state.currentUser?.name,
                          remarks: doc.remarks,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: const Text(
                        'Replace Doc',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Future.microtask(() {
                          if (context.mounted) {
                            _openUploadDocModal(context, doc);
                          }
                        });
                      },
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

  // 3. Official Digital Tax Invoice / Payment Voucher Modal
  void _openInvoiceVoucherModal(BuildContext context, ReceivedInvoiceModel inv) {
    final isDark = widget.state.isDarkMode;
    final user = widget.state.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle & Top Close
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Official Disbursal Voucher',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),

            // Printable Voucher Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Developer Letterhead
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DEVELOPER REALTY GROUP',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2563EB),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Corporate Finance & Partner Relations Desk',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PAID / SETTLED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'CIN: U45200MH2012PTC239812 • GSTIN: 27AABCD8891E1Z8',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Voucher Title & Reference
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VOUCHER NO:',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              inv.voucherNumber,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'DISBURSAL DATE:',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '${inv.disbursedDate.day} ${_getMonthName(inv.disbursedDate.month)} ${inv.disbursedDate.year}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Recipient (Channel Partner) Information Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBg : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ISSUED TO CHANNEL PARTNER:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.name.isNotEmpty == true ? user!.name : 'Channel Partner (Realtor)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            user?.firmName.isNotEmpty == true ? user!.firmName : 'Real Estate Advisory Firm',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                user?.reraNumber.isNotEmpty == true ? 'RERA: ${user!.reraNumber}' : 'RERA: Verified',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                              const SizedBox(width: 12),
                              Text(
                                'PAN: Verified',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Particulars Table
                    Text(
                      'PAYOUT PARTICULARS & TAX CALCULATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildTableRow('Description', 'Amount (INR)', isDark, isHeader: true),
                          _buildTableRow(
                            '${inv.type.displayName} - ${inv.projectName}\nClient: ${inv.clientName}${inv.unitNumber != null ? ' (${inv.unitNumber})' : ''}',
                            _formatCurrency(inv.grossAmount),
                            isDark,
                          ),
                          _buildTableRow(
                            'Less: TDS Under Section 194H @ ${(inv.tdsRate * 100).toInt()}%',
                            '- ${_formatCurrency(inv.tdsAmount)}',
                            isDark,
                            isNegative: true,
                          ),
                          _buildTableRow(
                            'NET AMOUNT DISBURSED & CREDITED',
                            _formatCurrency(inv.netAmount),
                            isDark,
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bank Disbursal & UTR Details
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Electronic Transfer Confirmation',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bank Name: ${inv.bankName}  •  Account: ${inv.bankAccountNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bank Transaction Ref (UTR): ${inv.utrNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Digital Verification Seal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VERIFICATION SEAL:',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DIGITALLY AUTHENTICATED\nDEVELOPER FINANCE DESK',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Icon(Icons.qr_code_2_rounded, size: 54, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFF2563EB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF2563EB)),
                            label: const Text(
                              'Share Voucher',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                text: 'Official Payment Voucher ${inv.voucherNumber} for ₹${inv.netAmount.toStringAsFixed(0)} (UTR: ${inv.utrNumber})',
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Voucher details copied to clipboard!')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text(
                              'Download PDF',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Downloading voucher ${inv.voucherNumber}...'),
                                  backgroundColor: const Color(0xFF16A34A),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                              await FileDownloadService.downloadInvoiceVoucherPdf(
                                voucherNumber: inv.voucherNumber,
                                clientName: inv.clientName,
                                projectName: inv.projectName,
                                grossAmount: inv.grossAmount,
                                tdsAmount: inv.tdsAmount,
                                netAmount: inv.netAmount,
                                utrNumber: inv.utrNumber,
                                bankName: inv.bankName,
                                dateStr: '${inv.disbursedDate.day} ${_getMonthName(inv.disbursedDate.month)} ${inv.disbursedDate.year}',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable Small Widgets ---

  Widget _buildSearchField(bool isDark, {required String hint}) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        fontSize: 13,
        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
        ),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF2563EB)),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(CpDocumentStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String title, String amount, bool isDark, {bool isHeader = false, bool isNegative = false, bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isHeader
            ? (isDark ? AppColors.darkBg : const Color(0xFFF1F5F9))
            : isTotal
                ? (const Color(0xFF16A34A).withValues(alpha: 0.08))
                : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: isTotal ? 0 : 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isTotal ? 12 : 11,
                fontWeight: isHeader || isTotal ? FontWeight.w800 : FontWeight.w600,
                color: isTotal
                    ? const Color(0xFF16A34A)
                    : isDark
                        ? AppColors.darkTextPrimary
                        : const Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 13 : 11,
              fontWeight: isHeader || isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isNegative
                  ? const Color(0xFFEF4444)
                  : isTotal
                      ? const Color(0xFF16A34A)
                      : isDark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Functions ---
  Color _getStatusColor(CpDocumentStatus status) {
    switch (status) {
      case CpDocumentStatus.verified:
        return const Color(0xFF16A34A);
      case CpDocumentStatus.underReview:
        return const Color(0xFFD97706);
      case CpDocumentStatus.missing:
        return const Color(0xFFEF4444);
      case CpDocumentStatus.expired:
        return const Color(0xFFDC2626);
    }
  }

  IconData _getDocIcon(CpDocumentType type) {
    switch (type) {
      case CpDocumentType.reraCertificate:
        return Icons.verified_user_rounded;
      case CpDocumentType.panCard:
        return Icons.badge_rounded;
      case CpDocumentType.gstCertificate:
        return Icons.receipt_long_rounded;
      case CpDocumentType.aadhaarCard:
        return Icons.credit_card_rounded;
      case CpDocumentType.cpAgreement:
        return Icons.assignment_rounded;
      case CpDocumentType.cancelledCheque:
        return Icons.account_balance_rounded;
      case CpDocumentType.other:
        return Icons.folder_shared_rounded;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)} K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }
}
