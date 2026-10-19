import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

Future<void> downloadFileImpl({
  required String fileName,
  String? content,
  List<int>? bytes,
  String mimeType = 'application/pdf',
}) async {
  try {
    final fileBytes = bytes ?? (content != null ? utf8.encode(content) : null);
    if (fileBytes != null && fileBytes.isNotEmpty) {
      final u8 = Uint8List.fromList(fileBytes);
      final xFile = XFile.fromData(
        u8,
        name: fileName,
        mimeType: mimeType,
      );
      await Share.shareXFiles(
        [xFile],
        subject: 'Download $fileName',
        text: 'Document: $fileName',
      );
    } else if (content != null && content.isNotEmpty) {
      await Share.share(content, subject: 'Download $fileName');
    }
  } catch (_) {}
}
