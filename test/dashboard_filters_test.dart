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

      // Verify Pipeline Health is rendered
      expect(find.text('Pipeline Health'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Visit Set'), findsOneWidget);
      expect(find.text('Visit Done'), findsOneWidget);
      expect(find.text('Booked'), findsOneWidget);

      // Verify Builder Announcements is NOT present
      expect(find.text('Builder Announcements & Pre-Launches'), findsNothing);

      // Verify Leads section is rendered with lead names
      expect(find.text('Leads'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      expect(find.text('Deepak Verma'), findsOneWidget);
      expect(find.text('Ananya Iyer'), findsOneWidget);

      // Verify Commission Analytics Cards are rendered
      expect(find.text('Commission Pending'), findsOneWidget);
      expect(find.text('Commission Received'), findsOneWidget);
      expect(find.text(state.commissionPendingFormatted), findsOneWidget);
      expect(find.text(state.commissionReceivedFormatted), findsOneWidget);
    });
  });
}
