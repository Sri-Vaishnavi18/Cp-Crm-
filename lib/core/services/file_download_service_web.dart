// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';

Future<void> downloadFileImpl({
  required String fileName,
  String? content,
  List<int>? bytes,
  String mimeType = 'application/pdf',
}) async {
  final fileBytes = bytes ?? (content != null ? utf8.encode(content) : <int>[]);
  final blob = html.Blob([fileBytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
