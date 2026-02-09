import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path/path.dart' as path;
import 'package:scan_local/pages/settings/settings_page.dart';
import 'package:scan_local/service/pipeline/text_recognition_pipeline.dart';
import 'package:scan_local/widgets/buttons.dart';
import 'package:text_recognition_pipeline/native_text_recognition_pipeline.dart';

class ScanFromFilesPage extends StatefulWidget {
  final TextRecognitionPipeline textRecognitionPipeline;
  final List<XFile> files;

  const ScanFromFilesPage({
    super.key,
    required this.textRecognitionPipeline,
    required this.files,
  });

  @override
  State<ScanFromFilesPage> createState() => _ScanFromFilesPageState();
}

class _ScanFromFilesPageState extends State<ScanFromFilesPage> {
  late List<XFile> _files;
  bool _grayscale = false;
  bool _unsharpMasking = true;
  bool _binary = false;
  bool _dewarp = true;
  bool _resize = true;
  bool _useTopResultFromDictionary = false;
  bool _useContext = false;

  @override
  void initState() {
    super.initState();
    _files = widget.files;
  }

  Future<void> _deleteFile(XFile xFile) async {
    final file = File(xFile.path);
    try {
      if (await file.exists()) {
        await file.delete();
        setState(() {
          _files.remove(xFile);
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan Files"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return SettingsPage();
                  },
                ),
              );
            },
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final fileName = path.basename(file.path);

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
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.image,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(fileName),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    OutlinedButton.icon(
                      style: TextButton.styleFrom(
                        iconSize: 30,
                        side: BorderSide(
                          width: 1,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (BuildContext context, StateSetter setModalState) {
                                return SafeArea(
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        12,
                                        16,
                                        24,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Preprocessing",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            alignment: WrapAlignment.start,
                                            children: [
                                              Buttons.buildConfigBtn(
                                                icon: Icons
                                                    .filter_b_and_w_outlined,
                                                text: "Grayscale",
                                                config: _grayscale,
                                                onPressed: () {
                                                  setModalState(() {
                                                    _grayscale = !_grayscale;
                                                  });
                                                },
                                                context: context,
                                              ),
                                              Buttons.buildConfigBtn(
                                                icon: Icons.high_quality,
                                                text: "Unsharp Mask",
                                                config: _unsharpMasking,
                                                onPressed: () {
                                                  setModalState(() {
                                                    _unsharpMasking =
                                                        !_unsharpMasking;
                                                  });
                                                },
                                                context: context,
                                              ),
                                              Buttons.buildConfigBtn(
                                                icon: Icons.contrast,
                                                text: "Binary",
                                                config: _binary,
                                                onPressed: () {
                                                  setModalState(() {
                                                    _binary = !_binary;
                                                  });
                                                },
                                                context: context,
                                              ),
                                              Buttons.buildConfigBtn(
                                                icon: Icons.transform,
                                                text: "Dewarp",
                                                config: _dewarp,
                                                onPressed: () {
                                                  setModalState(() {
                                                    _dewarp = !_dewarp;
                                                  });
                                                },
                                                context: context,
                                              ),
                                              Buttons.buildConfigBtn(
                                                icon: Icons.aspect_ratio,
                                                text: "Resize",
                                                config: _resize,
                                                onPressed: () {
                                                  setModalState(() {
                                                    _resize = !_resize;
                                                  });
                                                },
                                                context: context,
                                              ),
                                            ],
                                          ),
                                          const Divider(),
                                          Text(
                                            "Postprocessing",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            alignment: WrapAlignment.start,
                                            children: [
                                              Buttons.buildConfigBtn(
                                                icon: Icons.spellcheck,
                                                text: "Dictionary",
                                                config:
                                                    _useTopResultFromDictionary,
                                                onPressed: () {
                                                  setModalState(() {
                                                    _useTopResultFromDictionary =
                                                        !_useTopResultFromDictionary;
                                                  });
                                                },
                                                context: context,
                                              ),
                                              Buttons.buildConfigBtn(
                                                icon: Icons.text_fields,
                                                text: "Context",
                                                config: _useContext,
                                                onPressed: () {
                                                  setModalState(() {
                                                    _useContext = !_useContext;
                                                  });
                                                },
                                                context: context,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      icon: Icon(Icons.document_scanner),
                      label: Text("Scan Options"),
                    ),
                    Buttons.buildReviewBtn(
                      icon: const Icon(Icons.check),
                      onPressed: () async {
                        final int totalFiles = _files.length;
                        final ValueNotifier<int> processedCount =
                            ValueNotifier<int>(0);

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return PopScope(
                              canPop: false,
                              child: AlertDialog(
                                title: const Text("Scanning Documents"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ValueListenableBuilder<int>(
                                      valueListenable: processedCount,
                                      builder: (context, value, child) {
                                        double progress = totalFiles > 0
                                            ? value / totalFiles
                                            : 0;

                                        return Column(
                                          children: [
                                            LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 6,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              "$value / $totalFiles done",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                        widget.textRecognitionPipeline.setPreprocessingConfig(
                          PreprocessingConfig(
                            grayscale: _grayscale,
                            unsharpMasking: _unsharpMasking,
                            binary: _binary,
                            dewarp: _dewarp,
                            resize: _resize,
                          ),
                        );
                        widget.textRecognitionPipeline.setPostProcessingConfig(
                          PostprocessingConfig(
                            useTopResultFromDictionary:
                                _useTopResultFromDictionary,
                            useContext: _useContext,
                          ),
                        );
                        for (var file in _files) {
                          await widget.textRecognitionPipeline.scanDocument(
                            file,
                          );
                          processedCount.value++;
                        }
                        if (context.mounted) Navigator.pop(context);
                        if (mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      text: 'Scan',
                      context: context,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
