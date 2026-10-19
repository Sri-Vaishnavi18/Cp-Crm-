import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cp_crm/core/models/app_models.dart';
import 'package:cp_crm/core/services/mock_data_service.dart';
import 'package:cp_crm/core/services/file_download_service.dart';
import 'package:cp_crm/core/state/app_state.dart';
import 'package:cp_crm/features/projects/project_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Clean Document State & Upload Verification Tests', () {
    test('Initial CP documents start in unuploaded state with null fileName and missing status', () {
      final initialDocs = MockDataService.getInitialCpDocuments();

      expect(initialDocs.isNotEmpty, true);
      for (final doc in initialDocs) {
        expect(doc.fileName, isNull, reason: 'Doc ${doc.title} should not have a fake file');
        expect(doc.fileSize, isNull, reason: 'Doc ${doc.title} should not have a fake size');
        expect(doc.status, CpDocumentStatus.missing, reason: 'Doc ${doc.title} should be missing');
      }
    });

    test('AppState uploads and updates document properly', () async {
      final state = AppState();
      await Future.delayed(const Duration(milliseconds: 50));

      final reraDoc = state.cpDocuments.firstWhere((d) => d.id == 'doc_rera');
      expect(reraDoc.fileName, isNull);
      expect(reraDoc.status, CpDocumentStatus.missing);

      // Upload RERA Certificate
      await state.uploadOrUpdateDocument(
        documentId: 'doc_rera',
        documentNumber: 'MAHARERA12345678',
        fileName: 'my_official_rera_license.pdf',
        fileSize: '1.9 MB',
        documentType: CpDocumentType.reraCertificate,
      );

      final updatedDoc = state.cpDocuments.firstWhere((d) => d.id == 'doc_rera');
      expect(updatedDoc.fileName, 'my_official_rera_license.pdf');
      expect(updatedDoc.fileSize, '1.9 MB');
      expect(updatedDoc.documentNumber, 'MAHARERA12345678');
      expect(updatedDoc.status, CpDocumentStatus.underReview);

      // Reset / delete resets mandatory doc back to missing with null fileName
      await state.deleteDocument('doc_rera');
      final deletedDoc = state.cpDocuments.firstWhere((d) => d.id == 'doc_rera');
      expect(deletedDoc.fileName, isNull);
      expect(deletedDoc.fileSize, isNull);
      expect(deletedDoc.status, CpDocumentStatus.missing);
    });
  });

  group('PDF Generation & Download File Tests', () {
    test('generateCertificatePdf outputs authentic PDF-1.4 bytes', () {
      final bytes = FileDownloadService.generateCertificatePdf(
        title: 'RERA Registration Certificate',
        documentNumber: 'A51800034921',
        status: 'VERIFIED',
        validTill: '31/12/2026',
        partnerName: 'Authorized Real Estate Associate',
        remarks: 'Digitally verified compliance document.',
      );

      expect(bytes.isNotEmpty, true);
      final pdfHeader = String.fromCharCodes(bytes.take(8));
      expect(pdfHeader, startsWith('%PDF-1.4'));
    });

    test('generateInvoicePdf outputs authentic PDF-1.4 bytes', () {
      final bytes = FileDownloadService.generateInvoicePdf(
        voucherNumber: 'DISB-BKG-8819',
        clientName: 'Rahul Sharma',
        projectName: 'Summer Park',
        grossAmount: 160000.0,
        tdsAmount: 8000.0,
        netAmount: 152000.0,
        utrNumber: 'HDFC8829103991',
        bankName: 'HDFC Bank',
        dateStr: '18 October 2026',
      );

      expect(bytes.isNotEmpty, true);
      final pdfHeader = String.fromCharCodes(bytes.take(8));
      expect(pdfHeader, startsWith('%PDF-1.4'));
    });

    test('generateDocumentTypePdf creates distinct, authentic PDFs for each document type', () {
      // 1. RERA Certificate
      final reraBytes = FileDownloadService.generateDocumentTypePdf(
        type: CpDocumentType.reraCertificate,
        title: 'RERA Registration Certificate',
        documentNumber: 'RERA-TS-2024-9912',
        status: 'VERIFIED',
        partnerName: 'Vaishu Realty Associates',
        remarks: 'Agent empanelment valid.',
      );
      final reraStr = String.fromCharCodes(reraBytes);
      expect(reraStr.contains('REAL ESTATE REGULATORY AUTHORITY'), isTrue);
      expect(reraStr.contains('FORM B'), isTrue);

      // 2. PAN Card
      final panBytes = FileDownloadService.generateDocumentTypePdf(
        type: CpDocumentType.panCard,
        title: 'PAN Card',
        documentNumber: 'ABCDE1234F',
        status: 'VERIFIED',
        partnerName: 'Vaishu',
        remarks: 'PAN verified for TDS.',
      );
      final panStr = String.fromCharCodes(panBytes);
      expect(panStr.contains('INCOME TAX DEPARTMENT'), isTrue);
      expect(panStr.contains('PERMANENT ACCOUNT NUMBER CARD'), isTrue);
      expect(panStr.contains('ABCDE1234F'), isTrue);

      // 3. GST Certificate
      final gstBytes = FileDownloadService.generateDocumentTypePdf(
        type: CpDocumentType.gstCertificate,
        title: 'GST Certificate',
        documentNumber: '36AAAAA0000A1Z5',
        status: 'VERIFIED',
        partnerName: 'Vaishu Agency',
        remarks: 'GST active.',
      );
      final gstStr = String.fromCharCodes(gstBytes);
      expect(gstStr.contains('CENTRAL GOODS AND SERVICES TAX'), isTrue);
      expect(gstStr.contains('FORM GST REG-06'), isTrue);

      // 4. Aadhaar Card
      final aadhaarBytes = FileDownloadService.generateDocumentTypePdf(
        type: CpDocumentType.aadhaarCard,
        title: 'Aadhaar Card',
        documentNumber: 'XXXX-XXXX-9021',
        status: 'VERIFIED',
        partnerName: 'Vaishu',
        remarks: 'ID verified.',
      );
      final aadhaarStr = String.fromCharCodes(aadhaarBytes);
      expect(aadhaarStr.contains('UNIQUE IDENTIFICATION AUTHORITY OF INDIA'), isTrue);

      // 5. CP Agreement / MOU
      final mouBytes = FileDownloadService.generateDocumentTypePdf(
        type: CpDocumentType.cpAgreement,
        title: 'Channel Partner Agreement / MOU',
        documentNumber: 'MOU-78278',
        status: 'Under Review',
        partnerName: 'Vaishu',
        remarks: 'Pending signed agreement.',
      );
      final mouStr = String.fromCharCodes(mouBytes);
      expect(mouStr.contains('CHANNEL PARTNER EMPANELMENT AGREEMENT'), isTrue);
      expect(mouStr.contains('Key Covenant Summary'), isTrue);

      // 6. Bank Mandate / Cancelled Cheque
      final chequeBytes = FileDownloadService.generateDocumentTypePdf(
        type: CpDocumentType.cancelledCheque,
        title: 'Cancelled Cheque',
        documentNumber: 'CHQ-HDFC-0029',
        status: 'VERIFIED',
        partnerName: 'Vaishu',
        remarks: 'Account active.',
      );
      final chequeStr = String.fromCharCodes(chequeBytes);
      expect(chequeStr.contains('BANKING MANDATE'), isTrue);
      expect(chequeStr.contains('CANCELLED CHEQUE'), isTrue);

      // Verify each document type produces different content
      expect(reraBytes, isNot(equals(panBytes)));
      expect(panBytes, isNot(equals(gstBytes)));
      expect(gstBytes, isNot(equals(mouBytes)));
      expect(mouBytes, isNot(equals(chequeBytes)));
    });
  });

  group('ProjectDetailScreen Layout, Brochure Column & Removals Tests', () {
    testWidgets('ProjectDetailScreen removes Cost Estimator and Add Brochure, and provides Brochure column on same page', (tester) async {
      final state = AppState();
      final project = state.projects.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            state: state,
            project: project,
            initialSection: 'details',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Cost Estimator is completely removed from AppBar and body
      expect(find.byIcon(Icons.calculate_outlined), findsNothing);
      expect(find.byIcon(Icons.calculate), findsNothing);
      expect(find.text('Cost Estimator'), findsNothing);

      // 2. Verify + Add Brochure is completely removed from AppBar and body
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
      expect(find.text('+ Add Brochure'), findsNothing);

      // 3. Verify Project Image (Hero photo) is removed
      expect(find.byType(Image), findsNothing);

      // 4. Verify Project Details is initially active
      expect(find.text('Project Details'), findsOneWidget);
      expect(find.text('Brochure & Collateral'), findsOneWidget);
      expect(find.text('Unit Inventory & Pricing Matrix'), findsOneWidget);

      // 5. Tap Brochure & Collateral tab on the same page
      await tester.tap(find.text('Brochure & Collateral'));
      await tester.pumpAndSettle();

      // 6. Verify Brochure Column rendered on the same page
      expect(find.text('Project Brochure & Collateral'), findsOneWidget);
      expect(find.text('Share WhatsApp'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('RERA & Project Specifications'), findsOneWidget);
      expect(find.text('Marketing Assets & Collaterals'), findsOneWidget);
    });

    testWidgets('ProjectDetailScreen opens directly to Brochure column when initialSection is brochure', (tester) async {
      final state = AppState();
      final project = state.projects.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            state: state,
            project: project,
            initialSection: 'brochure',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify brochure column content is immediately visible on the same page
      expect(find.text('Project Brochure & Collateral'), findsOneWidget);
      expect(find.text('Share WhatsApp'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('RERA & Project Specifications'), findsOneWidget);

      // Switch back to details on the same page
      await tester.tap(find.text('Project Details'));
      await tester.pumpAndSettle();

      expect(find.text('Unit Inventory & Pricing Matrix'), findsOneWidget);
    });
  });
}
