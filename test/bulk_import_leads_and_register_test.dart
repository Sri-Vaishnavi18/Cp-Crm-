import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp_crm/core/state/app_state.dart';
import 'package:cp_crm/features/auth/auth_screens.dart';
import 'package:cp_crm/features/leads/leads_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Lead List Page Bulk Import UI Tests', () {
    testWidgets('LeadsScreen renders Bulk Import button in header', (tester) async {
      final state = AppState();
      await state.loadSampleDemoData();

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

      // Verify "Bulk Import" button is rendered in header
      expect(find.byKey(const Key('leads_bulk_import_button')), findsOneWidget);
      expect(find.text('Bulk Import'), findsOneWidget);
      expect(find.text('Add Lead'), findsOneWidget);
    });

    testWidgets('Tapping Bulk Import button opens BulkImportLeadsModalSheet', (tester) async {
      final state = AppState();
      await state.loadSampleDemoData();

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

      // Tap on Bulk Import button
      await tester.tap(find.byKey(const Key('leads_bulk_import_button')));
      await tester.pumpAndSettle();

      // Verify modal sheet is opened
      expect(find.byType(BulkImportLeadsModalSheet), findsOneWidget);
      expect(find.text('Bulk Import Leads'), findsOneWidget);
      expect(find.text('CSV / Text Data'), findsOneWidget);
      expect(find.text('Sample Templates'), findsOneWidget);

      // Verify NO parsed leads are shown initially
      expect(find.text('Parsed Preview (5 Leads)'), findsNothing);
      expect(find.text('Rahul Sharma'), findsNothing);

      // Verify the beautiful upload button and empty state are present
      expect(find.text('Upload File'), findsOneWidget);
      expect(find.text('No Leads Loaded Yet'), findsOneWidget);
      expect(find.text('Choose CSV / Excel File'), findsOneWidget);
      expect(find.text('Paste or Upload Leads to Import'), findsOneWidget);
    });

    testWidgets('Calls onOpenBulkImport callback when provided', (tester) async {
      final state = AppState();
      await state.loadSampleDemoData();
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeadsScreen(
              state: state,
              onOpenAddLead: () {},
              onOpenBulkImport: () => callbackCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('leads_bulk_import_button')));
      await tester.pump();

      expect(callbackCalled, isTrue);
    });
  });

  group('RegisterScreen Agency/Firm Removal Tests', () {
    testWidgets('RegisterScreen does not show Agency/Firm selector or Agency/Firm Name field', (tester) async {
      final state = AppState();

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(
            state: state,
            onRegisterSuccess: () {},
            onNavigateToLogin: () {},
          ),
        ),
      );
      await tester.pump();

      // Verify Agency / Firm choice chip is removed
      expect(find.text('Agency / Firm'), findsNothing);
      expect(find.text('Individual Realtor'), findsNothing);

      // Verify Agency / Firm Name input field is removed
      expect(find.text('Agency / Firm Name *'), findsNothing);

      // Verify Full Name field is present
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('RERA Registration Number *'), findsOneWidget);
      expect(find.text('Mobile Number * (Sign-In ID)'), findsOneWidget);
      expect(find.text('Create Account & Sign In'), findsOneWidget);
    });

    test('AppState.register registers partner without firmName and isAgency', () async {
      final state = AppState();

      final result = await state.register(
        name: 'Vikas Sharma',
        reraNumber: 'PRM/KA/RERA/1234/567',
        phone: '9876500001',
        email: 'vikas@sharmaproperties.in',
        city: 'Bangalore, Karnataka',
        password: 'password123',
      );

      expect(result.success, isTrue);
      expect(result.user?.name, 'Vikas Sharma');
      expect(result.user?.firmName, 'Vikas Sharma');
      expect(result.user?.isAgency, isFalse);
    });
  });
}
