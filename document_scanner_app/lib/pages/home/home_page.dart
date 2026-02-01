import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';

import 'package:document_scanner_app/pages/scan/scan_page.dart';
import 'package:document_scanner_app/pages/settings/settings_page.dart';

class HomePage extends StatefulWidget {
  final CameraDescription camera;

  const HomePage({super.key, required this.camera});

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
  }

  Future<void> _loadPdfFiles() async {
    setState(() => _isLoading = true);

    final directory = await getApplicationDocumentsDirectory();

    if (directory.existsSync()) {
      final List<FileSystemEntity> files = directory
          .listSync()
          .where((file) => file.path.endsWith('.pdf'))
          .toList();

      files.sort((a, b) {
        return b.statSync().modified.compareTo(a.statSync().modified);
      });

      setState(() {
        _pdfFiles = files;
        _isLoading = false;
      });
    } else {
      setState(() {
        _pdfFiles = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        await _loadPdfFiles();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("File deleted")));
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
                    await _loadPdfFiles();
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
      MaterialPageRoute(builder: (context) => ScanPage(camera: widget.camera)),
    ).then((success) async {
      if (success == true) await _loadPdfFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Document Scanner App"),
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
                : _pdfFiles.isEmpty
                ? Center(
                    child: Column(
                      spacing: 15,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.document_scanner,
                          color: Theme.of(context).colorScheme.primary,
                          size: 75,
                        ),
                        Text(
                          "Scan documents to view them here.",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
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
                              onPressed: (context) => _shareFile(file.path),
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
              onPressed: () {},
              icon: const Icon(Icons.folder_rounded),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.photo_rounded)),
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
