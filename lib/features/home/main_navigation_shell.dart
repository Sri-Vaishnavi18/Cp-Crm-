import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../shared/widgets/app_widgets.dart';
import '../dashboard/dashboard_screen.dart';
import '../leads/leads_screen.dart';
import '../projects/projects_screen.dart';
import '../commissions/commissions_screen.dart';
import '../spoc_helpdesk/spoc_screen.dart';
import '../notifications/notifications_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final AppState state;

  const MainNavigationShell({super.key, required this.state});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

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

  void _openProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UserProfileModalSheet(state: widget.state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDarkMode;
    final rera = widget.state.currentUser?.reraNumber ?? 'N/A';
    final safeRera = rera.length > 18 ? '${rera.substring(0, 18)}...' : rera;

    final screens = [
      DashboardScreen(
        state: widget.state,
        onNavigateTab: (idx) => setState(() => _currentIndex = idx),
        onOpenAddLead: _openAddLeadModal,
        onOpenScheduleVisit: _openScheduleVisitModal,
        onOpenProfile: _openProfileModal,
      ),
      LeadsScreen(
        state: widget.state,
        onOpenAddLead: _openAddLeadModal,
      ),
      ProjectsScreen(
        state: widget.state,
      ),
      CommissionsScreen(
        state: widget.state,
      ),
    ];

    final titles = [
      widget.state.currentUser?.firmName ?? 'CP CRM',
      'Leads & Deals Pipeline',
      'Active Projects & Inventory',
      'Project Commissions & Ledger',
    ];

    final subtitles = [
      'RERA: $safeRera',
      'Zero-OTP Algorithmic Protection',
      'Live Tower & Unit Status Matrix',
      'Project-wise Invoices & Settlements',
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: AppHeader(
          title: titles[_currentIndex],
          subtitle: subtitles[_currentIndex],
          onThemeToggle: widget.state.toggleTheme,
          isDark: isDark,
          unreadCount: widget.state.unreadNotificationCount,
          onNotificationTap: _openNotifications,
          isOffline: widget.state.isOffline,
          onOfflineToggle: () {
            widget.state.toggleOfflineMode();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.state.isOffline
                      ? 'Offline Mode Active: New leads will queue locally until reconnected.'
                      : 'Back Online: Offline lead queue synced successfully!',
                ),
              ),
            );
          },
          onProfileTap: _openProfileModal,
          profileInitials: (widget.state.currentUser?.name.isNotEmpty == true)
              ? widget.state.currentUser!.name.substring(0, 1).toUpperCase()
              : 'CP',
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          elevation: 0,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('${widget.state.allLeads.length}'),
                child: const Icon(Icons.people_outline),
              ),
              selectedIcon: Badge(
                label: Text('${widget.state.allLeads.length}'),
                child: const Icon(Icons.people, color: AppColors.primary),
              ),
              label: 'Leads',
            ),
            const NavigationDestination(
              icon: Icon(Icons.apartment_outlined),
              selectedIcon: Icon(Icons.apartment, color: AppColors.primary),
              label: 'Projects',
            ),
            const NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.primary),
              label: 'Commissions',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _openSpocHelpdesk,
              backgroundColor: AppColors.secondary,
              tooltip: 'Builder SPOC Directory',
              child: const Icon(Icons.support_agent, color: Colors.white),
            )
          : null,
    );
  }
}
