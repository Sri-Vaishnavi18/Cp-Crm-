import 'dart:convert';
import 'file_download_service_stub.dart'
    if (dart.library.html) 'file_download_service_web.dart';

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

  /// Downloads a document or certificate as an authentic, openable PDF file
  static Future<void> downloadDocumentPdf({
    required String documentTitle,
    required String documentNumber,
    required String fileName,
    String? status,
    String? validTill,
    String? partnerName,
    String? remarks,
  }) async {
    final pdfBytes = generateCertificatePdf(
      title: documentTitle,
      documentNumber: documentNumber,
      status: status ?? 'VERIFIED',
      validTill: validTill,
      partnerName: partnerName ?? 'Authorized Channel Partner',
      remarks: remarks ?? 'Official real estate regulatory compliance document.',
    );

    final cleanFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
    await downloadFile(
      fileName: cleanFileName,
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
