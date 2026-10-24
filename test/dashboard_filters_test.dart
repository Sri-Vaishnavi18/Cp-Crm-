import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp_crm/core/state/app_state.dart';
import 'package:cp_crm/features/dashboard/dashboard_screen.dart';
import 'package:cp_crm/features/leads/add_lead_modal.dart';
import 'package:cp_crm/features/leads/leads_screen.dart';
import 'package:cp_crm/features/projects/projects_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dashboard Date Filters & KPI Tests', () {
    test('Initial state is allTime preset and date filter is not active', () async {
      final state = AppState();
      // Allow async _initData to execute
      await Future.delayed(const Duration(milliseconds: 100));

      expect(state.dashboardDatePreset, DashboardDatePreset.allTime);
      expect(state.isDateFilterActive, false);
      expect(state.dateFilterLabel, 'All Time');
      expect(state.dashboardLeads.length, state.allLeads.length);
      expect(state.dashboardSiteVisits.length, state.siteVisits.length);
    });

    test('Setting Today filter updates dashboardLeads and KPIs', () async {
      final state = AppState();
      await Future.delayed(const Duration(milliseconds: 100));

      state.setDashboardDatePreset(DashboardDatePreset.today);

      expect(state.dashboardDatePreset, DashboardDatePreset.today);
      expect(state.isDateFilterActive, true);
      expect(state.dateFilterLabel, 'Today');
      // Initially, no lead was created today, so today leads count is 0
      expect(state.dashboardLeads.length, 0);

      // Now create a lead today
      state.addLead(
        firstName: 'Today',
        lastName: 'Client',
        phone: '9911223344',
        budget: '₹85L',
        configurations: ['2 BHK'],
        projectId: 'proj_avatar',
        projectName: 'My Home Avatar',
        timeline: '1 Month',
        notes: 'Test lead notes',
      );

      // Now Today leads count is accurately 1
      expect(state.dashboardLeads.length, 1);
      // Ananya Iyer (vis_1) scheduled Today
      expect(state.dashboardSiteVisits.isNotEmpty, true);
    });

    test('Setting Yesterday filter isolates yesterday leads and visits', () async {
      final state = AppState();
      await Future.delayed(const Duration(milliseconds: 100));

      state.setDashboardDatePreset(DashboardDatePreset.yesterday);

      expect(state.dashboardDatePreset, DashboardDatePreset.yesterday);
      expect(state.isDateFilterActive, true);
      expect(state.dateFilterLabel, 'Yesterday');
      // Ananya Iyer (lead_2) was created Yesterday
      expect(state.dashboardLeads.any((l) => l.id == 'lead_2'), true);
      // Deepak Verma (vis_2) was scheduled Yesterday
      expect(state.dashboardSiteVisits.any((v) => v.id == 'vis_2'), true);
    });

    test('Setting 7 Days and 30 Days filters includes corresponding range', () async {
      final state = AppState();
      await Future.delayed(const Duration(milliseconds: 100));

      state.setDashboardDatePreset(DashboardDatePreset.last7Days);
      expect(state.dashboardDatePreset, DashboardDatePreset.last7Days);
      expect(state.isDateFilterActive, true);
      expect(state.dateFilterLabel, 'Last 7 Days');
      final count7D = state.dashboardLeads.length;

      state.setDashboardDatePreset(DashboardDatePreset.last30Days);
      expect(state.dashboardDatePreset, DashboardDatePreset.last30Days);
      expect(state.dateFilterLabel, 'Last 30 Days');
      final count30D = state.dashboardLeads.length;

      expect(count30D, greaterThanOrEqualTo(count7D));
    });

    test('Custom Date Range filter functions accurately', () async {
      final state = AppState();
      await Future.delayed(const Duration(milliseconds: 100));

      final now = DateTime.now();
      final customRange = DateTimeRange(
        start: now.subtract(const Duration(days: 2)),
        end: now,
      );

      state.setCustomDateRange(customRange);

      expect(state.dashboardDatePreset, DashboardDatePreset.custom);
      expect(state.isDateFilterActive, true);
      expect(state.customDateRange, customRange);
      expect(state.dateFilterLabel.contains('-'), true);
    });

    test('Resetting date filter restores all data to allTime', () async {
      final state = AppState();
      await Future.delayed(const Duration(milliseconds: 100));

      state.setDashboardDatePreset(DashboardDatePreset.today);
      expect(state.isDateFilterActive, true);

      state.resetDashboardDateFilter();

      expect(state.dashboardDatePreset, DashboardDatePreset.allTime);
      expect(state.isDateFilterActive, false);
      expect(state.customDateRange, isNull);
      expect(state.dateFilterLabel, 'All Time');
      expect(state.dashboardLeads.length, state.allLeads.length);
    });
  });

  group('Dashboard UI Component Tests', () {
    testWidgets('Dashboard renders Pipeline Health and Leads section with real lead names', (WidgetTester tester) async {
      final state = AppState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              state: state,
              onNavigateTab: (_) {},
              onOpenAddLead: () {},
              onOpenScheduleVisit: () {},
            ),
          ),
        ),
      );

      // Verify 7 Analytics Metrics: Lead Pipeline Analytics (3 cards)
      expect(find.text('Total Leads'), findsOneWidget);
      expect(find.text('Sitevisited Leads'), findsOneWidget);
      expect(find.text('Booked Leads'), findsOneWidget);

      // Verify Sync badge in top bar
      expect(find.text('SYNCED'), findsOneWidget);

      // Verify Today's Activity and Quick Actions sections are removed
      expect(find.text("Today's Activity"), findsNothing);
      expect(find.text('Quick Actions'), findsNothing);

      // Verify 7 Analytics Metrics: 2x2 Commission & Financial Analytics Cards (4 cards)
      expect(find.text('Commission Recieved', skipOffstage: false), findsOneWidget);
      expect(find.text('₹6,000', skipOffstage: false), findsWidgets);
      expect(find.text('Commission Pending', skipOffstage: false), findsOneWidget);
      expect(find.text('₹1,88,000', skipOffstage: false), findsWidgets);
      expect(find.text('Invoices', skipOffstage: false), findsOneWidget);
      expect(find.text('4 Invoices', skipOffstage: false), findsOneWidget);
      expect(find.text('Total Commission Earned', skipOffstage: false), findsOneWidget);
      expect(find.text('₹1,94,000', skipOffstage: false), findsWidgets);

      // Verify Settlement Destination Bank Card & Edit Action
      expect(find.text('Settlement Destination Bank', skipOffstage: false), findsOneWidget);
      expect(find.textContaining('HDFC Bank Ltd', skipOffstage: false), findsOneWidget);
      expect(find.text('Edit', skipOffstage: false), findsOneWidget);

      // Verify Pipeline Conversion Funnel & Brokerage Performance Graph
      expect(find.text('Pipeline Conversion Funnel', skipOffstage: false), findsOneWidget);
      expect(find.text('Brokerage Trajectory', skipOffstage: false), findsOneWidget);
      expect(find.text('6-Month Settled vs Pending', skipOffstage: false), findsOneWidget);
    });

    testWidgets('Dashboard displays 0 progress and 0 brokerage on clean slate', (WidgetTester tester) async {
      late AppState state;
      await tester.runAsync(() async {
        state = AppState();
        await Future.delayed(const Duration(milliseconds: 100));
        await state.resetToCleanSlate();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              state: state,
              onNavigateTab: (_) {},
              onOpenAddLead: () {},
              onOpenScheduleVisit: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify funnel reflects zero leads without artificial progress
      expect(find.text('0% Win Rate', skipOffstage: false), findsOneWidget);
      expect(find.text('0 Leads', skipOffstage: false), findsOneWidget);
      expect(find.text('0 Visited', skipOffstage: false), findsOneWidget);
      expect(find.text('0 Closed Deals', skipOffstage: false), findsOneWidget);

      // Verify brokerage trajectory shows zero amounts
      expect(find.text('Settled: ₹0', skipOffstage: false), findsOneWidget);
      expect(find.text('Pending: ₹0', skipOffstage: false), findsOneWidget);
    });

    testWidgets('AddLeadModalSheet defaults to Cold Lead and excludes Warm and Hot Lead options', (WidgetTester tester) async {
      final state = AppState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddLeadModalSheet(
              state: state,
            ),
          ),
        ),
      );

      // Verify Cold Lead default exists and Warm/Hot lead options are removed
      expect(find.text('Cold Lead', skipOffstage: false), findsOneWidget);
      expect(find.text('DEFAULT', skipOffstage: false), findsOneWidget);
      expect(find.text('Warm Lead'), findsNothing);
      expect(find.text('Hot Lead'), findsNothing);
    });

    testWidgets('LeadsScreen renders all 7 projects and provides functional filtering', (WidgetTester tester) async {
      late AppState state;
      await tester.runAsync(() async {
        state = AppState();
        await Future.delayed(const Duration(milliseconds: 100));
        await state.loadSampleDemoData();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeadsScreen(
              state: state,
              onOpenAddLead: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify all 7 projects exist in state
      expect(state.projects.length, 7);

      // Verify the filter chips are present
      expect(find.text('Sort ▾', skipOffstage: false), findsOneWidget);
      expect(find.text('Project ▾', skipOffstage: false), findsOneWidget);
      expect(find.text('Budget ▾', skipOffstage: false), findsOneWidget);
      expect(find.text('Source ▾', skipOffstage: false), findsOneWidget);

      // Open Project Dropdown
      await tester.tap(find.text('Project ▾'));
      await tester.pumpAndSettle();

      // Verify all 7 project names appear in the popup menu
      expect(find.widgetWithText(PopupMenuItem<String>, 'All Projects'), findsOneWidget);
      expect(find.widgetWithText(PopupMenuItem<String>, 'My Home Avatar'), findsOneWidget);
      expect(find.widgetWithText(PopupMenuItem<String>, 'Prestige Sunshine'), findsOneWidget);
      expect(find.widgetWithText(PopupMenuItem<String>, 'Rajapushpa Provincia'), findsOneWidget);
      expect(find.widgetWithText(PopupMenuItem<String>, 'Aparna Zenon'), findsOneWidget);
      expect(find.widgetWithText(PopupMenuItem<String>, 'Prestige Serenity Palms'), findsOneWidget);
      expect(find.widgetWithText(PopupMenuItem<String>, 'Godrej Skyward Horizons'), findsOneWidget);
      expect(find.widgetWithText(PopupMenuItem<String>, 'Sobha Royal Pavilion'), findsOneWidget);

      // Tap on a project from the popup menu (e.g. Prestige Sunshine)
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Prestige Sunshine'));
      await tester.pumpAndSettle();

      // Verify project chip updated to show Prestige Sunshine and check icon
      expect(find.text('Prestige Sunshine', skipOffstage: false), findsWidgets);
    });

    testWidgets('LeadsScreen displays Just now for newly created leads and correctly responds to date filters and reset button', (WidgetTester tester) async {
      late AppState state;
      await tester.runAsync(() async {
        state = AppState();
        await Future.delayed(const Duration(milliseconds: 100));
      });

      // Add a new lead today
      state.addLead(
        firstName: 'Vasi',
        lastName: 'Client',
        phone: '9876543210',
        budget: '₹80 Lakhs - ₹1.2 Cr',
        configurations: ['2 BHK'],
        projectId: 'proj_avatar',
        projectName: 'My Home Avatar',
        timeline: 'Immediate (<15 days)',
        notes: 'Looking for 2 BHK',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeadsScreen(
              state: state,
              onOpenAddLead: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify Vasi Client appears with 'Just now' (NOT '2 days ago')
      expect(find.text('Vasi Client'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);

      // Verify Reset button exists on the filter bar
      expect(find.byKey(const Key('leads_reset_filters_button')), findsOneWidget);

      // Tap 'Today' date filter
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // In Today filter, Vasi Client is present
      expect(find.text('Vasi Client'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);

      // Tap 'Yesterday' date filter
      await tester.tap(find.text('Yesterday'));
      await tester.pumpAndSettle();

      // In Yesterday filter, Vasi Client is not present
      expect(find.text('Vasi Client'), findsNothing);

      // Tap Reset button
      await tester.tap(find.byKey(const Key('leads_reset_filters_button')));
      await tester.pumpAndSettle();

      // After reset, date filter is back to All Time and Vasi Client is visible again
      expect(state.dashboardDatePreset, DashboardDatePreset.allTime);
      expect(find.text('Vasi Client'), findsOneWidget);
    });

    testWidgets('ProjectsScreen renders without tune filter button and provides dynamic chips for all 7 projects', (WidgetTester tester) async {
      late AppState state;
      await tester.runAsync(() async {
        state = AppState();
        await Future.delayed(const Duration(milliseconds: 100));
        await state.loadSampleDemoData();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsScreen(
              state: state,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the tune filter button beside search is removed
      expect(find.byIcon(Icons.tune_rounded), findsNothing);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Verify filter chips exist for all 7 projects
      expect(find.text('All', skipOffstage: false), findsWidgets);
      expect(find.text('My Home Avatar', skipOffstage: false), findsWidgets);
      expect(find.text('Prestige Sunshine', skipOffstage: false), findsWidgets);
      expect(find.text('Rajapushpa Provincia', skipOffstage: false), findsWidgets);
      expect(find.text('Aparna Zenon', skipOffstage: false), findsWidgets);
      expect(find.text('Prestige Serenity Palms', skipOffstage: false), findsWidgets);
      expect(find.text('Godrej Skyward Horizons', skipOffstage: false), findsWidgets);
      expect(find.text('Sobha Royal Pavilion', skipOffstage: false), findsWidgets);

      // Tap 'My Home Avatar' filter chip which is visible on screen
      await tester.tap(find.text('My Home Avatar').first);
      await tester.pumpAndSettle();

      // Verify My Home Avatar is displayed in the list
      expect(find.text('Gachibowli, Hyderabad'), findsOneWidget);
      // Other project locations are filtered out
      expect(find.text('Kokapet, Hyderabad', skipOffstage: false), findsNothing);

      // Tap 'All' filter chip to restore
      await tester.tap(find.text('All').first);
      await tester.pumpAndSettle();

      // Verify all projects are visible again in state
      expect(find.text('Gachibowli, Hyderabad'), findsOneWidget);
      expect(find.text('Kokapet, Hyderabad', skipOffstage: false), findsOneWidget);
    });
  });
}


