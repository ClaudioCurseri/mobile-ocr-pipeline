import 'dart:io';
import 'package:camera/camera.dart';
import 'package:scan_local/pages/home/pdf_viewer_page.dart';
import 'package:scan_local/pages/scan/scan_from_files_page.dart';
import 'package:scan_local/service/pipeline/text_recognition_pipeline.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:scan_local/pages/scan/scan_page.dart';
import 'package:scan_local/pages/settings/settings_page.dart';

class HomePage extends StatefulWidget {
  final CameraDescription camera;
  final TextRecognitionPipeline textRecognitionPipeline;

  const HomePage({
    super.key,
    required this.camera,
    required this.textRecognitionPipeline,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<FileSystemEntity> _pdfFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
    _clearTempCameraPictures();
  }

  Future<void> _clearTempCameraPictures() async {
    final directory = await getApplicationDocumentsDirectory();
    final cameraDirectory = Directory('${directory.path}/camera/pictures');
    if (cameraDirectory.existsSync()) {
      cameraDirectory.listSync().forEach((file) => file.deleteSync());
    }
  }

  Future<void> _loadPdfFiles({bool showFullLoading = true}) async {
    if (showFullLoading) setState(() => _isLoading = true);

    final directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = [];

    if (directory.existsSync()) {
      files =
          directory
              .listSync()
              .where((file) => file.path.toLowerCase().endsWith('.pdf'))
              .toList()
            ..sort(
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
            );
    }

    if (mounted) {
      setState(() {
        _pdfFiles = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        await _loadPdfFiles(showFullLoading: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("File deleted"),
              duration: Duration(milliseconds: 500),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error deleting file: $e");
    }
  }

  Future<void> _renameFile(FileSystemEntity file) async {
    final oldName = path.basenameWithoutExtension(file.path);
    final TextEditingController nameController = TextEditingController(
      text: oldName,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename File"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter new name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text("Rename"),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      final dir = path.dirname(file.path);
      final newPath = path.join(dir, "$newName.pdf");

      if (await File(newPath).exists()) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Name already exists")));
        }
      } else {
        await file.rename(newPath);
        await _loadPdfFiles(showFullLoading: false);
      }
    }
  }

  void _shareFile(String filePath) {
    SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
  }

  Future<void> _navigateAndRefresh(
    Widget page, {
    bool clearTempPictures = false,
  }) async {
    final success = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    if (success == true) {
      await _loadPdfFiles(showFullLoading: false);
      if (clearTempPictures) await _clearTempCameraPictures();
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['jpg', 'jpeg', 'png', 'tiff', 'tif'],
      type: FileType.custom,
      allowMultiple: true,
    );

    if (result != null && result.xFiles.isNotEmpty) {
      _navigateAndRefresh(
        ScanFromFilesPage(
          textRecognitionPipeline: widget.textRecognitionPipeline,
          files: result.xFiles,
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await ImagePicker().pickMultiImage();
    if (images.isNotEmpty) {
      _navigateAndRefresh(
        ScanFromFilesPage(
          textRecognitionPipeline: widget.textRecognitionPipeline,
          files: images,
        ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context, BoxConstraints constraints) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: constraints.maxHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.document_scanner,
                color: Theme.of(context).colorScheme.primary,
                size: 75,
              ),
              const SizedBox(height: 15),
              const Text(
                "Scan documents to view them here.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfTile(FileSystemEntity file) {
    final fileName = path.basename(file.path);
    final lastModified = file.statSync().modified;

    return Slidable(
      key: ValueKey(file.path),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _deleteFile(file),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            icon: Icons.delete,
            label: 'Delete',
          ),
          SlidableAction(
            onPressed: (_) => _renameFile(file),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            icon: Icons.edit,
            label: 'Rename',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _shareFile(file.path),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            foregroundColor: Theme.of(context).colorScheme.onTertiary,
            icon: Icons.share,
            label: 'Share',
          ),
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(fileName),
        subtitle: Text("Date: ${lastModified.toString().split('.')[0]}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PDFViewerPage(filePath: file.path)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ScanLocal"),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              "Recent Scans",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadPdfFiles(showFullLoading: false),
                    child: _pdfFiles.isEmpty
                        ? LayoutBuilder(builder: _buildEmptyState)
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _pdfFiles.length,
                            itemBuilder: (context, index) =>
                                _buildPdfTile(_pdfFiles[index]),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndRefresh(
          ScanPage(
            camera: widget.camera,
            textRecognitionPipeline: widget.textRecognitionPipeline,
          ),
          clearTempPictures: true,
        ),
        child: const Icon(Icons.camera_enhance_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        notchMargin: 5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _pickFiles,
              icon: const Icon(Icons.upload_file_rounded),
            ),
            IconButton(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
