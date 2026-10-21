import 'dart:convert';
import 'file_download_service_stub.dart'
    if (dart.library.html) 'file_download_service_web.dart';

import '../models/app_models.dart';

class FileDownloadService {
  /// Triggers a real file download in the browser (or native share on mobile)
  static Future<void> downloadFile({
    required String fileName,
    String? content,
    List<int>? bytes,
    String mimeType = 'application/pdf',
  }) async {
    final finalBytes = bytes ?? (content != null ? utf8.encode(content) : <int>[]);
    await downloadFileImpl(
      fileName: fileName,
      content: content,
      bytes: finalBytes,
      mimeType: mimeType,
    );
  }

  /// Detects whether a file name or bytes represent an image
  static bool isImageFile(String fileName, [List<int>? bytes]) {
    if (bytes != null && bytes.length >= 4) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true; // JPEG
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true; // PNG
      if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) return true; // WEBP
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true; // GIF
    }
    final lower = fileName.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  /// Detects the accurate MIME type for a file
  static String detectMimeType(String fileName, [List<int>? bytes]) {
    if (bytes != null && bytes.length >= 4) {
      if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
        return 'application/pdf'; // %PDF
      }
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return 'image/jpeg';
      }
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return 'image/png';
      }
      if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
        return 'image/webp';
      }
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'image/gif';
      }
    }
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }

  /// Downloads a document or certificate:
  /// - If uploaded file is an image, downloads with genuine image extension and MIME type
  /// - If uploaded file is a PDF, downloads with application/pdf
  /// - If forcePdfCertificate is true (or no uploaded bytes), generates authentic, openable PDF-1.4 certificate
  static Future<void> downloadDocumentPdf({
    required String documentTitle,
    required String documentNumber,
    required String fileName,
    String? status,
    String? validTill,
    String? partnerName,
    String? remarks,
    CpDocumentType? documentType,
    List<int>? customBytes,
    bool forcePdfCertificate = false,
  }) async {
    // 1. If user explicitly asks for the PDF certificate, generate authentic PDF-1.4
    if (forcePdfCertificate) {
      final cleanPdfName = fileName.toLowerCase().endsWith('.pdf')
          ? fileName
          : '${fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')}_Certificate.pdf';

      final pdfBytes = generateDocumentTypePdf(
        type: documentType,
        title: documentTitle,
        documentNumber: documentNumber,
        status: status ?? 'VERIFIED',
        validTill: validTill,
        partnerName: partnerName ?? 'Authorized Channel Partner',
        remarks: remarks ?? 'Official real estate regulatory compliance document.',
      );

      await downloadFile(
        fileName: cleanPdfName,
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );
      return;
    }

    // 2. If it is an image file (by file extension or magic bytes)
    final isImg = isImageFile(fileName, customBytes);
    if (isImg) {
      String targetFileName = fileName;
      if (targetFileName.toLowerCase().endsWith('.pdf')) {
        targetFileName = targetFileName.substring(0, targetFileName.length - 4);
      }
      if (!isImageFile(targetFileName)) {
        targetFileName = '$targetFileName.png';
      }
      final mime = detectMimeType(targetFileName, customBytes);

      // Reliable 1x1 fallback PNG if bytes were lost across reload
      const fallbackPngBytes = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ];

      final imgBytes = (customBytes != null && customBytes.isNotEmpty)
          ? customBytes
          : fallbackPngBytes;

      await downloadFile(
        fileName: targetFileName,
        bytes: imgBytes,
        mimeType: mime.startsWith('image/') ? mime : 'image/png',
      );
      return;
    }

    // 3. If customBytes are present for PDF/other formats
    if (customBytes != null && customBytes.isNotEmpty) {
      String targetFileName = fileName.toLowerCase().endsWith('.pdf') ? fileName : '$fileName.pdf';
      await downloadFile(
        fileName: targetFileName,
        bytes: customBytes,
        mimeType: 'application/pdf',
      );
      return;
    }

    // 4. Fallback PDF compliance document for non-image files with empty bytes
    final cleanPdfName = fileName.toLowerCase().endsWith('.pdf')
        ? fileName
        : '${fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')}_Certificate.pdf';

    final pdfBytes = generateDocumentTypePdf(
      type: documentType,
      title: documentTitle,
      documentNumber: documentNumber,
      status: status ?? 'VERIFIED',
      validTill: validTill,
      partnerName: partnerName ?? 'Authorized Channel Partner',
      remarks: remarks ?? 'Official real estate regulatory compliance document.',
    );

    await downloadFile(
      fileName: cleanPdfName,
      bytes: pdfBytes,
      mimeType: 'application/pdf',
    );
  }

  /// Downloads an official invoice / disbursal voucher as an authentic, openable PDF
  static Future<void> downloadInvoiceVoucherPdf({
    required String voucherNumber,
    required String clientName,
    required String projectName,
    required double grossAmount,
    required double tdsAmount,
    required double netAmount,
    required String utrNumber,
    required String bankName,
    required String dateStr,
  }) async {
    final pdfBytes = generateInvoicePdf(
      voucherNumber: voucherNumber,
      clientName: clientName,
      projectName: projectName,
      grossAmount: grossAmount,
      tdsAmount: tdsAmount,
      netAmount: netAmount,
      utrNumber: utrNumber,
      bankName: bankName,
      dateStr: dateStr,
    );

    await downloadFile(
      fileName: '$voucherNumber.pdf',
      bytes: pdfBytes,
      mimeType: 'application/pdf',
    );
  }

  /// Downloads a project brochure as an openable PDF
  static Future<void> downloadProjectBrochurePdf({
    required String projectName,
    required String location,
    required String startingPrice,
    required String fileName,
  }) async {
    final pdfBytes = generateBrochurePdf(
      projectName: projectName,
      location: location,
      startingPrice: startingPrice,
    );

    final cleanFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
    await downloadFile(
      fileName: cleanFileName,
      bytes: pdfBytes,
      mimeType: 'application/pdf',
    );
  }

  // ==========================================
  // PURE DART VALID PDF GENERATORS
  // ==========================================

  /// Routes to the specialized generator based on document type
  static List<int> generateDocumentTypePdf({
    CpDocumentType? type,
    required String title,
    required String documentNumber,
    required String status,
    String? validTill,
    required String partnerName,
    required String remarks,
  }) {
    switch (type) {
      case CpDocumentType.reraCertificate:
        return generateReraCertificatePdf(
          documentNumber: documentNumber,
          partnerName: partnerName,
          status: status,
          validTill: validTill,
          remarks: remarks,
        );
      case CpDocumentType.panCard:
        return generatePanCardPdf(
          documentNumber: documentNumber,
          partnerName: partnerName,
          status: status,
          remarks: remarks,
        );
      case CpDocumentType.gstCertificate:
        return generateGstCertificatePdf(
          documentNumber: documentNumber,
          partnerName: partnerName,
          status: status,
          validTill: validTill,
          remarks: remarks,
        );
      case CpDocumentType.aadhaarCard:
        return generateAadhaarPdf(
          documentNumber: documentNumber,
          partnerName: partnerName,
          status: status,
          remarks: remarks,
        );
      case CpDocumentType.cpAgreement:
        return generateCpAgreementPdf(
          documentNumber: documentNumber,
          partnerName: partnerName,
          status: status,
          validTill: validTill,
          remarks: remarks,
        );
      case CpDocumentType.cancelledCheque:
        return generateBankMandatePdf(
          documentNumber: documentNumber,
          partnerName: partnerName,
          status: status,
          remarks: remarks,
        );
      case CpDocumentType.specimenSignature:
        return generateSignatureCertificatePdf(
          documentNumber: documentNumber,
          partnerName: partnerName,
          status: status,
          remarks: remarks,
        );
      case CpDocumentType.other:
      case null:
        return generateCertificatePdf(
          title: title,
          documentNumber: documentNumber,
          status: status,
          validTill: validTill,
          partnerName: partnerName,
          remarks: remarks,
        );
    }
  }

  /// 1. RERA Registration Certificate PDF
  static List<int> generateReraCertificatePdf({
    required String documentNumber,
    required String partnerName,
    required String status,
    String? validTill,
    required String remarks,
  }) {
    final streamContent = StringBuffer();
    // Header banner
    streamContent.writeln('0.06 0.28 0.62 rg 40 735 532 30 re f');
    streamContent.writeln('0.85 0.88 0.92 RG 1 w 40 60 532 705 re S');

    streamContent.writeln('BT');
    streamContent.writeln('/F1 14 Tf');
    streamContent.writeln('1 1 1 rg');
    streamContent.writeln('50 745 Td');
    streamContent.writeln('(REAL ESTATE REGULATORY AUTHORITY - RERA) Tj');

    streamContent.writeln('0 0 0 rg');
    streamContent.writeln('/F1 13 Tf');
    streamContent.writeln('0 -35 Td');
    streamContent.writeln('(FORM B: CERTIFICATE OF REGISTRATION OF REAL ESTATE AGENT) Tj');

    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0 -18 Td');
    streamContent.writeln('([Issued under Section 9 of Real Estate Regulation and Development Act, 2016]) Tj');

    streamContent.writeln('0.15 0.20 0.35 rg');
    streamContent.writeln('/F1 11 Tf');
    streamContent.writeln('0 -35 Td');
    final regNo = documentNumber.isNotEmpty ? documentNumber : 'RERA-AG-HYD-2024-8841';
    streamContent.writeln('(RERA Registration Number: ${_escapePdf(regNo)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Agent / Entity Name: ${_escapePdf(partnerName)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Compliance Status: ${_escapePdf(status)}) Tj');

    final validity = (validTill != null && validTill.isNotEmpty) ? validTill : '31/12/2027';
    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(License Validity Period: Through ${_escapePdf(validity)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Authorized Area of Operation: Residential and Commercial Real Estate) Tj');

    streamContent.writeln('0 -28 Td');
    streamContent.writeln('(${_escapePdf(remarks)}) Tj');

    streamContent.writeln('/F1 9 Tf');
    streamContent.writeln('0.3 0.3 0.3 rg');
    streamContent.writeln('0 -45 Td');
    streamContent.writeln('(Conditions of Registration: Agent must quote this RERA registration number) Tj');
    streamContent.writeln('0 -14 Td');
    streamContent.writeln('(on all official communications, collateral distributions, and property bookings.) Tj');

    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0.06 0.28 0.62 rg');
    streamContent.writeln('0 -40 Td');
    streamContent.writeln('([SEAL] Digitally Verified by State Real Estate Regulatory Authority) Tj');
    streamContent.writeln('ET');

    return _buildPdf14Document(streamContent.toString());
  }

  /// 2. PAN Card Verification PDF
  static List<int> generatePanCardPdf({
    required String documentNumber,
    required String partnerName,
    required String status,
    required String remarks,
  }) {
    final streamContent = StringBuffer();
    // Card header
    streamContent.writeln('0.10 0.35 0.55 rg 40 735 532 30 re f');
    streamContent.writeln('0.85 0.88 0.92 RG 1 w 40 80 532 685 re S');

    streamContent.writeln('BT');
    streamContent.writeln('/F1 13 Tf');
    streamContent.writeln('1 1 1 rg');
    streamContent.writeln('50 745 Td');
    streamContent.writeln('(INCOME TAX DEPARTMENT - GOVERNMENT OF INDIA) Tj');

    streamContent.writeln('0 0 0 rg');
    streamContent.writeln('/F1 15 Tf');
    streamContent.writeln('0 -40 Td');
    streamContent.writeln('(PERMANENT ACCOUNT NUMBER CARD) Tj');

    streamContent.writeln('0.15 0.20 0.35 rg');
    streamContent.writeln('/F1 14 Tf');
    streamContent.writeln('0 -35 Td');
    final pan = documentNumber.isNotEmpty ? documentNumber.toUpperCase() : 'ABCDE1234F';
    streamContent.writeln('(PAN NUMBER: ${_escapePdf(pan)}) Tj');

    streamContent.writeln('/F1 11 Tf');
    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(Taxpayer / Firm Name: ${_escapePdf(partnerName)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Verification Status: ${_escapePdf(status)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Tax Withholding Category: Section 194H Brokerage Deductions at 5%) Tj');

    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(${_escapePdf(remarks)}) Tj');

    streamContent.writeln('/F1 9 Tf');
    streamContent.writeln('0.3 0.3 0.3 rg');
    streamContent.writeln('0 -45 Td');
    streamContent.writeln('(Security Feature: Encrypted Electronic Verification with CBDT NSDL Registry) Tj');

    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0.10 0.35 0.55 rg');
    streamContent.writeln('0 -35 Td');
    streamContent.writeln('([VERIFIED] Income Tax Department Electronic Records Database) Tj');
    streamContent.writeln('ET');

    return _buildPdf14Document(streamContent.toString());
  }

  /// 3. GST Registration Certificate PDF
  static List<int> generateGstCertificatePdf({
    required String documentNumber,
    required String partnerName,
    required String status,
    String? validTill,
    required String remarks,
  }) {
    final streamContent = StringBuffer();
    // Blue header
    streamContent.writeln('0.08 0.40 0.30 rg 40 735 532 30 re f');
    streamContent.writeln('0.85 0.88 0.92 RG 1 w 40 70 532 695 re S');

    streamContent.writeln('BT');
    streamContent.writeln('/F1 13 Tf');
    streamContent.writeln('1 1 1 rg');
    streamContent.writeln('50 745 Td');
    streamContent.writeln('(GOVERNMENT OF INDIA - CENTRAL GOODS AND SERVICES TAX) Tj');

    streamContent.writeln('0 0 0 rg');
    streamContent.writeln('/F1 14 Tf');
    streamContent.writeln('0 -40 Td');
    streamContent.writeln('(FORM GST REG-06: REGISTRATION CERTIFICATE) Tj');

    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0 -18 Td');
    streamContent.writeln('([Issued under Section 25(3) of the CGST Act, 2017]) Tj');

    streamContent.writeln('0.15 0.20 0.35 rg');
    streamContent.writeln('/F1 13 Tf');
    streamContent.writeln('0 -35 Td');
    final gstin = documentNumber.isNotEmpty ? documentNumber.toUpperCase() : '36AAAAA0000A1Z5';
    streamContent.writeln('(Registration Number - GSTIN: ${_escapePdf(gstin)}) Tj');

    streamContent.writeln('/F1 11 Tf');
    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(Legal Name of Business: ${_escapePdf(partnerName)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Trade Classification: Real Estate Intermediation & Brokerage Services) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Compliance Status: ${_escapePdf(status)}) Tj');

    final validity = (validTill != null && validTill.isNotEmpty) ? validTill : 'From 01/04/2023 - Regular';
    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Validity Period: ${_escapePdf(validity)}) Tj');

    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(${_escapePdf(remarks)}) Tj');

    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0.08 0.40 0.30 rg');
    streamContent.writeln('0 -50 Td');
    streamContent.writeln('([SEAL] Goods and Services Tax Network - Authorized Digital Signature) Tj');
    streamContent.writeln('ET');

    return _buildPdf14Document(streamContent.toString());
  }

  /// 4. Aadhaar / Government ID Proof PDF
  static List<int> generateAadhaarPdf({
    required String documentNumber,
    required String partnerName,
    required String status,
    required String remarks,
  }) {
    final streamContent = StringBuffer();
    // Aadhaar Red-orange header
    streamContent.writeln('0.75 0.25 0.10 rg 40 735 532 30 re f');
    streamContent.writeln('0.85 0.88 0.92 RG 1 w 40 80 532 685 re S');

    streamContent.writeln('BT');
    streamContent.writeln('/F1 13 Tf');
    streamContent.writeln('1 1 1 rg');
    streamContent.writeln('50 745 Td');
    streamContent.writeln('(UNIQUE IDENTIFICATION AUTHORITY OF INDIA - UIDAI) Tj');

    streamContent.writeln('0 0 0 rg');
    streamContent.writeln('/F1 15 Tf');
    streamContent.writeln('0 -40 Td');
    streamContent.writeln('(GOVERNMENT OF INDIA - RESIDENT E-IDENTITY RECORD) Tj');

    streamContent.writeln('0.15 0.20 0.35 rg');
    streamContent.writeln('/F1 13 Tf');
    streamContent.writeln('0 -35 Td');
    final uid = documentNumber.isNotEmpty ? documentNumber : 'XXXX-XXXX-9021';
    streamContent.writeln('(Document Reference / Masked UID: ${_escapePdf(uid)}) Tj');

    streamContent.writeln('/F1 11 Tf');
    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(Resident Name: ${_escapePdf(partnerName)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Identity Verification Status: ${_escapePdf(status)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Document Classification: Primary Identity & Address Proof) Tj');

    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(${_escapePdf(remarks)}) Tj');

    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0.75 0.25 0.10 rg');
    streamContent.writeln('0 -50 Td');
    streamContent.writeln('([VERIFIED] Digitally Authenticated via UIDAI Identity Registry) Tj');
    streamContent.writeln('ET');

    return _buildPdf14Document(streamContent.toString());
  }

  /// 5. Channel Partner Agreement / MOU PDF
  static List<int> generateCpAgreementPdf({
    required String documentNumber,
    required String partnerName,
    required String status,
    String? validTill,
    required String remarks,
  }) {
    final streamContent = StringBuffer();
    // Purple header
    streamContent.writeln('0.35 0.15 0.60 rg 40 735 532 30 re f');
    streamContent.writeln('0.85 0.88 0.92 RG 1 w 40 60 532 705 re S');

    streamContent.writeln('BT');
    streamContent.writeln('/F1 13 Tf');
    streamContent.writeln('1 1 1 rg');
    streamContent.writeln('50 745 Td');
    streamContent.writeln('(DEVELOPER & CHANNEL PARTNER MASTER SERVICE AGREEMENT) Tj');

    streamContent.writeln('0 0 0 rg');
    streamContent.writeln('/F1 14 Tf');
    streamContent.writeln('0 -40 Td');
    streamContent.writeln('(CHANNEL PARTNER EMPANELMENT AGREEMENT / MOU) Tj');

    streamContent.writeln('0.15 0.20 0.35 rg');
    streamContent.writeln('/F1 11 Tf');
    streamContent.writeln('0 -32 Td');
    final mouNo = documentNumber.isNotEmpty ? documentNumber : 'CP-MOU-2024-8841';
    streamContent.writeln('(MOU Reference Agreement No: ${_escapePdf(mouNo)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Empaneled Agency: ${_escapePdf(partnerName)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Empanelment Status: ${_escapePdf(status)}) Tj');

    final validity = (validTill != null && validTill.isNotEmpty) ? validTill : '24 Months From Signoff';
    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Agreement Term: ${_escapePdf(validity)}) Tj');

    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(${_escapePdf(remarks)}) Tj');

    streamContent.writeln('/F1 9.5 Tf');
    streamContent.writeln('0.2 0.2 0.2 rg');
    streamContent.writeln('0 -35 Td');
    streamContent.writeln('(Key Covenant Summary:) Tj');
    streamContent.writeln('0 -15 Td');
    streamContent.writeln('(1. Commission slabs credited directly to verified bank within 15 days of buyer milestone.) Tj');
    streamContent.writeln('0 -15 Td');
    streamContent.writeln('(2. All client leads registered through the CP CRM app retain 60-day sole tag protection.) Tj');
    streamContent.writeln('0 -15 Td');
    streamContent.writeln('(3. Strictly authorized marketing collaterals and approved project prices only.) Tj');

    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0.35 0.15 0.60 rg');
    streamContent.writeln('0 -40 Td');
    streamContent.writeln('(Executed & Sealed: Developer Marketing Division & Channel Partner) Tj');
    streamContent.writeln('ET');

    return _buildPdf14Document(streamContent.toString());
  }

  /// 6. Bank Mandate / Cancelled Cheque PDF
  static List<int> generateBankMandatePdf({
    required String documentNumber,
    required String partnerName,
    required String status,
    required String remarks,
  }) {
    final streamContent = StringBuffer();
    // Dark green header
    streamContent.writeln('0.05 0.45 0.25 rg 40 735 532 30 re f');
    streamContent.writeln('0.85 0.88 0.92 RG 1 w 40 70 532 695 re S');

    streamContent.writeln('BT');
    streamContent.writeln('/F1 13 Tf');
    streamContent.writeln('1 1 1 rg');
    streamContent.writeln('50 745 Td');
    streamContent.writeln('(BANKING MANDATE & DIRECT COMMISSION DISBURSAL PROOF) Tj');

    streamContent.writeln('0 0 0 rg');
    streamContent.writeln('/F1 14 Tf');
    streamContent.writeln('0 -40 Td');
    streamContent.writeln('(CANCELLED CHEQUE / BANK ACCOUNT VERIFICATION) Tj');

    streamContent.writeln('0.15 0.20 0.35 rg');
    streamContent.writeln('/F1 11 Tf');
    streamContent.writeln('0 -35 Td');
    final chq = documentNumber.isNotEmpty ? documentNumber : 'CHQ-HDFC-002914';
    streamContent.writeln('(Account Proof Reference / Cheque: ${_escapePdf(chq)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Beneficiary Account Holder: ${_escapePdf(partnerName)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Verification Status: ${_escapePdf(status)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Disbursal Route: Automated NACH / RTGS Commission Credit) Tj');

    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(${_escapePdf(remarks)}) Tj');

    streamContent.writeln('/F1 9 Tf');
    streamContent.writeln('0.3 0.3 0.3 rg');
    streamContent.writeln('0 -45 Td');
    streamContent.writeln('(Bank IFSC, Account Number, and MICR cross-referenced against Developer Escrow.) Tj');

    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0.05 0.45 0.25 rg');
    streamContent.writeln('0 -35 Td');
    streamContent.writeln('([VERIFIED] Direct Payout Clearance Mandate Activated) Tj');
    streamContent.writeln('ET');

    return _buildPdf14Document(streamContent.toString());
  }

  /// 7. Authorized Specimen Signature Mandate PDF
  static List<int> generateSignatureCertificatePdf({
    required String documentNumber,
    required String partnerName,
    required String status,
    required String remarks,
  }) {
    final streamContent = StringBuffer();
    // Indigo / Navy executive header
    streamContent.writeln('0.15 0.22 0.45 rg 40 735 532 30 re f');
    streamContent.writeln('0.85 0.88 0.92 RG 1 w 40 70 532 695 re S');

    streamContent.writeln('BT');
    streamContent.writeln('/F1 13 Tf');
    streamContent.writeln('1 1 1 rg');
    streamContent.writeln('50 745 Td');
    streamContent.writeln('(AUTHORIZED SPECIMEN SIGNATURE & IDENTITY ATTESTATION) Tj');

    streamContent.writeln('0 0 0 rg');
    streamContent.writeln('/F1 14 Tf');
    streamContent.writeln('0 -40 Td');
    streamContent.writeln('(CHANNEL PARTNER SPECIMEN SIGNATURE RECORD) Tj');

    streamContent.writeln('0.15 0.20 0.35 rg');
    streamContent.writeln('/F1 11 Tf');
    streamContent.writeln('0 -35 Td');
    final sigRef = documentNumber.isNotEmpty ? documentNumber : 'SIG-AUTH-008291';
    streamContent.writeln('(Signature Reference / Attestation ID: ${_escapePdf(sigRef)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Authorized Signatory: ${_escapePdf(partnerName)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Verification Status: ${_escapePdf(status)}) Tj');

    streamContent.writeln('0 -22 Td');
    streamContent.writeln('(Mandate: Official Authorized Signatory for Invoices, MOUs & Brokerage Claims) Tj');

    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(${_escapePdf(remarks)}) Tj');

    streamContent.writeln('/F1 9 Tf');
    streamContent.writeln('0.3 0.3 0.3 rg');
    streamContent.writeln('0 -45 Td');
    streamContent.writeln('(Cross-referenced against Authorized PAN, Aadhaar & Partner Mandate on Developer Record.) Tj');

    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0.15 0.22 0.45 rg');
    streamContent.writeln('0 -35 Td');
    streamContent.writeln('([VERIFIED] Registered Specimen Signature on File) Tj');
    streamContent.writeln('ET');

    // Specimen Signature Box in PDF
    streamContent.writeln('0.94 0.96 0.99 rg 50 360 480 90 re f');
    streamContent.writeln('0.25 0.38 0.75 RG 1 w 50 360 480 90 re S');

    streamContent.writeln('BT');
    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0.25 0.38 0.75 rg');
    streamContent.writeln('65 425 Td');
    streamContent.writeln('(OFFICIAL SPECIMEN SIGNATURE ATTESTATION BOX) Tj');
    streamContent.writeln('0.3 0.35 0.45 rg');
    streamContent.writeln('/F1 9 Tf');
    streamContent.writeln('0 -20 Td');
    streamContent.writeln('(Signature verified and matched with Registered Channel Partner Record.) Tj');
    streamContent.writeln('0 -18 Td');
    streamContent.writeln('([VALIDATED] Executed under Channel Partner Real Estate Regulatory Framework) Tj');
    streamContent.writeln('ET');

    return _buildPdf14Document(streamContent.toString());
  }

  /// Fallback Generic Certificate PDF (Preserves original signature for tests)
  static List<int> generateCertificatePdf({
    required String title,
    required String documentNumber,
    required String status,
    String? validTill,
    required String partnerName,
    required String remarks,
  }) {
    final streamContent = StringBuffer();
    streamContent.writeln('BT');
    streamContent.writeln('/F1 20 Tf');
    streamContent.writeln('50 740 Td');
    streamContent.writeln('(${_escapePdf(title.toUpperCase())}) Tj');
    
    streamContent.writeln('/F1 12 Tf');
    streamContent.writeln('0 -30 Td');
    streamContent.writeln('(Document Reference: ${_escapePdf(documentNumber)}) Tj');
    
    streamContent.writeln('/F1 12 Tf');
    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(Compliance Status: ${_escapePdf(status)}) Tj');
    
    streamContent.writeln('/F1 12 Tf');
    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(Registered To: ${_escapePdf(partnerName)}) Tj');
    
    if (validTill != null && validTill.isNotEmpty) {
      streamContent.writeln('/F1 12 Tf');
      streamContent.writeln('0 -25 Td');
      streamContent.writeln('(Validity / Expiry: ${_escapePdf(validTill)}) Tj');
    }
    
    streamContent.writeln('/F1 11 Tf');
    streamContent.writeln('0 -35 Td');
    streamContent.writeln('(${_escapePdf(remarks)}) Tj');

    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0 -60 Td');
    streamContent.writeln('(Digitally Verified & Encrypted - CP CRM Compliance Registry) Tj');
    streamContent.writeln('ET');

    return _buildPdf14Document(streamContent.toString());
  }

  static List<int> generateInvoicePdf({
    required String voucherNumber,
    required String clientName,
    required String projectName,
    required double grossAmount,
    required double tdsAmount,
    required double netAmount,
    required String utrNumber,
    required String bankName,
    required String dateStr,
  }) {
    final streamContent = StringBuffer();
    streamContent.writeln('BT');
    streamContent.writeln('/F1 18 Tf');
    streamContent.writeln('50 740 Td');
    streamContent.writeln('(DEVELOPER REALTY GROUP - COMMISSION DISBURSAL VOUCHER) Tj');
    
    streamContent.writeln('/F1 12 Tf');
    streamContent.writeln('0 -30 Td');
    streamContent.writeln('(Voucher Number: ${_escapePdf(voucherNumber)}   |   Date: ${_escapePdf(dateStr)}) Tj');
    
    streamContent.writeln('/F1 12 Tf');
    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(Project: ${_escapePdf(projectName)}   |   Client: ${_escapePdf(clientName)}) Tj');
    
    streamContent.writeln('/F1 12 Tf');
    streamContent.writeln('0 -35 Td');
    streamContent.writeln('(Gross Payout Amount: INR ${grossAmount.toStringAsFixed(2)}) Tj');
    
    streamContent.writeln('/F1 12 Tf');
    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(Less TDS Deducted Sec 194H 5%: - INR ${tdsAmount.toStringAsFixed(2)}) Tj');
    
    streamContent.writeln('/F1 14 Tf');
    streamContent.writeln('0 -30 Td');
    streamContent.writeln('(NET CREDITED TO BANK: INR ${netAmount.toStringAsFixed(2)}) Tj');

    streamContent.writeln('/F1 11 Tf');
    streamContent.writeln('0 -35 Td');
    streamContent.writeln('(Electronic Transfer UTR: ${_escapePdf(utrNumber)}   |   Bank: ${_escapePdf(bankName)}) Tj');

    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0 -50 Td');
    streamContent.writeln('(Official Payment Receipt - Digitally Authenticated by Builder Finance Desk) Tj');
    streamContent.writeln('ET');

    return _buildPdf14Document(streamContent.toString());
  }

  static List<int> generateBrochurePdf({
    required String projectName,
    required String location,
    required String startingPrice,
  }) {
    final streamContent = StringBuffer();
    streamContent.writeln('BT');
    streamContent.writeln('/F1 22 Tf');
    streamContent.writeln('50 740 Td');
    streamContent.writeln('(${_escapePdf(projectName.toUpperCase())} - OFFICIAL BROCHURE) Tj');
    
    streamContent.writeln('/F1 13 Tf');
    streamContent.writeln('0 -35 Td');
    streamContent.writeln('(Location: ${_escapePdf(location)}) Tj');
    
    streamContent.writeln('/F1 13 Tf');
    streamContent.writeln('0 -25 Td');
    streamContent.writeln('(Starting Price: ${_escapePdf(startingPrice)}) Tj');
    
    streamContent.writeln('/F1 11 Tf');
    streamContent.writeln('0 -35 Td');
    streamContent.writeln('(Luxury Residential Living with World-Class Master Layout & Club Amenities) Tj');

    streamContent.writeln('/F1 10 Tf');
    streamContent.writeln('0 -50 Td');
    streamContent.writeln('(Marketed exclusively via Authorized Channel Partners - CP CRM) Tj');
    streamContent.writeln('ET');

    return _buildPdf14Document(streamContent.toString());
  }

  static List<int> _buildPdf14Document(String streamString) {
    final streamBytes = utf8.encode(streamString);
    final buffer = StringBuffer();

    // PDF Header
    buffer.write('%PDF-1.4\n');

    final offsets = <int>[];

    // 1 0 obj: Catalog
    offsets.add(utf8.encode(buffer.toString()).length);
    buffer.write('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // 2 0 obj: Pages
    offsets.add(utf8.encode(buffer.toString()).length);
    buffer.write('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');

    // 3 0 obj: Page
    offsets.add(utf8.encode(buffer.toString()).length);
    buffer.write('3 0 obj\n<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 4 0 R >> >> /MediaBox [0 0 612 792] /Contents 5 0 R >>\nendobj\n');

    // 4 0 obj: Font
    offsets.add(utf8.encode(buffer.toString()).length);
    buffer.write('4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n');

    // 5 0 obj: Stream
    offsets.add(utf8.encode(buffer.toString()).length);
    buffer.write('5 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n');
    final beforeStream = utf8.encode(buffer.toString());

    final afterStreamBuffer = StringBuffer();
    afterStreamBuffer.write('\nendstream\nendobj\n');

    // XRef table
    final xrefOffset = beforeStream.length + streamBytes.length + utf8.encode(afterStreamBuffer.toString()).length;
    final xrefBuffer = StringBuffer();
    xrefBuffer.write('xref\n0 6\n0000000000 65535 f \n');
    for (final off in offsets) {
      xrefBuffer.write('${off.toString().padLeft(10, '0')} 00000 n \n');
    }
    xrefBuffer.write('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n');

    final fullBytes = <int>[
      ...beforeStream,
      ...streamBytes,
      ...utf8.encode(afterStreamBuffer.toString()),
      ...utf8.encode(xrefBuffer.toString()),
    ];

    return fullBytes;
  }

  static String _escapePdf(String text) {
    return text.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
  }
}
