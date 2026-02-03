import 'dart:io';

import 'package:camera/camera.dart';
import 'package:document_scanner_app/pages/settings/settings_page.dart';
import 'package:document_scanner_app/service/pipeline/text_recognition_pipeline.dart';
import 'package:flutter/material.dart';
import 'package:text_recognition_pipeline/native_text_recognition_pipeline.dart';
import 'package:document_scanner_app/util/utils.dart' as utils;

class FlashModeMenuOption {
  final FlashMode flashMode;
  final IconData icon;

  const FlashModeMenuOption({required this.flashMode, required this.icon});
}

class ExposureMenuOption {
  final String label;
  final double? value;

  const ExposureMenuOption({required this.label, required this.value});
}

extension StringExtensions on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class ScanPage extends StatefulWidget {
  final CameraDescription camera;
  final TextRecognitionPipeline textRecognitionPipeline;

  const ScanPage({
    super.key,
    required this.camera,
    required this.textRecognitionPipeline,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _grayscale = false;
  bool _unsharpMasking = true;
  bool _binary = false;
  bool _dewarp = true;
  bool _resize = true;
  bool _useTopResultFromDictionary = false;
  bool _useContext = false;
  XFile? _capturedImage;
  final List<FlashModeMenuOption> _flashModeOptions = [
    const FlashModeMenuOption(flashMode: FlashMode.off, icon: Icons.flash_off),
    FlashModeMenuOption(flashMode: FlashMode.auto, icon: Icons.flash_auto),
    FlashModeMenuOption(flashMode: FlashMode.always, icon: Icons.flash_on),
    FlashModeMenuOption(flashMode: FlashMode.torch, icon: Icons.flashlight_on),
  ];
  late FlashModeMenuOption _selectedFlashMode;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  late ExposureMenuOption _selectedExposureOption;
  List<ExposureMenuOption> _exposureOptions = [];

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.max);
    _initializeControllerFuture = _controller.initialize().then((_) async {
      _minAvailableExposureOffset = await _controller.getMinExposureOffset();
      _maxAvailableExposureOffset = await _controller.getMaxExposureOffset();
      _generateExposureOptions();
    });
    _selectedFlashMode = _flashModeOptions.first;
    _selectedExposureOption = const ExposureMenuOption(
      label: 'Auto',
      value: null,
    );
  }

  void _generateExposureOptions() {
    List<ExposureMenuOption> options = [];
    options.add(const ExposureMenuOption(label: 'Auto', value: null));
    for (double value = -1.0; value < 0.0; value += 0.25) {
      options.add(
        ExposureMenuOption(
          label: value.toString(),
          value: _minAvailableExposureOffset * value,
        ),
      );
    }
    for (double value = 0.0; value <= 1.0; value += 0.25) {
      options.add(
        ExposureMenuOption(
          label: '+$value',
          value: _maxAvailableExposureOffset * value,
        ),
      );
    }
    setState(() {
      _exposureOptions = options;
    });
  }

  Future<void> _setExposure(ExposureMenuOption option) async {
    if (option.value == null) {
      await _controller.setExposureMode(ExposureMode.auto);
      await _controller.setExposureOffset(0.0);
    } else {
      await _controller.setExposureMode(ExposureMode.locked);
      await _controller.setExposureOffset(option.value!);
    }
    setState(() {
      _selectedExposureOption = option;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildCaptureControls() {
    return Row(
      key: const ValueKey('captureState'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MenuAnchor(
          builder:
              (BuildContext context, MenuController controller, Widget? child) {
                return IconButton(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  icon: Icon(
                    Icons.exposure,
                    color: _selectedExposureOption.value == null
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: ' Select Exposure',
                );
              },
          menuChildren: _exposureOptions.map((option) {
            return MenuItemButton(
              onPressed: () => _setExposure(option),
              trailingIcon: _selectedExposureOption == option
                  ? Icon(
                      Icons.check,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              child: Text(
                option.label,
                style: TextStyle(
                  color: _selectedExposureOption == option
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
        OutlinedButton(
          onPressed: () async {
            try {
              await _initializeControllerFuture;
              final image = await _controller.takePicture();
              if (!context.mounted) return;
              setState(() {
                _controller.pausePreview();
                _capturedImage = image;
              });
            } catch (e) {
              print(e);
            }
          },
          style: OutlinedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            side: BorderSide(
              width: 3.0,
              color: Theme.of(context).colorScheme.primary,
            ),
            backgroundColor: Colors.white,
          ),
          child: const Icon(Icons.circle, size: 30, color: Colors.transparent),
        ),
        MenuAnchor(
          builder:
              (BuildContext context, MenuController controller, Widget? child) {
                return IconButton(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  icon: Icon(
                    _selectedFlashMode.icon,
                    color: _selectedFlashMode == _flashModeOptions.first
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Select Flash Mode',
                );
              },
          menuChildren: _flashModeOptions.map((option) {
            return MenuItemButton(
              onPressed: () async {
                await _controller.setFlashMode(option.flashMode);
                setState(() {
                  _selectedFlashMode = option;
                });
              },
              trailingIcon: _selectedFlashMode == option
                  ? Icon(
                      Icons.check,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              child: Text(
                option.flashMode.name.capitalize(),
                style: TextStyle(
                  color: _selectedFlashMode == option
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewBtn({
    required Icon icon,
    required VoidCallback onPressed,
    required String text,
  }) {
    return OutlinedButton.icon(
      style: TextButton.styleFrom(
        iconSize: 30,
        side: BorderSide(
          width: 1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      onPressed: onPressed,
      icon: icon,
      label: Text(text),
    );
  }

  Widget _buildConfigBtn({
    required IconData icon,
    required String text,
    required bool config,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      style: TextButton.styleFrom(
        iconSize: 20,
        side: BorderSide(
          width: 1,
          color: config
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: config
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: Text(
        text,
        style: TextStyle(
          color: config
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildReviewControls() {
    return Row(
      key: const ValueKey('reviewState'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildReviewBtn(
          icon: const Icon(Icons.close),
          onPressed: () async {
            await utils.deleteFile(File(_capturedImage?.path ?? ""));
            setState(() {
              _controller.resumePreview();
              _capturedImage = null;
            });
          },
          text: 'Retry',
        ),
        _buildReviewBtn(
          icon: const Icon(Icons.check),
          onPressed: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (c) => const Center(child: CircularProgressIndicator()),
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
                useTopResultFromDictionary: _useTopResultFromDictionary,
                useContext: _useContext,
              ),
            );
            var success = await widget.textRecognitionPipeline.scanDocument(
              _capturedImage!,
            );
            if (context.mounted) Navigator.pop(context);
            if (mounted) {
              Navigator.of(context).pop(success);
            }
          },
          text: 'Scan',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan"),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                final isReady =
                    snapshot.connectionState == ConnectionState.done;
                final double aspectRatio = isReady
                    ? 1 / _controller.value.aspectRatio
                    : 3.0 / 4.0;
                return AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: isReady
                          ? CameraPreview(_controller)
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                            _buildConfigBtn(
                                              icon:
                                                  Icons.filter_b_and_w_outlined,
                                              text: "Grayscale",
                                              config: _grayscale,
                                              onPressed: () {
                                                setModalState(() {
                                                  _grayscale = !_grayscale;
                                                });
                                              },
                                            ),
                                            _buildConfigBtn(
                                              icon: Icons.high_quality,
                                              text: "Unsharp Mask",
                                              config: _unsharpMasking,
                                              onPressed: () {
                                                setModalState(() {
                                                  _unsharpMasking =
                                                      !_unsharpMasking;
                                                });
                                              },
                                            ),
                                            _buildConfigBtn(
                                              icon: Icons.contrast,
                                              text: "Binary",
                                              config: _binary,
                                              onPressed: () {
                                                setModalState(() {
                                                  _binary = !_binary;
                                                });
                                              },
                                            ),
                                            _buildConfigBtn(
                                              icon: Icons.transform,
                                              text: "Dewarp",
                                              config: _dewarp,
                                              onPressed: () {
                                                setModalState(() {
                                                  _dewarp = !_dewarp;
                                                });
                                              },
                                            ),
                                            _buildConfigBtn(
                                              icon: Icons.aspect_ratio,
                                              text: "Resize",
                                              config: _resize,
                                              onPressed: () {
                                                setModalState(() {
                                                  _resize = !_resize;
                                                });
                                              },
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
                                            _buildConfigBtn(
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
                                            ),
                                            _buildConfigBtn(
                                              icon: Icons.text_fields,
                                              text: "Context",
                                              config: _useContext,
                                              onPressed: () {
                                                setModalState(() {
                                                  _useContext = !_useContext;
                                                });
                                              },
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                    child: _capturedImage != null
                        ? _buildReviewControls()
                        : _buildCaptureControls(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
