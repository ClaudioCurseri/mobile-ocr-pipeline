import 'package:camera/camera.dart';
import 'package:document_scanner_app/pages/settings/settings_page.dart';
import 'package:document_scanner_app/service/pipeline/text_recognition_pipeline.dart';
import 'package:flutter/material.dart';

class ScanPage extends StatefulWidget {

  final CameraDescription camera;

  const ScanPage({super.key, required this.camera});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.max,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildControlBtn({
    required Icon icon, 
    required VoidCallback onPressed,
    required String text
  }) {
    return OutlinedButton.icon(
      style: TextButton.styleFrom(
        iconSize: 30,
        side: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary),
      ),
      onPressed: onPressed,
      icon: icon,
      label: Text(text)
    );
  }

  Widget _buildCaptureControl() {
    return Container(
      key: const ValueKey('captureState'), 
      alignment: Alignment.center,
      child: OutlinedButton(
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
    );
  }

  Widget _buildReviewControls() {
    return Row(
      key: const ValueKey('reviewState'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlBtn(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _controller.resumePreview();
              _capturedImage = null;
            });
          },
          text: 'Retry',
        ),
        _buildControlBtn(
          icon: const Icon(Icons.check),
          onPressed: () {
            TextRecognitionPipeline().scanDocument(_capturedImage!);
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
                  }
                )
              );
            }, 
            icon: const Icon(Icons.settings_rounded)
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                final isReady = snapshot.connectionState == ConnectionState.done;
                final double aspectRatio = isReady 
                  ? 1 / _controller.value.aspectRatio 
                  : 3.0 / 4.0;
                return AspectRatio(
                aspectRatio: aspectRatio,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
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
          child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: _capturedImage != null
                  ? _buildReviewControls()
                  : _buildCaptureControl(),
            ),
        )
        ],
      ),
    );
  }
}