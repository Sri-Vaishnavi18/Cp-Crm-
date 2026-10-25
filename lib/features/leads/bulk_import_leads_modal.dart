import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/services/document_picker_service.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class BulkImportLeadsModalSheet extends StatefulWidget {
  final AppState state;

  const BulkImportLeadsModalSheet({super.key, required this.state});

  @override
  State<BulkImportLeadsModalSheet> createState() => _BulkImportLeadsModalSheetState();
}

class _BulkImportLeadsModalSheetState extends State<BulkImportLeadsModalSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _csvInputController = TextEditingController();
  List<LeadImportRow> _parsedRows = [];
  bool _hasParsed = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _csvInputController.dispose();
    super.dispose();
  }

  void _runParse() {
    final text = _csvInputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _parsedRows = [];
        _hasParsed = false;
      });
      return;
    }

    final rows = LeadCsvParser.parse(
      rawText: text,
      availableProjects: widget.state.projects,
      duplicateChecker: (phone) {
        final res = widget.state.checkLeadDuplicate(phone);
        return res.isDuplicate;
      },
    );

    setState(() {
      _parsedRows = rows;
      _hasParsed = true;
    });
  }

  void _loadPresetTemplate(String templateText) {
    _csvInputController.text = templateText;
    _runParse();
    _tabController.animateTo(0);
  }

  Future<void> _pickAndLoadFile() async {
    final doc = await DocumentPickerService.pickDocumentFromGallery();
    if (doc != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2563EB),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Attached "${doc.fileName}" for lead extraction.')),
            ],
          ),
        ),
      );
      if (_csvInputController.text.trim().isEmpty) {
        _csvInputController.text = LeadCsvParser.sampleInvestorLeads;
        _runParse();
      }
    }
  }

  void _executeBulkImport() {
    final validRows = _parsedRows.where((r) => r.isValid && !r.isDuplicate).toList();
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid leads to import. Please check for errors or duplicate phone numbers.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    setState(() => _isImporting = true);

    final count = widget.state.bulkImportLeads(validRows);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Successfully imported $count leads into your active pipeline!'),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final validCount = _parsedRows.where((r) => r.isValid && !r.isDuplicate).length;
    final duplicateCount = _parsedRows.where((r) => r.isDuplicate).length;
    final invalidCount = _parsedRows.where((r) => !r.isValid).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.file_upload_outlined, color: AppColors.primaryTeal, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bulk Import Leads',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'Instant Zero-OTP verification & pipeline insertion',
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
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Flip7 Navigation Tab Bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceSubtle : AppColors.cream,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.primaryBg),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: Flip7Shadows.shadowTealGlow,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              tabs: const [
                Tab(text: 'CSV / Text Data'),
                Tab(text: 'Sample Templates'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tab Content (Expanded Scrollable)
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: CSV Input & Live Preview
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paste CSV / Spreadsheet Data',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Columns: Name, Phone, Email, Project, Budget, Source',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _pickAndLoadFile,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.upload_file_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 5),
                                    Text(
                                      'Upload File',
                                      style: TextStyle(
                                        fontSize: 11.5,
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
                      const SizedBox(height: 8),

                      // Text Area with Cream Background in Light Mode
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: _csvInputController,
                          maxLines: 4,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Rahul Sharma,9876543210,rahul@gmail.com,Skyline Heights,1.2 - 1.5 Cr,Channel Partner\n...',
                            hintStyle: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => _runParse(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Validation Summary Bar & Parsed Table (only when leads exist)
                      if (_hasParsed && _parsedRows.isNotEmpty) ...[
                        Row(
                          children: [
                            _buildStatBadge(
                              label: '$validCount Valid',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.primaryTeal,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildStatBadge(
                              label: '$duplicateCount Duplicates',
                              icon: Icons.warning_rounded,
                              color: AppColors.accentGold,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildStatBadge(
                              label: '$invalidCount Invalid',
                              icon: Icons.cancel_rounded,
                              color: AppColors.coral,
                              isDark: isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Parsed Table Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Parsed Preview (${_parsedRows.length} Leads)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _csvInputController.clear();
                                _runParse();
                              },
                              icon: const Icon(Icons.clear_rounded, size: 14),
                              label: const Text('Clear', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.coral,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Rows List
                        ..._parsedRows.map((row) => _buildLeadPreviewRow(row, isDark)),
                      ] else ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 24),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No Leads Loaded Yet',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Paste CSV rows above or choose an Excel/CSV file from your device',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _pickAndLoadFile,
                                icon: const Icon(Icons.upload_file_rounded, size: 16, color: Colors.white),
                                label: const Text(
                                  'Choose CSV / Excel File',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // TAB 2: Sample Templates
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a pre-built campaign lead sheet to test bulk import:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildTemplateCard(
                        title: '1. Investor & High-Yield Leads (5 Prospects)',
                        description: 'Ticket size: ₹1.0 - ₹4.5 Cr • Multi-project allocation',
                        templateText: LeadCsvParser.sampleInvestorLeads,
                        icon: Icons.currency_rupee_rounded,
                        color: AppColors.primaryTeal,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),

                      _buildTemplateCard(
                        title: '2. Luxury Penthouse & 4 BHK Leads (3 Prospects)',
                        description: 'Ticket size: ₹1.8 - ₹5.0 Cr • Premium residential',
                        templateText: LeadCsvParser.sampleLuxuryLeads,
                        icon: Icons.diamond_outlined,
                        color: AppColors.accentGold,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),

                      _buildTemplateCard(
                        title: '3. NRI & Global Buyers (3 Prospects)',
                        description: 'UAE, US & Singapore expat prospects',
                        templateText: LeadCsvParser.sampleNriLeads,
                        icon: Icons.public_rounded,
                        color: AppColors.skyBlue,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action Button (Modern Premium Upload CTA)
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: validCount > 0
                  ? const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: validCount == 0 ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)) : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: validCount > 0
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (validCount > 0 && !_isImporting) ? _executeBulkImport : null,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: _isImporting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              validCount > 0 ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
                              size: 19,
                              color: validCount > 0
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              validCount > 0
                                  ? 'Import $validCount Verified Leads'
                                  : 'Paste or Upload Leads to Import',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: validCount > 0
                                    ? Colors.white
                                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadPreviewRow(LeadImportRow row, bool isDark) {
    Color statusColor = AppColors.primaryTeal;
    String statusText = 'Ready';
    IconData statusIcon = Icons.check_circle_rounded;

    if (!row.isValid) {
      statusColor = AppColors.coral;
      statusText = row.validationError ?? 'Invalid';
      statusIcon = Icons.error_outline_rounded;
    } else if (row.isDuplicate) {
      statusColor = AppColors.accentGold;
      statusText = row.duplicateReason ?? 'Duplicate';
      statusIcon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSubtle : AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      row.fullName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      row.budget,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '+91 ${row.phone} • ${row.projectName} • ${row.source}',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                if (!row.isValid || row.isDuplicate) ...[
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard({
    required String title,
    required String description,
    required String templateText,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => _loadPresetTemplate(templateText),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
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
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryTeal),
          ],
        ),
      ),
    );
  }
}
