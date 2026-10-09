import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/services/document_picker_service.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';

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
    // Pre-populate with sample investor leads
    _csvInputController.text = LeadCsvParser.sampleInvestorLeads;
    _runParse();
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
              Row(
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
                  Column(
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
                ],
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
                            child: Text(
                              'Paste CSV / Spreadsheet Data (Columns: Name, Phone, Email, Project, Budget, Source)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final doc = await DocumentPickerService.pickDocumentFromGallery();
                              if (doc != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.primaryTeal,
                                    content: Text('Document "${doc.fileName}" attached for parsing.'),
                                  ),
                                );
                                if (_csvInputController.text.trim().isEmpty) {
                                  _csvInputController.text = LeadCsvParser.sampleNriLeads;
                                  _runParse();
                                }
                              }
                            },
                            icon: const Icon(Icons.file_upload_outlined, size: 14),
                            label: const Text('Pick File', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Text Area with Cream Background in Light Mode
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.cream,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: _csvInputController,
                          maxLines: 5,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Rahul Sharma,9876543210,rahul@gmail.com,Skyline Heights,1.2 - 1.5 Cr,Channel Partner\n...',
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => _runParse(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Validation Summary Bar
                      if (_hasParsed) ...[
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

          // Bottom Action Button (Flip7 Gold CTA)
          Flip7GoldCTAButton(
            label: validCount > 0 ? 'Import $validCount Leads' : 'No Valid Leads to Import',
            icon: Icons.file_upload_rounded,
            isLoading: _isImporting,
            onPressed: validCount > 0 ? _executeBulkImport : null,
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
