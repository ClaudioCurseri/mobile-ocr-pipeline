import 'dart:io';
import 'package:camera/camera.dart';
import 'package:scan_local/pages/scan/scan_from_files_page.dart';
import 'package:scan_local/service/pipeline/text_recognition_pipeline.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_pdfview/flutter_pdfview.dart';
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
    if (!directory.existsSync()) return;
    final cameraDirectory = Directory('${directory.path}/camera/pictures');
    if (!cameraDirectory.existsSync()) return;
    cameraDirectory.listSync().forEach((file) => file.deleteSync());
  }

  Future<void> _loadPdfFiles({bool showFullLoading = true}) async {
    if (showFullLoading) {
      setState(() => _isLoading = true);
    }

    final directory = await getApplicationDocumentsDirectory();

    if (directory.existsSync()) {
      final List<FileSystemEntity> files = directory
          .listSync()
          .where((file) => file.path.endsWith('.pdf'))
          .toList();

      files.sort((a, b) {
        return b.statSync().modified.compareTo(a.statSync().modified);
      });

      if (mounted) {
        setState(() {
          _pdfFiles = files;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _pdfFiles = [];
          _isLoading = false;
        });
      }
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
    final TextEditingController nameController = TextEditingController();
    final oldName = path.basenameWithoutExtension(file.path);
    nameController.text = oldName;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != oldName) {
                  final dir = path.dirname(file.path);
                  final newPath = path.join(dir, "$newName.pdf");
                  final newFile = File(newPath);

                  if (await newFile.exists()) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Name already exists")),
                      );
                    }
                  } else {
                    await file.rename(newPath);
                    if (context.mounted) Navigator.pop(context);
                    await _loadPdfFiles(showFullLoading: false);
                  }
                }
              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );
  }

  void _shareFile(String filePath) {
    SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
  }

  void _navigateToScanPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanPage(
          camera: widget.camera,
          textRecognitionPipeline: widget.textRecognitionPipeline,
        ),
      ),
    ).then((success) async {
      if (success == true) {
        await _loadPdfFiles(showFullLoading: false);
        await _clearTempCameraPictures();
      }
    });
  }

  void _navigateToScanFromFilesPage(List<XFile> files) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanFromFilesPage(
          textRecognitionPipeline: widget.textRecognitionPipeline,
          files: files,
        ),
      ),
    ).then((success) async {
      if (success == true) {
        await _loadPdfFiles(showFullLoading: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ScanLocal"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
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
                        ? LayoutBuilder(
                            builder: (context, constraints) =>
                                SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: constraints.maxHeight,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.document_scanner,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
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
                                ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _pdfFiles.length,
                            itemBuilder: (context, index) {
                              final file = _pdfFiles[index];
                              final fileName = path.basename(file.path);
                              final lastModified = file.statSync().modified;

                              return Slidable(
                                key: ValueKey(file.path),

                                startActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) => _deleteFile(file),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onError,
                                      icon: Icons.delete,
                                      label: 'Delete',
                                    ),
                                    SlidableAction(
                                      onPressed: (context) => _renameFile(file),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onSecondary,
                                      icon: Icons.edit,
                                      label: 'Rename',
                                    ),
                                  ],
                                ),

                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) =>
                                          _shareFile(file.path),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.tertiary,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onTertiary,
                                      icon: Icons.share,
                                      label: 'Share',
                                    ),
                                  ],
                                ),

                                child: ListTile(
                                  leading: const Icon(
                                    Icons.picture_as_pdf,
                                    color: Colors.red,
                                  ),
                                  title: Text(fileName),
                                  subtitle: Text(
                                    "Date: ${lastModified.toString().split('.')[0]}",
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PDFViewerPage(filePath: file.path),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToScanPage,
        child: const Icon(Icons.camera_enhance_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        notchMargin: 5,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'tiff', 'tif'],
                  type: FileType.custom,
                  allowMultiple: true,
                );

                if (result == null) {
                  // user canceled file picker
                  return;
                }

                List<XFile> files = result.xFiles;
                if (files.isEmpty) return;

                _navigateToScanFromFilesPage(files);
              },
              icon: const Icon(Icons.upload_file_rounded),
            ),
            IconButton(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final List<XFile> images = await picker.pickMultiImage();
                if (images.isEmpty) return;

                _navigateToScanFromFilesPage(images);
              },
              icon: const Icon(Icons.photo_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class PDFViewerPage extends StatelessWidget {
  final String filePath;

  const PDFViewerPage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(path.basename(filePath)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
            },
          ),
        ],
      ),
      body: PDFView(
        filePath: filePath,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
