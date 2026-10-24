import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp_crm/core/state/app_state.dart';
import 'package:cp_crm/features/leads/lead_detail_screen.dart';
import 'package:cp_crm/shared/widgets/app_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('ScheduleVisitModalSheet UI and Functionality Tests', () {
    testWidgets('Renders all modal components with proper hierarchy and styling', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = AppState();
      final lead = state.allLeads.first;

      await tester.pumpWidget(
        buildTestApp(
          ScheduleVisitModalSheet(
            state: state,
            preselectedLeadId: lead.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header checks
      expect(find.text('Schedule Digital Site Visit'), findsOneWidget);
      expect(find.text('Direct QR entry pass for site reception (Zero-OTP)'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Section labels
      expect(find.text('Select Lead *'), findsOneWidget);
      expect(find.text('Target Project *'), findsOneWidget);
      expect(find.text('Visit Date & Time Slot *'), findsOneWidget);
      expect(find.text('Visit Logistics & Concierge'), findsOneWidget);
      expect(find.text('Request Builder Cab Pickup'), findsOneWidget);
      expect(find.text('Broker Accompanying Client'), findsOneWidget);

      // Submit Button
      expect(find.text('Generate Digital QR Entry Pass (Zero-OTP)'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
    });

    testWidgets('Toggles cab pickup and accompanying client switches', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = AppState();
      final lead = state.allLeads.first;

      await tester.pumpWidget(
        buildTestApp(
          ScheduleVisitModalSheet(
            state: state,
            preselectedLeadId: lead.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));

      // Toggle cab pickup (first switch)
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      final firstSwitch = tester.widget<Switch>(switches.first);
      expect(firstSwitch.value, true);
    });

    testWidgets('Submitting creates site visit and updates AppState', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = AppState();
      final lead = state.allLeads.first;
      final initialVisitCount = state.siteVisits.length;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => ScheduleVisitModalSheet(
                        state: state,
                        preselectedLeadId: lead.id,
                      ),
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Digital Site Visit'), findsOneWidget);

      final submitBtn = find.text('Generate Digital QR Entry Pass (Zero-OTP)');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Modal closed, visit created
      expect(find.text('Schedule Digital Site Visit'), findsNothing);
      expect(state.siteVisits.length, initialVisitCount + 1);
      expect(find.textContaining('Scheduled! Digital QR Pass generated'), findsOneWidget);
    });

    testWidgets('LeadDetailScreen opens ScheduleVisitModalSheet without defect', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = AppState();
      final lead = state.allLeads.first;

      await tester.pumpWidget(
        MaterialApp(
          home: LeadDetailScreen(
            state: state,
            leadId: lead.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find schedule button and scroll into view if needed
      final scheduleBtn = find.text('Schedule');
      await tester.ensureVisible(scheduleBtn);
      await tester.pumpAndSettle();
      await tester.tap(scheduleBtn);
      await tester.pumpAndSettle();

      // Verify modal sheet is displayed
      expect(find.text('Schedule Digital Site Visit'), findsOneWidget);
      expect(find.text('Direct QR entry pass for site reception (Zero-OTP)'), findsOneWidget);

      // Close modal using close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Digital Site Visit'), findsNothing);
    });
  });
}
