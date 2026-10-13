import 'package:share_plus/share_plus.dart';

Future<void> downloadFileImpl({
  required String fileName,
  String? content,
  List<int>? bytes,
  String mimeType = 'application/pdf',
}) async {
  try {
    if (content != null && content.isNotEmpty) {
      await Share.share(content, subject: 'Download $fileName');
    }
  } catch (_) {}
}
