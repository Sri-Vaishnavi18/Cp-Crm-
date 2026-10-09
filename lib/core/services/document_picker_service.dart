import 'package:image_picker/image_picker.dart';

class PickedDocument {
  final String path;
  final String fileName;
  final int sizeBytes;

  const PickedDocument({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
  });
}

class DocumentPickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick a document/image from device gallery
  static Future<PickedDocument?> pickDocumentFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null) return null;
      final length = await image.length();
      return PickedDocument(
        path: image.path,
        fileName: image.name,
        sizeBytes: length,
      );
    } catch (_) {
      return null;
    }
  }

  /// Capture a document/slip using the device camera
  static Future<PickedDocument?> pickDocumentFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photo == null) return null;
      final length = await photo.length();
      return PickedDocument(
        path: photo.path,
        fileName: photo.name,
        sizeBytes: length,
      );
    } catch (_) {
      return null;
    }
  }

  /// Convenience methods returning raw path
  static Future<String?> pickImageFromGallery() async {
    final doc = await pickDocumentFromGallery();
    return doc?.path;
  }

  static Future<String?> captureImageFromCamera() async {
    final doc = await pickDocumentFromCamera();
    return doc?.path;
  }
}
