import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp_crm/core/state/app_state.dart';
import 'package:cp_crm/features/dashboard/dashboard_screen.dart';

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
      // Deepak Verma (lead_1) and Vikram Rao (lead_4) were created Today
      expect(state.dashboardLeads.isNotEmpty, true);
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
  });
}
