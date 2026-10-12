import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';

class CollateralsScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback? onBack;

  const CollateralsScreen({
    super.key,
    required this.state,
    this.onBack,
  });

  @override
  State<CollateralsScreen> createState() => _CollateralsScreenState();
}

class _CollateralsScreenState extends State<CollateralsScreen> {
  String _selectedCategory = 'All'; // All, Brochures, Price Lists, Floor Plans, Videos
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CollateralModel> _getFilteredCollaterals() {
    final all = widget.state.collaterals;
    final query = _searchController.text.trim().toLowerCase();

    return all.where((item) {
      if (_selectedCategory == 'Brochures' && item.category != 'Brochure') return false;
      if (_selectedCategory == 'Price Lists' && item.category != 'Price Sheet') return false;
      if (_selectedCategory == 'Floor Plans' && item.category != 'Floor Plan') return false;
      if (_selectedCategory == 'Videos' && item.category != 'Video') return false;

      if (query.isNotEmpty) {
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchProj = item.projectName.toLowerCase().contains(query);
        if (!matchTitle && !matchProj) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final collaterals = _getFilteredCollaterals();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header (Back arrow + Collateral + Search + Filter tune icon)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                    onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Collateral',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isSearching ? Icons.close_rounded : Icons.search_rounded,
                      size: 22,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF475569),
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) _searchController.clear();
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 22,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF475569),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Collateral filters active')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),

            // Search Bar Input (if active)
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search brochures, floor plans, price sheets...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF2563EB)),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0)),
                    ),
                  ),
                ),
              ),

            // 2. Circular Category Buttons Row (All, Brochures, Price Lists, Floor Plans, Videos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircularCategory(
                    icon: Icons.description_rounded,
                    label: 'All',
                    bgColor: const Color(0xFF2563EB),
                    iconColor: Colors.white,
                    isSelected: _selectedCategory == 'All',
                    onTap: () => setState(() => _selectedCategory = 'All'),
                  ),
                  _buildCircularCategory(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Brochures',
                    bgColor: const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFEF4444),
                    isSelected: _selectedCategory == 'Brochures',
                    onTap: () => setState(() => _selectedCategory = 'Brochures'),
                  ),
                  _buildCircularCategory(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Price Lists',
                    bgColor: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF16A34A),
                    isSelected: _selectedCategory == 'Price Lists',
                    onTap: () => setState(() => _selectedCategory = 'Price Lists'),
                  ),
                  _buildCircularCategory(
                    icon: Icons.layers_rounded,
                    label: 'Floor Plans',
                    bgColor: const Color(0xFFFFEDD5),
                    iconColor: const Color(0xFFEA580C),
                    isSelected: _selectedCategory == 'Floor Plans',
                    onTap: () => setState(() => _selectedCategory = 'Floor Plans'),
                  ),
                  _buildCircularCategory(
                    icon: Icons.videocam_rounded,
                    label: 'Videos',
                    bgColor: const Color(0xFFF3E8FF),
                    iconColor: const Color(0xFF7C3AED),
                    isSelected: _selectedCategory == 'Videos',
                    onTap: () => setState(() => _selectedCategory = 'Videos'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 3. Asset List (5 Items matching screenshot)
            Expanded(
              child: collaterals.isEmpty
                  ? Center(
                      child: Text(
                        'No collateral found in this category',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: collaterals.length,
                      itemBuilder: (context, index) {
                        final item = collaterals[index];
                        return _buildCollateralItem(context, item, index, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularCategory({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollateralItem(
    BuildContext context,
    CollateralModel item,
    int index,
    bool isDark,
  ) {
    // Exact thumbnails and badge types matching screenshot
    final thumbnails = [
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=200&q=80', // My Home Avatar
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=200&q=80', // Prestige Sunshine
      'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=200&q=80', // Floor Plans
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=200&q=80', // Video
      'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=200&q=80', // Location Map
    ];
    final thumbUrl = thumbnails[index % thumbnails.length];

    // Badge styling on thumbnail
    Widget badgeIcon;
    if (index == 0 || index == 4) {
      // PDF badge (Red)
      badgeIcon = Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'PDF',
          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      );
    } else if (index == 1) {
      // Excel badge (Green)
      badgeIcon = Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'X',
          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      );
    } else if (index == 2) {
      // Floor plan badge (Purple)
      badgeIcon = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.layers_rounded, color: Colors.white, size: 9),
      );
    } else {
      // Video badge (Red)
      badgeIcon = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 9),
      );
    }

    final dates = [
      'Updated 5 days ago',
      'Updated 3 days ago',
      'Updated 1 week ago',
      'Updated 2 days ago',
      'Updated 1 week ago',
    ];
    final dateDisplay = dates[index % dates.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail with corner file badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  thumbUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 50,
                    color: const Color(0xFFE2E8F0),
                    alignment: Alignment.center,
                    child: const Icon(Icons.description, color: Color(0xFF64748B)),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: badgeIcon,
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Title, Project & Size, Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.projectName} • ${item.fileSize}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  dateDisplay,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Download Action Icon
          IconButton(
            icon: Icon(
              Icons.download_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading ${item.title}...')),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          // 3-dots Menu
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
            ),
            onSelected: (val) {
              if (val == 'share') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sharing ${item.title}...')),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'view', child: Text('Preview')),
              const PopupMenuItem(value: 'share', child: Text('Share Link')),
            ],
          ),
        ],
      ),
    );
  }
}
