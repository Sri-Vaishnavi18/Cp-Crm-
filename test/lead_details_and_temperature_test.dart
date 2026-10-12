import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp_crm/core/models/app_models.dart';
import 'package:cp_crm/core/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Lead Temperature Rule Tests', () {
    test('LeadModel.getTemperatureForStage returns Cold for cold lead', () {
      expect(LeadModel.getTemperatureForStage(LeadStage.cold), LeadTemperature.cold);
    });

    test('LeadModel.getTemperatureForStage returns Warm for site visited', () {
      expect(LeadModel.getTemperatureForStage(LeadStage.siteVisited), LeadTemperature.warm);
    });

    test('LeadModel.getTemperatureForStage returns Hot for booked', () {
      expect(LeadModel.getTemperatureForStage(LeadStage.booked), LeadTemperature.hot);
    });
  });

  group('AppState Lead Stage & Temperature Automatic Cascade Tests', () {
    test('AppState.addLead creates a new lead with cold temperature by default', () {
      final state = AppState();
      state.addLead(
        firstName: 'Test',
        lastName: 'Client',
        phone: '9988776655',
        email: 'test.client@example.com',
        budget: '₹1 Cr',
        configurations: ['2 BHK'],
        projectId: 'proj_1',
        projectName: 'Prestige Serenity Palms',
        timeline: '1 Month',
        notes: 'Interested in floor 5+',
      );

      final newLead = state.allLeads.firstWhere((l) => l.phone == '9988776655');
      expect(newLead.stage, LeadStage.cold);
      expect(newLead.temperature, LeadTemperature.cold);
      expect(newLead.notesList.length, 1);
      expect(newLead.activityList.isNotEmpty, true);
    });

    test('Updating stage to siteVisited automatically cascades temperature to Warm', () {
      final state = AppState();
      state.addLead(
        firstName: 'Ramesh',
        lastName: 'Kumar',
        phone: '9877001122',
        budget: '₹85 Lakhs',
        configurations: ['2 BHK'],
        projectId: 'proj_1',
        projectName: 'Prestige Serenity Palms',
        timeline: 'Immediate',
        notes: '',
      );

      final lead = state.allLeads.firstWhere((l) => l.phone == '9877001122');
      expect(lead.temperature, LeadTemperature.cold);

      state.updateLeadStage(lead.id, LeadStage.siteVisited);
      expect(lead.stage, LeadStage.siteVisited);
      expect(lead.temperature, LeadTemperature.warm);
    });

    test('Updating stage to booked automatically cascades temperature to Hot', () {
      final state = AppState();
      state.addLead(
        firstName: 'Suresh',
        lastName: 'Raina',
        phone: '9877003344',
        budget: '₹2 Cr',
        configurations: ['3 BHK'],
        projectId: 'proj_1',
        projectName: 'Prestige Serenity Palms',
        timeline: 'Immediate',
        notes: '',
      );

      final lead = state.allLeads.firstWhere((l) => l.phone == '9877003344');
      state.updateLeadStage(lead.id, LeadStage.booked);
      expect(lead.stage, LeadStage.booked);
      expect(lead.temperature, LeadTemperature.hot);
    });

    test('Adding notes and scheduling Zero-OTP site visit appends to lead history', () {
      final state = AppState();
      final lead = state.allLeads.first;

      state.addLeadNote(lead.id, 'Client confirmed preference for morning visit');
      expect(lead.notesList.any((n) => n.text.contains('Client confirmed preference')), true);

      final visitCode = state.scheduleSiteVisit(
        leadId: lead.id,
        projectId: lead.projectId,
        scheduledAt: DateTime.now().add(const Duration(days: 2)),
        cabRequired: false,
        accompanying: true,
      );

      expect(visitCode.startsWith('VIS-'), true);
      expect(lead.siteVisitHistory.isNotEmpty, true);

      // CP updates status to siteVisited
      state.updateLeadStage(lead.id, LeadStage.siteVisited);
      expect(lead.temperature, LeadTemperature.warm);
    });
  });
}
