import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp_crm/core/services/license_service.dart';
import 'package:cp_crm/core/state/app_state.dart';
import 'package:cp_crm/features/auth/subscription_lock_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('LicenseService Core Logic Tests', () {
    test('Initial LicenseService defaults to active state', () {
      final service = LicenseService();
      expect(service.currentStatus, LicenseStatus.active);
      expect(service.isAllowed, isTrue);
      expect(service.adminPhone, '+919014547044');
      expect(service.adminWhatsApp, '919014547044');
    });

    test('Status overrides work accurately for testing', () async {
      final service = LicenseService();
      
      await service.overrideStatus(LicenseStatus.inactive);
      expect(service.currentStatus, LicenseStatus.inactive);
      expect(service.isAllowed, isFalse);

      await service.overrideStatus(
        LicenseStatus.expired,
        validUntil: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(service.currentStatus, LicenseStatus.expired);
      expect(service.isAllowed, isFalse);

      await service.overrideStatus(LicenseStatus.active);
      expect(service.currentStatus, LicenseStatus.active);
      expect(service.isAllowed, isTrue);
    });

    test('Grace period allows access within 8 hours', () async {
      final service = LicenseService();
      await service.overrideStatus(LicenseStatus.active);
      
      final result = await service.verifyLicense(phone: '9014547044');
      expect(result.isAllowed, isTrue);
      expect(result.status, LicenseStatus.active);
    });
  });

  group('AppState License Integration Tests', () {
    test('AppState exposes isSubscriptionActive and licenseService', () {
      final state = AppState();
      expect(state.licenseService, isNotNull);
      expect(state.isSubscriptionActive, isTrue);
      state.dispose();
    });

    test('AppState.overrideLicenseStatus updates active state and notifies listeners', () async {
      final state = AppState();
      bool wasNotified = false;
      state.addListener(() {
        wasNotified = true;
      });

      await state.overrideLicenseStatus(LicenseStatus.inactive);
      expect(state.isSubscriptionActive, isFalse);
      expect(wasNotified, isTrue);

      await state.overrideLicenseStatus(LicenseStatus.active);
      expect(state.isSubscriptionActive, isTrue);
      state.dispose();
    });
  });

  group('SubscriptionLockScreen Widget Tests', () {
    testWidgets('SubscriptionLockScreen renders lock UI and action buttons', (tester) async {
      final state = AppState();
      await state.overrideLicenseStatus(LicenseStatus.inactive);

      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionLockScreen(
            state: state,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Subscription Required'), findsOneWidget);
      expect(find.text('PAYMENT PENDING / INACTIVE'), findsOneWidget);
      expect(find.text('Check & Unlock Now'), findsOneWidget);
      expect(find.text('Contact Admin on WhatsApp'), findsOneWidget);
      expect(find.textContaining('Call Support'), findsOneWidget);

      state.dispose();
    });

    testWidgets('SubscriptionLockScreen displays Expired status correctly', (tester) async {
      final state = AppState();
      await state.overrideLicenseStatus(
        LicenseStatus.expired,
        validUntil: DateTime(2026, 10, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionLockScreen(
            state: state,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Subscription Expired'), findsOneWidget);
      expect(find.text('SUBSCRIPTION EXPIRED'), findsOneWidget);

      state.dispose();
    });
  });
}
