import 'package:camera/camera.dart';
import 'package:document_scanner_app/pages/home/home_page.dart';
import 'package:document_scanner_app/service/pipeline/text_recognition_pipeline.dart';
import 'package:flutter/material.dart';
import 'package:document_scanner_app/theme.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  final TextRecognitionPipeline textRecognitionPipeline = TextRecognitionPipeline();
  await textRecognitionPipeline.initialize();

  runApp(MainApp(camera: firstCamera, textRecognitionPipeline: textRecognitionPipeline));
}

class MainApp extends StatelessWidget {

  final CameraDescription camera;
  final TextRecognitionPipeline textRecognitionPipeline;

  const MainApp({super.key, required this.camera, required this.textRecognitionPipeline});

  @override
  Widget build(BuildContext context) {

    final textTheme = Theme.of(context).textTheme;

    final materialTheme = MaterialTheme(textTheme);

    return MaterialApp(
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      highContrastTheme: materialTheme.lightHighContrast(),
      highContrastDarkTheme: materialTheme.darkHighContrast(),

      themeMode: ThemeMode.system,

      home: HomePage(camera: camera, textRecognitionPipeline: textRecognitionPipeline),
    );
  }
}
