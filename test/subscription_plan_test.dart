import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp_crm/core/state/app_state.dart';
import 'package:cp_crm/core/services/license_service.dart';
import 'package:cp_crm/features/home/main_navigation_shell.dart';
import 'package:cp_crm/features/subscription/subscription_models.dart';
import 'package:cp_crm/features/subscription/subscription_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('Subscription Models & Pricing Tests', () {
    test('Available plans contain exact user-specified tiers and pricing', () {
      final plans = SubscriptionPlanModel.availablePlans;
      expect(plans.length, 3);

      // Tier 1: 1 Month @ ₹1,000
      final m1 = plans[0];
      expect(m1.tier, SubscriptionTier.monthly);
      expect(m1.price, 1000.0);
      expect(m1.durationDays, 30);
      expect(m1.durationMonths, 1);
      expect(m1.formattedPrice, '₹1000');
      expect(m1.monthlyEquivalent, 1000.0);

      // Tier 2: 6 Months @ ₹5,000 (Save ₹1,000)
      final m6 = plans[1];
      expect(m6.tier, SubscriptionTier.halfYearly);
      expect(m6.price, 5000.0);
      expect(m6.durationDays, 180);
      expect(m6.durationMonths, 6);
      expect(m6.formattedPrice, '₹5000');
      expect(m6.savingsText, contains('Save ₹1,000'));
      expect(m6.isPopular, isTrue);

      // Tier 3: 1 Year @ ₹10,000 (Save ₹2,000 / 2 Months FREE)
      final y1 = plans[2];
      expect(y1.tier, SubscriptionTier.annual);
      expect(y1.price, 10000.0);
      expect(y1.durationDays, 365);
      expect(y1.durationMonths, 12);
      expect(y1.formattedPrice, '₹10000');
      expect(y1.savingsText, contains('Save ₹2,000'));
      expect(y1.isBestValue, isTrue);
    });
  });

  group('Navigation Bar Subscription Tab Widget Tests', () {
    testWidgets('MainNavigationShell renders Subscription tab in bottom nav and navigates on tap', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationShell(state: state),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 'Subscription' tab exists in bottom nav
      expect(find.text('Subscription'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_outlined), findsOneWidget);

      // Tap 'Subscription' tab
      await tester.tap(find.text('Subscription'));
      await tester.pumpAndSettle();

      // Verify SubscriptionScreen is now visible
      expect(find.text('Subscription Plans'), findsOneWidget);
      expect(find.text('Verified Partner Licensing'), findsOneWidget);
      expect(find.text('CURRENT ACTIVE PLAN'), findsOneWidget);

      // Verify all 3 tiers are rendered
      expect(find.text('1 Month Starter'), findsOneWidget);
      expect(find.text('6 Months Pro'), findsOneWidget);
      expect(find.text('1 Year Elite'), findsOneWidget);
      expect(find.text('₹1000'), findsOneWidget);
      expect(find.text('₹5000'), findsWidgets);
      expect(find.text('₹10000'), findsOneWidget);

      state.dispose();
    });
  });

  group('SubscriptionScreen & Checkout Flow Widget Tests', () {
    testWidgets('Selecting a plan updates sticky bottom bar and opens checkout modal', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubscriptionScreen(state: state),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default selected is 6 Months Pro (₹5000)
      expect(find.text('Subscribe Now'), findsOneWidget);
      expect(find.text('₹5000'), findsWidgets);

      // Tap 1 Year Elite plan
      await tester.tap(find.text('1 Year Elite'));
      await tester.pumpAndSettle();

      // Sticky bar now shows ₹10000
      expect(find.text('₹10000'), findsWidgets);

      // Tap 'Subscribe Now' button to open checkout sheet
      await tester.tap(find.text('Subscribe Now'));
      await tester.pumpAndSettle();

      // Checkout sheet details should appear
      expect(find.text('Complete Payment'), findsOneWidget);
      expect(find.text('1. Instant UPI Transfer'), findsOneWidget);
      expect(find.text('cpcrm.pay@icici'), findsOneWidget);
      expect(find.text('2. Bank Transfer / NEFT / IMPS'), findsOneWidget);
      expect(find.text('Send Payment Screenshot on WhatsApp'), findsOneWidget);
      expect(find.text('Activate & Sync to Supabase Cloud'), findsOneWidget);

      state.dispose();
    });

    testWidgets('AppState extendSubscription updates license status and expiry date', (tester) async {
      final state = AppState();

      final res = await state.extendSubscription(
        daysToAdd: 180,
        planName: '6 Months Pro',
      );

      expect(res.status, LicenseStatus.active);
      expect(res.isAllowed, isTrue);
      expect(state.licenseService.plan, '6 Months Pro');
      expect(state.licenseService.currentStatus, LicenseStatus.active);
      expect(state.licenseService.validUntil, isNotNull);

      state.dispose();
    });
  });
}
