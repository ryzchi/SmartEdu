import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class FileViewerDialog extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  final String fileType;

  const FileViewerDialog({
    super.key,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
  });

  static void show(
    BuildContext context, {
    required String fileUrl,
    required String fileName,
    required String fileType,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => FileViewerDialog(
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
      ),
    );
  }

  @override
  State<FileViewerDialog> createState() => _FileViewerDialogState();
}

class _FileViewerDialogState extends State<FileViewerDialog> {
  late final String _viewId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _viewId = 'file-viewer-${DateTime.now().millisecondsSinceEpoch}';
    if (kIsWeb && _isPdf) {
      _registerPdfViewer();
    }
  }

  String _fixUrl(String url) {
    if (url.isEmpty) return url;
    if (url.contains('localhost')) {
      url = url.replaceFirst('http://localhost', 'http://127.0.0.1');
    }
    if (!url.startsWith('http')) {
      if (url.startsWith('/')) {
        return 'http://127.0.0.1$url';
      } else {
        return 'http://127.0.0.1/ADET/backend/$url';
      }
    }
    return url;
  }

  bool get _isPdf => widget.fileType.toUpperCase() == 'PDF';

  bool get _isOffice {
    final t = widget.fileType.toUpperCase();
    return ['DOCX', 'DOC', 'PPT', 'PPTX', 'XLS', 'XLSX'].contains(t);
  }

  void _registerPdfViewer() {
    final fixedUrl = _fixUrl(widget.fileUrl);
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = fixedUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..allowFullscreen = true;

      iframe.onLoad.listen((_) {
        if (mounted) setState(() => _isLoading = false);
      });

      Future.delayed(const Duration(seconds: 8), () {
        if (mounted && _isLoading) setState(() => _isLoading = false);
      });

      return iframe;
    });
  }

  String _buildDownloadName() {
    final ext = widget.fileType.toLowerCase();
    final safeTitle = widget.fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .trim();
    // avoid double extension
    if (safeTitle.toLowerCase().endsWith('.$ext')) return safeTitle;
    return '$safeTitle.$ext';
  }

void _downloadFile() {
  if (!kIsWeb) return;

  final fixedFileUrl = _fixUrl(widget.fileUrl);
  final ext = widget.fileType.toLowerCase();
  final safeTitle = widget.fileName
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
      .trim();

  final uri = Uri.parse(fixedFileUrl);
  final pathOnly = uri.path;

  final encodedPath = Uri.encodeComponent(pathOnly);
  final encodedTitle = Uri.encodeComponent(safeTitle);
  final downloadUrl =
      'http://127.0.0.1/ADET/backend/php/materials.php'
      '?download=1'
      '&file_url=$encodedPath'
      '&title=$encodedTitle';

  html.window.location.href = downloadUrl;
}

  void _openInNewTab() {
    if (kIsWeb) {
      html.window.open(_fixUrl(widget.fileUrl), '_blank');
    }
  }

  Color _getTypeColor() {
    switch (widget.fileType.toUpperCase()) {
      case 'PDF': return const Color(0xFFD85A30);
      case 'DOCX': case 'DOC': return Colors.blue;
      case 'PPT': case 'PPTX': return Colors.orange;
      case 'XLS': case 'XLSX': return Colors.green;
      case 'MP4': case 'AVI': case 'MOV': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.fileType.toUpperCase()) {
      case 'PDF': return Icons.picture_as_pdf;
      case 'DOCX': case 'DOC': return Icons.description;
      case 'PPT': case 'PPTX': return Icons.slideshow;
      case 'XLS': case 'XLSX': return Icons.table_chart;
      case 'MP4': case 'AVI': case 'MOV': return Icons.video_library;
      default: return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: screenSize.width * 0.85,
        height: screenSize.height * 0.88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0d2b5c),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getTypeIcon(), color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          widget.fileType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.white70, size: 20),
                    onPressed: _openInNewTab,
                    tooltip: 'Open in new tab',
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white70, size: 20),
                    onPressed: _downloadFile,
                    tooltip: 'Download',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ===== CONTENT =====
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: _buildContent(),
              ),
            ),

            // ===== FOOTER =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openInNewTab,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open in New Tab'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0d2b5c),
                      side: const BorderSide(color: Color(0xFF0d2b5c)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _downloadFile,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      foregroundColor: const Color(0xFF0d2b5c),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // PDF — render inline via iframe
    if (_isPdf && kIsWeb) {
      return Stack(
        children: [
          HtmlElementView(viewType: _viewId),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF0d2b5c)),
                    const SizedBox(height: 16),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // Office files — cannot preview locally
    if (_isOffice) {
      return Container(
        color: const Color(0xFF1a1a2e),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getTypeIcon(), size: 64, color: _getTypeColor()),
                const SizedBox(height: 16),
                Text(
                  widget.fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.fileType.toUpperCase(),
                    style: TextStyle(
                      color: _getTypeColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '${widget.fileType.toUpperCase()} files cannot be\npreviewed in the browser directly.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _downloadFile,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text(
                        'Download File',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
                        foregroundColor: const Color(0xFF0d2b5c),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _openInNewTab,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open in New Tab'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Fallback
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getTypeIcon(), size: 64, color: _getTypeColor()),
          const SizedBox(height: 16),
          const Text('Preview not available', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _downloadFile,
            icon: const Icon(Icons.download),
            label: const Text('Download File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0d2b5c),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}