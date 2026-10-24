import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/services/document_picker_service.dart';
import '../../core/services/file_download_service.dart';
import '../../core/services/url_action_service.dart';

class DocsScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback? onBack;
  final int initialTabIndex;

  const DocsScreen({
    super.key,
    required this.state,
    this.onBack,
    this.initialTabIndex = 0,
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
    final validIndex = (widget.initialTabIndex >= 0 && widget.initialTabIndex < 2)
        ? widget.initialTabIndex
        : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: validIndex);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(DocsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      final targetIndex = (widget.initialTabIndex >= 0 && widget.initialTabIndex < 2)
          ? widget.initialTabIndex
          : 0;
      if (_tabController.index != targetIndex) {
        _tabController.animateTo(targetIndex);
      }
    }
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
                      _buildCpDocsView(isDark),
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
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
        ],
      ),
    );
  }

  // --- Segmented Tab Switcher ---
  Widget _buildTabSwitcher(bool isDark, int missingCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 450;
        final docLabel = isCompact ? 'Required Docs' : 'CP Required Docs';
        final invoiceLabel = isCompact ? 'Invoices' : 'Invoices Received';

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
            labelStyle: TextStyle(
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                height: 42,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_shared_rounded, size: 16),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          docLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (missingCount > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
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
              ),
              Tab(
                height: 42,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 16),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          invoiceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _tabController.index == 1
                              ? Colors.white.withValues(alpha: 0.25)
                              : const Color(0xFF2563EB).withValues(alpha: 0.15),
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
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: CP REQUIRED DOCS VIEW
  // ==========================================

  Widget _buildCpDocsView(bool isDark) {
    final docs = _getFilteredDocuments();

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // Upload Document Button (Upside Search Bar)
          _buildUploadDocumentButton(isDark),
          const SizedBox(height: 12),

          // Search Field
          _buildSearchField(isDark, hint: 'Search RERA, PAN, GST, MOU...'),
          const SizedBox(height: 12),

          // Category Chips
          _buildDocCategoryChips(isDark),
          const SizedBox(height: 14),

          // Document List Count
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.state.cpDocuments.where((d) => d.status == CpDocumentStatus.verified || d.status == CpDocumentStatus.underReview).length} of ${widget.state.cpDocuments.length} Uploaded',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
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

  Widget _buildUploadDocumentButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openUploadDocModal(context, null),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Upload Document',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
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
    final isUploaded = doc.status == CpDocumentStatus.underReview || (doc.fileName != null && doc.fileName!.isNotEmpty);
    final statusColor = _getStatusColor(doc.status);
    final iconData = _getDocIcon(doc.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUploaded
              ? const Color(0xFF16A34A).withValues(alpha: 0.35)
              : (isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0)),
          width: isUploaded ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isUploaded
                ? const Color(0xFF16A34A).withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
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
              // Top Section: Icon, Title & Status Pill
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                doc.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusPill(doc.status, statusColor),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                doc.documentNumber.isNotEmpty
                                    ? 'Doc No: ${doc.documentNumber}'
                                    : 'No document number provided',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (doc.isMandatory) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                                ),
                                child: const Text(
                                  'Mandatory',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEF4444),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (doc.expiresAt != null) ...[
                          const SizedBox(height: 3),
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
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 10),

              // Bottom Section: Attachment info (clipped) & Action buttons (always visible)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isUploaded ? Icons.check_circle_rounded : Icons.attachment_rounded,
                          size: 14,
                          color: isUploaded ? const Color(0xFF16A34A) : (isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            doc.fileName != null && doc.fileName!.isNotEmpty
                                ? 'File attached • ${doc.fileName!}'
                                : 'No file attached',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isUploaded ? FontWeight.w700 : FontWeight.w500,
                              color: isUploaded ? const Color(0xFF16A34A) : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                        if (doc.fileName != null && doc.fileName!.isNotEmpty && doc.fileSize != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${doc.fileSize})',
                            style: TextStyle(
                              fontSize: 10,
                              color: isUploaded ? const Color(0xFF16A34A).withValues(alpha: 0.8) : (isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (doc.fileName != null && doc.fileName!.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final isImg = FileDownloadService.isImageFile(doc.fileName ?? '', doc.fileBytes);
                            return IconButton(
                              icon: Icon(isImg ? Icons.image_outlined : Icons.file_download_outlined, size: 18),
                              color: const Color(0xFF2563EB),
                              tooltip: isImg ? 'Download Image (${doc.fileName})' : 'Download PDF',
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              padding: const EdgeInsets.all(5),
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
                                  fileName: doc.fileName ?? (isImg ? '${doc.type.name}.png' : '${doc.type.name}.pdf'),
                                  status: doc.status.displayName,
                                  validTill: doc.expiresAt != null
                                      ? '${doc.expiresAt!.day}/${doc.expiresAt!.month}/${doc.expiresAt!.year}'
                                      : null,
                                  partnerName: widget.state.currentUser?.name,
                                  remarks: doc.remarks,
                                  documentType: doc.type,
                                  customBytes: doc.fileBytes,
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                      ],
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openUploadDocModal(context, doc),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isUploaded
                                  ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                  : const Color(0xFF2563EB).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isUploaded
                                    ? const Color(0xFF16A34A).withValues(alpha: 0.35)
                                    : const Color(0xFF2563EB).withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUploaded
                                      ? Icons.check_circle_rounded
                                      : (doc.status == CpDocumentStatus.missing
                                          ? Icons.add_rounded
                                          : Icons.cloud_upload_outlined),
                                  size: 14,
                                  color: isUploaded ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isUploaded
                                      ? 'Uploaded (Replace)'
                                      : (doc.status == CpDocumentStatus.missing ? 'Upload' : 'Replace'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isUploaded ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
              title: widget.state.receivedInvoices.isEmpty
                  ? 'No Received Invoices Yet'
                  : 'No Matching Invoices Found',
              subtitle: widget.state.receivedInvoices.isEmpty
                  ? 'Builder payout vouchers and credit advice will appear here once your submitted commission invoices are settled and credited.'
                  : 'No payout receipts match your current filter settings.',
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
                        onPressed: () => _openShareInvoiceModal(context, inv),
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
  // ========================================  // 1. Upload / Update Document Modal
  void _openUploadDocModal(BuildContext context, CpDocumentModel? existingDoc) {
    final isDark = widget.state.isDarkMode;
    final docNumCtrl = TextEditingController(text: existingDoc?.documentNumber ?? '');
    final remarksCtrl = TextEditingController(text: existingDoc?.remarks ?? '');
    CpDocumentType selectedType = existingDoc?.type ?? CpDocumentType.reraCertificate;
    String? selectedFileName = existingDoc?.fileName;
    String? selectedFileSize = existingDoc?.fileSize;
    List<int>? selectedFileBytes = existingDoc?.fileBytes;
    bool hasUserPickedFile = existingDoc?.fileName != null && existingDoc!.fileName!.isNotEmpty;
    DateTime? selectedExpiry = existingDoc?.expiresAt;
    String? docNumError;
    String? fileAttachmentError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isIdOptional = selectedType == CpDocumentType.cancelledCheque ||
              selectedType == CpDocumentType.specimenSignature ||
              selectedType == CpDocumentType.other;

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
                      IconButton(
                        onPressed: () => Navigator.of(modalCtx).maybePop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 4),
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
                            if (val != null) {
                              setModalState(() {
                                selectedType = val;
                                docNumError = null;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Document Identifier / Number Input
                  Text(
                    isIdOptional
                        ? 'Document Number / Reference ID (Optional)'
                        : 'Document Number / Reference ID *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: docNumCtrl,
                    onChanged: (val) {
                      if (docNumError != null) {
                        setModalState(() => docNumError = null);
                      }
                    },
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: selectedType == CpDocumentType.cancelledCheque
                          ? 'e.g. Bank Account / Cheque Ref (Optional)'
                          : (selectedType == CpDocumentType.specimenSignature
                              ? 'e.g. Signatory UID / Ref (Optional)'
                              : 'e.g. A51800034921 / ABCDE1234F'),
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                      ),
                      errorText: docNumError,
                      errorStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: docNumError != null
                              ? const Color(0xFFEF4444)
                              : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: docNumError != null ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                          width: 1.5,
                        ),
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
                                selectedFileBytes = picked.bytes;
                                hasUserPickedFile = true;
                                fileAttachmentError = null;
                                final lower = picked.fileName.toLowerCase();
                                if (existingDoc == null && (lower.contains('sign') || lower.contains('sig_') || lower.contains('signature'))) {
                                  selectedType = CpDocumentType.specimenSignature;
                                }
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
                                    : (fileAttachmentError != null
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF2563EB).withValues(alpha: 0.4)),
                                width: (hasUserPickedFile || fileAttachmentError != null) ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  (selectedFileName != null && selectedFileName!.toLowerCase().endsWith('.pdf'))
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.image_rounded,
                                  color: hasUserPickedFile
                                      ? const Color(0xFF16A34A)
                                      : (fileAttachmentError != null
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF2563EB)),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedFileName != null && selectedFileName!.isNotEmpty
                                            ? selectedFileName!
                                            : 'Attach document (PDF, PNG, JPG)',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: selectedFileName != null && selectedFileName!.isNotEmpty
                                              ? (isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B))
                                              : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                                        ),
                                      ),
                                      Text(
                                        hasUserPickedFile
                                            ? 'File attached • ${selectedFileSize ?? ''}'
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
                              selectedFileBytes = picked.bytes;
                              hasUserPickedFile = true;
                              fileAttachmentError = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (fileAttachmentError != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            fileAttachmentError!,
                            style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                        String numText = docNumCtrl.text.trim();

                        if (numText.isEmpty) {
                          if (isIdOptional) {
                            final prefix = selectedType == CpDocumentType.cancelledCheque
                                ? 'CHQ'
                                : (selectedType == CpDocumentType.specimenSignature ? 'SIG' : 'DOC');
                            numText = '$prefix-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                            docNumCtrl.text = numText;
                          } else {
                            setModalState(() {
                              docNumError = 'Please enter document number / reference ID';
                            });
                            return;
                          }
                        }

                        if (!hasUserPickedFile && (existingDoc?.fileName == null || existingDoc!.fileName!.isEmpty)) {
                          setModalState(() {
                            fileAttachmentError = 'Please attach a document file (PDF, PNG, JPG) before submitting.';
                          });
                          return;
                        }

                        final targetId = existingDoc?.id ?? 'doc_${DateTime.now().millisecondsSinceEpoch}';
                        final docTitle = existingDoc?.title ?? selectedType.displayName;

                        widget.state.uploadOrUpdateDocument(
                          documentId: targetId,
                          documentNumber: numText,
                          fileName: selectedFileName ?? 'document_${selectedType.name}.pdf',
                          fileSize: selectedFileSize ?? '1.2 MB',
                          expiresAt: selectedExpiry,
                          documentType: selectedType,
                          title: docTitle,
                          remarks: remarksCtrl.text.trim().isNotEmpty ? remarksCtrl.text.trim() : null,
                          fileBytes: selectedFileBytes,
                        );

                        Navigator.of(modalCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('$docTitle uploaded successfully for verification!'),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

              // Document Preview Graphic or Real Uploaded Image
              if (doc.fileBytes != null &&
                  doc.fileBytes!.isNotEmpty &&
                  FileDownloadService.isImageFile(doc.fileName ?? '', doc.fileBytes)) ...[
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 230),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.memory(
                          Uint8List.fromList(doc.fileBytes!),
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_rounded, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Uploaded Image Preview',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
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
              ],
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
              Builder(
                builder: (context) {
                  final isImg = FileDownloadService.isImageFile(doc.fileName ?? '', doc.fileBytes);
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Color(0xFF2563EB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: Icon(
                                isImg ? Icons.image_outlined : Icons.download_rounded,
                                size: 16,
                                color: const Color(0xFF2563EB),
                              ),
                              label: Text(
                                isImg ? 'Download Image' : 'Download PDF',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
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
                                  fileName: doc.fileName ?? (isImg ? '${doc.type.name}.png' : '${doc.type.name}.pdf'),
                                  status: doc.status.displayName,
                                  validTill: doc.expiresAt != null
                                      ? '${doc.expiresAt!.day}/${doc.expiresAt!.month}/${doc.expiresAt!.year}'
                                      : null,
                                  partnerName: widget.state.currentUser?.name,
                                  remarks: doc.remarks,
                                  documentType: doc.type,
                                  customBytes: doc.fileBytes,
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
                      if (isImg) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              foregroundColor: const Color(0xFF2563EB),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                            label: const Text(
                              'Export as Official PDF Certificate',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Exporting official PDF certificate for ${doc.title}...'),
                                  backgroundColor: const Color(0xFF2563EB),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                              await FileDownloadService.downloadDocumentPdf(
                                documentTitle: doc.title,
                                documentNumber: doc.documentNumber,
                                fileName: '${doc.type.name}_Certificate.pdf',
                                status: doc.status.displayName,
                                validTill: doc.expiresAt != null
                                    ? '${doc.expiresAt!.day}/${doc.expiresAt!.month}/${doc.expiresAt!.year}'
                                    : null,
                                partnerName: widget.state.currentUser?.name,
                                remarks: doc.remarks,
                                documentType: doc.type,
                                forcePdfCertificate: true,
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                },
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
                              Navigator.of(ctx).pop();
                              _openShareInvoiceModal(context, inv);
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

  // 3. Share Invoice Voucher Modal
  void _openShareInvoiceModal(BuildContext context, ReceivedInvoiceModel inv) {
    final isDark = widget.state.isDarkMode;
    final dateStr = '${inv.disbursedDate.day} ${_getMonthName(inv.disbursedDate.month)} ${inv.disbursedDate.year}';
    final formattedAmount = '₹${NumberFormat('#,##,###').format(inv.netAmount)}';
    final shareSummary = '📄 *COMMISSION DISBURSAL RECEIPT*\n'
        '• *Voucher No:* ${inv.voucherNumber}\n'
        '• *Project:* ${inv.projectName} (${inv.unitNumber})\n'
        '• *Client:* ${inv.clientName}\n'
        '• *Net Payout Credited:* $formattedAmount\n'
        '• *TDS Deducted (5%):* ₹${NumberFormat('#,##,###').format(inv.tdsAmount)}\n'
        '• *Bank & UTR:* ${inv.bankName} • ${inv.utrNumber}\n'
        '• *Disbursed Date:* $dateStr\n'
        '• *Status:* Verified & Credited\n\n'
        'Verified by Developer Finance Desk via CP CRM.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.share_rounded, color: Color(0xFF16A34A), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Payment Voucher',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${inv.voucherNumber} • $formattedAmount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Option 1: WhatsApp Share
              _buildShareOptionTile(
                icon: Icons.chat_bubble_rounded,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
                title: 'Share via WhatsApp',
                subtitle: 'Send formatted receipt directly to client or partner',
                isDark: isDark,
                onTap: () {
                  Navigator.of(ctx).pop();
                  UrlActionService.openWhatsApp(context, message: shareSummary);
                },
              ),
              const SizedBox(height: 10),

              // Option 2: Share PDF File
              _buildShareOptionTile(
                icon: Icons.picture_as_pdf_rounded,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                title: 'Share PDF Voucher File',
                subtitle: 'Send authentic PDF voucher via native share sheet',
                isDark: isDark,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Preparing PDF voucher for ${inv.voucherNumber}...'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: const Color(0xFF2563EB),
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
                    dateStr: dateStr,
                  );
                },
              ),
              const SizedBox(height: 10),

              // Option 3: System Share (All Apps)
              _buildShareOptionTile(
                icon: Icons.share_outlined,
                iconColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                title: 'Share via Other Apps',
                subtitle: 'Open native device share menu (Email, Messages, etc.)',
                isDark: isDark,
                onTap: () {
                  Navigator.of(ctx).pop();
                  UrlActionService.shareContent(
                    context,
                    text: shareSummary,
                    subject: 'Commission Disbursal Voucher ${inv.voucherNumber}',
                  );
                },
              ),
              const SizedBox(height: 10),

              // Option 4: Copy to Clipboard
              _buildShareOptionTile(
                icon: Icons.copy_rounded,
                iconColor: const Color(0xFF64748B),
                bgColor: const Color(0xFF64748B).withValues(alpha: 0.1),
                title: 'Copy Voucher Summary',
                subtitle: 'Copy structured text breakdown to clipboard',
                isDark: isDark,
                onTap: () {
                  Navigator.of(ctx).pop();
                  Clipboard.setData(ClipboardData(text: shareSummary));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voucher breakdown copied to clipboard!'),
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
              ),
            ],
          ),
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
    IconData icon;
    String displayLabel = status.displayName;
    Color pillColor = color;

    switch (status) {
      case CpDocumentStatus.verified:
        icon = Icons.check_circle_rounded;
        pillColor = const Color(0xFF16A34A);
        break;
      case CpDocumentStatus.underReview:
        icon = Icons.check_circle_rounded;
        displayLabel = 'Uploaded • In Review';
        pillColor = const Color(0xFF16A34A);
        break;
      case CpDocumentStatus.missing:
        icon = Icons.error_outline_rounded;
        break;
      case CpDocumentStatus.expired:
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: pillColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pillColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: pillColor),
          const SizedBox(width: 4),
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: pillColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
              ),
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
        return const Color(0xFF16A34A);
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
      case CpDocumentType.specimenSignature:
        return Icons.draw_rounded;
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
