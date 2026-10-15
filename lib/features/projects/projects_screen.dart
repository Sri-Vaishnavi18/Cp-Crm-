import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/services/url_action_service.dart';
import 'project_detail_screen.dart';
import 'create_project_modal.dart';

class ProjectsScreen extends StatefulWidget {
  final AppState state;
  final Function(ProjectModel)? onSelectProject;
  final VoidCallback? onBack;

  const ProjectsScreen({
    super.key,
    required this.state,
    this.onSelectProject,
    this.onBack,
  });

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _selectedBrand = 'All'; // All, My Home, Prestige, Rajapushpa, Aparna
  final Set<String> _favoriteIds = {};
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProjectModel> _getFilteredProjects() {
    final all = widget.state.projects;
    final query = _searchController.text.trim().toLowerCase();

    return all.where((proj) {
      if (_selectedBrand != 'All') {
        if (!proj.name.toLowerCase().contains(_selectedBrand.toLowerCase())) {
          return false;
        }
      }

      if (query.isNotEmpty) {
        final matchName = proj.name.toLowerCase().contains(query);
        final matchLoc = proj.location.toLowerCase().contains(query);
        if (!matchName && !matchLoc) return false;
      }

      return true;
    }).toList();
  }

  void _openProjectDetail(ProjectModel project) {
    if (widget.onSelectProject != null) {
      widget.onSelectProject!(project);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ProjectDetailScreen(
            project: project,
            state: widget.state,
          ),
        ),
      );
    }
  }

  void _openCreateProjectModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateProjectModalSheet(state: widget.state),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final isDark = widget.state.isDarkMode;
        final projects = _getFilteredProjects();

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F7FB),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreateProjectModal,
            backgroundColor: const Color(0xFF2563EB),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            label: const Text(
              'Add Project',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Header (Back arrow + Projects + Add Project + Search + Filter tune icon)
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
                        'Projects',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),

                      // Quick "+ Add Project" Header Pill Button
                      InkWell(
                        onTap: _openCreateProjectModal,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Add Project',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

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
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF475569),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Filter options active')),
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
                        hintText: 'Search by project name or location...',
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

                // 2. Horizontal Filter Chips (All, My Home, Prestige, Rajapushpa, Aparna)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildBrandChip('All', isDark),
                      const SizedBox(width: 8),
                      _buildBrandChip('My Home', isDark),
                      const SizedBox(width: 8),
                      _buildBrandChip('Prestige', isDark),
                      const SizedBox(width: 8),
                      _buildBrandChip('Rajapushpa', isDark),
                      const SizedBox(width: 8),
                      _buildBrandChip('Aparna', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // 3. Projects List
                Expanded(
                  child: projects.isEmpty
                      ? Center(
                          child: Text(
                            'No projects found matching selection',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: projects.length,
                          itemBuilder: (context, index) {
                            final project = projects[index];
                            return _buildProjectCard(context, project, index, isDark);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandChip(String brand, bool isDark) {
    final isSelected = _selectedBrand == brand;

    return InkWell(
      onTap: () => setState(() => _selectedBrand = brand),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          brand,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project, int index, bool isDark) {
    // Specific badges matching reference image
    String badgeText;
    Color badgeBgColor;
    Color badgeTextColor;

    if (project.name.contains('My Home')) {
      badgeText = 'NEW LAUNCH';
      badgeBgColor = const Color(0xFFFFEDD5);
      badgeTextColor = const Color(0xFFEA580C);
    } else if (project.name.contains('Prestige')) {
      badgeText = 'POPULAR';
      badgeBgColor = const Color(0xFFFFEDD5);
      badgeTextColor = const Color(0xFFEA580C);
    } else if (project.name.contains('Rajapushpa')) {
      badgeText = 'RERA APPROVED';
      badgeBgColor = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF16A34A);
    } else {
      badgeText = 'PREMIUM';
      badgeBgColor = const Color(0xFFFFEDD5);
      badgeTextColor = const Color(0xFFEA580C);
    }

    final isFav = _favoriteIds.contains(project.id);

    // High quality covers
    final covers = [
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&q=80',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
    ];
    final imageUrl = project.heroImageUrl.isNotEmpty
        ? project.heroImageUrl
        : covers[index % covers.length];

    // Configurations
    final bhkDisplay = project.name.contains('Prestige') || project.name.contains('Aparna')
        ? '2, 3 BHK'
        : '2, 3, 4 BHK';

    // Price
    final priceDisplay = project.startingPrice.isNotEmpty ? project.startingPrice : '₹62L - 2.1Cr';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
          width: 1,
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
          // 1. Cover Image with Overlay Badges & Heart Icon
          Stack(
            children: [
              GestureDetector(
                onTap: () => _openProjectDetail(project),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    imageUrl,
                    height: 155,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 155,
                      color: const Color(0xFF1E293B),
                      alignment: Alignment.center,
                      child: const Icon(Icons.apartment_rounded, color: Colors.white54, size: 40),
                    ),
                  ),
                ),
              ),

              // Gradient scrim over image
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Top Right Badge & Favorite Icon
              Positioned(
                top: 10,
                right: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: badgeTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isFav) {
                            _favoriteIds.remove(project.id);
                          } else {
                            _favoriteIds.add(project.id);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFFEF4444) : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 2. Body Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  project.location,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),

                // BHK and Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bhkDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                      ),
                    ),
                    Text(
                      priceDisplay,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Units & Inventory Visibility Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: 15,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${project.units.length} Units',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${project.units.where((u) => u.status == UnitStatus.available).length} Available',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      if (project.towers.isNotEmpty) ...[
                        const Spacer(),
                        Text(
                          '${project.towers.length} ${project.towers.length == 1 ? "Tower" : "Towers"}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Action Buttons Row: Details (Units & Prices), Brochure, Share
                Row(
                  children: [
                    // Details Button (Brand Blue) - View Units & Unit Prices
                    Expanded(
                      child: _buildProjectActionButton(
                        icon: Icons.visibility_outlined,
                        iconColor: const Color(0xFF2563EB),
                        label: 'Details',
                        onTap: () => _openProjectDetail(project),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Brochure Button (Purple)
                    Expanded(
                      child: _buildProjectActionButton(
                        icon: Icons.article_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        label: 'Brochure',
                        onTap: () => _openProjectDetail(project),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Share Button (Green)
                    Expanded(
                      child: _buildProjectActionButton(
                        icon: Icons.share_outlined,
                        iconColor: const Color(0xFF16A34A),
                        label: 'Share',
                        onTap: () {
                          UrlActionService.shareContent(
                            context,
                            text: 'Check out ${project.name} in ${project.location}! Starting price: $priceDisplay.',
                          );
                        },
                        isDark: isDark,
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

  Widget _buildProjectActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
