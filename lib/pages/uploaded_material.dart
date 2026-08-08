class UploadedMaterial {
  final String title;
  final String subject;
  final String fileName;
  final String filePath;
  final String? fileUrl;
  final String? type;
  final int? fileId;
  final List<int>? fileBytes;
  final String? fileContent;

  UploadedMaterial({
    required this.title,
    required this.subject,
    required this.fileName,
    required this.filePath,
    this.fileUrl,
    this.type,
    this.fileId,
    this.fileBytes,
    this.fileContent,
  });
}

