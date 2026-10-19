import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp_crm/core/state/app_state.dart';
import 'package:cp_crm/core/models/app_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Lead Creation From Scratch & Anti-Override Tests', () {
    test('New registered user starts with 0 leads, 0 visits, and 0 invoices', () async {
      final state = AppState();
      await Future.delayed(const Duration(milliseconds: 100));

      // Register new user
      final result = await state.register(
        name: 'Ashvik Realtor',
        firmName: 'Ashvik Properties',
        reraNumber: 'RERA/ASHVIK/001',
        phone: '9988776655',
        email: 'ashvik@realtor.com',
        city: 'Bangalore',
        isAgency: true,
        password: 'password123',
      );

      expect(result.success, true);
      expect(state.currentUser?.name, 'Ashvik Realtor');

      // Crucial: Clean slate verification
      expect(state.allLeads.length, 0);
      expect(state.siteVisits.length, 0);
      expect(state.allInvoices.length, 0);
      expect(state.dashboardLeads.length, 0);
      expect(state.dashboardSiteVisits.length, 0);
      expect(state.dashboardLeads.where((l) => l.stage == LeadStage.booked).length, 0);
      expect(state.totalCommissionClaimed, 0.0);
    });

    test('Adding Lead #1 starts from scratch and generates unique collision-free ID', () async {
      final state = AppState();
      await Future.delayed(const Duration(milliseconds: 100));

      await state.register(
        name: 'Ashvik Realtor',
        firmName: 'Ashvik Properties',
        reraNumber: 'RERA/ASHVIK/001',
        phone: '9988776655',
        email: 'ashvik@realtor.com',
        city: 'Bangalore',
        isAgency: true,
        password: 'password123',
      );

      expect(state.allLeads.isEmpty, true);

      // Add Lead #1
      state.addLead(
        firstName: 'Rohan',
        lastName: 'Gupta',
        phone: '9876543210',
        email: 'rohan.gupta@example.com',
        budget: '₹1.2 Cr',
        configurations: ['3 BHK'],
        projectId: 'proj_1',
        projectName: 'Prestige Serenity Palms',
        timeline: 'Immediate',
        notes: '',
        temperature: LeadTemperature.hot,
      );

      expect(state.allLeads.length, 1);
      final lead1 = state.allLeads.first;
      expect(lead1.fullName, 'Rohan Gupta');
      expect(lead1.id.startsWith('lead_'), true);
      expect(lead1.stage, LeadStage.cold);
      expect(lead1.temperature, LeadTemperature.hot);

      // Verify no site visits or invoices attached
      final visitsForLead1 = state.siteVisits.where((v) => v.leadId == lead1.id).toList();
      expect(visitsForLead1.isEmpty, true);
    });

    test('Adding Lead #2 does not override Lead #1; both leads coexist independently', () async {
      final state = AppState();
      await Future.delayed(const Duration(milliseconds: 100));

      await state.register(
        name: 'Ashvik Realtor',
        firmName: 'Ashvik Properties',
        reraNumber: 'RERA/ASHVIK/001',
        phone: '9988776655',
        email: 'ashvik@realtor.com',
        city: 'Bangalore',
        isAgency: true,
        password: 'password123',
      );

      // Add Lead 1
      state.addLead(
        firstName: 'Rohan',
        lastName: 'Gupta',
        phone: '9876543210',
        email: 'rohan@example.com',
        budget: '₹1.2 Cr',
        configurations: ['3 BHK'],
        projectId: 'proj_1',
        projectName: 'Prestige Serenity Palms',
        timeline: 'Immediate',
        notes: '',
      );

      // Add Lead 2
      state.addLead(
        firstName: 'Pooja',
        lastName: 'Sharma',
        phone: '9123456789',
        email: 'pooja@example.com',
        budget: '₹2.5 Cr',
        configurations: ['4 BHK'],
        projectId: 'proj_2',
        projectName: 'Godrej Woods',
        timeline: '3 Months',
        notes: '',
      );

      // Total leads must now be exactly 2
      expect(state.allLeads.length, 2);

      final lead1 = state.allLeads.firstWhere((l) => l.fullName == 'Rohan Gupta');
      final lead2 = state.allLeads.firstWhere((l) => l.fullName == 'Pooja Sharma');

      // IDs must be distinct and non-colliding
      expect(lead1.id != lead2.id, true);
      expect(lead1.phone, '9876543210');
      expect(lead2.phone, '9123456789');

      // Updating Lead 1 must not alter Lead 2
      state.updateLeadStage(lead1.id, LeadStage.siteVisited);
      state.addLeadNote(lead1.id, 'Client prefers tower B');

      final updatedLead1 = state.allLeads.firstWhere((l) => l.id == lead1.id);
      final unchangedLead2 = state.allLeads.firstWhere((l) => l.id == lead2.id);

      expect(updatedLead1.stage, LeadStage.siteVisited);
      expect(updatedLead1.notesList.any((n) => n.text == 'Client prefers tower B'), true);

      // Lead 2 must remain completely intact
      expect(unchangedLead2.stage, LeadStage.cold);
      expect(unchangedLead2.notesList.isEmpty, true);
      expect(unchangedLead2.fullName, 'Pooja Sharma');
    });

    test('resetToCleanSlate clears all pipeline leads, visits, and invoices to 0', () async {
      final state = AppState();
      await Future.delayed(const Duration(milliseconds: 100));

      // Load sample data
      await state.loadSampleDemoData();
      expect(state.allLeads.isNotEmpty, true);

      // Reset to clean slate
      await state.resetToCleanSlate();
      expect(state.allLeads.length, 0);
      expect(state.siteVisits.length, 0);
      expect(state.allInvoices.length, 0);
      expect(state.totalCommissionClaimed, 0.0);
    });

    test('SiteVisit serialization and strict isolation', () {
      final visit = SiteVisitModel(
        id: 'vis_test_999',
        visitCode: 'VIS-999',
        leadId: 'lead_test_123',
        clientName: 'Sunita Menon',
        clientPhone: '9888877777',
        projectId: 'proj_1',
        projectName: 'Godrej Woods',
        scheduledAt: DateTime(2025, 5, 20),
        cabRequired: false,
        accompanying: true,
        status: 'Scheduled',
      );

      final json = visit.toJson();
      final fromJson = SiteVisitModel.fromJson(json);

      expect(fromJson.id, 'vis_test_999');
      expect(fromJson.visitCode, 'VIS-999');
      expect(fromJson.leadId, 'lead_test_123');
      expect(fromJson.clientName, 'Sunita Menon');
      expect(fromJson.status, 'Scheduled');
    });
  });
}
