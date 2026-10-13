import 'package:image_picker/image_picker.dart';
import 'picked_document_data.dart';

Future<PickedDocumentData?> pickDocumentNativeImpl({
  String accept = '.pdf,.png,.jpg,.jpeg',
}) async {
  try {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final length = await file.length();
    final bytes = await file.readAsBytes();
    return PickedDocumentData(
      fileName: file.name,
      sizeBytes: length,
      path: file.path,
      bytes: bytes,
    );
  } catch (_) {
    return null;
  }
}
