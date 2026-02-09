import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:scan_local/pages/home/home_page.dart';
import 'package:scan_local/service/pipeline/text_recognition_pipeline.dart';
import 'package:flutter/material.dart';
import 'package:scan_local/theme.dart';
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
  await textRecognitionPipeline.initUnigramDictionaries();
  await textRecognitionPipeline.initBigramDictionaries();

  LicenseRegistry.addLicense(() async* {
      final tesseractLicense = await rootBundle.loadString('assets/licenses/tesseract.txt');
      final leptonicaLicense = await rootBundle.loadString('assets/licenses/leptonica.txt');
      final opencvLicense = await rootBundle.loadString('assets/licenses/opencv.txt');
      final symspellLicense = await rootBundle.loadString('assets/licenses/yams-symspell.txt');
      final dictionaryLicense = await rootBundle.loadString('assets/licenses/dictionaries.txt');
      yield LicenseEntryWithLineBreaks(['Tesseract OCR'], tesseractLicense);
      yield LicenseEntryWithLineBreaks(['Leptonica'], leptonicaLicense);
      yield LicenseEntryWithLineBreaks(['OpenCV'], opencvLicense);
      yield LicenseEntryWithLineBreaks(['yams-symspell'], symspellLicense);
      yield LicenseEntryWithLineBreaks(['Dictionaries'], dictionaryLicense);
  });

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
