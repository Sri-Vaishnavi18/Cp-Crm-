import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';

class BulkImportUnitsModalSheet extends StatefulWidget {
  final AppState state;
  final String? initialProjectId;

  const BulkImportUnitsModalSheet({
    super.key,
    required this.state,
    this.initialProjectId,
  });

  @override
  State<BulkImportUnitsModalSheet> createState() => _BulkImportUnitsModalSheetState();
}

class _BulkImportUnitsModalSheetState extends State<BulkImportUnitsModalSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _csvInputController = TextEditingController();
  late String _selectedProjectId;
  List<UnitImportRow> _parsedRows = [];
  bool _hasParsed = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.initialProjectId != null && widget.state.projects.any((p) => p.id == widget.initialProjectId)) {
      _selectedProjectId = widget.initialProjectId!;
    } else {
      _selectedProjectId = widget.state.projects.isNotEmpty ? widget.state.projects.first.id : 'p1';
    }

    _csvInputController.text = UnitCsvParser.sampleTowerAUnits;
    _runParse();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _csvInputController.dispose();
    super.dispose();
  }

  ProjectModel? get _currentProject {
    final idx = widget.state.projects.indexWhere((p) => p.id == _selectedProjectId);
    if (idx != -1) return widget.state.projects[idx];
    return widget.state.projects.isNotEmpty ? widget.state.projects.first : null;
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

    final project = _currentProject;
    final availableTowers = project?.towers ?? ['Tower A'];

    final rows = UnitCsvParser.parse(
      rawText: text,
      availableTowers: availableTowers,
    );

    // Validate duplicate against current project units
    final existingUnitNos = project?.units.map((u) => u.unitNo.trim().toUpperCase()).toSet() ?? {};

    for (final r in rows) {
      if (r.isValid && existingUnitNos.contains(r.unitNo.trim().toUpperCase())) {
        r.validationError = 'Already exists in project';
      }
    }

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
    final validUnits = _parsedRows
        .where((r) => r.isValid && r.validationError == null)
        .map((r) => r.toUnitModel())
        .toList();

    if (validUnits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid units to import. Please check for errors or duplicate unit numbers.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    setState(() => _isImporting = true);

    final count = widget.state.bulkImportUnits(_selectedProjectId, validUnits);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Added $count units to ${_currentProject?.name ?? "project"} inventory!'),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final validCount = _parsedRows.where((r) => r.isValid && r.validationError == null).length;
    final invalidOrDuplicateCount = _parsedRows.where((r) => !r.isValid || r.validationError != null).length;

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
                      color: AppColors.skyBlue.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: AppColors.skyBlue, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bulk Import Units',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Upload unit inventory matrix & pricing schedule',
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

          // Target Project Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceSubtle : AppColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.state.projects.any((p) => p.id == _selectedProjectId) ? _selectedProjectId : null,
                isExpanded: true,
                dropdownColor: isDark ? AppColors.darkSurfaceSubtle : Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryTeal),
                items: widget.state.projects.map((p) {
                  return DropdownMenuItem<String>(
                    value: p.id,
                    child: Row(
                      children: [
                        const Icon(Icons.apartment_rounded, size: 16, color: AppColors.primaryTeal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Target Project: ${p.name} (${p.units.length} units existing)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedProjectId = val;
                    });
                    _runParse();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

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
                gradient: AppColors.skyGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: Flip7Shadows.shadowSkyGlow,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              tabs: const [
                Tab(text: 'CSV / Unit Matrix'),
                Tab(text: 'Preset Inventory Templates'),
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
                      Text(
                        'Columns: UnitNo, Tower, Floor, BHK, CarpetArea, SuperArea, Facing, BasePrice, Status',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),

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
                            hintText: 'A-101,Tower A,1,2 BHK,780,1050,East,8500000,available\n...',
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => _runParse(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_hasParsed) ...[
                        Row(
                          children: [
                            _buildStatBadge(
                              label: '$validCount Valid Units',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.primaryTeal,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildStatBadge(
                              label: '$invalidOrDuplicateCount Conflicts',
                              icon: Icons.warning_rounded,
                              color: AppColors.coral,
                              isDark: isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Parsed Units (${_parsedRows.length} Total)',
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

                        ..._parsedRows.map((row) => _buildUnitPreviewRow(row, isDark)),
                      ],
                    ],
                  ),
                ),

                // TAB 2: Preset Templates
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a pre-configured inventory batch template:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildTemplateCard(
                        title: '1. Tower A - Typical Floors & Penthouse (6 Units)',
                        description: '2 BHK, 3 BHK, 3.5 BHK and Duplex Penthouse on 4th floor',
                        templateText: UnitCsvParser.sampleTowerAUnits,
                        icon: Icons.domain_rounded,
                        color: AppColors.primaryTeal,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),

                      _buildTemplateCard(
                        title: '2. Tower B - Compact Luxury & 4 BHK (5 Units)',
                        description: '2 BHK, 2.5 BHK, 3 BHK and 4 BHK Executive units',
                        templateText: UnitCsvParser.sampleTowerBUnits,
                        icon: Icons.location_city_rounded,
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

          // Bottom Action Button
          Flip7GoldCTAButton(
            label: validCount > 0 ? 'Commit $validCount Units to Project' : 'No Valid Units to Import',
            icon: Icons.add_to_photos_rounded,
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

  Widget _buildUnitPreviewRow(UnitImportRow row, bool isDark) {
    Color statusColor;
    String statusLabel;

    if (!row.isValid || row.validationError != null) {
      statusColor = AppColors.coral;
      statusLabel = row.validationError ?? 'Invalid';
    } else {
      switch (row.status) {
        case UnitStatus.available:
          statusColor = AppColors.primaryTeal;
          statusLabel = 'Available';
          break;
        case UnitStatus.blocked:
          statusColor = AppColors.accentGold;
          statusLabel = 'Blocked';
          break;
        case UnitStatus.sold:
          statusColor = AppColors.coral;
          statusLabel = 'Sold';
          break;
      }
    }

    final priceFormatted = row.basePrice >= 10000000
        ? '₹${(row.basePrice / 10000000).toStringAsFixed(2)} Cr'
        : '₹${(row.basePrice / 100000).toStringAsFixed(1)} L';

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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              row.unitNo.isNotEmpty ? row.unitNo : 'N/A',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: statusColor,
              ),
            ),
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
                      '${row.tower} • Floor ${row.floor} • ${row.bhk}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      priceFormatted,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${row.carpetArea.toStringAsFixed(0)} sq.ft carpet • ${row.facing} facing',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
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
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.skyBlue),
          ],
        ),
      ),
    );
  }
}
