import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/services/url_action_service.dart';
import '../../shared/widgets/app_widgets.dart';
import 'create_project_modal.dart';
import 'bulk_import_units_modal.dart';

class ProjectsScreen extends StatefulWidget {
  final AppState state;
  final Function(ProjectModel)? onSelectProject;

  const ProjectsScreen({super.key, required this.state, this.onSelectProject});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _selectedCategory = 'ALL';

  void _openCreateProjectModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateProjectModalSheet(state: widget.state),
    );
  }

  void _openBulkImportUnitsModal([String? projectId]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BulkImportUnitsModalSheet(
        state: widget.state,
        initialProjectId: projectId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final allProjects = widget.state.projects;
    final projects = _selectedCategory == 'ALL'
        ? allProjects
        : allProjects.where((p) => p.type == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        children: [
          // Top Action Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projects & Inventory',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'RERA inventory & live unit matrices',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Flip7PillButton(
                      label: 'Bulk Units',
                      icon: Icons.inventory_2_outlined,
                      variant: Flip7ButtonVariant.sky,
                      height: 38,
                      onPressed: () => _openBulkImportUnitsModal(),
                    ),
                    const SizedBox(width: 8),
                    Flip7GoldCTAButton(
                      label: '+ Create Project',
                      icon: Icons.add_business_rounded,
                      height: 38,
                      isFullWidth: false,
                      onPressed: _openCreateProjectModal,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip('ALL', 'All Projects (${allProjects.length})'),
                  _buildTabChip('Ongoing', 'Ongoing'),
                  _buildTabChip('Ready to Move', 'Ready to Move'),
                  _buildTabChip('Pre-Launch', 'Pre-Launch'),
                ],
              ),
            ),
          ),

          // Project Cards List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return _buildProjectCard(context, project, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    final isDark = widget.state.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = key),
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
            label,
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
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => ProjectDetailScreen(state: widget.state, project: project),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Container with Badges
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                  child: Image.network(
                    project.heroImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(child: Icon(Icons.apartment, size: 48, color: Colors.grey)),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      project.type,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Starts ${project.startingPrice}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          project.location,
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RERA: ${project.reraNumber.substring(0, 16)}...',
                        style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                      Text(
                        'Possession: ${project.possessionDate}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectDetailScreen extends StatefulWidget {
  final AppState state;
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.state, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  String _selectedTower = '';
  String _selectedUnitFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _selectedTower = widget.project.towers.first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final p = widget.project;
    final units = p.units.where((u) {
      final matchTower = u.tower == _selectedTower;
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
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Mobile Cost Estimator',
            onPressed: () => _openCostEstimator(context, p),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Photo
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey.shade900,
              child: Image.network(p.heroImageUrl, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),

            // Header Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 20),

                  // Interactive Unit Inventory Explorer Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Live Unit Inventory Matrix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.calculate, size: 16),
                        label: const Text('Cost Estimator', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _openCostEstimator(context, p),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tower Selector Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: p.towers.map((t) {
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
              ),
            ),
          ],
        ),
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
    String selectedLeadId = widget.state.allLeads.first.id;

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
