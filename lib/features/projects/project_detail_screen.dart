import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/url_action_service.dart';
import '../../core/services/file_download_service.dart';
import '../../core/services/document_picker_service.dart';
import '../../shared/widgets/powered_by_branding.dart';
import 'edit_project_modal.dart';

class ProjectDetailScreen extends StatefulWidget {
  final AppState state;
  final ProjectModel project;
  final String initialSection; // 'details' or 'brochure'

  const ProjectDetailScreen({
    super.key,
    required this.state,
    required this.project,
    this.initialSection = 'details',
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  String _selectedTower = '';
  String _selectedUnitFilter = 'ALL';
  late String _activeSection;

  @override
  void initState() {
    super.initState();
    _selectedTower = 'All Towers';
    _activeSection = widget.initialSection;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final p = widget.project;
    final units = p.units.where((u) {
      final matchTower = _selectedTower == 'All Towers' || _selectedTower.isEmpty || u.tower == _selectedTower;
      final matchStatus = _selectedUnitFilter == 'ALL' ||
          (_selectedUnitFilter == 'AVAILABLE' && u.status == UnitStatus.available) ||
          (_selectedUnitFilter == 'BLOCKED' && u.status == UnitStatus.blocked) ||
          (_selectedUnitFilter == 'SOLD' && u.status == UnitStatus.sold);
      return matchTower && matchStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFD97706)),
            tooltip: 'Edit Project Details',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => EditProjectModalSheet(
                  state: widget.state,
                  project: p,
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 850;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info (Name, Price, Location)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                      child: Text(p.startingPrice, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(p.location, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                const SizedBox(height: 12),

                // Distance & Connectivity Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_subway, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.distanceDetails,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Multi-Column Layout: Side-by-side on wide/desktop, Segmented switcher on mobile
                if (isWide) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildDetailsColumn(context, p, units, isDark),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 4,
                        child: _buildBrochureColumn(context, p, isDark),
                      ),
                    ],
                  ),
                ] else ...[
                  // Mobile / Compact: Segmented tab switcher on the same page
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _activeSection = 'details'),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _activeSection == 'details'
                                    ? const Color(0xFF2563EB)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.domain_rounded,
                                    size: 16,
                                    color: _activeSection == 'details'
                                        ? Colors.white
                                        : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Project Details',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: _activeSection == 'details'
                                          ? Colors.white
                                          : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _activeSection = 'brochure'),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _activeSection == 'brochure'
                                    ? const Color(0xFF7C3AED)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.article_rounded,
                                    size: 16,
                                    color: _activeSection == 'brochure'
                                        ? Colors.white
                                        : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Brochure & Collateral',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: _activeSection == 'brochure'
                                          ? Colors.white
                                          : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_activeSection == 'details')
                    _buildDetailsColumn(context, p, units, isDark)
                  else
                    _buildBrochureColumn(context, p, isDark),
                ],
                const SizedBox(height: 24),
                PoweredByBranding(isDark: isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsColumn(
    BuildContext context,
    ProjectModel p,
    List<UnitModel> units,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interactive Unit Inventory Explorer Section (No Cost Estimator button)
        const Text(
          'Unit Inventory & Pricing Matrix',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Tower Selector Chips
        if (p.towers.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All Towers', ...p.towers].map((t) {
                final isSelected = _selectedTower == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedTower = t),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 10),

        // Unit Status Legend & Filter
        Row(
          children: [
            _buildUnitStatusFilter('ALL', 'All Units', Colors.grey),
            const SizedBox(width: 6),
            _buildUnitStatusFilter('AVAILABLE', 'Available', AppColors.success),
            const SizedBox(width: 6),
            _buildUnitStatusFilter('BLOCKED', 'Blocked', AppColors.warning),
            const SizedBox(width: 6),
            _buildUnitStatusFilter('SOLD', 'Sold', AppColors.danger),
          ],
        ),
        const SizedBox(height: 12),

        // Units Grid
        if (units.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.domain_disabled_rounded,
                  size: 36,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No units match the selected filters',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
            ),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final u = units[index];
              return _buildUnitCard(context, u, isDark);
            },
          ),
        const SizedBox(height: 24),

        // Master Amenities
        const Text('Master Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: p.amenities.map((a) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(a, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Approved Banks
        const Text('Approved Home Loan Banks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: p.approvedBanks.map((b) {
            return Chip(
              avatar: const Icon(Icons.account_balance, size: 14, color: AppColors.primary),
              label: Text(b, style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBrochureColumn(BuildContext context, ProjectModel p, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Brochure & Marketing Deck',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildBrochureCard(context, p, isDark),
        const SizedBox(height: 16),

        // Project Specifications Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 18, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Text(
                    'RERA & Project Specifications',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSpecRow('RERA Number', p.reraNumber, isDark),
              _buildSpecRow('Project Type', p.type, isDark),
              _buildSpecRow('Possession Date', p.possessionDate, isDark),
              _buildSpecRow('Towers', '${p.towers.length} Towers (${p.towers.join(", ")})', isDark),
              _buildSpecRow('Total Inventory', '${p.units.length} Units', isDark),
              _buildSpecRow('Starting Price', p.startingPrice, isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Collaterals & Downloads Summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_copy_outlined, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Marketing Assets & Collaterals',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildCollateralRow('Master Floor Plan (All Configurations)', 'PDF • 4.8 MB', Icons.layers_outlined, isDark),
              _buildCollateralRow('Price List & Payment Schedule', 'XLSX • 1.2 MB', Icons.table_chart_outlined, isDark),
              _buildCollateralRow('Walkthrough & Drone Video', 'MP4 • 24.1 MB', Icons.play_circle_outline, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value, bool isDark) {
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollateralRow(String title, String meta, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  meta,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildUnitStatusFilter(String key, String label, Color color) {
    final isSelected = _selectedUnitFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedUnitFilter = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? color : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context, UnitModel unit, bool isDark) {
    Color statusColor;
    String statusText;
    switch (unit.status) {
      case UnitStatus.available:
        statusColor = AppColors.success;
        statusText = 'AVAILABLE';
        break;
      case UnitStatus.blocked:
        statusColor = AppColors.warning;
        statusText = 'BLOCKED (${unit.holdExpiresAt ?? "Hold"})';
        break;
      case UnitStatus.sold:
        statusColor = AppColors.danger;
        statusText = 'SOLD';
        break;
    }

    return Card(
      child: InkWell(
        onTap: () => _showUnitActionSheet(context, unit),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unit ${unit.unitNo}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${unit.bhk} • ${unit.carpetArea.toInt()} sq.ft', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('${unit.facing} Facing • Floor ${unit.floor}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                ],
              ),
              Text(
                '₹${(unit.basePrice / 100000).toStringAsFixed(2)} Lakhs',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnitActionSheet(BuildContext context, UnitModel unit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unit ${unit.unitNo} Specifications', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Configuration: ${unit.bhk} (${unit.carpetArea} sq.ft carpet / ${unit.superArea} sq.ft SBA)'),
              Text('Facing: ${unit.facing} | Floor: ${unit.floor}'),
              Text('Base Price: ₹${(unit.basePrice / 100000).toStringAsFixed(2)} Lakhs', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 20),

              if (unit.status == UnitStatus.available) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showHoldRequestDialog(context, unit);
                  },
                  icon: const Icon(Icons.lock_clock),
                  label: const Text('Request 24-Hour Temporary Unit Hold'),
                ),
                const SizedBox(height: 8),
              ],

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final msg = 'Unit ${unit.unitNo} in ${widget.project.name} (${unit.bhk}, ${unit.carpetArea} sq.ft) is available at ₹${(unit.basePrice / 100000).toStringAsFixed(2)} Lakhs.';
                  UrlActionService.shareContent(context, text: msg);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Unit Specs with Client'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHoldRequestDialog(BuildContext context, UnitModel unit) {
    final noteController = TextEditingController();
    String selectedLeadId = widget.state.allLeads.isNotEmpty ? widget.state.allLeads.first.id : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('24h Hold: Unit ${unit.unitNo}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Request temporary reservation for 24 hours to finalize client booking token.'),
              const SizedBox(height: 12),
              if (widget.state.allLeads.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: selectedLeadId,
                  items: widget.state.allLeads.map((l) => DropdownMenuItem(value: l.id, child: Text(l.fullName))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedLeadId = val);
                  },
                  decoration: const InputDecoration(labelText: 'Attributed Lead'),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Client Commitment Note', hintText: 'Token deposit expected by tomorrow'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                widget.state.requestUnitHold(
                  projectId: widget.project.id,
                  unitNo: unit.unitNo,
                  leadId: selectedLeadId,
                  notes: noteController.text,
                );
                Navigator.of(ctx).pop();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('24-Hour Unit Hold Confirmed!')),
                );
              },
              child: const Text('Submit Hold Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _openCostEstimator(BuildContext context, ProjectModel project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => CostEstimatorSheet(state: widget.state, project: project),
    );
  }

  Widget _buildBrochureCard(BuildContext context, ProjectModel p, bool isDark) {
    final brochureName = p.brochureFileName ?? '${p.name.replaceAll(' ', '_')}_Brochure.pdf';
    final brochureSize = p.brochureFileSize ?? '3.4 MB';
    final hasCustomBrochure = p.brochureFileName != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Project Brochure & Collateral',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hasCustomBrochure ? 'Custom Upload' : 'Official PDF',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$brochureName • $brochureSize',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    side: const BorderSide(color: Color(0xFF25D366)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 15, color: Color(0xFF16A34A)),
                  label: const Text(
                    'Share WhatsApp',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                  ),
                  onPressed: () {
                    final shareText = '🌟 *${p.name}* (${p.location})\n'
                        '💰 Starting at *${p.startingPrice}*\n'
                        '🏢 Status: ${p.type} • Possession: ${p.possessionDate}\n'
                        '📋 RERA: ${p.reraNumber}\n'
                        '📄 Attached Brochure: $brochureName ($brochureSize)\n\n'
                        'Shared by ${widget.state.currentUser?.firmName ?? 'Channel Partner'}.\n'
                        'Contact: ${widget.state.currentUser?.phone ?? ''}';
                    UrlActionService.openWhatsApp(context, message: shareText);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 15),
                  label: const Text(
                    'Download',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading brochure: $brochureName...'),
                        backgroundColor: const Color(0xFF2563EB),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    await FileDownloadService.downloadProjectBrochurePdf(
                      projectName: p.name,
                      location: p.location,
                      startingPrice: p.startingPrice,
                      fileName: brochureName,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openBrochureUploadModal(BuildContext context, ProjectModel p) {
    final isDark = widget.state.isDarkMode;
    String pickedName = p.brochureFileName ?? '${p.name.replaceAll(' ', '_')}_Brochure.pdf';
    String pickedSize = p.brochureFileSize ?? '3.4 MB';
    bool hasSelectedNew = false;

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
                        child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Project Brochure',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Upload official marketing deck or brochure for ${p.name}',
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
                  const SizedBox(height: 20),
                  Text(
                    'Select PDF File *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await DocumentPickerService.pickAnyDocument(accept: '.pdf');
                      if (picked != null) {
                        setModalState(() {
                          pickedName = picked.fileName;
                          pickedSize = picked.formattedSize;
                          hasSelectedNew = true;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasSelectedNew
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF2563EB).withValues(alpha: 0.4),
                          width: hasSelectedNew ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            color: hasSelectedNew ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pickedName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasSelectedNew ? 'Ready to attach • $pickedSize' : 'Tap to browse PDF on your device',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: hasSelectedNew
                                        ? const Color(0xFF16A34A)
                                        : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                                    fontWeight: hasSelectedNew ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasSelectedNew)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20)
                          else
                            const Icon(Icons.file_upload_outlined, color: Color(0xFF2563EB), size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        widget.state.updateProjectBrochure(
                          projectId: p.id,
                          fileName: pickedName,
                          fileSize: pickedSize,
                        );
                        setState(() {
                          p.brochureFileName = pickedName;
                          p.brochureFileSize = pickedSize;
                          p.brochureUpdatedAt = DateTime.now();
                        });
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Brochure attached successfully for ${p.name}!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Save Project Brochure', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
}

class CostEstimatorSheet extends StatefulWidget {
  final AppState state;
  final ProjectModel project;

  const CostEstimatorSheet({super.key, required this.state, required this.project});

  @override
  State<CostEstimatorSheet> createState() => _CostEstimatorSheetState();
}

class _CostEstimatorSheetState extends State<CostEstimatorSheet> {
  final double _basePrice = 8500000;
  final double _floorRise = 150000;
  final double _clubhouseCharges = 350000;
  final double _carParking = 400000;
  final double _gstRate = 0.05; // 5%
  final double _stampDutyRate = 0.056; // 5.6%

  @override
  Widget build(BuildContext context) {
    final agreementValue = _basePrice + _floorRise + _clubhouseCharges + _carParking;
    final gst = agreementValue * _gstRate;
    final stampDuty = agreementValue * _stampDutyRate;
    final totalCost = agreementValue + gst + stampDuty;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Mobile Cost Estimator — ${widget.project.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _buildCostRow('Base Unit Price', '₹${(_basePrice / 100000).toStringAsFixed(2)} L', true),
            _buildCostRow('Floor Rise & Premium Facing', '₹${(_floorRise / 100000).toStringAsFixed(2)} L', false),
            _buildCostRow('Clubhouse & Amenities Fee', '₹${(_clubhouseCharges / 100000).toStringAsFixed(2)} L', false),
            _buildCostRow('Covered Car Parking', '₹${(_carParking / 100000).toStringAsFixed(2)} L', false),
            const Divider(),
            _buildCostRow('Agreement Value', '₹${(agreementValue / 100000).toStringAsFixed(2)} Lakhs', true),
            _buildCostRow('Estimated GST (5%)', '₹${(gst / 100000).toStringAsFixed(2)} Lakhs', false),
            _buildCostRow('Estimated Stamp Duty & Reg (5.6%)', '₹${(stampDuty / 100000).toStringAsFixed(2)} Lakhs', false),
            const Divider(thickness: 1.5),
            _buildCostRow('Total Estimated All-Inclusive Cost', '₹${(totalCost / 100000).toStringAsFixed(2)} Lakhs', true, color: AppColors.primary),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                final text = '''
*Cost Estimation — ${widget.project.name}*
Agreement Value: ₹${(agreementValue / 100000).toStringAsFixed(2)} Lakhs
GST (5%): ₹${(gst / 100000).toStringAsFixed(2)} Lakhs
Stamp Duty & Reg: ₹${(stampDuty / 100000).toStringAsFixed(2)} Lakhs
------------------------------
*Total All-Inclusive: ₹${(totalCost / 100000).toStringAsFixed(2)} Lakhs*

Shared by: ${widget.state.currentUser?.firmName}
RERA: ${widget.state.currentUser?.reraNumber}
Phone: ${widget.state.currentUser?.phone}
''';
                UrlActionService.shareContent(context, text: text);
              },
              icon: const Icon(Icons.chat),
              label: const Text('Share Cost Sheet via WhatsApp / Native Share'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.whatsapp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String title, String value, bool isBold, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
