class PickedDocumentData {
  final String fileName;
  final int sizeBytes;
  final String path;
  final List<int>? bytes;

  const PickedDocumentData({
    required this.fileName,
    required this.sizeBytes,
    required this.path,
    this.bytes,
  });
}
