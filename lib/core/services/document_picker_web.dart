// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
import 'picked_document_data.dart';

Future<PickedDocumentData?> pickDocumentNativeImpl({
  String accept = '.pdf,.png,.jpg,.jpeg',
}) async {
  final completer = Completer<PickedDocumentData?>();
  final uploadInput = html.FileUploadInputElement()..accept = accept;
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        List<int> bytes = [];
        if (result is ByteBuffer) {
          bytes = Uint8List.view(result);
        } else if (result is Uint8List) {
          bytes = result;
        } else if (result is List<int>) {
          bytes = result;
        }
        completer.complete(
          PickedDocumentData(
            fileName: file.name,
            sizeBytes: file.size,
            path: file.name,
            bytes: bytes,
          ),
        );
      });
      reader.onError.listen((_) {
        completer.complete(null);
      });
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}
