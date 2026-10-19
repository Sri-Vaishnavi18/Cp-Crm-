// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

Future<void> downloadFileImpl({
  required String fileName,
  String? content,
  List<int>? bytes,
  String mimeType = 'application/pdf',
}) async {
  final fileBytes = bytes ?? (content != null ? utf8.encode(content) : <int>[]);
  final u8 = Uint8List.fromList(fileBytes);
  final blob = html.Blob([u8], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  // Delay revoking so the browser download engine can stream and write the file
  Future.delayed(const Duration(seconds: 5), () {
    try {
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  });
}
