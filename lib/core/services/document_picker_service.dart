import 'package:image_picker/image_picker.dart';
import 'document_picker_stub.dart'
    if (dart.library.html) 'document_picker_web.dart';

class PickedDocument {
  final String path;
  final String fileName;
  final int sizeBytes;
  final List<int>? bytes;

  const PickedDocument({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
    this.bytes,
  });

  String get formattedSize {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    } else {
      return '$sizeBytes B';
    }
  }
}

class DocumentPickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick any document file (PDF, JPG, PNG) using native file dialog on Web or Mobile
  static Future<PickedDocument?> pickAnyDocument({
    String accept = '.pdf,.png,.jpg,.jpeg',
  }) async {
    try {
      final nativeDoc = await pickDocumentNativeImpl(accept: accept);
      if (nativeDoc != null) {
        return PickedDocument(
          path: nativeDoc.path,
          fileName: nativeDoc.fileName,
          sizeBytes: nativeDoc.sizeBytes,
          bytes: nativeDoc.bytes,
        );
      }
    } catch (_) {}

    // Fallback to gallery
    return pickDocumentFromGallery();
  }

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
      final bytes = await image.readAsBytes();
      return PickedDocument(
        path: image.path,
        fileName: image.name,
        sizeBytes: length,
        bytes: bytes,
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
      final bytes = await photo.readAsBytes();
      return PickedDocument(
        path: photo.path,
        fileName: photo.name,
        sizeBytes: length,
        bytes: bytes,
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
