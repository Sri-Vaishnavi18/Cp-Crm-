import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp_crm/core/state/app_state.dart';
import 'package:cp_crm/core/models/app_models.dart';
import 'package:cp_crm/features/profile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Sync & Notification Persistence Tests', () {
    test('AppNotificationModel serialization and deserialization round-trip', () {
      final now = DateTime(2026, 10, 18, 15, 30);
      final notif = AppNotificationModel(
        id: 'notif_001',
        title: 'Payout Approved',
        message: 'Commission of ₹1.5L approved',
        type: 'broadcast',
        timestamp: now,
        isRead: true,
        targetRoute: '/commissions',
        targetId: 'inv_101',
      );

      final json = notif.toJson();
      expect(json['id'], 'notif_001');
      expect(json['title'], 'Payout Approved');
      expect(json['isRead'], true);
      expect(json['targetRoute'], '/commissions');

      final reconstructed = AppNotificationModel.fromJson(json);
      expect(reconstructed.id, notif.id);
      expect(reconstructed.title, notif.title);
      expect(reconstructed.message, notif.message);
      expect(reconstructed.type, notif.type);
      expect(reconstructed.isRead, true);
      expect(reconstructed.timestamp, now);
      expect(reconstructed.targetRoute, '/commissions');
      expect(reconstructed.targetId, 'inv_101');
    });

    test('Notifications read status persists permanently across user login session', () async {
      final state = AppState();
      await Future.delayed(const Duration(milliseconds: 100));

      final auth = await state.register(
        name: 'Rohan Sharma',
        firmName: 'Rohan Realty',
        reraNumber: 'RERA/KA/7788',
        phone: '9876543210',
        email: 'rohan@realty.com',
        city: 'Bangalore',
        isAgency: false,
        password: 'Pass@1234',
      );
      expect(auth.success, true);

      // Registering adds welcome notification (unread)
      expect(state.notifications.isNotEmpty, true);
      expect(state.unreadNotificationCount, greaterThan(0));

      // Mark all read
      state.markAllNotificationsRead();
      expect(state.unreadNotificationCount, 0);

      // Add a lead which triggers a new lead notification
      state.addLead(
        firstName: 'Ananya',
        lastName: 'Roy',
        phone: '9123456780',
        budget: '₹1.2 Cr',
        configurations: ['2 BHK'],
        projectId: 'proj_1',
        projectName: 'Prestige Falcon City',
        timeline: '30 Days',
        notes: 'Interested in tower B',
      );

      // Verify unread count is 1 (the lead notification)
      expect(state.unreadNotificationCount, 1);
      final leadNotif = state.notifications.firstWhere((n) => n.type == 'lead');
      expect(leadNotif.isRead, false);

      // Mark that lead notification as read
      state.markNotificationRead(leadNotif.id);
      expect(state.unreadNotificationCount, 0);

      // Log out
      await state.logout();
      expect(state.notifications.isEmpty, true);
      expect(state.unreadNotificationCount, 0);

      // Log back in as Rohan Sharma
      final loginResult = await state.login(
        identifier: '9876543210',
        password: 'Pass@1234',
      );
      expect(loginResult.success, true);

      // Verify notifications were restored from SharedPreferences with isRead == true
      expect(state.notifications.isNotEmpty, true);
      expect(state.unreadNotificationCount, 0);
      expect(state.notifications.every((n) => n.isRead), true);
    });

    test('Offline Lead queuing and triggerCloudSync() execution', () async {
      final state = AppState();
      await Future.delayed(const Duration(milliseconds: 100));

      await state.register(
        name: 'Suresh Patil',
        firmName: 'Patil Estates',
        reraNumber: 'RERA/KA/5566',
        phone: '9845012345',
        email: 'suresh@patil.com',
        city: 'Bangalore',
        isAgency: true,
        password: 'Pass@1234',
      );

      // Go offline
      state.toggleOfflineMode();
      expect(state.isOffline, true);

      // Add lead while offline
      state.addLead(
        firstName: 'Karan',
        lastName: 'Mehta',
        phone: '9888877777',
        budget: '₹95 Lakhs',
        configurations: ['3 BHK'],
        projectId: 'proj_2',
        projectName: 'Brigade Gateway',
        timeline: 'Immediate',
        notes: 'Offline spot inquiry',
      );

      expect(state.offlineQueueCount, 1);
      expect(state.allLeads.first.isQueuedOffline, true);

      // Trigger Cloud Sync
      final initialSyncTime = state.lastSyncedAt;
      final syncedCount = await state.triggerCloudSync();

      expect(syncedCount, 1);
      expect(state.offlineQueueCount, 0);
      expect(state.allLeads.first.isQueuedOffline, false);
      expect(state.lastSyncedAt.isAfter(initialSyncTime) || state.lastSyncedAt.isAtSameMomentAs(initialSyncTime), true);

      // Sync notification was created
      final syncNotif = state.notifications.firstWhere((n) => n.title.contains('Cloud Sync'));
      expect(syncNotif, isNotNull);
    });

    testWidgets('ProfileScreen renders interactive Sync Status and dynamic notification badge', (tester) async {
      final state = AppState();
      state.markAllNotificationsRead();

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(state: state),
        ),
      );
      await tester.pump();

      // Check Sync Status Card is rendered with SYNCED badge and tap hint
      expect(find.text('Sync Status'), findsOneWidget);
      expect(find.text('(Tap to sync)'), findsOneWidget);
      expect(find.text('SYNCED'), findsOneWidget);

      // Verify no hardcoded '4' badge is visible when unread count is 0
      expect(find.text('4'), findsNothing);

      // Now add an unread notification
      state.addLead(
        firstName: 'Vikram',
        lastName: 'Malhotra',
        phone: '9822233344',
        budget: '₹2.5 Cr',
        configurations: ['4 BHK'],
        projectId: 'proj_1',
        projectName: 'Prestige Falcon City',
        timeline: '60 Days',
        notes: 'Luxury seeker',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(state: state),
        ),
      );
      await tester.pump();

      // Now unread count is 1, so badge '1' should appear on Notifications menu item
      expect(find.text('1'), findsOneWidget);
    });
  });
}
