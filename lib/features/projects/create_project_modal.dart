import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';

class CreateProjectModalSheet extends StatefulWidget {
  final AppState state;

  const CreateProjectModalSheet({super.key, required this.state});

  @override
  State<CreateProjectModalSheet> createState() => _CreateProjectModalSheetState();
}

class _CreateProjectModalSheetState extends State<CreateProjectModalSheet> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startingPriceController = TextEditingController(text: '85 L');
  final TextEditingController _reraController = TextEditingController();
  final TextEditingController _possessionController = TextEditingController(text: 'Dec 2026');
  final TextEditingController _towersController = TextEditingController(text: 'Tower A, Tower B');
  final TextEditingController _distanceController = TextEditingController(text: 'Metro Station: 1.2 km • Tech Park: 3.5 km');
  final TextEditingController _heroImageController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&auto=format&fit=crop&q=80',
  );

  String _selectedType = 'Ongoing';
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
  final Set<String> _selectedAmenities = {
    'Clubhouse',
    'Swimming Pool',
    'Gymnasium',
    'EV Charging Stations',
    '24/7 Multi-Tier Security',
  };

  final List<String> _allBanks = [
    'HDFC Bank',
    'State Bank of India',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra',
    'Bank of Baroda',
  ];
  final Set<String> _selectedBanks = {
    'HDFC Bank',
    'State Bank of India',
    'ICICI Bank',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _startingPriceController.dispose();
    _reraController.dispose();
    _possessionController.dispose();
    _towersController.dispose();
    _distanceController.dispose();
    _heroImageController.dispose();
    super.dispose();
  }

  void _submitProject() {
    if (_nameController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide Project Name and Location.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final towersList = _towersController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (towersList.isEmpty) {
      towersList.add('Tower A');
    }

    final rera = _reraController.text.trim().isNotEmpty
        ? _reraController.text.trim().toUpperCase()
        : 'PRM/KA/RERA/${now.year}/${(1000 + widget.state.projects.length + 1)}';

    // Seed default starter units for each tower
    final initialUnits = <UnitModel>[];
    for (final tower in towersList) {
      initialUnits.add(
        UnitModel(
          unitNo: '${tower.contains(' ') ? tower.split(' ').last : tower[0]}-101',
          tower: tower,
          floor: 1,
          bhk: '2 BHK',
          carpetArea: 850.0,
          superArea: 1150.0,
          facing: 'East',
          basePrice: 8500000.0,
          status: UnitStatus.available,
        ),
      );
      initialUnits.add(
        UnitModel(
          unitNo: '${tower.contains(' ') ? tower.split(' ').last : tower[0]}-201',
          tower: tower,
          floor: 2,
          bhk: '3 BHK',
          carpetArea: 1200.0,
          superArea: 1620.0,
          facing: 'North',
          basePrice: 12500000.0,
          status: UnitStatus.available,
        ),
      );
    }

    final project = ProjectModel(
      id: 'proj_${now.millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      startingPrice: _startingPriceController.text.trim(),
      reraNumber: rera,
      possessionDate: _possessionController.text.trim(),
      type: _selectedType,
      heroImageUrl: _heroImageController.text.trim(),
      galleryImages: [
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&auto=format&fit=crop&q=80',
      ],
      amenities: _selectedAmenities.toList(),
      approvedBanks: _selectedBanks.toList(),
      distanceDetails: _distanceController.text.trim(),
      towers: towersList,
      units: initialUnits,
    );

    widget.state.addProject(project);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Project "${project.name}" added successfully with ${initialUnits.length} starter units!'),
        backgroundColor: AppColors.primaryTeal,
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

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_business_rounded, color: AppColors.accentDark, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Project',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'List property inventory & RERA registration',
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

          // Form Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Name
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Project Name *',
                        hintText: 'e.g. Grand Horizon Towers',
                        prefixIcon: Icon(Icons.apartment_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Location
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location / Micro-Market *',
                        hintText: 'e.g. Whitefield Main Road, Bangalore',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Starting Price & Possession Date (2 columns)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startingPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Starting Price *',
                              hintText: 'e.g. 85 L / 1.2 Cr',
                              prefixIcon: Icon(Icons.currency_rupee_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _possessionController,
                            decoration: const InputDecoration(
                              labelText: 'Possession Date',
                              hintText: 'e.g. Dec 2026',
                              prefixIcon: Icon(Icons.event_available_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // RERA Number
                    TextField(
                      controller: _reraController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'RERA Number (Optional)',
                        hintText: 'e.g. PRM/KA/RERA/1251/446/PR/210312/004012',
                        prefixIcon: Icon(Icons.verified_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Project Type Selector
                    Text(
                      'Project Stage / Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableTypes.map((t) {
                        final isSelected = _selectedType == t;
                        return ChoiceChip(
                          label: Text(t),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedType = t);
                          },
                          selectedColor: AppColors.primaryTeal,
                          backgroundColor: isDark ? AppColors.darkSurfaceSubtle : AppColors.cream,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryTeal : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Towers
                    TextField(
                      controller: _towersController,
                      decoration: const InputDecoration(
                        labelText: 'Towers (Comma separated)',
                        hintText: 'e.g. Tower A, Tower B, Tower C',
                        prefixIcon: Icon(Icons.domain_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Key Distances & Landmarks
                    TextField(
                      controller: _distanceController,
                      decoration: const InputDecoration(
                        labelText: 'Connectivity & Distance Details',
                        hintText: 'e.g. Metro: 1.2 km • Airport: 35 mins • IT Park: 2 km',
                        prefixIcon: Icon(Icons.near_me_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Amenities Multi-Select Tags
                    Text(
                      'Project Amenities',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _allAmenities.map((amenity) {
                        final isSelected = _selectedAmenities.contains(amenity);
                        return FilterChip(
                          label: Text(amenity),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedAmenities.add(amenity);
                              } else {
                                _selectedAmenities.remove(amenity);
                              }
                            });
                          },
                          selectedColor: AppColors.skyBlue.withValues(alpha: 0.25),
                          checkmarkColor: AppColors.skyBlue,
                          backgroundColor: isDark ? AppColors.darkSurfaceSubtle : AppColors.cream,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.skyBlue
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(
                              color: isSelected ? AppColors.skyBlue : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Approved Banks Multi-Select Tags
                    Text(
                      'Approved Home Loan Banks',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _allBanks.map((bank) {
                        final isSelected = _selectedBanks.contains(bank);
                        return FilterChip(
                          label: Text(bank),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedBanks.add(bank);
                              } else {
                                _selectedBanks.remove(bank);
                              }
                            });
                          },
                          selectedColor: AppColors.primaryTeal.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primaryTeal,
                          backgroundColor: isDark ? AppColors.darkSurfaceSubtle : AppColors.cream,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primaryTeal
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryTeal : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          Flip7GoldCTAButton(
            label: 'Create Project & Publish Inventory',
            icon: Icons.check_circle_rounded,
            onPressed: _submitProject,
          ),
        ],
      ),
    );
  }
}
