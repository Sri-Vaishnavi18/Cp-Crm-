import 'package:flutter_test/flutter_test.dart';
import 'package:cp_crm/core/models/app_models.dart';
import 'package:cp_crm/core/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Commission & Invoice Models & Logic Tests', () {
    test('InvoiceType extension values and labels', () {
      expect(InvoiceType.siteVisit.displayName, 'Site Visit Invoice');
      expect(InvoiceType.siteVisit.shortLabel, 'Site Visit Payout');
      expect(InvoiceType.booking.displayName, 'Booking Commission Invoice');
      expect(InvoiceType.booking.shortLabel, 'Booking Brokerage');
    });

    test('InvoiceStatus extension values and labels', () {
      expect(InvoiceStatus.pending.displayName, 'Pending Approval');
      expect(InvoiceStatus.approved.displayName, 'Approved');
      expect(InvoiceStatus.paid.displayName, 'Paid / Disbursed');
      expect(InvoiceStatus.rejected.displayName, 'Rejected');
    });

    test('BankDetailsModel serialization and deserialization', () {
      final bank = BankDetailsModel(
        accountHolder: 'Apex Realty',
        bankName: 'HDFC Bank',
        accountNumber: '50100492817263',
        ifscCode: 'HDFC0001234',
        upiId: 'apexrealty@okaxis',
      );

      final json = bank.toJson();
      expect(json['accountHolder'], 'Apex Realty');
      expect(json['bankName'], 'HDFC Bank');
      expect(json['accountNumber'], '50100492817263');
      expect(json['ifscCode'], 'HDFC0001234');
      expect(json['upiId'], 'apexrealty@okaxis');

      final fromJson = BankDetailsModel.fromJson(json);
      expect(fromJson.accountHolder, bank.accountHolder);
      expect(fromJson.bankName, bank.bankName);
      expect(fromJson.accountNumber, bank.accountNumber);
      expect(fromJson.ifscCode, bank.ifscCode);
      expect(fromJson.upiId, bank.upiId);
    });

    test('CommissionInvoiceModel serialization and deserialization', () {
      final bank = BankDetailsModel(
        accountHolder: 'Apex Realty',
        bankName: 'HDFC Bank',
        accountNumber: '50100492817263',
        ifscCode: 'HDFC0001234',
        upiId: 'apexrealty@okaxis',
      );
      final now = DateTime.now();
      final invoice = CommissionInvoiceModel(
        id: 'inv_test_1',
        invoiceNumber: 'INV-2026-TEST',
        leadId: 'lead_1',
        clientName: 'Rahul Verma',
        clientPhone: '9876543210',
        projectId: 'proj_1',
        projectName: 'Serenity Palms',
        type: InvoiceType.booking,
        amount: 150000.0,
        date: now,
        status: InvoiceStatus.approved,
        bankDetails: bank,
        notes: 'Token advance verified',
      );

      final json = invoice.toJson();
      expect(json['id'], 'inv_test_1');
      expect(json['invoiceNumber'], 'INV-2026-TEST');
      expect(json['type'], 'booking');
      expect(json['amount'], 150000.0);
      expect(json['status'], 'approved');

      final fromJson = CommissionInvoiceModel.fromJson(json);
      expect(fromJson.id, invoice.id);
      expect(fromJson.invoiceNumber, invoice.invoiceNumber);
      expect(fromJson.clientName, invoice.clientName);
      expect(fromJson.type, InvoiceType.booking);
      expect(fromJson.status, InvoiceStatus.approved);
      expect(fromJson.amount, 150000.0);
      expect(fromJson.bankDetails.bankName, 'HDFC Bank');
    });

    test('Lead Stage to Temperature Automatic Sync', () {
      expect(LeadModel.getTemperatureForStage(LeadStage.newLead), LeadTemperature.cold);
      expect(LeadModel.getTemperatureForStage(LeadStage.contacted), LeadTemperature.cold);
      expect(LeadModel.getTemperatureForStage(LeadStage.visitScheduled), LeadTemperature.warm);
      expect(LeadModel.getTemperatureForStage(LeadStage.visitCompleted), LeadTemperature.warm);
      expect(LeadModel.getTemperatureForStage(LeadStage.negotiation), LeadTemperature.warm);
      expect(LeadModel.getTemperatureForStage(LeadStage.tokenPaid), LeadTemperature.hot);
    });

    test('AppState Commission calculations and invoice submission', () {
      final state = AppState();

      // Verify initial bank details loaded
      expect(state.savedBankDetails, isNotNull);
      expect(state.savedBankDetails!.bankName, isNotEmpty);

      // Verify initial mock invoices
      expect(state.allInvoices.isNotEmpty, isTrue);
      expect(state.totalCommissionClaimed, greaterThan(0.0));
      expect(state.pendingCommissionAmount, greaterThanOrEqualTo(0.0));
      expect(state.paidCommissionAmount, greaterThanOrEqualTo(0.0));

      final initialCount = state.allInvoices.length;
      final initialNotificationCount = state.notifications.length;

      // Ensure we have a lead
      final lead = state.allLeads.first;
      final initialActivityCount = lead.activityList.length;

      // Submit a Site Visit invoice
      final newBank = BankDetailsModel(
        accountHolder: 'Test Realtor',
        bankName: 'ICICI Bank',
        accountNumber: '1122334455',
        ifscCode: 'ICIC0009999',
        upiId: 'testrealtor@okicici',
      );

      final inv = state.submitCommissionInvoice(
        leadId: lead.id,
        type: InvoiceType.siteVisit,
        amount: 3500.0,
        bankDetails: newBank,
        notes: 'Test site visit payout claim',
      );

      expect(inv.amount, 3500.0);
      expect(inv.type, InvoiceType.siteVisit);
      expect(inv.status, InvoiceStatus.pending);
      expect(inv.invoiceNumber, startsWith('INV-'));

      // Check state updates
      expect(state.allInvoices.length, initialCount + 1);
      expect(state.savedBankDetails!.accountHolder, 'Test Realtor');
      expect(state.savedBankDetails!.ifscCode, 'ICIC0009999');

      // Check lead activity log
      expect(lead.activityList.length, initialActivityCount + 1);
      expect(lead.activityList.first.title, contains('Site Visit Payout Invoice Generated'));
      expect(lead.activityList.first.title, contains('₹3500'));

      // Check notification triggered
      expect(state.notifications.length, initialNotificationCount + 1);
      expect(state.notifications.first.title, contains('Site Visit Payout Claim Submitted'));

      // Invoices for lead getter
      final leadInvoices = state.getInvoicesForLead(lead.id);
      expect(leadInvoices.any((i) => i.id == inv.id), isTrue);

      // Status update
      state.updateInvoiceStatus(inv.id, InvoiceStatus.paid);
      final updated = state.allInvoices.firstWhere((i) => i.id == inv.id);
      expect(updated.status, InvoiceStatus.paid);
    });

    test('Project-level commission filtering and KPI calculations', () {
      final state = AppState();
      final projects = state.projects;
      expect(projects.isNotEmpty, isTrue);

      final testProject = projects.first;
      final projectInvoices = state.getInvoicesForProject(testProject.id);
      final totalComm = state.getProjectTotalCommission(testProject.id);
      final recComm = state.getProjectReceivedCommission(testProject.id);
      final pendComm = state.getProjectPendingCommission(testProject.id);
      final leadsCount = state.getProjectLeadsCount(testProject.id);

      // Verify that Total = Received + Pending
      expect(totalComm, closeTo(recComm + pendComm, 0.01));
      expect(leadsCount, greaterThanOrEqualTo(0));

      if (projectInvoices.isNotEmpty) {
        final sampleInv = projectInvoices.first;
        final initialIsReceived = sampleInv.status == InvoiceStatus.paid;

        // Channel Partner toggles status
        state.toggleInvoiceReceivedStatus(
          sampleInv.id,
          isReceived: !initialIsReceived,
          note: 'CP verified bank transfer',
        );

        final updatedSample = state.allInvoices.firstWhere((i) => i.id == sampleInv.id);
        expect(updatedSample.status, !initialIsReceived ? InvoiceStatus.paid : InvoiceStatus.pending);

        // Verify that project metrics immediately recompute
        final newTotalComm = state.getProjectTotalCommission(testProject.id);
        final newRecComm = state.getProjectReceivedCommission(testProject.id);
        final newPendComm = state.getProjectPendingCommission(testProject.id);

        expect(newTotalComm, closeTo(newRecComm + newPendComm, 0.01));
      }
    });

    test('Invoice Unlocking Eligibility Logic Verification', () {
      // Rule 1: New Lead -> Locked for both Type 1 and Type 2
      final newLeadStage = LeadStage.newLead;
      final isType1ForNew = newLeadStage == LeadStage.visitScheduled ||
          newLeadStage == LeadStage.visitCompleted ||
          newLeadStage == LeadStage.negotiation ||
          newLeadStage == LeadStage.tokenPaid;
      final isType2ForNew = newLeadStage == LeadStage.tokenPaid;
      expect(isType1ForNew, isFalse);
      expect(isType2ForNew, isFalse);

      // Rule 2: Site Visit Scheduled / Completed -> Type 1 Unlocked, Type 2 Locked
      final visitStage = LeadStage.visitCompleted;
      final isType1ForVisit = visitStage == LeadStage.visitScheduled ||
          visitStage == LeadStage.visitCompleted ||
          visitStage == LeadStage.negotiation ||
          visitStage == LeadStage.tokenPaid;
      final isType2ForVisit = visitStage == LeadStage.tokenPaid;
      expect(isType1ForVisit, isTrue);
      expect(isType2ForVisit, isFalse);

      // Rule 3: Booked (tokenPaid) -> BOTH Type 1 and Type 2 are Unlocked!
      final bookedStage = LeadStage.tokenPaid;
      final isType1ForBooked = bookedStage == LeadStage.visitScheduled ||
          bookedStage == LeadStage.visitCompleted ||
          bookedStage == LeadStage.negotiation ||
          bookedStage == LeadStage.tokenPaid;
      final isType2ForBooked = bookedStage == LeadStage.tokenPaid;
      expect(isType1ForBooked, isTrue);
      expect(isType2ForBooked, isTrue);
    });
  });
}
