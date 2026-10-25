import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/services/url_action_service.dart';
import 'lead_detail_screen.dart';
import 'bulk_import_leads_modal.dart';
import '../../shared/widgets/app_widgets.dart';
export 'add_lead_modal.dart';
export 'bulk_import_leads_modal.dart';

class LeadsScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onOpenAddLead;
  final VoidCallback? onOpenBulkImport;
  final VoidCallback? onBack;
  final String? initialFilter;

  const LeadsScreen({
    super.key,
    required this.state,
    required this.onOpenAddLead,
    this.onOpenBulkImport,
    this.onBack,
    this.initialFilter,
  });

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedFilter = 'All'; // All, New, Contacted, Site Visit, Booked, Hot
  String _sortFilter = 'Sort ▾';
  String _projectFilter = 'Project ▾';
  String _budgetFilter = 'Budget ▾';
  String _sourceFilter = 'Source ▾';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null && widget.initialFilter!.isNotEmpty) {
      _selectedFilter = widget.initialFilter!;
    }
    _searchController.text = widget.state.leadSearchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openBulkImportModal() {
    if (widget.onOpenBulkImport != null) {
      widget.onOpenBulkImport!();
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => BulkImportLeadsModalSheet(state: widget.state),
      );
    }
  }

  void _navigateToDetail(LeadModel lead) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => LeadDetailScreen(state: widget.state, leadId: lead.id),
      ),
    );
  }

  static double _parseBudgetToRupees(String budget) {
    final clean = budget.replaceAll('₹', '').replaceAll(',', '').trim().toLowerCase();
    if (clean.isEmpty) return 0.0;

    // Check if it's a range like "80 lakhs - 1.2 cr" or "50l - 80l" or "1 cr - 1.5 cr"
    if (clean.contains('-')) {
      final parts = clean.split('-');
      if (parts.length == 2) {
        final low = _parseBudgetToRupees(parts[0]);
        final high = _parseBudgetToRupees(parts[1]);
        if (high > 0 && low > 0) return (low + high) / 2;
        if (high > 0) return high;
        if (low > 0) return low;
      }
    }

    // Check for Cr / Crore
    if (clean.contains('cr')) {
      final match = RegExp(r'([\d\.]+)').firstMatch(clean);
      if (match != null) {
        final val = double.tryParse(match.group(1)!) ?? 1.0;
        return val * 10000000;
      }
    }

    // Check for L / Lakh
    if (clean.contains('l')) {
      final match = RegExp(r'([\d\.]+)').firstMatch(clean);
      if (match != null) {
        final val = double.tryParse(match.group(1)!) ?? 50.0;
        return val * 100000;
      }
    }

    final match = RegExp(r'([\d\.]+)').firstMatch(clean);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0;
  }

  bool get _hasActiveFilters =>
      _selectedFilter != 'All' ||
      _sortFilter != 'Sort ▾' ||
      _projectFilter != 'Project ▾' ||
      _budgetFilter != 'Budget ▾' ||
      _sourceFilter != 'Source ▾' ||
      _searchController.text.trim().isNotEmpty ||
      widget.state.isDateFilterActive;

  void _resetAllFilters() {
    setState(() {
      _selectedFilter = 'All';
      _sortFilter = 'Sort ▾';
      _projectFilter = 'Project ▾';
      _budgetFilter = 'Budget ▾';
      _sourceFilter = 'Source ▾';
      _searchController.clear();
      _isSearching = false;
    });
    widget.state.resetDashboardDateFilter();
  }

  static String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins min${mins > 1 ? "s" : ""} ago';
    } else if (difference.inHours < 24 && dateTime.day == now.day) {
      final hours = difference.inHours;
      return hours == 0 ? 'Just now' : '$hours hr${hours > 1 ? "s" : ""} ago';
    } else {
      final yesterday = now.subtract(const Duration(days: 1));
      if (dateTime.year == yesterday.year &&
          dateTime.month == yesterday.month &&
          dateTime.day == yesterday.day) {
        return 'Yesterday';
      }
      final days = difference.inDays;
      if (days < 7) {
        return days <= 1 ? '1 day ago' : '$days days ago';
      } else if (days < 30) {
        final weeks = (days / 7).floor();
        return '$weeks week${weeks > 1 ? "s" : ""} ago';
      } else {
        final months = (days / 30).floor();
        return '$months month${months > 1 ? "s" : ""} ago';
      }
    }
  }

  List<LeadModel> _getFilteredLeads() {
    final all = widget.state.allLeads;
    final query = _searchController.text.trim().toLowerCase();

    final filtered = all.where((lead) {
      // Date filter
      if (!widget.state.isDateInActiveRange(lead.createdAt)) return false;

      // Tab filter
      if (_selectedFilter == 'Cold') {
        if (lead.stage != LeadStage.cold) return false;
      } else if (_selectedFilter == 'Site Visited' || _selectedFilter == 'Site Visit') {
        if (lead.stage != LeadStage.siteVisited) return false;
      } else if (_selectedFilter == 'Booked') {
        if (lead.stage != LeadStage.booked) return false;
      }

      // Project filter
      if (_projectFilter != 'Project ▾' && _projectFilter != 'All Projects') {
        final cleanProj = _projectFilter.replaceAll(' ▾', '').trim().toLowerCase();
        final leadProj = lead.projectName.trim().toLowerCase();
        final matches = leadProj.contains(cleanProj) || cleanProj.contains(leadProj);
        if (!matches) return false;
      }

      // Budget filter
      if (_budgetFilter != 'Budget ▾' && _budgetFilter != 'All Budgets') {
        final val = _parseBudgetToRupees(lead.budget);
        if (_budgetFilter == '< ₹75L') {
          if (val >= 7500000) return false;
        } else if (_budgetFilter == '₹75L - ₹1Cr') {
          if (val < 7500000 || val > 10000000) return false;
        } else if (_budgetFilter == '> ₹1Cr') {
          if (val <= 10000000) return false;
        }
      }

      // Source filter
      if (_sourceFilter != 'Source ▾' && _sourceFilter != 'All Sources') {
        final cleanSource = _sourceFilter.replaceAll(' ▾', '').trim().toLowerCase();
        if (lead.source.trim().toLowerCase() != cleanSource) return false;
      }

      // Search query
      if (query.isNotEmpty) {
        final matchName = lead.fullName.toLowerCase().contains(query);
        final matchPhone = lead.phone.contains(query);
        final matchProj = lead.projectName.toLowerCase().contains(query);
        if (!matchName && !matchPhone && !matchProj) return false;
      }

      return true;
    }).toList();

    // Sorting
    if (_sortFilter == 'Budget High-Low') {
      filtered.sort((a, b) => _parseBudgetToRupees(b.budget).compareTo(_parseBudgetToRupees(a.budget)));
    } else if (_sortFilter == 'Budget Low-High') {
      filtered.sort((a, b) => _parseBudgetToRupees(a.budget).compareTo(_parseBudgetToRupees(b.budget)));
    } else if (_sortFilter == 'Newest First') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortFilter == 'Oldest First') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final isDark = widget.state.isDarkMode;
        final leads = _getFilteredLeads();

        // Date-filtered leads for tab counts
        final dateFilteredLeads = widget.state.allLeads
            .where((l) => widget.state.isDateInActiveRange(l.createdAt))
            .toList();

        // Tab counts
        final allCount = dateFilteredLeads.length;
        final coldCount = dateFilteredLeads.where((l) => l.stage == LeadStage.cold).length;
        final siteVisitedCount = dateFilteredLeads.where((l) => l.stage == LeadStage.siteVisited).length;
        final bookedCount = dateFilteredLeads.where((l) => l.stage == LeadStage.booked).length;

        return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header (Back arrow + Leads + Search icon + "+ Add Lead" blue pill button)
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
                    'Leads',
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
                        if (!_isSearching) {
                          _searchController.clear();
                        }
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const Key('leads_bulk_import_button'),
                    onPressed: _openBulkImportModal,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 15, color: Color(0xFF2563EB)),
                    label: const Text(
                      'Bulk Import',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                        letterSpacing: -0.2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB).withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      backgroundColor: isDark
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                          : const Color(0xFFEFF6FF),
                      foregroundColor: const Color(0xFF1D4ED8),
                      elevation: 0,
                      shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: widget.onOpenAddLead,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      'Add Lead',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar Input (if search toggled)
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by client name, project, phone...',
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

            // Date Filter Bar (Today, Yesterday, 7 Days, 30 Days, Manual Calendar, Reset)
            DateFilterBar(
              state: widget.state,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),

            // 2. Top Filter Tabs: All, Cold, Site Visited, Booked
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildTabPill('All ($allCount)', 'All', isDark),
                  const SizedBox(width: 8),
                  _buildTabPill('Cold ($coldCount)', 'Cold', isDark),
                  const SizedBox(width: 8),
                  _buildTabPill('Site Visited ($siteVisitedCount)', 'Site Visited', isDark),
                  const SizedBox(width: 8),
                  _buildTabPill('Booked ($bookedCount)', 'Booked', isDark),
                ],
              ),
            ),

            // 3. Dropdown Filter Chips: Sort ▾, Project ▾, Budget ▾, Source ▾
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildDropdownChip(
                    label: _sortFilter,
                    options: ['Sort ▾', 'Newest First', 'Oldest First', 'Budget High-Low', 'Budget Low-High'],
                    onSelected: (val) => setState(() => _sortFilter = val),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownChip(
                    label: _projectFilter,
                    options: ['All Projects', ...widget.state.projects.map((p) => p.name)],
                    onSelected: (val) => setState(() => _projectFilter = val == 'All Projects' ? 'Project ▾' : val),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownChip(
                    label: _budgetFilter,
                    options: ['All Budgets', '< ₹75L', '₹75L - ₹1Cr', '> ₹1Cr'],
                    onSelected: (val) => setState(() => _budgetFilter = val == 'All Budgets' ? 'Budget ▾' : val),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownChip(
                    label: _sourceFilter,
                    options: ['All Sources', 'Website', 'Meta Ads', 'Referral', 'Walk-in', 'Digital Ads', 'Channel Partner', 'Cold Calling'],
                    onSelected: (val) => setState(() => _sourceFilter = val == 'All Sources' ? 'Source ▾' : val),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  // Reset Filter Chip
                  InkWell(
                    key: const Key('leads_reset_filters_button'),
                    onTap: _resetAllFilters,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _hasActiveFilters
                            ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                            : (isDark ? AppColors.darkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _hasActiveFilters
                              ? const Color(0xFFEF4444)
                              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restart_alt_rounded,
                            size: 14,
                            color: _hasActiveFilters
                                ? const Color(0xFFEF4444)
                                : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _hasActiveFilters
                                  ? const Color(0xFFEF4444)
                                  : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 4. Leads List
            Expanded(
              child: leads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No leads found matching filters',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                            ),
                          ),
                          if (_hasActiveFilters) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _resetAllFilters,
                              icon: const Icon(Icons.restart_alt_rounded, size: 16),
                              label: const Text('Reset All Filters'),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _openBulkImportModal,
                                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                                  label: const Text('Bulk Import Leads'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2563EB),
                                    side: const BorderSide(color: Color(0xFF2563EB)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: widget.onOpenAddLead,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Lead'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: leads.length,
                      itemBuilder: (context, index) {
                        final lead = leads[index];
                        return _buildLeadCard(context, lead, index, isDark);
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

  // Segmented Pill Tab
  Widget _buildTabPill(String title, String filterKey, bool isDark) {
    final isSelected = _selectedFilter == filterKey;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
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
          title,
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

  // Dropdown Filter Chip
  Widget _buildDropdownChip({
    required String label,
    required List<String> options,
    required Function(String) onSelected,
    required bool isDark,
  }) {
    final isActive = label != 'Sort ▾' &&
        label != 'Project ▾' &&
        label != 'Budget ▾' &&
        label != 'Source ▾';

    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => options.map((opt) {
        return PopupMenuItem<String>(
          value: opt,
          child: Text(opt, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2563EB).withValues(alpha: 0.12)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? const Color(0xFF2563EB)
                : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF2563EB)
                    : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check,
                size: 13,
                color: Color(0xFF2563EB),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Lead Card matching reference screenshot
  Widget _buildLeadCard(BuildContext context, LeadModel lead, int index, bool isDark) {
    // Dynamic status badge styling
    Color badgeBgColor;
    Color badgeTextColor;
    String badgeText;

    if (lead.stage == LeadStage.booked) {
      badgeText = 'BOOKED';
      badgeBgColor = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF16A34A);
    } else if (lead.stage == LeadStage.siteVisited) {
      badgeText = 'SITE VISITED';
      badgeBgColor = const Color(0xFFE0F2FE);
      badgeTextColor = const Color(0xFF0284C7);
    } else {
      badgeText = 'COLD';
      badgeBgColor = const Color(0xFFF1F5F9);
      badgeTextColor = const Color(0xFF64748B);
    }

    // Source icon & label
    IconData sourceIcon = Icons.language_rounded;
    String sourceLabel = lead.source.isNotEmpty ? lead.source : 'Website';
    if (sourceLabel.toLowerCase().contains('meta') || sourceLabel.toLowerCase().contains('ad')) {
      sourceIcon = Icons.campaign_rounded;
      sourceLabel = 'Meta Ads';
    } else if (sourceLabel.toLowerCase().contains('referral')) {
      sourceIcon = Icons.people_outline_rounded;
      sourceLabel = 'Referral';
    } else if (sourceLabel.toLowerCase().contains('walk')) {
      sourceIcon = Icons.directions_walk_rounded;
      sourceLabel = 'Walk-in';
    }

    // Relative timestamp display dynamically calculated from lead.createdAt
    final timeDisplay = _formatRelativeTime(lead.createdAt);

    final bhk = lead.configurations.isNotEmpty ? lead.configurations.first : '3 BHK';
    final budget = lead.budget.isNotEmpty ? lead.budget : '₹85L';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Name & Info + Status Pill + 3-dots
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + Subtitle (BHK • Budget) + Project
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.fullName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$bhk • $budget',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      lead.projectName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Metadata Row: Source & Timestamp
          Row(
            children: [
              Icon(sourceIcon, size: 14, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                sourceLabel,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                timeDisplay,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons: Call, WhatsApp, Schedule
          Row(
            children: [
              // Call Button
              Expanded(
                child: _buildLeadActionButton(
                  icon: Icons.phone_rounded,
                  iconColor: const Color(0xFF16A34A),
                  label: 'Call',
                  textColor: const Color(0xFF16A34A),
                  onTap: () => UrlActionService.makePhoneCall(context, lead.phone),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // WhatsApp Button
              Expanded(
                child: _buildLeadActionButton(
                  icon: Icons.chat_rounded,
                  iconColor: const Color(0xFF16A34A),
                  label: 'WhatsApp',
                  textColor: const Color(0xFF16A34A),
                  onTap: () => UrlActionService.openWhatsApp(
                    context,
                    phoneNumber: lead.phone,
                    message: 'Hello ${lead.fullName}, touching base regarding your inquiry for ${lead.projectName}.',
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),

              // View Details Button (Replaces Schedule button)
              Expanded(
                child: _buildLeadActionButton(
                  icon: Icons.visibility_outlined,
                  iconColor: const Color(0xFF2563EB),
                  label: 'View Details',
                  textColor: const Color(0xFF2563EB),
                  onTap: () => _navigateToDetail(lead),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color textColor,
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
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
