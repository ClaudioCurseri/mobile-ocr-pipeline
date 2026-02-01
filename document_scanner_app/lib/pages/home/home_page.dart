import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_pdfview/flutter_pdfview.dart';
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
  }

  void _navigateToScanPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanPage(camera: widget.camera),
      ),
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
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
            icon: const Icon(Icons.settings_rounded),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              "Recent Scans",
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pdfFiles.isEmpty
                    ? const Center(child: Text("No scans found"))
                    : ListView.builder(
                        itemCount: _pdfFiles.length,
                        itemBuilder: (context, index) {
                          final file = _pdfFiles[index];
                          final fileName = path.basename(file.path);
                          final lastModified = file.statSync().modified;

                          return ListTile(
                            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                            title: Text(fileName),
                            subtitle: Text("Date: ${lastModified.toString().split('.')[0]}"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PDFViewerPage(filePath: file.path),
                                ),
                              );
                            },
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
                icon: const Icon(
                  Icons.folder_rounded,
                )),
            IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.photo_rounded,
                ))
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
      ),
      body: PDFView(
        filePath: filePath,
        backgroundColor: Theme.of(context).colorScheme.surface
      ),
    );
  }
}