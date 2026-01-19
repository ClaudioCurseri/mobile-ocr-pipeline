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
    required IconData icon, 
    required Color color, 
    required VoidCallback onPressed
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
        side: BorderSide(width: 3.0, color: color),
        backgroundColor: Colors.white,
      ),
      child: Icon(icon, size: 30, color: color),
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
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_capturedImage != null) ...[
                   _buildControlBtn(
                     icon: Icons.close, 
                     color: Colors.red, 
                     onPressed: () {
                       setState(() {
                        _controller.resumePreview();
                        _capturedImage = null;
                       });
                     }
                   ),
                   _buildControlBtn(
                     icon: Icons.check, 
                     color: Colors.green, 
                     onPressed: () {
                      TextRecognitionPipeline().scanDocument(_capturedImage!);
                     }
                   ),
                ] else ...[
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
                  )
                ]
            ],
          ),
        )
        ],
      ),
    );
  }
}