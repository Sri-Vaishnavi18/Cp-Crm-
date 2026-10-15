import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../shared/widgets/app_widgets.dart';
import '../dashboard/dashboard_screen.dart';
import '../leads/leads_screen.dart';
import '../projects/projects_screen.dart';
import '../site_visits/site_visits_screen.dart';
import '../docs/docs_screen.dart';
import '../commissions/commissions_screen.dart';
import '../spoc_helpdesk/spoc_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final AppState state;

  const MainNavigationShell({super.key, required this.state});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  String? _leadInitialFilter;
  int _docsInitialTab = 0;

  void _openInvoices() {
    setState(() {
      _docsInitialTab = 1;
      _currentIndex = 3;
    });
  }

  void _openAddLeadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddLeadModalSheet(state: widget.state),
    );
  }

  void _openScheduleVisitModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ScheduleVisitModalSheet(state: widget.state),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => NotificationCenterScreen(state: widget.state)),
    );
  }

  void _openSpocHelpdesk() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => SpocHelpdeskScreen(state: widget.state)),
    );
  }

  void _openProfileScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => ProfileScreen(state: widget.state)),
    );
  }

  void _openSiteVisitsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => SiteVisitsScreen(
          state: widget.state,
          onOpenSchedule: _openScheduleVisitModal,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final isDark = widget.state.isDarkMode;

        final screens = [
          DashboardScreen(
            state: widget.state,
            onNavigateTab: (idx) => setState(() {
              _leadInitialFilter = null;
              if (idx == 3) {
                _docsInitialTab = 0;
              }
              _currentIndex = idx;
            }),
            onOpenAddLead: _openAddLeadModal,
            onOpenScheduleVisit: _openScheduleVisitModal,
            onOpenProfile: _openProfileScreen,
            onOpenSiteVisits: _openSiteVisitsScreen,
            onOpenSpocHelpdesk: _openSpocHelpdesk,
            onOpenNotifications: _openNotifications,
            onOpenCommissions: () => setState(() => _currentIndex = 4),
            onOpenDocs: () => setState(() {
              _docsInitialTab = 0;
              _currentIndex = 3;
            }),
            onOpenInvoices: _openInvoices,
            onOpenLeadsWithFilter: (filter) => setState(() {
              _leadInitialFilter = filter;
              _currentIndex = 1;
            }),
          ),
          LeadsScreen(
            key: ValueKey(_leadInitialFilter ?? 'all_leads'),
            state: widget.state,
            initialFilter: _leadInitialFilter,
            onOpenAddLead: _openAddLeadModal,
            onBack: () => setState(() => _currentIndex = 0),
          ),
          ProjectsScreen(
            state: widget.state,
            onBack: () => setState(() => _currentIndex = 0),
          ),
          DocsScreen(
            key: ValueKey('docs_tab_$_docsInitialTab'),
            state: widget.state,
            initialTabIndex: _docsInitialTab,
            onBack: () => setState(() => _currentIndex = 0),
          ),
          CommissionsScreen(
            state: widget.state,
            onBack: () => setState(() => _currentIndex = 0),
          ),
        ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          if (_currentIndex == 0)
            Positioned(
              right: 20,
              bottom: 80,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openSpocHelpdesk,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.headset_mic_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E9F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(
                    index: 0,
                    label: 'Dashboard',
                    activeIcon: Icons.home_rounded,
                    inactiveIcon: Icons.grid_view_outlined,
                    isDark: isDark,
                  ),
                  _buildBottomNavItem(
                    index: 1,
                    label: 'Leads',
                    activeIcon: Icons.people_alt_rounded,
                    inactiveIcon: Icons.people_alt_outlined,
                    badgeCount: widget.state.allLeads.isNotEmpty ? widget.state.allLeads.length : null,
                    isDark: isDark,
                  ),
                  _buildBottomNavItem(
                    index: 2,
                    label: 'Projects',
                    activeIcon: Icons.apartment_rounded,
                    inactiveIcon: Icons.apartment_outlined,
                    isDark: isDark,
                  ),
                  _buildBottomNavItem(
                    index: 3,
                    label: 'Docs',
                    activeIcon: Icons.folder_shared_rounded,
                    inactiveIcon: Icons.folder_shared_outlined,
                    badgeCount: widget.state.missingMandatoryDocsCount > 0 ? widget.state.missingMandatoryDocsCount : null,
                    isDark: isDark,
                  ),
                  _buildBottomNavItem(
                    index: 4,
                    label: 'Commissions',
                    activeIcon: Icons.account_balance_wallet_rounded,
                    inactiveIcon: Icons.account_balance_wallet_outlined,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              PoweredByBranding(
                isDark: isDark,
                padding: const EdgeInsets.only(bottom: 2),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required bool isDark,
    int? badgeCount,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? const Color(0xFF2563EB)
        : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B));

    Widget iconWidget = Icon(
      isSelected ? activeIcon : inactiveIcon,
      color: color,
      size: 24,
    );

    if (badgeCount != null && badgeCount > 0) {
      iconWidget = Badge(
        label: Text(
          '$badgeCount',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEF4444),
        child: iconWidget,
      );
    }

    return InkWell(
      onTap: () => setState(() {
        if (index == 3) {
          _docsInitialTab = 0;
        }
        _currentIndex = index;
      }),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
