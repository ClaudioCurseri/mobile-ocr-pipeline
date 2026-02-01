import 'package:camera/camera.dart';
import 'package:document_scanner_app/pages/home/home_page.dart';
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

  runApp(MainApp(camera: firstCamera));
}

class MainApp extends StatelessWidget {

  final CameraDescription camera;

  const MainApp({super.key, required this.camera});

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

      home: HomePage(camera: camera),
    );
  }
}
