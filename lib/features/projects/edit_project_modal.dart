import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/document_picker_service.dart';

class EditProjectModalSheet extends StatefulWidget {
  final AppState state;
  final ProjectModel project;

  const EditProjectModalSheet({
    super.key,
    required this.state,
    required this.project,
  });

  @override
  State<EditProjectModalSheet> createState() => _EditProjectModalSheetState();
}

class _EditProjectModalSheetState extends State<EditProjectModalSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Project Details Controllers
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _startingPriceController;
  late TextEditingController _reraController;
  late TextEditingController _possessionController;
  late TextEditingController _towersController;
  late TextEditingController _distanceController;
  late TextEditingController _heroImageController;

  late String _selectedType;
  final List<String> _availableTypes = ['Pre-Launch', 'Ongoing', 'Ready to Move'];

  final List<String> _allAmenities = [
    'Clubhouse',
    'Swimming Pool',
    'Gymnasium',
    'Children Play Area',
    'EV Charging Stations',
    'Jogging Track',
    'Tennis Court',
    '24/7 Multi-Tier Security',
    'Rooftop Lounge',
    'Landscaped Gardens',
  ];
  late Set<String> _selectedAmenities;

  final List<String> _allBanks = [
    'HDFC Bank',
    'State Bank of India',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra',
    'Bank of Baroda',
  ];
  late Set<String> _selectedBanks;

  // Units list
  late List<UnitModel> _units;

  // New Unit form state
  bool _showAddUnitForm = false;
  final TextEditingController _newUnitNoController = TextEditingController();
  final TextEditingController _newUnitFloorController = TextEditingController(text: '1');
  final TextEditingController _newUnitTowerController = TextEditingController(text: 'Tower A');
  final TextEditingController _newUnitCarpetController = TextEditingController(text: '950');
  final TextEditingController _newUnitPriceController = TextEditingController(text: '8500000');
  String _newUnitBhk = '2 BHK';
  String _newUnitFacing = 'East';
  UnitStatus _newUnitStatus = UnitStatus.available;

  // Brochure State
  late String _brochureFileName;
  late String _brochureFileSize;
  bool _hasCustomBrochureSelected = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final p = widget.project;
    _nameController = TextEditingController(text: p.name);
    _locationController = TextEditingController(text: p.location);
    _startingPriceController = TextEditingController(text: p.startingPrice);
    _reraController = TextEditingController(text: p.reraNumber);
    _possessionController = TextEditingController(text: p.possessionDate);
    _towersController = TextEditingController(text: p.towers.join(', '));
    _distanceController = TextEditingController(text: p.distanceDetails);
    _heroImageController = TextEditingController(text: p.heroImageUrl);

    _selectedType = _availableTypes.contains(p.type) ? p.type : 'Ongoing';
    _selectedAmenities = Set<String>.from(p.amenities);
    _selectedBanks = Set<String>.from(p.approvedBanks);

    _units = p.units
        .map(
          (u) => UnitModel(
            unitNo: u.unitNo,
            tower: u.tower,
            floor: u.floor,
            bhk: u.bhk,
            carpetArea: u.carpetArea,
            superArea: u.superArea,
            facing: u.facing,
            basePrice: u.basePrice,
            status: u.status,
            holdExpiresAt: u.holdExpiresAt,
          ),
        )
        .toList();

    _brochureFileName = p.brochureFileName ?? '${p.name.replaceAll(' ', '_')}_Brochure.pdf';
    _brochureFileSize = p.brochureFileSize ?? '3.4 MB';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _startingPriceController.dispose();
    _reraController.dispose();
    _possessionController.dispose();
    _towersController.dispose();
    _distanceController.dispose();
    _heroImageController.dispose();
    _newUnitNoController.dispose();
    _newUnitFloorController.dispose();
    _newUnitTowerController.dispose();
    _newUnitCarpetController.dispose();
    _newUnitPriceController.dispose();
    super.dispose();
  }

  void _addNewUnit() {
    final unitNo = _newUnitNoController.text.trim();
    if (unitNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Unit Number (e.g. A-102 or 305).'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    final floor = int.tryParse(_newUnitFloorController.text.trim()) ?? 1;
    final carpet = double.tryParse(_newUnitCarpetController.text.trim()) ?? 900.0;
    final superArea = carpet * 1.35;
    final price = double.tryParse(_newUnitPriceController.text.trim()) ?? 8500000.0;
    final tower = _newUnitTowerController.text.trim().isNotEmpty
        ? _newUnitTowerController.text.trim()
        : 'Tower A';

    setState(() {
      _units.add(
        UnitModel(
          unitNo: unitNo,
          tower: tower,
          floor: floor,
          bhk: _newUnitBhk,
          carpetArea: carpet,
          superArea: superArea,
          facing: _newUnitFacing,
          basePrice: price,
          status: _newUnitStatus,
        ),
      );
      _newUnitNoController.clear();
      _showAddUnitForm = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unit "$unitNo" added to $tower!'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  void _showEditUnitDialog(int index) {
    final unit = _units[index];
    final priceCtrl = TextEditingController(text: unit.basePrice.toStringAsFixed(0));
    final carpetCtrl = TextEditingController(text: unit.carpetArea.toStringAsFixed(0));
    final floorCtrl = TextEditingController(text: unit.floor.toString());
    UnitStatus currentStatus = unit.status;
    String currentBhk = unit.bhk;
    String currentFacing = unit.facing;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = widget.state.isDarkMode;
          return AlertDialog(
            title: Text('Edit Unit ${unit.unitNo} (${unit.tower})'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<UnitStatus>(
                    value: currentStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: UnitStatus.available, child: Text('Available')),
                      DropdownMenuItem(value: UnitStatus.blocked, child: Text('Blocked / Hold')),
                      DropdownMenuItem(value: UnitStatus.sold, child: Text('Sold')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => currentStatus = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: currentBhk,
                    decoration: const InputDecoration(labelText: 'Configuration'),
                    items: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Penthouse', 'Villa']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => currentBhk = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Base Price (₹)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: carpetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Carpet (sq.ft)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: floorCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Floor'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: currentFacing,
                    decoration: const InputDecoration(labelText: 'Facing'),
                    items: ['East', 'West', 'North', 'South', 'North-East', 'South-East']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => currentFacing = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newPrice = double.tryParse(priceCtrl.text.trim()) ?? unit.basePrice;
                  final newCarpet = double.tryParse(carpetCtrl.text.trim()) ?? unit.carpetArea;
                  final newFloor = int.tryParse(floorCtrl.text.trim()) ?? unit.floor;

                  setState(() {
                    _units[index] = UnitModel(
                      unitNo: unit.unitNo,
                      tower: unit.tower,
                      floor: newFloor,
                      bhk: currentBhk,
                      carpetArea: newCarpet,
                      superArea: newCarpet * 1.35,
                      facing: currentFacing,
                      basePrice: newPrice,
                      status: currentStatus,
                    );
                  });
                  Navigator.of(dialogCtx).pop();
                },
                child: const Text('Save Unit'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveChanges() {
    if (_nameController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide Project Name and Location.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    final towersList = _towersController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (towersList.isEmpty) {
      towersList.add('Tower A');
    }

    final updatedProject = ProjectModel(
      id: widget.project.id,
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      startingPrice: _startingPriceController.text.trim(),
      reraNumber: _reraController.text.trim(),
      possessionDate: _possessionController.text.trim(),
      type: _selectedType,
      heroImageUrl: _heroImageController.text.trim().isNotEmpty
          ? _heroImageController.text.trim()
          : widget.project.heroImageUrl,
      galleryImages: widget.project.galleryImages,
      amenities: _selectedAmenities.toList(),
      approvedBanks: _selectedBanks.toList(),
      distanceDetails: _distanceController.text.trim(),
      towers: towersList,
      units: List<UnitModel>.from(_units),
      brochureFileName: _brochureFileName,
      brochureFileSize: _brochureFileSize,
      brochureUpdatedAt: _hasCustomBrochureSelected ? DateTime.now() : widget.project.brochureUpdatedAt,
    );

    widget.state.updateProject(updatedProject);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Project "${updatedProject.name}" updated successfully!'),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;

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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, color: Color(0xFFD97706), size: 24),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Edit Project Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.project.name} • ${widget.project.location}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkSurfaceSubtle : Colors.grey.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Segmented Tabs
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
              labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              tabs: [
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.domain_rounded, size: 15),
                      SizedBox(width: 6),
                      Text('Project Info'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.meeting_room_rounded, size: 15),
                      const SizedBox(width: 5),
                      const Text('Units'),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_units.length}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, size: 15),
                      SizedBox(width: 6),
                      Text('Brochure'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProjectDetailsTab(isDark),
                _buildUnitDetailsTab(isDark),
                _buildBrochureTab(isDark),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons Footer
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 1: Project Details ---
  Widget _buildProjectDetailsTab(bool isDark) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name *',
                prefixIcon: Icon(Icons.apartment_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location / Micro-market *',
                prefixIcon: Icon(Icons.location_on_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startingPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Starting Price',
                      prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Project Stage',
                      prefixIcon: Icon(Icons.category_rounded, size: 18),
                    ),
                    items: _availableTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _possessionController,
                    decoration: const InputDecoration(
                      labelText: 'Possession Date',
                      prefixIcon: Icon(Icons.calendar_month_rounded, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _reraController,
                    decoration: const InputDecoration(
                      labelText: 'RERA Number',
                      prefixIcon: Icon(Icons.verified_rounded, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _towersController,
              decoration: const InputDecoration(
                labelText: 'Towers (comma-separated)',
                prefixIcon: Icon(Icons.layers_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _distanceController,
              decoration: const InputDecoration(
                labelText: 'Connectivity / Distance Highlights',
                prefixIcon: Icon(Icons.directions_subway_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _heroImageController,
              decoration: const InputDecoration(
                labelText: 'Hero Image URL',
                prefixIcon: Icon(Icons.image_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 16),

            // Amenities Multi-Select
            Text(
              'Amenities & Highlights',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allAmenities.map((amenity) {
                final isSelected = _selectedAmenities.contains(amenity);
                return FilterChip(
                  label: Text(amenity, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFF2563EB),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedAmenities.add(amenity);
                      } else {
                        _selectedAmenities.remove(amenity);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Approved Banks Multi-Select
            Text(
              'Approved Banks',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allBanks.map((bank) {
                final isSelected = _selectedBanks.contains(bank);
                return FilterChip(
                  label: Text(bank, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF16A34A).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFF16A34A),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedBanks.add(bank);
                      } else {
                        _selectedBanks.remove(bank);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: Unit Details / Inventory Management ---
  Widget _buildUnitDetailsTab(bool isDark) {
    final availableCount = _units.where((u) => u.status == UnitStatus.available).length;
    final blockedCount = _units.where((u) => u.status == UnitStatus.blocked).length;
    final soldCount = _units.where((u) => u.status == UnitStatus.sold).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Units Inventory Metrics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildUnitMetric('Total', '${_units.length}', const Color(0xFF2563EB)),
                _buildUnitMetric('Available', '$availableCount', const Color(0xFF16A34A)),
                _buildUnitMetric('Hold', '$blockedCount', const Color(0xFFD97706)),
                _buildUnitMetric('Sold', '$soldCount', const Color(0xFFDC2626)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Add Unit Toggle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Project Units Inventory',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showAddUnitForm = !_showAddUnitForm),
                icon: Icon(
                  _showAddUnitForm ? Icons.remove_circle_outline : Icons.add_circle_outline,
                  size: 16,
                  color: const Color(0xFF2563EB),
                ),
                label: Text(
                  _showAddUnitForm ? 'Close Form' : 'Add Unit',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),

          // Add Unit Inline Form
          if (_showAddUnitForm) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Unit to Inventory', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newUnitNoController,
                          decoration: const InputDecoration(labelText: 'Unit No *', hintText: 'A-302'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _newUnitTowerController,
                          decoration: const InputDecoration(labelText: 'Tower', hintText: 'Tower A'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _newUnitBhk,
                          decoration: const InputDecoration(labelText: 'BHK'),
                          items: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Penthouse', 'Villa']
                              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _newUnitBhk = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _newUnitFloorController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Floor', hintText: '3'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newUnitCarpetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Carpet (sq.ft)', hintText: '950'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _newUnitPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Base Price (₹)', hintText: '8500000'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _newUnitFacing,
                          decoration: const InputDecoration(labelText: 'Facing'),
                          items: ['East', 'West', 'North', 'South', 'North-East', 'South-East']
                              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _newUnitFacing = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<UnitStatus>(
                          value: _newUnitStatus,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(value: UnitStatus.available, child: Text('Available')),
                            DropdownMenuItem(value: UnitStatus.blocked, child: Text('Hold')),
                            DropdownMenuItem(value: UnitStatus.sold, child: Text('Sold')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _newUnitStatus = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addNewUnit,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add to Inventory'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Units List
          if (_units.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text('No units added yet. Tap "+ Add Unit" above.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _units.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final u = _units[idx];
                Color statusColor;
                String statusLabel;
                switch (u.status) {
                  case UnitStatus.available:
                    statusColor = const Color(0xFF16A34A);
                    statusLabel = 'Available';
                    break;
                  case UnitStatus.blocked:
                    statusColor = const Color(0xFFD97706);
                    statusLabel = 'Hold';
                    break;
                  case UnitStatus.sold:
                    statusColor = const Color(0xFFDC2626);
                    statusLabel = 'Sold';
                    break;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${u.unitNo} (${u.tower})',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${u.bhk} • Floor ${u.floor} • ${u.carpetArea.toStringAsFixed(0)} sq.ft • ₹${(u.basePrice / 100000).toStringAsFixed(1)} L',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showEditUnitDialog(idx),
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                        tooltip: 'Edit Unit',
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _units.removeAt(idx));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Unit ${u.unitNo} deleted'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                        tooltip: 'Delete Unit',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUnitMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // --- TAB 3: Brochure Re-Upload & Collateral ---
  Widget _buildBrochureTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Brochure Status Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hasCustomBrochureSelected
                    ? const Color(0xFF16A34A)
                    : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                width: _hasCustomBrochureSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 26),
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
                              _brochureFileName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_hasCustomBrochureSelected) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Ready to Save',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Size: $_brochureFileSize • Official Project PDF',
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
          const SizedBox(height: 16),

          // Upload action
          Text(
            'Re-upload Project Brochure',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload a revised marketing deck, cost schedule, or high-res project brochure from your device.',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          InkWell(
            onTap: () async {
              final picked = await DocumentPickerService.pickAnyDocument(accept: '.pdf');
              if (picked != null) {
                setState(() {
                  _brochureFileName = picked.fileName;
                  _brochureFileSize = picked.formattedSize;
                  _hasCustomBrochureSelected = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected new brochure: ${picked.fileName}'),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSubtle : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_rounded, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Browse & Pick PDF File',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Presets / Quick Sample Replacements
          Text(
            'Or Select from Standard Templates',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          _buildPresetBrochureTile(
            title: 'Master Deck & Unit Layouts 2026',
            size: '4.8 MB',
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _buildPresetBrochureTile(
            title: 'Verified Cost Sheet & Payment Plan',
            size: '2.3 MB',
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _buildPresetBrochureTile(
            title: 'Floor Plans & Luxury Specifications',
            size: '5.2 MB',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetBrochureTile({
    required String title,
    required String size,
    required bool isDark,
  }) {
    final cleanFileName = '${widget.project.name.replaceAll(' ', '_')}_$title.pdf';
    final isCurrent = _brochureFileName == cleanFileName;

    return InkWell(
      onTap: () {
        setState(() {
          _brochureFileName = cleanFileName;
          _brochureFileSize = size;
          _hasCustomBrochureSelected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected template: $title'),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(milliseconds: 900),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrent
              ? const Color(0xFF2563EB).withValues(alpha: 0.1)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrent
                ? const Color(0xFF2563EB)
                : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCurrent ? Icons.check_circle_rounded : Icons.description_outlined,
              size: 18,
              color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                ),
              ),
            ),
            Text(
              size,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
