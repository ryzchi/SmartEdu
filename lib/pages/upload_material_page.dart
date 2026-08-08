import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'material_service.dart';
import 'uploaded_material.dart';

class UploadMaterialPage extends StatefulWidget {
  final String? preselectedSubject;
  const UploadMaterialPage({super.key, this.preselectedSubject});

  @override
  State<UploadMaterialPage> createState() => _UploadMaterialPageState();
}

class _UploadMaterialPageState extends State<UploadMaterialPage> {
  File? selectedFile;
  String? selectedFileName;
  List<int>? selectedFileBytes;

  late TextEditingController _titleController;
  late TextEditingController _subjectController;

  bool _isLoading = false;
  bool _isDragging = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _subjectController = TextEditingController(
      text: widget.preselectedSubject ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _handleDroppedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final fileName = filePath.split('/').last;
        final fileBytes = await file.readAsBytes();
        setState(() {
          selectedFile = file;
          selectedFileName = fileName;
          selectedFileBytes = fileBytes;
          _isDragging = false;
        });
      }
    } catch (e) {
      print('Error handling dropped file: $e');
      setState(() => _isDragging = false);
    }
  }

  String _getFileExtension() {
    if (selectedFileName == null) return '';
    final parts = selectedFileName!.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : '';
  }

  IconData _getFileIcon() {
    final ext = _getFileExtension().toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.video_library;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor() {
    final ext = _getFileExtension().toLowerCase();
    switch (ext) {
      case 'pdf':
        return const Color(0xFFD85A30);
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Colors.red;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _getShortMimeType() {
    final ext = _getFileExtension().toLowerCase();
    switch (ext) {
      case 'pdf': return 'PDF';
      case 'doc': return 'DOC';
      case 'docx': return 'DOCX';
      case 'xls': return 'XLS';
      case 'xlsx': return 'XLSX';
      case 'ppt': return 'PPT';
      case 'pptx': return 'PPTX';
      case 'jpg':
      case 'jpeg': return 'JPEG';
      case 'png': return 'PNG';
      case 'mp4': return 'MP4';
      case 'mp3': return 'MP3';
      default: return ext.toUpperCase();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int index = 0;
    double size = bytes.toDouble();
    while (size > 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[index]}';
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'docx',
          'doc',
          'ppt',
          'pptx',
          'jpg',
          'jpeg',
          'png',
          'gif',
          'mp4',
          'avi',
          'mov',
          'xls',
          'xlsx',
        ],
      );
      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        if (picked.bytes != null) {
          _handleFilePicked(picked);
        } else {
          if (mounted) {
            setState(
              () => _errorMessage = 'Failed to read file. Please try again.',
            );
          }
        }
      }
    } catch (e) {
      print('File picker error: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Error: ${e.toString()}');
      }
    }
  }

  void _handleFilePicked(PlatformFile picked) {
    try {
      setState(() {
        selectedFileName = picked.name;
        selectedFileBytes = picked.bytes;
        if (!kIsWeb && picked.path != null) {
          selectedFile = File(picked.path!);
        } else {
          selectedFile = null;
        }
        _isDragging = false;
      });
    } catch (e) {
      print('Error handling picked file: $e');
      setState(() => _errorMessage = 'Error selecting file: $e');
    }
  }

  Future<void> upload() async {
    if (selectedFileName == null) {
      setState(() => _errorMessage = 'Please select a file.');
      return;
    }
    if (_titleController.text.trim().isEmpty ||
        _subjectController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter title and subject.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final materialService = MaterialService();
      final extension = selectedFileName!.contains('.')
          ? selectedFileName!.split('.').last.toUpperCase()
          : 'FILE';

      final response = await materialService.uploadMaterial(
        file: selectedFile,
        fileBytes: selectedFileBytes,
        fileName: selectedFileName,
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        type: extension,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final fileUrl = response['file_url'] ?? '';

        final uploadedMaterial = UploadedMaterial(
          title: _titleController.text.trim(),
          subject: _subjectController.text.trim(),
          fileName: selectedFileName!,
          filePath: selectedFile?.path ?? '',
          fileUrl: fileUrl,
          type: extension,
          fileId: response['id'] as int?,
          fileBytes: selectedFileBytes,
          fileContent: null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );
        Navigator.pop(context, uploadedMaterial);
      } else {
        setState(
          () => _errorMessage =
              response['message'] ?? 'Upload failed. Try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return Container(
    width: 580,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== HEADER with X button =====
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0d2b5c), Color(0xFF1a5276)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Learning Material',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Share educational resources with your students',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ X / Close button (gaya ng Submit Assignment)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ===== MATERIAL DETAILS =====
        const Text(
          'Material Details',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0d2b5c),
          ),
        ),
        const SizedBox(height: 12),

        // Title Field
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Material Title',
              hintText: 'e.g., Quadratic Equations',
              prefixIcon: Icon(
                Icons.title,
                color: Color(0xFF0d2b5c),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              labelStyle: TextStyle(fontSize: 13),
              hintStyle: TextStyle(fontSize: 14),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),

        // Subject Field
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject/Course',
              hintText: 'e.g., Mathematics',
              prefixIcon: Icon(
                Icons.school,
                color: Color(0xFF0d2b5c),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              labelStyle: TextStyle(fontSize: 13),
              hintStyle: TextStyle(fontSize: 14),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 20),

        // ===== FILE SELECTION =====
        const Text(
          'Select File',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0d2b5c),
          ),
        ),
        const SizedBox(height: 12),

        // Drag and Drop File Selection Card
        GestureDetector(
          onTap: pickFile,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isDragging
                    ? const Color(0xFF0d2b5c)
                    : (selectedFileName != null
                        ? const Color(0xFF0d2b5c)
                        : Colors.grey.shade300),
                width: _isDragging ? 3 : 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _isDragging
                  ? const Color(0xFF0d2b5c).withOpacity(0.1)
                  : (selectedFileName != null
                      ? const Color(0xFF0d2b5c).withOpacity(0.03)
                      : Colors.grey.shade50),
            ),
            child: Center(
              child: selectedFileName == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isDragging
                              ? Icons.cloud_download_outlined
                              : Icons.cloud_upload_outlined,
                          size: 44,
                          color: _isDragging
                              ? const Color(0xFF0d2b5c)
                              : const Color(0xFF0d2b5c).withOpacity(0.6),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isDragging
                              ? 'Drop file here'
                              : 'Drag & Drop or Click to Select',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _isDragging
                                ? const Color(0xFF0d2b5c)
                                : const Color(0xFF0d2b5c),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'PDF, DOCX, PPT, Images, or Video files',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _getFileIconColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getFileIcon(),
                              size: 28,
                              color: _getFileIconColor(),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  selectedFileName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      _formatFileSize(
                                        selectedFileBytes?.length ?? 0,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 3,
                                      height: 3,
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _getShortMimeType(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    border: Border.all(
                                      color: Colors.green.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Ready to upload',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedFile = null;
                                selectedFileName = null;
                                selectedFileBytes = null;
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Error Message
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // ===== UPLOAD BUTTON =====
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : upload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0d2b5c),
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Uploading...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 20,
                        color: Colors.white,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Upload File',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    ),
  );
}
}